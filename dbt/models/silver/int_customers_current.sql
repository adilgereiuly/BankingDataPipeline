WITH base AS (
    SELECT
        customer_id,
        LEFT(first_name, 1) || REPEAT('*', GREATEST(LENGTH(first_name) - 1, 0)) AS first_name,
        LEFT(last_name, 1) || REPEAT('*', GREATEST(LENGTH(last_name) - 1, 0)) AS last_name,
        CASE
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, CAST(dob AS DATE))) < 25 THEN '18-24'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, CAST(dob AS DATE))) < 35 THEN '25-34'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, CAST(dob AS DATE))) < 45 THEN '35-44'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, CAST(dob AS DATE))) < 55 THEN '45-54'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, CAST(dob AS DATE))) < 65 THEN '55-64'
            ELSE '65+'
        END AS dob,
        status AS original_status,
        CAST(created_at AS TIMESTAMPTZ) AS created_at
    FROM {{ source('bronze', 'customers') }}
),

latest_status_change AS (
    SELECT DISTINCT ON (customer_id)
        customer_id,
        status AS latest_status
    FROM {{ source('bronze', 'customer_changes') }}
    WHERE change_type = 'status'
    ORDER BY customer_id, change_timestamp DESC
)

SELECT
    b.customer_id,
    b.first_name,
    b.last_name,
    b.dob,
    COALESCE(c.latest_status, b.original_status) AS status,
    b.created_at
FROM base b
LEFT JOIN latest_status_change c ON b.customer_id = c.customer_id
