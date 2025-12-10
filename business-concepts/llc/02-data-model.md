# LLC: Data Model

**Data Note**: LLC cap table data is stored in **Corporation tables** with `has_llc_waterfall = true` flag.  
LLC **billing/ARR** is tracked separately in Zuora.

---

## 🗂️ Key Point

**LLCs in Carta are stored as Corporations** with special flags:
- `corporation.has_llc_waterfall = TRUE`
- Different equity instruments (units vs shares)
- Capital account tracking features

---

## 💰 LLC ARR Models (Zuora Billing)

### `core_dim_zuora_llc_products`
**Schema**: `dbt_verified_core`  
**Grain**: One row per **Salesforce Account** (latest snapshot)  
**Purpose**: LLC-specific product ARR breakdown

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `salesforce_account_id` | VARCHAR | Primary key (account ID) |
| `llc_cap_table_arr_dollars` | FLOAT | LLC Cap Table product ARR |
| `is_llc_cap_table_active` | BOOLEAN | Has active LLC cap table |
| `is_llc_cap_table_churned` | BOOLEAN | LLC cap table churned |
| `llc_cap_table_churn_date` | DATE | Date of churn |

**Example Query**:
```sql
SELECT 
    salesforce_account_id,
    llc_cap_table_arr_dollars,
    is_llc_cap_table_active
FROM core_dim_zuora_llc_products
WHERE is_llc_cap_table_active = TRUE
ORDER BY llc_cap_table_arr_dollars DESC
LIMIT 10
```

---

### `core_historical_llc_arr_decomp_detailed`
**Schema**: `dbt_verified_core`  
**Grain**: One row per account per date per product  
**Purpose**: Detailed LLC ARR time-series with decomposition

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `as_of_date` | DATE | Snapshot date |
| `salesforce_account_id` | VARCHAR | Account ID |
| `salesforce_entity_id` | VARCHAR | Entity ID (if applicable) |
| `product` | VARCHAR | Product name |
| `arr_dollars` | FLOAT | ARR amount |
| `arr_category` | VARCHAR | New/Expansion/Contraction/Churn |

**Example Query**:
```sql
SELECT 
    as_of_date,
    product,
    SUM(arr_dollars) AS total_llc_arr
FROM core_historical_llc_arr_decomp_detailed
WHERE as_of_date >= CURRENT_DATE - INTERVAL '12 months'
    AND is_last_day_of_month = TRUE
GROUP BY 1, 2
ORDER BY 1 DESC, 2
```

---

## 🏢 LLC Company Data (Corporation Tables)

### `core_dim_corporations`
**Schema**: `dbt_verified_core`  
**Filtering**: `has_llc_waterfall = TRUE`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `corporation_id` | NUMBER | Primary key |
| `legal_name` | VARCHAR | Company legal name |
| `has_llc_waterfall` | BOOLEAN | **LLC indicator** |
| `legal_entity_type` | VARCHAR | Entity type |
| `is_active` | BOOLEAN | Company active status |

**Example Query**:
```sql
-- Find all LLC companies
SELECT 
    corporation_id,
    legal_name,
    legal_entity_type,
    created_at
FROM core_dim_corporations
WHERE has_llc_waterfall = TRUE
    AND is_active = TRUE
ORDER BY created_at DESC
LIMIT 20
```

---

## 📌 Important Notes

### LLC vs Corporation Data

**Same Tables, Different Flags**:
```sql
-- Corporations (C-corp, S-corp)
SELECT * FROM core_dim_corporations 
WHERE has_llc_waterfall = FALSE

-- LLCs
SELECT * FROM core_dim_corporations 
WHERE has_llc_waterfall = TRUE
```

### ARR Tracking Separation

**LLC ARR** (billing):
- `core_dim_zuora_llc_products`
- `core_historical_llc_arr_decomp_detailed`

**Corporation ARR** (billing):
- `core_dim_corporations_subscriptions`
- `core_historical_corporations_subscription_arr`

---

## 🔗 Join Patterns

### LLC ARR to Company Data
```sql
SELECT 
    corp.legal_name,
    corp.corporation_id,
    llc_arr.llc_cap_table_arr_dollars
FROM core_dim_corporations corp
INNER JOIN base_salesforce_accounts sfdc
    ON corp.corporation_id = sfdc.corporation_id
INNER JOIN core_dim_zuora_llc_products llc_arr
    ON sfdc.account_id = llc_arr.salesforce_account_id
WHERE corp.has_llc_waterfall = TRUE
    AND corp.is_active = TRUE
```

---

## 💡 Key Takeaways

1. **LLC companies use Corporation tables** with `has_llc_waterfall = TRUE`
2. **LLC ARR tracked separately** in Zuora LLC product models
3. **No separate LLC member tables** - use equity/stakeholder tables
4. **Capital accounts** tracked via waterfall functionality
