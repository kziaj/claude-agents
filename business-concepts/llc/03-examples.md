# LLC: Examples & Common Queries

**Practical SQL examples** for working with LLC data.

---

## 🔍 Finding LLC Companies

### All LLC companies
```sql
SELECT 
    corporation_id,
    legal_name,
    legal_entity_type,
    created_at,
    has_llc_waterfall
FROM core_dim_corporations
WHERE has_llc_waterfall = TRUE
    AND is_active = TRUE
ORDER BY created_at DESC
LIMIT 20
```

### LLC companies with active ARR
```sql
SELECT 
    corp.legal_name,
    llc.llc_cap_table_arr_dollars,
    llc.is_llc_cap_table_active
FROM core_dim_corporations corp
INNER JOIN base_salesforce_accounts sfdc
    ON corp.corporation_id = sfdc.corporation_id
INNER JOIN core_dim_zuora_llc_products llc
    ON sfdc.account_id = llc.salesforce_account_id
WHERE corp.has_llc_waterfall = TRUE
    AND llc.is_llc_cap_table_active = TRUE
ORDER BY llc.llc_cap_table_arr_dollars DESC
```

---

## 💰 LLC ARR Analysis

### Monthly LLC ARR trend
```sql
SELECT 
    DATE_TRUNC('month', as_of_date) AS month,
    SUM(arr_dollars) AS total_llc_arr
FROM core_historical_llc_arr_decomp_detailed
WHERE is_last_day_of_month = TRUE
    AND as_of_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 1
ORDER BY 1 DESC
```

### LLC ARR by product
```sql
SELECT 
    product,
    SUM(arr_dollars) AS arr_dollars,
    COUNT(DISTINCT salesforce_account_id) AS account_count
FROM core_historical_llc_arr_decomp_detailed
WHERE as_of_date = CURRENT_DATE - 1
GROUP BY 1
ORDER BY 2 DESC
```

---

## 📊 LLC vs Corporation Comparison

### Count by entity type
```sql
SELECT 
    CASE 
        WHEN has_llc_waterfall THEN 'LLC'
        ELSE 'Corporation'
    END AS entity_type,
    COUNT(*) AS company_count
FROM core_dim_corporations
WHERE is_active = TRUE
GROUP BY 1
```

---

**See corporation examples for more cap table queries!**
