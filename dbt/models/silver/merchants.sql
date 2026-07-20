WITH source AS (
    SELECT * FROM {{source('bronze', 'merchants')}}
)

SELECT
merchant_id,
name,
category_id,
city,
dwh_load_date
FROM source
