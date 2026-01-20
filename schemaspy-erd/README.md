# SchemaSpy ERD Generator

> Comprehensive database documentation with interactive HTML using [SchemaSpy](http://schemaspy.org/)

## Overview

This tool generates a complete interactive HTML website documenting your database schema, including ER diagrams, table details, relationship graphs, and searchable metadata. Perfect for onboarding, architecture discussions, and comprehensive documentation.

## 🎯 Quick Start

```bash
cd schemaspy-erd

# Option 1: Use config file (recommended)
source ../config.sh && ./scripts/generate-erd.sh

# Option 2: Set environment variables
export CHANGELOG_FILE="path/to/changelog.xml"
export SCHEMA_NAME="myschema"
./scripts/generate-erd.sh
```

Output files will be in `output/`:
- `output/{schema-name}-erd.png` - PNG diagram (extracted from HTML)
- `output/{schema-name}-erd.svg` - SVG diagram (extracted from HTML)
- `output/html/index.html` - Interactive HTML documentation (main entry point)

Open `output/html/index.html` in a web browser to explore the documentation.

## 📁 Project Structure

```
schemaspy-erd/
├── scripts/
│   └── generate-erd.sh       # Main generation script
├── k8s/
│   ├── postgres-cluster.yaml # CloudNativePG cluster definition
│   └── schemaspy-job.yaml    # Kubernetes job for documentation generation
├── output/                   # Generated documentation (gitignored)
└── schemaspy/               # Downloaded tools (gitignored)
```

## 🔧 Prerequisites

- **kubectl** - Connected to a Kubernetes cluster
- **Liquibase** - For generating SQL from changelog
- **CloudNativePG operator** - Installed in your cluster
- **curl** or **wget** - For downloading SchemaSpy (automatic)

## 📋 How It Works

1. **Download Dependencies** (first run only)
   - Downloads SchemaSpy v6.2.4 JAR
   - Downloads PostgreSQL JDBC driver
   - Cached in `schemaspy/` directory for subsequent runs

2. **Generate SQL**
   - Uses Liquibase offline mode to generate SQL
   - No database connection required at this stage

3. **Start PostgreSQL**
   - Creates temporary CloudNativePG cluster in Kubernetes
   - Single instance, minimal resources (512Mi RAM, 100m CPU)

4. **Populate Schema**
   - Creates the schema
   - Applies the generated SQL

5. **Generate Documentation**
   - Runs SchemaSpy in a Kubernetes job
   - Connects to PostgreSQL and reverse-engineers the schema
   - Generates interactive HTML, diagrams, and metadata

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

### SchemaSpy Options (Optional)

The default `k8s/schemaspy-job.yaml` uses generic values. Only edit if you need custom documentation settings.

Defaults:
```yaml
# Connection (uses environment defaults)
-host db-erd-temp-rw.default.svc.cluster.local
-db mydb
-u dbuser
-s public

# Output options (customize these)
-o /output                  # Output directory
-noimplied                  # Don't show implied relationships
-norows                     # Don't show row counts (faster)
-vizjs                      # Use viz.js for rendering (no Graphviz needed)
```

#### Common Options

- `-noimplied` - Only show explicit foreign key relationships
- `-norows` - Skip row count queries (faster, but no data stats)
- `-vizjs` - Use JavaScript-based rendering (recommended)
- `-degree 2` - Maximum relationship depth to show
- `-renderer :cairo` - Use Cairo renderer (higher quality)

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

### HTML Documentation

The main output is a comprehensive website at `output/html/index.html` with:

#### Main Pages
- **Index** - Overview with summary statistics
- **Tables** - List of all tables with details
- **Columns** - Searchable column index
- **Relationships** - Interactive relationship diagrams
- **Orphans** - Tables without foreign key relationships
- **Anomalies** - Potential schema issues

#### Per-Table Pages
Each table gets its own page with:
- Column definitions and types
- Primary and foreign keys
- Indexes and constraints
- Parent/child relationships
- Table diagram showing immediate relationships

#### Diagrams
- **Summary diagram** - All tables and relationships
- **Table diagrams** - Per-table relationship views
- **PNG exports** - Static images extracted to output root

### Extracted Diagrams

For convenience, the main ER diagram is extracted:
- `output/{schema-name}-erd.png` - High-resolution PNG
- `output/{schema-name}-erd.svg` - Scalable SVG

## 🚀 Advanced Usage

### Publishing to GitLab Pages

```yaml
# .gitlab-ci.yml
pages:
  image: your-base-image-with-kubectl-and-liquibase
  script:
    - cd schemaspy-erd
    - ./generate-erd.sh
    - mv output/html ../public
  artifacts:
    paths:
      - public
  only:
    - main
```

Your documentation will be available at `https://yourusername.gitlab.io/yourproject/`.

### Local Web Server

To view the documentation with all features enabled:

```bash
# Python 3
cd output/html
python3 -m http.server 8000

# Or Node.js
npx http-server output/html -p 8000
```

Then open `http://localhost:8000` in your browser.

### Including Row Counts

Remove `-norows` from `schemaspy-job.yaml` to include row statistics. Note: this makes generation slower.

### Multiple Schemas

To document multiple schemas, run the tool once per schema or modify the job to generate all at once:

```bash
# In schemaspy-job.yaml, change:
-s public

# To:
-all  # Document all schemas
```

## 🐛 Troubleshooting

### "SchemaSpy timeout"

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

### "HTML copy failed"

Check pod logs for generation errors:

```bash
kubectl logs -n default -l job-name=schemaspy-erd
```

Common issues:
- SchemaSpy crashed during generation
- Out of memory (increase resource limits)
- Invalid schema structure

### Download Failures

If automatic download fails:

1. Manually download dependencies:
```bash
cd schemaspy-erd
mkdir -p schemaspy
cd schemaspy
wget https://github.com/schemaspy/schemaspy/releases/download/v6.2.4/schemaspy-6.2.4.jar
wget https://jdbc.postgresql.org/download/postgresql-42.7.1.jar
```

2. Run the script again

### Large Schemas

For very large schemas (100+ tables):
1. Increase PostgreSQL memory limits
2. Use `-degree 1` to reduce relationship depth
3. Consider splitting into multiple schema runs
4. Increase job timeout

## 🔍 Output Details

### What's Included

- **Tables** - All table definitions
- **Columns** - Full column metadata
- **Primary Keys** - Highlighted in diagrams
- **Foreign Keys** - Shown as relationships
- **Indexes** - Listed per table
- **Constraints** - Check constraints, unique constraints
- **Views** - If present in schema
- **Comments** - Table and column comments from database
- **Orphan Tables** - Tables without relationships
- **Anomalies** - Potential schema issues

### What's NOT Included (with `-norows`)

- Row counts per table
- Data samples
- Actual data values

To include these, remove `-norows` from the SchemaSpy job configuration.

## 📈 Performance

Typical runtime breakdown:

- Download (first run only): 5-10 seconds
- SQL generation: 5-10 seconds
- PostgreSQL startup: 30-40 seconds
- Schema population: 5-10 seconds
- Documentation generation: 60-90 seconds
- **Total**: ~2-3 minutes (after first run)

With `-norows` enabled, add 30-60 seconds for row count queries.

## 🎨 Customizing Output

### Custom CSS

Add custom styling by creating a CSS file and mounting it:

1. Create `custom.css`
2. Mount it in the job
3. Reference it in SchemaSpy options:

```yaml
-css custom.css
```

### Custom Logo

Add your organization's logo:

```yaml
-imageformat png
-logo /path/to/logo.png
```

### Custom Metadata

Add descriptions to tables and columns in your database:

```sql
COMMENT ON TABLE my_table IS 'Description of what this table stores';
COMMENT ON COLUMN my_table.my_column IS 'What this column represents';
```

SchemaSpy will automatically include these in the documentation.

## 🔗 Related Tools

- **[SchemaCrawler](../schemacrawler-erd/)** - For quick diagram generation
- **[SchemaSpy Docs](http://schemaspy.org/)** - Official documentation
- **[SchemaSpy GitHub](https://github.com/schemaspy/schemaspy)** - Source code and issues

## 📝 Example Output

```bash
=== SchemaSpy ERD Generator ===

✓ SchemaSpy 6.2.4 ready
📝 Generating SQL from Liquibase...
☘️  Starting PostgreSQL CNPG cluster...
   Waiting for cluster...
📊 Populating schema...
🎨 Generating ERD diagrams...
   ✓ HTML docs copied
✓ Complete!

Output files:
  • PNG: /path/to/output/public-erd.png
  • SVG: /path/to/output/public-erd.svg
  • HTML: /path/to/output/html/index.html
```

## 🌐 Publishing Options

### GitLab Pages
- Push HTML to `public/` directory
- Enable GitLab Pages in project settings
- Documentation auto-updates on commits

### GitHub Pages
- Push HTML to `docs/` directory
- Enable GitHub Pages in repository settings
- Choose `docs/` as source

### Internal Wiki
- Copy HTML files to your wiki hosting
- Update internal links if needed
- Consider adding authentication

### Confluence/SharePoint
- Generate documentation locally
- Upload HTML as attachments
- Embed index.html in page

## 🤝 Contributing

Found a bug or have a suggestion? Please open an issue in the main repository.

## 📚 Additional Resources

- [SchemaSpy Official Site](http://schemaspy.org/)
- [SchemaSpy GitHub](https://github.com/schemaspy/schemaspy)
- [SchemaSpy Wiki](https://github.com/schemaspy/schemaspy/wiki)
- [CloudNativePG Documentation](https://cloudnative-pg.io/)
- [PostgreSQL JDBC Driver](https://jdbc.postgresql.org/)
