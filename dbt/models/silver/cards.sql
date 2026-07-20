{{ config(
    materialized='incremental',
    unique_key='card_id',
    incremental_strategy='merge'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'cards') }}

    {% if is_incremental() %}
    WHERE dwh_load_date > (SELECT MAX(dwh_load_date) FROM {{ this }})
    {% endif %}
)


SELECT
card_id,
account_id,
bin,
CAST(issued_date AS DATE) AS issued_date,
status,
dwh_load_date
FROM source
