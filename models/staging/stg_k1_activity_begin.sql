-- Denormalized view over raw k1_activity_begin telemetry.
-- Direct translation of data-cache-manual.ipynb, cell 4:
--   simple renames + flattening, one row in == one row out.
-- No filtering/aggregation here on purpose -- keep this layer "dumb" so
-- every downstream model reads consistent, friendly column names.

select
    _platform_account_id as platform_account_id,
    _hydra_public_id      as hydra_public_id,
    _platform_name        as platform_name,
    _session_id           as session_id,
    unix_timestamp(wbanalyticssourcedate) as wb_source_epoch,
    wba_date,
    hr
from {{ source('k1_raw', 'k1_activity_begin') }}
