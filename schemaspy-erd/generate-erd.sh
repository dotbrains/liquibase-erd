#!/bin/bash
set -e -o pipefail

# Configuration from environment variables
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-mydb}"
DB_USER="${DB_USER:-dbuser}"
DB_PASSWORD="${DB_PASSWORD:-temp-password}"
SCHEMA_NAME="${SCHEMA_NAME:-public}"
CHANGELOG_FILE="${CHANGELOG_FILE:-/workspace/db/changelog.xml}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"

echo "=== SchemaSpy ERD Generator (Docker) ==="
echo ""

# Validation
if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "❌ Error: Changelog file not found: $CHANGELOG_FILE"
    echo "   Make sure CHANGELOG_FILE is set correctly and the file is mounted"
    exit 1
fi

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
for i in $(seq 1 30); do
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Error: Cannot connect to PostgreSQL"
        exit 1
    fi
    sleep 1
done

echo "✓ Connected to PostgreSQL"

# Create schema
echo "📊 Creating schema..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "CREATE SCHEMA IF NOT EXISTS $SCHEMA_NAME;" > /dev/null 2>&1

# Apply Liquibase changes directly to database
echo "📝 Applying Liquibase changes to database..."
mkdir -p "$OUTPUT_DIR"

# Extract directory and filename from changelog path
CHANGELOG_DIR=$(dirname "$CHANGELOG_FILE")
CHANGELOG_NAME=$(basename "$CHANGELOG_FILE")

liquibase \
    --search-path="$CHANGELOG_DIR" \
    --changeLogFile="$CHANGELOG_NAME" \
    --url="jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME" \
    --username="$DB_USER" \
    --password="$DB_PASSWORD" \
    --liquibase-schema-name="$SCHEMA_NAME" \
    --default-schema-name="$SCHEMA_NAME" \
    update > "$OUTPUT_DIR/liquibase-update.log" 2>&1 || {
        echo "❌ Error: Failed to apply Liquibase changes"
        cat "$OUTPUT_DIR/liquibase-update.log"
        exit 1
    }

echo "✓ Schema applied successfully"

# Generate ERD using SchemaSpy
echo "🎨 Generating ERD diagrams and documentation..."

java -jar /opt/schemaspy/schemaspy.jar \
    -t pgsql \
    -dp /opt/schemaspy/postgresql.jar \
    -db "$DB_NAME" \
    -host "$DB_HOST" \
    -port "$DB_PORT" \
    -u "$DB_USER" \
    -p "$DB_PASSWORD" \
    -s "$SCHEMA_NAME" \
    -o "$OUTPUT_DIR/html" \
    -vizjs 2>&1 | grep -v "^INFO:" || true

# Copy diagram files to output root if they exist
if [ -f "$OUTPUT_DIR/html/diagrams/summary/relationships.real.large.png" ]; then
    cp "$OUTPUT_DIR/html/diagrams/summary/relationships.real.large.png" "$OUTPUT_DIR/${SCHEMA_NAME}-erd.png"
fi

if [ -f "$OUTPUT_DIR/html/diagrams/summary/relationships.real.large.svg" ]; then
    cp "$OUTPUT_DIR/html/diagrams/summary/relationships.real.large.svg" "$OUTPUT_DIR/${SCHEMA_NAME}-erd.svg"
fi

echo "✓ Complete!"
echo ""
echo "Output files:"
[ -f "$OUTPUT_DIR/${SCHEMA_NAME}-erd.png" ] && echo "  • PNG: $OUTPUT_DIR/${SCHEMA_NAME}-erd.png"
[ -f "$OUTPUT_DIR/${SCHEMA_NAME}-erd.svg" ] && echo "  • SVG: $OUTPUT_DIR/${SCHEMA_NAME}-erd.svg"
[ -d "$OUTPUT_DIR/html" ] && echo "  • HTML: $OUTPUT_DIR/html/index.html"
echo ""
