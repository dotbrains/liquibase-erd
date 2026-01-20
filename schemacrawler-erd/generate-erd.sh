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

echo "=== SchemaCrawler ERD Generator (Docker) ==="
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

# Determine the directory containing the changelog
CHANGELOG_DIR="$(dirname "$CHANGELOG_FILE")"
CHANGELOG_BASENAME="$(basename "$CHANGELOG_FILE")"

/opt/liquibase \
    --search-path="$CHANGELOG_DIR" \
    --changeLogFile="$CHANGELOG_BASENAME" \
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

# Generate ERD using SchemaCrawler
echo "🎨 Generating ERD diagrams..."

# Connection URL
JDBC_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Generate PNG
schemacrawler.sh \
    --server=postgresql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --database="$DB_NAME" \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    --schemas="$SCHEMA_NAME" \
    --info-level=standard \
    --command=schema \
    --output-format=png \
    --output-file="$OUTPUT_DIR/${SCHEMA_NAME}-erd.png" \
    2>&1 | grep -v "^SchemaCrawler" || true

# Generate SVG
schemacrawler.sh \
    --server=postgresql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --database="$DB_NAME" \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    --schemas="$SCHEMA_NAME" \
    --info-level=standard \
    --command=schema \
    --output-format=svg \
    --output-file="$OUTPUT_DIR/${SCHEMA_NAME}-erd.svg" \
    2>&1 | grep -v "^SchemaCrawler" || true

echo "✓ Complete!"
echo ""
echo "Output files:"
[ -f "$OUTPUT_DIR/${SCHEMA_NAME}-erd.png" ] && echo "  • PNG: $OUTPUT_DIR/${SCHEMA_NAME}-erd.png"
[ -f "$OUTPUT_DIR/${SCHEMA_NAME}-erd.svg" ] && echo "  • SVG: $OUTPUT_DIR/${SCHEMA_NAME}-erd.svg"
echo ""
