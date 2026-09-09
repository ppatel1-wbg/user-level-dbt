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

This is the easiest path when PATs are disabled and you don't have (or don't
want to wait on) a service principal. It authenticates as *you*, via a
one-time browser login, the same way `databricks auth login` works.

`dbt init`'s interactive wizard does **not** offer this as a menu option —
you have to hand-write it into `~/.dbt/profiles.yml`:

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