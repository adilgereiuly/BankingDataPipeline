{{ config(
    materialized='incremental',
    unique_key='account_id',
    incremental_strategy='merge'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'accounts') }}

    {% if is_incremental() %}
    WHERE dwh_load_date > (SELECT MAX(dwh_load_date) FROM {{ this }})
    {% endif %}
)

SELECT
    account_id,
    customer_id,
    product_id,
    currency_code,
    CAST(opened_date AS DATE) AS opened_date,
    status,
    dwh_load_date
FROM source
