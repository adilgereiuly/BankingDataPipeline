{{ config(
    materialized='incremental',
    unique_key='transaction_id'
) }}

WITH transactions AS (
    SELECT * FROM {{ ref('transactions') }}

    {% if is_incremental() %}
    WHERE dwh_load_date > (SELECT MAX(dwh_load_date) FROM {{ this }})
    {% endif %}
),

types AS (
    SELECT * FROM {{ ref('transaction_types') }}
),

currencies AS (
    SELECT * FROM {{ ref('currencies') }}
),

accounts AS (
    SELECT * FROM {{ ref('dim_accounts') }}
),

customers AS (
    SELECT
        customer_id,
        customer_sk,
        status,
        address_line,
        city,
        country,
        phone,
        email,
        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY valid_from) = 1
            THEN '-infinity'::timestamptz
            ELSE valid_from
        END AS valid_from,
        valid_to
    FROM {{ ref('dim_customers') }}
)

SELECT
    t.transaction_id,
    t.transaction_timestamp,
    md5(t.account_id) AS account_sk,
    CASE WHEN t.card_id IS NULL OR t.card_id = '' THEN NULL ELSE md5(t.card_id) END AS card_sk,
    CASE WHEN t.merchant_id IS NULL OR t.merchant_id = '' THEN NULL ELSE md5(t.merchant_id) END AS merchant_sk,
    c.customer_sk,
    t.transaction_type,
    ty.description AS transaction_type_description,
    t.currency_code,
    cur.currency_name,
    t.amount,
    t.status,
    t.dwh_load_date
FROM transactions t
LEFT JOIN types ty ON t.transaction_type = ty.transaction_type
LEFT JOIN currencies cur ON t.currency_code = cur.currency_code
LEFT JOIN accounts a ON t.account_id = a.account_id
LEFT JOIN customers c
    ON a.customer_id = c.customer_id
    AND t.transaction_timestamp >= c.valid_from
    AND (c.valid_to IS NULL OR t.transaction_timestamp < c.valid_to)
