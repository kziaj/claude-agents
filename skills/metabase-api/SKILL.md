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

## Creating Cards

### Prerequisites for Card Creation

1. **Database ID**: Typically `1` for main Snowflake production database
2. **Personal Collection ID**: User's personal collection ("Klajdi Ziaj's Personal Collection")
3. **Session token**: Same authentication as querying

### ⚠️ CRITICAL: Validate SQL with snow cli First

**MANDATORY: Test ALL SQL queries using snow cli BEFORE creating or updating Metabase cards.**

```bash
snow sql --query "YOUR_SQL_HERE" --format JSON
```

**Why this is required:**
- ✅ Catches syntax errors before card creation
- ✅ Validates table access and Snowflake permissions
- ✅ Ensures query performance is acceptable
- ✅ Prevents creating broken/failing cards in Metabase
- ✅ Respects row-level security and data access controls

**Example validation workflow:**

```bash
# Test your SQL query first
snow sql --query "SELECT * FROM prod_db.dbt_core.core_dim_users LIMIT 10" --format JSON

# Verify:
# 1. Query executes without errors
# 2. Results look correct
# 3. Performance is acceptable

# ONLY THEN create Metabase card with validated SQL
```

**If snow cli fails, fix the SQL before attempting card creation. If snow cli succeeds, Metabase will succeed.**

### Workflow: Create a New Card

#### Step 0: Validate SQL with snow cli (MANDATORY)

**Before any card creation, test the SQL:**

```bash
snow sql --query "SELECT * FROM prod_db.dbt_core.core_dim_users WHERE is_active = true LIMIT 100" --format JSON
```

**Confirm:**
- Query executes successfully
- Results are correct
- No permission errors

**If validation fails, DO NOT proceed to card creation. Fix SQL first.**

#### Step 1: Find User's Personal Collection ID

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

#### Step 2: Create the Card

**Required fields:**
- `name`: Card title
- `dataset_query`: Query structure with SQL
- `database_id`: Database ID (typically `1`)
- `collection_id`: Personal collection ID from Step 1
- `display`: Visualization type (`"table"`, `"bar"`, `"line"`, etc.)
- `visualization_settings`: Empty object `{}`

**Example: Create a card with native SQL query**

```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Analysis",
    "dataset_query": {
      "type": "native",
      "native": {
        "query": "SELECT * FROM prod_db.dbt_core.core_dim_users LIMIT 100",
        "template-tags": {}
      },
      "database": 1
    },
    "display": "table",
    "visualization_settings": {},
    "collection_id": 123,
    "description": "Analysis created via API"
  }' | jq '{id, name, collection_id}'
```

**Response:**
```json
{
  "id": 45678,
  "name": "My Analysis",
  "collection_id": 123
}
```

#### Step 3: Return Card URL

Construct and display the URL:
```
https://metabase-prod.ds.carta.rocks/question/45678
```

### Card Creation User Flow

**User provides:**
- Card name (e.g., "Revenue Analysis")
- SQL query (e.g., "SELECT * FROM prod_db.dbt_core.revenue LIMIT 10")
- Optional: description, visualization type

**Claude executes:**
1. **VALIDATE SQL with snow cli first** (MANDATORY)
   ```bash
   snow sql --query "USER_PROVIDED_SQL" --format JSON
   ```
2. Only if validation succeeds:
3. Get session token via Playwright MCP
4. Find personal collection ID (cache it for session)
5. Create card with POST /api/card
6. Return shareable URL

**If Step 1 fails, STOP and ask user to fix SQL. Do not proceed to card creation.**

**Example prompts:**
- "Create a Metabase card called 'Daily Active Users' with this SQL: SELECT ..."
- "Make a new question for revenue analysis: SELECT ..."
- "Add a card to my personal collection with the query: ..."

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
