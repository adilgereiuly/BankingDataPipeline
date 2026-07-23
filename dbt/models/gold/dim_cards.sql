{{ config(materialized='table') }}

WITH cards AS (
    SELECT * FROM {{ ref('cards') }}
),

bin_ranges AS (
    SELECT * FROM {{ ref('card_bin_ranges') }}
)

SELECT
    md5(c.card_id) AS card_sk,
    c.card_id,
    c.account_id,
    c.issued_date,
    c.status,
    b.product_name AS card_product_name,
    b.network,
    c.dwh_load_date
FROM cards c
LEFT JOIN bin_ranges b ON c.bin = b.bin
