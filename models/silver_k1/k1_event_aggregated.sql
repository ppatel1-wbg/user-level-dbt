-- Hourly event aggregation: one row per active user per hour.
-- Translation of data-cache-manual.ipynb cells 18-20, but replaces the
-- notebook's pandas_udf-based first_by_epoch/last_by_epoch (which need a
-- live Spark session and can't run against a SQL Warehouse -- see notes.md
-- section 7b) with a pure-SQL rewrite: min_by/max_by + FILTER (WHERE ...)
-- to ignore NULLs, per notes.md section 7b Option A.

{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['platform_account_id', 'hydra_public_id', 'wba_date', 'hr'],
    cluster_by=['wba_date', 'hr']
  )
}}

select
    'k1' as game_code,
    platform_account_id,
    hydra_public_id,
    max_by(platform_name, wb_source_epoch) filter (where platform_name is not null) as platform_name,
    min_by(platform_name, wb_source_epoch) filter (where platform_name is not null) as first_platform,
    max_by(platform_name, wb_source_epoch) filter (where platform_name is not null) as last_platform,
    min(wb_source_epoch) as install_ts,
    max(wb_source_epoch) as last_seen_ts,
    wba_date,
    hr
from {{ ref('stg_k1_activity_begin') }}
where platform_account_id is not null
{% if is_incremental() %}
  -- only reprocess hours newer than what's already loaded
  and wba_date >= (select coalesce(max(wba_date), '19700101') from {{ this }})
{% endif %}
group by platform_account_id, hydra_public_id, wba_date, hr
