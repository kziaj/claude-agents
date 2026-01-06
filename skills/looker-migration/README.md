# Looker Migration Skill

Tools and workflows for migrating Looker views from scratch (dbt_core, dbt_mart) to verified (dbt_verified_*) schemas.

## Files

- **SKILL.md** - Comprehensive workflow documentation
- **README.md** - This file

## Commands

Created in `~/.claude/commands/`:

1. **compare-table-schemas** - Compare scratch vs verified table column schemas
2. **scan-looker-references** - Scan directory for dbt_core/dbt_mart references  
3. **validate-lookml-fields** - Verify LookML fields exist in target Snowflake table

## Quick Start

```bash
# 1. Scan for references
scan-looker-references --dir revenue/ --schemas dbt_core,dbt_mart

# 2. Compare schemas
compare-table-schemas dbt_core.core_fct_zuora_arr dbt_verified_core.core_historical_zuora_arr

# 3. Validate before migrating
validate-lookml-fields \
  --lookml revenue/zuora_arr.view.lkml \
  --table dbt_verified_core.core_historical_zuora_arr

# 4. If validation passes, migrate
sed -i '' 's/dbt_core.core_fct_zuora_arr/dbt_verified_core.core_historical_zuora_arr/g' \
  views/revenue/zuora_arr.view.lkml
```

## When to Use

**Use this skill when:**
- Migrating Looker views to verified schemas
- Validating schema compatibility before migration
- Documenting column mappings for migrations
- Processing multiple Looker directories systematically

**Key principle:** Always validate column compatibility BEFORE changing sql_table_name references.

## Reference Implementation

[DA-4203](https://github.com/carta/ds-looker-carta-analytics/pull/1537) - Zuora + Corporation ARR/Subscription Models
- 25 files migrated
- ~195 references updated
- 18 unique table mappings documented
- Directory-by-directory atomic commits

## Workflow Overview

1. **Pre-Migration:** Generate column mappings, scan directories
2. **Per-Directory:** Validate fields, migrate files, commit
3. **Post-Migration:** Review diff, create PR with comprehensive docs

See `SKILL.md` for complete workflow and troubleshooting guide.
