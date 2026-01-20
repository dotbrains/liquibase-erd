# Docker Setup Guide

This guide explains how to use the Docker-based ERD generation tools.

## Why Docker?

The Docker setup provides several benefits:

- ✅ **No Kubernetes Required** - Works on any machine with Docker
- ✅ **No Local Dependencies** - All tools bundled in containers
- ✅ **Portable** - Same experience across macOS, Linux, and Windows
- ✅ **Simple** - Just install Docker and run
- ✅ **Fast Setup** - No need to install Liquibase, Java, PostgreSQL, etc.

## Prerequisites

Install Docker Desktop (includes Docker Compose):
- **macOS/Windows**: Download from [docker.com](https://www.docker.com/get-started)
- **Linux**: Install Docker and Docker Compose from your package manager

## Quick Start

### Generate Diagrams (SchemaCrawler)

```bash
# Simple - uses defaults
./docker-run-schemacrawler.sh

# With custom configuration
export DB_NAME="mydatabase"
export SCHEMA_NAME="myschema"
export CHANGELOG_FILE="/workspace/db/changelog.xml"
./docker-run-schemacrawler.sh
```

### Generate Full Documentation (SchemaSpy)

```bash
# Simple - uses defaults
./docker-run-schemaspy.sh

# With custom configuration
export DB_NAME="mydatabase"
export SCHEMA_NAME="myschema"
export CHANGELOG_FILE="/workspace/db/changelog.xml"
./docker-run-schemaspy.sh
```

## Configuration

### Method 1: Environment Variables

Set these before running:

```bash
export DB_NAME="mydatabase"           # Database name
export DB_USER="dbuser"               # Database user
export SCHEMA_NAME="public"           # Schema to document
export CHANGELOG_FILE="/workspace/db/changelog.xml"  # Path inside container
export CHANGELOG_DIR="."              # Local directory to mount
export OUTPUT_DIR="./output"          # Where to save results
```

### Method 2: config.sh File

Create a `config.sh` file:

```bash
cp config.example.sh config.sh
# Edit config.sh with your settings
```

Then run:

```bash
./docker-run-schemacrawler.sh  # Automatically loads config.sh
```

### Method 3: Direct docker-compose

For more control:

```bash
# SchemaCrawler
docker-compose --profile schemacrawler up --build

# SchemaSpy
docker-compose --profile schemaspy up --build

# Cleanup
docker-compose down
```

## How It Works

1. **Build Phase**: Docker builds containers with all dependencies
2. **PostgreSQL**: Temporary PostgreSQL container starts
3. **Liquibase**: Generates SQL from your changelog (offline mode)
4. **Apply Schema**: SQL is applied to PostgreSQL
5. **Generate ERDs**: Tool reverse-engineers database and creates diagrams
6. **Cleanup**: All containers are removed

## File Paths

### CHANGELOG_FILE

This is the path **inside the Docker container** (always starts with `/workspace/`):

```bash
export CHANGELOG_FILE="/workspace/db/changelog.xml"
export CHANGELOG_FILE="/workspace/example/db/changelog.xml"
```

### CHANGELOG_DIR

This is the **local directory** on your machine that gets mounted to `/workspace/`:

```bash
export CHANGELOG_DIR="."              # Current directory
export CHANGELOG_DIR="/path/to/project"  # Absolute path
```

### OUTPUT_DIR

Where generated files are saved on your machine:

```bash
export OUTPUT_DIR="./schemacrawler-erd/output"  # Default for SchemaCrawler
export OUTPUT_DIR="./schemaspy-erd/output"      # Default for SchemaSpy
```

## Examples

### Example 1: Simple Project

Your project structure:
```
my-project/
├── db/
│   └── changelog.xml
└── liquibase-erd/  (this repo)
```

Run from `liquibase-erd/`:
```bash
export CHANGELOG_DIR="../my-project"
export CHANGELOG_FILE="/workspace/db/changelog.xml"
./docker-run-schemacrawler.sh
```

### Example 2: Monorepo

Your project structure:
```
monorepo/
├── backend/
│   └── db/
│       └── changelog.xml
└── tools/
    └── liquibase-erd/  (this repo)
```

Run from `liquibase-erd/`:
```bash
export CHANGELOG_DIR="../../"
export CHANGELOG_FILE="/workspace/backend/db/changelog.xml"
./docker-run-schemacrawler.sh
```

### Example 3: Demo

Try the included example:

```bash
cd example
./run-schemacrawler.sh
# Or
./run-schemaspy.sh
```

## Troubleshooting

### "Changelog file not found"

Make sure:
1. `CHANGELOG_DIR` points to the directory containing your changelog
2. `CHANGELOG_FILE` path is relative to `/workspace/` (the mounted directory)

Example:
```bash
# If your changelog is at: /Users/you/project/db/changelog.xml
export CHANGELOG_DIR="/Users/you/project"
export CHANGELOG_FILE="/workspace/db/changelog.xml"
```

### "Cannot connect to Docker daemon"

- Make sure Docker Desktop is running
- On Linux: `sudo systemctl start docker`

### Permission Issues

If output files are owned by root:
```bash
# Linux only - add yourself to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Slow Build Times

First build downloads all dependencies (~500MB). Subsequent builds are much faster thanks to Docker caching.

To rebuild from scratch:
```bash
docker-compose build --no-cache
```

## Advanced Usage

### Custom PostgreSQL Version

Edit `docker-compose.yml`:
```yaml
postgres:
  image: postgres:16-alpine  # Change version here
```

### Custom Tool Versions

Edit the Dockerfiles:
- `schemacrawler-erd/Dockerfile` - Change `SCHEMACRAWLER_VERSION`
- `schemaspy-erd/Dockerfile` - Change `SCHEMASPY_VERSION`
- Both files - Change `LIQUIBASE_VERSION`

### Running in CI/CD

```bash
# GitLab CI / GitHub Actions
docker-compose --profile schemacrawler up --build --abort-on-container-exit
docker-compose down

# Upload artifacts
# (diagram files are in output directories)
```

## Comparison: Docker vs Kubernetes

| Feature | Docker | Kubernetes |
|---------|--------|------------|
| Prerequisites | Docker only | kubectl, CloudNativePG, Liquibase |
| Setup Time | < 1 minute | 5-10 minutes |
| Works Offline | Yes (after first build) | No |
| Portable | All platforms | Requires K8s cluster |
| CI/CD | Easy | Complex |
| Production Use | Demo/local only | Scalable |
