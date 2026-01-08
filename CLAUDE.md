# Klajdi's AGENTS.md Global Rulesfile

This file should follow the formatting conventions used in [Claude Code's internal system prompt](https://minusx.ai/blog/decoding-claude-code/#appendix).

# Git Commit Workflow
Use the Bash tool for ALL git-related tasks. This workflow MUST be followed for all code changes.

---

### **IMPORTANT: Foundational Rules**
- You MUST NEVER commit directly to `main` or `master` branches unless explicitly asked to do so.
- Before starting, you MUST look for an associated Jira ticket in the prompt and use `acli jira workitem view [TICKET-ID]` to understand the context.

---

## 1. Branching
All work MUST be done on a new feature branch. The branch name MUST follow this exact convention: `kz/{lowercase-jira-ticket}/{kebab-case-description}`. The `kz` prefix stands for "Klajdi Ziaj".

<example>
git switch -c kz/da-3780/create-snowflake-us-west-tf-workspace
</example>

---

## 2. Committing Changes
All commit messages MUST be prefixed with the Jira ticket ID in brackets. After committing your changes with a descriptive message, you MUST push the branch to the remote origin.
Before committing, you MUST run the changes locally to ensure they work correctly. For dbt projects, this means running `dbt run --models <model_names>` or similar commands. Take a screenshot of the successful run output and include it in the PR description as proof that the changes work locally.

<example>
git commit -m "[DA-3780] Create Snowflake us-west Terraform workspace"
git push -u origin kz/da-3780/create-snowflake-us-west-tf-workspace
</example>

---

## 3. Creating a Pull Request
Use the `gh` command to open all pull requests.

**Labels**: You MUST apply one of the following labels to every pull request. Choose the label that best describes the change.
- `cc-config changes`: Configuration change to an existing feature or resource.
- `cc-documentation`: Adding documentation.
- `cc-product-development`: New work or iteration on features.

**Template**: If a pull request template exists in the repository, you MUST use it to fill out the description.

<example>
gh pr create --title "[DA-3780] Create Snowflake us-west Terraform workspace" --body "..." --label "cc-product-development"
</example>

---

## 4. Preparing for Review
After creating the pull request, you MUST copy a formatted link to your clipboard using `pbcopy` to request a review in Slack. The format depends on the repository.

<example>
# For carta/ds-airflow
echo ":airflow: [DA-3815] Create chorus.ai transcripts DAG https://github.com/carta/ds-airflow/pull/2342" | pbcopy

# For carta/ds-dbt
echo ":dbt: [DE-3876] Fix firms enabled model feature flag https://github.com/carta/ds-dbt/pull/8584" | pbcopy

# For carta/terraform
echo ":terraform-party: [DA-3803] Add additional ip lists to default Snowflake network policy https://github.com/carta/terraform/pull/9690" | pbcopy
</example>

# Jira Ticket Tool
Use the `acli` command via the Bash tool for ALL Jira-related tasks. A Jira ticket is synonymous with a `workitem`.

---

## Creating a workitem
When the user asks you to create a Jira ticket, you MUST use the `acli jira workitem create` command.

**IMPORTANT**: Always populate the summary, project, and type. Unless a different project is specified, you MUST default to the `DA` project. Use the user's request to fill in the description and assignee.

<example>
acli jira workitem create --summary "New Task" --project "DA" --type "Task" --description "Detailed description from user..." --assignee "@me"
</example>

---

## Viewing a workitem
When a Jira ticket ID (e.g., `DA-1234` or `DE-5678`) is referenced, ALWAYS use the `acli jira workitem view` command to get additional context.

<example>
acli jira workitem view DE-3858
</example>

---

## Searching for my workitems
When the user asks for their tickets, you MUST use the `acli jira workitem search` command with a JQL query.

**IMPORTANT**: Your query must follow these rules:
1. Filter for the user's primary projects: `DA` (Data Engineering) and `DE` (Dev Ecosystem).
2. Filter for the assignee: `Klajdi Ziaj`.
3. Filter out completed or inactive statuses: `Done` and `Backlog`.

<example>
acli jira workitem search --jql "project IN ('DA', 'DE') AND assignee='Klajdi Ziaj' AND status NOT IN (Done, Backlog)"
</example>

---

## Managing Placeholder Tickets (DA-TBD)

When creating PRs during exploratory work, you may use placeholder ticket IDs like `DA-TBD-1`, `DA-TBD-2`. These MUST be replaced with real Jira tickets before merging.

**Workflow:**
1. After completing work, create real Jira ticket with full context
2. Update PR title with real ticket ID using `gh pr edit`

<example>
# Create Jira ticket with PR context
acli jira workitem create \
  --summary "Create verified corporation ARR models" \
  --project "DA" \
  --type "Task" \
  --description "Full description including PR link, changes made, and impact..." \
  --assignee "@me"

# Returns: DA-4135

# Update PR title
gh pr edit 9107 --title "[DA-4135] Create verified corporation ARR models"
</example>

---

## Jira Ticket Configuration

- **Jira tickets**: When the user asks about tickets, issues, or Jira-related tasks, use the `jira-ticket` skill
  - My Jira Projects
    1. Data Engineering (default project)
        * Project Key: DA
        * Board Id: 618
  - Variables
    1. JIRA_ASSIGNEE_NAME=Klajdi Ziaj

# Snowflake Data Warehouse Query Tool
Use the `snow` command via the Bash tool for ALL Snowflake-related queries.

---

### **IMPORTANT: Query Constraints**
- You MUST ONLY write `SELECT` statements. ALL other statement types (e.g., `INSERT`, `UPDATE`, `DELETE`, `CREATE`) are strictly forbidden.
- You MUST ALWAYS format the output as JSON by including the `--format JSON` flag in your command.

---

## Querying for Specific Data
When the user asks to find specific records, construct a `SELECT` statement with an appropriate `WHERE` clause.

<example>
# "Find a firm with id 648da6cb-f2d1-4980-a1d4-f0908d1bc9b9"
snow sql --query "select * from dbt_core.fundadmin_firm where id = '648da6cb-f2d1-4980-a1d4-f0908d1bc9b9';" --format JSON
</example>

---

## Querying Schema Metadata
When the user asks to find tables or other schema information, you MUST query the `information_schema`.

<example>
# "Find the fund table in the dbt_core schema"
snow sql --query "SELECT * FROM PROD_DB.information_schema.tables WHERE table_schema ILIKE 'dbt_core' AND table_name ILIKE '%firm%';" --format JSON
</example>

---
---

# Slack Tool
Use the `curl` command via the Bash tool to interact with the Slack Web API, acting as the "Databot2" app.

---

### **IMPORTANT: Authentication**
- ALL API requests MUST be authenticated. You MUST include the authorization header `-H "Authorization: Bearer $SLACK_TOKEN"` in every `curl` command.

---

## Reading a Slack Thread
When given a Slack URL, you MUST parse the channel (token immediately following `/archives/`) and the timestamp (`ts` prefixed with a `p`) to query the `conversations.replies` endpoint.

<example>
# User provides URL: https://eshares.slack.com/archives/C04L5QG5PHQ/p1756996268859839
curl -H "Authorization: Bearer $SLACK_TOKEN" "https://slack.com/api/conversations.replies?channel=C04L5QG5PHQ&ts=1756996268.859839"
</example>

---

## Reading Channel History
When asked for the latest messages in a channel, you MUST use the `conversations.history` endpoint. You should include a `limit` to avoid fetching excessive data.

<example>
# "Get the latest messages in channel C04L5QG5PHQ"
curl -H "Authorization: Bearer $SLACK_TOKEN" "https://slack.com/api/conversations.history?channel=C04L5QG5PHQ&limit=5&inclusive=true"
</example>


# Metabase Tool
Use the `metabase-api` skill via the skill() function for ALL Metabase-related tasks.

---

### **IMPORTANT: Authentication**
- The skill automatically retrieves your Metabase session token using Playwright MCP and Island browser
- You MUST have Island browser open with an active Metabase session
- No manual token extraction is required

---

## Querying Existing Questions

When the user provides a Metabase question URL or asks to query a question:

<example>
# User provides URL: https://metabase-prod.ds.carta.rocks/question/16232
skill(metabase-api) https://metabase-prod.ds.carta.rocks/question/16232
</example>

The skill will:
1. Extract the card ID from the URL
2. Retrieve your session token via Playwright MCP
3. Execute the query and show results summary
4. Prompt for next steps (export CSV/JSON, analyze, etc.)

---

## Creating New Cards

**IMPORTANT: Always Prefer GUI Questions Over SQL Queries**

Create GUI questions (MBQL) by default - they enable seamless drill-down functionality. Only fall back to SQL when absolutely necessary.

**⚠️ CRITICAL: Validate Data Access with snow cli First**

Before creating ANY Metabase card, you MUST validate table access:

```bash
snow sql --query "SELECT * FROM prod_db.dbt_verified_core.your_table LIMIT 10" --format JSON
```

**Why this is MANDATORY:**
- Validates table access and Snowflake permissions
- Confirms table and column names are correct
- Ensures data availability
- Prevents creating broken cards in Metabase

**RULE: If snow cli fails, STOP and ask user to fix table/column names. Do not proceed to card creation.**

---

### Creating GUI Questions (PREFERRED)

**Use the `metabase-create-card` command for streamlined card creation:**

<example>
# "Create a bar chart showing MoM distinct approved zip requests"
User: Create a Metabase bar chart: MoM distinct zip requests by status

Assistant will:
1. Validate data access with snow cli (MANDATORY)
2. Use metabase-create-card command with appropriate options
3. Command handles session token, ID lookups, and caching automatically
4. Return shareable Metabase URL

Command used:
metabase-create-card \
  --name "MoM Distinct Zip Requests by Status" \
  --table CORE_FCT_ZIP_REQUESTS \
  --agg-type distinct \
  --agg-field REQUEST_ID \
  --breakout REQUEST_CREATED_AT,REQUEST_STATUS_NAME \
  --temporal-unit month \
  --display bar \
  --stacked
</example>

**Use GUI questions for:**
- ✅ Simple aggregations: count, sum, distinct, avg
- ✅ Group by date/category
- ✅ Simple filters: equals, greater than, less than
- ✅ Single table queries

**Streamlined Workflow (with helper command):**
1. **VALIDATE data access with snow cli first** (MANDATORY)
2. Run `metabase-create-card` with appropriate flags
3. Script handles: session token, collection ID, table IDs, field IDs, caching
4. Return shareable Metabase URL

**Manual Workflow (if command unavailable):**
1. **VALIDATE data access with snow cli first** (MANDATORY)
2. Retrieve session token via Playwright MCP
3. Find personal collection ID: "Klajdi Ziaj's Personal Collection"
4. Look up table ID from database metadata
5. Look up field IDs for columns needed
6. Create card with MBQL query structure
7. Return shareable Metabase URL

---

### Fallback to SQL Queries (ONLY WHEN NEEDED)

**Only create SQL cards when GUI cannot express the query:**
- Complex JOINs with aliases or multiple tables
- CTEs (WITH clauses) or subqueries
- Window functions (ROW_NUMBER, LAG, LEAD, etc.)
- Custom SQL expressions not supported by MBQL
- UNION or other set operations

<example>
# User explicitly provides SQL with CTE
User: Create a Metabase card with this SQL: WITH base AS (SELECT...) SELECT * FROM base

Assistant will:
1. Validate SQL with snow cli
2. Create SQL card (native query)
3. Return URL
(Note: SQL cards have limited drill-down capabilities)
</example>

**Default Settings:**
- **Collection**: "Klajdi Ziaj's Personal Collection" (automatically found)
- **Database**: `1` (main Snowflake PROD_DB)
- **Display Type**: Match user's request (`bar`, `line`, `table`, etc.)

**Available Display Types:**
- `bar`: Bar chart (great for categories and time series)
- `line`: Line chart (best for trends over time)
- `table`: Standard table view
- `pie`: Pie chart
- `scalar`: Single number
- `row`: Row chart

---

## Exporting Data

The skill supports exporting query results to:
- **CSV**: `/tmp/<card_name>.csv`
- **JSON**: `/tmp/<card_name>.json`

After querying a card, the skill will prompt for export options.

---

# Looker BI Migration Tool

Use the looker-migration skill and commands for migrating Looker views from scratch to verified schemas.

---

### **IMPORTANT: Migration Process**
- ALWAYS generate column mappings FIRST before starting migration
- Process one directory at a time (not entire repo)
- Validate schema compatibility before changing sql_table_name

---

## Available Commands

### compare-table-schemas
Compare column schemas between scratch and verified Snowflake tables.

<example>
compare-table-schemas dbt_core.core_fct_zuora_arr dbt_verified_core.core_historical_zuora_arr
</example>

### scan-looker-references
Scan Looker directory for scratch schema references.

<example>
scan-looker-references --dir revenue/ --schemas dbt_core,dbt_mart
</example>

### validate-lookml-fields
Validate that LookML field references exist in target Snowflake table.

<example>
validate-lookml-fields --lookml revenue/zuora_arr.view.lkml --table dbt_verified_core.core_historical_zuora_arr
</example>

---

## Migration Workflow

For complete workflow documentation, see:
- **Skill Document:** ~/.claude/skills/looker-migration/SKILL.md
- **Quick Reference:** ~/.claude/workflows/looker-bi-migration.md
- **Example PR:** DA-4203 (PR #1537)

**Key Steps:**
1. Generate column mappings for all table pairs
2. Scan one directory at a time
3. Validate schema compatibility file by file
4. Migrate and commit directory
5. Repeat for next directory

---

### Process for Migrating LookML to Snowflake Cortex Analyst

Please follow the following steps when I ask you to translate LookML code to Snowflake Cortex Analyst YAML

1. Read the LookML model file and the LookML view files in the specified directory. All tables in the LookML model file should have a corresponding LookML view file. Be sure to include all the columns from the LookML view file in the yaml.

1. CRITICAL: Read the Snowflake documentation carefully, especially the primary key format and relationship specifications. Do not assume formats - follow the documented YAML structure exactly.
  1. Here is the Snowflake documentation: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec
  1. Here is the specific section for the YAML format: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec#yaml-format
  1. Here is addditional detailed specifications: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec#specification

1. When creating the YAML, pay attention to the following:
  1. The database is PROD_DB. 
  1. RELATIONSHIPS: relationship_type can be one_to_one or many_to_one. Any one_to_many relationships in the LookML should be adjusted appropriately. The default join type in LookML is left_outer.
  1. PRIMARY KEYS: For each table, identify LookML dimensions marked with `primary_key: yes` and define them in a `primary_key` section with a `columns` list. If no primary key is defined for a table, do not include the primary_key section.
  1. VERIFIED QUERIES: Only include queries in the LookML model as verified queries. Do not add any other queries. You can reword the description from the LookML into a question if needed.

1. Output the full yaml to a file. Call the file cortex_<name_of_lookml_model>.yaml.
    e.g. If the LookML model file is sent_email.model.lkml, the file should be called cortex_sent_email.yaml

# dbt Model Migration Best Practices

When migrating or refactoring multiple dbt models in ds-dbt repository:

## 1. Consider Using dbt-refactor-agent for Bulk Changes

For systematic changes affecting **5+ models**, use the dbt-refactor-agent:
- The agent analyzes models, identifies compliance issues, fixes code structure, adds tests/documentation
- Use: `Task tool with subagent_type: dbt-refactor-agent`
- This prevents iterative fix cycles by catching issues upfront

## 2. Validate Locally BEFORE Pushing

**ALWAYS run these commands before pushing:**

```bash
# Check all models have descriptions (REQUIRED by pre-commit)
poetry run pre-commit run check-model-has-description --all-files

# Verify models compile without errors
poetry run dbt parse

# Check for required tests
poetry run pre-commit run check-model-has-tests-by-name --all-files

# Validate timestamp naming (base models only)
validate-timestamp-naming --directory models/models_verified/base
```

## 3. Check All Downstream References

When renaming models, find all references that need updating:

```bash
# Find all references to a model
grep -r "ref('old_model_name')" models/
```

## 4. Ensure YAML Files Match SQL Files

**Critical requirements:**
- Every `.sql` file needs a corresponding `.yml` file
- The `name:` field in YAML must match the SQL filename
- All models MUST have a `description:` field (required by pre-commit hooks)

**Example YAML structure:**
```yaml
models:
  - name: model_name
    description: 'Brief description of what this model does'
    columns:
      - name: column_name
        description: ''
```

## 5. Systematic Approach for Bulk Changes

- Use `grep` to identify patterns
- Use `sed` or scripts for bulk replacements
- Commit changes in logical groups (e.g., "rename YAMLs", "add descriptions", "update refs")
- Validate after each commit group

## Common Issues This Prevents

- ❌ Missing model descriptions causing pre-commit failures
- ❌ Broken references after renaming models
- ❌ YAML files not matching SQL filenames
- ❌ Compilation errors from incorrect `ref()` calls

## 6. Run CI Checks Locally Before Pushing

**ALWAYS run these CI checks before pushing verified model changes:**

```bash
# Critical: Check verified models don't reference scratch models
poetry run python ./scripts/verified_models_reference_check.py --files models/models_verified/path/to/model.sql

# Run for all changed verified models:
poetry run python ./scripts/verified_models_reference_check.py --files $(git diff --name-only main | grep "models_verified.*\\.sql$" | tr '\\n' ' ')
```

**Why this matters:** The `check-verified-model-references` CI check will fail if ANY verified model references a scratch model. Running this locally catches violations before pushing.

**Common violations:**
- Verified model references `core_fct_subscription_arr_scratch` instead of `transform_temporal_corporations_subscription_arr`
- Verified model references `base_google_sheets_arr_manual_override_scratch` instead of `base_google_sheets_arr_manual_override`

**Fix:** Update the `ref()` calls in your verified models to reference only verified models or sources.

## 7. Verified Model Development Workflow

**CRITICAL:** Before committing models to `models_verified/`, run a comprehensive validation workflow to catch issues before CI.

### Quick Validation Commands

Use these new commands to validate verified models:

```bash
# 1. Check syntax, style, and YAML compliance
validate-verified-standards

# 2. Check layer dependencies (mart → core only, etc.)
validate-layer-dependencies

# 3. Check verified models don't reference scratch models
check-verified-references

# 4. All checks at once (fast track)
validate-verified-standards && validate-layer-dependencies && check-verified-references && poetry run dbt parse
```

### Layer Dependency Rules

**CRITICAL:** These rules are enforced by `validate-layer-dependencies`:

- **Mart models** → MUST only reference **core** models (never transform, never other marts)
- **Core models** → Can reference transform or base (never mart)
- **Transform models** → Can reference base or other transform (never core/mart)
- **Base models** → Only reference sources

**Example violations:**
```sql
-- ❌ WRONG: Mart references transform
SELECT * FROM {{ ref('transform_temporal_zuora_arr') }}

-- ✅ CORRECT: Mart references core
SELECT * FROM {{ ref('core_historical_zuora_arr') }}
```

### Complete Pre-Commit Checklist

For a comprehensive workflow with troubleshooting, see: `~/.claude/skills/verified-pre-commit/SKILL.md`

**Summary:**
1. Syntax & style validation (`validate-verified-standards`)
2. Layer dependency validation (`validate-layer-dependencies`)
3. Verified reference validation (`check-verified-references`)
4. Pre-commit hooks (descriptions, tests)
5. Compilation & build test (`dbt parse`, `dbt build`)
6. Data validation (if migrating from scratch)

**Time investment:** 10-20 minutes of validation saves 1-2 hours of CI failures and rework.

## 8. Manual Migration When Commands Fail

If `migrate-model-to-scratch` fails, use manual approach:

**Step 1: Rename with git mv**
```bash
git mv models/models_scratch/path/old_model.sql models/models_scratch/path/old_model_scratch.sql
```

**Step 2: Add alias to preserve table name**
Edit the file and update config block:
```sql
{{
  config(
    alias='old_model',  -- Add this line
    materialized='table'
  )
}}
```

**Step 3: Create verified version**
Create new file in `models/models_verified/` with:
- Clean production name (no _scratch suffix)
- Explicit column lists (no SELECT *)
- Proper config for layer

**Step 4: Update downstream refs**
```bash
# Find all references
grep -r "ref('old_model')" models/

# Update scratch models to reference _scratch version
# Update verified models to reference verified version
```

**Step 5: Validate**
```bash
# Compile to check syntax
poetry run dbt parse

# Run CI check for verified models
poetry run python ./scripts/verified_models_reference_check.py --files models/models_verified/path/to/new_model.sql
```

---

## Session Context / Resume Work

To save your work state before restarting Claude:
```
"Save our current session state to session-context/ - we're working on [description]"
```

To resume after restart:
```
"Read the latest session context file and continue where we left off"
```

See `~/.claude/session-context/README.md` for full documentation and examples.

