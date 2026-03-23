# Liquibase ERD 💧

[![License: PolyForm Shield 1.0.0](https://img.shields.io/badge/License-PolyForm%20Shield%201.0.0-blue.svg)](https://polyformproject.org/licenses/shield/1.0.0/)

> Automated Entity-Relationship Diagram (ERD) generation from Liquibase changelogs using Kubernetes and PostgreSQL.

This repository contains two complementary tools for generating database ERD documentation from Liquibase changelogs. Both use a similar workflow: generating SQL from Liquibase in offline mode, spinning up a temporary PostgreSQL cluster, applying the schema, and reverse-engineering it into diagrams.

## 🎯 Quick Start

### Docker Method (Easiest!)

The simplest way to get started - no Kubernetes required:

```bash
# Clone this repository
git clone https://github.com/dotbrains/liquibase-erd
cd liquibase-erd

# Generate simple diagrams (SchemaCrawler)
./run-schemacrawler.sh

# Generate interactive HTML documentation (SchemaSpy)
./run-schemaspy.sh
```

Customize by creating a `config.sh` file:

```bash
cp config.example.sh config.sh
# Edit config.sh with your settings
./run-schemacrawler.sh
```

Or set environment variables directly:

```bash
export DB_NAME="mydatabase"
export SCHEMA_NAME="myschema"
export CHANGELOG_FILE="/workspace/path/to/changelog.xml"
export CHANGELOG_DIR="."
./run-schemacrawler.sh
```

### Kubernetes Method (Original)

If you prefer using Kubernetes:

```bash
# Clone this repository
git clone https://github.com/dotbrains/liquibase-erd
cd liquibase-erd

# Configure for your project (first time only)
cp config.example.sh config.sh
# Edit config.sh with your database details and changelog path

# Generate simple diagrams (SchemaCrawler)
cd schemacrawler-erd
source ../config.sh && ./scripts/generate-erd.sh

# Generate interactive HTML documentation (SchemaSpy)
cd ../schemaspy-erd
source ../config.sh && ./scripts/generate-erd.sh
```

## 📦 What's Included

### [SchemaCrawler](./schemacrawler-erd/) - Quick Diagrams
```
schemacrawler-erd/
├── scripts/generate-erd.sh    # Main script
├── k8s/                       # Kubernetes manifests
└── output/                    # Generated PNG/SVG
```
- **Runtime**: ~1 minute
- **Best for**: Quick reference diagrams, CI/CD pipelines

### [SchemaSpy](./schemaspy-erd/) - Interactive Documentation
```
schemaspy-erd/
├── scripts/generate-erd.sh    # Main script
├── k8s/                       # Kubernetes manifests
└── output/                    # Generated HTML + diagrams
```
- **Runtime**: ~2-3 minutes  
- **Best for**: Comprehensive documentation, onboarding

## 🔧 Prerequisites

### Docker Method (Recommended) 🐳

The easiest way to use these tools is with Docker. This works on any machine without additional dependencies:

- **Docker** - Install from [docker.com](https://www.docker.com/get-started)
- **Docker Compose** - Included with Docker Desktop, or install separately

That's it! All other dependencies (Liquibase, SchemaCrawler, SchemaSpy, PostgreSQL) are handled inside Docker containers.

📖 **See [docs/DOCKER.md](./docs/DOCKER.md) for detailed Docker setup guide and troubleshooting.**

### Kubernetes Method (Original)

For the Kubernetes-based approach, you'll need:

📖 **See [docs/KUBERNETES.md](./docs/KUBERNETES.md) for detailed Kubernetes setup guide and troubleshooting.**

- **kubectl** - Connected to a Kubernetes cluster
- **Liquibase** - Available in your PATH
- **CloudNativePG operator** - Installed in your cluster (`kubectl get crd clusters.postgresql.cnpg.io`)

Optional:
- **curl** or **wget** - For downloading dependencies (automatically detected)

## 📋 How It Works

### Docker Workflow

1. **Generate SQL** - Liquibase generates SQL from your changelog in offline mode (no database required)
2. **Spin up PostgreSQL** - Creates a temporary PostgreSQL container
3. **Apply Schema** - Populates the database with your schema
4. **Reverse Engineer** - Tool connects to the database and generates diagrams/documentation
5. **Cleanup** - Automatically removes all containers

### Kubernetes Workflow (Original)

1. **Generate SQL** - Liquibase generates SQL from your changelog in offline mode (no database required)
2. **Spin up PostgreSQL** - Creates a temporary CloudNativePG cluster in Kubernetes
3. **Apply Schema** - Populates the database with your schema
4. **Reverse Engineer** - Tool connects to the database and generates diagrams/documentation
5. **Cleanup** - Automatically removes all Kubernetes resources

## 🎨 Customization

### Adapting for Your Project

Both tools use environment variables for configuration, making them easy to customize without editing files.

#### Method 1: Using config.sh (Recommended)

1. Copy the example configuration:
   ```bash
   cp config.example.sh config.sh
   ```

2. Edit `config.sh` with your project details:
   ```bash
   export CLUSTER_NAME="myproject-erd-temp"
   export DB_NAME="mydatabase"
   export DB_USER="myuser"
   export SCHEMA_NAME="myschema"
   export CHANGELOG_FILE="path/to/your/changelog.xml"
   ```

3. Source the config before running:
   ```bash
   source config.sh
   cd schemacrawler-erd && ./scripts/generate-erd.sh
   ```

#### Method 2: Direct Environment Variables

Set variables inline:
```bash
CLUSTER_NAME="myproject-erd-temp" \
DB_NAME="mydatabase" \
DB_USER="myuser" \
SCHEMA_NAME="myschema" \
CHANGELOG_FILE="db/changelog.xml" \
./scripts/generate-erd.sh
```

#### Default Values

If not specified, these defaults are used:
- `CLUSTER_NAME`: `db-erd-temp`
- `NAMESPACE`: `default`
- `DB_NAME`: `mydb`
- `DB_USER`: `dbuser`
- `SCHEMA_NAME`: `public`
- `POSTGRES_PASSWORD`: `temp-password`
- `CHANGELOG_FILE`: `db/changelog.xml`

### Advanced Customization

#### Change Namespace
Default is `default`. To use a different namespace:

```bash
# In generate-erd.sh
NAMESPACE="your-namespace"

# In postgres-cluster.yaml
metadata:
  namespace: your-namespace

# In job YAML files
metadata:
  namespace: your-namespace
```

#### Adjust Resource Limits

In `postgres-cluster.yaml`:

```yaml
resources:
  requests:
    memory: 512Mi   # Increase for larger schemas
    cpu: 100m
  limits:
    memory: 1Gi     # Increase for larger schemas
    cpu: 500m
```

#### Change PostgreSQL Image

In `postgres-cluster.yaml`:

```yaml
imageName: ghcr.io/cloudnative-pg/postgresql:17
# Change to your preferred registry/version
```

## 📚 Documentation

Each tool has its own detailed README:

- [SchemaCrawler Documentation](./schemacrawler-erd/README.md) - Simple diagrams
- [SchemaSpy Documentation](./schemaspy-erd/README.md) - Interactive HTML docs

Setup guides:

- [Docker Setup Guide](./docs/DOCKER.md) - Docker-based deployment (recommended for local use)
- [Kubernetes Setup Guide](./docs/KUBERNETES.md) - Kubernetes-based deployment (recommended for production)
- [Quick Start Guide](./docs/QUICK_START.md) - Fast setup reference

## 🔍 Comparison

| Feature | SchemaCrawler | SchemaSpy |
|---------|---------------|-----------|
| Output Format | PNG, SVG | PNG, SVG, HTML |
| Runtime | ~1 minute | ~2-3 minutes |
| Output Size | ~2MB | ~50MB |
| Interactive | ❌ | ✅ |
| Metadata Tables | ❌ | ✅ |
| Search | ❌ | ✅ |
| Per-Table Views | ❌ | ✅ |
| Orphan Detection | ❌ | ✅ |
| Customization | Limited | Extensive |
| CI/CD Friendly | ✅ | ⚠️ (larger artifacts) |

## 🚀 Use Cases

### Use SchemaCrawler When:
- You need quick reference diagrams
- Output will be embedded in other documentation
- Running in CI/CD pipelines (faster)
- Storage/bandwidth is limited

### Use SchemaSpy When:
- Onboarding new team members
- Conducting architecture reviews
- Need comprehensive schema documentation
- Want to publish to GitLab Pages or similar
- Need to explore table relationships interactively

## 📝 License

This project is licensed under the [PolyForm Shield License 1.0.0](https://polyformproject.org/licenses/shield/1.0.0/) — see [LICENSE](LICENSE) for details.
## 🙏 Acknowledgments

- [SchemaCrawler](https://www.schemacrawler.com/) - Database schema discovery and comprehension
- [SchemaSpy](http://schemaspy.org/) - Document database schemas
- [CloudNativePG](https://cloudnative-pg.io/) - PostgreSQL on Kubernetes
- [Liquibase](https://www.liquibase.org/) - Database change management
