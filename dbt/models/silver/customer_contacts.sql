WITH source AS (
    SELECT * FROM {{ source('bronze', 'customer_contacts') }}
)

SELECT
    contact_id,
    customer_id,
    REPEAT('*', GREATEST(LENGTH(phone) - 4, 0)) || RIGHT(phone, 4) AS phone,
    LEFT(email, 1) || '***@' || SPLIT_PART(email, '@', 2) AS email,
    CAST(valid_from AS DATE) AS valid_from,
    CAST(valid_to AS DATE) AS valid_to,
    dwh_load_date
FROM source
