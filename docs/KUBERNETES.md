# Kubernetes Setup Guide

This guide explains how to use the Kubernetes-based ERD generation tools with CloudNativePG.

## Why Kubernetes?

The Kubernetes setup provides several benefits:

- ✅ **Production-Ready** - Uses CloudNativePG operator for robust PostgreSQL management
- ✅ **Scalable** - Leverages cluster resources
- ✅ **Isolated** - Temporary namespaces keep things clean
- ✅ **Enterprise-Friendly** - Works with air-gapped registries and corporate environments
- ✅ **Cloud-Native** - Fits naturally into existing K8s workflows

## Prerequisites

### Required

1. **kubectl** - Kubernetes command-line tool
   - Must be connected to a working Kubernetes cluster
   - Verify: `kubectl cluster-info`

2. **CloudNativePG Operator** - PostgreSQL operator for Kubernetes
   - Check if installed: `kubectl get crd clusters.postgresql.cnpg.io`
   - Install if needed: [CloudNativePG Installation](https://cloudnative-pg.io/documentation/current/installation_upgrade/)

3. **Liquibase** - Database schema change management tool
   - Must be available in your PATH
   - Verify: `liquibase --version`
   - Download: [Liquibase Downloads](https://www.liquibase.org/download)

### Optional

- **curl** or **wget** - For downloading dependencies (automatically detected)

## Quick Start

### Generate Diagrams (SchemaCrawler)

```bash
# Clone the repository
git clone https://github.com/dotbrains/liquibase-erd
cd liquibase-erd

# Configure for your project
cp config.example.sh config.sh
# Edit config.sh with your settings

# Generate diagrams
cd schemacrawler-erd
source ../config.sh && ./scripts/generate-erd.sh
```

### Generate Full Documentation (SchemaSpy)

```bash
# From the repository root
cd schemaspy-erd
source ../config.sh && ./scripts/generate-erd.sh
```

## Configuration

### Method 1: config.sh File (Recommended)

Create a configuration file:

```bash
cp config.example.sh config.sh
```

Edit `config.sh` with your project details:

```bash
# Kubernetes settings
export CLUSTER_NAME="myproject-erd-temp"
export NAMESPACE="default"

# Database settings
export DB_NAME="mydatabase"
export DB_USER="dbuser"
export SCHEMA_NAME="public"
export POSTGRES_PASSWORD="temp-password"

# Liquibase settings
export CHANGELOG_FILE="db/changelog.xml"
```

Then source the config before running:

```bash
source config.sh
cd schemacrawler-erd && ./scripts/generate-erd.sh
```

### Method 2: Environment Variables

Set variables inline:

```bash
CLUSTER_NAME="myproject-erd-temp" \
DB_NAME="mydatabase" \
DB_USER="myuser" \
SCHEMA_NAME="myschema" \
CHANGELOG_FILE="db/changelog.xml" \
./scripts/generate-erd.sh
```

### Default Values

If not specified, these defaults are used:

- `CLUSTER_NAME`: `db-erd-temp`
- `NAMESPACE`: `default`
- `DB_NAME`: `mydb`
- `DB_USER`: `dbuser`
- `SCHEMA_NAME`: `public`
- `POSTGRES_PASSWORD`: `temp-password`
- `CHANGELOG_FILE`: `db/changelog.xml`

## How It Works

1. **Generate SQL** - Liquibase generates SQL from your changelog in offline mode (no database required)
2. **Spin up PostgreSQL** - Creates a temporary CloudNativePG cluster in Kubernetes
3. **Apply Schema** - Populates the database with your schema
4. **Reverse Engineer** - Tool connects to the database and generates diagrams/documentation
5. **Cleanup** - Automatically removes all Kubernetes resources

## Advanced Configuration

### Using a Different Namespace

Default is `default`. To use a different namespace:

**In generate-erd.sh:**
```bash
NAMESPACE="your-namespace"
```

**In postgres-cluster.yaml:**
```yaml
metadata:
  namespace: your-namespace
```

**In job YAML files:**
```yaml
metadata:
  namespace: your-namespace
```

### Adjusting Resource Limits

For larger schemas, you may need to increase resources. Edit `postgres-cluster.yaml`:

```yaml
resources:
  requests:
    memory: 512Mi   # Increase for larger schemas
    cpu: 100m
  limits:
    memory: 1Gi     # Increase for larger schemas
    cpu: 500m
```

### Using Custom PostgreSQL Image

If you're in an air-gapped environment or using a custom registry, edit `postgres-cluster.yaml`:

```yaml
imageName: ghcr.io/cloudnative-pg/postgresql:17
# Change to your preferred registry/version
```

Common alternatives:
```yaml
# Standard Docker Hub
imageName: postgres:17

# Google Container Registry
imageName: gcr.io/my-project/postgresql:17

# AWS ECR
imageName: 123456789.dkr.ecr.us-east-1.amazonaws.com/postgresql:17
```

### Customizing Job Images

For SchemaCrawler or SchemaSpy jobs, edit the respective job YAML files:

**schemacrawler-job.yaml:**
```yaml
spec:
  template:
    spec:
      containers:
      - name: schemacrawler
        image: your-registry/schemacrawler:latest
```

**schemaspy-job.yaml:**
```yaml
spec:
  template:
    spec:
      containers:
      - name: schemaspy
        image: your-registry/schemaspy:latest
```

## Troubleshooting

### CloudNativePG Not Installed

**Error:**
```
error: the server doesn't have a resource type "clusters"
```

**Solution:**
```bash
# Install CloudNativePG operator
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml

# Verify installation
kubectl get crd clusters.postgresql.cnpg.io
```

### Cluster Won't Start

**Check cluster status:**
```bash
kubectl get cluster -n <namespace>
kubectl describe cluster <cluster-name> -n <namespace>
```

**Check pod logs:**
```bash
kubectl get pods -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Common issues:**
- Insufficient cluster resources (check resource requests/limits)
- Image pull errors (check registry access and credentials)
- Storage issues (check PersistentVolumeClaims)

### Job Failures

**Check job status:**
```bash
kubectl get jobs -n <namespace>
kubectl describe job <job-name> -n <namespace>
```

**View job logs:**
```bash
kubectl logs job/<job-name> -n <namespace>
```

**Common issues:**
- Database not ready (job started before PostgreSQL cluster was ready)
- Connection errors (check service names and ports)
- Permission errors (check RBAC settings)

### Changelog Not Found

Make sure:
1. `CHANGELOG_FILE` path is correct relative to where you run the script
2. Liquibase can access the file
3. The file contains valid Liquibase XML/YAML/JSON

**Test Liquibase access:**
```bash
liquibase --changeLogFile=$CHANGELOG_FILE validate
```

### Network Policies

If your cluster has strict network policies, you may need to allow:
- Job pods → PostgreSQL cluster pods (port 5432)
- PostgreSQL pods ↔ PostgreSQL pods (replication)

### Resource Quotas

If your namespace has resource quotas, ensure there's enough:
- CPU (minimum ~200m for cluster + job)
- Memory (minimum ~1Gi for cluster + job)
- Storage (minimum ~1Gi for PostgreSQL)

## CI/CD Integration

### GitLab CI

```yaml
generate-erd:
  image: liquibase/liquibase:latest
  stage: documentation
  before_script:
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl
    - mv kubectl /usr/local/bin/
  script:
    - export CLUSTER_NAME="ci-erd-${CI_PIPELINE_ID}"
    - cd schemacrawler-erd
    - ./scripts/generate-erd.sh
  artifacts:
    paths:
      - schemacrawler-erd/output/
    expire_in: 30 days
  only:
    - main
```

### GitHub Actions

```yaml
name: Generate ERD
on:
  push:
    branches: [main]

jobs:
  generate-erd:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        
      - name: Set up Liquibase
        run: |
          wget https://github.com/liquibase/liquibase/releases/download/v4.24.0/liquibase-4.24.0.tar.gz
          tar -xzf liquibase-4.24.0.tar.gz
          echo "$PWD/liquibase" >> $GITHUB_PATH
          
      - name: Generate ERD
        env:
          CLUSTER_NAME: ci-erd-${{ github.run_id }}
          KUBECONFIG: ${{ secrets.KUBECONFIG }}
        run: |
          cd schemacrawler-erd
          ./scripts/generate-erd.sh
          
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: erd-diagrams
          path: schemacrawler-erd/output/
```

## Comparison: Kubernetes vs Docker

| Feature | Kubernetes | Docker |
|---------|------------|--------|
| Prerequisites | kubectl, CloudNativePG, Liquibase | Docker only |
| Setup Time | 5-10 minutes | < 1 minute |
| Works Offline | No | Yes (after first build) |
| Portable | Requires K8s cluster | All platforms |
| CI/CD | Complex | Easy |
| Production Use | Scalable | Demo/local only |
| Resource Management | Advanced (quotas, limits, requests) | Basic |
| High Availability | Yes (CloudNativePG) | No |

## Best Practices

1. **Use Temporary Namespaces** - Create dedicated namespaces for ERD generation to avoid conflicts
2. **Set Resource Limits** - Prevent runaway jobs from consuming cluster resources
3. **Clean Up** - Always run cleanup commands even if generation fails
4. **Use Unique Names** - Include timestamps or IDs in cluster names (e.g., `erd-${CI_PIPELINE_ID}`)
5. **Monitor Resources** - Watch cluster resource usage during generation
6. **Version Pin Images** - Use specific image versions rather than `latest` tags

## Security Considerations

1. **Temporary Credentials** - Use short-lived passwords for temporary clusters
2. **RBAC** - Ensure jobs have minimal necessary permissions
3. **Network Isolation** - Use NetworkPolicies to restrict database access
4. **Image Security** - Scan container images for vulnerabilities
5. **Secrets Management** - Use Kubernetes Secrets for sensitive data (never commit passwords)

## Next Steps

- Review [SchemaCrawler Documentation](../schemacrawler-erd/README.md) for SchemaCrawler-specific options
- Review [SchemaSpy Documentation](../schemaspy-erd/README.md) for SchemaSpy-specific options
- Check [DOCKER.md](./DOCKER.md) for the simpler Docker-based alternative
- Explore [QUICK_START.md](./QUICK_START.md) for rapid setup guide
