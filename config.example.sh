#!/bin/bash
# Configuration Example
# Copy this file to config.sh and customize for your project
# Then source it before running: source config.sh && ./generate-erd.sh

# Database configuration
export CLUSTER_NAME="myproject-erd-temp"
export NAMESPACE="default"
export DB_NAME="mydatabase"
export DB_USER="myuser"
export SCHEMA_NAME="myschema"
export POSTGRES_PASSWORD="temp-password-$(date +%s)"  # Unique password per run

# Liquibase configuration
# Absolute path or relative to where you run the script
export CHANGELOG_FILE="/path/to/your/db/changelog.xml"

# Example for Shield project:
# export CLUSTER_NAME="shield-erd-temp"
# export DB_NAME="shield"
# export DB_USER="shield"
# export SCHEMA_NAME="orchestrator"
# export CHANGELOG_FILE="js/db/orchestrator/migration/changelog.orchestrator.xml"
