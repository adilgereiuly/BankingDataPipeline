SELECT *
FROM {{ ref('fact_transactions') }}
WHERE customer_sk IS NULL
