SELECT *
FROM {{ ref('transactions') }}
WHERE transaction_type != 'purchase'
  AND merchant_id IS NOT NULL
