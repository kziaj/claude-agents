# Claude Commands

## analyze-unused-columns

**Purpose**: Identifies unused columns in dbt models through downstream analysis and Snowflake query history validation.

### Usage

```bash
# Execute the command
~/.claude/commands/analyze-unused-columns MODEL_NAME

# Example
~/.claude/commands/analyze-unused-columns core_dim_organizations
```

### What It Does

1. **Finds Model**: Locates the dbt model file and validates it exists
2. **Gets Columns**: Extracts all columns from Snowflake for the model
3. **Analyzes Dependencies**: Uses `dbt ls` to find downstream models
4. **Checks Usage**: Searches downstream model files for column references
5. **Query History**: Analyzes 120 days of Snowflake query history for actual usage
6. **Generates Reports**: Creates two detailed markdown reports

### Output Files

Reports are saved to: `~/.claude/results/remove-unused-columns/`

1. **`{MODEL_NAME}_DBT_COLUMN_USAGE.md`**:
   - Executive summary
   - Columns used/unused in downstream dbt models  
   - Recommended phased approach
   - Impact assessment

2. **`{MODEL_NAME}_FULL_COLUMN_ANALYSIS.md`**:
   - Overall summary with key metrics
   - Columns to keep vs delete
   - Query history analysis table
   - Final recommendations

### Prerequisites

- dbt project at `~/carta/ds-dbt`
- Snowflake CLI configured (`snow` command)
- Access to `DBT_BASE.BASE_SNOWFLAKE_QUERY_HISTORY` table
- Model deployed in Snowflake (`DBT_CORE`, `DBT_MART`, `DBT_VERIFIED_*` schemas)

### Example Output

```
[INFO] Starting unused column analysis for model: core_dim_organizations
[SUCCESS] Found model at: /Users/klajdi.ziaj/carta/ds-dbt/models/core/core_dim_organizations.sql
[SUCCESS] Found 25 columns in model
[SUCCESS] Found 12 downstream models
[SUCCESS] dbt Analysis complete: 8 columns appear unused in downstream models
[SUCCESS] Created dbt analysis report: ~/.claude/results/remove-unused-columns/core_dim_organizations_DBT_COLUMN_USAGE.md
[SUCCESS] Query history analysis complete: 3 columns found in query history
[SUCCESS] Created full analysis report: ~/.claude/results/remove-unused-columns/core_dim_organizations_FULL_COLUMN_ANALYSIS.md

═══════════════════════════════════════════════
Column Analysis Complete for: core_dim_organizations  
═══════════════════════════════════════════════

📊 SUMMARY:
   • Total Columns: 25
   • Unused in dbt: 8
   • Found in queries: 3  
   • Actually unused: 5

📁 REPORTS GENERATED:
   • dbt Analysis: ~/.claude/results/remove-unused-columns/core_dim_organizations_DBT_COLUMN_USAGE.md
   • Full Analysis: ~/.claude/results/remove-unused-columns/core_dim_organizations_FULL_COLUMN_ANALYSIS.md

⚠️  5 columns appear safe to remove
   Review reports before making changes
```

---

## migrate-model-to-scratch

**Purpose**: Migrates dbt models to scratch naming convention as part of domain refactoring. Renames models with `_scratch` suffix, manages aliases, and updates all downstream references.

### Usage

```bash
# Execute the command
~/.claude/commands/migrate-model-to-scratch MODEL_NAME

# Via runner script
bash ~/.claude/run-command.sh migrate-model-to-scratch MODEL_NAME

# Example
~/.claude/commands/migrate-model-to-scratch core_fct_zuora_arr
```

### What It Does

1. **Renames Model File**: `core_fct_zuora_arr.sql` → `core_fct_zuora_arr_scratch.sql`
2. **Manages Aliases**: 
   - If no existing alias: Adds `alias: 'core_fct_zuora_arr'` to preserve original table name
   - If alias exists: Leaves existing alias unchanged
3. **Updates References (Directory-Aware)**: 
   - **Scratch models**: Only updates references within `models/scratch/` directory
   - **Verified models**: Only updates references within `models/verified/` directory  
   - **Domain separation**: Preserves cross-directory references to maintain proper domain boundaries
4. **Removes Original**: Deletes original model file after successful migration
5. **Generates Report**: Creates detailed migration report with all changes

### 🎯 Domain Separation Logic

**When migrating a scratch model:**
- ✅ `scratch/mart_revenue.sql`: `ref('core_fct_zuora_arr')` → `ref('core_fct_zuora_arr_scratch')`
- ✅ `verified/mart_summary.sql`: `ref('core_fct_zuora_arr')` → **unchanged** (still references verified version)

This ensures proper domain boundaries where scratch models reference scratch versions while verified models reference clean verified versions.

### Output Files

Reports are saved to: `~/.claude/results/model-migrations/`

**`{MODEL_NAME}_to_scratch_migration_{timestamp}.md`**:
- Complete migration summary
- List of all files changed
- Downstream reference updates
- Validation checklist
- Next steps and testing commands

### Prerequisites

- dbt project at `~/carta/ds-dbt`
- Model file exists and is accessible
- No existing `{MODEL_NAME}_scratch.sql` file

### Example Output

```
[INFO] ═══════════════════════════════════════════════
[INFO] Starting model migration to scratch naming
[INFO] ═══════════════════════════════════════════════
[INFO] Original Model: core_fct_zuora_arr
[INFO] New Name: core_fct_zuora_arr_scratch

[SUCCESS] Found model at: models/core/core_fct_zuora_arr.sql
[INFO] No existing alias found - will add original name as alias
[ACTION] Added new config block with alias='core_fct_zuora_arr'
[SUCCESS] Created: models/core/core_fct_zuora_arr_scratch.sql
[INFO] Model is in scratch - will only update scratch references to maintain domain separation
[SUCCESS] Found references in 8 files within scratch directory (domain separation)
[ACTION] Updating references in: models/scratch/marts/mart_revenue_summary.sql
[ACTION] Updating references in: models/scratch/marts/mart_arr_analysis.sql
[SUCCESS] Removed: models/core/core_fct_zuora_arr.sql
[SUCCESS] Migration report saved: ~/.claude/results/model-migrations/core_fct_zuora_arr_to_scratch_migration_20251110_143022.md

[SUCCESS] ═══════════════════════════════════════════════
[SUCCESS] Migration Complete!
[SUCCESS] ═══════════════════════════════════════════════

📊 SUMMARY:
   • Model renamed: core_fct_zuora_arr → core_fct_zuora_arr_scratch
   • Added alias: 'core_fct_zuora_arr'
   • Updated references: 8 files (in scratch directory (domain separation))
   • Domain separation: Only scratch directory (domain separation) references updated

⚠️  NEXT STEPS:
   1. Test: dbt compile --select core_fct_zuora_arr_scratch
   2. Run: dbt run --select core_fct_zuora_arr_scratch
   3. Validate downstream: dbt run --select +core_fct_zuora_arr_scratch
   4. Commit changes when satisfied
```

### Use Case

This command is specifically designed for the final step of dbt domain migration to `verified/` directory:

1. **Domain Migration Process**:
   - Models are migrated from `scratch/` to `verified/`
   - Original models in `scratch/` need to be renamed to `_scratch` suffix
   - Alias preserves original table name for external tools
   - All downstream references must be updated to new model name

2. **Why Aliases Matter**:
   - External BI tools (Looker, Tableau) reference table names directly
   - Alias ensures table name stays `core_fct_zuora_arr` in Snowflake
   - Model name becomes `core_fct_zuora_arr_scratch` for dbt references
   - Seamless transition for external dependencies