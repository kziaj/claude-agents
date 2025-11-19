# Commands Reference Guide

Quick, single-purpose utilities for common dbt refactoring tasks.

---

## Table of Contents

1. [migrate-model-to-scratch](#1-migrate-model-to-scratch)
2. [update-yaml-metadata](#2-update-yaml-metadata)
3. [bulk-model-rename](#3-bulk-model-rename)
4. [analyze-unused-columns](#4-analyze-unused-columns)
5. [compare-model-data](#5-compare-model-data)
6. [get-column-lineage](#6-get-column-lineage)
7. [validate-timestamp-naming](#7-validate-timestamp-naming)
8. [validate-verified-standards](#8-validate-verified-standards)

---

## 1. migrate-model-to-scratch

**Purpose**: Rename a single model with `_scratch` suffix while preserving table names via alias config.

**Version**: 2.0 (with bug fixes from DA-4090)

### Usage

```bash
~/.claude/commands/migrate-model-to-scratch MODEL_NAME

# Example:
~/.claude/commands/migrate-model-to-scratch core_fct_zuora_arr

# Skip compilation (faster):
SKIP_COMPILE=true ~/.claude/commands/migrate-model-to-scratch core_fct_zuora_arr
```

### What It Does

1. Renames SQL file: `model.sql` → `model_scratch.sql` (using git mv)
2. Adds alias config: `{{ config(alias='original_name') }}`
3. Updates YAML name field (if YAML exists)
4. Finds downstream references (grep + dbt list)
5. Updates all refs: `ref('model')` → `ref('model_scratch')`
6. Updates snapshot references (Step 6.5)
7. Stages all changes with git
8. Validates compilation (optional)

### Input

- `MODEL_NAME`: Name of model without .sql extension or path

### Output

- Renamed SQL file with alias config
- Updated YAML file (if exists)
- Updated downstream SQL files
- Updated snapshot files (if referenced)
- Migration report in `~/.claude/results/model-migrations/`
- Parseable summary: `MIGRATION_SUMMARY: renamed=1 downstream_refs=X snapshots=Y status=success`

### Time Savings

- **Per model**: ~8 minutes (vs. 15-20 minutes manual)
- **10 models**: ~80 minutes (vs. 2.5-3 hours manual)

### When to Use

✅ **Use When:**
- Migrating 1-20 models individually
- Need _scratch suffix for domain separation
- Want alias config for Snowflake table preservation
- Need validation and audit trail per model

❌ **Don't Use When:**
- Migrating 20+ models (use agent instead)
- Models have complex non-standard configs
- Need custom migration logic

### Common Issues

**Issue**: Double config blocks created  
**Status**: ✅ Fixed in v2.0  
**Solution**: Now uses Python-based config merging

**Issue**: Snapshot references not updated  
**Status**: ✅ Fixed in v2.0  
**Solution**: Added Step 6.5 to search snapshots/

**Issue**: Compilation times out after 2 minutes  
**Status**: ✅ Fixed in v2.0  
**Solution**: Timeout increased to 5 minutes, added SKIP_COMPILE option

### Examples from DA-4090

```bash
# Base subscription models (15 runs)
migrate-model-to-scratch base_revenue_service_charge
migrate-model-to-scratch base_revenue_service_chargediscount
migrate-model-to-scratch base_revenue_service_subscription
# ... etc

# Result: 62 downstream refs updated automatically
```

---

## 2. update-yaml-metadata

**Purpose**: Bulk update metadata fields in YAML files matching a pattern.

**Version**: 1.0 (created during DA-4090)

### Usage

```bash
~/.claude/commands/update-yaml-metadata PATTERN FIELD OLD_VALUE NEW_VALUE

# Examples:
update-yaml-metadata '*_scratch.yml' total_downstream_nodes 301 303
update-yaml-metadata 'models/core/subscriptions/*.yml' total_upstream_nodes 8 10
```

### What It Does

1. Finds all YAML files matching pattern
2. Checks which files contain field with old value
3. Updates field: `old_value` → `new_value`
4. Validates changes
5. Stages all changes with git
6. Provides summary statistics

### Input

- `PATTERN`: File pattern (e.g., `'*_scratch.yml'`, `'models/**/*.yml'`)
- `FIELD`: Metadata field name (e.g., `total_downstream_nodes`)
- `OLD_VALUE`: Current value to find
- `NEW_VALUE`: New value to replace with

### Output

- Updated YAML files
- Validation report
- Parseable summary: `UPDATE_SUMMARY: searched=X matched=Y updated=Y status=success`

### Time Savings

- **Per file**: ~30 seconds (vs. ~2 minutes manual)
- **10 files**: ~5 minutes (vs. ~20 minutes manual)
- **Saved 15 minutes in DA-4090 merge conflict resolution**

### When to Use

✅ **Use When:**
- Resolving merge conflicts in metadata
- Syncing metadata after bulk operations
- Updating 3+ YAML files with same change
- Need atomic, validated updates

❌ **Don't Use When:**
- Only 1-2 files need updating (manual faster)
- Changes are complex (multiple fields)
- Metadata values differ per file

### Real-World Example (DA-4090)

**Problem**: Main branch updated `total_downstream_nodes` in 9 YAML files while our branch was in progress, causing merge conflicts.

**Solution**:
```bash
# Update all 9 files at once
update-yaml-metadata '*_scratch.yml' total_downstream_nodes 301 303
update-yaml-metadata '*_scratch.yml' total_downstream_nodes 308 310
update-yaml-metadata '*_scratch.yml' total_downstream_nodes 303 305
# ... etc for all 9 changes

# Result: Merge conflicts resolved in 30 seconds vs. 15 minutes manual
```

---

## 3. bulk-model-rename

**Purpose**: Pattern-based bulk renaming across many models with automatic reference updates.

### Usage

```bash
~/.claude/commands/bulk-model-rename "SOURCE_PATTERN" "TARGET_PATTERN"

# Examples:
bulk-model-rename "core_*" "transform_corporations_*"
bulk-model-rename "fct_*" "fact_*"
```

### What It Does

1. Finds all SQL files matching source pattern
2. Applies rename transformation
3. Updates refs throughout codebase
4. Handles YAML files (renames + updates names)
5. Stages all changes with git

### Input

- `SOURCE_PATTERN`: Pattern to match (e.g., `"core_*"`)
- `TARGET_PATTERN`: Replacement pattern (e.g., `"transform_*"`)

### Output

- Renamed SQL files
- Renamed YAML files
- Updated references across all models
- Summary report

### Time Savings

- **20 models**: ~2-3 minutes (vs. 30-40 minutes manual)

### When to Use

✅ **Use When:**
- Systematic naming convention changes
- Changing prefixes across domain
- 10+ models with consistent pattern

❌ **Don't Use When:**
- Models need individual review
- Complex transformation logic required
- Patterns are not consistent

---

## 4. analyze-unused-columns

**Purpose**: Identify unused columns through downstream analysis and query history.

### Usage

```bash
~/.claude/commands/analyze-unused-columns MODEL_NAME

# Example:
analyze-unused-columns core_dim_subscriptions
```

### What It Does

1. Analyzes downstream model references
2. Checks Snowflake query history (120 days)
3. Identifies columns never used in queries
4. Generates detailed usage reports
5. Provides removal recommendations

### Input

- `MODEL_NAME`: Name of model to analyze

### Output

Two detailed reports in `~/.claude/results/remove-unused-columns/`:
- `{model}_DBT_COLUMN_USAGE.md` - dbt reference analysis
- `{model}_FULL_COLUMN_ANALYSIS.md` - Query history + recommendations

### Time Savings

- **Per model**: ~5-10 minutes (vs. 30-60 minutes manual)

### When to Use

✅ **Use When:**
- Optimizing models for performance
- Reducing complexity before refactor
- Cleaning up technical debt
- Understanding actual column usage

❌ **Don't Use When:**
- Model is newly created (no query history)
- Columns used in external tools (Looker, etc.)
- Don't have Snowflake query access

---

## 5. compare-model-data

**Purpose**: Row-by-row comparison between scratch/ and verified/ versions with match percentage reporting.

### Usage

```bash
~/.claude/commands/compare-model-data SCRATCH_MODEL VERIFIED_MODEL

# Example:
compare-model-data core_fct_zuora_arr_scratch core_fct_zuora_arr
```

### What It Does

1. Queries both models from Snowflake
2. Compares row counts
3. Compares data row-by-row
4. Calculates match percentage
5. Identifies mismatched rows
6. Generates comparison report

### Input

- `SCRATCH_MODEL`: Name of scratch version
- `VERIFIED_MODEL`: Name of verified version

### Output

- Row count comparison
- Match percentage (target: 99%+)
- List of mismatched rows
- Detailed comparison report

### Time Savings

- **Per model pair**: ~10-15 minutes (vs. 30-45 minutes manual)

### When to Use

✅ **Use When:**
- Validating migration didn't change data
- Ensuring zero regression after refactor
- Need quantifiable match metrics
- Final validation before PR

❌ **Don't Use When:**
- Intentionally changed logic
- Models are not comparable
- Expected differences exist

---

## 6. get-column-lineage

**Purpose**: Trace column-level upstream/downstream dependencies using Snowflake metadata.

### Usage

```bash
~/.claude/commands/get-column-lineage MODEL_NAME COLUMN_NAME

# Example:
get-column-lineage core_dim_subscriptions subscription_id
```

### What It Does

1. Queries Snowflake metadata tables
2. Traces column upstream to source
3. Traces column downstream to consumers
4. Maps full column lineage path
5. Identifies impact of changes

### Input

- `MODEL_NAME`: Name of model containing column
- `COLUMN_NAME`: Name of column to trace

### Output

- Upstream lineage (sources)
- Downstream lineage (consumers)
- Full lineage graph
- Impact analysis report

### Time Savings

- **Per column**: ~5-10 minutes (vs. 20-30 minutes manual)

### When to Use

✅ **Use When:**
- Planning to rename/remove columns
- Understanding column dependencies
- Analyzing impact before changes
- Documenting data lineage

❌ **Don't Use When:**
- Column metadata not available
- Simple models with obvious lineage
- Don't need detailed impact analysis

---

## 7. validate-timestamp-naming

**Purpose**: Scan base models to detect timestamp columns missing `_at` suffix.

### Usage

```bash
~/.claude/commands/validate-timestamp-naming --directory DIRECTORY

# Example:
validate-timestamp-naming --directory models/models_verified/base
```

### What It Does

1. Scans all SQL files in directory
2. Identifies timestamp/datetime columns
3. Checks for `_at` suffix
4. Reports violations
5. Suggests fixes

### Input

- `--directory`: Directory path to scan (default: models/models_verified/base)

### Output

- List of violations
- Affected models and columns
- Validation report
- Exit code 1 if violations found

### Time Savings

- **Scan entire base layer**: ~2 minutes (vs. 30+ minutes manual)
- **Prevents 1+ hour of CI fix cycles**

### When to Use

✅ **Use When:**
- Before pushing base model changes
- As part of pre-commit checks
- Validating verified/ standards
- Ensuring naming consistency

❌ **Don't Use When:**
- Not working with base models
- Legacy models with different conventions
- Timestamps are intentionally named differently

### Real-World Impact (DA-4083)

Scanned 60 base models, found 1 violation in `base_island_audit_btg`, prevented production issue.

---

## 8. validate-verified-standards

**Purpose**: Comprehensive pre-commit checker for verified/ standards compliance.

### Usage

```bash
~/.claude/commands/validate-verified-standards --directory DIRECTORY

# Example:
validate-verified-standards --directory models/models_verified/core
```

### What It Does

1. Checks for alias configs (not allowed in verified/)
2. Detects SELECT * patterns
3. Validates YAML existence and completeness
4. Checks naming conventions
5. Ensures test coverage
6. Reports all violations

### Input

- `--directory`: Directory path to validate

### Output

- List of all violations by category
- Affected models
- Detailed validation report
- Exit code 1 if violations found

### Time Savings

- **Validate 10 models**: ~5 minutes (vs. 20-30 minutes manual)
- **Prevents 1-2 hours of CI fix cycles**

### When to Use

✅ **Use When:**
- Before pushing verified/ changes
- As part of pre-commit workflow
- Validating refactor compliance
- Final check before PR

❌ **Don't Use When:**
- Working with scratch/ models
- Intentional exceptions documented
- Not targeting verified/ directory

---

## Decision Matrix

### How Many Models?

| Count | Recommended Tool |
|-------|------------------|
| 1-3 | `migrate-model-to-scratch` |
| 3-10 | `migrate-model-to-scratch` + validation commands |
| 10-20 | `migrate-model-to-scratch` + validation commands |
| 20+ | Use dbt-refactor-agent instead |

### What's the Goal?

| Goal | Command |
|------|---------|
| Rename with _scratch | `migrate-model-to-scratch` |
| Update YAML metadata | `update-yaml-metadata` |
| Pattern-based rename | `bulk-model-rename` |
| Remove unused columns | `analyze-unused-columns` |
| Validate data match | `compare-model-data` |
| Understand lineage | `get-column-lineage` |
| Check timestamp naming | `validate-timestamp-naming` |
| Check verified/ standards | `validate-verified-standards` |

---

## Command Chaining

### Typical Migration Flow

```bash
# 1. Rename to scratch
for model in model1 model2 model3; do
    migrate-model-to-scratch $model
done

# 2. Analyze for optimization
analyze-unused-columns model1_scratch

# 3. Validate naming
validate-timestamp-naming --directory models/models_verified/base

# 4. Compare data
compare-model-data model1_scratch model1_verified

# 5. Validate standards
validate-verified-standards --directory models/models_verified/core

# 6. If merge conflicts, update metadata
update-yaml-metadata '*_scratch.yml' total_downstream_nodes 301 303
```

---

## Troubleshooting

### migrate-model-to-scratch

**Problem**: Compilation times out  
**Solution**: Use `SKIP_COMPILE=true` or increase timeout

**Problem**: Double config blocks created  
**Solution**: ✅ Fixed in v2.0 - update command

**Problem**: Snapshot not updated  
**Solution**: ✅ Fixed in v2.0 - update command

### update-yaml-metadata

**Problem**: Pattern not matching files  
**Solution**: Use quotes around pattern, check path is relative to project root

**Problem**: Field not found in files  
**Solution**: Verify field name spelling, check YAML structure

### General

**Problem**: Command not found  
**Solution**: Make executable: `chmod +x ~/.claude/commands/COMMAND_NAME`

**Problem**: Git not staging changes  
**Solution**: Check you're in correct directory, verify git repo

---

## Version History

### v2.0 - November 19, 2025
- `migrate-model-to-scratch`: Fixed double config bug, added snapshot updates, improved timeout handling
- `update-yaml-metadata`: New command created

### v1.0 - November 13, 2025
- Initial command suite released
- 7 commands: migrate-model-to-scratch, bulk-model-rename, analyze-unused-columns, compare-model-data, get-column-lineage, validate-timestamp-naming, validate-verified-standards

---

## Related Documentation

- [Main README](../README.md) - Overview of all tooling
- [MIGRATION_WORKFLOW.md](../MIGRATION_WORKFLOW.md) - DA-4090 case study
- [TOOLING_OVERVIEW.md](../TOOLING_OVERVIEW.md) - Executive summary

---

**Maintained by**: Klajdi Ziaj  
**Last Updated**: November 19, 2025  
**Feedback**: Open issues in repo or reach out on Slack
