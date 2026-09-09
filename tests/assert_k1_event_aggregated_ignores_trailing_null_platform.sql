-- Regression test for the exact bug data-cache-manual.ipynb cells 10-16
-- called out: a naive min_by/max_by(platform_name, wb_source_epoch) returns
-- NULL for last_platform when the chronologically-last event in the window
-- happens to have a NULL platform_name, because plain min_by/max_by don't
-- ignore NULLs.
--
-- Fixture (seed.ipynb, k1_activity_begin): hydra_k1_015 on wba_date
-- 20260110, hr 09 has three events:
--   09:00  platform_name = 'switch'
--   09:20  platform_name = 'steam'
--   09:32  platform_name = NULL   <- chronologically last, but NULL
--
-- The FILTER-based rewrite in k1_event_aggregated (notes.md section 7b,
-- Option A) must ignore that trailing NULL and still resolve:
--   first_platform = 'switch' (first non-null)
--   last_platform / platform_name = 'steam' (last non-null)
--
-- This test fails (returns a row) if that resolution is wrong.

select *
from {{ ref('k1_event_aggregated') }}
where hydra_public_id = 'hydra_k1_015'
  and wba_date = '20260110'
  and hr = '09'
  and (
    platform_name is distinct from 'steam'
    or last_platform is distinct from 'steam'
    or first_platform is distinct from 'switch'
  )
