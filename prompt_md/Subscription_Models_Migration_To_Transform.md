# Subscription Models Migration Plan: Scratch Core → Verified Transform

**Date Created:** January 2025  
**Owner:** Klajdi Ziaj  
**Jira Ticket:** DA-XXXX (to be created)  
**Estimated Time:** 2.5 hours (includes 30 min data quality validation)  
**Complexity:** High (7 interdependent models, ~39 downstream references)

---

## Executive Summary

This migration moves 7 interdependent subscription models from `models_scratch/core/subscriptions/` to `models_verified/transform/corporations/` to comply with verified/ layer architecture rules. The migration resolves a critical architectural violation where CORE models were referencing other CORE models, which is prohibited in the verified/ directory structure.

**Key Constraint:** In verified/, CORE layer can only reference BASE and TRANSFORM layers (not other CORE models). Moving these models to TRANSFORM resolves circular dependencies and enables proper layer separation.

---

## ⚠️ IMPORTANT: Consider Using dbt-refactor-agent First

**Before proceeding with the manual migration below**, consider using the **dbt-refactor-agent** for this 7-model systematic migration.

### Why Use the Agent?

The agent would handle this migration automatically and catch issues upfront:
- ✅ Automatically creates/updates YAML files with proper `name:` and `description:` fields
- ✅ Validates all refs are updated correctly
- ✅ Runs pre-commit hooks before committing
- ✅ Prevents the 6+ fix commits we experienced in PR #9012
- ✅ Catches missing descriptions, mismatched YAML names, compilation errors

### Decision Criteria

**Use dbt-refactor-agent if:**
- You want automated, systematic handling of 7+ models
- You want to avoid iterative fix cycles
- You trust the agent to handle refactoring

**Use manual migration if:**
- You need fine-grained control over each step
- You want to learn the migration process
- You need to document exact changes for training purposes

### Lessons from PR #9012 (Zuora ARR Migration)

In PR #9012, we migrated 43 Zuora ARR models **manually** and encountered:
- ❌ 6 fix commits needed (45+ minutes of CI iterations)
- ❌ 59 models missing `description:` field in YAMLs
- ❌ YAML files not renamed to match `_scratch` SQL files
- ❌ Downstream refs not updated systematically
- ❌ Didn't run pre-commit hooks locally first

**If we had used dbt-refactor-agent:**
- ✅ All issues caught in first pass
- ✅ Single clean commit
- ✅ 30 minutes total instead of 2+ hours

**This document provides the manual approach.** If using the agent, use it as a reference for validation only.

---

## ⚠️ CRITICAL: File Creation vs. Copying Rules

**NEVER copy files from scratch/ to verified/.** Always create NEW files following verified/ conventions.

### For Scratch Models (Existing Files)
1. ✅ **RENAME** with `git mv` to `_scratch` suffix (preserves git history)
2. ✅ **ADD** `alias` config to preserve Snowflake table names
3. ✅ **UPDATE** internal refs to other `_scratch` models
4. ✅ **UPDATE** YAML files to match new names
5. ❌ **NEVER DELETE** - we're renaming, not deleting

### For Verified Models (New Files)
1. ✅ **CREATE NEW FILES** in verified/ directory (start fresh)
2. ✅ **READ** scratch version to understand business logic
3. ✅ **WRITE** SQL from understanding, NOT copy-paste
4. ✅ **FOLLOW** verified/ styleguide and conventions
5. ✅ **USE** clean production names (no version suffixes)
6. ✅ **ADD** proper configs, tests, descriptions
7. ❌ **NEVER COPY** files from scratch to verified

**Why This Matters:**
- Scratch and verified have different conventions
- Copy-paste brings scratch patterns into verified
- Creates technical debt and style inconsistencies
- Defeats the purpose of having a verified/ directory

---

## ⚠️ CRITICAL: Verified Model Standards (DA-4090 Findings)

**These violations were discovered after initial migration and required significant rework:**

### Standard 1: NO Alias Configs in Verified Models

**Rule:** Verified models must NOT use `alias` config. Only scratch models with `_scratch` suffix need aliases to preserve Snowflake table names.

**Violation Found (DA-4090):**
- 12 verified base models incorrectly included `alias` configs
- This violates verified/ conventions where model name = table name

**Example Violation:**
```sql
-- WRONG (verified model):
{{
  config(
    alias='base_revenue_service_subscription',
    materialized='ephemeral'
  )
}}

-- CORRECT (verified model):
{{
  config(
    materialized='ephemeral'
  )
}}
```

**Fix Applied:**
- Removed alias configs from 12 base models:
  - base_revenue_service_subscription
  - base_revenue_service_plan
  - base_revenue_service_charge
  - base_revenue_service_priceinfo
  - base_revenue_service_discountinfo
  - base_revenue_service_chargediscount
  - base_revenue_service_escalator
  - base_revenue_service_customerescalatorhistory
  - base_revenue_service_customerthresholdhistory
  - base_cartaweb_home_contractinformation
  - base_cartaweb_home_contractsigner
  - base_cartaweb_corporations_churnrecord

---

### Standard 2: NO SELECT * in Verified Models

**Rule:** Verified models must use explicit column lists. `SELECT *` is prohibited to ensure schema stability and documentation.

**Violation Found (DA-4090):**
- 9 verified base models used `SELECT *` (15 total occurrences)
- This violates verified/ standards requiring explicit columns for:
  - Schema documentation
  - Breaking change prevention
  - Column lineage tracking

**Example Violation:**
```sql
-- WRONG (verified model):
SELECT *
FROM raw.revenue_service.subscription

-- CORRECT (verified model):
SELECT
  id
  , customer_id
  , plan_id
  , is_active
  , activation_date
  , deactivation_date
  -- ... all columns explicitly listed
FROM raw.revenue_service.subscription
```

**Fix Applied:**
- Used dbt-refactor-agent to expand SELECT * to explicit columns in 9 base models
- Result: 400+ columns now explicitly defined across all models
- Models fixed:
  - base_revenue_service_subscription (3 SELECT * → explicit columns)
  - base_revenue_service_plan (2 SELECT *)
  - base_revenue_service_charge (2 SELECT *)
  - base_revenue_service_priceinfo (1 SELECT *)
  - base_revenue_service_discountinfo (1 SELECT *)
  - base_revenue_service_chargediscount (1 SELECT *)
  - base_revenue_service_escalator (1 SELECT *)
  - base_revenue_service_customerescalatorhistory (2 SELECT *)
  - base_cartaweb_home_contractinformation (2 SELECT *)

**Prevention:** Run `grep -r "SELECT \*" models_verified/` before committing to catch violations.

---

## Architecture Rules & Context

### Layer Architecture (Verified/ Directory ONLY)

```
Sources
  ↓
BASE (References: Sources only)
  ↓
TRANSFORM (References: BASE, TRANSFORM) ← Multi-layer allowed
  ↓
CORE (References: BASE, TRANSFORM) ← CANNOT reference other CORE
  ↓
MART (References: BASE, TRANSFORM, CORE)
```

**Critical Rules:**
1. Each layer can ONLY reference upstream (lower) layers
2. TRANSFORM is special: can have multiple sub-layers referencing each other
3. CORE → CORE references are PROHIBITED in verified/
4. These rules ONLY apply in `models_verified/`, NOT in `models_scratch/`

### Domain Separation Strategy

**Scratch Domain:**
- Models stay in scratch with `_scratch` suffix
- Scratch models reference scratch models only
- Use alias config to preserve Snowflake table names

**Verified Domain:**
- New transform models with clean production names
- Verified models reference verified models only
- No version suffixes (e.g., `_v2`)

---

## Models to Migrate (7 Total)

### 1. Main Model: core_dim_subscriptions → transform_corporations_subscriptions

**Current Path:** `models_scratch/core/subscriptions/core_dim_subscriptions.sql`  
**New Path:** `models_verified/transform/corporations/transform_corporations_subscriptions.sql`  
**Purpose:** Primary subscriptions dimension table with comprehensive subscription data  
**Dependencies:** 5 other core models + 11 base models  
**Downstream:** ~39 models reference this  
**Type:** Regular table (not incremental/snapshot)

**Key Metrics:**
- ~800+ lines of SQL
- 16 CTEs
- Complex join logic with subscriptions, plans, charges, discounts

**Internal References (will change):**
- `ref('core_dim_subscription_charges')`
- `ref('core_dim_subscription_payment_windows')`
- `ref('core_dim_subscription_tiers')`
- `ref('core_fct_subscription_active_features')`
- `ref('core_fct_subscription_customer_threshold_history')`

**Base References (will NOT change):**
- `ref('base_revenue_service_subscription')`
- `ref('base_revenue_service_plan')`
- `ref('base_revenue_service_charge')`
- `ref('base_revenue_service_priceinfo')`
- `ref('base_revenue_service_discountinfo')`
- `ref('base_revenue_service_chargediscount')`
- `ref('base_revenue_service_escalator')`
- `ref('base_cartaweb_home_contractinformation')`
- `ref('base_cartaweb_home_contractsigner')`
- `ref('base_cartaweb_corporations_churnrecord')`
- `ref('base_subscriptions_temporal_revenue_service_charge')`

### 2. Supporting Model: core_dim_subscription_charges → transform_corporations_subscription_charges

**Current Path:** `models_scratch/core/subscriptions/core_dim_subscription_charges.sql`  
**New Path:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_charges.sql`  
**Purpose:** Charge records for subscriptions  
**Dependencies:** 4 base models + 1 snapshot source  
**Downstream:** Referenced by core_dim_subscriptions  
**Type:** Regular table

**Base References (will NOT change):**
- `ref('base_revenue_service_charge')`
- `ref('base_revenue_service_subscription')`
- `ref('base_revenue_service_plan')`
- `ref('base_revenue_service_priceinfo')`
- `source('dbt_core', 'source_core_dim_subscription_payment_windows_snapshot')`

### 3. Supporting Model: core_dim_subscription_payment_windows → transform_corporations_subscription_payment_windows

**Current Path:** `models_scratch/core/subscriptions/core_dim_subscription_payment_windows.sql`  
**New Path:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_payment_windows.sql`  
**Purpose:** Non-overlapping payment windows for each subscription  
**Dependencies:** 9 base models + escalators + threshold_history + 1 snapshot  
**Downstream:** Referenced by core_dim_subscriptions, core_dim_subscription_tiers  
**Type:** Regular table

**Internal References (will change):**
- `ref('core_fct_subscription_escalators')` → `ref('transform_corporations_subscription_escalators')`
- `ref('core_fct_subscription_customer_threshold_history')` → `ref('transform_corporations_subscription_thresholds')`

**Base References (will NOT change):**
- `ref('base_revenue_service_subscription')`
- `ref('base_revenue_service_plan')`
- `ref('base_revenue_service_priceinfo')`
- `ref('base_revenue_service_discountinfo')`
- `ref('base_revenue_service_charge')`
- `ref('base_revenue_service_chargediscount')`
- `ref('base_revenue_service_escalator')`
- `ref('base_revenue_service_customerthresholdhistory')`
- `ref('base_cartaweb_home_contractinformation')`
- `source('dbt_core', 'source_core_dim_subscription_payment_windows_snapshot')`

### 4. Supporting Model: core_dim_subscription_tiers → transform_corporations_subscription_tiers

**Current Path:** `models_scratch/core/subscriptions/core_dim_subscription_tiers.sql`  
**New Path:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_tiers.sql`  
**Purpose:** Subscription tier pricing information  
**Dependencies:** 3 base models + payment_windows + threshold_history  
**Downstream:** Referenced by core_dim_subscriptions  
**Type:** Regular table

**Internal References (will change):**
- `ref('core_dim_subscription_payment_windows')` → `ref('transform_corporations_subscription_payment_windows')`
- `ref('core_fct_subscription_customer_threshold_history')` → `ref('transform_corporations_subscription_thresholds')`

**Base References (will NOT change):**
- `ref('base_revenue_service_subscription')`
- `ref('base_revenue_service_plan')`
- `ref('base_revenue_service_priceinfo')`

### 5. Supporting Model: core_fct_subscription_active_features → transform_corporations_subscription_features

**Current Path:** `models_scratch/core/subscriptions/core_fct_subscription_active_features.sql`  
**New Path:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_features.sql`  
**Purpose:** Active subscription features over time  
**Dependencies:** 3 base models + series_dates source  
**Downstream:** Referenced by core_dim_subscriptions  
**Type:** Regular table

**Base References (will NOT change):**
- `ref('base_revenue_service_subscription')`
- `ref('base_revenue_service_plan')`
- `ref('base_cartaweb_corporations_churnrecord')`
- `source('dbt_core', 'series_dates')`

### 6. Supporting Model: core_fct_subscription_customer_threshold_history → transform_corporations_subscription_thresholds

**Current Path:** `models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history.sql`  
**New Path:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_thresholds.sql`  
**Purpose:** Historical threshold counts (stakeholder/employee) over time  
**Dependencies:** 2 base models + series_dates source  
**Downstream:** Referenced by core_dim_subscriptions, payment_windows, tiers  
**Type:** Regular table

**Base References (will NOT change):**
- `ref('base_revenue_service_customerthresholdhistory')`
- `ref('base_analytics_analytics_storedcorporationdata')`
- `source('dbt_core', 'series_dates')`

### 7. Supporting Model: core_fct_subscription_escalators → transform_corporations_subscription_escalators

**Current Path:** `models_scratch/core/subscriptions/core_fct_subscription_escalators.sql`  
**New Path:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_escalators.sql`  
**Purpose:** Subscription price escalators (renewal price increases)  
**Dependencies:** 2 base models  
**Downstream:** Referenced by payment_windows  
**Type:** Regular table

**Why This Must Move:** If this stays in CORE, then `transform_corporations_subscription_payment_windows` would reference CORE from TRANSFORM, violating layer rules (TRANSFORM cannot reference downstream). Moving to TRANSFORM resolves this.

**Base References (will NOT change):**
- `ref('base_revenue_service_escalator')`
- `ref('base_revenue_service_customerescalatorhistory')`

---

## Base Models - MUST Also Migrate (Following Zuora ARR Pattern)

**⚠️ IMPORTANT UPDATE:** After reviewing the Zuora ARR migration (PR #9003), we discovered that base models MUST also be migrated to verified/ to maintain domain separation.

**The Problem:** Verified transform models cannot reference scratch base models. This violates domain separation:
```
WRONG: models_verified/transform/ → models_scratch/base/ ❌
RIGHT: models_verified/transform/ → models_verified/base/ ✅
```

**The Solution:** Following the Zuora ARR migration pattern, we must ALSO migrate these 15 base models to maintain domain separation:

### Base Models to Migrate (15 total)

**Base Subscriptions (10 models):**
1. `base_revenue_service_subscription` (stays same name)
2. `base_revenue_service_plan` (stays same name)
3. `base_revenue_service_charge` (stays same name)
4. `base_revenue_service_priceinfo` (stays same name)
5. `base_revenue_service_discountinfo` (stays same name)
6. `base_revenue_service_chargediscount` (stays same name)
7. `base_revenue_service_escalator` (stays same name)
8. `base_revenue_service_customerescalatorhistory` (stays same name)
9. `base_revenue_service_customerthresholdhistory` (stays same name)
10. `base_revenue_service_features_array` (stays same name)

**Base Cartaweb (3 models):**
11. `base_cartaweb_home_contractinformation` (stays same name)
12. `base_cartaweb_home_contractsigner` (stays same name)
13. `base_cartaweb_corporations_churnrecord` (stays same name)

**Base Analytics (1 model):**
14. `base_analytics_analytics_storedcorporationdata` (stays same name)

**Base Subscriptions Temporal (1 model):**
15. `base_subscriptions_temporal_revenue_service_charge` (stays same name)

**Migration Process for Base Models:**
1. RENAME scratch versions to `_scratch` suffix with `alias` config FIRST
2. CREATE NEW verified versions in `models_verified/base/` with clean names (NOT copy!)
3. UPDATE verified transform models to reference clean base model names
4. UPDATE scratch transform models to reference `_scratch` base models

**Note:** This adds ~15 more models to the migration scope, bringing total from 7 to 22 models.

---

## Downstream Models to Update (~39 models in verified/)

These models currently reference the 7 subscription models and need ref() updates:

**Confirmed Downstream (based on core_dim_subscriptions usage):**
- `mart_dim_corporations.sql` (models_scratch/marts/corporations/)
- Various corporation and revenue models in verified/

**Search Required:** Use `grep -r "ref('core_dim_subscriptions')" models_verified/` to find all downstream references.

**Update Pattern:**
```sql
-- OLD (scratch refs scratch):
{{ ref('core_dim_subscriptions') }}
{{ ref('core_dim_subscription_charges') }}
{{ ref('core_dim_subscription_payment_windows') }}
{{ ref('core_dim_subscription_tiers') }}
{{ ref('core_fct_subscription_active_features') }}
{{ ref('core_fct_subscription_customer_threshold_history') }}
{{ ref('core_fct_subscription_escalators') }}

-- NEW (verified refs verified):
{{ ref('transform_corporations_subscriptions') }}
{{ ref('transform_corporations_subscription_charges') }}
{{ ref('transform_corporations_subscription_payment_windows') }}
{{ ref('transform_corporations_subscription_tiers') }}
{{ ref('transform_corporations_subscription_features') }}
{{ ref('transform_corporations_subscription_thresholds') }}
{{ ref('transform_corporations_subscription_escalators') }}
```

**CRITICAL:** Only update models in `models_verified/`. Models in `models_scratch/` should continue referencing the `_scratch` versions.

---

## Phase-by-Phase Execution Plan

### Phase 1: Setup & Branch Creation (5 minutes)

#### Step 1.1: Create Jira Ticket

```bash
acli jira workitem create \
  --summary "Migrate 7 subscription models from core to transform layer" \
  --project "DA" \
  --type "Task" \
  --description "Move core_dim_subscriptions and 6 dependencies to transform layer to resolve CORE→CORE layer violations in verified/. This migration enables proper layer separation and complies with verified/ architecture rules." \
  --assignee "@me"
```

**Expected Output:**
```
DA-XXXX created successfully
```

**Action:** Note the ticket number (e.g., DA-3890) for git branch naming.

#### Step 1.2: View Ticket to Confirm

```bash
acli jira workitem view DA-XXXX
```

**Expected Output:** Full ticket details including description and assignee.

#### Step 1.3: Create Git Branch

```bash
cd /Users/klajdi.ziaj/ds-redshift
git fetch origin
git switch main
git pull origin main
git switch -c th/da-XXXX/migrate-subscriptions-to-transform
```

**Expected Output:**
```
Switched to a new branch 'th/da-XXXX/migrate-subscriptions-to-transform'
```

**Validation:**
```bash
git branch --show-current
```

**Expected:** `th/da-XXXX/migrate-subscriptions-to-transform`

---

### Phase 2: Rename Scratch Models with _scratch Suffix (15 minutes)

**Purpose:** Preserve scratch versions with `_scratch` suffix and alias configs to maintain Snowflake table names.

**Command Used:** `~/.claude/commands/migrate-model-to-scratch`

**What This Command Does:**
1. Renames file with `_scratch` suffix
2. Adds dbt config with alias to preserve original table name
3. Updates all refs within the file to point to `_scratch` versions
4. Stages git changes

#### Step 2.1: Migrate Model 1 - core_dim_subscriptions

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_dim_subscriptions.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_dim_subscriptions_scratch.sql
✓ Added alias config: core_dim_subscriptions
✓ Updated 5 internal refs to _scratch versions
✓ Staged changes
```

**File Changes:**
- **Created:** `models_scratch/core/subscriptions/core_dim_subscriptions_scratch.sql`
- **Deleted:** `models_scratch/core/subscriptions/core_dim_subscriptions.sql`

**Config Added to File:**
```sql
{{
  config(
    alias='core_dim_subscriptions',
    -- existing configs preserved
  )
}}
```

**Internal Refs Updated:**
```sql
-- BEFORE:
{{ ref('core_dim_subscription_charges') }}
{{ ref('core_dim_subscription_payment_windows') }}
{{ ref('core_dim_subscription_tiers') }}
{{ ref('core_fct_subscription_active_features') }}
{{ ref('core_fct_subscription_customer_threshold_history') }}

-- AFTER:
{{ ref('core_dim_subscription_charges_scratch') }}
{{ ref('core_dim_subscription_payment_windows_scratch') }}
{{ ref('core_dim_subscription_tiers_scratch') }}
{{ ref('core_fct_subscription_active_features_scratch') }}
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}
```

#### Step 2.2: Migrate Model 2 - core_dim_subscription_charges

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_dim_subscription_charges.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_dim_subscription_charges_scratch.sql
✓ Added alias config: core_dim_subscription_charges
✓ Updated 0 internal refs (no refs to other core models)
✓ Staged changes
```

**File Changes:**
- **Created:** `models_scratch/core/subscriptions/core_dim_subscription_charges_scratch.sql`
- **Deleted:** `models_scratch/core/subscriptions/core_dim_subscription_charges.sql`

#### Step 2.3: Migrate Model 3 - core_dim_subscription_payment_windows

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_dim_subscription_payment_windows.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_dim_subscription_payment_windows_scratch.sql
✓ Added alias config: core_dim_subscription_payment_windows
✓ Updated 2 internal refs to _scratch versions
✓ Staged changes
```

**Internal Refs Updated:**
```sql
-- BEFORE:
{{ ref('core_fct_subscription_escalators') }}
{{ ref('core_fct_subscription_customer_threshold_history') }}

-- AFTER:
{{ ref('core_fct_subscription_escalators_scratch') }}
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}
```

#### Step 2.4: Migrate Model 4 - core_dim_subscription_tiers

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_dim_subscription_tiers.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_dim_subscription_tiers_scratch.sql
✓ Added alias config: core_dim_subscription_tiers
✓ Updated 2 internal refs to _scratch versions
✓ Staged changes
```

**Internal Refs Updated:**
```sql
-- BEFORE:
{{ ref('core_dim_subscription_payment_windows') }}
{{ ref('core_fct_subscription_customer_threshold_history') }}

-- AFTER:
{{ ref('core_dim_subscription_payment_windows_scratch') }}
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}
```

#### Step 2.5: Migrate Model 5 - core_fct_subscription_active_features

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_fct_subscription_active_features.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_fct_subscription_active_features_scratch.sql
✓ Added alias config: core_fct_subscription_active_features
✓ Updated 0 internal refs (no refs to other core models)
✓ Staged changes
```

#### Step 2.6: Migrate Model 6 - core_fct_subscription_customer_threshold_history

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history_scratch.sql
✓ Added alias config: core_fct_subscription_customer_threshold_history
✓ Updated 0 internal refs (no refs to other core models)
✓ Staged changes
```

#### Step 2.7: Migrate Model 7 - core_fct_subscription_escalators

```bash
~/.claude/commands/migrate-model-to-scratch models_scratch/core/subscriptions/core_fct_subscription_escalators.sql
```

**Expected Output:**
```
✓ Renamed to: models_scratch/core/subscriptions/core_fct_subscription_escalators_scratch.sql
✓ Added alias config: core_fct_subscription_escalators
✓ Updated 0 internal refs (no refs to other core models)
✓ Staged changes
```

#### Step 2.8: Review Scratch Changes

```bash
git status
```

**Expected Output:**
```
On branch th/da-XXXX/migrate-subscriptions-to-transform
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        deleted:    models_scratch/core/subscriptions/core_dim_subscription_charges.sql
        deleted:    models_scratch/core/subscriptions/core_dim_subscription_payment_windows.sql
        deleted:    models_scratch/core/subscriptions/core_dim_subscription_tiers.sql
        deleted:    models_scratch/core/subscriptions/core_dim_subscriptions.sql
        deleted:    models_scratch/core/subscriptions/core_fct_subscription_active_features.sql
        deleted:    models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history.sql
        deleted:    models_scratch/core/subscriptions/core_fct_subscription_escalators.sql
        new file:   models_scratch/core/subscriptions/core_dim_subscription_charges_scratch.sql
        new file:   models_scratch/core/subscriptions/core_dim_subscription_payment_windows_scratch.sql
        new file:   models_scratch/core/subscriptions/core_dim_subscription_tiers_scratch.sql
        new file:   models_scratch/core/subscriptions/core_dim_subscriptions_scratch.sql
        new file:   models_scratch/core/subscriptions/core_fct_subscription_active_features_scratch.sql
        new file:   models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history_scratch.sql
        new file:   models_scratch/core/subscriptions/core_fct_subscription_escalators_scratch.sql
```

**Validation:**
- 7 files deleted (original versions)
- 7 files created (with `_scratch` suffix)
- All changes staged

---

### Phase 3: Create Verified Transform Models (45 minutes)

**Purpose:** Create production-ready transform models in verified/ with clean names and proper layer references.

#### Step 3.1: Create Directory Structure

```bash
mkdir -p models_verified/transform/corporations/supporting
```

**Expected:** Directory created silently.

**Validation:**
```bash
ls -la models_verified/transform/corporations/
```

**Expected Output:**
```
drwxr-xr-x  supporting/
```

#### Step 3.2: Create Model 1 - transform_corporations_subscriptions (Main)

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version to understand business logic:**
```bash
# Review the scratch version to understand what it does
cat models_scratch/core/subscriptions/core_dim_subscriptions_scratch.sql
```

**Step 2: CREATE NEW file in verified/:**
```bash
# Create new file (not copy!)
touch models_verified/transform/corporations/transform_corporations_subscriptions.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config** (verified models don't need aliases):
```sql
-- DELETE THIS BLOCK:
{{
  config(
    alias='core_dim_subscriptions',
    -- keep other configs
  )
}}

-- REPLACE WITH:
{{
  config(
    sort='subscription_id',
    dist='corporation_id',
    unique_key='subscription_id',
    materialized='table'
  )
}}
```

2. **Update internal refs** to point to verified transform models:
```sql
-- OLD:
{{ ref('core_dim_subscription_charges_scratch') }}
{{ ref('core_dim_subscription_payment_windows_scratch') }}
{{ ref('core_dim_subscription_tiers_scratch') }}
{{ ref('core_fct_subscription_active_features_scratch') }}
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}

-- NEW:
{{ ref('transform_corporations_subscription_charges') }}
{{ ref('transform_corporations_subscription_payment_windows') }}
{{ ref('transform_corporations_subscription_tiers') }}
{{ ref('transform_corporations_subscription_features') }}
{{ ref('transform_corporations_subscription_thresholds') }}
```

3. **Keep base refs unchanged** - these stay as-is:
```sql
-- NO CHANGES NEEDED:
{{ ref('base_revenue_service_subscription') }}
{{ ref('base_revenue_service_plan') }}
{{ ref('base_revenue_service_charge') }}
-- ... etc (all 11 base refs stay unchanged)
```

**Validation:**
```bash
grep -c "ref('transform_" models_verified/transform/corporations/transform_corporations_subscriptions.sql
```

**Expected:** 5 (matches 5 internal transform refs)

```bash
grep -c "ref('base_" models_verified/transform/corporations/transform_corporations_subscriptions.sql
```

**Expected:** 11 (matches 11 base refs)

#### Step 3.3: Create Model 2 - transform_corporations_subscription_charges

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version:**
```bash
cat models_scratch/core/subscriptions/core_dim_subscription_charges_scratch.sql
```

**Step 2: CREATE NEW file:**
```bash
touch models_verified/transform/corporations/supporting/transform_corporations_subscription_charges.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config**:
```sql
{{
  config(
    sort='charge_id',
    dist='corporation_id',
    unique_key='charge_id',
    materialized='table'
  )
}}
```

2. **Update refs:** This model has NO internal refs to other core models, only base refs. Base refs stay unchanged.

3. **Verify no _scratch refs remain:**
```bash
grep "_scratch" models_verified/transform/corporations/supporting/transform_corporations_subscription_charges.sql
```

**Expected:** No matches (exit code 1)

#### Step 3.4: Create Model 3 - transform_corporations_subscription_payment_windows

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version:**
```bash
cat models_scratch/core/subscriptions/core_dim_subscription_payment_windows_scratch.sql
```

**Step 2: CREATE NEW file:**
```bash
touch models_verified/transform/corporations/supporting/transform_corporations_subscription_payment_windows.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config**:
```sql
{{
  config(
    sort='subscription_id',
    dist='corporation_id',
    unique_key='_pk',
    materialized='table'
  )
}}
```

2. **Update internal refs**:
```sql
-- OLD:
{{ ref('core_fct_subscription_escalators_scratch') }}
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}

-- NEW:
{{ ref('transform_corporations_subscription_escalators') }}
{{ ref('transform_corporations_subscription_thresholds') }}
```

3. **Verify snapshot source ref unchanged**:
```sql
-- SHOULD REMAIN:
{{ source('dbt_core', 'source_core_dim_subscription_payment_windows_snapshot') }}
```

**Validation:**
```bash
grep -c "ref('transform_" models_verified/transform/corporations/supporting/transform_corporations_subscription_payment_windows.sql
```

**Expected:** 2 (escalators + thresholds)

#### Step 3.5: Create Model 4 - transform_corporations_subscription_tiers

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version:**
```bash
cat models_scratch/core/subscriptions/core_dim_subscription_tiers_scratch.sql
```

**Step 2: CREATE NEW file:**
```bash
touch models_verified/transform/corporations/supporting/transform_corporations_subscription_tiers.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config**:
```sql
{{
  config(
    sort='subscription_id',
    dist='corporation_id',
    materialized='table'
  )
}}
```

2. **Update internal refs**:
```sql
-- OLD:
{{ ref('core_dim_subscription_payment_windows_scratch') }}
{{ ref('core_fct_subscription_customer_threshold_history_scratch') }}

-- NEW:
{{ ref('transform_corporations_subscription_payment_windows') }}
{{ ref('transform_corporations_subscription_thresholds') }}
```

**Validation:**
```bash
grep -c "ref('transform_" models_verified/transform/corporations/supporting/transform_corporations_subscription_tiers.sql
```

**Expected:** 2 (payment_windows + thresholds)

#### Step 3.6: Create Model 5 - transform_corporations_subscription_features

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version:**
```bash
cat models_scratch/core/subscriptions/core_fct_subscription_active_features_scratch.sql
```

**Step 2: CREATE NEW file:**
```bash
touch models_verified/transform/corporations/supporting/transform_corporations_subscription_features.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config**:
```sql
{{
  config(
    sort=['as_of_date', 'corporation_id'],
    dist='corporation_id',
    materialized='table'
  )
}}
```

2. **Update refs:** This model has NO internal refs to other core models, only base refs. Base refs stay unchanged.

3. **Verify source refs unchanged:**
```sql
-- SHOULD REMAIN:
{{ source('dbt_core', 'series_dates') }}
```

#### Step 3.7: Create Model 6 - transform_corporations_subscription_thresholds

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version:**
```bash
cat models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history_scratch.sql
```

**Step 2: CREATE NEW file:**
```bash
touch models_verified/transform/corporations/supporting/transform_corporations_subscription_thresholds.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config**:
```sql
{{
  config(
    sort=['as_of_date', 'corporation_id'],
    dist='corporation_id',
    pre_hook="SET statement_timeout = 7200000;",
    unique_key='_pk',
    materialized='table'
  )
}}
```

2. **Update refs:** This model has NO internal refs to other core models, only base refs. Base refs stay unchanged.

3. **Verify source refs unchanged:**
```sql
-- SHOULD REMAIN:
{{ source('dbt_core', 'series_dates') }}
```

#### Step 3.8: Create Model 7 - transform_corporations_subscription_escalators

**⚠️ CRITICAL: Do NOT copy the file. Create a NEW file from scratch.**

**Step 1: READ scratch version:**
```bash
cat models_scratch/core/subscriptions/core_fct_subscription_escalators_scratch.sql
```

**Step 2: CREATE NEW file:**
```bash
touch models_verified/transform/corporations/supporting/transform_corporations_subscription_escalators.sql
```

**Step 3: WRITE SQL following verified/ conventions:**

1. **Remove alias config**:
```sql
{{
  config(
    dist='corporation_id',
    unique_key='_pk',
    materialized='table'
  )
}}
```

2. **Update refs:** This model has NO internal refs to other core models, only base refs. Base refs stay unchanged.

**Validation:**
```bash
grep "_scratch" models_verified/transform/corporations/supporting/transform_corporations_subscription_escalators.sql
```

**Expected:** No matches (exit code 1)

#### Step 3.9: Review Verified Transform Models

```bash
ls -la models_verified/transform/corporations/
ls -la models_verified/transform/corporations/supporting/
```

**Expected Output:**
```
models_verified/transform/corporations/:
-rw-r--r--  transform_corporations_subscriptions.sql

models_verified/transform/corporations/supporting/:
-rw-r--r--  transform_corporations_subscription_charges.sql
-rw-r--r--  transform_corporations_subscription_escalators.sql
-rw-r--r--  transform_corporations_subscription_features.sql
-rw-r--r--  transform_corporations_subscription_payment_windows.sql
-rw-r--r--  transform_corporations_subscription_thresholds.sql
-rw-r--r--  transform_corporations_subscription_tiers.sql
```

**Validation:** 7 new files created (1 main + 6 supporting)

#### Step 3.10: Verify No _scratch Refs in Verified Models

```bash
grep -r "_scratch" models_verified/transform/corporations/
```

**Expected:** No matches (exit code 1)

**If matches found:** This indicates incomplete ref updates. Go back and fix.

#### Step 3.11: Stage Verified Changes

```bash
git add models_verified/transform/corporations/
```

**Validation:**
```bash
git status
```

**Expected Output:**
```
On branch th/da-XXXX/migrate-subscriptions-to-transform
Changes to be committed:
  ... (14 changes from Phase 2)
  new file:   models_verified/transform/corporations/supporting/transform_corporations_subscription_charges.sql
  new file:   models_verified/transform/corporations/supporting/transform_corporations_subscription_escalators.sql
  new file:   models_verified/transform/corporations/supporting/transform_corporations_subscription_features.sql
  new file:   models_verified/transform/corporations/supporting/transform_corporations_subscription_payment_windows.sql
  new file:   models_verified/transform/corporations/supporting/transform_corporations_subscription_thresholds.sql
  new file:   models_verified/transform/corporations/supporting/transform_corporations_subscription_tiers.sql
  new file:   models_verified/transform/corporations/transform_corporations_subscriptions.sql
```

---

### Phase 3.2: Create/Update YAML Files (20 minutes) **← CRITICAL NEW PHASE**

**Purpose:** Create or update YAML schema files for all 7 verified transform models with proper `name:` and `description:` fields.

**⚠️ CRITICAL:** Pre-commit hooks **REQUIRE** all models to have:
1. A `.yml` file with matching basename
2. A `name:` field matching the SQL filename
3. A `description:` field (cannot be empty)

**Failure to do this will cause CI failures** (learned from PR #9012 where 59 models failed check-model-has-description).

---

#### Step 3.2.1: Create YAML for Main Model - transform_corporations_subscriptions

**Create file:** `models_verified/transform/corporations/transform_corporations_subscriptions.yml`

**Template:**
```yaml
version: 2
models:
  - name: transform_corporations_subscriptions
    description: 'Main subscription dimension table with comprehensive subscription data including charges, payment windows, tiers, features, and thresholds. Transformed from core_dim_subscriptions to comply with verified/ layer architecture.'
    columns:
      - name: subscription_id
        description: 'Primary key - unique subscription identifier'
        tests:
          - unique
          - not_null
      - name: corporation_id
        description: 'Foreign key to corporations'
        tests:
          - not_null
      - name: is_active
        description: 'Boolean indicating if subscription is currently active'
      - name: yearly_value_dollars_net
        description: 'Net annual recurring revenue (ARR) for this subscription'
      - name: activation_date
        description: 'Date subscription was activated'
      - name: deactivation_date
        description: 'Date subscription was deactivated (null if active)'
      - name: type
        description: 'Subscription type (e.g., standard, enterprise)'
      - name: product
        description: 'Product name for this subscription'
      # Add remaining columns as needed
```

**Validation:**
```bash
grep "name: transform_corporations_subscriptions" models_verified/transform/corporations/transform_corporations_subscriptions.yml
grep "description:" models_verified/transform/corporations/transform_corporations_subscriptions.yml
```

**Expected:** Both commands return matches.

---

#### Step 3.2.2: Create YAMLs for Supporting Models (6 files)

**Create file:** `models_verified/transform/corporations/supporting/transform_corporations_subscription_charges.yml`

**Template:**
```yaml
version: 2
models:
  - name: transform_corporations_subscription_charges
    description: 'Charge records for subscriptions including amounts, statuses, and pricing details'
    columns:
      - name: charge_id
        description: 'Primary key - unique charge identifier'
        tests:
          - unique
          - not_null
      - name: subscription_id
        description: 'Foreign key to subscriptions'
      - name: amount_cents
        description: 'Charge amount in cents'
      - name: status
        description: 'Charge status (active, cancelled, etc.)'
```

**Repeat for remaining 5 supporting models:**

1. `transform_corporations_subscription_payment_windows.yml`
2. `transform_corporations_subscription_tiers.yml`
3. `transform_corporations_subscription_features.yml`
4. `transform_corporations_subscription_thresholds.yml`
5. `transform_corporations_subscription_escalators.yml`

**Template Pattern for All Supporting Models:**
```yaml
version: 2
models:
  - name: MODEL_NAME_HERE
    description: 'Brief description of what this model contains and its purpose'
    columns:
      - name: PRIMARY_KEY_COLUMN
        description: 'Primary key description'
        tests:
          - unique
          - not_null
      # Add key columns with descriptions
```

---

#### Step 3.2.3: Update Scratch Model YAMLs

**CRITICAL:** If scratch models don't have YAMLs yet, create them too:

**Pattern:** Copy existing YAML or create new one for each `_scratch` model:

```yaml
version: 2
models:
  - name: core_dim_subscriptions_scratch
    description: 'Scratch version - deprecated, use transform_corporations_subscriptions instead'
    columns:
      # Copy column definitions from transform version
```

**Repeat for all 7 scratch models** if YAMLs don't exist.

---

#### Step 3.2.4: Validate YAML Files Match SQL Files

**Check that every SQL file has a matching YAML:**

```bash
# Check verified models
ls models_verified/transform/corporations/*.sql | sed 's/.sql$//' | while read base; do
  if [ ! -f "${base}.yml" ]; then
    echo "MISSING YAML: ${base}.yml"
  fi
done

ls models_verified/transform/corporations/supporting/*.sql | sed 's/.sql$//' | while read base; do
  if [ ! -f "${base}.yml" ]; then
    echo "MISSING YAML: ${base}.yml"
  fi
done

# Check scratch models
ls models_scratch/core/subscriptions/*_scratch.sql | sed 's/.sql$//' | while read base; do
  if [ ! -f "${base}.yml" ]; then
    echo "MISSING YAML: ${base}.yml"
  fi
done
```

**Expected:** No output (all YAMLs exist)

**If missing YAMLs found:** Create them using templates above.

---

#### Step 3.2.5: Validate name: Fields Match Filenames

```bash
# Validate transform models
for yml in models_verified/transform/corporations/*.yml models_verified/transform/corporations/supporting/*.yml; do
  basename=$(basename "$yml" .yml)
  if ! grep -q "name: $basename" "$yml"; then
    echo "MISMATCH: $yml name field doesn't match filename"
  fi
done

# Validate scratch models
for yml in models_scratch/core/subscriptions/*_scratch.yml; do
  basename=$(basename "$yml" .yml)
  if ! grep -q "name: $basename" "$yml"; then
    echo "MISMATCH: $yml name field doesn't match filename"
  fi
done
```

**Expected:** No output (all names match)

**If mismatches found:** Edit YAML files to fix `name:` fields.

---

#### Step 3.2.6: Validate All Models Have Descriptions

```bash
# Check for missing descriptions
for yml in models_verified/transform/corporations/*.yml models_verified/transform/corporations/supporting/*.yml models_scratch/core/subscriptions/*_scratch.yml; do
  if ! grep -A 1 "- name:" "$yml" | grep -q "description:"; then
    echo "MISSING DESCRIPTION: $yml"
  fi
done
```

**Expected:** No output (all models have descriptions)

**If missing descriptions:** Add placeholder descriptions:
```yaml
description: 'Model description pending - verify/transform migration'
```

---

#### Step 3.2.7: Stage YAML Changes

```bash
git add models_verified/transform/corporations/*.yml
git add models_verified/transform/corporations/supporting/*.yml
git add models_scratch/core/subscriptions/*.yml
```

**Validation:**
```bash
git status
```

**Expected:** YAML files staged alongside SQL files.

---

### Phase 3.5: Data Quality Validation (30 minutes) **← CRITICAL NEW PHASE**

**Purpose:** Validate that each verified transform model produces identical data to its scratch counterpart before proceeding to downstream updates.

**CRITICAL:** Do NOT proceed to Phase 4 until ALL 7 models pass data quality validation.

---

#### Data Quality Validation Strategy

For each of the 7 models, we must:
1. Run both scratch and verified versions
2. Compare row counts (must match exactly)
3. Compare data checksums/hashes (must match exactly)
4. Compare key columns for business logic validation
5. Document any discrepancies and fix before proceeding

**Failure Handling:** If ANY validation fails, STOP immediately, investigate, and fix the verified model before continuing.

---

#### Step 3.5.1: Validate Model 1 - transform_corporations_subscriptions

**Run Both Versions:**
```bash
dbt run --models core_dim_subscriptions_scratch
dbt run --models transform_corporations_subscriptions
```

**Expected:** Both models execute successfully.

**Validation Query 1: Row Count Comparison**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions,
  COUNT(DISTINCT corporation_id) AS unique_corporations
FROM prod_db.dbt_core.core_dim_subscriptions
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions,
  COUNT(DISTINCT corporation_id) AS unique_corporations
FROM prod_db.dbt_core.transform_corporations_subscriptions
" --format JSON
```

**Expected Output:**
```json
[
  {"VERSION": "scratch", "ROW_COUNT": XXXXX, "UNIQUE_SUBSCRIPTIONS": XXXXX, "UNIQUE_CORPORATIONS": XXXXX},
  {"VERSION": "verified", "ROW_COUNT": XXXXX, "UNIQUE_SUBSCRIPTIONS": XXXXX, "UNIQUE_CORPORATIONS": XXXXX}
]
```

**Validation:** All counts must match exactly between scratch and verified.

**Validation Query 2: Key Column Differences**
```bash
snow sql --query "
WITH scratch AS (
  SELECT 
    subscription_id,
    corporation_id,
    is_active,
    yearly_value_dollars_net,
    activation_date,
    deactivation_date,
    type,
    product
  FROM prod_db.dbt_core.core_dim_subscriptions
),
verified AS (
  SELECT 
    subscription_id,
    corporation_id,
    is_active,
    yearly_value_dollars_net,
    activation_date,
    deactivation_date,
    type,
    product
  FROM prod_db.dbt_core.transform_corporations_subscriptions
)
SELECT 
  COALESCE(s.subscription_id, v.subscription_id) AS subscription_id,
  s.corporation_id AS scratch_corp_id,
  v.corporation_id AS verified_corp_id,
  s.is_active AS scratch_is_active,
  v.is_active AS verified_is_active,
  s.yearly_value_dollars_net AS scratch_arr,
  v.yearly_value_dollars_net AS verified_arr,
  s.type AS scratch_type,
  v.type AS verified_type,
  s.product AS scratch_product,
  v.product AS verified_product,
  CASE 
    WHEN s.subscription_id IS NULL THEN 'Missing in scratch'
    WHEN v.subscription_id IS NULL THEN 'Missing in verified'
    WHEN s.is_active != v.is_active THEN 'is_active mismatch'
    WHEN ABS(COALESCE(s.yearly_value_dollars_net,0) - COALESCE(v.yearly_value_dollars_net,0)) > 0.01 THEN 'ARR mismatch'
    WHEN s.type != v.type THEN 'type mismatch'
    WHEN s.product != v.product THEN 'product mismatch'
    ELSE 'other mismatch'
  END AS difference_type
FROM scratch s
FULL OUTER JOIN verified v ON s.subscription_id = v.subscription_id
WHERE s.subscription_id IS NULL 
   OR v.subscription_id IS NULL
   OR s.corporation_id != v.corporation_id
   OR s.is_active != v.is_active
   OR ABS(COALESCE(s.yearly_value_dollars_net,0) - COALESCE(v.yearly_value_dollars_net,0)) > 0.01
   OR s.activation_date != v.activation_date
   OR COALESCE(s.deactivation_date, '9999-12-31') != COALESCE(v.deactivation_date, '9999-12-31')
   OR s.type != v.type
   OR s.product != v.product
LIMIT 100
" --format JSON
```

**Expected:** 0 rows returned (empty array `[]`).

**If discrepancies found:** Review SQL logic differences, fix verified model, re-run, and re-validate.

---

#### Step 3.5.2: Validate Model 2 - transform_corporations_subscription_charges

**Run Both Versions:**
```bash
dbt run --models core_dim_subscription_charges_scratch
dbt run --models transform_corporations_subscription_charges
```

**Validation Query: Row Count & Key Column Comparison**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT charge_id) AS unique_charges,
  SUM(amount_cents) AS total_amount_cents
FROM prod_db.dbt_core.core_dim_subscription_charges
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT charge_id) AS unique_charges,
  SUM(amount_cents) AS total_amount_cents
FROM prod_db.dbt_core.transform_corporations_subscription_charges
" --format JSON
```

**Expected:** All metrics match exactly.

**Detailed Difference Check:**
```bash
snow sql --query "
SELECT 
  COALESCE(s.charge_id, v.charge_id) AS charge_id,
  s.subscription_id AS scratch_sub_id,
  v.subscription_id AS verified_sub_id,
  s.status AS scratch_status,
  v.status AS verified_status,
  s.amount_cents AS scratch_amount,
  v.amount_cents AS verified_amount
FROM prod_db.dbt_core.core_dim_subscription_charges s
FULL OUTER JOIN prod_db.dbt_core.transform_corporations_subscription_charges v 
  ON s.charge_id = v.charge_id
WHERE s.charge_id IS NULL 
   OR v.charge_id IS NULL
   OR s.subscription_id != v.subscription_id
   OR s.status != v.status
   OR s.amount_cents != v.amount_cents
LIMIT 100
" --format JSON
```

**Expected:** 0 rows.

---

#### Step 3.5.3: Validate Model 3 - transform_corporations_subscription_payment_windows

**Run Both Versions:**
```bash
dbt run --models core_dim_subscription_payment_windows_scratch
dbt run --models transform_corporations_subscription_payment_windows
```

**Validation Query:**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_windows,
  SUM(yearly_value_dollars_net) AS total_arr_net,
  MIN(sub_payment_start) AS earliest_start,
  MAX(sub_payment_end_final) AS latest_end
FROM prod_db.dbt_core.core_dim_subscription_payment_windows
WHERE is_valid
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_windows,
  SUM(yearly_value_dollars_net) AS total_arr_net,
  MIN(sub_payment_start) AS earliest_start,
  MAX(sub_payment_end_final) AS latest_end
FROM prod_db.dbt_core.transform_corporations_subscription_payment_windows
WHERE is_valid
" --format JSON
```

**Expected:** All metrics match, especially total ARR.

**Critical ARR Validation:**
```bash
snow sql --query "
SELECT 
  COALESCE(s._pk, v._pk) AS window_pk,
  s.yearly_value_dollars_net AS scratch_arr,
  v.yearly_value_dollars_net AS verified_arr,
  ABS(COALESCE(s.yearly_value_dollars_net,0) - COALESCE(v.yearly_value_dollars_net,0)) AS arr_difference
FROM prod_db.dbt_core.core_dim_subscription_payment_windows s
FULL OUTER JOIN prod_db.dbt_core.transform_corporations_subscription_payment_windows v 
  ON s._pk = v._pk
WHERE s._pk IS NULL 
   OR v._pk IS NULL
   OR ABS(COALESCE(s.yearly_value_dollars_net,0) - COALESCE(v.yearly_value_dollars_net,0)) > 0.01
LIMIT 100
" --format JSON
```

**Expected:** 0 rows (ARR calculations must match exactly).

---

#### Step 3.5.4: Validate Model 4 - transform_corporations_subscription_tiers

**Run Both Versions:**
```bash
dbt run --models core_dim_subscription_tiers_scratch
dbt run --models transform_corporations_subscription_tiers
```

**Validation Query:**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions
FROM prod_db.dbt_core.core_dim_subscription_tiers
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions
FROM prod_db.dbt_core.transform_corporations_subscription_tiers
" --format JSON
```

**Expected:** Counts match.

---

#### Step 3.5.5: Validate Model 5 - transform_corporations_subscription_features

**Run Both Versions:**
```bash
dbt run --models core_fct_subscription_active_features_scratch
dbt run --models transform_corporations_subscription_features
```

**Validation Query:**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_feature_days,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions,
  COUNT(DISTINCT feature_name) AS unique_features
FROM prod_db.dbt_core.core_fct_subscription_active_features
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_feature_days,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions,
  COUNT(DISTINCT feature_name) AS unique_features
FROM prod_db.dbt_core.transform_corporations_subscription_features
" --format JSON
```

**Expected:** All metrics match.

---

#### Step 3.5.6: Validate Model 6 - transform_corporations_subscription_thresholds

**Run Both Versions:**
```bash
dbt run --models core_fct_subscription_customer_threshold_history_scratch
dbt run --models transform_corporations_subscription_thresholds
```

**Validation Query:**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_threshold_records,
  SUM(threshold_count) AS total_threshold_count,
  MIN(as_of_date) AS earliest_date,
  MAX(as_of_date) AS latest_date
FROM prod_db.dbt_core.core_fct_subscription_customer_threshold_history
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_threshold_records,
  SUM(threshold_count) AS total_threshold_count,
  MIN(as_of_date) AS earliest_date,
  MAX(as_of_date) AS latest_date
FROM prod_db.dbt_core.transform_corporations_subscription_thresholds
" --format JSON
```

**Expected:** All metrics match, especially threshold counts.

---

#### Step 3.5.7: Validate Model 7 - transform_corporations_subscription_escalators

**Run Both Versions:**
```bash
dbt run --models core_fct_subscription_escalators_scratch
dbt run --models transform_corporations_subscription_escalators
```

**Validation Query:**
```bash
snow sql --query "
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_escalators,
  AVG(escalator_percent) AS avg_escalator_pct
FROM prod_db.dbt_core.core_fct_subscription_escalators
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_escalators,
  AVG(escalator_percent) AS avg_escalator_pct
FROM prod_db.dbt_core.transform_corporations_subscription_escalators
" --format JSON
```

**Expected:** All metrics match.

---

#### Step 3.5.8: Summary Validation Report

**Create validation summary:**
```bash
cat > /tmp/dqv_summary.txt << 'EOF'
=== DATA QUALITY VALIDATION SUMMARY ===

✓ Model 1: transform_corporations_subscriptions - PASSED
✓ Model 2: transform_corporations_subscription_charges - PASSED
✓ Model 3: transform_corporations_subscription_payment_windows - PASSED
✓ Model 4: transform_corporations_subscription_tiers - PASSED
✓ Model 5: transform_corporations_subscription_features - PASSED
✓ Model 6: transform_corporations_subscription_thresholds - PASSED
✓ Model 7: transform_corporations_subscription_escalators - PASSED

All 7 models validated successfully.
Row counts match.
Key column values match.
ARR calculations match.
Ready to proceed to Phase 4.
EOF

cat /tmp/dqv_summary.txt
```

**GATE CHECK:** All 7 models must show PASSED. If ANY fail, do NOT proceed to Phase 4.

---

### Phase 4: Update Downstream References (30 minutes)

**Purpose:** Update all models in verified/ that reference the old core model names to use new transform names.

#### Step 4.1: Find All Downstream References

```bash
grep -r "ref('core_dim_subscriptions')" models_verified/ | wc -l
grep -r "ref('core_dim_subscription_charges')" models_verified/ | wc -l
grep -r "ref('core_dim_subscription_payment_windows')" models_verified/ | wc -l
grep -r "ref('core_dim_subscription_tiers')" models_verified/ | wc -l
grep -r "ref('core_fct_subscription_active_features')" models_verified/ | wc -l
grep -r "ref('core_fct_subscription_customer_threshold_history')" models_verified/ | wc -l
grep -r "ref('core_fct_subscription_escalators')" models_verified/ | wc -l
```

**Expected:** Various counts (estimated ~39 total references across all 7 models)

**Action:** Save full list of files:
```bash
grep -rl "ref('core_dim_subscriptions')" models_verified/ > /tmp/downstream_files.txt
grep -rl "ref('core_dim_subscription_charges')" models_verified/ >> /tmp/downstream_files.txt
grep -rl "ref('core_dim_subscription_payment_windows')" models_verified/ >> /tmp/downstream_files.txt
grep -rl "ref('core_dim_subscription_tiers')" models_verified/ >> /tmp/downstream_files.txt
grep -rl "ref('core_fct_subscription_active_features')" models_verified/ >> /tmp/downstream_files.txt
grep -rl "ref('core_fct_subscription_customer_threshold_history')" models_verified/ >> /tmp/downstream_files.txt
grep -rl "ref('core_fct_subscription_escalators')" models_verified/ >> /tmp/downstream_files.txt
sort -u /tmp/downstream_files.txt
```

**Expected Output:** List of unique file paths that need updates.

#### Step 4.2: Update References Using sed

**Pattern 1: core_dim_subscriptions → transform_corporations_subscriptions**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_dim_subscriptions')/ref('transform_corporations_subscriptions')/g" {} +
```

**Pattern 2: core_dim_subscription_charges → transform_corporations_subscription_charges**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_dim_subscription_charges')/ref('transform_corporations_subscription_charges')/g" {} +
```

**Pattern 3: core_dim_subscription_payment_windows → transform_corporations_subscription_payment_windows**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_dim_subscription_payment_windows')/ref('transform_corporations_subscription_payment_windows')/g" {} +
```

**Pattern 4: core_dim_subscription_tiers → transform_corporations_subscription_tiers**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_dim_subscription_tiers')/ref('transform_corporations_subscription_tiers')/g" {} +
```

**Pattern 5: core_fct_subscription_active_features → transform_corporations_subscription_features**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_fct_subscription_active_features')/ref('transform_corporations_subscription_features')/g" {} +
```

**Pattern 6: core_fct_subscription_customer_threshold_history → transform_corporations_subscription_thresholds**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_fct_subscription_customer_threshold_history')/ref('transform_corporations_subscription_thresholds')/g" {} +
```

**Pattern 7: core_fct_subscription_escalators → transform_corporations_subscription_escalators**

```bash
find models_verified/ -type f -name "*.sql" -exec sed -i '' \
  "s/ref('core_fct_subscription_escalators')/ref('transform_corporations_subscription_escalators')/g" {} +
```

#### Step 4.3: Verify Replacements

```bash
grep -r "ref('core_dim_subscriptions')" models_verified/ | wc -l
grep -r "ref('core_dim_subscription_charges')" models_verified/ | wc -l
grep -r "ref('core_dim_subscription_payment_windows')" models_verified/ | wc -l
grep -r "ref('core_dim_subscription_tiers')" models_verified/ | wc -l
grep -r "ref('core_fct_subscription_active_features')" models_verified/ | wc -l
grep -r "ref('core_fct_subscription_customer_threshold_history')" models_verified/ | wc -l
grep -r "ref('core_fct_subscription_escalators')" models_verified/ | wc -l
```

**Expected:** All counts should be 0 (no old refs remaining in verified/)

**If non-zero:** Review remaining references manually and fix.

#### Step 4.4: Verify New References Exist

```bash
grep -r "ref('transform_corporations_subscriptions')" models_verified/ | wc -l
grep -r "ref('transform_corporations_subscription_charges')" models_verified/ | wc -l
grep -r "ref('transform_corporations_subscription_payment_windows')" models_verified/ | wc -l
grep -r "ref('transform_corporations_subscription_tiers')" models_verified/ | wc -l
grep -r "ref('transform_corporations_subscription_features')" models_verified/ | wc -l
grep -r "ref('transform_corporations_subscription_thresholds')" models_verified/ | wc -l
grep -r "ref('transform_corporations_subscription_escalators')" models_verified/ | wc -l
```

**Expected:** Counts should match the original downstream ref counts from Step 4.1.

#### Step 4.5: Confirm Scratch Refs Unchanged

**CRITICAL:** Verify that models in scratch/ still reference the `_scratch` versions:

```bash
grep -r "ref('core_dim_subscriptions')" models_scratch/ | wc -l
```

**Expected:** 0 (should now be `core_dim_subscriptions_scratch`)

```bash
grep -r "ref('core_dim_subscriptions_scratch')" models_scratch/ | wc -l
```

**Expected:** >0 (scratch models referencing scratch versions)

**If scratch refs were accidentally changed:** This indicates sed replaced too broadly. Revert and fix.

#### Step 4.6: Stage Downstream Changes

```bash
git add models_verified/
```

**Validation:**
```bash
git status
```

**Expected:** Additional modified files in `models_verified/` showing downstream ref updates.

---

### Phase 5: Validation & Testing (15 minutes)

**Purpose:** Ensure all models compile, run successfully, and no circular dependencies exist.

#### Step 5.1: Compile All Models

```bash
cd /Users/klajdi.ziaj/ds-redshift
dbt compile
```

**Expected Output:**
```
Running with dbt=1.x.x
Found X models, Y tests, Z snapshots, ...
Concurrency: 4 threads

Completed successfully
```

**If errors occur:**
- Review compilation errors
- Common issues:
  - Typos in model names
  - Missing model definitions
  - Incorrect ref() syntax
  - Circular dependencies

**Fix and recompile until successful.**

#### Step 5.2: Run Transform Models Only

```bash
dbt run --models transform_corporations_subscriptions+
```

**What this does:** Runs `transform_corporations_subscriptions` and all its upstream dependencies (the 6 supporting models).

**Expected Output:**
```
Running with dbt=1.x.x
Found X models, Y tests, Z snapshots, ...

Concurrency: 4 threads

XX:XX:XX | 1 of 7 START sql table model transform_corporations_subscription_charges ... [RUN]
XX:XX:XX | 1 of 7 OK created sql table model transform_corporations_subscription_charges ... [SUCCESS in Xs]
XX:XX:XX | 2 of 7 START sql table model transform_corporations_subscription_escalators ... [RUN]
XX:XX:XX | 2 of 7 OK created sql table model transform_corporations_subscription_escalators ... [SUCCESS in Xs]
... (similar for all 7 models)

Completed successfully
```

**Take screenshot of this output for PR description.**

**If failures occur:**
- Review SQL errors
- Check Snowflake connection
- Verify base models exist
- Fix issues and re-run

#### Step 5.3: Test Downstream Models (Sample)

**Pick 2-3 downstream models that reference transform_corporations_subscriptions:**

```bash
# Example - adjust based on actual downstream models found:
dbt run --models mart_corporations_arr
dbt run --models core_revenue_metrics
dbt run --models transform_corporations_additional_model
```

**Expected:** All downstream models run successfully with new transform refs.

**If failures occur:**
- Review ref updates in those models
- Check for missed reference updates
- Fix and re-run

#### Step 5.4: Check for Circular Dependencies

```bash
dbt list --select transform_corporations_subscriptions+ --output json | jq '.[] | .depends_on.nodes'
```

**Expected:** List of upstream dependencies with no circular references.

**If circular dependency detected:**
- Review dependency chain
- Ensure TRANSFORM models only reference BASE and TRANSFORM (not CORE)
- Fix model structure

#### Step 5.5: Run Full Test Suite (Optional but Recommended)

```bash
dbt test --models transform_corporations_subscriptions+
```

**Expected:** All tests pass (or document any expected failures).

#### Step 5.6: Verify Scratch Models Still Work

```bash
dbt run --models core_dim_subscriptions_scratch
```

**Expected:** Scratch version runs successfully with alias config preserving table name.

**Validation:**
- Check that Snowflake table is still named `core_dim_subscriptions` (not `core_dim_subscriptions_scratch`)
- This confirms alias config is working

---

### Phase 5.7: Run Pre-commit Hooks Locally **← CRITICAL NEW PHASE**

**Purpose:** Validate all changes pass pre-commit hooks **BEFORE** pushing to avoid CI failures.

**⚠️ GATE CHECK:** Do NOT proceed to Phase 6 (commit/push) if ANY hooks fail.

**Lesson from PR #9012:** We skipped this step and needed 6 fix commits to resolve hook failures that could have been caught locally in 5 minutes.

---

#### Step 5.7.1: Run check-model-has-description

```bash
cd /Users/klajdi.ziaj/ds-redshift
poetry run pre-commit run check-model-has-description --all-files
```

**What This Checks:**
- Every `.sql` file has a matching `.yml` file
- Every model in YAML has a `description:` field
- The `description:` field is not empty

**Expected Output:**
```
check-model-has-description.........................................Passed
```

**If Failed:**
```
check-model-has-description.........................................Failed
- hook id: check-model-has-description

models_verified/transform/corporations/transform_corporations_subscriptions.sql: does not have defined description or properties file is missing.
... (additional failed models listed)
```

**Fix Strategy:**
1. Go back to Phase 3.2 and create/fix missing YAMLs
2. Ensure `name:` fields match SQL filenames
3. Ensure all models have `description:` field
4. Re-run this step until it passes

---

#### Step 5.7.2: Run dbt-parse

```bash
poetry run pre-commit run dbt-parse --all-files
```

**What This Checks:**
- All models compile without errors
- All `ref()` calls point to existing models
- No circular dependencies
- SQL syntax is valid

**Expected Output:**
```
dbt-parse..............................................................Passed
```

**If Failed:**
```
dbt-parse..............................................................Failed
- hook id: dbt-parse

Compilation Error in model transform_corporations_subscriptions (models/models_verified/transform/corporations/transform_corporations_subscriptions.sql)
  Model 'transform_corporations_subscriptions' depends on a node named 'transform_corporations_subscription_charges' which was not found
```

**Fix Strategy:**
1. Review compilation error details
2. Common issues:
   - Typo in `ref()` call
   - Model file doesn't exist
   - Circular dependency
   - YAML `name:` doesn't match SQL filename
3. Fix the issue
4. Re-run this step until it passes

---

#### Step 5.7.3: Run check-model-has-tests-by-name (Optional)

```bash
poetry run pre-commit run check-model-has-tests-by-name --all-files
```

**What This Checks:**
- Primary key columns have `unique` and `not_null` tests
- Required tests exist per repository standards

**Expected Output:**
```
check-model-has-tests-by-name......................................Passed
```

**If Failed:** Add required tests to YAML files and re-run.

---

#### Step 5.7.4: Summary Gate Check

**Create validation summary:**
```bash
cat > /tmp/precommit_validation_summary.txt << 'EOF'
=== PRE-COMMIT VALIDATION SUMMARY ===

✓ check-model-has-description - PASSED
✓ dbt-parse - PASSED
✓ check-model-has-tests-by-name - PASSED (or skipped)

All pre-commit hooks passed.
Ready to proceed to Phase 6 (commit & push).
EOF

cat /tmp/precommit_validation_summary.txt
```

**⚠️ GATE CHECK:** All hooks must show PASSED. If ANY fail, do NOT proceed to Phase 6.

**Why This Matters:**
- Prevents CI failures
- Catches issues in 5 minutes locally vs. 45+ minutes of CI iterations
- Ensures clean, single-commit migration
- Saves reviewer time

---

### Phase 6: Documentation, Commit & PR (10 minutes)

#### Step 6.1: Take Screenshot of Successful dbt Run

**Action:** Take screenshot of Phase 5, Step 5.2 output showing all 7 transform models running successfully.

**Save to:** Desktop or `/tmp/subscription_migration_success.png`

#### Step 6.2: Review All Changes

```bash
git status
git diff --cached --stat
```

**Expected Summary:**
- 7 files deleted (original scratch versions)
- 7 files created (scratch with `_scratch` suffix)
- 7 files created (verified transform versions)
- ~10-20 files modified (downstream refs in verified/)

**Total:** ~28-35 files changed

#### Step 6.3: Commit Changes

```bash
git commit -m "[DA-XXXX] Migrate 7 subscription models from core to transform layer

This migration moves core_dim_subscriptions and its 6 dependencies from
models_scratch/core/subscriptions/ to models_verified/transform/corporations/
to resolve CORE→CORE layer violations in verified/ directory.

**Scratch Changes (7 models):**
- Renamed with _scratch suffix
- Added alias configs to preserve Snowflake table names
- Updated internal refs to point to _scratch versions

**Verified Changes (7 new models):**
- Created in transform/corporations/ and transform/corporations/supporting/
- Clean production names (no version suffixes)
- Updated refs to point to verified transform models
- Proper layer separation: TRANSFORM → BASE, TRANSFORM

**Downstream Updates (~XX models):**
- Updated refs in models_verified/ to use new transform model names

**Layer Compliance:**
- All models now comply with verified/ layer architecture
- CORE no longer references other CORE models
- TRANSFORM properly references BASE and other TRANSFORM models

Tested locally - all 7 models run successfully.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Expected Output:**
```
[th/da-XXXX/migrate-subscriptions-to-transform XXXXXXX] [DA-XXXX] Migrate 7 subscription models from core to transform layer
 XX files changed, XXXX insertions(+), XXXX deletions(-)
 ...
```

#### Step 6.4: Push Branch to Remote

```bash
git push -u origin th/da-XXXX/migrate-subscriptions-to-transform
```

**Expected Output:**
```
Enumerating objects: XX, done.
Counting objects: 100% (XX/XX), done.
Delta compression using up to 8 threads
Compressing objects: 100% (XX/XX), done.
Writing objects: 100% (XX/XX), XX.XX KiB | XX.XX MiB/s, done.
Total XX (delta XX), reused XX (delta XX), pack-reused 0
remote: Resolving deltas: 100% (XX/XX), completed with XX local objects.
To github.com:carta/ds-redshift.git
 * [new branch]      th/da-XXXX/migrate-subscriptions-to-transform -> th/da-XXXX/migrate-subscriptions-to-transform
branch 'th/da-XXXX/migrate-subscriptions-to-transform' set up to track 'origin/th/da-XXXX/migrate-subscriptions-to-transform'.
```

#### Step 6.5: Create Pull Request

```bash
gh pr create \
  --title "[DA-XXXX] Migrate 7 subscription models from core to transform layer" \
  --body "## Summary

This PR migrates 7 interdependent subscription models from \`models_scratch/core/subscriptions/\` to \`models_verified/transform/corporations/\` to resolve CORE→CORE layer violations and comply with verified/ layer architecture rules.

## Motivation

In the verified/ directory, CORE models cannot reference other CORE models (only BASE and TRANSFORM). The current subscription models had circular dependencies that violated this rule. Moving them to TRANSFORM layer resolves this because TRANSFORM can have multiple sub-layers that reference each other.

## Changes

### Scratch Models (7 files)
- ✅ Renamed with \`_scratch\` suffix using \`migrate-model-to-scratch\` command
- ✅ Added alias configs to preserve Snowflake table names
- ✅ Updated internal refs to point to \`_scratch\` versions
- ✅ Domain separation maintained (scratch refs scratch)

### Verified Transform Models (7 new files)
- ✅ Created in \`models_verified/transform/corporations/\` and \`supporting/\`
- ✅ Clean production names (no version suffixes):
  - \`transform_corporations_subscriptions\` (main)
  - \`transform_corporations_subscription_charges\`
  - \`transform_corporations_subscription_payment_windows\`
  - \`transform_corporations_subscription_tiers\`
  - \`transform_corporations_subscription_features\`
  - \`transform_corporations_subscription_thresholds\`
  - \`transform_corporations_subscription_escalators\`
- ✅ Updated refs to point to verified transform models
- ✅ Base model refs unchanged (TRANSFORM→BASE allowed)
- ✅ Proper dbt configs (sort, dist, unique_key, materialized)

### Downstream Models (~XX files)
- ✅ Updated refs in \`models_verified/\` to use new transform model names
- ✅ Scratch models unchanged (continue referencing \`_scratch\` versions)

## Layer Architecture Compliance

**Before:** CORE → CORE ❌ (violation)
**After:** TRANSFORM → TRANSFORM ✅ (compliant)

All models now follow verified/ layer rules:
- BASE → Sources only
- TRANSFORM → BASE, TRANSFORM
- CORE → BASE, TRANSFORM (not other CORE)
- MART → BASE, TRANSFORM, CORE

## Testing

### Local Validation
- ✅ \`dbt compile\` - All models compile successfully
- ✅ \`dbt run --models transform_corporations_subscriptions+\` - All 7 models run successfully
- ✅ Downstream model sample testing passed
- ✅ No circular dependencies detected
- ✅ Scratch models still work with alias configs

### Screenshot
![Successful dbt run](path/to/subscription_migration_success.png)

## Checklist
- [x] Scratch models renamed with \`_scratch\` suffix
- [x] Verified transform models created with clean names
- [x] **YAML files created for all models with proper `name:` and `description:` fields** ← NEW (PR #9012 lesson)
- [x] **YAML `name:` fields match SQL filenames** ← NEW (PR #9012 lesson)
- [x] **All models have description field in YAML** ← NEW (PR #9012 lesson)
- [x] Internal refs updated between the 7 models
- [x] **Data quality validation passed for all 7 models** ← NEW
- [x] Downstream refs updated in verified/
- [x] Base refs unchanged
- [x] **Pre-commit hooks pass locally (check-model-has-description, dbt-parse)** ← NEW (PR #9012 lesson)
- [x] All models compile
- [x] All models run successfully locally
- [x] No circular dependencies
- [x] Layer rules compliant
- [x] Screenshot of successful run attached

## Downstream Impact
- ~39 downstream models updated with new refs
- No breaking changes expected (table names preserved via aliases)
- Scratch domain continues to work independently

## Rollback Plan
If issues arise, revert this PR and restore original model names.

---

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>" \
  --label "cc-product-development"
```

**Expected Output:**
```
https://github.com/carta/ds-redshift/pull/XXXX
```

#### Step 6.6: Copy PR Link to Slack

```bash
echo ":dbt: [DA-XXXX] Migrate 7 subscription models from core to transform layer https://github.com/carta/ds-redshift/pull/XXXX" | pbcopy
```

**Expected:** Link copied to clipboard.

**Action:** Paste in appropriate Slack channel (e.g., `#data-engineering-prs`) to request review.

#### Step 6.7: Update Jira Ticket

```bash
acli jira workitem update DA-XXXX \
  --status "In Review" \
  --comment "PR created: https://github.com/carta/ds-redshift/pull/XXXX

Migration completed successfully:
- 7 subscription models moved from core to transform layer
- All models compile and run successfully
- Downstream refs updated
- Layer architecture now compliant

Pending code review."
```

**Expected Output:**
```
DA-XXXX updated successfully
```

---

## Post-Migration Validation

### After PR Merge

1. **Verify CI/CD Pipeline:**
   - Check that all models build successfully in CI
   - Verify no test failures
   - Confirm deployment to dev/staging environments

2. **Verify Snowflake Tables:**
   - Scratch tables still named without `_scratch` suffix (alias working)
   - Transform tables created with new names in PROD_DB
   - Data matches between scratch and transform versions

3. **Monitor Downstream Jobs:**
   - Watch for any failures in dependent dbt runs
   - Check Airflow DAGs using these models
   - Verify BI dashboards still work

4. **Update Documentation:**
   - Update any internal docs referencing old model names
   - Update data dictionaries
   - Notify stakeholders of new model names

---

## Rollback Plan

If critical issues arise after merge:

1. **Immediate Revert:**
   ```bash
   git revert <commit-hash>
   git push origin main
   ```

2. **Manual Fix:**
   - Restore original file names in scratch/
   - Delete verified transform models
   - Revert downstream ref changes
   - Re-run dbt

3. **Communication:**
   - Update Jira ticket with rollback reason
   - Notify stakeholders in Slack
   - Document issues for future migration attempt

---

## Success Criteria

- [ ] All 7 models compile without errors
- [ ] All 7 models run successfully in Snowflake
- [ ] **YAML files created for all models with descriptions** ← NEW (PR #9012 lesson)
- [ ] **Pre-commit hooks pass locally before pushing** ← NEW (PR #9012 lesson)
- [ ] **Data quality validation passed (row counts and key columns match between scratch and verified)** ← NEW
- [ ] Downstream models compile and run successfully
- [ ] No circular dependencies exist
- [ ] Layer architecture rules satisfied
- [ ] Scratch models work with aliases
- [ ] PR merged to main
- [ ] CI/CD pipeline passes
- [ ] No production incidents
- [ ] Jira ticket marked as Done

---

## Files Changed Summary

### Deleted (7 files)
```
models_scratch/core/subscriptions/core_dim_subscriptions.sql
models_scratch/core/subscriptions/core_dim_subscription_charges.sql
models_scratch/core/subscriptions/core_dim_subscription_payment_windows.sql
models_scratch/core/subscriptions/core_dim_subscription_tiers.sql
models_scratch/core/subscriptions/core_fct_subscription_active_features.sql
models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history.sql
models_scratch/core/subscriptions/core_fct_subscription_escalators.sql
```

### Created in Scratch (7 files)
```
models_scratch/core/subscriptions/core_dim_subscriptions_scratch.sql
models_scratch/core/subscriptions/core_dim_subscription_charges_scratch.sql
models_scratch/core/subscriptions/core_dim_subscription_payment_windows_scratch.sql
models_scratch/core/subscriptions/core_dim_subscription_tiers_scratch.sql
models_scratch/core/subscriptions/core_fct_subscription_active_features_scratch.sql
models_scratch/core/subscriptions/core_fct_subscription_customer_threshold_history_scratch.sql
models_scratch/core/subscriptions/core_fct_subscription_escalators_scratch.sql
```

### Created in Verified (7 files)
```
models_verified/transform/corporations/transform_corporations_subscriptions.sql
models_verified/transform/corporations/supporting/transform_corporations_subscription_charges.sql
models_verified/transform/corporations/supporting/transform_corporations_subscription_payment_windows.sql
models_verified/transform/corporations/supporting/transform_corporations_subscription_tiers.sql
models_verified/transform/corporations/supporting/transform_corporations_subscription_features.sql
models_verified/transform/corporations/supporting/transform_corporations_subscription_thresholds.sql
models_verified/transform/corporations/supporting/transform_corporations_subscription_escalators.sql
```

### Modified in Verified (~10-20 files)
```
Various downstream models with ref() updates
(Exact list determined in Phase 4, Step 4.1)
```

---

## Risk Assessment

**Low Risk:**
- All models are regular tables (not incremental/snapshot)
- Atomic migration of interdependent models
- Thorough local testing before commit
- Scratch domain separation prevents cross-contamination

**Medium Risk:**
- Large number of downstream dependencies (~39 refs)
- Manual sed replacements could miss edge cases
- Base model references must remain unchanged

**Mitigation:**
- Comprehensive grep validation after each phase
- Multiple validation steps before commit
- Screenshot proof of successful local runs
- Rollback plan documented

---

## Lessons Learned from PR #9012 (Zuora ARR Migration - 43 Models)

**Context:** In November 2024, we migrated 43 Zuora ARR models from scratch/ to _scratch naming convention. The migration took 2+ hours with 6 fix commits due to lack of upfront validation.

### What Went Wrong ❌

1. **Skipped Pre-commit Validation Locally**
   - Pushed code without running `check-model-has-description`
   - Result: 59 models failed CI with missing descriptions
   - Fix time: 1 hour + 3 commits

2. **Didn't Create/Update YAML Files Systematically**
   - Renamed SQL files but forgot to rename corresponding YAMLs
   - `name:` fields in YAMLs didn't match SQL filenames
   - Result: dbt couldn't find model definitions
   - Fix time: 30 minutes + 2 commits

3. **Forgot to Update Downstream References**
   - Missed 2 mart models referencing old names
   - Result: Compilation errors "node not found"
   - Fix time: 15 minutes + 1 commit

4. **Left Duplicate Original Files**
   - Didn't delete original files after creating _scratch versions
   - Result: "two resources with identical database representation" error
   - Fix time: 10 minutes + 1 commit

5. **Didn't Use dbt-refactor-agent**
   - Chose manual approach for 43-model migration
   - Result: All the issues above could have been prevented
   - Opportunity cost: 1.5 hours wasted

### What Should Have Been Done ✅

1. **Run Pre-commit Hooks Locally First**
   ```bash
   poetry run pre-commit run check-model-has-description --all-files
   poetry run dbt parse
   ```
   - Catches 90% of issues in 5 minutes
   - Prevents CI iteration cycles

2. **Create/Update YAMLs Before Pushing**
   - Ensure every .sql has a .yml
   - Ensure `name:` matches filename
   - Ensure `description:` field exists
   - Use validation scripts (added in Phase 3.2)

3. **Use dbt-refactor-agent for 7+ Model Migrations**
   - Agent handles YAML creation automatically
   - Agent runs validation before committing
   - Agent updates refs systematically
   - Single clean commit

4. **Systematic Ref Updates with Validation**
   - Use grep to find all refs
   - Use sed for bulk replacements
   - Validate after each change
   - Test compilation after each phase

### Time Comparison

**Manual Approach (PR #9012 - actual):**
- Initial work: 1 hour
- First push + CI wait: 15 minutes
- Fix commit 1 (missing descriptions): 20 minutes + CI wait
- Fix commit 2 (YAML renames): 15 minutes + CI wait
- Fix commit 3 (more descriptions): 10 minutes + CI wait
- Fix commit 4 (downstream refs): 10 minutes + CI wait
- Fix commit 5 (duplicate files): 10 minutes + CI wait
- Fix commit 6 (final cleanup): 10 minutes + CI wait
- **Total: 2 hours 45 minutes**

**Manual Approach WITH Local Validation (this document):**
- Initial work: 1 hour
- Create YAMLs: 20 minutes
- Data validation: 30 minutes
- Run pre-commit hooks: 5 minutes
- Single push + CI wait: 15 minutes
- **Total: 2 hours 10 minutes (35 minutes saved, 1 clean commit)**

**dbt-refactor-agent Approach (recommended):**
- Agent execution: 30 minutes (automated)
- Review agent output: 10 minutes
- Single push + CI wait: 15 minutes
- **Total: 55 minutes (1 hour 50 minutes saved, 1 clean commit)**

### Key Takeaways

1. **Always run pre-commit hooks locally** - Saves 45+ minutes of CI iterations
2. **YAML files are not optional** - check-model-has-description will fail
3. **YAML `name:` must match filename** - dbt won't find the model otherwise
4. **Every model needs a description** - Even placeholder text is better than nothing
5. **For 7+ models, use dbt-refactor-agent** - It's faster and more reliable
6. **Validate after each phase** - Catch issues early, fix incrementally
7. **Test locally before pushing** - dbt run, dbt compile, pre-commit hooks

### Prevention Checklist (Use This Next Time)

Before pushing ANY dbt model migration:
- [ ] All YAML files created/updated
- [ ] All `name:` fields match SQL filenames  
- [ ] All models have `description:` field
- [ ] `poetry run pre-commit run check-model-has-description --all-files` passes
- [ ] `poetry run dbt parse` succeeds
- [ ] `dbt run --models <affected_models>` succeeds
- [ ] All downstream refs updated and validated
- [ ] Screenshot of successful run taken for PR

**If YES to all above:** Push confidently with 1 clean commit  
**If NO to any:** Fix it locally first, do NOT push

---

## Lessons Learned from DA-4090 Subscription Models Migration (January 2025)

**Context:** Completed migration of 22 subscription models (7 transform + 15 base) from scratch/ to verified/. Total PR size: 208 files changed.

### What Went Wrong ❌

#### 1. Violated Verified Model Standards

**Problem:** Created verified models with scratch conventions:
- 12 verified base models included `alias` configs (verified models should NOT have aliases)
- 9 verified base models used `SELECT *` (verified requires explicit columns)

**Impact:**
- Required additional PR to fix 12 alias config removals
- Required dbt-refactor-agent run to expand 400+ columns across 9 models
- Added 2 hours of rework time

**Root Cause:** Did not validate against verified/ styleguide before creating models. Blindly copied patterns from scratch models.

**Lesson:** Before creating ANY verified model, validate:
```bash
# Check for alias configs (should be 0 in verified)
grep -r "alias=" models_verified/

# Check for SELECT * (should be 0 in verified)
grep -r "SELECT \*" models_verified/
```

---

#### 2. Created Monolithic PR (208 Files)

**Problem:** Initial PR #9014 contained both scratch renames AND verified model creation:
- 164 files for scratch renames (7 models × 2 files each + downstream updates + YAMLs)
- 44 files for verified model creation (22 models × 2 files each)
- Total: 208 files changed

**Impact:**
- Overwhelming for reviewers
- Difficult to validate each change type
- Mixed concerns (renames vs new models)
- High risk of missing issues in review

**Root Cause:** Did not plan PR splitting strategy upfront. Treated migration as single atomic change.

**Lesson:** For migrations with 100+ file changes, ALWAYS split into logical PRs:
1. PR #1: Scratch renames (preserves existing behavior)
2. PR #2: Verified model creation (new code)
3. PR #3: Standards fixes (if needed)

---

#### 3. Duplicate YAML Files Not Cleaned Up

**Problem:** After splitting PR, left 8 duplicate YAML files in both PRs:
- PR #9017 (scratch): Renamed YAMLs to match `_scratch` SQL files
- PR #9018 (verified): Created new YAMLs for verified models
- Both PRs modified the same original YAML files

**Impact:**
- Merge conflicts between PRs
- Confusion about which YAML to use
- Required manual cleanup of 8 duplicate files

**Root Cause:** Did not account for YAML file lifecycle when splitting PR with `git diff --cached`.

**Lesson:** When splitting PRs, explicitly handle YAML files:
- If renaming: Include YAML rename in same PR as SQL rename
- If creating new: Delete old YAML in first PR, create new in second PR
- Use `git rm` to explicitly track deletions

---

### What Went Right ✅

#### 1. Used Git Patch Splitting Strategy

**Success:** Used `git diff --cached` with path filters to cleanly split 208-file PR:
```bash
# Create patch with only scratch changes
git diff --cached models_scratch/ > /tmp/scratch_changes.patch

# Create patch with only verified changes
git diff --cached models_verified/ > /tmp/verified_changes.patch
```

**Benefits:**
- Clean separation of concerns
- Easy to review each PR independently
- Reduced risk per PR
- Could merge scratch PR first, then verified PR

**Lesson:** For ANY migration with 50+ files, plan patch splitting upfront.

---

#### 2. Used dbt-refactor-agent for SELECT * Expansion

**Success:** Agent expanded 15 SELECT * statements to 400+ explicit columns across 9 models in ~20 minutes.

**Manual Alternative:** Would have taken 2+ hours to manually list all columns from source tables.

**Lesson:** For bulk code transformations (SELECT * expansion, adding tests, etc.), use agents first. Manual work is last resort.

---

#### 3. Validated Layer Architecture Before Committing

**Success:** Ran `dbt compile` and `dbt run` locally before pushing to catch:
- Circular dependencies (would have caused CI failure)
- Missing model references (typos in ref() calls)
- Layer rule violations (TRANSFORM → CORE references)

**Lesson:** NEVER push migration PRs without local validation:
```bash
# Must pass all these before pushing:
dbt compile
dbt run --models <affected_models>
poetry run pre-commit run check-model-has-description --all-files
poetry run pre-commit run dbt-parse --all-files
```

---

### Time Comparison: Actual vs Ideal

**Actual (DA-4090):**
- Initial migration work: 2 hours
- Created monolithic PR: 30 minutes
- Realized standards violations: 1 hour debugging
- Fixed alias configs: 1 hour
- Fixed SELECT * violations (agent): 30 minutes
- Split PR into two: 1 hour
- Cleaned up duplicate YAMLs: 30 minutes
- **Total: 6.5 hours**

**Ideal (if followed plan):**
- Initial migration work: 2 hours
- Validate against styleguide upfront: 15 minutes
- Create verified models correctly first time: (no rework)
- Plan PR split upfront: 15 minutes
- Create two clean PRs: 45 minutes
- **Total: 3 hours 15 minutes (50% time savings)**

---

### Updated Prevention Checklist

Before pushing ANY verified model migration PR:

**Standards Validation:**
- [ ] No `alias` configs in models_verified/ (`grep -r "alias=" models_verified/`)
- [ ] No `SELECT *` in models_verified/ (`grep -r "SELECT \*" models_verified/`)
- [ ] All models have explicit column lists
- [ ] All models follow verified/ naming conventions

**PR Planning (if 50+ files):**
- [ ] Plan split strategy upfront (scratch vs verified vs fixes)
- [ ] Identify YAML file handling (rename/delete/create)
- [ ] Create separate branches for each PR
- [ ] Use `git diff` with path filters for clean patches

**Local Validation:**
- [ ] `dbt compile` succeeds
- [ ] `dbt run --models <affected>` succeeds
- [ ] `poetry run pre-commit run check-model-has-description --all-files` passes
- [ ] `poetry run pre-commit run dbt-parse --all-files` passes
- [ ] No circular dependencies (`dbt list --select <model>+ --output json`)

**Documentation:**
- [ ] Screenshot of successful dbt run for PR description
- [ ] Document any standards violations found and fixed
- [ ] Update this prompt file with lessons learned

---

### Key Takeaways

1. **Validated styleguide compliance BEFORE creating models** - Saves 2+ hours of rework
2. **Plan PR splits for 50+ file changes** - Makes reviews manageable
3. **Handle YAML files explicitly when splitting** - Prevents duplicate file conflicts
4. **Use agents for bulk transformations** - dbt-refactor-agent saved 90 minutes
5. **Always validate locally before pushing** - Catches issues in 5 minutes vs 45 minutes in CI

---

## PR Splitting Strategy for Large Migrations

**When to Split:** Migrations with 100+ file changes should be split into multiple PRs for easier review.

### Approach: Git Patch Method

Use `git diff --cached` with path filters to create separate patches:

```bash
# Stage all changes first
git add models_scratch/ models_verified/

# Create patch for scratch changes only
git diff --cached models_scratch/ > /tmp/scratch_changes.patch

# Create patch for verified changes only
git diff --cached models_verified/ > /tmp/verified_changes.patch

# Verify patches look correct
head -20 /tmp/scratch_changes.patch
head -20 /tmp/verified_changes.patch
```

### Apply Patches to Separate Branches

**Branch 1: Scratch Renames**
```bash
# Create first branch for scratch renames
git switch main
git switch -c th/da-XXXX/rename-subscriptions-scratch

# Apply scratch patch
git apply /tmp/scratch_changes.patch

# Stage and commit
git add models_scratch/
git commit -m "[DA-XXXX] Rename 7 subscription models with _scratch suffix"
git push -u origin th/da-XXXX/rename-subscriptions-scratch

# Create PR #1
gh pr create \
  --title "[DA-XXXX] Rename subscription models with _scratch suffix" \
  --body "## Summary\n\nRename 7 subscription models to _scratch suffix with alias configs..." \
  --label "cc-product-development"
```

**Branch 2: Verified Model Creation**
```bash
# Create second branch for verified models
git switch main
git switch -c th/da-XXXX/create-verified-subscription-models

# Apply verified patch
git apply /tmp/verified_changes.patch

# Stage and commit
git add models_verified/
git commit -m "[DA-XXXX] Create 22 verified subscription models"
git push -u origin th/da-XXXX/create-verified-subscription-models

# Create PR #2
gh pr create \
  --title "[DA-XXXX] Create verified subscription models" \
  --body "## Summary\n\nCreate 22 verified subscription models (7 transform + 15 base)..." \
  --label "cc-product-development"
```

### Handling YAML Files

**Problem:** When splitting, YAML files may be modified in both patches, causing conflicts.

**Solution:**
1. **For Scratch PR:** Include YAML renames alongside SQL renames
2. **For Verified PR:** Create NEW YAML files with clean names
3. **Cleanup:** Delete old YAML files in scratch PR if creating new ones in verified PR

**Example:**
```bash
# In scratch PR - rename YAML to match _scratch SQL
git mv models_scratch/core/subscriptions/core_dim_subscriptions.yml \
        models_scratch/core/subscriptions/core_dim_subscriptions_scratch.yml

# In verified PR - create NEW YAML
# (not rename, create fresh file)
touch models_verified/transform/corporations/transform_corporations_subscriptions.yml
```

### Benefits of This Approach

✅ Clean separation of concerns (renames vs new code)  
✅ Easier code review (smaller, focused PRs)  
✅ Reduced risk per PR (can revert independently)  
✅ Can merge incrementally (scratch first, then verified)  
✅ Clear git history (one commit per logical change)

### PR Size Guidelines

- **< 50 files**: Single PR acceptable
- **50-100 files**: Consider splitting by domain (scratch vs verified)
- **100-200 files**: MUST split by logical change type
- **200+ files**: Split into 3+ PRs (renames, new models, fixes)

---

## Data Quality Validation Queries for Subscriptions

**Context:** After creating verified transform models, validate data matches scratch versions before updating downstream models.

### Validation Pattern: Row Counts + Key Metrics

**Query Template:**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT <primary_key>) AS unique_keys,
  SUM(<key_metric>) AS total_metric
FROM <scratch_table>
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT <primary_key>) AS unique_keys,
  SUM(<key_metric>) AS total_metric
FROM <verified_table>
```

### Subscription-Specific Validation Queries

**1. Main Subscriptions Table**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions,
  COUNT(DISTINCT corporation_id) AS unique_corporations,
  SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_count,
  SUM(current_arr_dollars) AS total_arr
FROM dbt_core.core_dim_subscriptions
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions,
  COUNT(DISTINCT corporation_id) AS unique_corporations,
  SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_count,
  SUM(current_arr_dollars) AS total_arr
FROM dbt_verified_transform.transform_corporations_subscriptions
```

**2. Payment Windows (ARR Critical)**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_windows,
  SUM(yearly_value_dollars_net) AS total_arr_net,
  MIN(sub_payment_start) AS earliest_start,
  MAX(sub_payment_end_final) AS latest_end
FROM dbt_core.core_dim_subscription_payment_windows
WHERE is_valid
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT _pk) AS unique_windows,
  SUM(yearly_value_dollars_net) AS total_arr_net,
  MIN(sub_payment_start) AS earliest_start,
  MAX(sub_payment_end_final) AS latest_end
FROM dbt_verified_transform.transform_corporations_subscription_payment_windows
WHERE is_valid
```

**3. Charges (Recovery Tracking)**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT id) AS unique_charges,
  SUM(amount_dollars) AS total_charge_amount,
  SUM(CASE WHEN status = 'Recovered' THEN 1 ELSE 0 END) AS recovered_count,
  SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_count
FROM dbt_core.core_dim_subscription_charges
UNION ALL
SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT id) AS unique_charges,
  SUM(amount_dollars) AS total_charge_amount,
  SUM(CASE WHEN status = 'Recovered' THEN 1 ELSE 0 END) AS recovered_count,
  SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_count
FROM dbt_verified_transform.transform_corporations_subscription_charges
```

**4. Detailed Difference Check (Find Mismatches)**
```sql
WITH scratch AS (
  SELECT 
    subscription_id,
    corporation_id,
    is_active,
    current_arr_dollars,
    current_tier,
    package_type
  FROM dbt_core.core_dim_subscriptions
),
verified AS (
  SELECT 
    subscription_id,
    corporation_id,
    is_active,
    current_arr_dollars,
    current_tier,
    package_type
  FROM dbt_verified_transform.transform_corporations_subscriptions
)
SELECT 
  COALESCE(s.subscription_id, v.subscription_id) AS subscription_id,
  s.is_active AS scratch_is_active,
  v.is_active AS verified_is_active,
  s.current_arr_dollars AS scratch_arr,
  v.current_arr_dollars AS verified_arr,
  ABS(COALESCE(s.current_arr_dollars,0) - COALESCE(v.current_arr_dollars,0)) AS arr_difference,
  s.package_type AS scratch_package,
  v.package_type AS verified_package,
  CASE 
    WHEN s.subscription_id IS NULL THEN 'Missing in scratch'
    WHEN v.subscription_id IS NULL THEN 'Missing in verified'
    WHEN s.is_active != v.is_active THEN 'is_active mismatch'
    WHEN ABS(COALESCE(s.current_arr_dollars,0) - COALESCE(v.current_arr_dollars,0)) > 0.01 THEN 'ARR mismatch'
    WHEN s.package_type != v.package_type THEN 'package mismatch'
    ELSE 'other mismatch'
  END AS difference_type
FROM scratch s
FULL OUTER JOIN verified v ON s.subscription_id = v.subscription_id
WHERE s.subscription_id IS NULL 
   OR v.subscription_id IS NULL
   OR s.is_active != v.is_active
   OR ABS(COALESCE(s.current_arr_dollars,0) - COALESCE(v.current_arr_dollars,0)) > 0.01
   OR s.package_type != v.package_type
LIMIT 100
```

### Validation Thresholds

**Must Match Exactly:**
- Row counts (COUNT(*))
- Unique key counts (COUNT(DISTINCT primary_key))
- Total ARR within $0.01 (SUM(arr_dollars))

**Acceptable Small Differences:**
- Timestamp formatting (timezone conversions)
- Floating point rounding (< $0.01 difference)
- NULL vs empty string (if not business-critical)

**Failure Criteria:**
- ANY missing rows (scratch has row that verified doesn't)
- ARR difference > $0.01
- Active subscription count mismatch
- Tier assignment differences

### When to Run These Queries

1. **After Initial Model Creation** - Validate basic data transfer
2. **After Fixing Standards Violations** - Ensure fixes didn't break logic
3. **Before Merging PR** - Final validation
4. **After Production Deployment** - Confirm prod matches dev

---

## References

- [dbt Layer Architecture Documentation](~/.claude/skills/dbt-refactor-standards/SKILL.md)
- [migrate-model-to-scratch Command](~/.claude/commands/migrate-model-to-scratch)
- [dbt Refactor Agent](~/.claude/agents/dbt-refactor-agent.md)
- [Model Migration Agent](~/.claude/agents/model-migration-agent.md)
- Jira Ticket: DA-XXXX
- Pull Request: https://github.com/carta/ds-redshift/pull/XXXX

---

**Last Updated:** January 2025  
**Status:** Ready for execution  
**Next Action:** Begin Phase 1 - Setup & Branch Creation
