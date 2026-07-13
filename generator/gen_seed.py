#!/usr/bin/env python3
"""Create the deterministic baseline data set for the banking simulator."""
from __future__ import annotations

import argparse
import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

try:
    from faker import Faker
except ImportError as exc:
    raise SystemExit("gen_seed.py requires Faker. Install it with: pip install Faker") from exc

SEED = 20260713
DEFAULT_CUSTOMERS = 500
DEFAULT_MERCHANTS = 80
ACCOUNT_COUNTS = (1, 2, 2, 2, 3)
ACTIVE_ACCOUNT_PROBABILITY = 0.90
CARD_PROBABILITY = 0.75

CURRENCIES = [
    ("USD", "US Dollar", "$"), ("EUR", "Euro", "€"), ("KZT", "Kazakhstani Tenge", "₸"),
    ("GBP", "Pound Sterling", "£"), ("RUB", "Russian Ruble", "₽"),
]
CATEGORY_NAMES = ["Grocery", "Restaurant", "Fuel", "Pharmacy", "Travel", "Retail", "Utilities", "Entertainment", "Online Services", "Transport"]
TRANSACTION_TYPES = ["purchase", "transfer_out", "transfer_in", "withdrawal", "deposit", "fee"]
PRODUCTS = [
    ("CHK", "Current account", "USD"), ("SAV", "Savings account", "USD"),
    ("KZT_CHK", "Tenge current account", "KZT"), ("EUR_SAV", "Euro savings account", "EUR"),
    ("PREM", "Premium current account", "USD"),
]
BIN_RANGES = [("421234", "Visa Classic", "VISA"), ("521234", "Mastercard Standard", "MASTERCARD"), ("431234", "Visa Gold", "VISA")]
CITIES = ["Almaty", "Astana", "Atyrau", "Shymkent", "Karaganda", "Aktobe", "Pavlodar", "Kostanay"]


def write_csv(path: Path, columns: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("staging/seed"))
    parser.add_argument("--customers", type=int, default=DEFAULT_CUSTOMERS)
    parser.add_argument("--merchants", type=int, default=DEFAULT_MERCHANTS)
    args = parser.parse_args()
    if args.customers < 1 or args.merchants < 1:
        parser.error("--customers and --merchants must be positive")

    rng = random.Random(SEED)
    fake = Faker("en_US")
    Faker.seed(SEED)
    today = date.today()
    created_start = today - timedelta(days=3 * 365)
    customers, addresses, contacts, accounts, cards = [], [], [], [], []
    address_no = contact_no = account_no = card_no = 0

    for customer_no in range(1, args.customers + 1):
        customer_id = f"C{customer_no:06d}"
        created = created_start + timedelta(days=rng.randrange((today - created_start).days + 1))
        customer_status = rng.choices(["active", "blocked", "closed"], weights=[94, 3, 3])[0]
        customers.append({"customer_id": customer_id, "first_name": fake.first_name(), "last_name": fake.last_name(),
                          "dob": fake.date_of_birth(minimum_age=18, maximum_age=80).isoformat(), "status": customer_status,
                          "created_at": datetime.combine(created, datetime.min.time()).isoformat(sep=" ")})
        address_no += 1
        addresses.append({"address_id": f"A{address_no:07d}", "customer_id": customer_id, "address_line": fake.street_address().replace("\n", ", "),
                          "city": rng.choice(CITIES), "country": "Kazakhstan", "valid_from": created.isoformat(), "valid_to": ""})
        contact_no += 1
        contacts.append({"contact_id": f"CT{contact_no:07d}", "customer_id": customer_id, "phone": fake.msisdn()[:11],
                         "email": fake.unique.email(), "valid_from": created.isoformat(), "valid_to": ""})
        for _ in range(rng.choice(ACCOUNT_COUNTS)):
            account_no += 1
            product_id, _, currency = rng.choice(PRODUCTS)
            opened = created + timedelta(days=rng.randrange(max(1, (today - created).days + 1)))
            account_status = "active" if customer_status == "active" and rng.random() < ACTIVE_ACCOUNT_PROBABILITY else rng.choice(["dormant", "closed"])
            account_id = f"AC{account_no:07d}"
            accounts.append({"account_id": account_id, "customer_id": customer_id, "product_id": product_id, "currency_code": currency,
                             "opened_date": opened.isoformat(), "status": account_status})
            if account_status == "active" and rng.random() < CARD_PROBABILITY:
                card_no += 1
                bin_value, _, _ = rng.choice(BIN_RANGES)
                cards.append({"card_id": f"CD{card_no:07d}", "account_id": account_id, "bin": bin_value,
                              "issued_date": opened.isoformat(), "status": "active"})

    merchants = [{"merchant_id": f"M{i:04d}", "name": f"{fake.company()} {rng.choice(['Store', 'Market', 'Services', 'Cafe'])}",
                  "category_id": f"MC{rng.randrange(1, len(CATEGORY_NAMES) + 1):02d}", "city": rng.choice(CITIES)}
                 for i in range(1, args.merchants + 1)]
    out = args.output_dir
    write_csv(out / "customers.csv", ["customer_id", "first_name", "last_name", "dob", "status", "created_at"], customers)
    write_csv(out / "customer_addresses.csv", ["address_id", "customer_id", "address_line", "city", "country", "valid_from", "valid_to"], addresses)
    write_csv(out / "customer_contacts.csv", ["contact_id", "customer_id", "phone", "email", "valid_from", "valid_to"], contacts)
    write_csv(out / "accounts.csv", ["account_id", "customer_id", "product_id", "currency_code", "opened_date", "status"], accounts)
    write_csv(out / "cards.csv", ["card_id", "account_id", "bin", "issued_date", "status"], cards)
    write_csv(out / "merchants.csv", ["merchant_id", "name", "category_id", "city"], merchants)
    write_csv(out / "currencies.csv", ["currency_code", "currency_name", "symbol"], [dict(zip(["currency_code", "currency_name", "symbol"], x)) for x in CURRENCIES])
    write_csv(out / "merchant_categories.csv", ["category_id", "category_name"], [{"category_id": f"MC{i:02d}", "category_name": name} for i, name in enumerate(CATEGORY_NAMES, 1)])
    write_csv(out / "transaction_types.csv", ["transaction_type", "description"], [{"transaction_type": x, "description": x.replace("_", " ").title()} for x in TRANSACTION_TYPES])
    write_csv(out / "account_products.csv", ["product_id", "product_name", "default_currency"], [dict(zip(["product_id", "product_name", "default_currency"], x)) for x in PRODUCTS])
    write_csv(out / "card_bin_ranges.csv", ["bin", "product_name", "network"], [dict(zip(["bin", "product_name", "network"], x)) for x in BIN_RANGES])
    print(f"Wrote seed data to {out} ({len(customers)} customers, {len(accounts)} accounts, {len(cards)} cards).")


if __name__ == "__main__":
    main()
