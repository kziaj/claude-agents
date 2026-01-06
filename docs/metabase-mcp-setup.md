# Metabase API MCP Integration Setup Guide

**Complete guide for setting up Metabase API integration with Claude Code using Playwright MCP**

Version: 1.0  
Last Updated: 2025-12-17  
Author: Klajdi Ziaj

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Installation Steps](#installation-steps)
5. [Skill Configuration](#skill-configuration)
6. [Usage Guide](#usage-guide)
7. [API Reference](#api-reference)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)
10. [Appendix](#appendix)

---

## Overview

### What This Enables

This integration allows Claude Code to interact with Metabase programmatically via:
- **Querying existing questions**: Execute Metabase queries and retrieve results
- **Creating new cards**: Generate Metabase questions from SQL queries
- **Exporting data**: Export results to CSV or JSON
- **Managing collections**: Work with personal and team collections
- **Automatic authentication**: No manual token management required

### Components

1. **metabase-api skill**: Claude Code skill that defines Metabase workflows
2. **Playwright MCP extension**: Browser extension that captures session cookies
3. **Playwright MCP server**: MCP server that controls Island browser
4. **Island browser**: Chromium-based browser where Metabase sessions live

### Why Playwright MCP?

Metabase doesn't have:
- Command-line interface (CLI)
- Long-lived API keys that respect Snowflake access controls

Group API keys would bypass Snowflake's row-level security. Using Playwright MCP allows Claude to use **your personal session**, respecting all access controls.

---

## Prerequisites

### Required Software

- **Claude Code**: Latest version with MCP support
- **Island browser**: Installed at `/Applications/Island.app/`
- **Node.js**: For running `npx` commands (bundled with Claude Code)
- **Active Metabase account**: With access to https://metabase-prod.ds.carta.rocks

### Required Access

- Metabase account with ability to:
  - Query existing questions
  - Create new cards
  - Access personal collection
- Snowflake database access (enforced via Metabase)

### System Requirements

- macOS (tested on Darwin 24.6.0)
- Write access to `~/.claude/` directory
- Network access to:
  - metabase-prod.ds.carta.rocks
  - npm registry (for Playwright MCP)
  - GitHub (for extension download)

---

## Architecture

```
┌─────────────────┐
│  Claude Code    │
│                 │
│  ┌───────────┐  │
│  │metabase-  │  │
│  │api skill  │  │
│  └─────┬─────┘  │
│        │        │
└────────┼────────┘
         │
         │ MCP Protocol
         │
┌────────▼────────┐
│ Playwright MCP  │
│    Server       │
└────────┬────────┘
         │
         │ Browser Control
         │
┌────────▼────────┐        ┌─────────────┐
│ Island Browser  │───────▶│  Metabase   │
│ (with Extension)│  HTTPS │    API      │
└─────────────────┘        └─────────────┘
         │
         │ Session Cookie
         │
    metabase.SESSION
```

### Flow

1. User prompts Claude: "Query Metabase question 16232"
2. Claude invokes `metabase-api` skill
3. Skill calls Playwright MCP to get session cookie from Island browser
4. Playwright MCP extension extracts `metabase.SESSION` cookie
5. Skill uses cookie to authenticate API requests to Metabase
6. Results returned to Claude, formatted for user

---

## Installation Steps

### Step 1: Install metabase-api Skill

**Location**: `~/.claude/skills/metabase-api/`

**Download the skill files:**

Option A: If you have the skill ZIP file:
```bash
unzip metabase-api.zip -d /tmp/
cp -r /tmp/metabase-api ~/.claude/skills/metabase-api
```

Option B: If you have the skill from claude-marketplace PR #54:
```bash
cd ~/claude-marketplace
gh pr checkout 54
cp -r plugins/metabase/skills/metabase-api ~/.claude/skills/metabase-api
```

**Verify installation:**
```bash
ls -la ~/.claude/skills/metabase-api/
# Should show:
# README.md
# SKILL.md
```

**File structure:**
```
~/.claude/skills/metabase-api/
├── README.md          # Setup instructions for Playwright MCP
└── SKILL.md           # Skill definition with workflows
```

---

### Step 2: Download Playwright MCP Extension

**Extension location**: `~/playwright-mcp-extension/`

**Download from GitHub releases:**
```bash
cd ~/Downloads
gh release download v0.0.52 \
  --repo microsoft/playwright-mcp \
  --pattern "playwright-mcp-extension-*.zip"
```

**Extract to permanent location:**
```bash
mkdir -p ~/playwright-mcp-extension
unzip -o playwright-mcp-extension-0.0.52.zip -d ~/playwright-mcp-extension/
```

**Verify extraction:**
```bash
ls -la ~/playwright-mcp-extension/
# Should show:
# manifest.json
# connect.html
# status.html
# icons/
# lib/
```

**Alternative: Latest version**
```bash
# Check for newer releases
gh release list --repo microsoft/playwright-mcp --limit 5

# Download latest (replace version number)
gh release download vX.X.XX \
  --repo microsoft/playwright-mcp \
  --pattern "playwright-mcp-extension-*.zip"
```

---

### Step 3: Load Extension in Island Browser

**1. Open Island browser**
```bash
open -a Island
```

**2. Navigate to extensions page**
Type in address bar:
```
chrome://extensions/
```

**3. Enable Developer Mode**
- Look for toggle in **top right corner**
- Switch it **ON**
- Should say "Developer mode"

**4. Load unpacked extension**
- Click **"Load unpacked"** button
- Navigate to: `/Users/$(whoami)/playwright-mcp-extension/`
- Click **"Select"**

**5. Verify extension loaded**
You should see:
```
Playwright MCP Bridge 0.0.52
Share browser tabs with Playwright MCP server
ID: jakfalbnbhgkpmoaakfflhflbfpkailf
```

**6. Handle safety warning**
If you see "Safety Check - Review 1 extension that may be unsafe":
- Click **"Keep"** or dismiss the warning
- Keep Developer mode **ON** (required for unpacked extensions)
- Extension is safe - it's from Microsoft's official repository

**7. Get the extension token**

Option A: Click extension icon
- Look for Playwright icon in browser toolbar (top right)
- Click the icon
- You'll see a page showing: `PLAYWRIGHT_MCP_EXTENSION_TOKEN=<long-token-string>`

Option B: Direct URL
- Open new tab in Island browser
- Paste this URL:
  ```
  chrome-extension://jakfalbnbhgkpmoaakfflhflbfpkailf/status.html
  ```
- You'll see: `PLAYWRIGHT_MCP_EXTENSION_TOKEN=<long-token-string>`

**8. Copy the token**
Copy the **entire token string** after the `=` sign. Example:
```
mSwUBYtepyxBwJdl6KxwxIDDdLppK85kX7djXMBnZtM
```

Save this token - you'll need it in Step 4.

---

### Step 4: Configure Playwright MCP in Claude Code

**Configuration file**: `~/.claude.json`

**Add Playwright MCP server to your configuration:**

```bash
python3 << 'EOF'
import json
import os

config_path = os.path.expanduser('~/.claude.json')

# Read current config
with open(config_path, 'r') as f:
    data = json.load(f)

# Add playwright MCP server
data['mcpServers']['playwright'] = {
    "type": "stdio",
    "command": "npx",
    "args": [
        "@playwright/mcp@latest",
        "--extension",
        "--executable-path",
        "/Applications/Island.app/Contents/MacOS/Island"
    ],
    "env": {
        "PLAYWRIGHT_MCP_EXTENSION_TOKEN": "REPLACE_WITH_YOUR_TOKEN"
    }
}

# Write back atomically
temp_path = config_path + '.tmp'
with open(temp_path, 'w') as f:
    json.dump(data, f, indent=2)

os.replace(temp_path, config_path)
print("✓ Playwright MCP server added to ~/.claude.json")
EOF
```

**⚠️ IMPORTANT**: Replace `REPLACE_WITH_YOUR_TOKEN` with the actual token from Step 3.

**Manual configuration (alternative):**

1. Open `~/.claude.json` in your editor
2. Find the `"mcpServers"` section
3. Add this configuration:
```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--extension",
        "--executable-path",
        "/Applications/Island.app/Contents/MacOS/Island"
      ],
      "env": {
        "PLAYWRIGHT_MCP_EXTENSION_TOKEN": "your-token-here"
      }
    }
  }
}
```

**Verify configuration:**
```bash
python3 -c "
import json
with open('$HOME/.claude.json', 'r') as f:
    data = json.load(f)
    if 'playwright' in data['mcpServers']:
        print('✓ Playwright MCP configured')
        print('Token:', data['mcpServers']['playwright']['env']['PLAYWRIGHT_MCP_EXTENSION_TOKEN'][:20] + '...')
    else:
        print('✗ Playwright MCP not found')
"
```

---

### Step 5: Restart Claude Code

**Quit Claude Code completely:**
```bash
# Kill all Claude Code processes
pkill -f claude

# Or use Cmd+Q if in terminal
```

**Restart Claude Code:**
```bash
claude
```

**Verify MCP server is running:**
In Claude Code, type:
```
/mcp
```

You should see `playwright` in the list of MCP servers with status **Connected**.

---

## Skill Configuration

### Skill Enhancement: Card Creation

The `metabase-api` skill was enhanced to support creating cards in addition to querying.

**Enhanced capabilities:**
- ✓ Query existing questions
- ✓ **Create new cards** (NEW)
- ✓ Export data to CSV/JSON
- ✓ Find personal collection ID
- ✓ Manage collections

### SKILL.md Structure

**Location**: `~/.claude/skills/metabase-api/SKILL.md`

**Key sections:**
1. **Prerequisites**: Session token requirements
2. **API Documentation References**: Links to Metabase API docs
3. **Getting the Session Token**: Automatic via Playwright MCP
4. **Workflow**: Querying existing cards
5. **Exporting Data**: CSV and JSON export examples
6. **Creating Cards**: NEW - Complete card creation workflow
7. **Error Handling**: Both querying and creating errors

**Creating Cards section** includes:
- Prerequisites (database ID, collection ID)
- Step-by-step workflow
- Finding personal collection ID
- Creating card with POST /api/card
- Required fields and JSON structure
- Display types (table, bar, line, pie, etc.)
- Parameter support for dynamic queries
- User flow examples

### CLAUDE.md Integration

**Location**: `~/.claude/CLAUDE.md`

**Section added**: "# Metabase Tool"

**Contents:**
- Authentication notes (Playwright MCP automatic)
- Querying existing questions workflow
- Creating new cards workflow
- Your personal collection: "Klajdi Ziaj's Personal Collection"
- Default settings (database ID: 1, display: table)
- Available display types
- Export options

**This ensures Claude automatically:**
- Uses the `metabase-api` skill for Metabase tasks
- Grabs session token from Island browser
- Creates cards in your personal collection by default
- Handles both query and create workflows

---

## Usage Guide

### Prerequisites for Usage

1. **Island browser must be open** with active Metabase session
2. **Playwright MCP extension must be loaded** in Island
3. **Claude Code must be running** with MCP servers connected

### Querying Existing Questions

**Example 1: Query by URL**
```
Query https://metabase-prod.ds.carta.rocks/question/16232
```

**Example 2: Query by card ID**
```
Get data from Metabase card 16232
```

**What happens:**
1. Claude extracts card ID (16232) from URL
2. Playwright MCP retrieves your `metabase.SESSION` cookie from Island
3. Claude calls `GET /api/card/16232` to get metadata
4. Claude calls `POST /api/card/16232/query` to execute query
5. Results are summarized (row count, columns, sample data)
6. Claude prompts for next steps:
   - Save as CSV
   - Save as JSON
   - Analyze further
   - Something else

**Export to CSV:**
```
Save the results as CSV
```

**Export to JSON:**
```
Export this as JSON
```

### Creating New Cards

**⚠️ MANDATORY: Validate SQL with snow cli First**

Before creating ANY Metabase card, you MUST test the SQL query:

```bash
snow sql --query "YOUR_SQL_HERE" --format JSON
```

**Why this is CRITICAL:**
- ✅ Catches syntax errors before card creation
- ✅ Validates table access and Snowflake permissions
- ✅ Ensures query performance is acceptable
- ✅ Prevents creating broken/failing cards in Metabase
- ✅ Respects row-level security

**RULE: If snow cli fails, STOP. Fix SQL before creating card.**

---

**Example 1: Simple card creation WITH validation**
```
First validate:
snow sql --query "SELECT * FROM prod_db.dbt_core.core_dim_users WHERE is_active = true LIMIT 100" --format JSON

Then create the card:
Create a Metabase card called "Active Users" with SQL:
SELECT * FROM prod_db.dbt_core.core_dim_users WHERE is_active = true LIMIT 100
```

**Example 2: Card with aggregation WITH validation**
```
First validate:
snow sql --query "SELECT date_trunc('month', transaction_date) as month, sum(amount) as total_revenue FROM prod_db.dbt_core.transactions GROUP BY 1 ORDER BY 1 DESC LIMIT 12" --format JSON

Then create:
Make a new Metabase question called "Monthly Revenue" with this query:
SELECT 
  date_trunc('month', transaction_date) as month,
  sum(amount) as total_revenue
FROM prod_db.dbt_core.transactions
GROUP BY 1
ORDER BY 1 DESC
LIMIT 12
```

**Example 3: Card with specific display type WITH validation**
```
First validate:
snow sql --query "SELECT product_name, sum(revenue) as total FROM prod_db.dbt_core.sales GROUP BY 1 ORDER BY 2 DESC LIMIT 10" --format JSON

Then create:
Create a bar chart in Metabase called "Revenue by Product" with SQL:
SELECT product_name, sum(revenue) as total
FROM prod_db.dbt_core.sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

Display as: bar
```

**What happens:**
1. **Claude validates SQL with snow cli FIRST** (MANDATORY)
   ```bash
   snow sql --query "SELECT * FROM ..." --format JSON
   ```
2. Only if validation succeeds:
3. Claude retrieves your session token via Playwright MCP
4. Claude calls `GET /api/collection` to find "Klajdi Ziaj's Personal Collection"
5. Claude extracts your personal collection ID (e.g., 123)
6. Claude constructs the card creation payload:
   ```json
   {
     "name": "Active Users",
     "dataset_query": {
       "type": "native",
       "native": {
         "query": "SELECT * FROM ...",
         "template-tags": {}
       },
       "database": 1
     },
     "display": "table",
     "visualization_settings": {},
     "collection_id": 123,
     "description": "Analysis created via API"
   }
   ```
7. Claude calls `POST /api/card` to create the card
8. Claude returns the shareable URL:
   ```
   Card created: https://metabase-prod.ds.carta.rocks/question/45678
   ```

**If Step 1 (validation) fails, STOP and ask user to fix SQL. Do not proceed to card creation.**

### Display Types

Available visualization types:
- **table**: Standard table view (default)
- **bar**: Bar chart
- **line**: Line chart  
- **pie**: Pie chart
- **scalar**: Single number (for metrics)
- **row**: Row chart (horizontal bars)

Specify in your prompt:
```
Create a pie chart showing...
Create a line graph of...
Show me a single number for...
```

### Working with Collections

**Find your personal collection:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/collection" | \
  jq '.[] | select(.name | contains("Klajdi")) | {id, name}'
```

**List cards in a collection:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/collection/123/items" | \
  jq '.data[] | {id, name, model}'
```

### Advanced: Parameterized Queries

**Create card with date parameter:**
```
Create a Metabase card called "Sales by Date Range" with this SQL:
SELECT * FROM prod_db.dbt_core.sales 
WHERE transaction_date > {{start_date}}

Add a date parameter called "start_date"
```

Claude will create a card with template tags:
```json
{
  "dataset_query": {
    "type": "native",
    "native": {
      "query": "SELECT * FROM prod_db.dbt_core.sales WHERE transaction_date > {{start_date}}",
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

---

## API Reference

### Metabase API Base URL
```
https://metabase-prod.ds.carta.rocks/api
```

### Authentication

All API requests require session cookie:
```bash
--cookie "metabase.SESSION=<session-token>"
```

### Common Endpoints

#### GET /api/card/:id
Get card metadata (name, SQL, columns, creator, etc.)

**Request:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/card/16232"
```

**Response:**
```json
{
  "id": 16232,
  "name": "Invoice Manager Scratchpad",
  "description": "Analysis of invoices",
  "dataset_query": {
    "type": "native",
    "native": {
      "query": "SELECT * FROM ..."
    },
    "database": 1
  },
  "display": "table",
  "collection_id": 123,
  "creator": {...}
}
```

#### POST /api/card/:id/query
Execute a card's query and get results

**Request:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card/16232/query" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Response:**
```json
{
  "data": {
    "rows": [
      ["value1", "value2", "value3"],
      ["value4", "value5", "value6"]
    ],
    "cols": [
      {"name": "column1", "display_name": "Column 1", "base_type": "type/Text"},
      {"name": "column2", "display_name": "Column 2", "base_type": "type/Integer"}
    ]
  },
  "row_count": 2,
  "status": "completed"
}
```

#### POST /api/card
Create a new card

**Request:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  -X POST "https://metabase-prod.ds.carta.rocks/api/card" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Analysis",
    "dataset_query": {
      "type": "native",
      "native": {
        "query": "SELECT * FROM prod_db.dbt_core.users LIMIT 10",
        "template-tags": {}
      },
      "database": 1
    },
    "display": "table",
    "visualization_settings": {},
    "collection_id": 123,
    "description": "User analysis"
  }'
```

**Response:**
```json
{
  "id": 45678,
  "name": "My Analysis",
  "collection_id": 123,
  "created_at": "2025-12-17T10:00:00.000Z"
}
```

#### GET /api/collection
List all collections accessible to user

**Request:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/collection"
```

**Response:**
```json
[
  {
    "id": 123,
    "name": "Klajdi Ziaj's Personal Collection",
    "slug": "klajdi_ziaj_s_personal_collection",
    "personal_owner_id": 456
  },
  {
    "id": 789,
    "name": "Team Analytics",
    "slug": "team_analytics"
  }
]
```

#### GET /api/collection/:id/items
Get items (cards, dashboards) in a collection

**Request:**
```bash
curl -s --cookie "metabase.SESSION=$SESSION" \
  "https://metabase-prod.ds.carta.rocks/api/collection/123/items"
```

**Response:**
```json
{
  "data": [
    {
      "id": 16232,
      "name": "My Question",
      "model": "card",
      "description": "Analysis"
    }
  ],
  "total": 1
}
```

### Database IDs

Common database IDs in Metabase:
- **1**: Main Snowflake PROD_DB (default)
- Check with: `GET /api/database`

### Complete API Documentation

Metabase API docs: https://www.metabase.com/docs/latest/api

Key sections:
- Cards (Questions): https://www.metabase.com/docs/latest/api#tag/apicard
- Collections: https://www.metabase.com/docs/latest/api#tag/apicollection
- Dashboards: https://www.metabase.com/docs/latest/api#tag/apidashboard

---

## Troubleshooting

### Extension Not Loading

**Symptom**: Extension doesn't appear in chrome://extensions/

**Solutions:**
1. Verify files extracted correctly:
   ```bash
   ls -la ~/playwright-mcp-extension/manifest.json
   ```
2. Ensure Developer mode is **ON** in chrome://extensions/
3. Try clicking "Load unpacked" again and select the directory
4. Check Island browser version is compatible
5. Look for errors in chrome://extensions/ (click "Errors" button)

---

### Token Not Showing

**Symptom**: Extension loaded but can't find the token

**Solutions:**
1. Click the Playwright MCP extension icon in browser toolbar
2. Try the direct URL approach:
   ```
   chrome-extension://jakfalbnbhgkpmoaakfflhflbfpkailf/status.html
   ```
3. Check if extension is enabled (toggle should be ON)
4. Reload the extension (click reload icon in chrome://extensions/)
5. Generate new token:
   - Remove extension
   - Re-add extension
   - New token will be generated

---

### MCP Server Not Connecting

**Symptom**: `/mcp` command shows playwright as "Disconnected"

**Solutions:**
1. Verify token in ~/.claude.json is correct:
   ```bash
   grep -A5 '"playwright"' ~/.claude.json
   ```
2. Check Island browser is at correct path:
   ```bash
   ls /Applications/Island.app/Contents/MacOS/Island
   ```
3. Verify npx is available:
   ```bash
   which npx
   npx --version
   ```
4. Check Playwright MCP can be installed:
   ```bash
   npx @playwright/mcp@latest --version
   ```
5. Restart Claude Code completely
6. Check Claude Code logs for MCP errors

---

### Session Token Expired

**Symptom**: API returns 401 Unauthorized

**Solutions:**
1. **Refresh Metabase session in Island browser:**
   - Open https://metabase-prod.ds.carta.rocks in Island
   - Log in again via Okta if needed
   - Claude will automatically get the new session token

2. **Manually verify session:**
   ```bash
   # In Island DevTools console:
   document.cookie.split(';').find(c => c.includes('metabase.SESSION'))
   ```

3. **Session TTL**: Metabase sessions typically last 14 days
   - Keep Island browser open with active Metabase tab
   - Refresh Metabase page periodically to keep session alive

---

### SQL Query Errors

**Symptom**: 500 Internal Server Error when creating card

**⚠️ PREVENTION: Always use snow cli FIRST (MANDATORY)**

Before creating ANY card:
```bash
snow sql --query "YOUR_SQL" --format JSON
```

**If snow cli succeeds, Metabase will succeed.**
**If snow cli fails, fix SQL before creating card.**

**Solutions:**
1. **Test SQL in Metabase UI first:**
   - Open Metabase UI
   - Create question manually with same SQL
   - Fix any syntax errors
   - Then use corrected SQL with Claude

2. **Common SQL issues:**
   - Missing schema: Use `prod_db.dbt_core.table_name`
   - Access denied: Check Snowflake permissions
   - Invalid syntax: Test in Snowflake SQL editor first

3. **Check database ID:**
   ```bash
   curl -s --cookie "metabase.SESSION=$SESSION" \
     "https://metabase-prod.ds.carta.rocks/api/database" | \
     jq '.data[] | {id, name}'
   ```

---

### Collection Not Found

**Symptom**: Can't create card - "Collection not found"

**Solutions:**
1. **Find your personal collection ID:**
   ```bash
   curl -s --cookie "metabase.SESSION=$SESSION" \
     "https://metabase-prod.ds.carta.rocks/api/collection" | \
     jq '.[] | select(.personal_owner_id != null) | {id, name}'
   ```

2. **Verify collection access:**
   - Open Metabase UI
   - Navigate to "Your personal collection"
   - Check you can create questions there

3. **Use correct collection ID format:**
   - Must be integer (e.g., 123)
   - Not string (e.g., "123")
   - Not collection slug

---

### Playwright MCP Browser Issues

**Symptom**: Playwright MCP can't control Island browser

**Solutions:**
1. **Verify extension token matches config:**
   - Check token in Island browser (status.html)
   - Check token in ~/.claude.json
   - They must match exactly

2. **Check browser path:**
   ```bash
   # Should exist and be executable
   ls -l /Applications/Island.app/Contents/MacOS/Island
   ```

3. **Test Playwright MCP manually:**
   ```bash
   npx @playwright/mcp@latest \
     --extension \
     --executable-path /Applications/Island.app/Contents/MacOS/Island
   ```

4. **Island browser alternatives:**
   If Island doesn't work, you can use Chrome:
   ```json
   {
     "command": "npx",
     "args": [
       "@playwright/mcp@latest",
       "--extension",
       "--executable-path",
       "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
     ]
   }
   ```

---

### Large Result Sets

**Symptom**: Query results too large, Claude truncates response

**Solutions:**
1. **Export directly to file:**
   ```
   Query card 16232 and save results to /tmp/results.csv
   ```

2. **Add LIMIT to SQL:**
   ```sql
   SELECT * FROM table LIMIT 1000
   ```

3. **Use pagination in Metabase:**
   - Create multiple cards with offset/limit
   - Query each card separately

---

### Permission Denied

**Symptom**: 403 Forbidden when accessing Metabase resources

**Solutions:**
1. **Check Metabase permissions:**
   - Open Metabase UI
   - Verify you can access the question/collection manually

2. **Snowflake access controls:**
   - Metabase enforces Snowflake row-level security
   - Your personal session respects these controls
   - If you can't see data in UI, API won't work either

3. **Collection permissions:**
   - Personal collections: Only you have access
   - Team collections: Check with collection owner
   - Organization collections: May need admin approval

---

## Maintenance

### Updating Playwright MCP Extension

**Check for updates:**
```bash
gh release list --repo microsoft/playwright-mcp --limit 5
```

**Update to latest version:**
```bash
# Download latest release
cd ~/Downloads
gh release download <VERSION> \
  --repo microsoft/playwright-mcp \
  --pattern "playwright-mcp-extension-*.zip"

# Extract to same location (overwrite)
unzip -o playwright-mcp-extension-*.zip -d ~/playwright-mcp-extension/

# Reload extension in Island browser
# 1. Go to chrome://extensions/
# 2. Click reload icon on Playwright MCP Bridge card
# 3. Get new token from status page
# 4. Update ~/.claude.json with new token
# 5. Restart Claude Code
```

---

### Rotating Extension Token

**When to rotate:**
- Security best practice: Every 90 days
- Token compromised
- Extension reinstalled

**How to rotate:**
1. Remove extension from Island browser
2. Re-add extension (same files)
3. New token will be generated automatically
4. Update ~/.claude.json with new token
5. Restart Claude Code

**Rotation script:**
```bash
# Get new token from extension
NEW_TOKEN=$(curl -s "chrome-extension://jakfalbnbhgkpmoaakfflhflbfpkailf/status.html" | grep -o 'PLAYWRIGHT_MCP_EXTENSION_TOKEN=[^"]*' | cut -d= -f2)

# Update config
python3 << EOF
import json
with open('$HOME/.claude.json', 'r') as f:
    data = json.load(f)
data['mcpServers']['playwright']['env']['PLAYWRIGHT_MCP_EXTENSION_TOKEN'] = '$NEW_TOKEN'
with open('$HOME/.claude.json', 'w') as f:
    json.dump(data, f, indent=2)
EOF

echo "✓ Token rotated. Restart Claude Code."
```

---

### Updating metabase-api Skill

**Check for skill updates:**
```bash
cd ~/claude-marketplace
git pull origin main
gh pr list --repo carta/claude-marketplace --search "metabase"
```

**Update skill files:**
```bash
# If there's a new version in PR or main branch
cp -r plugins/metabase/skills/metabase-api ~/.claude/skills/metabase-api

# Verify
cat ~/.claude/skills/metabase-api/SKILL.md | head -20
```

**Test after update:**
```bash
# In Claude Code
Query a simple Metabase question to test
```

---

### Backing Up Configuration

**Backup important files:**
```bash
# Create backup directory
mkdir -p ~/.claude-backups/$(date +%Y%m%d)

# Backup configurations
cp ~/.claude.json ~/.claude-backups/$(date +%Y%m%d)/
cp ~/.claude/CLAUDE.md ~/.claude-backups/$(date +%Y%m%d)/
cp -r ~/.claude/skills/metabase-api ~/.claude-backups/$(date +%Y%m%d)/

echo "✓ Backup created at ~/.claude-backups/$(date +%Y%m%d)/"
```

**Restore from backup:**
```bash
# Choose backup date
BACKUP_DATE="20251217"

# Restore
cp ~/.claude-backups/$BACKUP_DATE/.claude.json ~/.claude.json
cp ~/.claude-backups/$BACKUP_DATE/CLAUDE.md ~/.claude/CLAUDE.md
cp -r ~/.claude-backups/$BACKUP_DATE/metabase-api ~/.claude/skills/

echo "✓ Restored from backup $BACKUP_DATE"
```

---

### Monitoring Usage

**Track Metabase API usage:**
```bash
# Check recent Claude Code sessions that used Metabase
grep -r "metabase" ~/.claude/sessions/ | head -20

# Count Metabase queries this month
grep -r "metabase.SESSION" ~/.claude/sessions/ | wc -l
```

**Monitor MCP server health:**
```bash
# In Claude Code
/mcp

# Should show playwright as "Connected"
```

---

## Appendix

### Complete File Locations

```
~/.claude/
├── CLAUDE.md                          # Global rules (Metabase section added)
├── .claude.json                       # MCP server config (playwright added)
├── skills/
│   └── metabase-api/
│       ├── README.md                  # Playwright MCP setup instructions
│       └── SKILL.md                   # Metabase API skill definition
└── docs/
    └── metabase-mcp-setup.md          # This documentation

~/playwright-mcp-extension/            # Playwright MCP extension files
├── manifest.json
├── connect.html
├── status.html
├── icons/
└── lib/
```

---

### Environment Variables

**Optional environment variables:**

```bash
# Override Island browser path
export ISLAND_BROWSER_PATH="/Applications/Island.app/Contents/MacOS/Island"

# Claude Code API token (if using API mode)
export CLAUDE_API_KEY="your-api-key"

# Metabase base URL (if using different instance)
export METABASE_URL="https://metabase-prod.ds.carta.rocks"
```

---

### Quick Reference: All Commands

**Installation:**
```bash
# 1. Install skill
cp -r /tmp/metabase-api ~/.claude/skills/metabase-api

# 2. Download extension
gh release download v0.0.52 --repo microsoft/playwright-mcp --pattern "playwright-mcp-extension-*.zip"

# 3. Extract extension
mkdir -p ~/playwright-mcp-extension
unzip -o playwright-mcp-extension-0.0.52.zip -d ~/playwright-mcp-extension/

# 4. Load in Island browser (manual step in chrome://extensions/)

# 5. Configure MCP (replace TOKEN)
python3 << 'EOF'
import json
with open('/Users/$USER/.claude.json', 'r') as f:
    data = json.load(f)
data['mcpServers']['playwright'] = {
    "type": "stdio",
    "command": "npx",
    "args": ["@playwright/mcp@latest", "--extension", "--executable-path", "/Applications/Island.app/Contents/MacOS/Island"],
    "env": {"PLAYWRIGHT_MCP_EXTENSION_TOKEN": "TOKEN"}
}
with open('/Users/$USER/.claude.json', 'w') as f:
    json.dump(data, f, indent=2)
EOF

# 6. Restart Claude Code
pkill -f claude && claude
```

**Usage:**
```bash
# Query question
"Query https://metabase-prod.ds.carta.rocks/question/16232"

# Create card
"Create a Metabase card called 'Test' with SQL: SELECT 1"

# Export results
"Export this as CSV"
```

**Troubleshooting:**
```bash
# Check MCP status
/mcp

# Verify token
grep -A5 '"playwright"' ~/.claude.json

# Test Playwright MCP
npx @playwright/mcp@latest --version

# Check Island browser
ls /Applications/Island.app/Contents/MacOS/Island
```

---

### Prompt for Claude to Install

**Give this prompt to Claude Code to automate installation:**

```
Install the Metabase API MCP integration by following ~/.claude/docs/metabase-mcp-setup.md

Complete steps:
1. Download and install metabase-api skill
2. Download Playwright MCP extension to ~/playwright-mcp-extension/
3. Extract the extension
4. Prompt me to load it in Island browser and provide the token
5. Once I provide the token, configure ~/.claude.json
6. Add Metabase section to ~/.claude/CLAUDE.md
7. Verify all files are in place

Don't skip any steps. Prompt me for the extension token when ready.
```

---

### Support and Resources

**Documentation:**
- Metabase API: https://www.metabase.com/docs/latest/api
- Playwright MCP: https://github.com/microsoft/playwright-mcp
- Claude Code MCP: https://docs.anthropic.com/en/docs/claude-code/mcp

**Internal Resources:**
- claude-marketplace PR #54: https://github.com/carta/claude-marketplace/pull/54
- metabase-prod: https://metabase-prod.ds.carta.rocks
- This documentation: ~/.claude/docs/metabase-mcp-setup.md

**Troubleshooting:**
- Check Claude Code logs
- Review MCP server status with `/mcp`
- Test Metabase API manually with curl
- Verify Island browser session is active

---

## Changelog

### v1.0 (2025-12-17)
- Initial documentation
- Complete installation guide
- Card creation functionality
- Troubleshooting section
- Maintenance procedures

---

**End of documentation**
