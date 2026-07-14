-- =============================================================================
-- Bronze Layer DDL
-- Project: Banking Data Pipeline
-- Purpose: Raw landing tables — one per source entity, mirrors incoming CSV
--          structure exactly (no type casting, no constraints beyond PK)
-- =============================================================================


CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.account_products (
    product_id VARCHAR(255) PRIMARY KEY,
    product_name VARCHAR(255),
    default_currency VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.accounts (
    account_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    product_id VARCHAR(255),
    currency_code VARCHAR(255),
    opened_date VARCHAR(255),
    status VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.card_bin_ranges (
    bin VARCHAR(255) PRIMARY KEY,
    product_name VARCHAR(255),
    network VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.cards (
    card_id VARCHAR(255) PRIMARY KEY,
    account_id VARCHAR(255),
    bin VARCHAR(255),
    issued_date VARCHAR(255),
    status VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.currencies (
    currency_code VARCHAR(255) PRIMARY KEY,
    currency_name VARCHAR(255),
    symbol VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.customer_addresses (
    address_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    address_line VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    valid_from VARCHAR(255),
    valid_to VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.customer_contacts (
    contact_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    phone VARCHAR(255),
    email VARCHAR(255),
    valid_from VARCHAR(255),
    valid_to VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.customers (
    customer_id VARCHAR(255) PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    dob VARCHAR(255),
    status VARCHAR(255),
    created_at VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.merchant_categories (
    category_id VARCHAR(255) PRIMARY KEY,
    category_name VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.merchants (
    merchant_id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    category_id VARCHAR(255),
    city VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.transaction_types (
    transaction_type VARCHAR(255) PRIMARY KEY,
    description VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.transactions (
    transaction_id VARCHAR(255) PRIMARY KEY,
    transaction_timestamp VARCHAR(255),
    account_id VARCHAR(255),
    card_id VARCHAR(255),
    merchant_id VARCHAR(255),
    transaction_type VARCHAR(255),
    currency_code VARCHAR(255),
    amount VARCHAR(255),
    status VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.customer_changes (
    change_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    change_type VARCHAR(255),
    status VARCHAR(255),
    address_line VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    change_timestamp VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


