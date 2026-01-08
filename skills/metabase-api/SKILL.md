---
name: metabase-api
description: Query and create Metabase questions via API, export results, and manage collections
---

# Metabase API

Query, create, and manage Metabase questions (cards) and export results.

## Prerequisites

User must provide:
1. **Metabase question URL** (e.g., `https://metabase-prod.ds.carta.rocks/question/16232-invoice-manager-scratchpad`)
2. **metabase.SESSION cookie value**

## API Documentation References

Key Metabase API endpoints:
- **Cards** (Questions/Queries): https://www.metabase.com/docs/latest/api#tag/apicard
  - `GET /api/card/:id` - Get card metadata
  - `POST /api/card/:id/query` - Execute card query
  - `PUT /api/card/:id` - Update card
  - `POST /api/card` - Create new card
- **Collections**: https://www.metabase.com/docs/latest/api#tag/apicollection
  - `GET /api/collection` - List all collections
  - `GET /api/collection/:id/items` - Get collection contents
  - `POST /api/collection` - Create collection
- **Dashboards**: https://www.metabase.com/docs/latest/api#tag/apidashboard
  - `GET /api/dashboard/:id` - Get dashboard
  - `GET /api/dashboard/:dashboard-id/dashcard/:dashcard-id/card/:card-id/query` - Execute dashboard card query
  - `POST /api/dashboard` - Create dashboard
- **Database Metadata**: https://www.metabase.com/docs/latest/api#tag/apidatabase
  - `GET /api/database/:id/metadata` - Get all tables and fields for a database
  - `GET /api/table/:id/query_metadata` - Get detailed field metadata for a table

## Getting the Session Token

### Automatic Method (Preferred)

Try using Playwright MCP to automatically retrieve the session cookie:

```javascript
// Navigate to Metabase (if not already there)
mcp__playwright__browser_navigate("https://metabase-prod.ds.carta.rocks")

// Extract the session cookie
mcp__playwright__browser_run_code(async (page) => {
  const cookies = await page.context().cookies();
  const sessionCookie = cookies.find(c => c.name === 'metabase.SESSION');
  return sessionCookie?.value;
})
```

**Note:** This will incur ~15K-30K tokens in context due to page state snapshots returned by Playwright MCP.

### Manual Fallback Method

If Playwright MCP is unavailable or fails, ask user to retrieve their `metabase.SESSION` cookie manually:

1. Open Metabase in Island/Chrome browser and log in via Okta SSO
2. Open DevTools: `Cmd+Option+I` (Mac) or `F12` (Windows)
3. Go to **Application** tab → **Cookies** → select the Metabase domain
4. Find `metabase.SESSION` cookie and copy its **Value**
5. Provide the value (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

## Query Types: GUI Questions vs SQL Queries

Metabase supports two types of questions:

### 1. GUI Questions (MBQL) - PREFERRED
**Use this by default** - enables seamless drill-down functionality

- **Type:** `"query"` with MBQL (Metabase Query Language)
- **Pros:**
  - ✅ Full drill-down capability in Metabase UI
  - ✅ Visual query builder for users
  - ✅ Better integration with Metabase features
  - ✅ Column-level permissions respected
- **Cons:**
  - Requires looking up table IDs and field IDs
  - Limited to simpler query patterns

**Example MBQL structure:**
```json
{
  "dataset_query": {
    "type": "query",
    "query": {
      "source-table": 123,
      "aggregation": [["distinct", ["field", 456, null]]],
      "breakout": [["field", 789, {"temporal-unit": "month"}]],
      "filter": ["=", ["field", 101, null], "Approved"]
    },
    "database": 1
  },
  "display": "bar"
}
```

### 2. SQL Queries (Native) - FALLBACK ONLY
**Only use when MBQL cannot express the query**

- **Type:** `"native"` with raw SQL
- **Pros:**
  - Can express any SQL query
  - Works with CTEs, window functions, complex joins
- **Cons:**
  - ❌ Limited drill-down capabilities
  - ❌ No visual query builder
  - ❌ Users must edit SQL directly

**When to fall back to SQL:**
- Complex JOINs with aliases or multiple tables
- CTEs (WITH clauses) or subqueries
- Window functions (ROW_NUMBER, LAG, LEAD, etc.)
- Custom SQL expressions not supported by MBQL
- UNION or other set operations

## Looking Up Table and Field IDs

To create GUI questions, you need numeric IDs for tables and fields.

### Step 1: Get Database Metadata

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/database/1/metadata" | \
  jq '.tables[] | select(.name == "CORE_FCT_ZIP_REQUESTS") | {id, schema, name}'
```

**Response:**
```json
{
  "id": 123,
  "schema": "DBT_VERIFIED_CORE",
  "name": "CORE_FCT_ZIP_REQUESTS"
}
```

### Step 2: Get Field Metadata for Table

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/table/123/query_metadata" | \
  jq '.fields[] | {id, name, base_type}'
```

**Response:**
```json
[
  {"id": 456, "name": "REQUEST_ID", "base_type": "type/Text"},
  {"id": 789, "name": "REQUEST_COMPLETED_AT", "base_type": "type/DateTime"},
  {"id": 101, "name": "REQUEST_STATUS_NAME", "base_type": "type/Text"}
]
```

### Step 3: Build MBQL Query

Use the IDs from above:
- `source-table`: 123 (table ID)
- `field` references: 456, 789, 101 (field IDs)

## MBQL Common Patterns

### Count Distinct Grouped by Month

**Use case:** Month-over-month metrics (e.g., distinct zip requests)

```json
{
  "dataset_query": {
    "type": "query",
    "query": {
      "source-table": 123,
      "aggregation": [["distinct", ["field", 456, null]]],
      "breakout": [["field", 789, {"temporal-unit": "month"}]],
      "filter": ["=", ["field", 101, null], "Approved"]
    },
    "database": 1
  },
  "display": "bar",
  "visualization_settings": {}
}
```

**Explanation:**
- `source-table: 123` → CORE_FCT_ZIP_REQUESTS table
- `aggregation: [["distinct", ["field", 456, null]]]` → COUNT(DISTINCT REQUEST_ID)
- `breakout: [["field", 789, {"temporal-unit": "month"}]]` → GROUP BY DATE_TRUNC('month', REQUEST_COMPLETED_AT)
- `filter: ["=", ["field", 101, null], "Approved"]` → WHERE REQUEST_STATUS_NAME = 'Approved'

### Simple Count Grouped by Category

```json
{
  "query": {
    "source-table": 123,
    "aggregation": [["count"]],
    "breakout": [["field", 101, null]]
  }
}
```

### Sum with Filter

```json
{
  "query": {
    "source-table": 123,
    "aggregation": [["sum", ["field", 999, null]]],
    "breakout": [["field", 789, {"temporal-unit": "month"}]],
    "filter": ["and",
      ["=", ["field", 101, null], "Approved"],
      [">", ["field", 789, null], "2025-01-01"]
    ]
  }
}
```

### Multiple Aggregations

```json
{
  "query": {
    "source-table": 123,
    "aggregation": [
      ["count"],
      ["sum", ["field", 999, null]],
      ["avg", ["field", 888, null]]
    ],
    "breakout": [["field", 789, {"temporal-unit": "month"}]]
  }
}
```

## Workflow

The following workflow demonstrates querying a Card (question). Similar patterns apply to Collections and Dashboards using their respective API endpoints (see API Documentation References above).

### 1. Extract Card ID from URL

Parse the card ID from the question URL. Examples:
- `https://metabase-prod.ds.carta.rocks/question/16232-invoice-manager-scratchpad` → card ID: `16232`
- `https://metabase-prod.ds.carta.rocks/question/16232` → card ID: `16232`

For Collections: `https://metabase-prod.ds.carta.rocks/collection/123` → collection ID: `123`
For Dashboards: `https://metabase-prod.ds.carta.rocks/dashboard/456` → dashboard ID: `456`

### 2. Get Card Metadata

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/card/$CARD_ID" | jq .
```

Returns: card name, description, SQL query, column metadata, creator info, etc.

### 3. Execute Query

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card/$CARD_ID/query" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 4. Default Behavior: Summarize Results

After executing:
- Report row count and column names
- Summarize key data patterns/statistics
- Show sample of first few rows

### 5. Prompt User for Next Steps

Ask user what they'd like to do:
- **Save as CSV**: Export to `/tmp/<card_name>.csv`
- **Save as JSON**: Export raw response to `/tmp/<card_name>.json`
- **Analyze further**: Run additional analysis
- **Something else**: Custom request

## Exporting Data

**CSV export:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card/$CARD_ID/query" \
  -H "Content-Type: application/json" \
  -d '{}' | jq -r '
  (.data.cols | map(.name)) as $headers |
  ($headers | @csv),
  (.data.rows[] | @csv)
' > /tmp/output.csv
```

**JSON export:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card/$CARD_ID/query" \
  -H "Content-Type: application/json" \
  -d '{}' > /tmp/output.json
```

## Creating Cards (Streamlined Method)

### Using the metabase-create-card Helper Script (RECOMMENDED)

The fastest way to create Metabase cards is using the `metabase-create-card` command, which handles all ID lookups and caching automatically.

**Basic Usage:**

```bash
metabase-create-card \
  --name "Card Name" \
  --table TABLE_NAME \
  --agg-type distinct \
  --agg-field FIELD_NAME \
  --breakout FIELD1,FIELD2 \
  --display bar
```

**Example: MoM Distinct Count Stacked Bar Chart**

```bash
metabase-create-card \
  --name "MoM Distinct Zip Requests by Status" \
  --table CORE_FCT_ZIP_REQUESTS \
  --agg-type distinct \
  --agg-field REQUEST_ID \
  --breakout REQUEST_CREATED_AT,REQUEST_STATUS_NAME \
  --temporal-unit month \
  --display bar \
  --stacked
```

**Available Options:**

- `--name NAME`: Card name (required)
- `--table TABLE_NAME`: Table name without schema (default schema: DBT_VERIFIED_CORE)
- `--schema SCHEMA`: Override default schema
- `--agg-type TYPE`: Aggregation type: `count`, `distinct`, `sum`, `avg` (default: `distinct`)
- `--agg-field FIELD`: Field to aggregate (required for distinct/sum/avg)
- `--breakout FIELD1,FIELD2`: Comma-separated fields for grouping
- `--temporal-unit UNIT`: For date breakouts: `month`, `day`, `year`
- `--display TYPE`: Visualization: `bar`, `line`, `table`, `pie` (default: `bar`)
- `--stacked`: Enable stacked bars (for bar charts)
- `--description DESC`: Card description
- `--refresh-cache`: Force refresh of cached IDs

**How it works:**

1. Auto-retrieves session token (prompts if needed)
2. Caches table IDs and field IDs in `~/.claude/skills/metabase-api/cache.json`
3. Subsequent calls are faster (no ID lookups needed)
4. Returns the Metabase URL for the new card

**Cache Management:**

The script maintains a cache at `~/.claude/skills/metabase-api/cache.json` with:
- Your personal collection ID
- Snowflake database ID (hardcoded to 9)
- Table IDs (schema.table → numeric ID)
- Field IDs (table_id.field → numeric ID)

Use `--refresh-cache` if IDs become stale or tables/fields are added.

---

## Creating Cards (Manual Method)

### Prerequisites for Card Creation

1. **Database ID**: Typically `1` for main Snowflake production database
2. **Personal Collection ID**: User's personal collection ("Klajdi Ziaj's Personal Collection")
3. **Session token**: Same authentication as querying

### ⚠️ CRITICAL: Validate with snow cli First

**MANDATORY: Test data access using snow cli BEFORE creating Metabase cards.**

```bash
snow sql --query "SELECT * FROM prod_db.dbt_verified_core.core_fct_zip_requests LIMIT 10" --format JSON
```

**Why this is required:**
- ✅ Validates table access and Snowflake permissions
- ✅ Confirms table/column names are correct
- ✅ Ensures data availability
- ✅ Respects row-level security and data access controls

**Use for validation even when creating GUI questions** - you're not creating SQL cards, but you need to verify the table exists and is accessible.

### Workflow: Create a New Card

**PREFERRED: Create GUI Question (MBQL)** → Falls back to SQL if needed

#### Step 0: Validate Data Access with snow cli (MANDATORY)

**Before any card creation, validate table access:**

```bash
snow sql --query "SELECT * FROM prod_db.dbt_verified_core.core_fct_zip_requests LIMIT 10" --format JSON
```

**Confirm:**
- Query executes successfully
- Table and columns exist
- No permission errors

**If validation fails, DO NOT proceed to card creation.**

#### Step 1: Get Session Token

Use Playwright MCP to retrieve session cookie (see "Getting the Session Token" section above).

#### Step 2: Find User's Personal Collection ID

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/collection" | \
  jq '.[] | select(.name == "Klajdi Ziaj'"'"'s Personal Collection") | {id, name}'
```

Returns:
```json
{
  "id": 123,
  "name": "Klajdi Ziaj's Personal Collection"
}
```

#### Step 3: Look Up Table ID

Get the numeric table ID for your source table:

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/database/1/metadata" | \
  jq '.tables[] | select(.schema == "DBT_VERIFIED_CORE" and .name == "CORE_FCT_ZIP_REQUESTS") | {id, schema, name}'
```

**Example response:**
```json
{"id": 123, "schema": "DBT_VERIFIED_CORE", "name": "CORE_FCT_ZIP_REQUESTS"}
```

#### Step 4: Look Up Field IDs

Get the numeric field IDs for columns you'll use:

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/table/123/query_metadata" | \
  jq '.fields[] | select(.name == "REQUEST_ID" or .name == "REQUEST_COMPLETED_AT" or .name == "REQUEST_STATUS_NAME") | {id, name, base_type}'
```

**Example response:**
```json
[
  {"id": 456, "name": "REQUEST_ID", "base_type": "type/Text"},
  {"id": 789, "name": "REQUEST_COMPLETED_AT", "base_type": "type/DateTime"},
  {"id": 101, "name": "REQUEST_STATUS_NAME", "base_type": "type/Text"}
]
```

#### Step 5: Create GUI Question Card

**Required fields:**
- `name`: Card title
- `dataset_query`: MBQL query structure
- `database_id`: Database ID (typically `1`)
- `collection_id`: Personal collection ID from Step 2
- `display`: Visualization type (`"table"`, `"bar"`, `"line"`, etc.)
- `visualization_settings`: Empty object `{}`

**Example: Create MoM distinct count bar chart**

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "MoM Distinct Approved Zip Requests",
    "dataset_query": {
      "type": "query",
      "query": {
        "source-table": 123,
        "aggregation": [["distinct", ["field", 456, null]]],
        "breakout": [["field", 789, {"temporal-unit": "month"}]],
        "filter": ["=", ["field", 101, null], "Approved"]
      },
      "database": 1
    },
    "display": "bar",
    "visualization_settings": {},
    "collection_id": 456,
    "description": "Month-over-month count of distinct approved zip requests"
  }' | jq '{id, name, collection_id}'
```

**Response:**
```json
{
  "id": 45678,
  "name": "MoM Distinct Approved Zip Requests",
  "collection_id": 456
}
```

#### Step 6: Return Card URL

Construct and display the URL:
```
https://metabase-prod.ds.carta.rocks/question/45678
```

---

### Fallback: Create SQL Card (When MBQL Cannot Express Query)

**Only use when the query requires SQL-only features** (CTEs, window functions, complex joins, etc.)

**Example: Create a card with native SQL query**

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Complex Query with CTE",
    "dataset_query": {
      "type": "native",
      "native": {
        "query": "WITH base AS (SELECT * FROM prod_db.dbt_core.table) SELECT * FROM base",
        "template-tags": {}
      },
      "database": 1
    },
    "display": "table",
    "visualization_settings": {},
    "collection_id": 456,
    "description": "Complex query requiring SQL"
  }' | jq '{id, name, collection_id}'
```

**Note:** SQL cards have limited drill-down capabilities compared to GUI questions.

### Card Creation User Flow

**User provides:**
- Card name (e.g., "MoM Distinct Approved Zip Requests")
- Description of what to measure (e.g., "distinct count of approved zip requests by month")
- Optional: table name, filters, visualization type

**Claude executes:**

1. **VALIDATE data access with snow cli first** (MANDATORY)
   ```bash
   snow sql --query "SELECT * FROM prod_db.dbt_verified_core.core_fct_zip_requests LIMIT 10" --format JSON
   ```
2. Only if validation succeeds:
3. Get session token via Playwright MCP
4. Find personal collection ID (cache it for session)
5. **Determine if GUI question is possible:**
   - **Simple aggregations** (count, sum, distinct, avg) → Use GUI (MBQL)
   - **Group by date/category** → Use GUI (MBQL)
   - **Simple filters** (equals, greater than, less than) → Use GUI (MBQL)
   - **Complex SQL** (CTEs, window functions, complex joins) → Fall back to SQL
6. Look up table ID and field IDs (for GUI questions)
7. Create card with POST /api/card
8. Return shareable URL

**If Step 1 fails, STOP and ask user to fix table/column names.**

**Example prompts for GUI questions:**
- "Create a Metabase bar chart: MoM distinct approved zip requests"
- "Make a question showing count of users by department"
- "Create a line chart of monthly revenue from the revenue table"

**Example prompts requiring SQL fallback:**
- "Create a card with this SQL: WITH base AS (...)" ← Has CTE
- "Show running total of revenue using window functions" ← Has window function
- "Create card joining 3 tables with custom aliases" ← Complex join

### Display Types

Common `display` values:
- `"table"`: Standard table view (default)
- `"bar"`: Bar chart
- `"line"`: Line chart
- `"pie"`: Pie chart
- `"scalar"`: Single number
- `"row"`: Row chart

### Advanced: Query with Parameters

For parameterized queries, use template tags:

```json
{
  "dataset_query": {
    "type": "native",
    "native": {
      "query": "SELECT * FROM table WHERE date > {{start_date}}",
      "template-tags": {
        "start_date": {
          "type": "date",
          "name": "start_date",
          "display-name": "Start Date"
        }
      }
    },
    "database": 1
  }
}
```

## Error Handling

### Querying Cards
- **401 Unauthorized**: Session expired. Ask user for fresh `metabase.SESSION` token.
- **404 Not Found**: Invalid card ID or user lacks access to question.
- **Empty results**: Query may have no data or require parameters.

### Creating Cards
- **400 Bad Request**: Invalid SQL syntax or malformed request body
- **401 Unauthorized**: Session expired or invalid token
- **403 Forbidden**: User lacks permission to create cards in specified collection
- **404 Not Found**: Collection or database not found
- **500 Internal Server Error**: Query execution error (check SQL syntax, table access)

## Example Session

```
User: Query https://metabase-prod.ds.carta.rocks/question/16232

Claude: I need your metabase.SESSION cookie to authenticate:
1. Open Metabase in your browser (logged in)
2. DevTools → Application → Cookies → metabase.SESSION
3. Copy and paste the value here

User: 1fcd815d-8a70-4fe5-b0f4-ae7e704c4e06

Claude: [executes query]

Card: Invoice Manager Scratchpad
- 100 rows, 42 columns
- Columns: ZUORA_ACCOUNT_ID, ACCOUNT_NUMBER, MRR, ...
- Summary: Billing data for Carta Investor Services accounts

What would you like to do with this data?
- Save as CSV
- Save as JSON
- Analyze further
- Something else
```
