# Looker BI Migration Workflow

**Purpose:** Systematically migrate Looker view files from scratch schemas (dbt_core, dbt_mart) to verified schemas (dbt_verified_core, dbt_verified_transform, dbt_verified_mart).

**Reference Implementation:** [DA-4203](https://github.com/carta/ds-looker-carta-analytics/pull/1537) - Zuora + Corporation ARR/Subscription Models

---

## Overview

Migrating Looker views requires:
1. **Schema compatibility validation** - Ensure verified tables have the columns LookML expects
2. **Column mapping** - Document any renamed or missing columns
3. **Directory-by-directory migration** - Process systematically to avoid overwhelming changes
4. **Atomic commits** - Commit after each logical unit (directory or model group)

---

## Phase 1: Pre-Migration Analysis

### Step 1: Identify Scope

**Goal:** Determine which Looker directories and files need migration.

```bash
# Quick scan of all Looker views for scratch references
cd ~/ds-looker-carta-analytics
grep -r "sql_table_name.*dbt_core\." views/ --include="*.lkml" | wc -l
grep -r "sql_table_name.*dbt_mart\." views/ --include="*.lkml" | wc -l

# Identify high-priority directories based on business area
# Example: revenue/, core/, subscriptions/, corporations/
```

**Output:** List of directories to migrate (prioritize by business impact).

### Step 2: Generate Column Mappings

**Goal:** Create comprehensive documentation of scratch → verified table mappings.

**Method A: Use compare-table-schemas command**
```bash
# For each table pair in scope
compare-table-schemas dbt_core.core_fct_zuora_arr dbt_verified_core.core_historical_zuora_arr
```

**Method B: Use Claude to batch generate mappings**
```
"Generate column mappings for the following table pairs:
- dbt_core.core_fct_zuora_arr → dbt_verified_core.core_historical_zuora_arr
- dbt_core.core_dim_subscriptions → dbt_verified_core.core_dim_corporations_subscriptions
...
Create a markdown document with complete column-by-column mappings."
```

**Output:** `scratch-to-verified-column-mapping.md` in the Looker repo.

**Key Information to Capture:**
- ✅ Columns that match exactly
- ⚠️ Columns that are renamed (CREATED → CREATED_AT)
- ❌ Columns missing in verified
- ➕ Extra columns in verified (informational only)

### Step 3: Review Scratch-to-Verified Model Mapping

**Location:** `~/ds-dbt/docs/scratch-to-verified-mapping.md` or `~/ds-redshift/docs/scratch-to-verified-mapping.md`

**Verify:**
- All referenced scratch models have verified equivalents
- Understand the verified model naming patterns
- Note any models without verified equivalents (block migration for those)

---

## Phase 2: Directory-by-Directory Migration

### Step 1: Choose a Directory

Start with a small, low-risk directory to validate the workflow.

**Recommended order:**
1. Small utility directories (2-5 files)
2. Core business logic directories (10-15 files)
3. Large complex directories (20+ files)

### Step 2: Scan Directory for References

```bash
# Scan specific directory
scan-looker-references --dir revenue/ --schemas dbt_core,dbt_mart
```

**Output:**
- List of files with references
- Count of references per model
- Total reference count

### Step 3: Validate Schema Compatibility (File by File)

For each file in the directory:

```bash
# Example: revenue/zuora_arr.view.lkml
validate-lookml-fields \
  --lookml revenue/zuora_arr.view.lkml \
  --table dbt_verified_core.core_historical_zuora_arr
```

**Decision Tree:**
- ✅ **All columns exist** → Safe to migrate
- ⚠️ **Some columns renamed** → Update LookML dimension definitions
- ❌ **Columns missing** → Check if:
  - Column exists in a different verified model (use that instead)
  - Column is computed downstream (use downstream model)
  - Column truly doesn't exist (block migration, discuss with dbt team)

### Step 4: Perform Migration

**For files with perfect schema match:**
```bash
# Simple find-replace in file
sed -i '' 's/dbt_core.core_fct_zuora_arr/dbt_verified_core.core_historical_zuora_arr/g' \
  views/revenue/zuora_arr.view.lkml
```

**For files with column renames:**
```
1. Update sql_table_name to verified schema
2. Update dimension definitions to use new column names:

dimension: created {
  type: time
  sql: ${TABLE}.CREATED_AT ;;  # Changed from CREATED
}
```

### Step 5: Test Locally (if possible)

If you have Looker access:
1. Copy modified LookML to Looker dev branch
2. Run explores to verify no errors
3. Validate that data matches expectations

### Step 6: Commit Changes

```bash
# Stage all changes in directory
git add views/revenue/

# Commit with descriptive message
git commit -m "[DA-XXXX] Migrate revenue/ Looker views to verified schemas

- Updated 8 files to reference verified tables
- Renamed columns: CREATED → CREATED_AT, MODIFIED → MODIFIED_AT
- All schema validations passed
"

# Push to branch
git push
```

### Step 7: Repeat for Next Directory

Continue with remaining directories following the same process.

---

## Phase 3: Final Validation & PR

### Step 1: Create Comprehensive Migration Report

**Include in PR description:**
- Total files changed
- Total references migrated
- List of all table mappings (scratch → verified)
- Any column renames or caveats
- Models that remain on scratch (with justification)

**Example:** See [PR #1537](https://github.com/carta/ds-looker-carta-analytics/pull/1537/files)

### Step 2: Review Entire Diff

```bash
# View all sql_table_name changes
git diff origin/master...HEAD -- '*.view.lkml' | grep -E "^[-+]\s*sql_table_name:"
```

**Validate:**
- No accidental schema names (e.g., `dbt_verified_marts` instead of `dbt_verified_mart`)
- No mixed references (part dbt_core, part dbt_verified_core in same file)
- All changes are intentional

### Step 3: Open Pull Request

```bash
gh pr create \
  --title "[DA-XXXX] Migrate Looker views from scratch to verified schemas" \
  --body "$(cat PR_DESCRIPTION.md)" \
  --label "cc-product-development"
```

---

## Common Issues & Solutions

### Issue 1: Column Renamed in Verified

**Symptom:** `validate-lookml-fields` reports missing columns like CREATED, MODIFIED

**Solution:**
1. Check column mapping doc for renamed columns
2. Update LookML dimension to use new column name:
```lkml
dimension: created {
  type: time
  sql: ${TABLE}.CREATED_AT ;;  # Renamed from CREATED
}
```

### Issue 2: Missing Columns in Verified

**Symptom:** Scratch table has columns that don't exist in verified

**Investigation:**
1. Check if column is computed in a downstream model
   - Example: `core_dim_zuora_accounts` computes ARR_GO_LIVE_DATE
   - Verified base has no ARR_GO_LIVE_DATE, but downstream core model adds it
2. Check if column name changed significantly
3. Check if column was deprecated

**Solutions:**
- Use more downstream verified model (mart > core > transform)
- Update LookML to use different column
- Block migration if column is truly unavailable

### Issue 3: Different Model Structure

**Symptom:** Verified model has completely different columns than scratch

**Example:** `dim_corporations` (scratch) vs `mart_corporations` (verified)
- Only 9 overlapping columns
- Different analytical purposes

**Investigation:**
1. Read both model SQL files to understand purpose
2. Check if LookML only uses overlapping columns
3. Determine if migration is appropriate

**Decision:**
- If LookML only uses common columns → Migrate with caution
- If LookML uses many scratch-specific columns → Do NOT migrate (or redesign LookML)

### Issue 4: No Verified Equivalent Exists

**Symptom:** Scratch model has no mapping in `scratch-to-verified-mapping.md`

**Solution:**
1. Verify model truly doesn't exist in verified tier
2. Add to "out of scope" list in PR description
3. Create follow-up Jira ticket for dbt team to create verified version

**Example from DA-4203:**
- `mart_dim_corporation_features` - No verified equivalent
- `mart_dim_llc_accounts` - No verified equivalent

---

## Best Practices

### DO:
✅ Generate column mappings BEFORE starting migration  
✅ Process one directory at a time  
✅ Validate schema compatibility before changing sql_table_name  
✅ Commit after each directory (atomic changes)  
✅ Document any column renames in commit messages  
✅ Use most downstream verified model when available  
✅ Test in Looker dev environment if possible  

### DON'T:
❌ Migrate entire repo at once  
❌ Assume column names are identical  
❌ Skip validation steps  
❌ Mix scratch and verified references in same file  
❌ Use base/transform when core/mart is available  
❌ Forget to update dimension definitions for renamed columns  

---

## Commands Reference

```bash
# Compare table schemas
compare-table-schemas <scratch_table> <verified_table>

# Scan directory for references
scan-looker-references --dir <directory> --schemas dbt_core,dbt_mart

# Validate LookML fields exist in target
validate-lookml-fields --lookml <file> --table <schema.table>

# Quick counts
grep -r "sql_table_name.*dbt_core\." views/ --include="*.lkml" | wc -l
grep -r "sql_table_name.*dbt_mart\." views/ --include="*.lkml" | wc -l

# View all changes
git diff origin/master...HEAD -- '*.view.lkml' | grep "sql_table_name:"
```

---

## Example Workflow

```bash
# 1. Pre-Migration
cd ~/ds-looker-carta-analytics
scan-looker-references --dir revenue/ --schemas dbt_core,dbt_mart
# → Found 8 files with 15 references

# 2. Generate column mappings (via Claude)
# → Creates scratch-to-verified-column-mapping.md

# 3. Validate each file
validate-lookml-fields \
  --lookml revenue/zuora_arr.view.lkml \
  --table dbt_verified_core.core_historical_zuora_arr
# → ✅ All columns found

# 4. Migrate file
sed -i '' 's/dbt_core.core_fct_zuora_arr/dbt_verified_core.core_historical_zuora_arr/g' \
  views/revenue/zuora_arr.view.lkml

# 5. Repeat for all files in directory

# 6. Commit
git add views/revenue/
git commit -m "[DA-4203] Migrate revenue/ directory to verified schemas"
git push

# 7. Move to next directory
scan-looker-references --dir core/ --schemas dbt_core,dbt_mart
```

---

## Success Metrics

- ✅ Zero schema validation errors
- ✅ All LookML dimension fields exist in target tables
- ✅ Atomic commits per directory
- ✅ Comprehensive column mapping documentation
- ✅ Clear PR description with migration summary
- ✅ No mixed scratch/verified references

---

## Related Documentation

- **dbt Model Tiers:** `~/ds-dbt/docs/model-tiers.md`
- **Scratch-to-Verified Mapping:** `~/ds-dbt/docs/scratch-to-verified-mapping.md`
- **Example Migration PR:** [PR #1537](https://github.com/carta/ds-looker-carta-analytics/pull/1537)
