-- Custom generic test: asserts install_ts (or equivalent "first seen"
-- column) is never later than last_seen_ts (or equivalent "last seen"
-- column) for the same row.
--
-- This encodes an invariant both k1_event_aggregated and
-- k1_user_level_activity_begin depend on: install_ts only ever moves
-- earlier (LEAST) and last_seen_ts only ever moves later (GREATEST), so
-- install_ts > last_seen_ts should be structurally impossible. If this test
-- ever fails, it means the incremental merge logic in notes.md section 7d
-- has a bug (e.g. LEAST/GREATEST applied to the wrong columns, or a stale
-- {{ this }} snapshot).
--
-- Usage in schema.yml:
--   data_tests:
--     - install_before_last_seen:
--         install_column: install_ts
--         last_seen_column: last_seen_ts

{% test install_before_last_seen(model, install_column, last_seen_column) %}

select *
from {{ model }}
where {{ install_column }} > {{ last_seen_column }}

{% endtest %}
