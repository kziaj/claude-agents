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
All work MUST be done on a new feature branch. The branch name MUST follow this exact convention: `th/{lowercase-jira-ticket}/{kebab-case-description}`. The `th` prefix stands for "Klajdi Ziaj".

<example>
git switch -c th/da-3780/create-snowflake-us-west-tf-workspace
</example>

---

## 2. Committing Changes
All commit messages MUST be prefixed with the Jira ticket ID in brackets. After committing your changes with a descriptive message, you MUST push the branch to the remote origin.
Before committing, you MUST run the changes locally to ensure they work correctly. For dbt projects, this means running `dbt run --models <model_names>` or similar commands. Take a screenshot of the successful run output and include it in the PR description as proof that the changes work locally.

<example>
git commit -m "[DA-3780] Create Snowflake us-west Terraform workspace"
git push -u origin th/da-3780/create-snowflake-us-west-tf-workspace
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

---