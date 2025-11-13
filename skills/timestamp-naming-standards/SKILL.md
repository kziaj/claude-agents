# Timestamp Naming Standards Skill

## Overview

This skill documents the required naming convention for timestamp columns in dbt base models within the verified/ directory structure. All timestamp columns MUST use the `_at` suffix for clarity, consistency, and to avoid ambiguity.

## Why This Matters

1. **Clarity**: `created_at` is immediately recognizable as a timestamp, while `created` could be a boolean flag
2. **Consistency**: Uniform naming makes queries more predictable and reduces cognitive load
3. **Standards Compliance**: Verified models require strict adherence to naming conventions
4. **Downstream Impact**: Base model columns flow through transform → core → mart layers, affecting many models

## The Rule

**In verified base models, ALL timestamp columns MUST end with `_at` suffix.**

### Timestamp Column Types

These column patterns require the `_at` suffix:

| Pattern | Correct | Wrong |
|---------|---------|-------|
| Creation timestamp | `created_at` | `created`, `create_date`, `creation_time` |
| Modification timestamp | `modified_at` | `modified`, `modify_date`, `last_modified` |
| Update timestamp | `updated_at` | `updated`, `update_date`, `last_updated` |
| Deletion timestamp | `deleted_at` | `deleted`, `delete_date`, `deletion_time` |
| Load timestamp | `loaded_at` | `loaded`, `load_date`, `load_time` |
| Sync timestamp | `synced_at` | `synced`, `sync_date`, `last_sync` |

## Snowflake Datatype Casting Examples

### ❌ Wrong - Missing `_at` Suffix

```sql
SELECT
  id,
  created::timestamp_ntz as created,  -- WRONG
  modified::timestamp_ntz as modified,  -- WRONG
  updated::timestamp as updated  -- WRONG
FROM {{ source('raw_system', 'table') }}
```

### ✅ Correct - With `_at` Suffix

```sql
SELECT
  id,
  created::timestamp_ntz as created_at,  -- CORRECT
  modified::timestamp_ntz as modified_at,  -- CORRECT
  updated::timestamp as updated_at  -- CORRECT
FROM {{ source('raw_system', 'table') }}
```

### Common Patterns

```sql
-- Pattern 1: Direct column cast
raw_column::timestamp_ntz as created_at

-- Pattern 2: Function cast with alias
CAST(raw_column AS timestamp) as modified_at

-- Pattern 3: Special Snowflake metadata columns
_fivetran_synced::timestamp_ntz as _loaded_at
_sdc_batched_at::timestamp_ntz as _synced_at

-- Pattern 4: Date columns (also need _at if they represent points in time)
open_date::date as opened_at
close_date::date as closed_at
```

## Validation Command

Use the `validate-timestamp-naming` command to automatically scan for violations:

```bash
# Scan all verified base models (default)
validate-timestamp-naming

# Scan specific directory
validate-timestamp-naming --directory models/models_verified/base/zuora

# Scan scratch models
validate-timestamp-naming --directory scratch

# Future: Auto-fix mode (not yet implemented)
validate-timestamp-naming --fix
```

## Downstream Update Checklist

When fixing timestamp naming in a base model, you MUST also update:

### 1. Find Downstream References

```bash
# Find all models referencing the changed column
rg "column_name" models/models_verified/ --type sql -l
```

### 2. Update Transform Models

Transform models typically reference base columns directly:

**Before:**
```sql
SELECT
  b.id,
  b.created,  -- OLD NAME
  b.modified  -- OLD NAME
FROM {{ ref('base_system_table') }} b
```

**After:**
```sql
SELECT
  b.id,
  b.created_at,  -- NEW NAME
  b.modified_at  -- NEW NAME
FROM {{ ref('base_system_table') }} b
```

### 3. Update YAML Documentation

Update column descriptions in both base and downstream YAML files:

**Before:**
```yaml
columns:
  - name: created
    description: 'Timestamp when record was created'
```

**After:**
```yaml
columns:
  - name: created_at
    description: 'Timestamp when record was created'
```

### 4. Update Incremental Logic

Check for timestamp columns used in incremental strategies:

```sql
{% if is_incremental() %}
  WHERE modified_at > (SELECT MAX(modified_at) FROM {{ this }})
{% endif %}
```

### 5. Run Tests

```bash
# Compile to check for SQL errors
poetry run dbt parse

# Run affected models
poetry run dbt run --models base_model_name+

# Test downstream dependencies
poetry run dbt test --models base_model_name+
```

## Exceptions

### When `_at` Suffix is NOT Required

1. **Non-timestamp columns**: Boolean flags like `is_deleted` or `is_active`
2. **Date ranges**: Columns like `valid_from` and `valid_to` in window functions
3. **Non-verified models**: Scratch models don't require strict naming (but encouraged)

### Fivetran/Airbyte Metadata Columns

These special metadata columns are allowed to deviate:

- `_fivetran_synced` → Should become `_loaded_at` when explicitly selected
- `_sdc_batched_at` → Should become `_synced_at` when explicitly selected
- `_airbyte_emitted_at` → Should become `_loaded_at` when explicitly selected

## Real-World Example

### Issue Found: base_banking_account.sql

**Violation (Lines 25, 27):**
```sql
SELECT 
  id,
  account_number,
  created::timestamp_ntz as created,  -- VIOLATION
  created_by_id,
  modified::timestamp_ntz as modified,  -- VIOLATION
  modified_by_id
FROM {{ source('raw_banking', 'account') }}
```

**Fixed:**
```sql
SELECT 
  id,
  account_number,
  created::timestamp_ntz as created_at,  -- FIXED
  created_by_id,
  modified::timestamp_ntz as modified_at,  -- FIXED
  modified_by_id
FROM {{ source('raw_banking', 'account') }}
```

**Downstream Impact (2 models required updates):**
1. `transform_ccl_account_history.sql` - Updated 2 column references
2. `transform_int_ccl_account_history_windows.sql` - Updated 2 column references

## Pre-Commit Integration

The validate-timestamp-naming check can be integrated into pre-commit hooks:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: validate-timestamp-naming
        name: Validate Timestamp Naming Convention
        entry: bash -c 'validate-timestamp-naming --directory models/models_verified/base'
        language: system
        pass_filenames: false
        files: ^models/models_verified/base/.*\.sql$
```

## Related Documentation

- **Command**: `~/.claude/commands/validate-timestamp-naming` - Automated violation scanner
- **Skill**: `~/.claude/skills/dbt-refactor-standards/SKILL.md` - Full verified model standards
- **CLAUDE.md**: Global rules file with pre-push checklist including timestamp validation

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│         TIMESTAMP NAMING QUICK REFERENCE                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ❌ WRONG              ✅ CORRECT                        │
│  ─────────             ──────────                       │
│  created               created_at                       │
│  modified              modified_at                      │
│  updated               updated_at                       │
│  deleted               deleted_at                       │
│  loaded                loaded_at                        │
│  synced                synced_at                        │
│                                                         │
│  VALIDATION:                                            │
│  validate-timestamp-naming                              │
│                                                         │
│  SCOPE:                                                 │
│  • Required: models_verified/base/                      │
│  • Optional: models_scratch/base/                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

**Last Updated**: 2025-01-13  
**Version**: 1.0  
**Author**: Generated from DA-4083 Zuora ARR migration learnings
