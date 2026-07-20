WITH source AS (
    SELECT * FROM {{ source('bronze', 'account_products') }}
)


SELECT
product_id,
product_name,
default_currency,
dwh_load_date
FROM source
