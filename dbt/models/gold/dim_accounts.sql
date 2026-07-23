{{ config(materialized='table') }}

WITH accounts AS (
    SELECT * FROM {{ ref('accounts') }}
),

products AS (
    SELECT * FROM {{ ref('account_products') }}
)

SELECT
    md5(a.account_id) AS account_sk,
    a.account_id,
    a.customer_id,
    a.currency_code,
    a.opened_date,
    a.status,
    p.product_name,
    p.default_currency,
    a.dwh_load_date
FROM accounts a
LEFT JOIN products p ON a.product_id = p.product_id
