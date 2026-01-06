#!/bin/bash

# Validate Claude Code Setup for Carta Analytics Engineering
# Usage: ~/.claude/scripts/validate-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print colored output
print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ PASS${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}❌ FAIL${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo -e "${GREEN}=== Carta Analytics Engineering - Claude Code Setup Validation ===${NC}\n"

# 1. Check Claude Code Installation
print_check "Claude Code installation"
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | head -1)
    print_success "Claude Code installed: $CLAUDE_VERSION"
else
    print_fail "Claude Code not installed"
    print_info "Install with: brew install anthropic/tap/claude"
fi
echo ""

# 2. Check AWS CLI and Bedrock Access
print_check "AWS Bedrock authentication"
if command -v aws &> /dev/null; then
    if [[ -n "$AWS_PROFILE" ]]; then
        # Test AWS SSO login
        if aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
            print_success "AWS Bedrock authenticated with profile: $AWS_PROFILE"
        else
            print_fail "AWS authentication failed"
            print_info "Run: aws sso login --profile $AWS_PROFILE"
        fi
    else
        print_warning "AWS_PROFILE not set in environment"
        print_info "Add to ~/.zshrc: export AWS_PROFILE=\"AmazonBedrockStandardAccess-559050237467\""
    fi
else
    print_fail "AWS CLI not installed"
    print_info "Install with: brew install awscli"
fi
echo ""

# 3. Check GitHub CLI
print_check "GitHub CLI configuration"
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        GH_USER=$(gh api user -q .login 2>/dev/null)
        print_success "GitHub CLI authenticated as: $GH_USER"
    else
        print_fail "GitHub CLI not authenticated"
        print_info "Run: gh auth login"
    fi
else
    print_fail "GitHub CLI not installed"
    print_info "Install with: brew install gh"
fi
echo ""

# 4. Check Jira CLI
print_check "Jira CLI configuration"
if command -v acli &> /dev/null; then
    print_success "Jira CLI (acli) installed"
    if [[ -n "$JIRA_ASSIGNEE_NAME" ]]; then
        print_success "JIRA_ASSIGNEE_NAME set to: $JIRA_ASSIGNEE_NAME"
    else
        print_warning "JIRA_ASSIGNEE_NAME not set"
        print_info "Add to ~/.zshrc: export JIRA_ASSIGNEE_NAME=\"Your Full Name\""
    fi
else
    print_fail "Jira CLI not installed"
    print_info "Install with: brew install go-jira/jira/go-jira"
fi
echo ""

# 5. Check Snowflake CLI
print_check "Snowflake CLI configuration"
if command -v snow &> /dev/null; then
    print_success "Snowflake CLI installed"
    # Test connection
    if snow connection test --connection default &> /dev/null; then
        print_success "Snowflake connection working (default)"
    else
        print_warning "Snowflake connection not configured or failing"
        print_info "Run: snow connection add"
    fi
else
    print_fail "Snowflake CLI not installed"
    print_info "Install with: brew tap snowflakedb/snowflake-cli && brew install snowflake-cli"
fi
echo ""

# 6. Check Poetry installation
print_check "Poetry (Python dependency manager)"
if command -v poetry &> /dev/null; then
    POETRY_VERSION=$(poetry --version 2>&1)
    print_success "Poetry installed: $POETRY_VERSION"
else
    print_fail "Poetry not installed"
    print_info "Install with: brew install poetry"
fi
echo ""

# 7. Check for Carta repositories
print_check "Carta dbt repository"
if [[ -n "$CARTA_DBT_DIR" ]]; then
    if [ -d "$CARTA_DBT_DIR" ]; then
        print_success "dbt repo found at: $CARTA_DBT_DIR"
        
        # Check if it's a git repo
        if [ -d "$CARTA_DBT_DIR/.git" ]; then
            print_success "dbt repo is a git repository"
        else
            print_warning "dbt directory exists but is not a git repository"
        fi
        
        # Check for poetry project
        if [ -f "$CARTA_DBT_DIR/pyproject.toml" ]; then
            print_success "Poetry project found in dbt repo"
        else
            print_warning "pyproject.toml not found - may not be Poetry project"
        fi
    else
        print_fail "CARTA_DBT_DIR set but directory doesn't exist: $CARTA_DBT_DIR"
        print_info "Clone with: cd ~/carta && gh repo clone carta/ds-dbt"
    fi
else
    print_warning "CARTA_DBT_DIR not set"
    print_info "Add to ~/.zshrc: export CARTA_DBT_DIR=\"$HOME/carta/ds-dbt\""
fi
echo ""

# 8. Check Claude directory and commands
print_check "Claude Code configuration directory"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
if [ -d "$CLAUDE_DIR" ]; then
    print_success "Claude directory exists: $CLAUDE_DIR"
    
    # Check for CLAUDE.md
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        print_success "CLAUDE.md configuration file found"
    else
        print_warning "CLAUDE.md not found"
        print_info "Copy from template: cp $CLAUDE_DIR/CLAUDE.md.template $CLAUDE_DIR/CLAUDE.md"
    fi
    
    # Check for commands directory
    if [ -d "$CLAUDE_DIR/commands" ]; then
        CMD_COUNT=$(find "$CLAUDE_DIR/commands" -type f -perm +111 2>/dev/null | wc -l | tr -d ' ')
        print_success "Found $CMD_COUNT executable commands"
    else
        print_warning "commands/ directory not found"
    fi
    
    # Check for skills directory
    if [ -d "$CLAUDE_DIR/skills" ]; then
        SKILL_COUNT=$(find "$CLAUDE_DIR/skills" -type d -depth 1 2>/dev/null | wc -l | tr -d ' ')
        print_success "Found $SKILL_COUNT skills"
    else
        print_warning "skills/ directory not found"
    fi
else
    print_fail "Claude directory not found: $CLAUDE_DIR"
    print_info "Clone with: git clone https://github.com/kziaj/claude-agents.git ~/.claude"
fi
echo ""

# 9. Check environment variables
print_check "Required environment variables"
ENV_VARS=(
    "AWS_PROFILE:AmazonBedrockStandardAccess-559050237467"
    "AWS_REGION:us-east-1"
    "CLAUDE_CODE_USE_BEDROCK:1"
    "CARTA_DBT_DIR:$HOME/carta/ds-dbt"
)

for var_spec in "${ENV_VARS[@]}"; do
    VAR_NAME="${var_spec%%:*}"
    VAR_EXPECTED="${var_spec##*:}"
    VAR_VALUE="${!VAR_NAME}"
    
    if [[ -n "$VAR_VALUE" ]]; then
        print_success "$VAR_NAME is set"
    else
        print_warning "$VAR_NAME not set (expected: $VAR_EXPECTED)"
        print_info "Add to ~/.zshrc: export $VAR_NAME=\"$VAR_EXPECTED\""
    fi
done
echo ""

# 10. Check git configuration
print_check "Git configuration"
GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$GIT_USER" ]]; then
    print_success "Git user.name: $GIT_USER"
else
    print_warning "Git user.name not set"
    print_info "Run: git config --global user.name \"Your Name\""
fi

if [[ -n "$GIT_EMAIL" ]]; then
    print_success "Git user.email: $GIT_EMAIL"
else
    print_warning "Git user.email not set"
    print_info "Run: git config --global user.email \"your.email@carta.com\""
fi
echo ""

# Summary
echo -e "${GREEN}=== Validation Summary ===${NC}"
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 Perfect setup! You're ready to use Claude Code.${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. cd ~/carta/ds-dbt"
        echo "  2. claude"
        echo "  3. Try: 'Show me my Jira tickets'"
    else
        echo -e "${YELLOW}⚠️  Setup is functional but has warnings.${NC}"
        echo "Fix warnings above for the best experience."
    fi
else
    echo -e "${RED}❌ Setup incomplete. Fix the failed checks above.${NC}"
    echo ""
    echo "Common solutions:"
    echo "  - Missing tools: Check installation commands above"
    echo "  - Authentication: Re-run auth commands (gh auth login, aws sso login, etc.)"
    echo "  - Environment variables: Add them to ~/.zshrc and run 'source ~/.zshrc'"
    exit 1
fi
