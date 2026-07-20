WITH source AS (
    SELECT * FROM {{source('bronze', 'merchant_categories')}}
)

SELECT
category_id,
category_name,
dwh_load_date
FROM source
