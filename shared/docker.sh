#!/bin/bash
set -e

# Shared Docker runner script
# Called by run-schemacrawler.sh and run-schemaspy.sh

TOOL_PROFILE="$1"  # 'schemacrawler' or 'schemaspy'
TOOL_NAME="$(echo "$TOOL_PROFILE" | sed 's/^./\U&/')"  # Capitalize first letter
PROJECT_ROOT="$2"  # Project root directory

if [ -z "$TOOL_PROFILE" ] || [ -z "$PROJECT_ROOT" ]; then
    echo "Error: This script should not be called directly."
    echo "Use run-schemacrawler.sh or run-schemaspy.sh instead."
    exit 1
fi

cd "$PROJECT_ROOT"

echo "========================================="
echo "$TOOL_NAME ERD Generator (Docker)"
echo "========================================="
echo ""

# Load config if it exists
if [ -f "config.sh" ]; then
    echo "Loading configuration from config.sh..."
    source config.sh
fi

# Set defaults
export DB_NAME="${DB_NAME:-mydb}"
export DB_USER="${DB_USER:-dbuser}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-temp-password-$(date +%s)}"
export SCHEMA_NAME="${SCHEMA_NAME:-public}"
export CHANGELOG_FILE="${CHANGELOG_FILE:-/workspace/db/changelog.xml}"
export CHANGELOG_DIR="${CHANGELOG_DIR:-.}"
export OUTPUT_DIR="${OUTPUT_DIR:-./$(echo $TOOL_PROFILE | tr '[:upper:]' '[:lower:]')-erd/output}"

echo "Configuration:"
echo "  Database: $DB_NAME"
echo "  Schema: $SCHEMA_NAME"
echo "  Changelog: $CHANGELOG_FILE"
echo "  Output: $OUTPUT_DIR"
echo ""

# Build and run
docker-compose --profile "$TOOL_PROFILE" up --build --abort-on-container-exit

# Cleanup
docker-compose down

echo ""
echo "========================================="
echo "Complete!"
echo "========================================="
echo ""
echo "Generated files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.png "$OUTPUT_DIR"/*.svg 2>/dev/null || echo "  No diagram files found"
[ "$TOOL_PROFILE" = "schemaspy" ] && [ -d "$OUTPUT_DIR/html" ] && echo "  HTML documentation: $OUTPUT_DIR/html/index.html"
echo ""
