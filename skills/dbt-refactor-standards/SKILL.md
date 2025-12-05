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

## Domain Separation

**CRITICAL**: Verified models can ONLY reference other verified models. Scratch models can ONLY reference other scratch models.

**Wrong:**
```sql
-- models_verified/transform/model.sql
{{ ref('base_model') }}  -- ❌ References scratch base
```

**Right:**
```sql
-- models_verified/transform/model.sql
{{ ref('base_model') }}  -- ✅ References verified base (same name, different directory)

-- models_scratch/transform/model_scratch.sql
{{ ref('base_model_scratch') }}  -- ✅ References scratch base
```

This means when migrating a model to verified/, you MUST also migrate all its dependencies to verified/ (base models, transform models, etc.).

## File Creation Best Practices

**NEVER copy files from scratch/ to verified/.** Always create NEW files.

**For Scratch Models:**
- RENAME with `git mv` to `_scratch` suffix
- ADD `alias` config to preserve Snowflake table names
- UPDATE internal refs to other `_scratch` models

**For Verified Models:**
- CREATE NEW FILES in verified/ directory
- READ scratch version to understand business logic
- WRITE SQL from understanding (not copy-paste)
- FOLLOW verified/ styleguide and conventions

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

**Production Names**: All models in `verified/` directory use clean production names (no version suffixes).

**Examples:**
- `base_corporations_corporations`
- `transform_fund_partner_contribute`
- `core_dim_users`
- `core_fct_transactions`
- `mart_daily_revenue`

**Scratch Models**: When migrating to verified/, scratch versions are renamed with `_scratch` suffix and use `alias` config to preserve table names:
- `base_corporations_corporations_scratch` (with `alias='base_corporations_corporations'`)

This allows coexistence during migration while maintaining clean production names.

## Verified Model Standards (CRITICAL)

**These rules are STRICTLY ENFORCED for models in `models_verified/` directory.**

### Rule 1: NO Alias Configs in Verified Models

**Rationale**: In verified/, the filename IS the table name. Using `alias` configs breaks this contract and causes confusion.

**Wrong ❌:**
```sql
-- models_verified/base/revenue_service/base_revenue_service_charge.sql
{{
  config(
    alias='revenue_service_charge',  -- ❌ NEVER in verified/
    materialized='ephemeral'
  )
}}
```

**Right ✅:**
```sql
-- models_verified/base/revenue_service/base_revenue_service_charge.sql
{{
  config(
    materialized='ephemeral'
  )
}}

-- Snowflake table name: base_revenue_service_charge (matches filename)
```

**Scratch models only:**
```sql
-- models_scratch/base/base_revenue_service_charge_scratch.sql
{{ config(alias='base_revenue_service_charge') }}  -- ✅ OK in scratch/
{{
  config(
    materialized='ephemeral'
  )
}}
```

### Rule 2: NO SELECT * in Verified Models

**Rationale**: SELECT * creates fragile dependencies. If upstream schema changes, verified models break unexpectedly. Explicit columns make dependencies clear and prevent downstream breakage.

**Wrong ❌:**
```sql
-- models_verified/transform/model.sql
WITH base AS (
  SELECT *  -- ❌ NEVER in verified/
  FROM {{ ref('base_model') }}
)
SELECT * FROM base  -- ❌ NEVER in verified/
```

**Right ✅:**
```sql
-- models_verified/transform/model.sql
WITH base AS (
  SELECT
    subscription_id
    , yearly_value_cents_net
    , tier
    , created_at
  FROM {{ ref('base_model') }}
)
SELECT
  subscription_id
  , yearly_value_cents_net
  , tier
  , created_at
FROM base
```

### Rule 3: Timestamp Column Naming in Base Models

**Rationale**: All timestamp columns in verified base models MUST use `_at` suffix for clarity and consistency. Without this convention, `created` could be ambiguous (boolean flag? date? timestamp?), whereas `created_at` is unambiguous.

**This rule applies ONLY to base models** - transform, core, and mart layers inherit whatever column names come from upstream.

**Wrong ❌:**
```sql
-- models_verified/base/banking/base_banking_account.sql
SELECT
  id,
  created::timestamp_ntz as created,  -- ❌ Missing _at suffix
  modified::timestamp_ntz as modified,  -- ❌ Missing _at suffix
  updated::timestamp as updated  -- ❌ Missing _at suffix
FROM {{ source('raw_banking', 'account') }}
```

**Right ✅:**
```sql
-- models_verified/base/banking/base_banking_account.sql
SELECT
  id,
  created::timestamp_ntz as created_at,  -- ✅ Clear timestamp column
  modified::timestamp_ntz as modified_at,  -- ✅ Clear timestamp column
  updated::timestamp as updated_at  -- ✅ Clear timestamp column
FROM {{ source('raw_banking', 'account') }}
```

**Validation:**
```bash
# Check all verified base models for timestamp naming violations
validate-timestamp-naming --directory models/models_verified/base
```

**See also**: `~/.claude/skills/timestamp-naming-standards/SKILL.md` for comprehensive examples and patterns.

### Validation Command

Before committing verified/ models, run:
```bash
validate-verified-standards
```

This checks:
- ✅ No alias configs in verified/
- ✅ No SELECT * in verified/
- ✅ All SQL files have matching YAML
- ✅ All models have descriptions
- ✅ YAML names match filenames
- ✅ No orphaned YAML files
- ✅ dbt parse succeeds

**Example from DA-4090**: This command would have caught 12 alias violations and 9 SELECT * violations before commit, saving 2+ hours of rework.

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