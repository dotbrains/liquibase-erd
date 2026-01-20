#!/bin/bash
# Wrapper for running SchemaSpy with Docker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/shared/docker.sh" schemaspy "$SCRIPT_DIR"
