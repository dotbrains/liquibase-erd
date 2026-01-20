#!/bin/bash
# Demo script for SchemaSpy ERD generation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo "SchemaSpy ERD Demo"
echo "========================================="
echo ""
echo "This demo will:"
echo "  1. Use the sample e-commerce database schema"
echo "  2. Generate ERD diagrams and interactive HTML docs"
echo "  3. Output to: example/output/schemaspy/"
echo ""
echo "Press Enter to continue..."
read

# Configuration for demo
export DB_NAME="demo_ecommerce"
export DB_USER="demo"
export POSTGRES_PASSWORD="demo-password-$(date +%s)"
export SCHEMA_NAME="public"
export CHANGELOG_FILE="/workspace/example/db/changelog.xml"
export CHANGELOG_DIR="$PROJECT_ROOT"
export OUTPUT_DIR="$SCRIPT_DIR/output/schemaspy"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run using shared script
exec "$PROJECT_ROOT/shared/docker.sh" schemaspy "$PROJECT_ROOT"
