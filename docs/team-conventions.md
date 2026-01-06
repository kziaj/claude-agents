# Carta Analytics Engineering - Claude Code Team Conventions

This document defines team-wide conventions for using Claude Code at Carta.

**Audience:** All Analytics Engineering team members  
**Last Updated:** January 2026  
**Status:** Official team standards

---

## Git Workflow Standards

### Branch Naming Convention

**Format:** `{initials}/{ticket-id}/{description}`

**Rules:**
- Use your initials (2-3 letters) as prefix
- Ticket ID must be lowercase
- Description must be kebab-case
- Keep descriptions short and descriptive

**Examples:**
```bash
# Good
kz/da-1234/migrate-zuora-arr
jd/de-567/add-looker-dashboard
sm/da-890/fix-subscription-model

# Bad
kz/DA-1234/migrate_zuora_arr    # Uppercase ticket, underscore
john/da-1234/this-is-a-very-long-description-that-should-be-shorter
migrate-zuora-arr               # Missing initials/ticket
```

### Commit Message Format

**Format:** `[TICKET-ID] Message`

**Rules:**
- Ticket ID in brackets, uppercase
- Message is imperative mood ("Add" not "Added")
- Be descriptive but concise
- Reference multiple tickets if needed

**Examples:**
```bash
# Good
[DA-1234] Migrate zuora ARR models to verified
[DE-567] Add primary key test to subscription model
[DA-890, DA-891] Fix duplicate handling in revenue logic

# Bad
da-1234 migrate zuora models    # Missing brackets, lowercase
[DA-1234] migrated models       # Past tense
[DA-1234] stuff                 # Not descriptive
```

### Pull Request Guidelines

**Required Elements:**
1. **Title:** Same format as commit message
2. **Label:** One of:
   - `cc-product-development` - New features/enhancements
   - `cc-config-changes` - Configuration updates
   - `cc-documentation` - Documentation only
3. **Description:** Use PR template if available
4. **Screenshot:** For dbt runs, include proof of local success

**Example:**
```bash
gh pr create \
  --title "[DA-1234] Migrate zuora ARR models to verified" \
  --label "cc-product-development" \
  --body "$(cat << 'EOF'
## Summary
- Migrated 5 zuora ARR models to verified/
- Added primary key tests
- Updated downstream references

## Testing
Ran locally:
```bash
dbt build -m +core_fct_zuora_arr+
```
[Screenshot of successful run]

## Checklist
- [x] Pre-commit hooks pass
- [x] All tests pass locally
- [x] Documentation updated
EOF
)"
```

### Slack Notification Format

After creating PR, copy notification to clipboard:

**Format varies by repository:**

```bash
# For ds-dbt
echo ":dbt: [DA-1234] Migrate zuora ARR models https://github.com/carta/ds-dbt/pull/9107" | pbcopy

# For ds-airflow
echo ":airflow: [DA-2345] Add new ETL pipeline https://github.com/carta/ds-airflow/pull/543" | pbcopy

# For terraform
echo ":terraform-party: [DA-3456] Update Snowflake config https://github.com/carta/terraform/pull/876" | pbcopy
```

---

## Jira Workflow Standards

### Default Project

**Default to DA (Data Engineering)** unless ticket is explicitly in another project:
- DA: Data warehouse work (dbt, Snowflake, data modeling)
- DE: Dev ecosystem work (tooling, infrastructure, CI/CD)

### Ticket Creation

**Required fields:**
- Summary (clear, actionable)
- Description (context, requirements, acceptance criteria)
- Assignee (usually yourself)
- Type (Task, Story, Bug, etc.)

**Example:**
```bash
acli jira workitem create \
  --summary "Migrate zuora ARR models to verified schema" \
  --project "DA" \
  --type "Task" \
  --description "Move 5 zuora ARR models from scratch to verified following team standards" \
  --assignee "@me"
```

### Ticket Search

**Standard query for "my tickets":**
```bash
acli jira workitem search --jql "project IN ('DA', 'DE') AND assignee='{Your Name}' AND status NOT IN (Done, Backlog)"
```

---

## dbt Development Standards

### Before Committing - Required Checks

**ALWAYS run these locally:**

```bash
# 1. Validate verified model standards
validate-verified-standards

# 2. Check layer dependencies
validate-layer-dependencies

# 3. Check for scratch references
check-verified-references

# 4. Run pre-commit hooks
poetry run pre-commit run --all-files

# 5. Verify compilation
poetry run dbt parse
```

### Model Migration Workflow

**For 1-3 models (manual):**
1. Create scratch version with `_scratch` suffix
2. Create verified version in proper layer
3. Validate locally
4. Create PR

**For 5+ models (use agent):**
1. Use `dbt-refactor-agent`
2. Agent handles standards compliance automatically
3. Review and validate
4. Create PR

### Naming Conventions

**Layers:**
- `base_*` - Raw source data
- `transform_*` - Business logic transformations
- `core_*` - Core dimensions and facts
- `mart_*` - Final analytics tables

**Suffixes:**
- `_scratch` - Work-in-progress, non-production
- No suffix for verified/production models

### Required Documentation

**Every model MUST have:**
- `description:` field in YAML
- Tests (at minimum: `not_null` on primary key)
- Column descriptions for important fields

---

## Snowflake Query Standards

### Query Format

**ALWAYS use:**
```bash
snow sql --query "YOUR_SQL_HERE" --format JSON
```

**Query restrictions:**
- ✅ SELECT statements only
- ❌ INSERT, UPDATE, DELETE, CREATE forbidden
- ✅ JSON output format required

### Common Patterns

**Find tables:**
```sql
SELECT * FROM PROD_DB.information_schema.tables 
WHERE table_schema ILIKE 'dbt_core' 
AND table_name ILIKE '%zuora%'
```

**Check row counts:**
```sql
SELECT COUNT(*) FROM dbt_core.core_fct_zuora_arr
```

**Compare schemas:**
```sql
SELECT column_name, data_type 
FROM PROD_DB.information_schema.columns 
WHERE table_schema = 'dbt_core' 
AND table_name = 'core_fct_zuora_arr'
ORDER BY ordinal_position
```

---

## Claude Code Usage Patterns

### When to Use Agents

**Use agents for:**
- 5+ model migrations → `dbt-refactor-agent`
- Complex dependency analysis → `model-migration-agent`
- Multiple ticket creation → `jira-ticket-agent`
- Data warehouse queries → `snowflake-agent`

**Don't use agents for:**
- Simple 1-2 model changes
- Quick queries
- Single ticket creation

### Session Context Best Practices

**Save state before:**
- End of day
- Long breaks (lunch, meetings)
- Context switches to different projects
- Complex operations

**Format:**
```
"Save our current session state to session-context/ - we're working on [brief description]"
```

**Resume:**
```
"Read the latest session context file and continue where we left off"
```

### Prompt Engineering Tips

**Good prompts:**
- ✅ "Migrate core_fct_subscription_arr to scratch naming"
- ✅ "Validate my verified models before committing"
- ✅ "Create a PR for DA-1234 with proper labels"

**Bad prompts:**
- ❌ "Do something with this model"
- ❌ "Fix it"
- ❌ "Help"

**For complex tasks:**
```
"I need to migrate 8 subscription models. Here's what I want:
1. Rename scratch versions with _scratch suffix
2. Create verified versions with explicit column lists
3. Add primary key tests
4. Run all validation checks
5. Create a PR

Use dbt-refactor-agent for this work."
```

---

## Security & Privacy

### What NEVER Goes in Version Control

**Never commit:**
- API tokens (Jira, GitHub, Slack, etc.)
- AWS credentials
- Database passwords
- Snowflake credentials
- Personal data from queries
- Session context files (already gitignored)

### Safe Practices

**✅ DO:**
- Use environment variables for credentials
- Keep `settings.local.json` for personal settings
- Use `session-context/` for private work notes
- Review `git diff` before committing
- Use `.gitignore` properly

**❌ DON'T:**
- Hardcode credentials in scripts
- Share your personal configuration files
- Commit company-sensitive data
- Push directly to main branch

---

## Maintenance Schedule

### Monthly Tasks

- [ ] Run `~/.claude/scripts/cleanup.sh`
- [ ] Archive old session context files
- [ ] Review and update team conventions
- [ ] Check for command updates (`git pull` in ~/.claude)

### Quarterly Tasks

- [ ] Delete old archived files (6+ months)
- [ ] Review custom commands for obsolescence
- [ ] Update documentation for workflow changes
- [ ] Participate in Claude Code knowledge sharing

---

## Getting Help

### Escalation Path

1. **Try Claude first** - Often can solve or explain
2. **Check documentation** - ONBOARDING.md, this doc, skill READMEs
3. **Ask in Slack** - #claude-code-users for Claude-specific, #analytics-engineering for general
4. **Office hours** - Thursdays 2-3pm PT
5. **Onboarding buddy** - First 30 days

### Common Issues

**See:** `docs/troubleshooting.md` (in this repo)

### Contributing Improvements

**To suggest changes:**
1. Open an issue in claude-agents repo
2. Discuss in #claude-code-users
3. Submit PR with your improvement
4. Tag team lead for review

---

## Version History

- **v1.0** (Jan 2026) - Initial team conventions
- Future versions will be tracked here

---

**Questions?** Ask in #claude-code-users  
**Maintainer:** Analytics Engineering Leadership  
**Feedback:** [Create an issue](https://github.com/kziaj/claude-agents/issues)
