{% snapshot addresses_snapshot %}

{{
    config(
        target_schema='silver',
        unique_key='customer_id',
        strategy='check',
        check_cols=['address_line', 'city', 'country']
    )
}}

SELECT * FROM {{ ref('addresses_current') }}

{% endsnapshot %}
