-- stg_k1_activity_begin is a pure rename/flatten passthrough (no filtering,
-- no aggregation -- see notes.md section 7a). Its row count must exactly
-- match the raw source, or something upstream (a join, a filter added by
-- accident) has silently changed the shape of this layer.

with src as (
    select count(*) as cnt from {{ source('k1_raw', 'k1_activity_begin') }}
),

stg as (
    select count(*) as cnt from {{ ref('stg_k1_activity_begin') }}
)

select
    src.cnt as source_row_count,
    stg.cnt as staging_row_count
from src
cross join stg
where src.cnt != stg.cnt
