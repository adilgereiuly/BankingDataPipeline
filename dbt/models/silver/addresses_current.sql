WITH base AS (
    SELECT
        address_id,
        customer_id,
        address_line AS original_address_line,
        city AS original_city,
        country AS original_country,
        CAST(valid_from AS DATE) AS created_at
    FROM {{ source('bronze', 'customer_addresses') }}
),

latest_address_change AS (
    SELECT DISTINCT ON (customer_id)
        customer_id,
        address_line AS latest_address_line,
        city AS latest_city,
        country AS latest_country
    FROM {{ source('bronze', 'customer_changes') }}
    WHERE change_type = 'address'
    ORDER BY customer_id, change_timestamp DESC
)

SELECT
    b.customer_id,
    REGEXP_REPLACE(COALESCE(c.latest_address_line, b.original_address_line), '\d+', '###', 'g') AS address_line,
    COALESCE(c.latest_city, b.original_city) AS city,
    COALESCE(c.latest_country, b.original_country) AS country,
    b.created_at
FROM base b
LEFT JOIN latest_address_change c ON b.customer_id = c.customer_id
