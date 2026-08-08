-- Maps every source's own channel and medium naming onto one consistent
-- taxonomy. This mapping table is the piece that actually makes cross-source
-- joins reliable, populate it with every raw label variant found in the data,
-- not just the obvious ones.

with channel_mapping as (

    select * from (
        values
            ('google ads', 'cpc', 'google_ads', 'paid_search'),
            ('googleads', 'ppc', 'google_ads', 'paid_search'),
            ('meta', 'paid_social', 'meta_ads', 'paid_social'),
            ('facebook ads', 'cpc', 'meta_ads', 'paid_social'),
            ('hubspot', 'email', 'hubspot', 'email'),
            ('organic', 'organic', 'organic_search', 'organic_search'),
            ('(direct)', '(none)', 'direct', 'direct'),
            ('linkedin', 'paid_social', 'linkedin_ads', 'paid_social')
    ) as t(raw_source, raw_medium, standard_channel, standard_medium)

),

raw_events as (

    select
        source_system,
        raw_source,
        raw_medium,
        event_id,
        event_timestamp
    from {{ source('raw', 'all_marketing_events') }}

),

standardized as (

    select
        r.source_system,
        r.event_id,
        r.event_timestamp,
        coalesce(m.standard_channel, 'unmapped: ' || lower(r.raw_source)) as standard_channel,
        coalesce(m.standard_medium, 'unmapped: ' || lower(r.raw_medium)) as standard_medium

    from raw_events r
    left join channel_mapping m
        on lower(r.raw_source) = m.raw_source
        and lower(r.raw_medium) = m.raw_medium

)

select * from standardized
