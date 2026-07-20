WITH source AS (
    SELECT * FROM {{ source('bronze', 'customer_changes') }}
)

SELECT
    change_id,
    customer_id,
    change_type,
    status,
    address_line,
    city,
    country,
    CAST(change_timestamp AS TIMESTAMPTZ) AS change_timestamp,
    dwh_load_date
FROM source
