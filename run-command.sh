#!/bin/bash

# Claude Command Runner
# Usage: ./run-command.sh analyze-unused-columns MODEL_NAME

COMMAND="$1"
shift  # Remove first argument, pass rest to command

case "$COMMAND" in
    "analyze-unused-columns")
        bash ~/.claude/commands/analyze-unused-columns "$@"
        ;;
    "migrate-model-to-scratch")
        bash ~/.claude/commands/migrate-model-to-scratch "$@"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Available commands:"
        echo "  analyze-unused-columns MODEL_NAME    - Analyze unused columns in dbt model"
        echo "  migrate-model-to-scratch MODEL_NAME  - Migrate model to _scratch naming convention"
        exit 1
        ;;
esac