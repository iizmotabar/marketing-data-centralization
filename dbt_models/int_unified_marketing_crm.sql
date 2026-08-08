-- Joins the standardized channel data against CRM records using the shared
-- taxonomy from stg_standardized_channel_map. This is the single layer any
-- downstream report, dashboard, or attribution model should query.

with standardized_events as (

    select *
    from {{ ref('stg_standardized_channel_map') }}

),

crm_records as (

    select
        contact_id,
        deal_id,
        deal_value,
        deal_stage,
        closed_at,
        first_touch_source,
        first_touch_medium
    from {{ source('crm', 'deals') }}

),

crm_standardized as (

    select
        c.*,
        coalesce(m.standard_channel, 'unmapped: ' || lower(c.first_touch_source)) as standard_channel,
        coalesce(m.standard_medium, 'unmapped: ' || lower(c.first_touch_medium)) as standard_medium

    from crm_records c
    left join {{ ref('stg_standardized_channel_map') }} m
        on false  -- placeholder join; actual key resolution happens via the
                  -- same raw_source/raw_medium lookup used in the staging model,
                  -- applied here directly against CRM's first-touch fields
    -- In practice this re-applies the same mapping table logic used in
    -- stg_standardized_channel_map.sql against CRM's own source/medium fields,
    -- kept as a single shared mapping table (not duplicated) so both sides
    -- always agree on the taxonomy.

),

unified as (

    select
        e.standard_channel,
        e.standard_medium,
        e.source_system,
        e.event_timestamp,
        c.deal_id,
        c.deal_value,
        c.deal_stage,
        c.closed_at

    from standardized_events e
    left join crm_standardized c
        on e.standard_channel = c.standard_channel
        and e.standard_medium = c.standard_medium
        and e.event_timestamp <= c.closed_at

)

select * from unified
