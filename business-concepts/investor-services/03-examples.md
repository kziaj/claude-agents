# Investor Services: Examples & Common Queries

**Practical SQL examples** for working with investor services data.

---

## 🎯 Basic Lookups

### Find a firm by name
```sql
SELECT 
    id AS firm_id,
    name AS firm_name,
    sfdc_id AS salesforce_account_id,
    fax_firm_segment AS segment,
    has_gl_enabled
FROM base_fund_admin_firms
WHERE name ILIKE '%sequoia%'
    AND is_deleted = FALSE
```

### Find all funds for a specific firm
```sql
SELECT 
    fund.id AS fund_id,
    fund.name AS fund_name,
    fund.entity_type_name,
    fund.legal_structure,
    fund.currency
FROM base_fund_admin_firms firm
INNER JOIN base_fund_admin_funds fund
    ON firm.id = fund.firm_id
WHERE firm.name = 'UpWest Labs'
    AND firm.is_deleted = FALSE
    AND fund.is_deleted = FALSE
ORDER BY fund.name
```

### Get fund counts by entity type
```sql
SELECT 
    entity_type_name,
    COUNT(*) AS entity_count
FROM base_fund_admin_funds
WHERE is_deleted = FALSE
GROUP BY entity_type_name
ORDER BY entity_count DESC
```

**Expected Output**:
```
entity_type_name    | entity_count
Fund                | 2,450
GP                  | 1,230
SPV                 | 3,890
Mgt Company         | 890
```

---

## 💰 ARR Analysis

### Get current ARR for all firms
```sql
SELECT 
    firm.name AS firm_name,
    arr.product,
    arr.arr_dollars,
    arr.is_churned
FROM base_fund_admin_firms firm
INNER JOIN core_historical_zuora_arr arr
    ON firm.sfdc_id = arr.salesforce_account_id
WHERE arr.as_of_date = CURRENT_DATE - 1
    AND firm.is_deleted = FALSE
ORDER BY arr.arr_dollars DESC
LIMIT 20
```

### Get ARR trend for a specific firm
```sql
SELECT 
    arr.as_of_date,
    arr.product,
    arr.arr_dollars
FROM core_historical_zuora_arr arr
WHERE arr.salesforce_account_id = '001f400000DTWIsAAP'
    AND arr.as_of_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
    AND arr.is_last_day_of_month = TRUE
ORDER BY arr.as_of_date, arr.product
```

### Compare firm-level vs entity-level ARR
```sql
WITH firm_arr AS (
    SELECT 
        salesforce_account_id,
        SUM(arr_dollars) AS firm_total_arr
    FROM core_historical_zuora_arr
    WHERE as_of_date = CURRENT_DATE - 1
        AND product = 'Fund Admin'
    GROUP BY 1
),
entity_arr AS (
    SELECT 
        salesforce_account_id,
        SUM(arr_dollars) AS entity_total_arr,
        COUNT(DISTINCT salesforce_entity_id) AS entity_count
    FROM core_fct_zuora_arr_by_salesforce_entity
    WHERE as_of_date = CURRENT_DATE - 1
        AND product = 'Fund Admin'
    GROUP BY 1
)
SELECT 
    firm.name AS firm_name,
    firm_arr.firm_total_arr,
    entity_arr.entity_total_arr,
    entity_arr.entity_count,
    firm_arr.firm_total_arr - entity_arr.entity_total_arr AS difference
FROM base_fund_admin_firms firm
INNER JOIN firm_arr
    ON firm.sfdc_id = firm_arr.salesforce_account_id
INNER JOIN entity_arr
    ON firm.sfdc_id = entity_arr.salesforce_account_id
WHERE ABS(firm_arr.firm_total_arr - entity_arr.entity_total_arr) > 100
ORDER BY ABS(difference) DESC
LIMIT 10
```

### Get product mix by firm segment
```sql
SELECT 
    firm.fax_firm_segment AS segment,
    prod.product,
    COUNT(DISTINCT firm.id) AS firm_count,
    AVG(prod.arr_dollars) AS avg_arr,
    SUM(prod.arr_dollars) AS total_arr
FROM base_fund_admin_firms firm
INNER JOIN core_historical_zuora_arr prod
    ON firm.sfdc_id = prod.salesforce_account_id
WHERE prod.as_of_date = CURRENT_DATE - 1
    AND firm.is_deleted = FALSE
    AND prod.arr_dollars > 0
GROUP BY 1, 2
ORDER BY 1, total_arr DESC
```

---

## 📊 Portfolio Analysis

### Get top portfolio companies by number of fund investors
```sql
SELECT 
    issuer.issuer_name AS portfolio_company,
    issuer.carta_entity_id AS corporation_id,
    COUNT(DISTINCT asset.fund_id) AS num_fund_investors,
    SUM(asset.cost_basis) AS total_investment
FROM base_fund_admin_general_ledger_asset_records asset
INNER JOIN transform_fund_admin_general_ledger_issuers_with_entity_links issuer
    ON asset.issuer_id = issuer.issuer_id
WHERE issuer.carta_entity_id IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(DISTINCT asset.fund_id) >= 3
ORDER BY num_fund_investors DESC, total_investment DESC
LIMIT 20
```

### Find all funds invested in a specific company
```sql
-- Find funds that invested in "Stripe"
SELECT 
    firm.name AS firm_name,
    fund.name AS fund_name,
    asset.shares_outstanding,
    asset.cost_basis AS investment_amount
FROM base_fund_admin_general_ledger_asset_records asset
INNER JOIN base_fund_admin_funds fund
    ON asset.fund_id = fund.id
INNER JOIN base_fund_admin_firms firm
    ON fund.firm_id = firm.id
INNER JOIN transform_fund_admin_general_ledger_issuers_with_entity_links issuer
    ON asset.issuer_id = issuer.issuer_id
WHERE issuer.issuer_name ILIKE '%stripe%'
    AND fund.is_deleted = FALSE
    AND firm.is_deleted = FALSE
ORDER BY asset.cost_basis DESC
```

### Get portfolio concentration by fund
```sql
SELECT 
    fund.name AS fund_name,
    COUNT(DISTINCT asset.issuer_id) AS num_portfolio_companies,
    SUM(asset.cost_basis) AS total_invested,
    MAX(asset.cost_basis) AS largest_position,
    (MAX(asset.cost_basis) / NULLIF(SUM(asset.cost_basis), 0)) * 100 AS largest_position_pct
FROM base_fund_admin_funds fund
LEFT JOIN base_fund_admin_general_ledger_asset_records asset
    ON fund.id = asset.fund_id
WHERE fund.entity_type = 1  -- Only actual funds
    AND fund.is_deleted = FALSE
GROUP BY 1
HAVING SUM(asset.cost_basis) > 0
ORDER BY total_invested DESC
LIMIT 20
```

---

## 🔍 Segment & Product Analysis

### Firms by segment with ARR
```sql
SELECT 
    firm.fax_firm_segment AS segment,
    COUNT(DISTINCT firm.id) AS firm_count,
    COUNT(DISTINCT fund.id) AS fund_count,
    SUM(arr.arr_dollars) AS total_arr,
    AVG(arr.arr_dollars) AS avg_arr_per_firm
FROM base_fund_admin_firms firm
LEFT JOIN base_fund_admin_funds fund
    ON firm.id = fund.firm_id
    AND fund.is_deleted = FALSE
LEFT JOIN core_historical_zuora_arr arr
    ON firm.sfdc_id = arr.salesforce_account_id
    AND arr.as_of_date = CURRENT_DATE - 1
WHERE firm.is_deleted = FALSE
GROUP BY 1
ORDER BY total_arr DESC NULLS LAST
```

### Active product adoption by firm
```sql
SELECT 
    firm.name AS firm_name,
    prod.is_fund_admin_active,
    prod.is_tax_active,
    prod.is_kyc_active,
    prod.is_gp_carry_active,
    prod.fund_admin_arr_dollars,
    prod.tax_arr_dollars,
    prod.all_products_arr_dollars AS total_arr
FROM base_fund_admin_firms firm
INNER JOIN core_dim_zuora_investor_services_products prod
    ON firm.sfdc_id = prod.salesforce_account_id
WHERE firm.is_deleted = FALSE
ORDER BY prod.all_products_arr_dollars DESC
LIMIT 50
```

### Product churn analysis
```sql
SELECT 
    product,
    COUNT(DISTINCT CASE WHEN is_churned THEN salesforce_account_id END) AS churned_accounts,
    COUNT(DISTINCT salesforce_account_id) AS total_accounts,
    (COUNT(DISTINCT CASE WHEN is_churned THEN salesforce_account_id END)::FLOAT / 
     NULLIF(COUNT(DISTINCT salesforce_account_id), 0) * 100) AS churn_rate_pct
FROM core_historical_zuora_arr
WHERE as_of_date = CURRENT_DATE - 1
GROUP BY product
ORDER BY churn_rate_pct DESC
```

---

## ⏰ Time-Series Analysis

### Month-over-month ARR growth
```sql
WITH monthly_arr AS (
    SELECT 
        DATE_TRUNC('month', as_of_date) AS month,
        product,
        SUM(arr_dollars) AS arr_dollars
    FROM core_historical_zuora_arr
    WHERE is_last_day_of_month = TRUE
        AND as_of_date >= CURRENT_DATE - INTERVAL '13 months'
    GROUP BY 1, 2
)
SELECT 
    curr.month,
    curr.product,
    curr.arr_dollars AS current_arr,
    prev.arr_dollars AS prior_month_arr,
    curr.arr_dollars - prev.arr_dollars AS arr_growth,
    ((curr.arr_dollars - prev.arr_dollars) / NULLIF(prev.arr_dollars, 0) * 100) AS growth_pct
FROM monthly_arr curr
LEFT JOIN monthly_arr prev
    ON curr.product = prev.product
    AND curr.month = prev.month + INTERVAL '1 month'
ORDER BY curr.month DESC, curr.product
```

### New vs retained vs churned ARR
```sql
WITH arr_last_month AS (
    SELECT DISTINCT
        salesforce_account_id,
        arr_dollars
    FROM core_historical_zuora_arr
    WHERE as_of_date = DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day'
        AND product = 'Fund Admin'
),
arr_this_month AS (
    SELECT DISTINCT
        salesforce_account_id,
        arr_dollars
    FROM core_historical_zuora_arr
    WHERE is_last_day_of_month = TRUE
        AND as_of_date = DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'
        AND product = 'Fund Admin'
)
SELECT 
    SUM(CASE 
        WHEN curr.salesforce_account_id IS NOT NULL AND prev.salesforce_account_id IS NULL 
        THEN curr.arr_dollars 
    END) AS new_arr,
    SUM(CASE 
        WHEN curr.salesforce_account_id IS NOT NULL AND prev.salesforce_account_id IS NOT NULL 
        THEN curr.arr_dollars 
    END) AS retained_arr,
    SUM(CASE 
        WHEN curr.salesforce_account_id IS NULL AND prev.salesforce_account_id IS NOT NULL 
        THEN prev.arr_dollars 
    END) AS churned_arr
FROM arr_this_month curr
FULL OUTER JOIN arr_last_month prev
    ON curr.salesforce_account_id = prev.salesforce_account_id
```

---

## 🔗 Cross-System Joins

### Link Fund Admin firm to CartaWeb organization
```sql
SELECT 
    firm.id AS fund_admin_firm_id,
    firm.name AS firm_name,
    firm.carta_id AS cartaweb_org_id,
    org.name AS cartaweb_org_name,
    org.entity_type_name AS org_type
FROM base_fund_admin_firms firm
LEFT JOIN raw_cartaweb_organizations.organizations_organization org
    ON firm.carta_id = org.id
WHERE firm.is_deleted = FALSE
LIMIT 10
```

### Connect Fund Admin to Salesforce
```sql
SELECT 
    firm.id AS fund_admin_firm_id,
    firm.name AS firm_name,
    firm.sfdc_id AS salesforce_account_id,
    sfdc.name AS salesforce_account_name,
    sfdc.owner_id AS account_owner
FROM base_fund_admin_firms firm
LEFT JOIN base_salesforce_accounts sfdc
    ON firm.sfdc_id = sfdc.account_id
WHERE firm.is_deleted = FALSE
    AND firm.sfdc_id IS NOT NULL
LIMIT 10
```

---

## 🚨 Data Quality Checks

### Firms without Salesforce mapping
```sql
SELECT 
    id AS firm_id,
    name AS firm_name,
    created_at,
    updated_at
FROM base_fund_admin_firms
WHERE sfdc_id IS NULL
    AND is_deleted = FALSE
ORDER BY created_at DESC
```

### Funds without a parent firm
```sql
SELECT 
    id AS fund_id,
    name AS fund_name,
    firm_id,
    entity_type_name
FROM base_fund_admin_funds
WHERE firm_id NOT IN (SELECT id FROM base_fund_admin_firms WHERE is_deleted = FALSE)
    AND is_deleted = FALSE
```

### ARR discrepancies between firm and entity level
```sql
-- Already shown above in "Compare firm-level vs entity-level ARR"
```

### Orphaned asset records
```sql
SELECT 
    asset.id AS asset_id,
    asset.fund_id,
    asset.issuer_id
FROM base_fund_admin_general_ledger_asset_records asset
WHERE asset.fund_id NOT IN (
    SELECT id 
    FROM base_fund_admin_funds 
    WHERE is_deleted = FALSE
)
LIMIT 10
```

---

## 📌 Pro Tips

### Always filter soft deletes
```sql
-- ❌ Wrong
SELECT * FROM base_fund_admin_firms

-- ✅ Correct
SELECT * FROM base_fund_admin_firms WHERE is_deleted = FALSE
```

### Use is_last_day_of_month for snapshots
```sql
-- For monthly analysis, filter on month-end only
WHERE is_last_day_of_month = TRUE
```

### Join via ID mapping tables
```sql
-- Use core_dim_fund_admin_fund_ids to join across systems
SELECT ...
FROM base_fund_admin_funds fund
INNER JOIN core_dim_fund_admin_fund_ids ids
    ON fund.id = ids.fund_admin_fund_id
INNER JOIN core_fct_zuora_arr_by_salesforce_entity arr
    ON ids.salesforce_entity_id = arr.salesforce_entity_id
```

### Understand ARR grain
```sql
-- Firm-level ARR (one row per firm per day)
SELECT * FROM core_historical_zuora_arr
WHERE salesforce_account_id = '<account_id>'

-- Entity-level ARR (one row per fund per day)
SELECT * FROM core_fct_zuora_arr_by_salesforce_entity
WHERE salesforce_entity_id = '<entity_id>'
```

---

## 🎓 Learning Path

1. **Start simple**: Look up firms and funds
2. **Explore relationships**: Join firms to funds
3. **Add ARR**: Include billing data
4. **Time-series**: Analyze trends over time
5. **Portfolio**: Connect to investments
6. **Cross-system**: Link to Salesforce, CartaWeb

**Next**: Try modifying these queries for your specific use case!
