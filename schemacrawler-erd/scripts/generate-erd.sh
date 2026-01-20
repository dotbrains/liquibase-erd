#!/bin/bash
set -e -o pipefail

# Configuration - Customize these for your project
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/output"
K8S_DIR="$PROJECT_ROOT/k8s"

# Database configuration
CLUSTER_NAME="${CLUSTER_NAME:-db-erd-temp}"               # Kubernetes cluster name
NAMESPACE="${NAMESPACE:-default}"                         # Kubernetes namespace
DB_NAME="${DB_NAME:-mydb}"                                # Database name
DB_USER="${DB_USER:-dbuser}"                              # Database user
SCHEMA_NAME="${SCHEMA_NAME:-public}"                      # Schema to document
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-temp-password}"   # Temporary password

# Liquibase configuration
CHANGELOG_FILE="${CHANGELOG_FILE:-db/changelog.xml}"      # Path to Liquibase changelog

# Tool configuration
SCHEMACRAWLER_VERSION="16.21.2"

# Helper functions
die() {
    echo "❌ Error: $1" >&2
    exit 1
}

cleanup() {
    kubectl delete job schemacrawler-erd -n "$NAMESPACE" --ignore-not-found=true > /dev/null 2>&1
    kubectl delete cluster "$CLUSTER_NAME" -n "$NAMESPACE" --ignore-not-found=true > /dev/null 2>&1
    kubectl delete secret "${CLUSTER_NAME}-auth" -n "$NAMESPACE" --ignore-not-found=true > /dev/null 2>&1
    [ -f "$OUTPUT_DIR/databasechangelog.csv" ] && rm "$OUTPUT_DIR/databasechangelog.csv"
}
trap cleanup EXIT

wait_for_condition() {
    local timeout=$1
    local condition=$2
    local error_msg=$3
    
    for i in $(seq 1 $timeout); do
        eval "$condition" && return 0
        [ $i -eq $timeout ] && die "$error_msg"
        sleep 1
    done
}

echo "=== SchemaCrawler ERD Generator ==="
echo ""

# Validation
for cmd in liquibase kubectl; do
    command -v $cmd &> /dev/null || die "$cmd not found"
done
kubectl cluster-info &> /dev/null || die "Cannot connect to Kubernetes cluster"
kubectl get crd clusters.postgresql.cnpg.io &> /dev/null || die "CloudNativePG operator not found"

# Download SchemaCrawler if needed
mkdir -p "$OUTPUT_DIR"
SC_DIR="$PROJECT_ROOT/schemacrawler/schemacrawler-$SCHEMACRAWLER_VERSION-bin"

if [ ! -d "$SC_DIR" ]; then
    echo "📦 Downloading SchemaCrawler $SCHEMACRAWLER_VERSION..."
    mkdir -p "$PROJECT_ROOT/schemacrawler"
    cd "$PROJECT_ROOT/schemacrawler"
    
    if command -v curl &> /dev/null; then
        curl -sLO "https://github.com/schemacrawler/SchemaCrawler/releases/download/v$SCHEMACRAWLER_VERSION/schemacrawler-$SCHEMACRAWLER_VERSION-bin.zip"
    else
        wget -q "https://github.com/schemacrawler/SchemaCrawler/releases/download/v$SCHEMACRAWLER_VERSION/schemacrawler-$SCHEMACRAWLER_VERSION-bin.zip"
    fi
    
    unzip -q "schemacrawler-$SCHEMACRAWLER_VERSION-bin.zip"
    rm "schemacrawler-$SCHEMACRAWLER_VERSION-bin.zip"
    cd "$REPO_ROOT"
fi

echo "✓ SchemaCrawler $SCHEMACRAWLER_VERSION ready"

# Generate SQL from Liquibase
echo "📝 Generating SQL from Liquibase..."
if [ ! -f "$CHANGELOG_FILE" ]; then
    die "Changelog file not found: $CHANGELOG_FILE"
fi

liquibase \
    --changeLogFile="$CHANGELOG_FILE" \
    --url=offline:postgresql \
    updateSQL > "$OUTPUT_DIR/schema.sql" 2>&1

# Start CNPG cluster
echo "☸️  Starting PostgreSQL CNPG cluster..."
kubectl delete cluster "$CLUSTER_NAME" -n "$NAMESPACE" --ignore-not-found=true --wait=false > /dev/null 2>&1
kubectl delete secret "${CLUSTER_NAME}-auth" -n "$NAMESPACE" --ignore-not-found=true > /dev/null 2>&1
sleep 2

kubectl apply -f "$K8S_DIR/postgres-cluster.yaml" -n "$NAMESPACE" || die "Failed to create cluster"

echo "   Waiting for cluster..."
wait_for_condition 120 \
    "kubectl get cluster '$CLUSTER_NAME' -n '$NAMESPACE' -o jsonpath='{.status.phase}' 2>/dev/null | grep -q 'Cluster in healthy state'" \
    "Cluster timeout"

DB_HOST="${CLUSTER_NAME}-rw.${NAMESPACE}.svc.cluster.local"

# Populate database schema
echo "📊 Populating schema..."

POD_NAME=$(kubectl get pod -n "$NAMESPACE" \
    -l "cnpg.io/cluster=$CLUSTER_NAME,role=primary" \
    -o jsonpath='{.items[0].metadata.name}')
[ -z "$POD_NAME" ] && die "Could not find primary pod"

# Create schema
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
    bash -c "PGPASSWORD='$POSTGRES_PASSWORD' psql -h localhost -U $DB_USER -d '$DB_NAME' -c 'CREATE SCHEMA IF NOT EXISTS $SCHEMA_NAME;'" \
    > /dev/null 2>&1 || die "Failed to create schema"

# Clean SQL (remove Liquibase output noise)
grep -v '^##\|^Starting Liquibase\|^Liquibase Version\|^Liquibase Open Source\|Liquibase command\|was executed successfully' \
    "$OUTPUT_DIR/schema.sql" > "$OUTPUT_DIR/schema-clean.sql"

# Apply SQL to database
cat "$OUTPUT_DIR/schema-clean.sql" | \
    kubectl exec -i -n "$NAMESPACE" "$POD_NAME" -- \
    bash -c "PGPASSWORD='$POSTGRES_PASSWORD' psql -h localhost -U $DB_USER -d '$DB_NAME'" \
    > "$OUTPUT_DIR/sql-apply.log" 2>&1 || {
        echo "❌ Error: Failed to apply SQL"
        tail -20 "$OUTPUT_DIR/sql-apply.log"
        exit 1
    }

# Test connectivity
wait_for_condition 10 \
    "kubectl exec -n '$NAMESPACE' '$POD_NAME' -- bash -c \"PGPASSWORD='$POSTGRES_PASSWORD' psql -h $DB_HOST -p 5432 -U shield -d '$DB_NAME' -c 'SELECT 1'\" > /dev/null 2>&1" \
    "Cannot connect to database"

# Generate ERD using Kubernetes Job
echo "🎨 Generating ERD diagrams..."
kubectl delete job schemacrawler-erd -n "$NAMESPACE" --ignore-not-found=true > /dev/null 2>&1
sleep 2

kubectl apply -f "$K8S_DIR/schemacrawler-job.yaml" -n "$NAMESPACE" > /dev/null 2>&1 || die "Failed to create job"

# Wait for pod to start
for i in $(seq 1 60); do
    POD=$(kubectl get pods -n "$NAMESPACE" -l job-name=schemacrawler-erd \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD" ]; then
        STATUS=$(kubectl get pod "$POD" -n "$NAMESPACE" \
            -o jsonpath='{.status.containerStatuses[0].state}' 2>/dev/null)
        echo "$STATUS" | grep -q "running" && break
    fi
    
    [ $i -eq 60 ] && die "Pod timeout"
    sleep 1
done

# Copy SchemaCrawler files to pod
kubectl cp "$SC_DIR" "$NAMESPACE/$POD:/sc" -c schemacrawler 2>&1 | grep -v "Defaulted container\|tar:" > /dev/null || true

# Wait for generation and copy outputs
for i in $(seq 1 120); do
    if kubectl logs "$POD" -n "$NAMESPACE" -c schemacrawler 2>/dev/null | grep -q "Done! Files generated"; then
        # Copy diagram files
        kubectl cp "$NAMESPACE/$POD:/output/${SCHEMA_NAME}-erd.png" "$OUTPUT_DIR/${SCHEMA_NAME}-erd.png" \
            -c schemacrawler 2>/dev/null || echo "⚠️  PNG copy failed"
        kubectl cp "$NAMESPACE/$POD:/output/${SCHEMA_NAME}-erd.svg" "$OUTPUT_DIR/${SCHEMA_NAME}-erd.svg" \
            -c schemacrawler 2>/dev/null || echo "⚠️  SVG copy failed"
        break
    fi
    
    # Check for job failure
    FAILED=$(kubectl get job schemacrawler-erd -n "$NAMESPACE" -o jsonpath='{.status.failed}' 2>/dev/null)
    if [ -n "$FAILED" ] && [ "$FAILED" != "0" ]; then
        echo "❌ Error: Job failed"
        kubectl logs "$POD" -n "$NAMESPACE" -c schemacrawler 2>&1 | tail -30
        exit 1
    fi
    
    [ $i -eq 120 ] && die "Timeout"
    sleep 1
done

echo "✓ Complete!"
echo ""
echo "Output files:"
[ -f "$OUTPUT_DIR/${SCHEMA_NAME}-erd.png" ] && echo "  • PNG: $OUTPUT_DIR/${SCHEMA_NAME}-erd.png"
[ -f "$OUTPUT_DIR/${SCHEMA_NAME}-erd.svg" ] && echo "  • SVG: $OUTPUT_DIR/${SCHEMA_NAME}-erd.svg"
echo ""
