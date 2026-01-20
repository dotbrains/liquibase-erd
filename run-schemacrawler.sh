#!/bin/bash
# Wrapper for running SchemaCrawler with Docker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/shared/docker.sh" schemacrawler "$SCRIPT_DIR"
