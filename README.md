# Data Cache DBT Design

This is simple DBT project to showcase how to use DBT to build models on Databricks platform using OAuth for local run.

## Prerequisites

- Python 3
- Code Editor
- Databricks account

## Set up

1. Create environment for your DBT project using below instructions.

```shell
pyenv local 3.11.11
python --version
pyenv virtualenv dbt-env
pyenv activate dbt-env

pip install --upgrade pip
pip install -r requirements.txt
dbt --version
```

### Using OAuth

Manually create a file at `~/.dbt/profiles.yml` with below content:

```yaml
user_level_dbt:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: wba_sandbox
      schema: default
      host: <your-workspace-hostname>.cloud.databricks.com
      http_path: /sql/1.0/warehouses/<your-warehouse-id>
      auth_type: oauth
      threads: 4
```

Verify the connection:

```shell
dbt debug
```

## Project structure


```
models/
  staging/            -- wba_sandbox.default   (views, 1:1 with raw sources)
    stg_k1_activity_begin.sql
  silver_k1/          -- wba_sandbox.silver_k1  (incremental, one row per user per hour)
    k1_event_aggregated.sql
  gold_k1/            -- wba_sandbox.gold_k1    (incremental, one row per user, ever)
    k1_user_level_activity_begin.sql
tests/
  generic/            -- reusable custom test macros (e.g. install_before_last_seen)
  assert_*.sql        -- singular tests, incl. a regression test for a specific
                          NULL-handling bug found in data-cache-manual.ipynb
macros/
  generate_schema_name.sql  -- makes +schema: map exactly to wba_sandbox.<schema>,
                                instead of dbt's usual <target_schema>_<custom_schema>
```

Data flows `staging -> silver_k1 -> gold_k1`.

## Commands

```shell
# Confirm your connection/credentials are working
dbt debug

# Check everything parses/compiles without touching the warehouse
dbt parse
dbt compile

# Build just the staging layer (cheap, always safe to re-run -- it's a view)
dbt run --select staging

# First-ever build of silver/gold: these tables already exist in Databricks
# from manually running data-cache-manual.ipynb, with a different schema
# than dbt produces, so the very first dbt build of each must use
# --full-refresh to drop and recreate them cleanly:
dbt run --select k1_event_aggregated --full-refresh
dbt run --select k1_user_level_activity_begin --full-refresh

# Every run after that: normal incremental merge, respecting dependency
# order (staging -> silver_k1 -> gold_k1)
dbt run

# Build a model and everything downstream of it
dbt run --select k1_event_aggregated+

# Run the test suite (schema tests + singular regression tests)
dbt test

# Build + test in one go -- the command you'll use day to day
dbt build

# Preview a model's output without materializing it
dbt show --select stg_k1_activity_begin --limit 10

# Browse column-level docs and the staging -> silver -> gold lineage graph
dbt docs generate && dbt docs serve
```

