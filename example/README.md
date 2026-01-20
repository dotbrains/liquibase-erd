# Example Demo

This directory contains a complete demo setup for both ERD generation tools using a sample e-commerce database schema.

## 📋 What's Included

### Sample Database Schema
`db/changelog.xml` - A Liquibase changelog defining an e-commerce database with:
- **Users** - Customer accounts
- **Products** - Product catalog
- **Orders** - Customer orders
- **Order Items** - Line items for orders
- **Addresses** - Shipping/billing addresses
- **Reviews** - Product reviews

This schema includes:
- 6 tables with relationships
- Primary keys and foreign keys
- Indexes for performance
- Timestamps and constraints

### Demo Scripts
- `run-schemacrawler.sh` - Generate PNG/SVG diagrams using SchemaCrawler
- `run-schemaspy.sh` - Generate interactive HTML documentation using SchemaSpy

## 🚀 Quick Start

### Prerequisites

These demo scripts use the main ERD generation tools, which require:

- **kubectl** - Connected to a Kubernetes cluster
- **Liquibase** - Installed and in your PATH
- **CloudNativePG operator** - Installed in your cluster

The demo scripts handle all configuration automatically - you just run them!

### Run SchemaCrawler Demo

```bash
cd example
chmod +x run-schemacrawler.sh
./run-schemacrawler.sh
```

**Output**: `output/schemacrawler/public-erd.png` and `public-erd.svg`

### Run SchemaSpy Demo

```bash
cd example
chmod +x run-schemaspy.sh
./run-schemaspy.sh
```

**Output**: 
- `output/schemaspy/html/index.html` - Interactive documentation
- `output/schemaspy/public-erd.png` - PNG diagram
- `output/schemaspy/public-erd.svg` - SVG diagram

## 📁 Directory Structure

```
example/
├── README.md                      # This file
├── db/
│   └── changelog.xml             # Sample Liquibase changelog
├── run-schemacrawler.sh          # SchemaCrawler demo script
├── run-schemaspy.sh              # SchemaSpy demo script
└── output/                       # Generated files (gitignored)
    ├── schemacrawler/            # SchemaCrawler output
    │   ├── public-erd.png
    │   └── public-erd.svg
    └── schemaspy/                # SchemaSpy output
        ├── html/
        ├── public-erd.png
        └── public-erd.svg
```

## 🎯 What the Demo Does

Both demo scripts:

1. **Configure** - Set up environment variables for the demo database
2. **Prompt** - Ask you to confirm before running
3. **Run the main tool** - Calls `../schemacrawler-erd/scripts/generate-erd.sh` or `../schemaspy-erd/scripts/generate-erd.sh`

The main tools then:

4. **Generate SQL** - Use Liquibase to generate SQL from the changelog
5. **Create Database** - Spin up a temporary PostgreSQL cluster in Kubernetes (via kubectl)
6. **Generate Diagrams** - Run the respective tool to create ERD documentation
7. **Cleanup** - Automatically remove Kubernetes resources
8. **Show Output** - Display where the generated files are located

> **Note**: The demo scripts are just thin wrappers that configure and call the main generation scripts with demo-specific settings.

## 🔧 Customization

### Modify the Schema

Edit `db/changelog.xml` to add or modify tables:

```xml
<changeSet id="7" author="demo">
    <createTable tableName="your_table">
        <column name="id" type="bigint" autoIncrement="true">
            <constraints primaryKey="true" nullable="false"/>
        </column>
        <!-- Add more columns -->
    </createTable>
</changeSet>
```

Then run the demo scripts again to see your changes.

### Change Configuration

Both demo scripts use these environment variables:

```bash
CHANGELOG_FILE="$SCRIPT_DIR/db/changelog.xml"
CLUSTER_NAME="demo-erd-temp"
DB_NAME="demo_ecommerce"
DB_USER="demo"
SCHEMA_NAME="public"
POSTGRES_PASSWORD="demo-password-$(date +%s)"
```

You can modify these in the scripts to customize the demo.

## 📊 Expected Output

### SchemaCrawler
- **Runtime**: ~1 minute
- **Files**: 2 (PNG + SVG)
- **Size**: ~100KB

### SchemaSpy
- **Runtime**: ~2-3 minutes
- **Files**: ~50+ (HTML site + diagrams)
- **Size**: ~2MB

## 🐛 Troubleshooting

### "kubectl: command not found"
Install kubectl and configure access to your Kubernetes cluster.

### "liquibase: command not found"
Install Liquibase: https://www.liquibase.org/download

### "CloudNativePG operator not found"
Install the operator:
```bash
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml
```

### Cleanup Resources Manually
If a demo fails and doesn't cleanup:
```bash
kubectl delete cluster demo-erd-temp -n default
kubectl delete secret demo-erd-temp-auth -n default
kubectl delete job schemacrawler-erd -n default
kubectl delete job schemaspy-erd -n default
```

## 🔗 Next Steps

After running the demo:

1. **View the output** - Compare both tools to see which fits your needs
2. **Try your own schema** - Replace `db/changelog.xml` with your Liquibase changelog
3. **Customize** - Modify the Kubernetes manifests in `../schemacrawler-erd/k8s/` or `../schemaspy-erd/k8s/`
4. **Integrate** - Add ERD generation to your CI/CD pipeline

## 💡 Tips

- **First run is slower** - Tools need to download dependencies
- **Cached runs are faster** - Subsequent runs reuse downloaded tools
- **View HTML locally** - SchemaSpy output works best when served via HTTP:
  ```bash
  cd output/schemaspy/html
  python3 -m http.server 8000
  # Open http://localhost:8000
  ```
- **Compare outputs** - Run both tools on the same schema to see differences

## 📚 Documentation

- [Main README](../README.md)
- [SchemaCrawler Documentation](../schemacrawler-erd/README.md)
- [SchemaSpy Documentation](../schemaspy-erd/README.md)
