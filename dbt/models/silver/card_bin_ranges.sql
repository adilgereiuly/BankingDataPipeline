WITH source AS (
    SELECT * FROM {{source('bronze', 'card_bin_ranges')}}
)

SELECT
bin,
product_name,
network,
dwh_load_date
FROM source
