SELECT *
FROM {{ ref('transactions') }}
WHERE transaction_type = 'purchase'
  AND (card_id IS NULL OR merchant_id IS NULL)
