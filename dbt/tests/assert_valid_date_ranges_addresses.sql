SELECT *
FROM {{ ref('addresses_snapshot') }}
WHERE dbt_valid_to IS NOT NULL
  AND dbt_valid_to <= dbt_valid_from
