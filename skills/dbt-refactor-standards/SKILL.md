# dbt Refactor Standards

This skill provides reference standards for dbt model development as part of the dbt refactor initiative.

## Layer Structure

Our dbt project follows a four-layer architecture:

| Layer | Naming | Primary Key? | Materialization | Example |
|-------|--------|--------------|----------------|---------|
| **Base** | `base_<model_name>` | No | Ephemeral | `base_corporations_corporations` |
| **Transform** | `transform_<model_name>_<action>` | No | Table | `transform_fund_partner_contribute` |
| **Core - Dim** | `core_dim_<entity>` | Yes | Table | `core_dim_zuora_subscriptions` |
| **Core - Fact** | `core_fct_<entity>` | Yes | Table | `core_fct_zuora_arr` |
| **Mart** | `mart_[temporal]_<entity>` | Yes | Table | `mart_daily_revenue`, `core_fund_admin_firms` |

## Layer Flow Rules

```
base → transform → core → mart
```

**Critical Rules:**
- Mart models MUST ONLY reference core models (never transform)
- Transform can reference base or other transform models
- Core models are the single source of truth

## Directory Structure

```
models/
├── scratch/          # Innovation zone - fast development, can cut corners
└── verified/         # Production quality - strict standards required
    └── <domain>/
        ├── base/
        ├── transform/
        ├── core/
        └── mart/
```

**Choose scratch/ for:** Prototyping, fast iteration, exploratory analysis, short-term projects

**Choose verified/ for:** Production-critical metrics, high downstream impact, long-term maintenance, executive visibility

## Naming Convention for verified/ Models

**CRITICAL**: All models in `verified/` directory must include `_v2` suffix until migration is complete.

**Examples:**
- `base_corporations_corporations_v2`
- `transform_fund_partner_contribute_v2`
- `core_dim_users_v2`
- `core_fct_transactions_v2`
- `mart_daily_revenue_v2`

This allows coexistence of old and new models during the migration period.

## Testing Requirements by Layer

| Layer | Required Tests |
|-------|---------------|
| Base | None (ephemeral) |
| Transform | **unique + not_null on unique_key** (enforced by CI) |
| Core | unique + not_null on PK, referential integrity |
| Mart | unique + not_null on PK, referential integrity |

**CRITICAL**: Transform models MUST have tests on their `unique_key` field to pass CI pre-commit hooks:
- `check-model-has-tests-by-name` requires at least 1 `not_null` test
- `check-model-has-tests-by-group` requires at least 1 test from `['unique', 'unique_combination_of_columns']`

**Always add these tests BEFORE pushing to PR** to avoid CI failures.

## Configuration Requirements

**For Core & Mart models**, add cluster_by configuration:

```yaml
models:
  - name: core_dim_users
    config:
      cluster_by: ['primary_key_field']
    columns:
      - name: user_id
        data_tests:
          - unique
          - not_null
```

## Special Cases: Snapshots and Incremental Models

**CRITICAL**: Snapshots and incremental models CANNOT be automatically refactored/migrated.

**Why?** These models contain historical data that cannot be recreated from source:
- **Snapshots**: Track slowly changing dimensions over time
- **Incremental models**: Accumulate historical records day-by-day

**Migration Process:**
1. **DO NOT** attempt to migrate these models yourself
2. **STOP** and identify the model is a snapshot or incremental (check config for `materialized = 'snapshot'` or `materialized = 'incremental'`)
3. **INSTRUCT** the user: "This model requires a production data backfill. Please reach out to the Data Engineering team with the model name to request a migration script."
4. **WAIT** for Data Engineering to provide a backfill script that clones historical data from production to the new _v2 table

**How to Identify:**
```sql
-- Incremental model
{{
  config(
    materialized = 'incremental'
  )
}}

-- Snapshot model (in snapshots/ directory)
{% snapshot snapshot_name %}
  {{
    config(
      strategy='timestamp',
      updated_at='updated_at'
    )
  }}
{% endsnapshot %}
```

## Documentation Standards

All models must include:
- Model description (grain and intended use case)
- Column descriptions for all columns
- Primary key description
- In-line code descriptions for SQL conditions

## Common Model Examples

**Base**: `base_corporations_corporations` - Raw data with minimal transformations

**Transform**: 
- `transform_fund_partner_contribute` - Fund partner contribution transformations
- `transform_earliest_audit_timestamp` - Finding earliest audit timestamps

**Core**:
- `core_dim_zuora_subscriptions` - All contextual details surrounding subscriptions
- `core_fct_zuora_arr` - Daily ARR for rate plans linking back to subscriptions

**Mart**: `core_fund_admin_firms` - Analytics-ready firm data (OBT joining dims/facts)

---

**Reference**: [dbt Refactor Confluence](https://carta1.atlassian.net/wiki/spaces/AE/pages/3871244324)