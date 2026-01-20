#!/bin/bash
# Demo script for SchemaCrawler ERD generation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo "SchemaCrawler ERD Demo"
echo "========================================="
echo ""
echo "This demo will:"
echo "  1. Use the sample e-commerce database schema"
echo "  2. Generate ERD diagrams (PNG and SVG)"
echo "  3. Output to: example/output/schemacrawler/"
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
export OUTPUT_DIR="$SCRIPT_DIR/output/schemacrawler"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run using shared script
exec "$PROJECT_ROOT/shared/docker.sh" schemacrawler "$PROJECT_ROOT"
