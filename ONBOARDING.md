# Claude Code Onboarding for Carta Analytics Engineering

Welcome to the Analytics Engineering team at Carta! This guide will help you set up Claude Code to maximize your productivity with our team's established workflows and best practices.

**Time to complete:** ~2-3 hours on Day 1  
**Goal:** Have Claude Code fully configured and ready to assist with dbt, Jira, Snowflake, and Git workflows

---

## Table of Contents

- [What is Claude Code?](#what-is-claude-code)
- [Day 1: Initial Setup](#day-1-initial-setup)
- [Week 1: Core Workflows](#week-1-core-workflows)
- [Month 1: Advanced Patterns](#month-1-advanced-patterns)
- [Troubleshooting](#troubleshooting)
- [Security & Best Practices](#security--best-practices)

---

## What is Claude Code?

Claude Code is an AI-powered CLI assistant that helps with:
- **dbt development**: Writing models, tests, documentation
- **Git workflows**: Branching, committing, creating PRs
- **Jira management**: Creating tickets, tracking work
- **Snowflake queries**: Exploring data, validating changes
- **Code migrations**: Systematic refactoring with validation

At Carta, our team has built custom commands, skills, and workflows that make Claude Code even more powerful for analytics engineering work.

---

## Day 1: Initial Setup

### Prerequisites Checklist

Before starting, ensure you have access to:
- [ ] Carta GitHub organization
- [ ] Jira (carta1.atlassian.net)
- [ ] Snowflake PROD_DB
- [ ] AWS SSO (for Bedrock access)
- [ ] Slack workspace

### Step 1: Install Claude Code (15 min)

```bash
# Install Claude Code via Homebrew
brew install anthropic/tap/claude

# Verify installation
claude --version
```

**Alternative installation methods:**
- [Official Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)

### Step 2: Configure AWS Bedrock (15 min)

Claude Code at Carta uses AWS Bedrock for model access:

```bash
# Install AWS CLI if not already installed
brew install awscli

# Configure AWS SSO (use your Carta credentials)
aws configure sso --profile AmazonBedrockStandardAccess-559050237467

# Test authentication
aws sso login --profile AmazonBedrockStandardAccess-559050237467
```

**Verify Bedrock access:**
```bash
aws bedrock list-foundation-models \
  --region us-east-1 \
  --profile AmazonBedrockStandardAccess-559050237467
```

### Step 3: Install Team Tools (30 min)

Install the tools Claude Code will use:

```bash
# GitHub CLI (for PR management)
brew install gh
gh auth login
# Choose: GitHub.com → HTTPS → Yes (authenticate) → Login with browser

# Atlassian CLI (for Jira)
brew tap go-jira/jira
brew install go-jira
# Configure with your Jira credentials

# Snowflake CLI
brew tap snowflakedb/snowflake-cli
brew install snowflake-cli

# Configure Snowflake connection
snow connection add
# Connection name: default
# Account: carta.us-east-1
# Username: your.name@carta.com
# Authenticator: externalbrowser

# dbt + Poetry (for ds-dbt development)
brew install poetry
```

**Verify installations:**
```bash
gh --version
snow --version
poetry --version
```

### Step 4: Clone Carta Repositories (15 min)

```bash
# Create carta directory
mkdir -p ~/carta
cd ~/carta

# Clone dbt repository
gh repo clone carta/ds-dbt

# Clone Airflow repository (if you need it)
gh repo clone carta/ds-airflow

# Set up dbt project
cd ~/carta/ds-dbt
poetry install
```

### Step 5: Clone Team Claude Configuration (10 min)

Our team maintains a shared configuration repository with commands, skills, and workflows:

```bash
# Clone the team configuration
git clone https://github.com/kziaj/claude-agents.git ~/.claude

# Enter the directory
cd ~/.claude
```

### Step 6: Personalize Your Configuration (20 min)

Create your personal CLAUDE.md from the team template:

```bash
cd ~/.claude
cp CLAUDE.md CLAUDE.md.template  # Backup original
```

**Edit `~/.claude/CLAUDE.md`** and update these sections:

1. **Branch naming prefix** (Line ~17):
   ```markdown
   Branch naming: `{YOUR_INITIALS}/{ticket-id}/{description}`
   Example: xy/da-1234/add-revenue-model
   ```

2. **Jira assignee** (Line ~138):
   ```markdown
   JIRA_ASSIGNEE_NAME={Your Full Name}
   ```

3. **Git commit author** (optional):
   ```bash
   cd ~/.claude
   git config user.name "Your Name"
   git config user.email "your.email@carta.com"
   ```

### Step 7: Configure Environment Variables (10 min)

Add these to your `~/.zshrc` (or `~/.bashrc`):

```bash
# Open your shell config
nano ~/.zshrc

# Add these lines at the end:

# Carta repository paths
export CARTA_DBT_DIR="$HOME/carta/ds-dbt"
export CARTA_AIRFLOW_DIR="$HOME/carta/ds-airflow"
export CLAUDE_DIR="$HOME/.claude"

# AWS Bedrock for Claude Code
export AWS_PROFILE="AmazonBedrockStandardAccess-559050237467"
export AWS_REGION="us-east-1"
export CLAUDE_CODE_USE_BEDROCK="1"
export ANTHROPIC_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"

# Jira configuration
export JIRA_ASSIGNEE_NAME="Your Full Name"

# Git branch prefix (your initials)
export GIT_BRANCH_PREFIX="xy"

# Helpful dbt aliases
alias d='dbt run --defer --state artifacts/nonprod_run/ --favor-state --models'
alias ds='dbt run --defer --state artifacts/snowflake_prod_run/ --favor-state -t snowflake --models'

# Claude commands in PATH
export PATH="$HOME/.claude/commands:$PATH"

# Save and reload
source ~/.zshrc
```

### Step 8: Validate Your Setup (10 min)

Run the validation script:

```bash
~/.claude/scripts/validate-setup.sh
```

Expected output:
```
✅ Claude Code installed
✅ AWS Bedrock authenticated
✅ GitHub CLI configured
✅ Jira CLI configured
✅ Snowflake connection working
✅ dbt project found
✅ All commands executable
```

**If any checks fail**, see [Troubleshooting](#troubleshooting) section.

### Step 9: Your First Claude Code Session (15 min)

Test your setup with a simple workflow:

```bash
# Start Claude Code in your dbt project
cd ~/carta/ds-dbt
claude

# Try these commands:
# 1. "Show me my current Jira tickets"
# 2. "What's in the core/zuora directory?"
# 3. "Explain the core_fct_zuora_arr model"
```

🎉 **You're done with Day 1 setup!**

---

## Week 1: Core Workflows

Now that Claude is set up, learn the core workflows you'll use daily.

### Workflow 1: Creating a Branch for a Ticket

```
User: "I'm working on DA-1234. Create a branch for migrating zuora ARR models"

Claude will:
1. Read the Jira ticket (acli jira workitem view DA-1234)
2. Create a branch following team convention: {initials}/da-1234/migrate-zuora-arr
3. Check out the branch
```

### Workflow 2: Migrating a Model to Scratch

```
User: "Migrate core_fct_subscription_arr to scratch naming"

Claude will:
1. Use migrate-model-to-scratch command
2. Rename file with _scratch suffix
3. Add alias config
4. Update downstream references
5. Stage changes with git
```

### Workflow 3: Running Validation Before Committing

```
User: "Validate my verified models before I commit"

Claude will run:
1. validate-verified-standards (syntax, no SELECT *)
2. validate-layer-dependencies (mart → core only)
3. check-verified-references (no scratch refs)
4. dbt parse (compilation check)
```

### Workflow 4: Creating a Pull Request

```
User: "Create a PR for this work"

Claude will:
1. Check git status and diff
2. Push branch to origin
3. Generate PR description with summary
4. Create PR with proper label (cc-product-development)
5. Copy Slack notification to clipboard: `:dbt: [DA-1234] Title https://...`
```

### Workflow 5: Querying Snowflake

```
User: "How many rows are in core_fct_zuora_arr?"

Claude will:
1. Use snow sql CLI
2. Run SELECT COUNT(*) query
3. Return results in JSON format
```

---

## Month 1: Advanced Patterns

### Using Agents for Complex Tasks

Agents handle multi-step workflows autonomously:

**dbt-refactor-agent** (for 5+ model migrations):
```
User: "Use dbt-refactor-agent to migrate the 8 subscription models to verified/ with proper tests and documentation"
```

**model-migration-agent** (for dependency analysis):
```
User: "Use model-migration-agent to analyze dependencies for moving core_dim_corporations to verified/"
```

**jira-ticket-agent** (for ticket management):
```
User: "Use jira-ticket-agent to create tickets for each domain migration"
```

### Session Context for Resuming Work

Before long breaks, save your work state:

```
User: "Save our current session state to session-context/ - we're working on zuora migration"
```

After resuming:
```
User: "Read the latest session context file and continue where we left off"
```

### Custom Commands

Our team has built these commands (all in `~/.claude/commands/`):

- `migrate-model-to-scratch` - Rename with _scratch suffix
- `validate-verified-standards` - Check verified/ model compliance
- `validate-layer-dependencies` - Enforce layer architecture
- `check-verified-references` - Ensure no scratch refs
- `compare-table-schemas` - Compare scratch vs verified
- `analyze-unused-columns` - Find unused columns
- `bulk-model-rename` - Systematic renaming
- `find-next-migration-candidates` - Identify ready models

**Usage example:**
```bash
cd ~/carta/ds-dbt
~/.claude/commands/validate-verified-standards
```

Or via Claude:
```
User: "Run validate-verified-standards on my changed files"
```

---

## Troubleshooting

### Claude Code won't start

**Error:** `claude: command not found`

**Solution:**
```bash
# Reinstall Claude Code
brew uninstall claude
brew install anthropic/tap/claude

# Verify installation
which claude
claude --version
```

---

### AWS Bedrock authentication fails

**Error:** `Unable to locate credentials` or `Access Denied`

**Solution:**
```bash
# Re-authenticate with AWS SSO
aws sso login --profile AmazonBedrockStandardAccess-559050237467

# Verify profile is set
echo $AWS_PROFILE

# If not set, add to ~/.zshrc:
export AWS_PROFILE="AmazonBedrockStandardAccess-559050237467"
source ~/.zshrc
```

---

### Jira CLI not working

**Error:** `acli: command not found` or authentication fails

**Solution:**
```bash
# Reinstall Jira CLI
brew reinstall go-jira

# Get API token from Jira
# 1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
# 2. Create API token
# 3. Configure acli with token
```

---

### Snowflake connection fails

**Error:** `Connection refused` or `Invalid credentials`

**Solution:**
```bash
# Test connection manually
snow connection test

# If fails, reconfigure
snow connection add --default
# Account: carta.us-east-1
# Authenticator: externalbrowser
```

---

### dbt commands fail

**Error:** `dbt: command not found` or `No module named dbt`

**Solution:**
```bash
cd ~/carta/ds-dbt

# Reinstall dependencies
poetry install

# Activate virtual environment
poetry shell

# Test dbt
dbt --version
```

---

### Commands not found

**Error:** `migrate-model-to-scratch: command not found`

**Solution:**
```bash
# Make commands executable
chmod +x ~/.claude/commands/*

# Add to PATH in ~/.zshrc
export PATH="$HOME/.claude/commands:$PATH"
source ~/.zshrc

# Verify
which migrate-model-to-scratch
```

---

## Security & Best Practices

### ✅ DO:

- ✅ Use `.gitignore` to exclude personal notes (`session-context/*.md`, `prompt_md/`)
- ✅ Keep AWS credentials in environment variables, not files
- ✅ Use `settings.local.json` for personal settings (already gitignored)
- ✅ Run cleanup script monthly: `~/.claude/scripts/cleanup.sh`
- ✅ Review git diff before committing changes
- ✅ Use session context to save work state before long breaks

### ❌ DON'T:

- ❌ Commit API tokens, passwords, or credentials to git
- ❌ Share your personal `settings.local.json`
- ❌ Put company-sensitive data in public repos
- ❌ Disable pre-commit hooks without good reason
- ❌ Let your `projects/` directory exceed 100MB

---

## Getting Help

### Team Resources

- **Slack:** #analytics-engineering (general help)
- **Slack:** #claude-code-users (Claude-specific questions)
- **Confluence:** [Claude Code Team Guide](link-to-confluence)
- **GitHub:** [claude-agents issues](https://github.com/kziaj/claude-agents/issues)

### Onboarding Buddy

Your onboarding buddy is: **{ASSIGNED_BUDDY}**

Schedule time with them in Week 1 to:
- Review your first PR together
- Walk through a complex migration
- Discuss team conventions and best practices

### Office Hours

Claude Code office hours: **Thursdays 2-3pm PT**
- Bring your questions
- See live demos
- Learn advanced patterns

---

## Next Steps

### Week 1 Goals

- [ ] Complete your first ticket end-to-end with Claude
- [ ] Create a PR using team conventions
- [ ] Run all validation commands successfully
- [ ] Join #claude-code-users Slack channel
- [ ] Meet with your onboarding buddy

### Week 2-4 Goals

- [ ] Use an agent (dbt-refactor or model-migration)
- [ ] Contribute a new command or skill
- [ ] Help another team member with Claude
- [ ] Participate in knowledge sharing session

---

## Feedback

We're constantly improving our Claude Code setup. After 30 days, please complete:

📋 **[New Hire Feedback Form](link-to-form)**

Your input helps us make onboarding better for future team members!

---

**Last Updated:** January 2026  
**Maintained By:** Analytics Engineering Team  
**Questions?** Reach out in #claude-code-users

---

## Quick Reference

### Essential Commands

```bash
# Start Claude Code
cd ~/carta/ds-dbt && claude

# Validate changes
validate-verified-standards
validate-layer-dependencies
check-verified-references

# Migration helpers
migrate-model-to-scratch <model_path>
compare-table-schemas <scratch_table> <verified_table>

# Cleanup
~/.claude/scripts/cleanup.sh --dry-run
~/.claude/scripts/cleanup.sh
```

### Key Directories

- `~/.claude/` - Your Claude configuration
- `~/.claude/commands/` - Team commands
- `~/.claude/skills/` - Team skills and documentation
- `~/.claude/session-context/` - Your work notes
- `~/carta/ds-dbt/` - dbt project

### Helpful Aliases

```bash
d <model>       # Run dbt model in dev
ds <model>      # Run dbt model in Snowflake prod
```

Welcome to the team! 🚀
