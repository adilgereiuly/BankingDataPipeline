#!/usr/bin/env python3
"""Generate one idempotent daily landing batch from the seed and earlier batches."""
from __future__ import annotations

import argparse
import csv
import random
from datetime import date, datetime, time, timedelta
from pathlib import Path

try:
    from faker import Faker
except ImportError as exc:
    raise SystemExit("gen_daily_batch.py requires Faker. Install it with: pip install Faker") from exc

DEFAULT_MIN_TRANSACTIONS, DEFAULT_MAX_TRANSACTIONS = 150, 400
MAX_NEW_CUSTOMERS = 5
CHANGE_RATE_MIN, CHANGE_RATE_MAX = 0.01, 0.03
APPROVAL_PROBABILITY = 0.97
CARD_PROBABILITY = 0.75
TRANSACTION_WEIGHTS = {"purchase": 58, "transfer_out": 13, "transfer_in": 11, "withdrawal": 8, "deposit": 7, "fee": 3}
AMOUNT_RANGES = {"purchase": (2, 300), "transfer_out": (20, 3000), "transfer_in": (20, 5000), "withdrawal": (20, 500), "deposit": (50, 5000), "fee": (1, 25)}
CITIES = ["Almaty", "Astana", "Atyrau", "Shymkent", "Karaganda", "Aktobe", "Pavlodar", "Kostanay"]


def rows(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write(path: Path, columns: list[str], data: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, extrasaction="ignore")
        writer.writeheader(); writer.writerows(data)


def universe(seed: Path, incoming: Path, batch_date: str):
    """Replay batches strictly before batch_date, producing current entity state."""
    customers = {x["customer_id"]: x for x in rows(seed / "customers.csv")}
    accounts = {x["account_id"]: x for x in rows(seed / "accounts.csv")}
    cards = {x["card_id"]: x for x in rows(seed / "cards.csv")}
    merchants = rows(seed / "merchants.csv")
    for folder in sorted((p for p in incoming.iterdir() if p.is_dir() and p.name < batch_date), key=lambda p: p.name) if incoming.exists() else []:
        for item in rows(folder / f"new_customers_{folder.name}.csv"): customers[item["customer_id"]] = item
        for item in rows(folder / f"new_accounts_{folder.name}.csv"): accounts[item["account_id"]] = item
        for item in rows(folder / f"new_cards_{folder.name}.csv"): cards[item["card_id"]] = item
        for item in rows(folder / f"customer_changes_{folder.name}.csv"):
            if item["change_type"] == "status": customers[item["customer_id"]]["status"] = item["status"]
    return customers, accounts, cards, merchants


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch_date", help="Date to generate, YYYY-MM-DD")
    parser.add_argument("--seed-dir", type=Path, default=Path("staging/seed"))
    parser.add_argument("--incoming-dir", type=Path, default=Path("staging/incoming"))
    parser.add_argument("--min-transactions", type=int, default=DEFAULT_MIN_TRANSACTIONS)
    parser.add_argument("--max-transactions", type=int, default=DEFAULT_MAX_TRANSACTIONS)
    parser.add_argument("--max-new-customers", type=int, default=MAX_NEW_CUSTOMERS)
    args = parser.parse_args()
    try: day = date.fromisoformat(args.batch_date)
    except ValueError: parser.error("batch_date must be YYYY-MM-DD")
    if args.min_transactions < 0 or args.max_transactions < args.min_transactions or args.max_new_customers < 0: parser.error("invalid volume limits")
    if not (args.seed_dir / "customers.csv").exists(): parser.error(f"seed data not found in {args.seed_dir}; run gen_seed.py first")

    rng = random.Random(f"banking-daily:{args.batch_date}")
    fake = Faker("en_US"); fake.seed_instance(f"banking-daily:{args.batch_date}")
    customers, accounts, cards, merchants = universe(args.seed_dir, args.incoming_dir, args.batch_date)
    out = args.incoming_dir / args.batch_date
    active_customers = [x for x in customers.values() if x["status"] == "active"]
    active_accounts = [x for x in accounts.values() if x["status"] == "active" and customers.get(x["customer_id"], {}).get("status") == "active"]
    active_cards = [x for x in cards.values() if x["status"] == "active" and x["account_id"] in {a["account_id"] for a in active_accounts}]
    cards_by_account = {}
    for card in active_cards: cards_by_account.setdefault(card["account_id"], []).append(card)

    # Changes are append-only events. Address fields are populated only for address events.
    change_count = min(len(active_customers), rng.randint(round(len(active_customers) * CHANGE_RATE_MIN), round(len(active_customers) * CHANGE_RATE_MAX)))
    changes = []
    for i, customer in enumerate(rng.sample(active_customers, change_count), 1):
        stamp = datetime.combine(day, time(rng.randrange(24), rng.randrange(60), rng.randrange(60))).isoformat(sep=" ")
        if rng.random() < 0.75:
            changes.append({"change_id": f"CH{day:%Y%m%d}{i:05d}", "customer_id": customer["customer_id"], "change_type": "address", "status": "", "address_line": fake.street_address().replace("\n", ", "), "city": rng.choice(CITIES), "country": "Kazakhstan", "change_timestamp": stamp})
        else:
            changes.append({"change_id": f"CH{day:%Y%m%d}{i:05d}", "customer_id": customer["customer_id"], "change_type": "status", "status": rng.choices(["blocked", "closed"], [4, 1])[0], "address_line": "", "city": "", "country": "", "change_timestamp": stamp})

    existing_customer_number = max((int(x[1:]) for x in customers if x.startswith("C")), default=0)
    existing_account_number = max((int(x[2:]) for x in accounts if x.startswith("AC")), default=0)
    existing_card_number = max((int(x[2:]) for x in cards if x.startswith("CD")), default=0)
    products = rows(args.seed_dir / "account_products.csv"); bins = rows(args.seed_dir / "card_bin_ranges.csv")
    new_customers, new_accounts, new_cards = [], [], []
    for n in range(1, rng.randint(0, args.max_new_customers) + 1):
        cid = f"C{existing_customer_number + n:06d}"
        created_at = datetime.combine(day, time(rng.randrange(24), rng.randrange(60))).isoformat(sep=" ")
        new_customers.append({"customer_id": cid, "first_name": fake.first_name(), "last_name": fake.last_name(), "dob": fake.date_of_birth(minimum_age=18, maximum_age=80).isoformat(), "status": "active", "created_at": created_at})
        if rng.random() < 0.85:
            product = rng.choice(products); aid = f"AC{existing_account_number + len(new_accounts) + 1:07d}"
            new_accounts.append({"account_id": aid, "customer_id": cid, "product_id": product["product_id"], "currency_code": product["default_currency"], "opened_date": day.isoformat(), "status": "active"})
            if rng.random() < CARD_PROBABILITY:
                bin_row = rng.choice(bins); card_id = f"CD{existing_card_number + len(new_cards) + 1:07d}"
                new_cards.append({"card_id": card_id, "account_id": aid, "bin": bin_row["bin"], "issued_date": day.isoformat(), "status": "active"})

    txs = []
    if active_accounts:
        available_types = [t for t in TRANSACTION_WEIGHTS if t != "purchase" or active_cards]
        weights = [TRANSACTION_WEIGHTS[t] for t in available_types]
        for n in range(1, rng.randint(args.min_transactions, args.max_transactions) + 1):
            tx_type = rng.choices(available_types, weights=weights)[0]
            candidates = [a for a in active_accounts if tx_type != "purchase" or a["account_id"] in cards_by_account]
            account = rng.choice(candidates)
            timestamp = datetime.combine(day, time()) + timedelta(seconds=rng.randrange(86400))
            txs.append({"transaction_id": f"TX{day:%Y%m%d}{n:06d}", "transaction_timestamp": timestamp.isoformat(sep=" "), "account_id": account["account_id"],
                        "card_id": rng.choice(cards_by_account[account["account_id"]])["card_id"] if tx_type == "purchase" else "", "merchant_id": rng.choice(merchants)["merchant_id"] if tx_type == "purchase" else "",
                        "transaction_type": tx_type, "currency_code": account["currency_code"], "amount": f"{rng.uniform(*AMOUNT_RANGES[tx_type]):.2f}", "status": "approved" if rng.random() < APPROVAL_PROBABILITY else "declined"})

    write(out / f"transactions_{args.batch_date}.csv", ["transaction_id", "transaction_timestamp", "account_id", "card_id", "merchant_id", "transaction_type", "currency_code", "amount", "status"], txs)
    write(out / f"customer_changes_{args.batch_date}.csv", ["change_id", "customer_id", "change_type", "status", "address_line", "city", "country", "change_timestamp"], changes)
    write(out / f"new_customers_{args.batch_date}.csv", ["customer_id", "first_name", "last_name", "dob", "status", "created_at"], new_customers)
    write(out / f"new_accounts_{args.batch_date}.csv", ["account_id", "customer_id", "product_id", "currency_code", "opened_date", "status"], new_accounts)
    write(out / f"new_cards_{args.batch_date}.csv", ["card_id", "account_id", "bin", "issued_date", "status"], new_cards)
    print(f"Wrote {out}: {len(txs)} transactions, {len(changes)} changes, {len(new_customers)} new customers.")


if __name__ == "__main__":
    main()
