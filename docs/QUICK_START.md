# Quick Start Guide

> Get ERD diagrams from your Liquibase changelog in under 5 minutes

## 🚀 TL;DR

### Docker Method (Easiest)

```bash
# Clone and run
git clone https://github.com/dotbrains/liquibase-erd
cd liquibase-erd

# Quick diagrams
./run-schemacrawler.sh

# Or full documentation
./run-schemaspy.sh
```

### Kubernetes Method (Original)

```bash
# Clone and run
git clone https://github.com/dotbrains/liquibase-erd
cd liquibase-erd/schemacrawler-erd
./scripts/generate-erd.sh

# Or for full documentation
cd ../schemaspy-erd
./scripts/generate-erd.sh
```

## ⏱️ Prerequisites Check

### Docker Method

```bash
# Check you have Docker
docker --version           # Should show version
docker compose version     # Should show version
```

### Kubernetes Method

```bash
# Check you have everything
kubectl cluster-info        # Should connect
liquibase --version         # Should show version
kubectl get crd clusters.postgresql.cnpg.io  # Should exist
```

If any of these fail, see the main [README.md](../README.md) for setup instructions.

## 📝 Adapting for Your Project

### Docker Method

#### Option 1: Environment Variables (Quick)

```bash
export DB_NAME="mydatabase"
export SCHEMA_NAME="myschema"
export CHANGELOG_FILE="/workspace/path/to/changelog.xml"
export CHANGELOG_DIR="."
./run-schemacrawler.sh
```

#### Option 2: Config File (Recommended)

```bash
# Copy and edit config
cp config.example.sh config.sh
# Edit config.sh with your settings

# Run with config
./run-schemacrawler.sh  # or ./run-schemaspy.sh
```

### Kubernetes Method

#### Step 1: Pick Your Tool

**Want quick diagrams?** → Use `schemacrawler-erd/`  
**Want full documentation?** → Use `schemaspy-erd/`

#### Step 2: Update Configuration

Edit `scripts/generate-erd.sh` in your chosen directory:

```bash
# Line 6-13: Change these values
CLUSTER_NAME="your-project-erd-temp"
DB_NAME="your_database"
SCHEMA_NAME="your_schema"

# Line 76-79: Update changelog path
liquibase \
    --changeLogFile=path/to/your/changelog.xml \
    --url=offline:postgresql \
    updateSQL > "$OUTPUT_DIR/schema.sql"
```

### Step 3: Update Kubernetes Config

Edit `k8s/postgres-cluster.yaml`:

```yaml
# Line 4 and 14: Match your CLUSTER_NAME
name: your-project-erd-temp

# Line 22 and 23: Match your DB_NAME
database: your_database
owner: your_user
```

### Step 4: Update Job Config

**For SchemaCrawler** - Edit `k8s/schemacrawler-job.yaml`:
```yaml
# Line 29-33: Update connection details
--host=your-project-erd-temp-rw.default.svc.cluster.local
--database=your_database
--user=your_user
--schemas=your_schema
```

**For SchemaSpy** - Edit `k8s/schemaspy-job.yaml`:
```yaml
# Line 29-34: Update connection details
-host your-project-erd-temp-rw.default.svc.cluster.local
-db your_database
-u your_user
-s your_schema
```

### Step 5: Run It

```bash
./scripts/generate-erd.sh
```

## 📂 What You Get

### Docker Method

**SchemaCrawler Output:**
```
example/output/schemacrawler/
├── public-erd.png           # PNG diagram
├── public-erd.svg           # SVG diagram
└── liquibase-update.log     # Liquibase logs
```

**SchemaSpy Output:**
```
example/output/schemaspy/
├── public-erd.svg           # SVG diagram
├── liquibase-update.log     # Liquibase logs
└── html/
    └── index.html           # Start here!
```

### Kubernetes Method

**SchemaCrawler Output:**
```
schemacrawler-erd/output/
├── {schema}-erd.png    # PNG diagram
└── {schema}-erd.svg    # SVG diagram
```

**SchemaSpy Output:**
```
schemaspy-erd/output/
├── {schema}-erd.png         # PNG diagram
├── {schema}-erd.svg         # SVG diagram
└── html/
    └── index.html           # Start here!
```

## 🔧 Common Customizations

### Change Namespace

In all files, replace `default` with your namespace:

```bash
# scripts/generate-erd.sh
NAMESPACE="your-namespace"

# k8s/postgres-cluster.yaml
namespace: your-namespace

# k8s/schemacrawler-job.yaml or k8s/schemaspy-job.yaml
namespace: your-namespace
```

### Increase Resources

In `k8s/postgres-cluster.yaml`:

```yaml
resources:
  requests:
    memory: 1Gi      # Increase from 512Mi
    cpu: 200m        # Increase from 100m
```

### Change Diagram Detail

**SchemaCrawler** - In `k8s/schemacrawler-job.yaml`:
```bash
--info-level=standard  # Less detail (faster)
--info-level=maximum   # More detail (default)
```

**SchemaSpy** - In `k8s/schemaspy-job.yaml`:
```bash
-degree 1  # Show fewer relationships (faster)
-degree 2  # Show more relationships (default)
```

## ⏱️ Expected Runtime

- **First run**: ~2-3 minutes (downloads dependencies)
- **Subsequent runs**: ~1 minute (SchemaCrawler) or ~2 minutes (SchemaSpy)

## 🐛 Quick Troubleshooting

### Docker Method

#### "Container exits with code 1"
Check the container logs:
```bash
docker logs liquibase-erd-schemaspy-1
# or
docker logs liquibase-erd-schemacrawler-1
```

#### "No tables found in schema"
- Check your `CHANGELOG_FILE` path is correct
- Verify the changelog file exists and is valid
- Check `example/output/{tool}/liquibase-update.log` for errors

#### "Port already in use"
Another PostgreSQL instance is running:
```bash
docker compose down
# or change the port in docker-compose.yml
```

### Kubernetes Method

#### "kubectl: command not found"
Install kubectl and connect to your cluster.

#### "liquibase: command not found"
Install Liquibase or add it to your PATH.

#### "CloudNativePG operator not found"
Install the operator:
```bash
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml
```

#### "Cluster timeout"
Your cluster might be slow to start. Wait a bit and try again, or increase the timeout in `scripts/generate-erd.sh`.

#### Job keeps failing
Check pod logs:
```bash
kubectl logs -n default -l job-name=schemacrawler-erd
# or
kubectl logs -n default -l job-name=schemaspy-erd
```

## 📚 More Information

- [Full README](../README.md) - Complete documentation
- [Docker Guide](./DOCKER.md) - Detailed Docker setup
- [SchemaCrawler Guide](../schemacrawler-erd/README.md) - Detailed SchemaCrawler docs
- [SchemaSpy Guide](../schemaspy-erd/README.md) - Detailed SchemaSpy docs

## 💡 Tips

### Docker Method
- **Use config.sh** - Easier to manage than environment variables
- **Check output directory** - Files are in `example/output/{tool}/`
- **Review logs** - Check `liquibase-update.log` if something fails
- **Clean up** - Docker automatically removes containers after runs

### Kubernetes Method
- **Run locally first** - Test before adding to CI/CD
- **Cache downloads** - Keep the `schemacrawler/` and `schemaspy/` directories
- **Version control** - Commit your customized configs
- **Document changes** - Add a comment explaining your customizations
- **Test cleanup** - Ensure Kubernetes resources are removed after each run
