{{ config(materialized='table') }}

WITH merchants AS (
    SELECT * FROM {{ ref('merchants') }}
),

categories AS (
    SELECT * FROM {{ ref('merchant_categories') }}
)

SELECT
    md5(m.merchant_id) AS merchant_sk,
    m.merchant_id,
    m.name AS merchant_name,
    m.city,
    c.category_name,
    m.dwh_load_date
FROM merchants m
LEFT JOIN categories c ON m.category_id = c.category_id
