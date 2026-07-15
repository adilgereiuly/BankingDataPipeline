
-- =============================================================================
-- Silver Layer DDL
-- Purpose: 
-- Cleansed, correctly-typed tables built from Bronze. Casts raw text into real types (DATE, TIMESTAMPTZ, NUMERIC), and historizes
-- customers and customer_addresses via SCD2 using the seed snapshot plus the customer_changes event stream.

CREATE SCHEMA IF NOT EXISTS silver;

CREATE TABLE IF NOT EXISTS silver.account_products (
    product_id VARCHAR(255) PRIMARY KEY,
    product_name VARCHAR(255),
    default_currency VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.accounts (
    account_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    product_id VARCHAR(255),
    currency_code VARCHAR(255),
    opened_date DATE,
    status VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.card_bin_ranges (
    bin VARCHAR(255) PRIMARY KEY,
    product_name VARCHAR(255),
    network VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.cards (
    card_id VARCHAR(255) PRIMARY KEY,
    account_id VARCHAR(255),
    bin VARCHAR(255),
    issued_date DATE,
    status VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.currencies (
    currency_code VARCHAR(255) PRIMARY KEY,
    currency_name VARCHAR(255),
    symbol VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.customer_addresses (
    addresses_sk INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_id VARCHAR(255),
    customer_id VARCHAR(255),
    address_line VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    valid_from DATE,
    valid_to DATE,
    is_current BOOLEAN DEFAULT TRUE,
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.customer_contacts (
    contact_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    phone VARCHAR(255),
    email VARCHAR(255),
    valid_from DATE,
    valid_to DATE,
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.customers (
    customers_sk INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    dob DATE,
    status VARCHAR(255),
    created_at TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    valid_from DATE,
    valid_to DATE,
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.merchant_categories (
    category_id VARCHAR(255) PRIMARY KEY,
    category_name VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.merchants (
    merchant_id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    category_id VARCHAR(255),
    city VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.transaction_types (
    transaction_type VARCHAR(255) PRIMARY KEY,
    description VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.transactions (
    transaction_id VARCHAR(255) PRIMARY KEY,
    transaction_timestamp TIMESTAMPTZ,
    account_id VARCHAR(255),
    card_id VARCHAR(255),
    merchant_id VARCHAR(255),
    transaction_type VARCHAR(255),
    currency_code VARCHAR(255),
    amount NUMERIC(12,2),
    status VARCHAR(255),
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.customer_changes (
    change_id VARCHAR(255) PRIMARY KEY,
    customer_id VARCHAR(255),
    change_type VARCHAR(255),
    status VARCHAR(255),
    address_line VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    change_timestamp TIMESTAMPTZ,
    dwh_load_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
