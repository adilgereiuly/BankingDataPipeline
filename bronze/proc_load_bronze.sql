-- =============================================================================
-- Bronze Layer Ingestion Procedures
-- Purpose: One stored procedure per source entity. 
--          Each procedure truncates its staging table, COPYs the given CSV into staging, then merges into Bronze:
--            - Current-state entities: 
--              (customers, accounts, cards, etc.)
--              use ON CONFLICT DO UPDATE, so Bronze always reflects the latest known state per row.
--            - Append-only entities:
--              (transactions, customer_changes) 
--              use ON CONFLICT DO NOTHING, since historical events are never overwritten.
-- Usage:   CALL bronze.load_<table>('/staging/incoming/{date}/<file>.csv');
-- =============================================================================


CREATE OR REPLACE PROCEDURE bronze.load_account_products (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.account_products;
EXECUTE format('COPY staging.account_products (product_id, product_name, default_currency) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.account_products
(product_id, product_name, default_currency, dwh_load_date)
SELECT
product_id,
product_name,
default_currency,
CURRENT_TIMESTAMP
FROM staging.account_products
ON CONFLICT (product_id) DO UPDATE SET
product_name = excluded.product_name,
default_currency = excluded.default_currency,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_accounts (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.accounts;
EXECUTE format('COPY staging.accounts (account_id, customer_id, product_id, currency_code, opened_date, status) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.accounts
(account_id, customer_id, product_id, currency_code, opened_date, status, dwh_load_date)
SELECT
account_id,
customer_id,
product_id,
currency_code,
opened_date,
status,
CURRENT_TIMESTAMP
FROM staging.accounts
ON CONFLICT (account_id) DO UPDATE SET
customer_id = excluded.customer_id,
product_id = excluded.product_id,
currency_code = excluded.currency_code,
opened_date = excluded.opened_date,
status = excluded.status,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_card_bin_ranges (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.card_bin_ranges;
EXECUTE format('COPY staging.card_bin_ranges (bin, product_name, network) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.card_bin_ranges
(bin, product_name, network, dwh_load_date)
SELECT
bin,
product_name,
network,
CURRENT_TIMESTAMP
FROM staging.card_bin_ranges
ON CONFLICT (bin) DO UPDATE SET
product_name = excluded.product_name,
network = excluded.network,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_cards (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.cards;
EXECUTE format('COPY staging.cards (card_id, account_id, bin, issued_date, status) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.cards
(card_id, account_id, bin, issued_date, status, dwh_load_date)
SELECT
card_id,
account_id,
bin,
issued_date,
status,
CURRENT_TIMESTAMP
FROM staging.cards
ON CONFLICT (card_id) DO UPDATE SET
account_id = excluded.account_id,
bin = excluded.bin,
issued_date = excluded.issued_date,
status = excluded.status,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_currencies (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.currencies;
EXECUTE format('COPY staging.currencies (currency_code, currency_name, symbol) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.currencies
(currency_code, currency_name, symbol, dwh_load_date)
SELECT
currency_code,
currency_name,
symbol,
CURRENT_TIMESTAMP
FROM staging.currencies
ON CONFLICT (currency_code) DO UPDATE SET
currency_name = excluded.currency_name,
symbol = excluded.symbol,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_customer_addresses (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.customer_addresses;
EXECUTE format('COPY staging.customer_addresses (address_id, customer_id, address_line, city, country, valid_from, valid_to) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.customer_addresses
(address_id, customer_id, address_line, city, country, valid_from, valid_to, dwh_load_date)
SELECT
address_id,
customer_id,
address_line,
city,
country,
valid_from,
valid_to,
CURRENT_TIMESTAMP
FROM staging.customer_addresses
ON CONFLICT (address_id) DO UPDATE SET
customer_id = excluded.customer_id,
address_line = excluded.address_line,
city = excluded.city,
country = excluded.country,
valid_from = excluded.valid_from,
valid_to = excluded.valid_to,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_customer_contacts (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.customer_contacts;
EXECUTE format('COPY staging.customer_contacts (contact_id, customer_id, phone, email, valid_from, valid_to) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.customer_contacts
(contact_id, customer_id, phone, email, valid_from, valid_to, dwh_load_date)
SELECT
contact_id,
customer_id,
phone,
email,
valid_from,
valid_to,
CURRENT_TIMESTAMP
FROM staging.customer_contacts
ON CONFLICT (contact_id) DO UPDATE SET
customer_id = excluded.customer_id,
phone = excluded.phone,
email = excluded.email,
valid_from = excluded.valid_from,
valid_to = excluded.valid_to,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_customers (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.customers;
EXECUTE format('COPY staging.customers (customer_id, first_name, last_name, dob, status, created_at) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.customers
(customer_id, first_name, last_name, dob, status, created_at, dwh_load_date)
SELECT
customer_id,
first_name,
last_name,
dob,
status,
created_at,
CURRENT_TIMESTAMP
FROM staging.customers
ON CONFLICT (customer_id) DO UPDATE SET
first_name = excluded.first_name,
last_name = excluded.last_name,
dob = excluded.dob,
status = excluded.status,
created_at = excluded.created_at,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_merchant_categories (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.merchant_categories;
EXECUTE format('COPY staging.merchant_categories (category_id, category_name) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.merchant_categories
(category_id, category_name, dwh_load_date)
SELECT
category_id,
category_name,
CURRENT_TIMESTAMP
FROM staging.merchant_categories
ON CONFLICT (category_id) DO UPDATE SET
category_name = excluded.category_name,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_merchants (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.merchants;
EXECUTE format('COPY staging.merchants (merchant_id, name, category_id, city) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.merchants
(merchant_id, name, category_id, city, dwh_load_date)
SELECT
merchant_id,
name,
category_id,
city,
CURRENT_TIMESTAMP
FROM staging.merchants
ON CONFLICT (merchant_id) DO UPDATE SET
name = excluded.name,
category_id = excluded.category_id,
city = excluded.city,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_transaction_types (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.transaction_types;
EXECUTE format('COPY staging.transaction_types (transaction_type, description) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.transaction_types
(transaction_type, description, dwh_load_date)
SELECT
transaction_type,
description,
CURRENT_TIMESTAMP
FROM staging.transaction_types
ON CONFLICT (transaction_type) DO UPDATE SET
description = excluded.description,
dwh_load_date = CURRENT_TIMESTAMP;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_customer_changes (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.customer_changes;
EXECUTE format('COPY staging.customer_changes (change_id, customer_id, change_type, status, address_line, city, country, change_timestamp) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.customer_changes
(change_id, customer_id, change_type, status, address_line, city, country, change_timestamp, dwh_load_date)
SELECT
change_id,
customer_id,
change_type,
status,
address_line,
city,
country,
change_timestamp,
CURRENT_TIMESTAMP
FROM staging.customer_changes
ON CONFLICT(change_id) DO NOTHING;
END;
$$;


CREATE OR REPLACE PROCEDURE bronze.load_transactions (file_path TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
TRUNCATE staging.transactions;
EXECUTE format('COPY staging.transactions (transaction_id, transaction_timestamp, account_id, card_id, merchant_id, transaction_type, currency_code, amount, status) FROM %L WITH (FORMAT CSV, HEADER TRUE)', file_path);
INSERT INTO bronze.transactions
(transaction_id, transaction_timestamp, account_id, card_id, merchant_id, transaction_type, currency_code, amount, status, dwh_load_date)
SELECT
transaction_id,
transaction_timestamp,
account_id,
card_id,
merchant_id,
transaction_type,
currency_code,
amount,
status,
CURRENT_TIMESTAMP
FROM staging.transactions
ON CONFLICT(transaction_id) DO NOTHING;
END;
$$;
