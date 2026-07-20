{{ config(
    materialized='incremental',
    unique_key='transaction_id',
    incremental_strategy='append'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'transactions') }}

    {% if is_incremental() %}
    WHERE dwh_load_date > (SELECT MAX(dwh_load_date) FROM {{ this }})
    {% endif %}
)

SELECT
    transaction_id,
    CAST(transaction_timestamp AS TIMESTAMPTZ) AS transaction_timestamp,
    account_id,
    card_id,
    merchant_id,
    transaction_type,
    currency_code,
    CAST(amount AS NUMERIC(12,2)) AS amount,
    status,
    dwh_load_date
FROM source
