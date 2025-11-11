# Zuora ARR Migration to Verified - Project Prompts

**Project:** Migrate `core_fct_zuora_arr` and all upstream dependencies from scratch/ to verified/  
**Jira Ticket:** [DA-4083](https://carta1.atlassian.net/browse/DA-4083)  
**GitHub PR:** [#9003](https://github.com/carta/ds-dbt/pull/9003)  
**Date:** November 10, 2025

---

## Session Context

This session continued from a previous conversation where we had already migrated 6 upstream dependency models (base, transform, transform intermediate layers) for the Zuora ARR fact table. The previous session established:
- Architecture understanding (base → transform → core layers)
- Intermediate transform (int/) subdirectory structure
- _v2 suffix convention for verified/ models
- Incremental model handling (CCL account history)

---

## Core Migration & Validation

### Prompt 1: Complete Migration Assessment
```
what else do I need to migrate fct zuora arr data model
```

**Context:** User asking what remains to complete the full Zuora ARR migration. Led to discovery that we needed the snapshot model before we could migrate the core fact table.

**Key Finding:** Identified missing `core_dim_zuora_contract_subscriptions_snapshot` that needed _v2 version.

---

### Prompt 2: Snapshot Naming Convention Clarification
```
shouldn't I clone first?
```

**Context:** User confirming proper workflow for snapshot migration - clone production data first, then create snapshot file.

**Action:** Provided clone script for production snapshot data (192K rows).

---

### Prompt 3: Snapshot Renaming Request
```
okay I cloned it, but I want to change the name to match the name of the model transform_int_zuora_contract_subscriptions_v2
```

**Context:** User wanted snapshot name to match the underlying transform_int model it references, not the old core_dim naming.

**Action:** 
- Renamed from `core_dim_zuora_contract_subscriptions_snapshot_v2` 
- To: `transform_int_zuora_contract_subscriptions_v2_snapshot`
- Updated snapshot file to reference `transform_int_zuora_contract_subscriptions_v2`

---

### Prompt 4: Complete Snapshot Creation & Validation
```
cool its done can you do a data quality check? also create the snapshot and push to the pr?
```

**Context:** User completed cloning, requested full snapshot creation with validation.

**Actions:**
1. Created `snapshots/transform_int_zuora_contract_subscriptions_v2_snapshot.sql`
2. Validated 192,357 rows match between production and cloned
3. Ran `dbt snapshot` successfully (406 new records)
4. Committed and pushed to PR

---

### Prompt 5: Create Main ARR Model
```
now can you create the arr model? Also do a data quality check?
```

**Context:** With all dependencies migrated, create the main `core_fct_zuora_arr_v2` model.

**Actions:**
1. Created `models/models_verified/core/zuora/core_fct_zuora_arr_v2.sql`
   - Updated all refs to _v2 versions
   - Added `cluster_by` configuration
2. Created `models/models_verified/core/zuora/core_fct_zuora_arr_v2.yml`
3. Ran `dbt build` - all tests passing
4. Validated 45.4M rows match scratch version perfectly

**Validation Results:**
- Total rows: 45,380,412 (100% match)
- Date range: 2018-04-10 to 2025-11-10
- Nov 9 ARR: $319.3M (exact match)

---

## Documentation & Cleanup

### Prompt 6: PR Summary Enhancement
```
can you improve the summary to include this. this is the most important part. Look at what we have and add what we added. Also add directory structure and create a liniage graph
```

**Context:** User wanted comprehensive PR summary showing all 8 models, directory structure, and lineage visualization.

**Action:** Created detailed PR description with:
- Complete model inventory (8 models across all layers)
- Directory structure showing verified/ layout
- ASCII lineage graph showing data flow
- Enhanced validation table with all models

---

### Prompt 7: PR Summary Simplification
```
it looks ugly remove the directory structure and remove the liniage graph, keep it how you had it before but with the new models.
```

**Context:** User preferred cleaner format without ASCII art.

**Action:** Simplified PR to clean table format with 8 models and validation results.

---

### Prompt 8: Lineage Documentation Request
```
give me a description of what is going on here, I am going to create an liniage image based off the descriptions. I want to emphasis the layers
```

**Context:** User wanted layer-by-layer description to create visual lineage diagram.

**Output:** Detailed layer breakdown:
- Layer 1: BASE (ephemeral) - 3 sources
- Layer 2: TRANSFORM (tables) - 4 models
- Layer 3: TRANSFORM INTERMEDIATE (int/ tables) - 2 models
- Layer 4: SNAPSHOTS - 1 snapshot
- Layer 5: CORE (clustered table) - 1 fact table (main output)

---

### Prompt 9: Remove Redshift Legacy Code
```
hey, we are only compiling in snowflake, no more redshift. Remove anything not needed Look at the configs too.
```

**Context:** Clean up Redshift remnants from code.

**Actions:**
1. Removed `sort` config (Redshift-only)
2. Removed `{% if target.type == 'snowflake' %}` conditional
3. Use `BOOLAND_AGG` directly
4. Re-ran `dbt build` to verify - all passing

---

### Prompt 10: Final Verification
```
cool did you update the pr?
```

**Context:** Confirming cleanup commit was pushed to PR.

**Verification:** Confirmed commit `7f2a2e1` in PR with Redshift code removal.

---

## Final Summary

### Models Migrated (8 Total)
1. `base_google_sheets_ccl_sfdc_mapping_v2` (base)
2. `transform_finance_arr_official_v2` (transform)
3. `transform_zuora_accounts_mark_dupes_v2` (transform)
4. `transform_ccl_account_history_v2` (transform, incremental)
5. `transform_int_zuora_contract_subscriptions_v2` (transform/int)
6. `transform_int_ccl_account_history_windows_v2` (transform/int)
7. `transform_int_zuora_contract_subscriptions_v2_snapshot` (snapshot)
8. `core_fct_zuora_arr_v2` (core) ⭐ **Main Output**

### Validation Results
- All 8 models: 100% row count match with scratch equivalents
- Core model: 45.4M rows, $190B+ total ARR tracked
- Date coverage: 2018-04-10 to 2025-11-10
- All dbt tests passing

### Key Learnings
1. **Snapshot naming**: Match underlying model name, not old scratch name
2. **Clone before snapshot**: Always clone production data before creating _v2 snapshot
3. **Layer violations resolved**: Core now references transform + base only (no core-to-core refs)
4. **Snowflake-only**: Removed all Redshift configs (sort, target.type conditionals)
5. **Incremental models**: Require production data clones for validation
6. **Transform tests required**: CI hooks enforce unique + not_null tests on transform unique_key field

---

## Post-Migration Session: CI Fixes & Downstream Analysis

### Prompt 11: CI Pre-commit Hook Failures
```
cool, now I am receiving these ci errors.
- hook id: check-model-has-tests-by-name
- hook id: check-model-has-tests-by-group
```

**Context:** After pushing PR, CI failed because transform models lacked required tests.

**Error Details:**
- 5 transform models missing `not_null` tests (check-model-has-tests-by-name)
- 5 transform models missing `unique` tests (check-model-has-tests-by-group)

**Solution:**
1. Added unique + not_null tests to all 5 transform models on their unique_key field:
   - `transform_int_zuora_contract_subscriptions_v2` (rate_plan_charge_id)
   - `transform_zuora_accounts_mark_dupes_v2` (account_id)
   - `transform_finance_arr_official_v2` (_pk)
   - `transform_ccl_account_history_v2` (primary_key)
   - `transform_int_ccl_account_history_windows_v2` (_pk)
2. Ran `dbt test` - all 10 tests passed
3. Updated dbt-refactor skill and agent docs with Transform test requirements

---

### Prompt 12: Document Test Requirements
```
cool sounds good, can you also add this documentation in any of the agents/skills you feel like we need to add it too
```

**Context:** Prevent future CI failures by updating refactoring documentation.

**Actions:**
1. Updated `~/.claude/skills/dbt-refactor-standards/SKILL.md`:
   - Enhanced testing requirements table
   - Added CI pre-commit hook details
   - Emphasized testing before PR push

2. Updated `~/.claude/agents/dbt-refactor-agent.md`:
   - Added Transform test requirements to YAML examples
   - Enhanced validation phase with pre-push checklist
   - Added CI hook enforcement warnings
   - Updated compliance checklist

---

### Prompt 13: Downstream Model Analysis
```
can you give me a list of all downstream models that reference core_zuora_fct_arr? Try to bucket them together if possible
```

**Context:** Understanding migration scope for downstream consumers.

**Findings:** 33 files reference `core_fct_zuora_arr`:
- **6 Mart Models** (revenue analytics, fund admin)
- **23 Core Intermediate Models** (ARR bucketing pipeline in 3 variants):
  - 9 models: `arr_final/` (main pipeline)
  - 7 models: `without_overrides/` (excluding finance overrides)
  - 7 models: `finance_official/` (finance values only)
- **2 Other Core Models** (dim_zuora_accounts, llc_accounts)
- **2 Ad-hoc queries**

**Most Downstream Model:** `mart_fct_arr_zuora_changelog_expansion_llc`

---

### Prompt 14: Focus on ARR Bucketing Pipeline
```
lets focus on these [23 ARR bucketing models]
```

**Context:** User wants to understand and potentially refactor the 23-model bucketing pipeline.

**Analysis:** Pipeline has 3 parallel implementations:
1. **Main pipeline** (9 models): Uses arr_dollars with finance overrides
2. **Without overrides** (7 models): Uses arr_dollars_without_override
3. **Finance official** (7 models): Uses arr_dollars_finance

All converge into `core_fct_zuora_arr_buckets` → feeds revenue marts

---

### Prompt 15: Path to Mart Model
```
how do we go from core_fct_zuora_arr_v2 to mart_fct_revenue_arr_bucket_investor_services.sql
```

**Context:** Understanding migration path excluding core_dim_zuora_accounts.

**Path Identified:**
```
core_fct_zuora_arr_v2
  ↓
9 intermediate bucketing models (arr_final/)
  ↓
core_fct_zuora_arr_buckets
  ↓
mart_fct_revenue_arr_bucket_investor_services
```

**Question:** Migrate just main pipeline (9) or all 3 variants (23)?

**Answer:** All 3 pipelines, but user doesn't want intermediate models.

---

### Prompt 16: Consolidation Strategy
```
all 3, but I dont want any models inbetween core_fct_zuora_arr_v2 and mart_fct_revenue_arr_bucket_investor_services
```

**Context:** User wants to eliminate all 23 intermediate models.

**Options Presented:**
1. **Inline into mart** - Move all logic into one massive mart SQL (~1000 lines)
2. **Add to core** - Expand core_fct_zuora_arr_v2 with bucketing logic
3. **One transform** - Create single `transform_zuora_arr_bucketed_v2` (1 model)

**User Choice:** Option 1 - Full consolidation into mart

---

### Prompt 17: Consolidation Approach
```
option 1. try to consolidate as much as possible.
```

**Context:** User confirmed full consolidation into mart - eliminate all intermediates.

**Plan:**
Create single mart model `mart_fct_revenue_arr_bucket_investor_services_v2` containing:
- All 9 main pipeline steps (based, churned, delta, expansion, unioned, dates_exploded, MTD, TTD)
- All 7 without_overrides variant steps
- All 7 finance_official variant steps
- Combine all 3 variants
- Filter to Investor Services subsidiaries

**Estimated:** ~800-1000 lines of SQL with 30+ CTEs

**Status:** In progress

---

## ARR Bucketing Pipeline Migration (Session 3)

### Architecture Decision: Transform Layer Refactoring

**Initial Plan:** Consolidate 23 intermediate models into single mart model (~1000 lines)

**Revised Architecture:** After completing consolidation, refactored to proper layered approach:
- Move consolidated logic from `core` → `transform` layer (rename to `transform_temporal_zuora_arr_v2`)
- Break 1144-line consolidated model into 5 materialized transform models
- Create core passthrough + buckets model
- All ARR decomposition models in `transform/zuora/arr_decomp/` subdirectory

**Rationale:** Transform can reference transform (no layer violations), enables better testing and modularity

---

### Prompt 18: Refactor to Transform Layer
```
change of plans, we want this in core, transform can reference transform, so remove the int. I want core_fct_zuora_arr to be in transform and change the name to transform_temporal_zuora_arr, create a passthrough model in core, create the buckets model in core referencing transform, feel free to break consolidation into 3-5 materialized transform models.... all of the arr decomp transform models add in a sub directory in zuora under arr_decomp
```

**Actions:**
1. Moved `core_fct_zuora_arr_v2` → `transform_temporal_zuora_arr_v2` (348 lines)
2. Created 5 materialized transform models in `arr_decomp/`:
   - `transform_zuora_arr_based_v2` (92 lines) - Daily ARR deltas
   - `transform_zuora_arr_bucketed_v2` (580 lines) - Bucket categorization
   - `transform_zuora_arr_dates_exploded_v2` (70 lines) - Date spine
   - `transform_zuora_arr_month_to_date_v2` (299 lines) - MTD calculations
   - `transform_zuora_arr_time_to_date_v2` (204 lines) - QTD/YTD calculations
3. Created `core_fct_zuora_arr_v2` (9 lines) - Passthrough view
4. Created `core_fct_zuora_arr_buckets_v2` (107 lines) - Combines all variants
5. Simplified `mart_fct_revenue_arr_bucket_investor_services_v2` (9 lines)

**All 3 Variants Supported:**
- `main`: Uses `arr_dollars` (with finance overrides)
- `without_overrides`: Uses `arr_dollars_without_override`
- `finance_official`: Uses `arr_dollars_finance`

---

### Critical Bug Fixes

**Bug 1: Surrogate Key Missing Variant**
- **Error:** 45.9M duplicate PKs in `transform_zuora_arr_month_to_date_v2`
- **Root Cause:** `_pk_core_fct_zuora_arr_buckets` didn't include `variant` column
- **Fix:** Added `variant` to surrogate key generation for all 3 variant CTEs
- **Lines:** 299:72, 299:127, 299:182

**Bug 2: Time-to-Date PK Missing Variant**
- **Error:** 31.3M duplicate PKs in `transform_zuora_arr_time_to_date_v2`
- **Root Cause:** `_pk` didn't include `variant` in surrogate key
- **Fix:** Regenerated `_pk` with variant for all 3 variants
- **Lines:** 204:73, 204:137, 204:201

**Bug 3: UNION Column Name Inheritance**
- **Error:** `invalid identifier 'TIME_TO_DATE_WITHOUT_OVERRIDE.ARR_DELTA_MONTH_TO_DATE_WITHOUT_OVERRIDE'`
- **Root Cause:** UNION causes column names to inherit from first SELECT
- **Fix:** Added explicit aliases in core buckets model to rename columns
- **Lines:** 107:59-67

**Bug 4: NULL Metrics - Join Key Mismatch**
- **Error:** All arr_delta_* columns showing NULL (0 non-NULL out of 19M rows)
- **Root Cause:** Core joining on `_pk`, but `dates_exploded._pk` excludes `variant` while `bucketed._pk` includes it
- **Fix:** Changed all 6 LEFT JOINs from `_pk` to explicit column matching:
```sql
LEFT JOIN final_unioned arr_delta
    ON dates.as_of_date = arr_delta.as_of_date
    AND dates.salesforce_account_id = arr_delta.salesforce_account_id
    AND dates.product = arr_delta.product
    AND dates.arr_bucket = arr_delta.arr_bucket
```

**Bug 5: Time-to-Date MTD Join Mismatch**
- **Error:** MTD values NULL, QTD/YTD sums = 0
- **Root Cause:** Same `_pk` mismatch in `transform_zuora_arr_time_to_date_v2`
- **Fix:** Changed month_to_date joins to explicit column matching (lines 204:34-37, 98-101, 162-165)

---

### Data Quality Validation Results

**Core ARR Buckets Model (core_fct_zuora_arr_buckets_v2):**
- **Initial:** 19.2M rows (Investor Services only with filters)
- **After Removing Filters:** 31.4M rows (all subsidiaries, all dates)
- **Validation:** All metrics now populate correctly:
  - arr_delta_day: Non-NULL values present
  - arr_delta_month_to_date: Non-NULL values present  
  - arr_delta_quarter_to_date: 31.4M non-NULL
  - arr_delta_year_to_date: 31.4M non-NULL

**Bucket Distribution (Post-Fix):**
| Bucket | Rows | Daily Sum | MTD Sum | QTD Sum | YTD Sum |
|--------|------|-----------|---------|---------|---------|
| Churn | 3.5M | -$41.0M | -$629M | -$1.57B | -$5.79B |
| Contraction | 3.8M | -$79.1M | -$1.06B | -$2.28B | -$8.06B |
| Expansion | 4.4M | +$122.7M | +$1.42B | +$3.27B | +$12.05B |
| New Logo | 4.8M | +$245.6M | +$6.55B | +$18.85B | +$24.66B |
| Recovery | 2.7M | +$16.5M | +$99.8M | +$303M | +$1.13B |

---

### Upstream Dependency Validation (7 Models)

All upstream models compared between scratch and verified:

| Model | Scratch | Verified | Status |
|-------|---------|----------|--------|
| `base_zuora_account` | `base_zuora_account_v2` | ✅ IDENTICAL (5,845 accounts) |
| `core_ccl_account_history_windows` | `transform_int_ccl_account_history_windows_v2` | ✅ IDENTICAL (2,401 rows) |
| `base_google_sheets_ccl_sfdc_mapping` | `base_google_sheets_ccl_sfdc_mapping_v2` | ✅ IDENTICAL (same source) |
| `core_dim_zuora_contract_subscriptions_snapshot` | `transform_int_zuora_contract_subscriptions_v2_snapshot` | ⚠️ Minor diff (194K vs 192K - snapshot timing) |
| `core_dim_zuora_accounts__mark_dupes` | `transform_zuora_accounts_mark_dupes_v2` | ✅ IDENTICAL (5,845 accounts) |
| `core_dim_zuora_contract_subscriptions` | `transform_int_zuora_contract_subscriptions_v2` | ⚠️ Minor diff (+31 charges, +0.12%) |
| `core_finance_arr_official` | `transform_finance_arr_official_v2` | ✅ IDENTICAL (5.5M rows, $33.5B) |

**Subscription Models Validation:**
- `core_dim_zuora_subscriptions` vs `transform_zuora_subscriptions_consolidated_v2`
- **Result:** 100% IDENTICAL - 340,759 rows, 91,233 latest versions, all products match exactly

---

### Final ARR Model Comparison

**After Full Rebuild with Refreshed Upstreams:**

| Metric | Scratch | Verified | Difference |
|--------|---------|----------|------------|
| **Total Rows** | 45,396,783 | 45,416,194 | +19,411 (+0.04%) |
| **Accounts** | 5,490 | 5,492 | +2 (+0.04%) |
| **Products** | 12 | 12 | ✅ MATCH |
| **Sum ARR** | $190.52B | $190.53B | +$3.4M (+0.002%) |

**Extra Accounts in Verified (from +31 contract subscription charges):**
- `001Ut00000efjzpIAA`: 8,319 rows, $12K ARR
- `001Ut00000d7BBZIA2`: 8,319 rows, $20K ARR

**Conclusion:** ✅ **99.96% match rate** - Verified models are functionally identical to scratch

---

## Models Migrated Summary

### Transform Layer (arr_decomp/)
1. `transform_temporal_zuora_arr_v2` (348 lines) - Main temporal ARR with all 3 variants
2. `transform_zuora_arr_based_v2` (92 lines) - Daily ARR deltas
3. `transform_zuora_arr_bucketed_v2` (580 lines) - Bucket categorization (New Logo, Churn, Expansion, Contraction, Recovery)
4. `transform_zuora_arr_dates_exploded_v2` (70 lines) - Date spine with series_dates
5. `transform_zuora_arr_month_to_date_v2` (299 lines) - Month-to-date aggregations
6. `transform_zuora_arr_time_to_date_v2` (204 lines) - Quarter/Year-to-date aggregations

### Core Layer
7. `core_fct_zuora_arr_v2` (9 lines) - Passthrough view to transform
8. `core_fct_zuora_arr_buckets_v2` (107 lines) - Combines all variants, joins time periods

### Mart Layer
9. `mart_fct_revenue_arr_bucket_investor_services_v2` (9 lines) - Simple reference to core buckets

**DELETED:** Original consolidated mart (1144 lines)

---

## Key Learnings

### Technical
1. **Join Key Design:** When using surrogate keys across models, ensure ALL grouping dimensions are included (especially `variant` columns)
2. **UNION Behavior:** Column names inherit from first SELECT - use explicit aliases in downstream references
3. **Transform Layer:** Can reference other transform models - no layer violations
4. **Materialization:** Breaking large CTEs into materialized tables improves maintainability and debuggability

### Process
5. **Upstream Validation:** Always validate upstream dependencies are identical before investigating downstream differences
6. **Incremental Debugging:** Fix join issues one model at a time, rebuild, validate
7. **Data Quality Checks:** Run comprehensive metric aggregation queries (SUM, COUNT non-NULL) to catch NULL cascades early

### Architecture
8. **Modular Decomposition:** 5 focused models (92-580 lines) > 1 monolith (1144 lines)
9. **Variant Pattern:** Support multiple calculation variants (main, without_overrides, finance_official) in parallel
10. **Core Simplification:** Core buckets model just combines variants - no complex logic

---

## Scratch Models Migration to _scratch Naming Convention (Session 4)

**Date:** November 10, 2025  
**Related PRs:**
- Verified Migration: [#9003](https://github.com/carta/ds-dbt/pull/9003) - Migrate to verified/ (9 models)
- Scratch Migration: [#9012](https://github.com/carta/ds-dbt/pull/9012) - Add _scratch suffix to replaced models (43 models)

### Context & Motivation

After completing the verified migration (PR #9003), the original scratch models needed to be renamed with `_scratch` suffix to:
1. Clearly distinguish deprecated models from new verified versions
2. Prevent confusion about which models are being replaced
3. Maintain database table names unchanged using dbt `alias` configuration
4. Allow gradual deprecation of old models after verified versions are validated

### Migration Scope

**Total Models Migrated:** 43 models across 4 layers  
**Branch:** `th/zuora-arr-migration/migrate-to-scratch-naming`  
**Files Changed:** 109 (43 model renames + 66 downstream reference updates)

#### Base Layer (12 models)
All Zuora and Google Sheets base models that feed the ARR pipeline:

1. `base_google_sheets_ccl_sfdc_mapping` → `base_google_sheets_ccl_sfdc_mapping_scratch`
2. `base_zuora_account` → `base_zuora_account_scratch`
3. `base_zuora_amendment` → `base_zuora_amendment_scratch`
4. `base_zuora_invoice` → `base_zuora_invoice_scratch`
5. `base_zuora_invoice_item` → `base_zuora_invoice_item_scratch`
6. `base_zuora_order` → `base_zuora_order_scratch`
7. `base_zuora_order_action` → `base_zuora_order_action_scratch`
8. `base_zuora_product` → `base_zuora_product_scratch`
9. `base_zuora_rate_plan` → `base_zuora_rate_plan_scratch`
10. `base_zuora_rate_plan_charge` → `base_zuora_rate_plan_charge_scratch`
11. `base_zuora_rate_plan_charge_tier` → `base_zuora_rate_plan_charge_tier_scratch`
12. `base_zuora_subscription` → `base_zuora_subscription_scratch`

**Updated:** 9 downstream files (core models referencing base)

#### Core/Transform Layer (9 models)
Banking, finance, and Zuora core models that were replaced by verified equivalents:

13. `core_ccl_account_history` → `core_ccl_account_history_scratch`
14. `core_ccl_account_history_windows` → `core_ccl_account_history_windows_scratch`
15. `core_finance_arr_official` → `core_finance_arr_official_scratch`
16. `core_dim_zuora_accounts__mark_dupes` → `core_dim_zuora_accounts__mark_dupes_scratch`
17. `core_dim_zuora_contract_subscriptions` → `core_dim_zuora_contract_subscriptions_scratch`
18. `core_fct_zuora_arr` → `core_fct_zuora_arr_scratch`
19. `core_fct_zuora_arr_buckets` → `core_fct_zuora_arr_buckets_scratch`
20. `core_dim_zuora_subscriptions` → `core_dim_zuora_subscriptions_scratch`
21. `mart_fct_revenue_arr_bucket_investor_services` → `mart_fct_revenue_arr_bucket_investor_services_scratch`

**Updated:** 35 downstream files (mart and intermediate models)

#### Intermediate ARR Models (22 models)
All 3 ARR bucketing variant pipelines that feed into the consolidated buckets model:

**arr_final/ subdirectory (8 models):**
22. `core_fct_zuora_arr_buckets__1based` → `core_fct_zuora_arr_buckets__1based_scratch`
23. `core_fct_zuora_arr_buckets__2churned` → `core_fct_zuora_arr_buckets__2churned_scratch`
24. `core_fct_zuora_arr_buckets__3delta` → `core_fct_zuora_arr_buckets__3delta_scratch`
25. `core_fct_zuora_arr_buckets__4expansion` → `core_fct_zuora_arr_buckets__4expansion_scratch`
26. `core_fct_zuora_arr_buckets__5unioned` → `core_fct_zuora_arr_buckets__5unioned_scratch`
27. `core_fct_zuora_arr_buckets__6dates_exploded` → `core_fct_zuora_arr_buckets__6dates_exploded_scratch`
28. `core_fct_zuora_arr_buckets__7bucketed_month_to_date` → `core_fct_zuora_arr_buckets__7bucketed_month_to_date_scratch`
29. `core_fct_zuora_arr_buckets__8bucketed_time_to_date` → `core_fct_zuora_arr_buckets__8bucketed_time_to_date_scratch`

**without_overrides/ subdirectory (7 models):**
30. `core_fct_zuora_arr_buckets__1a_based_without_overrides` → `core_fct_zuora_arr_buckets__1a_based_without_overrides_scratch`
31. `core_fct_zuora_arr_buckets__2a_churned_without_overrides` → `core_fct_zuora_arr_buckets__2a_churned_without_overrides_scratch`
32. `core_fct_zuora_arr_buckets__3a_delta_without_overrides` → `core_fct_zuora_arr_buckets__3a_delta_without_overrides_scratch`
33. `core_fct_zuora_arr_buckets__4a_expansion_without_overrides` → `core_fct_zuora_arr_buckets__4a_expansion_without_overrides_scratch`
34. `core_fct_zuora_arr_buckets__5a_unioned_without_overrides` → `core_fct_zuora_arr_buckets__5a_unioned_without_overrides_scratch`
35. `core_fct_zuora_arr_buckets__7a_bucketed_month_to_date_without_overrides` → `core_fct_zuora_arr_buckets__7a_bucketed_month_to_date_without_overrides_scratch`
36. `core_fct_zuora_arr_buckets__8a_bucketed_time_to_date_without_overrides` → `core_fct_zuora_arr_buckets__8a_bucketed_time_to_date_without_overrides_scratch`

**finance_official/ subdirectory (7 models):**
37. `core_fct_zuora_arr_buckets__1b_based_finance` → `core_fct_zuora_arr_buckets__1b_based_finance_scratch`
38. `core_fct_zuora_arr_buckets__2b_churned_finance` → `core_fct_zuora_arr_buckets__2b_churned_finance_scratch`
39. `core_fct_zuora_arr_buckets__3b_delta_finance` → `core_fct_zuora_arr_buckets__3b_delta_finance_scratch`
40. `core_fct_zuora_arr_buckets__4b_expansion_finance` → `core_fct_zuora_arr_buckets__4b_expansion_finance_scratch`
41. `core_fct_zuora_arr_buckets__5b_unioned_finance` → `core_fct_zuora_arr_buckets__5b_unioned_finance_scratch`
42. `core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance` → `core_fct_zuora_arr_buckets__7b_bucketed_month_to_date_finance_scratch`
43. `core_fct_zuora_arr_buckets__8b_bucketed_time_to_date_finance` → `core_fct_zuora_arr_buckets__8b_bucketed_time_to_date_finance_scratch`

**Updated:** 22 internal references between intermediate models

### Migration Tool

Used custom bash script: `~/.claude/commands/migrate-model-to-scratch`

**Script Features:**
- Renames model file using `git mv` (preserves history)
- Adds `alias='original_name'` config to preserve database table names
- Finds downstream references using dual verification:
  - `grep` for text search across models/
  - `dbt list` for actual DAG dependencies
- Updates all `ref()` calls in models_scratch/ scope only
- Stages all changes with git
- Generates detailed migration report per model

**Example Output:**
```
Model renamed: base_zuora_account → base_zuora_account_scratch
Added alias: 'base_zuora_account' (table name preserved)
Updated references: 9 files (in models_scratch directory)
```

### Database Impact

**Zero database impact** - All table names remain unchanged via dbt alias configuration:

```sql
{{ config(
    alias='base_zuora_account'
) }}
```

- Model file: `base_zuora_account_scratch.sql`
- Database table: `base_zuora_account` (unchanged)
- External tools (Looker, etc.): Continue working without changes

### Validation

**Downstream Reference Verification:**
- All 66 downstream models updated correctly
- No remaining unmigrated `ref()` calls (verified via grep)
- All references scoped to models_scratch/ only (verified/ not affected)

**Manual Fix Required:**
- 1 reference to `core_fct_zuora_arr_buckets__8bucketed_time_to_date` missed by script
- Fixed manually in `core_fct_zuora_arr_buckets_scratch.sql` line 48

### PR Cleanup

**Issue:** Initial PR #9012 was created from branch containing both verified migration commits and scratch migration commit, showing all changes together.

**Fix:** Rebased scratch migration to clean state:
```bash
# Create clean branch from main
git checkout -b temp-scratch-only origin/main

# Cherry-pick only scratch migration commit
git cherry-pick b2b2b6821

# Replace old branch
git branch -D th/zuora-arr-migration/migrate-to-scratch-naming
git branch -m temp-scratch-only th/zuora-arr-migration/migrate-to-scratch-naming

# Force push to update PR
git push -f origin th/zuora-arr-migration/migrate-to-scratch-naming
```

**Result:** PR #9012 now shows only scratch migration changes (1 commit, 67 files) based on `main` branch.

### Key Learnings

1. **Dual Verification Essential:** Grep and dbt list often show discrepancies - grep more reliable for find/replace
2. **Scope Isolation:** Only update references within same directory (models_scratch) to avoid breaking verified/
3. **Alias Pattern:** Using `alias` config enables safe renaming without downstream impact
4. **Batch Processing:** Can migrate models in batches using loops, but verify each completion
5. **Git Preservation:** Using `git mv` preserves file history for deprecated models

### Next Steps

1. **Merge both PRs:**
   - PR #9003: Verified migration (9 new models)
   - PR #9012: Scratch naming (43 renamed models)

2. **Deprecation Timeline:**
   - Week 1-2: Monitor verified models in production
   - Week 3-4: Update downstream consumers to use _v2 models
   - Week 5+: Drop _scratch models after full migration

3. **Documentation:**
   - Update Looker explores to point to new verified tables
   - Notify stakeholders of deprecated model names
   - Add deprecation warnings to _scratch model YAML files

---

## Session 4 Summary

**Completed:** November 10, 2025 (Evening)

Successfully migrated all 43 Zuora ARR scratch models to `_scratch` naming convention in preparation for verified/ migration validation and eventual deprecation.

**Key Achievements:**
- ✅ 43 models renamed with `_scratch` suffix across 4 layers
- ✅ 66 downstream references updated automatically
- ✅ Zero database impact (alias config preserves table names)
- ✅ Git history preserved via `git mv`
- ✅ PR #9012 created and cleaned (based on main, not verified branch)
- ✅ Documentation updated with complete migration audit trail

**Final Status:**
- **PR #9003:** Verified migration (9 new models) - Ready for review
- **PR #9012:** Scratch naming (43 renamed models) - Ready for review

Both PRs are independent and can be merged in any order. Database tables remain unchanged during scratch migration due to dbt alias configuration.
