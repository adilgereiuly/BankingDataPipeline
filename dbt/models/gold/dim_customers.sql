{{ config(materialized='table') }}

WITH customers AS (
    SELECT * FROM {{ ref('customers_snapshot') }}
),

addresses AS (
    SELECT * FROM {{ ref('addresses_snapshot') }}
),

contacts AS (
    SELECT * FROM {{ ref('customer_contacts') }}
),

change_points AS (
    SELECT customer_id, dbt_valid_from AS change_at FROM customers
    UNION
    SELECT customer_id, dbt_valid_from AS change_at FROM addresses
),

combined AS (
    SELECT
        cp.customer_id,
        cp.change_at AS valid_from,
        LEAD(cp.change_at) OVER (PARTITION BY cp.customer_id ORDER BY cp.change_at) AS valid_to,
        c.first_name,
        c.last_name,
        c.dob,
        c.status,
        a.address_line,
        a.city,
        a.country
    FROM change_points cp
    LEFT JOIN customers c
        ON cp.customer_id = c.customer_id
        AND cp.change_at >= c.dbt_valid_from
        AND (c.dbt_valid_to IS NULL OR cp.change_at < c.dbt_valid_to)
    LEFT JOIN addresses a
        ON cp.customer_id = a.customer_id
        AND cp.change_at >= a.dbt_valid_from
        AND (a.dbt_valid_to IS NULL OR cp.change_at < a.dbt_valid_to)
)

SELECT
    md5(combined.customer_id || combined.valid_from::text) AS customer_sk,
    combined.customer_id,
    combined.first_name,
    combined.last_name,
    combined.dob,
    combined.status,
    combined.address_line,
    combined.city,
    combined.country,
    ct.phone,
    ct.email,
    combined.valid_from,
    combined.valid_to,
    (combined.valid_to IS NULL) AS is_current
FROM combined
LEFT JOIN contacts ct ON combined.customer_id = ct.customer_id
