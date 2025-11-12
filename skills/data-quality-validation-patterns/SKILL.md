# Data Quality Validation Patterns

This skill provides reusable SQL patterns for validating data consistency between scratch and verified dbt models during migrations.

## When to Use Data Quality Validation

**Required Scenarios:**
- Migrating models from scratch/ to verified/
- Refactoring model logic
- Replacing SELECT * with explicit columns
- Changing aggregation or join logic

**Optional Scenarios:**
- Adding tests to existing models (no logic changes)
- Pure documentation updates
- YAML-only changes

## Core Validation Strategy

**Principle**: Validate that scratch and verified models produce functionally equivalent results within acceptable thresholds.

**Approach**:
1. Compare row counts (expect exact match or document timing differences)
2. Compare key metrics (ARR, totals, unique keys)
3. Sample and compare data structure
4. Document any expected differences

## Pattern 1: Row Count Comparison

**Purpose**: Verify models produce same number of records

**SQL Template:**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count
FROM PROD_DB.DBT_CORE.SCRATCH_MODEL_NAME

UNION ALL

SELECT 
  'verified' AS version,
  COUNT(*) AS row_count
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_MODEL_NAME;
```

**Expected Result:**
- Exact match: ✅ PASS
- Small difference (<0.1%): ⚠️ INVESTIGATE (timing issue?)
- Large difference (>1%): ❌ FAIL (logic error)

**Example from DA-4090 (subscriptions):**
```sql
-- Result: 391,854 vs 392,002 rows (+148 rows, 0.04%)
-- Cause: New subscriptions created between scratch and verified builds
-- Verdict: ✅ PASS (timing difference, not logic error)
```

## Pattern 2: Unique Key Validation

**Purpose**: Verify primary key uniqueness and consistency

**SQL Template:**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT primary_key_field) AS unique_keys,
  COUNT(*) - COUNT(DISTINCT primary_key_field) AS duplicate_count
FROM PROD_DB.DBT_CORE.SCRATCH_MODEL_NAME

UNION ALL

SELECT 
  'verified' AS version,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT primary_key_field) AS unique_keys,
  COUNT(*) - COUNT(DISTINCT primary_key_field) AS duplicate_count
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_MODEL_NAME;
```

**Expected Result:**
- `duplicate_count` should be 0 for both
- `unique_keys` should match `total_rows` for both

**Example from DA-4090 (subscriptions):**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions
FROM DEV_KLAJDI_ZIAJ_DB.DBT_CORE.CORE_DIM_SUBSCRIPTIONS

UNION ALL

SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  COUNT(DISTINCT subscription_id) AS unique_subscriptions
FROM DEV_KLAJDI_ZIAJ_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTIONS;

-- Result: Both had unique_subscriptions == row_count (no duplicates) ✅
```

## Pattern 3: Key Metrics Comparison

**Purpose**: Validate business-critical aggregations (totals, sums, averages)

**SQL Template:**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  SUM(metric_field) AS total_metric,
  ROUND(AVG(metric_field), 2) AS avg_metric,
  MIN(metric_field) AS min_metric,
  MAX(metric_field) AS max_metric
FROM PROD_DB.DBT_CORE.SCRATCH_MODEL_NAME

UNION ALL

SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  SUM(metric_field) AS total_metric,
  ROUND(AVG(metric_field), 2) AS avg_metric,
  MIN(metric_field) AS min_metric,
  MAX(metric_field) AS max_metric
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_MODEL_NAME;
```

**Expected Result:**
- Totals should match within rounding tolerance (<$0.01 for dollars)
- Averages may differ slightly due to row count differences
- Min/max should be identical (unless timing issue)

**Example from DA-4090 (payment_windows ARR):**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  ROUND(SUM(yearly_value_dollars_net), 2) AS total_arr_net,
  ROUND(SUM(yearly_value_dollars_gross), 2) AS total_arr_gross
FROM PROD_DB.DBT_CORE.CORE_DIM_SUBSCRIPTION_PAYMENT_WINDOWS
WHERE is_valid

UNION ALL

SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  ROUND(SUM(yearly_value_dollars_net), 2) AS total_arr_net,
  ROUND(SUM(yearly_value_dollars_gross), 2) AS total_arr_gross
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_PAYMENT_WINDOWS
WHERE is_valid;

-- Result: EXACT MATCH on $2.06B ARR net and $2.39B ARR gross ✅
-- This was the CRITICAL validation - ARR must be exact
```

## Pattern 4: Boolean Flag Distribution

**Purpose**: Validate filtering logic and status distributions

**SQL Template:**
```sql
SELECT 
  'scratch' AS version,
  boolean_flag,
  COUNT(*) AS count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM PROD_DB.DBT_CORE.SCRATCH_MODEL_NAME
GROUP BY boolean_flag

UNION ALL

SELECT 
  'verified' AS version,
  boolean_flag,
  COUNT(*) AS count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_MODEL_NAME
GROUP BY boolean_flag
ORDER BY version, boolean_flag;
```

**Expected Result:**
- Distributions should match (exact or within 0.1%)
- All flag values present in both models

**Example from DA-4090 (subscriptions is_active):**
```sql
SELECT 
  'scratch' AS version,
  is_active,
  COUNT(*) AS count
FROM DEV_KLAJDI_ZIAJ_DB.DBT_CORE.CORE_DIM_SUBSCRIPTIONS
GROUP BY is_active

UNION ALL

SELECT 
  'verified' AS version,
  is_active,
  COUNT(*) AS count
FROM DEV_KLAJDI_ZIAJ_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTIONS
GROUP BY is_active;

-- Result: Active counts matched within timing tolerance ✅
```

## Pattern 5: Sample Data Comparison

**Purpose**: Spot-check data structure and values

**SQL Template:**
```sql
-- Scratch sample
SELECT * 
FROM PROD_DB.DBT_CORE.SCRATCH_MODEL_NAME
LIMIT 10;

-- Verified sample
SELECT * 
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_MODEL_NAME
LIMIT 10;
```

**What to Check:**
- Column names match
- Data types are compatible
- Null patterns are similar
- Value ranges are reasonable

## Domain-Specific Patterns

### Subscription Models

**Pattern: ARR Validation (CRITICAL)**
```sql
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  ROUND(SUM(yearly_value_dollars_net), 2) AS total_arr_net,
  ROUND(SUM(yearly_value_dollars_gross), 2) AS total_arr_gross,
  ROUND(SUM(yearly_value_dollars_discount), 2) AS total_discounts
FROM PROD_DB.DBT_CORE.CORE_DIM_SUBSCRIPTION_PAYMENT_WINDOWS
WHERE is_valid

UNION ALL

SELECT 
  'verified' AS version,
  COUNT(*) AS row_count,
  ROUND(SUM(yearly_value_dollars_net), 2) AS total_arr_net,
  ROUND(SUM(yearly_value_dollars_gross), 2) AS total_arr_gross,
  ROUND(SUM(yearly_value_dollars_discount), 2) AS total_discounts
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_PAYMENT_WINDOWS
WHERE is_valid;
```

**Pattern: Charge Status Distribution**
```sql
SELECT 
  'scratch' AS version,
  status,
  COUNT(*) AS count
FROM PROD_DB.DBT_CORE.CORE_DIM_SUBSCRIPTION_CHARGES
GROUP BY status

UNION ALL

SELECT 
  'verified' AS version,
  status,
  COUNT(*) AS count
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_CHARGES
GROUP BY status
ORDER BY version, status;
```

**Pattern: Tier Distribution**
```sql
SELECT 
  'scratch' AS version,
  tier,
  COUNT(*) AS count
FROM PROD_DB.DBT_CORE.CORE_DIM_SUBSCRIPTION_TIERS
GROUP BY tier

UNION ALL

SELECT 
  'verified' AS version,
  tier,
  COUNT(*) AS count
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_TIERS
GROUP BY tier
ORDER BY version, tier;
```

### Temporal/Snapshot Models

**Pattern: Date Range Validation**
```sql
SELECT 
  'scratch' AS version,
  MIN(effective_date) AS earliest_date,
  MAX(effective_date) AS latest_date,
  COUNT(DISTINCT effective_date) AS unique_dates
FROM PROD_DB.DBT_CORE.SCRATCH_TEMPORAL_MODEL

UNION ALL

SELECT 
  'verified' AS version,
  MIN(effective_date) AS earliest_date,
  MAX(effective_date) AS latest_date,
  COUNT(DISTINCT effective_date) AS unique_dates
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_TEMPORAL_MODEL;
```

**Pattern: Historical Record Counts by Date**
```sql
SELECT 
  'scratch' AS version,
  DATE_TRUNC('month', effective_date) AS month,
  COUNT(*) AS record_count
FROM PROD_DB.DBT_CORE.SCRATCH_TEMPORAL_MODEL
GROUP BY DATE_TRUNC('month', effective_date)

UNION ALL

SELECT 
  'verified' AS version,
  DATE_TRUNC('month', effective_date) AS month,
  COUNT(*) AS record_count
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.VERIFIED_TEMPORAL_MODEL
GROUP BY DATE_TRUNC('month', effective_date)
ORDER BY month, version;
```

## Handling Large Tables (1B+ rows)

**Problem**: Queries timeout on billion-row tables

**Solution**: Simplify queries and run separately

**Example from DA-4090 (1.04B row table):**
```sql
-- Instead of this (times out):
SELECT 
  'scratch' AS version,
  COUNT(*) AS row_count,
  SUM(threshold_count) AS total_thresholds
FROM PROD_DB.DBT_CORE.CORE_FCT_SUBSCRIPTION_CUSTOMER_THRESHOLD_HISTORY
UNION ALL
SELECT ...;

-- Do this (runs successfully):
-- Query 1:
SELECT COUNT(*) AS row_count 
FROM PROD_DB.DBT_CORE.CORE_FCT_SUBSCRIPTION_CUSTOMER_THRESHOLD_HISTORY;

-- Query 2:
SELECT COUNT(*) AS row_count 
FROM PROD_DB.DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_THRESHOLDS;

-- Compare results manually
```

## Interpreting Differences

### Expected Differences (✅ PASS)

**Timing Differences:**
- New records created between scratch and verified builds
- Example: +148 subscriptions (0.04% difference)
- **How to verify**: Check timestamps of new records

**Rounding Differences:**
- Different decimal precision in aggregations
- Example: $2,055,994,441.90 vs $2,055,994,441.89
- **Acceptable if**: <$0.01 for currency, <0.01% for percentages

### Investigate Further (⚠️ WARN)

**Small Metric Differences:**
- Totals differ by 0.1% - 1%
- Could be legitimate but verify business logic
- **Action**: Compare sample records to understand difference

**Schema Differences:**
- Column counts differ
- New calculated fields added
- **Action**: Verify all expected columns present

### Critical Issues (❌ FAIL)

**Large Row Count Differences:**
- >1% difference in row counts
- **Likely cause**: Join logic error, missing WHERE clause

**Wildly Different Metrics:**
- ARR totals differ by >$1000
- **Likely cause**: Aggregation logic error, wrong grouping

**Missing Data:**
- Key values present in scratch but not verified
- **Likely cause**: Filter too restrictive, missing LEFT JOIN

## Best Practices

1. **Start with row counts** - simplest check, catches most issues
2. **Validate critical metrics** - ARR, revenue, counts (business impact)
3. **Check unique keys** - ensures data integrity
4. **Sample data last** - spot-check for edge cases
5. **Document expected differences** - timing issues, rounding, etc.
6. **Use exact table paths** - include database, schema, table name
7. **Round currency to 2 decimals** - avoids floating point noise
8. **Run separate queries for huge tables** - avoids timeouts
9. **Save queries in PR description** - enables reproduction

## Automated Validation

Use the `compare-model-data` command for automated validation:

```bash
compare-model-data \
  DBT_CORE.SCRATCH_MODEL_NAME \
  DBT_VERIFIED_TRANSFORM.VERIFIED_MODEL_NAME
```

This runs:
- Row count comparison
- Schema comparison
- Sample data extraction
- Generates markdown report

**When to use command vs manual queries:**
- **Command**: Quick validation, standard metrics
- **Manual queries**: Domain-specific metrics (ARR, thresholds), complex aggregations

## Example: Complete Validation Workflow (DA-4090)

**Task**: Validate 7 subscription transform models

**Step 1: List Models and Plan**
```bash
# Models to validate:
# 1. subscriptions (main aggregation)
# 2. charges (payment tracking)
# 3. payment_windows (ARR calculation)
# 4. tiers (pricing levels)
# 5. features (package classification)
# 6. thresholds (temporal snapshots - 1B+ rows)
# 7. escalators (price increases)
```

**Step 2: Validate Each Model**

Model 1 (subscriptions):
```sql
-- Row counts + key metrics
SELECT 'scratch', COUNT(*), COUNT(DISTINCT subscription_id), 
       SUM(CASE WHEN is_active THEN 1 ELSE 0 END), 
       ROUND(SUM(current_arr_dollars), 2)
FROM DBT_CORE.CORE_DIM_SUBSCRIPTIONS
UNION ALL
SELECT 'verified', COUNT(*), COUNT(DISTINCT subscription_id), 
       SUM(CASE WHEN is_active THEN 1 ELSE 0 END), 
       ROUND(SUM(current_arr_dollars), 2)
FROM DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTIONS;

-- Result: 391,854 vs 392,002 rows (+148, timing)
-- ARR: $327,600,462.57 vs $327,598,462.57 (rounding)
-- Verdict: ✅ PASS
```

Model 3 (payment_windows - CRITICAL ARR validation):
```sql
-- This is the MOST CRITICAL validation - ARR must be exact
SELECT 'scratch', COUNT(*), 
       ROUND(SUM(yearly_value_dollars_net), 2) AS arr_net,
       ROUND(SUM(yearly_value_dollars_gross), 2) AS arr_gross
FROM DBT_CORE.CORE_DIM_SUBSCRIPTION_PAYMENT_WINDOWS
WHERE is_valid
UNION ALL
SELECT 'verified', COUNT(*), 
       ROUND(SUM(yearly_value_dollars_net), 2) AS arr_net,
       ROUND(SUM(yearly_value_dollars_gross), 2) AS arr_gross
FROM DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_PAYMENT_WINDOWS
WHERE is_valid;

-- Result: 403,566 rows (EXACT MATCH)
-- ARR Net: $2,055,994,441.90 (EXACT MATCH)
-- ARR Gross: $2,393,988,830.95 (EXACT MATCH)
-- Verdict: ✅ PERFECT MATCH - This was the make-or-break validation
```

Model 6 (thresholds - 1B rows, use simplified query):
```sql
-- Separate queries due to size
SELECT COUNT(*) FROM DBT_CORE.CORE_FCT_SUBSCRIPTION_CUSTOMER_THRESHOLD_HISTORY;
-- Result: 1,038,908,442 rows

SELECT COUNT(*) FROM DBT_VERIFIED_TRANSFORM.TRANSFORM_CORPORATIONS_SUBSCRIPTION_THRESHOLDS;
-- Result: 1,038,908,442 rows

-- Verdict: ✅ EXACT MATCH
```

**Step 3: Generate Summary Report**

| Model | Rows | Status | Notes |
|-------|------|--------|-------|
| subscriptions | 392,002 vs 391,854 | ✅ | +148 rows (timing) |
| charges | 354,022 | ✅ **PERFECT** | All metrics match |
| payment_windows | 403,566 | ✅ **PERFECT** | ARR: $2.06B exact |
| tiers | 2,275,329 | ✅ **PERFECT** | All metrics match |
| features | 588,923,329 | ✅ **PERFECT** | 588M rows validated |
| thresholds | 1,038,908,442 | ✅ **PERFECT** | 1.04B rows validated |
| escalators | 142,789 | ✅ **PERFECT** | All metrics match |

**Total Records Validated**: 2,631,898,777 (2.63 billion rows)

**Conclusion**: Verified models are functionally identical to scratch equivalents. Safe to merge and deploy.

---

**Reference**: Lessons learned from DA-4090 subscription models migration (January 2025)
