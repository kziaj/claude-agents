# Corporations: Examples & Common Queries

**Practical SQL examples** for working with corporation (company) data.

---

## 🎯 Basic Lookups

### Find a company by name
```sql
SELECT 
    corporation_id,
    legal_name,
    dba,
    industry,
    state_of_incorporation,
    is_active
FROM core_dim_corporations
WHERE legal_name ILIKE '%stripe%'
    AND is_void = FALSE
```

### Get company profile details
```sql
SELECT 
    corp.legal_name,
    corp.dba,
    corp.legal_entity_type,
    corp.incorporation_date,
    corp.state_of_incorporation,
    corp.industry,
    corp.industry_broad,
    corp.hq_country,
    corp.address,
    corp.city,
    corp.state,
    corp.country,
    corp.website,
    corp.phone
FROM core_dim_corporations corp
WHERE corp.corporation_id = 123456
```

### Find all companies in an industry
```sql
SELECT 
    corporation_id,
    legal_name,
    industry,
    industry_broad,
    state_of_incorporation,
    is_active
FROM core_dim_corporations
WHERE industry_broad = 'Technology'
    AND is_active = TRUE
    AND is_void = FALSE
ORDER BY legal_name
LIMIT 100
```

**Expected Output**:
```
corporation_id | legal_name        | industry  | industry_broad | state_of_incorporation | is_active
123456        | StartupCo Inc.    | SaaS      | Technology     | Delaware              | true
234567        | TechVentures LLC  | AI/ML     | Technology     | Delaware              | true
345678        | CloudCorp Inc.    | Cloud     | Technology     | California            | true
```

---

## 💳 Subscription Analysis

### Get all active subscriptions for a company
```sql
SELECT 
    corp.legal_name,
    sub.product,
    sub.package_type,
    sub.activation_date,
    sub.current_arr_dollars,
    sub.current_threshold_ct,
    sub.current_tier,
    sub.is_paying
FROM core_dim_corporations corp
INNER JOIN core_dim_corporations_subscriptions sub
    ON corp.corporation_id = sub.corporation_id
WHERE corp.legal_name = 'StartupCo, Inc.'
    AND corp.is_void = FALSE
    AND sub.is_active = TRUE
ORDER BY sub.current_arr_dollars DESC
```

### Find companies by subscription tier
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    sub.product,
    sub.package_type,
    sub.current_arr_dollars
FROM core_dim_corporations corp
INNER JOIN core_dim_corporations_subscriptions sub
    ON corp.corporation_id = sub.corporation_id
WHERE sub.package_type = 'Scale'
    AND sub.is_active = TRUE
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
ORDER BY sub.current_arr_dollars DESC
LIMIT 50
```

### Compare subscription features
```sql
SELECT 
    sub.package_type,
    COUNT(DISTINCT corp.corporation_id) AS company_count,
    AVG(sub.current_arr_dollars) AS avg_arr,
    SUM(sub.current_arr_dollars) AS total_arr,
    AVG(sub.current_threshold_ct) AS avg_stakeholders
FROM core_dim_corporations corp
INNER JOIN core_dim_corporations_subscriptions sub
    ON corp.corporation_id = sub.corporation_id
WHERE sub.is_active = TRUE
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
    AND sub.product = 'CapTable'
GROUP BY 1
ORDER BY total_arr DESC
```

**Expected Output**:
```
package_type | company_count | avg_arr    | total_arr    | avg_stakeholders
Scale        | 1,250        | 18500.00   | 23,125,000  | 350
Growth       | 3,420        | 8200.00    | 28,044,000  | 150
Starter      | 8,950        | 2400.00    | 21,480,000  | 45
Custom       | 280          | 45000.00   | 12,600,000  | 800
```

---

## 💰 ARR Analysis

### Get current ARR by company
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    arr.product,
    arr.arr_cumulative,
    arr.ct_stakeholders,
    arr.segment
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND corp.is_void = FALSE
    AND arr.arr_cumulative > 0
ORDER BY arr.arr_cumulative DESC
LIMIT 100
```

### Get ARR trend for a specific company
```sql
SELECT 
    arr.as_of_date,
    arr.product,
    arr.arr_cumulative,
    arr.ct_stakeholders
FROM core_historical_corporations_subscription_arr arr
WHERE arr.corporation_id = 123456
    AND arr.as_of_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
    AND arr.is_last_day_of_month = TRUE
ORDER BY arr.as_of_date, arr.product
```

### Month-over-month ARR growth
```sql
WITH monthly_arr AS (
    SELECT 
        DATE_TRUNC('month', as_of_date) AS month,
        product,
        SUM(arr_cumulative) AS arr_cumulative
    FROM core_historical_corporations_subscription_arr
    WHERE is_last_day_of_month = TRUE
        AND as_of_date >= CURRENT_DATE - INTERVAL '13 months'
    GROUP BY 1, 2
)
SELECT 
    curr.month,
    curr.product,
    curr.arr_cumulative AS current_arr,
    prev.arr_cumulative AS prior_month_arr,
    curr.arr_cumulative - prev.arr_cumulative AS arr_growth,
    ((curr.arr_cumulative - prev.arr_cumulative) / NULLIF(prev.arr_cumulative, 0) * 100) AS growth_pct
FROM monthly_arr curr
LEFT JOIN monthly_arr prev
    ON curr.product = prev.product
    AND curr.month = prev.month + INTERVAL '1 month'
ORDER BY curr.month DESC, curr.product
```

### Top companies by ARR
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    corp.state_of_incorporation,
    SUM(arr.arr_cumulative) AS total_arr,
    COUNT(DISTINCT arr.product) AS product_count
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
GROUP BY 1, 2, 3
ORDER BY total_arr DESC
LIMIT 50
```

---

## 📊 Product Mix Analysis

### ARR breakdown by product
```sql
SELECT 
    arr.product,
    COUNT(DISTINCT arr.corporation_id) AS company_count,
    AVG(arr.arr_cumulative) AS avg_arr,
    SUM(arr.arr_cumulative) AS total_arr
FROM core_historical_corporations_subscription_arr arr
INNER JOIN core_dim_corporations corp
    ON arr.corporation_id = corp.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND corp.is_void = FALSE
    AND arr.arr_cumulative > 0
GROUP BY 1
ORDER BY total_arr DESC
```

### Product adoption by industry
```sql
SELECT 
    corp.industry_broad,
    arr.product,
    COUNT(DISTINCT corp.corporation_id) AS company_count,
    AVG(arr.arr_cumulative) AS avg_arr,
    SUM(arr.arr_cumulative) AS total_arr
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
    AND arr.arr_cumulative > 0
GROUP BY 1, 2
ORDER BY 1, total_arr DESC
```

### Multi-product customers
```sql
WITH product_counts AS (
    SELECT 
        corporation_id,
        COUNT(DISTINCT product) AS product_count,
        SUM(arr_cumulative) AS total_arr
    FROM core_historical_corporations_subscription_arr
    WHERE as_of_date = CURRENT_DATE - 1
        AND arr_cumulative > 0
    GROUP BY 1
)
SELECT 
    corp.legal_name,
    pc.product_count,
    pc.total_arr,
    LISTAGG(DISTINCT arr.product, ', ') WITHIN GROUP (ORDER BY arr.product) AS products
FROM product_counts pc
INNER JOIN core_dim_corporations corp
    ON pc.corporation_id = corp.corporation_id
INNER JOIN core_historical_corporations_subscription_arr arr
    ON pc.corporation_id = arr.corporation_id
    AND arr.as_of_date = CURRENT_DATE - 1
WHERE pc.product_count >= 3
    AND corp.is_void = FALSE
GROUP BY 1, 2, 3
ORDER BY pc.product_count DESC, pc.total_arr DESC
LIMIT 50
```

---

## 🔍 Churn Analysis

### Companies that churned this quarter
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    arr.product,
    arr.churn_date,
    arr.arr_cumulative AS arr_at_churn,
    arr.segment
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.is_date_of_churn = TRUE
    AND DATE_TRUNC('quarter', arr.churn_date) = DATE_TRUNC('quarter', CURRENT_DATE)
ORDER BY arr.arr_cumulative DESC
```

### Churn rate by segment
```sql
WITH churned AS (
    SELECT 
        segment,
        product,
        COUNT(DISTINCT corporation_id) AS churned_companies,
        SUM(arr_cumulative) AS churned_arr
    FROM core_historical_corporations_subscription_arr
    WHERE is_date_of_churn = TRUE
        AND churn_date >= DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY 1, 2
),
active AS (
    SELECT 
        segment,
        product,
        COUNT(DISTINCT corporation_id) AS active_companies,
        SUM(arr_cumulative) AS active_arr
    FROM core_historical_corporations_subscription_arr
    WHERE as_of_date = CURRENT_DATE - 1
        AND is_active_today = TRUE
    GROUP BY 1, 2
)
SELECT 
    a.segment,
    a.product,
    a.active_companies,
    COALESCE(c.churned_companies, 0) AS churned_ytd,
    (COALESCE(c.churned_companies, 0)::FLOAT / NULLIF(a.active_companies, 0) * 100) AS churn_rate_pct,
    a.active_arr,
    COALESCE(c.churned_arr, 0) AS churned_arr_ytd
FROM active a
LEFT JOIN churned c
    ON a.segment = c.segment
    AND a.product = c.product
ORDER BY a.segment, churn_rate_pct DESC
```

### Recovery analysis (churned then came back)
```sql
SELECT 
    corp.legal_name,
    arr.product,
    arr.churn_date,
    recovery.as_of_date AS recovery_date,
    recovery.arr_cumulative AS recovered_arr,
    DATEDIFF(day, arr.churn_date, recovery.as_of_date) AS days_to_recovery
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
INNER JOIN core_historical_corporations_subscription_arr recovery
    ON arr.corporation_id = recovery.corporation_id
    AND arr.product = recovery.product
WHERE arr.is_date_of_churn = TRUE
    AND recovery.is_date_of_recovery = TRUE
    AND recovery.as_of_date > arr.churn_date
    AND arr.churn_date >= CURRENT_DATE - INTERVAL '2 years'
ORDER BY days_to_recovery
```

---

## 🏢 Stakeholder & Company Size Analysis

### Companies by stakeholder count
```sql
SELECT 
    CASE 
        WHEN arr.ct_adjusted_stakeholders < 50 THEN '0-49'
        WHEN arr.ct_adjusted_stakeholders < 100 THEN '50-99'
        WHEN arr.ct_adjusted_stakeholders < 250 THEN '100-249'
        WHEN arr.ct_adjusted_stakeholders < 500 THEN '250-499'
        ELSE '500+' 
    END AS stakeholder_bucket,
    COUNT(DISTINCT arr.corporation_id) AS company_count,
    AVG(arr.arr_cumulative) AS avg_arr,
    SUM(arr.arr_cumulative) AS total_arr
FROM core_historical_corporations_subscription_arr arr
INNER JOIN core_dim_corporations corp
    ON arr.corporation_id = corp.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND arr.product = 'CapTable'
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
GROUP BY 1
ORDER BY stakeholder_bucket
```

### Companies with most employees
```sql
SELECT 
    corp.legal_name,
    corp.industry,
    arr.ct_employees,
    arr.ct_stakeholders,
    arr.arr_cumulative
FROM core_dim_corporations corp
INNER JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND corp.is_active = TRUE
    AND corp.is_void = FALSE
ORDER BY arr.ct_employees DESC NULLS LAST
LIMIT 100
```

---

## 🔗 LLC vs Corporation Analysis

### Find all LLC companies
```sql
SELECT 
    corporation_id,
    legal_name,
    legal_entity_type,
    industry,
    state_of_incorporation,
    has_llc_waterfall,
    is_active
FROM core_dim_corporations
WHERE has_llc_waterfall = TRUE
    AND is_void = FALSE
ORDER BY legal_name
```

### Compare LLC vs non-LLC metrics
```sql
SELECT 
    CASE WHEN corp.has_llc_waterfall THEN 'LLC' ELSE 'Corporation' END AS entity_type,
    COUNT(DISTINCT corp.corporation_id) AS company_count,
    COUNT(DISTINCT sub.subscription_id) AS subscription_count,
    AVG(arr.arr_cumulative) AS avg_arr,
    SUM(arr.arr_cumulative) AS total_arr,
    AVG(arr.ct_stakeholders) AS avg_stakeholders
FROM core_dim_corporations corp
LEFT JOIN core_dim_corporations_subscriptions sub
    ON corp.corporation_id = sub.corporation_id
    AND sub.is_active = TRUE
LEFT JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
    AND arr.as_of_date = CURRENT_DATE - 1
WHERE corp.is_active = TRUE
    AND corp.is_void = FALSE
GROUP BY 1
```

**Expected Output**:
```
entity_type   | company_count | subscription_count | avg_arr   | total_arr      | avg_stakeholders
Corporation   | 45,230       | 58,450            | 5200.00   | 235,196,000   | 125
LLC           | 3,850        | 4,120             | 8500.00   | 32,725,000    | 15
```

---

## ⏰ Time-Series Analysis

### New companies by month
```sql
SELECT 
    DATE_TRUNC('month', arr.go_live_date) AS month,
    COUNT(DISTINCT arr.corporation_id) AS new_companies,
    SUM(arr.arr_cumulative) AS new_arr
FROM core_historical_corporations_subscription_arr arr
INNER JOIN core_dim_corporations corp
    ON arr.corporation_id = corp.corporation_id
WHERE arr.is_launch = TRUE
    AND arr.go_live_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
    AND corp.is_void = FALSE
GROUP BY 1
ORDER BY 1 DESC
```

### ARR cohort analysis
```sql
WITH cohort AS (
    SELECT 
        corporation_id,
        DATE_TRUNC('month', MIN(go_live_date)) AS cohort_month
    FROM core_historical_corporations_subscription_arr
    WHERE is_launch = TRUE
    GROUP BY 1
)
SELECT 
    c.cohort_month,
    COUNT(DISTINCT arr.corporation_id) AS cohort_size,
    SUM(CASE WHEN arr.is_active_today THEN arr.arr_cumulative ELSE 0 END) AS current_arr,
    SUM(CASE WHEN arr.is_churned THEN 1 ELSE 0 END) AS churned_count,
    (SUM(CASE WHEN arr.is_churned THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(DISTINCT arr.corporation_id), 0) * 100) AS churn_rate_pct
FROM cohort c
INNER JOIN core_historical_corporations_subscription_arr arr
    ON c.corporation_id = arr.corporation_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND c.cohort_month >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '2 years'
GROUP BY 1
ORDER BY 1 DESC
```

---

## 🚨 Data Quality Checks

### Companies without ARR
```sql
SELECT 
    corp.corporation_id,
    corp.legal_name,
    corp.industry,
    corp.go_live_at,
    corp.is_active
FROM core_dim_corporations corp
LEFT JOIN core_historical_corporations_subscription_arr arr
    ON corp.corporation_id = arr.corporation_id
    AND arr.as_of_date = CURRENT_DATE - 1
WHERE corp.is_active = TRUE
    AND corp.is_void = FALSE
    AND (arr.arr_cumulative IS NULL OR arr.arr_cumulative = 0)
ORDER BY corp.go_live_at DESC
LIMIT 100
```

### Subscriptions without matching corporation
```sql
SELECT 
    sub.subscription_id,
    sub.corporation_id,
    sub.product,
    sub.is_active
FROM core_dim_corporations_subscriptions sub
LEFT JOIN core_dim_corporations corp
    ON sub.corporation_id = corp.corporation_id
WHERE corp.corporation_id IS NULL
    AND sub.is_active = TRUE
```

### ARR discrepancies between subscription and historical
```sql
WITH sub_arr AS (
    SELECT 
        corporation_id,
        SUM(current_arr_dollars) AS subscription_arr
    FROM core_dim_corporations_subscriptions
    WHERE is_active = TRUE
    GROUP BY 1
),
historical_arr AS (
    SELECT 
        corporation_id,
        SUM(arr_cumulative) AS historical_arr
    FROM core_historical_corporations_subscription_arr
    WHERE as_of_date = CURRENT_DATE - 1
    GROUP BY 1
)
SELECT 
    corp.legal_name,
    s.subscription_arr,
    h.historical_arr,
    s.subscription_arr - h.historical_arr AS difference,
    ((s.subscription_arr - h.historical_arr) / NULLIF(h.historical_arr, 0) * 100) AS diff_pct
FROM core_dim_corporations corp
INNER JOIN sub_arr s ON corp.corporation_id = s.corporation_id
INNER JOIN historical_arr h ON corp.corporation_id = h.corporation_id
WHERE ABS(s.subscription_arr - h.historical_arr) > 100
ORDER BY ABS(difference) DESC
LIMIT 50
```

---

## 📌 Pro Tips

### Always filter soft deletes
```sql
-- ❌ Wrong
SELECT * FROM core_dim_corporations

-- ✅ Correct
SELECT * FROM core_dim_corporations WHERE is_void = FALSE
```

### Use date filters efficiently
```sql
-- For current ARR, use yesterday's date (data lags by 1 day)
WHERE as_of_date = CURRENT_DATE - 1

-- For month-end snapshots
WHERE is_last_day_of_month = TRUE
```

### Distinguish active vs archived
```sql
-- Active, paying customers
WHERE is_active = TRUE AND is_void = FALSE

-- Archived/iceboxed companies
WHERE is_archived = TRUE OR in_icebox = TRUE

-- All companies (including inactive)
WHERE is_void = FALSE
```

### Use the right ARR field
```sql
-- For reporting: Use finance ARR (what Finance reports)
SELECT finance_arr_dollars FROM core_historical_corporations_subscription_arr

-- For analysis: Use cumulative ARR (most comprehensive)
SELECT arr_cumulative FROM core_historical_corporations_subscription_arr

-- For forecasting: Use renewal ARR
SELECT renewal_arr_dollars FROM core_historical_corporations_subscription_arr
```

---

## 🎓 Learning Path

1. **Start simple**: Look up companies by name or industry
2. **Explore subscriptions**: Join companies to their subscriptions
3. **Add ARR**: Include billing and revenue data
4. **Time-series**: Analyze trends over time
5. **Churn analysis**: Track customer retention
6. **Cohorts**: Understand customer lifecycle

**Next**: Try modifying these queries for your specific use case!
