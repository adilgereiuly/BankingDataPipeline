WITH source AS (
    SELECT * FROM {{source('bronze', 'currencies')}}
)

SELECT
currency_code,
currency_name,
symbol,
dwh_load_date
FROM source
