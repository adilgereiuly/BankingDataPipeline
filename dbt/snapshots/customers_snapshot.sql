{% snapshot customers_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='customer_id',
        strategy='check',
        check_cols=['status']
    )
}}

SELECT * FROM {{ ref('int_customers_current') }}

{% endsnapshot %}
