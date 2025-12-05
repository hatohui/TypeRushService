# Step 05: Secrets Manager

## Status: COMPLETED

**Completed on:** 2025-11-23

## Terraform Module: `modules/14-secrets-manager`

## Overview

Create AWS Secrets Manager secrets for RDS database credentials and ElastiCache Redis AUTH token using Terraform random provider for secure password generation.

## Architecture Reference

From `architecture-diagram.md`:

- Secrets Manager: $0.80/month (2 secrets × $0.40)
- Secrets accessed via VPC endpoints (private, no NAT cost)
- ECS and Lambda retrieve secrets at startup

## Components to Implement

### 1. Random Password Generation

- [ ] Use Terraform `random_password` resource
- [ ] RDS password: 32 characters, special chars, no quotes
- [ ] Redis AUTH token: 64 characters, alphanumeric only
- [ ] Store in Terraform state (encrypted by Terraform Cloud)

### 2. RDS Database Credentials Secret

- [ ] **Secret Name**: `typerush/record-db/credentials`
- [ ] **Secret Content** (JSON):
  ```json
  {
    "username": "typerush_admin",
    "password": "<random_32_char>",
    "engine": "postgres",
    "host": "<rds_endpoint>",
    "port": 5432,
    "dbname": "typerush_records",
    "dbClusterIdentifier": "<rds_instance_id>"
  }
  ```
- [ ] **Recovery Window**: 7 days (for dev, can be 0 for immediate deletion)
- [ ] **Rotation**: Disabled in dev (enable in production)
- [ ] **KMS Encryption**: Use default aws/secretsmanager key (free)
- [ ] **Tags**: Project, Environment, Purpose

### 3. ElastiCache Redis AUTH Token Secret

- [ ] **Secret Name**: `typerush/elasticache/auth-token`
- [ ] **Secret Content** (JSON):
  ```json
  {
    "auth_token": "<random_64_char>",
    "endpoint": "<redis_endpoint>",
    "port": 6379
  }
  ```
- [ ] **Recovery Window**: 7 days
- [ ] **Rotation**: Not applicable for ElastiCache (manual rotation)
- [ ] **KMS Encryption**: Use default aws/secretsmanager key
- [ ] **Tags**: Project, Environment, Purpose

### 4. Secret Policies

- [ ] No resource policies needed (IAM roles control access)
- [ ] ECS Task Execution Role can read both secrets
- [ ] Game Service Task Role can read ElastiCache secret
- [ ] Record Service Lambda Role can read RDS secret

## Implementation Details

### Random Provider Configuration

```hcl
resource "random_password" "rds_password" {
  length  = 32
  special = true
  # Exclude problematic characters for PostgreSQL
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "redis_auth_token" {
  length  = 64
  special = false  # ElastiCache requires alphanumeric only
  upper   = true
  lower   = true
  numeric = true
}
```

### Secret Creation Pattern

```hcl
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project_name}/record-db/credentials"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-rds-credentials"
      Purpose = "RDS PostgreSQL connection credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username            = "typerush_admin"
    password            = random_password.rds_password.result
    engine              = "postgres"
    host                = var.rds_endpoint
    port                = 5432
    dbname              = "typerush_records"
    dbClusterIdentifier = var.rds_instance_id
  })
}
```

## Module Structure

```
modules/14-secrets-manager/
├── main.tf       # Random passwords and secrets
├── variables.tf  # RDS/ElastiCache endpoints (from other modules)
└── outputs.tf    # Secret ARNs
```

## Dependencies

- **Required Before**: RDS and ElastiCache modules (need endpoints)
- **Alternative**: Create secrets with placeholder endpoints, update later
- **Recommended**: Create secrets early, update with `depends_on` after RDS/ElastiCache

## Deployment Order Options

### Option A: Create Secrets First (Recommended for Dev)

```powershell
# Create secrets with placeholder values
terraform apply -target=module.secrets

# Deploy RDS and ElastiCache
terraform apply -target=module.rds -target=module.elasticache

# Update secrets with actual endpoints (will trigger RDS/ElastiCache recreation to use new passwords)
terraform apply
```

### Option B: Deploy Data Layer First

```powershell
# Deploy RDS and ElastiCache without secrets (use default passwords)
terraform apply -target=module.rds -target=module.elasticache

# Create secrets with actual endpoints
terraform apply -target=module.secrets

# Update RDS and ElastiCache to use secrets (will trigger password rotation)
terraform apply
```

## Validation Commands

```powershell
# List secrets
aws secretsmanager list-secrets --filters Key=name,Values=typerush

# Get secret value (WARNING: Displays password!)
aws secretsmanager get-secret-value --secret-id typerush/record-db/credentials

# Verify secret is accessible from Lambda
aws lambda invoke --function-name typerush-dev-record-service `
  --payload '{"test": "secret-access"}' response.json
```

## Cost Impact

**$0.80/month**

- 2 secrets × $0.40/month/secret
- First 10,000 API calls free (more than enough for dev)
- No KMS charge (using default key)

## Security Considerations

### ✅ Secret Rotation

- **Dev**: Disabled (manual rotation if needed)
- **Production**: Enable automatic rotation (RDS: every 30 days)

### ✅ Access Pattern

```
Cold Start:
  ECS Task Execution → Get secret → Store in environment variable
  Lambda Cold Start → Get secret → Cache for warm invocations

Warm Invocations:
  Use cached secret (no additional Secrets Manager API calls)
```

### ✅ VPC Endpoint Usage

- Secrets retrieved via VPC endpoint (private communication)
- No NAT Gateway cost for secret retrieval
- Faster than going through NAT Gateway

### ✅ Audit Trail

- All secret access logged in CloudTrail
- Monitor for unusual access patterns
- Set up CloudWatch alarms for excessive API calls

## Testing Plan

1. [ ] Create secrets with random passwords
2. [ ] Verify secrets are encrypted at rest
3. [ ] Test ECS can retrieve ElastiCache secret
4. [ ] Test Lambda can retrieve RDS secret
5. [ ] Verify passwords meet complexity requirements
6. [ ] Test secret rotation (if enabled)

## Rollback Plan

```powershell
# Delete secrets immediately (skip recovery window)
terraform destroy -target=module.secrets

# Or via AWS CLI
aws secretsmanager delete-secret --secret-id typerush/record-db/credentials --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id typerush/elasticache/auth-token --force-delete-without-recovery
```

## Next Step

Proceed to [Step 06: VPC Endpoints](./06_vpc_endpoints.md)
