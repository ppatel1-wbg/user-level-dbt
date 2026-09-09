-- User-level lifetime snapshot: one row per user, ever.
-- Translation of data-cache-manual.ipynb cells 27-29.
--
-- Faithfully reproduces the notebook's FULL JOIN ... snapshot logic (first
-- seen platform/install_ts are "sticky" -- never overwritten once set;
-- last seen platform/last_seen_ts are "latest wins"), but keeps it
-- genuinely incremental: the left join against {{ this }} only touches
-- users who had new activity this run, it does not rescan the whole gold
-- table. See notes.md section 7d for the full reasoning.

{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['platform_account_id', 'hydra_public_id'],
    cluster_by=['platform_account_id', 'hydra_public_id']
  )
}}

with new_activity as (

    select
        game_code,
        platform_account_id,
        hydra_public_id,
        max_by(platform_name, wba_date) filter (where platform_name is not null) as platform_name,
        min_by(platform_name, wba_date) filter (where platform_name is not null) as first_platform,
        max_by(platform_name, wba_date) filter (where platform_name is not null) as last_platform,
        min(install_ts) as install_ts,
        max(last_seen_ts) as last_seen_ts
    from {{ ref('k1_event_aggregated') }}
    {% if is_incremental() %}
    -- only scan silver hours not yet reflected in gold -- keeps this a
    -- cheap incremental read, not a rescan of full history
    where wba_date >= (
        select coalesce(date_format(max(last_seen_ts), 'yyyyMMdd'), '19700101')
        from {{ this }}
    )
    {% endif %}
    group by game_code, platform_account_id, hydra_public_id

)

{% if is_incremental() %}

-- combine this run's new activity against each user's existing gold row --
-- same semantics as cell 29's FULL JOIN, but scoped to users with new
-- activity this run (untouched existing users are left alone entirely)
select
    n.game_code,
    n.platform_account_id,
    n.hydra_public_id,
    coalesce(n.platform_name, e.platform_name) as platform_name,
    coalesce(e.first_platform, n.first_platform) as first_platform,
    coalesce(n.last_platform, e.last_platform) as last_platform,
    least(n.install_ts, e.install_ts) as install_ts,
    greatest(n.last_seen_ts, e.last_seen_ts) as last_seen_ts
from new_activity n
left join {{ this }} e
    on n.platform_account_id = e.platform_account_id
   and n.hydra_public_id = e.hydra_public_id

{% else %}

-- first-ever build (or --full-refresh): no prior snapshot to merge against,
-- new_activity already covers full history so it *is* the final answer
select * from new_activity

{% endif %}
