# Metabase Claude Code Plugin

This plugin provides two capabilities:
1. **sql-to-metabase URL Generator**: Generate shareable Metabase URLs from SQL queries
2. **metabase-api API Query**: Work directly with the Metabase API in Claude Code

## ⚠️ CRITICAL: SQL Validation Required

**MANDATORY: Before creating or updating any Metabase card, you MUST validate the SQL query using:**

```bash
snow sql --query "YOUR_SQL_HERE" --format JSON
```

**Why this is required:**
- ✅ Catches syntax errors before card creation
- ✅ Validates table access and Snowflake permissions
- ✅ Ensures query performance is acceptable
- ✅ Prevents creating broken/failing cards in Metabase

**Rule: If snow cli fails, DO NOT create the card. Fix SQL first.**

---

## Prerequisites

### Playwright MCP Extension Setup (Required for API Query)

To automatically retrieve Metabase session cookies, you need to install the Playwright MCP extension in Island browser.

#### Step 1: Download the Extension

1. Go to the [Playwright MCP Releases page](https://github.com/microsoft/playwright-mcp/releases)
2. Download the latest Chrome extension (`.zip` file)
3. Extract the `.zip` file to a directory on your machine

#### Step 2: Load Extension in Island

1. Open Island browser
2. Navigate to `chrome://extensions/`
3. Enable **"Developer mode"** (toggle in the top right corner)
4. Click **"Load unpacked"**
5. Select the extracted extension directory
6. You should see a **Playwright MCP Extension Token** appear in your browser

#### Step 3: Copy the Extension Token

Copy the `PLAYWRIGHT_MCP_EXTENSION_TOKEN` value that appears in Island browser after loading the extension.

#### Step 4: Update Claude Code Configuration

You need to add the Playwright MCP server to your `~/.claude.json` configuration file.

1. Open `~/.claude.json` in a text editor
2. Find the `mcpServers` section (or create it if it doesn't exist)
3. Add the following configuration, **replacing the placeholder token with your actual token**:

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
        "PLAYWRIGHT_MCP_EXTENSION_TOKEN": "YOUR_TOKEN_HERE"
      }
    }
  }
}
```

**Important:** Replace `YOUR_TOKEN_HERE` with the token you copied from Island browser in Step 3.

#### Step 5: Restart Claude Code

After updating the configuration:
1. Quit Claude Code completely
2. Restart Claude Code
3. The Playwright MCP server should now be available

You can verify by asking Claude Code to use the Playwright MCP tools to retrieve your Metabase session cookie.

## Full Documentation

For complete Playwright MCP extension documentation, see:
https://github.com/microsoft/playwright-mcp/blob/main/extension/README.md

## Usage

Once configured, the skill can:
- Automatically retrieve Metabase session cookies via Playwright MCP
- Fall back to manual cookie retrieval if needed
- Query Metabase Cards, Collections, and Dashboards
- Export results to CSV or JSON

See `SKILL.md` for detailed usage instructions.
