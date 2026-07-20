WITH source AS (
    SELECT * FROM {{source('bronze', 'transaction_types')}}
)

SELECT
transaction_type,
description,
dwh_load_date
FROM source
