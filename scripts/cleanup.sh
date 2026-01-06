#!/bin/bash

# Claude Code Directory Cleanup Script
# Automates routine maintenance of ~/.claude directory
# Usage: ~/.claude/scripts/cleanup.sh [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLAUDE_DIR="$HOME/.claude"
DRY_RUN=false

# Parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}Running in DRY RUN mode - no files will be deleted${NC}\n"
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get human-readable size
get_size() {
    du -sh "$1" 2>/dev/null | awk '{print $1}'
}

# Start cleanup
echo -e "${GREEN}=== Claude Code Directory Cleanup ===${NC}\n"
print_status "Starting cleanup of $CLAUDE_DIR"
echo ""

# 1. Clean up conversation history (older than 21 days)
print_status "Checking conversation history..."
PROJECTS_DIR="$CLAUDE_DIR/projects/-Users-$(whoami)"
if [ -d "$PROJECTS_DIR" ]; then
    OLD_CONVERSATIONS=$(find "$PROJECTS_DIR" -name "*.jsonl" -type f -mtime +21 2>/dev/null | wc -l | tr -d ' ')
    if [ "$OLD_CONVERSATIONS" -gt 0 ]; then
        SIZE_BEFORE=$(get_size "$PROJECTS_DIR")
        print_warning "Found $OLD_CONVERSATIONS conversation files older than 21 days"
        
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$CLAUDE_DIR/projects/archive/$(date +%Y-%m)"
            find "$PROJECTS_DIR" -name "*.jsonl" -type f -mtime +21 -exec mv {} "$CLAUDE_DIR/projects/archive/$(date +%Y-%m)/" \;
            SIZE_AFTER=$(get_size "$PROJECTS_DIR")
            print_success "Archived $OLD_CONVERSATIONS files to projects/archive/$(date +%Y-%m)/ ($SIZE_BEFORE -> $SIZE_AFTER)"
        else
            print_warning "[DRY RUN] Would archive $OLD_CONVERSATIONS files"
        fi
    else
        print_success "No old conversation files to archive"
    fi
else
    print_warning "Projects directory not found"
fi
echo ""

# 2. Clean up shell snapshots (older than 14 days)
print_status "Checking shell snapshots..."
SHELL_SNAPSHOTS_DIR="$CLAUDE_DIR/shell-snapshots"
if [ -d "$SHELL_SNAPSHOTS_DIR" ]; then
    OLD_SNAPSHOTS=$(find "$SHELL_SNAPSHOTS_DIR" -type f -mtime +14 2>/dev/null | wc -l | tr -d ' ')
    if [ "$OLD_SNAPSHOTS" -gt 0 ]; then
        SIZE_BEFORE=$(get_size "$SHELL_SNAPSHOTS_DIR")
        print_warning "Found $OLD_SNAPSHOTS shell snapshot files older than 14 days"
        
        if [ "$DRY_RUN" = false ]; then
            find "$SHELL_SNAPSHOTS_DIR" -type f -mtime +14 -delete
            SIZE_AFTER=$(get_size "$SHELL_SNAPSHOTS_DIR")
            print_success "Deleted $OLD_SNAPSHOTS files ($SIZE_BEFORE -> $SIZE_AFTER)"
        else
            print_warning "[DRY RUN] Would delete $OLD_SNAPSHOTS files"
        fi
    else
        print_success "No old shell snapshots to delete"
    fi
else
    print_warning "Shell snapshots directory not found"
fi
echo ""

# 3. Clean up todos (older than 14 days)
print_status "Checking todos..."
TODOS_DIR="$CLAUDE_DIR/todos"
if [ -d "$TODOS_DIR" ]; then
    OLD_TODOS=$(find "$TODOS_DIR" -type f -mtime +14 2>/dev/null | wc -l | tr -d ' ')
    if [ "$OLD_TODOS" -gt 0 ]; then
        SIZE_BEFORE=$(get_size "$TODOS_DIR")
        print_warning "Found $OLD_TODOS todo files older than 14 days"
        
        if [ "$DRY_RUN" = false ]; then
            find "$TODOS_DIR" -type f -mtime +14 -delete
            SIZE_AFTER=$(get_size "$TODOS_DIR")
            print_success "Deleted $OLD_TODOS files ($SIZE_BEFORE -> $SIZE_AFTER)"
        else
            print_warning "[DRY RUN] Would delete $OLD_TODOS files"
        fi
    else
        print_success "No old todo files to delete"
    fi
else
    print_warning "Todos directory not found"
fi
echo ""

# 4. Remove .DS_Store files
print_status "Checking for .DS_Store files..."
DS_STORE_COUNT=$(find "$CLAUDE_DIR" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$DS_STORE_COUNT" -gt 0 ]; then
    print_warning "Found $DS_STORE_COUNT .DS_Store files"
    
    if [ "$DRY_RUN" = false ]; then
        find "$CLAUDE_DIR" -name ".DS_Store" -type f -delete
        print_success "Deleted $DS_STORE_COUNT .DS_Store files"
    else
        print_warning "[DRY RUN] Would delete $DS_STORE_COUNT .DS_Store files"
    fi
else
    print_success "No .DS_Store files found"
fi
echo ""

# 5. Archive old session context files
print_status "Checking session context files..."
SESSION_CONTEXT_DIR="$CLAUDE_DIR/session-context"
if [ -d "$SESSION_CONTEXT_DIR" ]; then
    # Archive files from previous months (not current month)
    CURRENT_MONTH=$(date +%Y-%m)
    OLD_SESSIONS=$(find "$SESSION_CONTEXT_DIR" -maxdepth 1 -name "*.md" -type f ! -name "README.md" ! -name "TEMPLATE.md" ! -name "EXAMPLE*.md" 2>/dev/null | while read file; do
        if [[ ! $(basename "$file") =~ ^${CURRENT_MONTH} ]] && [[ ! $(basename "$file") =~ ^$(date +%Y-%m --date='1 month ago') ]]; then
            echo "$file"
        fi
    done | wc -l | tr -d ' ')
    
    if [ "$OLD_SESSIONS" -gt 0 ]; then
        print_warning "Found $OLD_SESSIONS session context files to archive"
        
        if [ "$DRY_RUN" = false ]; then
            find "$SESSION_CONTEXT_DIR" -maxdepth 1 -name "*.md" -type f ! -name "README.md" ! -name "TEMPLATE.md" ! -name "EXAMPLE*.md" 2>/dev/null | while read file; do
                if [[ ! $(basename "$file") =~ ^${CURRENT_MONTH} ]] && [[ ! $(basename "$file") =~ ^$(date +%Y-%m --date='1 month ago') ]]; then
                    FILE_DATE=$(basename "$file" | grep -oE '^[0-9]{4}-[0-9]{2}' || echo "unknown")
                    if [ "$FILE_DATE" != "unknown" ]; then
                        ARCHIVE_DIR="$SESSION_CONTEXT_DIR/archive/$FILE_DATE"
                    else
                        ARCHIVE_DIR="$SESSION_CONTEXT_DIR/archive/unknown"
                    fi
                    mkdir -p "$ARCHIVE_DIR"
                    mv "$file" "$ARCHIVE_DIR/"
                fi
            done
            print_success "Archived $OLD_SESSIONS session context files"
        else
            print_warning "[DRY RUN] Would archive $OLD_SESSIONS session context files"
        fi
    else
        print_success "No old session context files to archive"
    fi
else
    print_warning "Session context directory not found"
fi
echo ""

# 6. Archive old result files (older than 90 days)
print_status "Checking result files..."
RESULTS_DIR="$CLAUDE_DIR/results"
if [ -d "$RESULTS_DIR" ]; then
    OLD_RESULTS=$(find "$RESULTS_DIR" -type f -mtime +90 2>/dev/null | wc -l | tr -d ' ')
    if [ "$OLD_RESULTS" -gt 0 ]; then
        print_warning "Found $OLD_RESULTS result files older than 90 days"
        
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$RESULTS_DIR/archive/$(date +%Y-%m)"
            find "$RESULTS_DIR" -type f -mtime +90 -exec mv {} "$RESULTS_DIR/archive/$(date +%Y-%m)/" \;
            print_success "Archived $OLD_RESULTS result files"
        else
            print_warning "[DRY RUN] Would archive $OLD_RESULTS result files"
        fi
    else
        print_success "No old result files to archive"
    fi
else
    print_warning "Results directory not found"
fi
echo ""

# Summary
echo -e "${GREEN}=== Cleanup Summary ===${NC}"
print_status "Cleanup completed!"
echo ""
print_status "Current directory sizes:"
[ -d "$PROJECTS_DIR" ] && echo "  Projects: $(get_size "$PROJECTS_DIR")"
[ -d "$SHELL_SNAPSHOTS_DIR" ] && echo "  Shell Snapshots: $(get_size "$SHELL_SNAPSHOTS_DIR")"
[ -d "$TODOS_DIR" ] && echo "  Todos: $(get_size "$TODOS_DIR")"
[ -d "$SESSION_CONTEXT_DIR" ] && echo "  Session Context: $(get_size "$SESSION_CONTEXT_DIR")"
[ -d "$RESULTS_DIR" ] && echo "  Results: $(get_size "$RESULTS_DIR")"
echo ""
print_success "Total directory size: $(get_size "$CLAUDE_DIR")"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}This was a dry run. Run without --dry-run to actually clean up files.${NC}"
else
    echo -e "${GREEN}Cleanup complete! Run this script monthly to keep your .claude directory tidy.${NC}"
fi
