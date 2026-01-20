# SchemaCrawler ERD Generator

> Fast, simple ERD diagram generation using [SchemaCrawler](https://www.schemacrawler.com/)

## Overview

This tool generates PNG and SVG diagrams of your database schema. It's designed for speed and simplicity - perfect for quick reference diagrams or embedding in documentation.

## 🎯 Quick Start

```bash
cd schemacrawler-erd

# Option 1: Use config file (recommended)
source ../config.sh && ./scripts/generate-erd.sh

# Option 2: Set environment variables
export CHANGELOG_FILE="path/to/changelog.xml"
export SCHEMA_NAME="myschema"
./scripts/generate-erd.sh
```

Output files will be in `output/`:
- `output/{schema-name}-erd.png` - PNG diagram
- `output/{schema-name}-erd.svg` - SVG diagram

## 📁 Project Structure

```
schemacrawler-erd/
├── scripts/
│   └── generate-erd.sh          # Main generation script
├── k8s/
│   ├── postgres-cluster.yaml    # CloudNativePG cluster definition
│   ├── postgres-values.yaml     # (Optional) Helm values reference
│   └── schemacrawler-job.yaml   # Kubernetes job for diagram generation
├── output/                      # Generated diagrams (gitignored)
└── schemacrawler/              # Downloaded tools (gitignored)
```

## 🔧 Prerequisites

- **kubectl** - Connected to a Kubernetes cluster
- **Liquibase** - For generating SQL from changelog
- **CloudNativePG operator** - Installed in your cluster
- **curl** or **wget** - For downloading SchemaCrawler (automatic)

## 📋 How It Works

1. **Download SchemaCrawler** (first run only)
   - Downloads v16.21.2 from GitHub releases
   - Cached in `schemacrawler/` directory for subsequent runs

2. **Generate SQL**
   - Uses Liquibase offline mode to generate SQL
   - No database connection required at this stage

3. **Start PostgreSQL**
   - Creates temporary CloudNativePG cluster in Kubernetes
   - Single instance, minimal resources (512Mi RAM, 100m CPU)

4. **Populate Schema**
   - Creates the schema
   - Applies the generated SQL

5. **Generate Diagrams**
   - Runs SchemaCrawler in a Kubernetes job
   - Connects to PostgreSQL and reverse-engineers the schema
   - Generates PNG and SVG outputs

6. **Cleanup**
   - Automatically removes all Kubernetes resources
   - Cleans up temporary files

## ⚙️ Configuration

### Basic Configuration

The script uses environment variables with sensible defaults:

```bash
# Required
export CHANGELOG_FILE="path/to/changelog.xml"  # Path to Liquibase changelog

# Optional (defaults shown)
export CLUSTER_NAME="db-erd-temp"              # Kubernetes cluster name
export NAMESPACE="default"                     # Kubernetes namespace
export DB_NAME="mydb"                          # Database name
export DB_USER="dbuser"                        # Database user
export SCHEMA_NAME="public"                    # Schema to document
export POSTGRES_PASSWORD="temp-password"       # Temporary password
```

### Setting Changelog Path

Set the `CHANGELOG_FILE` environment variable:

```bash
export CHANGELOG_FILE="db/migration/changelog.xml"
./scripts/generate-erd.sh
```

Or use a config file (recommended for complex projects).

### Kubernetes Resources (Optional)

The default `k8s/postgres-cluster.yaml` uses generic values that work with environment variables. Only edit if you need custom PostgreSQL settings.

Defaults:
```yaml
metadata:
  name: db-erd-temp
  namespace: default

bootstrap:
  initdb:
    database: mydb
    owner: dbuser
```

### SchemaCrawler Options (Optional)

The default `k8s/schemacrawler-job.yaml` uses generic values. Only edit if you need custom diagram settings.

Defaults:
```yaml
# Connection (uses environment defaults)
--host=db-erd-temp-rw.default.svc.cluster.local
--database=mydb
--user=dbuser
--schemas=public

# Diagram settings (customize these)
--info-level=maximum              # Detail level: minimum, standard, detailed, maximum
--weak-associations               # Show inferred relationships
--portable-names                  # Use portable naming
```

#### Info Levels

- `minimum` - Just tables and columns
- `standard` - Adds foreign keys
- `detailed` - Adds indexes and constraints
- `maximum` - Everything including check constraints

### Resource Limits

Adjust PostgreSQL resources in `k8s/postgres-cluster.yaml`:

```yaml
resources:
  requests:
    memory: 512Mi   # Minimum memory
    cpu: 100m       # Minimum CPU
  limits:
    memory: 1Gi     # Maximum memory
    cpu: 500m       # Maximum CPU
```

Increase for larger schemas or faster processing.

## 📊 Output

### PNG Diagram
- Located at `output/{schema-name}-erd.png`
- Good for presentations, documentation, wikis
- Default size is optimized for readability

### SVG Diagram
- Located at `output/{schema-name}-erd.svg`
- Scalable vector format
- Best for web pages and high-quality prints
- Can be opened in browsers or editors like Inkscape

## 🚀 Advanced Usage

### Running in CI/CD

```yaml
# GitLab CI example
generate-erd:
  image: your-base-image-with-kubectl-and-liquibase
  script:
    - cd schemacrawler-erd
    - ./scripts/generate-erd.sh
  artifacts:
    paths:
      - schemacrawler-erd/output/*.png
      - schemacrawler-erd/output/*.svg
    expire_in: 30 days
```

### Customizing Diagram Appearance

SchemaCrawler uses Graphviz for rendering. You can customize appearance by modifying the job args in `k8s/schemacrawler-job.yaml`:

```bash
# Add Graphviz options
java -cp "lib/*" schemacrawler.Main \
  ... existing options ... \
  -Dschemacrawler.graph.graphviz_opts="-Gdpi=300 -Gsize=20,20"
```

### Multiple Schemas

To document multiple schemas, modify the job command:

```bash
--schemas=schema1,schema2,schema3
```

## 🐛 Troubleshooting

### "SchemaCrawler timeout"

The job takes longer than expected. Increase timeout in `generate-erd.sh`:

```bash
for i in $(seq 1 240); do  # Increase from 120 to 240
```

### "Cannot connect to database"

Check that:
1. CloudNativePG cluster is running: `kubectl get cluster -n default`
2. Pod is healthy: `kubectl get pods -n default -l cnpg.io/cluster=db-erd-temp`
3. Firewall/network policies allow communication

### "Failed to apply SQL"

Check `output/sql-apply.log` for errors:

```bash
cat output/sql-apply.log
```

Common issues:
- Invalid SQL syntax in Liquibase output
- Missing schema definitions
- Duplicate object errors

### "PNG/SVG copy failed"

The files might not have been generated. Check pod logs:

```bash
kubectl logs -n default -l job-name=schemacrawler-erd
```

### Download Failures

If automatic download fails:

1. Manually download SchemaCrawler:
```bash
cd schemacrawler-erd
mkdir -p schemacrawler
cd schemacrawler
wget https://github.com/schemacrawler/SchemaCrawler/releases/download/v16.21.2/schemacrawler-16.21.2-bin.zip
unzip schemacrawler-16.21.2-bin.zip
```

2. Run the script again

## 🔍 Output Details

### What's Included in Diagrams

- **Tables** - All tables in the schema
- **Columns** - Column names and types
- **Primary Keys** - Highlighted
- **Foreign Keys** - Shown as arrows
- **Weak Associations** - Inferred relationships (dashed lines)
- **Indexes** - Shown with info-level=maximum

### What's NOT Included

- No HTML documentation (use SchemaSpy for that)
- No metadata tables
- No row counts
- No interactive features

## 📈 Performance

Typical runtime breakdown:

- Download (first run only): 10-20 seconds
- SQL generation: 5-10 seconds
- PostgreSQL startup: 30-40 seconds
- Schema population: 5-10 seconds
- Diagram generation: 20-30 seconds
- **Total**: ~1 minute (after first run)

## 🔗 Related Tools

- **[SchemaSpy](../schemaspy-erd/)** - For interactive HTML documentation
- **[SchemaCrawler Docs](https://www.schemacrawler.com/)** - Official documentation

## 📝 Example Output

```bash
=== SchemaCrawler ERD Generator ===

✓ SchemaCrawler 16.21.2 ready
📝 Generating SQL from Liquibase...
☘️  Starting PostgreSQL CNPG cluster...
   Waiting for cluster...
📊 Populating schema...
🎨 Generating ERD diagrams...
✓ Complete!

Output files:
  • PNG: /path/to/output/public-erd.png
  • SVG: /path/to/output/public-erd.svg
```

## 🤝 Contributing

Found a bug or have a suggestion? Please open an issue in the main repository.

## 📚 Additional Resources

- [SchemaCrawler Official Site](https://www.schemacrawler.com/)
- [SchemaCrawler GitHub](https://github.com/schemacrawler/SchemaCrawler)
- [CloudNativePG Documentation](https://cloudnative-pg.io/)
- [Graphviz Documentation](https://graphviz.org/)
