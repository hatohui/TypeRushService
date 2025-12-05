# Step 07: RDS PostgreSQL Database

## Status: COMPLETED

**Completion Date**: 2025-11-23

## Terraform Module: `modules/06-rds`

## Overview

Create a single RDS PostgreSQL 17 instance for the Record Service to store user accounts and game history. Configured for dev environment with minimal cost.

## Architecture Reference

From `architecture-diagram.md`:

- **Database**: PostgreSQL 17 on db.t3.micro
- **Cost**: $14.40/month (Single-AZ, 20GB storage)
- **Purpose**: Store accounts and game history (Record Service only)
- **Network**: Deployed in Database Subnet (10.0.201.0/24)
- **Access**: Only Record Service Lambda can connect

## Components to Implement

### 1. DB Subnet Group

- [ ] **Name**: `typerush-dev-record-db-subnet-group`
- [ ] **Subnets**: Database subnet (minimum 1 for single-AZ)
- [ ] **Purpose**: Define where RDS instance can be placed
- [ ] **Note**: Multi-AZ requires 2+ subnets in different AZs

### 2. RDS PostgreSQL Instance

- [ ] **Engine**: PostgreSQL 17.x (latest minor version)
- [ ] **Instance Class**: db.t3.micro (2 vCPU, 1 GB RAM)
- [ ] **Storage**: 20 GB GP3 (General Purpose SSD)
- [ ] **Storage Autoscaling**: Disabled (dev, fixed size)
- [ ] **Multi-AZ**: Disabled (single-AZ for cost savings)
- [ ] **Publicly Accessible**: False
- [ ] **VPC Security Group**: RDS security group (only Lambda access)
- [ ] **Subnet Group**: Database subnet group

### 3. Database Configuration

- [ ] **Database Name**: `typerush_records`
- [ ] **Master Username**: Retrieved from Secrets Manager
- [ ] **Master Password**: Retrieved from Secrets Manager
- [ ] **Port**: 5432 (PostgreSQL default)
- [ ] **Parameter Group**: Default postgres17 family

### 4. Backup Configuration

- [ ] **Automated Backups**: Enabled
- [ ] **Backup Retention**: 1 day (minimum for dev)
- [ ] **Backup Window**: 03:00-04:00 UTC (Singapore night time)
- [ ] **Maintenance Window**: Sun:04:00-Sun:05:00 UTC
- [ ] **Final Snapshot**: Create on deletion (with timestamp)

### 5. Encryption and Security

- [ ] **Encryption at Rest**: Enabled (default KMS key: aws/rds)
- [ ] **Encryption in Transit**: Enforced (SSL/TLS required)
- [ ] **Storage Encrypted**: True
- [ ] **IAM Database Authentication**: Disabled (using password auth)
- [ ] **Enhanced Monitoring**: Disabled (dev, save costs)

### 6. Performance and Monitoring

- [ ] **Performance Insights**: Disabled (dev, save costs)
- [ ] **CloudWatch Logs**: Export PostgreSQL logs
  - [ ] Enable: postgresql log
  - [ ] Retention: 7 days
- [ ] **Monitoring Interval**: 0 (enhanced monitoring off)

## Database Schema

### Tables Created by Prisma Migrations

1. **accounts** - User authentication

   - id (UUID, primary key)
   - email (unique)
   - username (unique)
   - password_hash
   - created_at, updated_at

2. **match_history** - Game results

   - id (UUID, primary key)
   - account_id (foreign key → accounts)
   - wpm (words per minute)
   - accuracy (percentage)
   - text_id (reference to DynamoDB)
   - duration_seconds
   - completed_at

3. **\_prisma_migrations** - Prisma migration tracking

## Implementation Details

### Secrets Manager Integration

```hcl
data "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = "typerush/record-db/credentials"
}

locals {
  rds_creds = jsondecode(data.aws_secretsmanager_secret_version.rds_credentials.secret_string)
}

resource "aws_db_instance" "record_db" {
  identifier = "${var.project_name}-${var.environment}-record-db"

  engine         = "postgres"
  engine_version = "17"
  instance_class = var.rds_instance_class

  username = local.rds_creds.username
  password = local.rds_creds.password

  db_name = "typerush_records"
  port    = 5432

  # ... other configuration
}
```

### Connection String for Record Service

```
postgresql://typerush_admin:{password}@typerush-dev-record-db.xxxxx.ap-southeast-1.rds.amazonaws.com:5432/typerush_records?sslmode=require
```

## Module Structure

```
modules/12-rds/
├── main.tf       # DB subnet group, RDS instance
├── variables.tf  # Instance class, storage size, subnet IDs
└── outputs.tf    # Endpoint, ARN, instance ID
```

## Dependencies

- **Required**: Module 01 (Networking) - Database subnet
- **Required**: Module 02 (Security Groups) - RDS security group
- **Required**: Module 14 (Secrets Manager) - RDS credentials

## Deployment

```powershell
# Deploy RDS (takes ~10-15 minutes)
terraform apply -var-file="env\dev.tfvars.local" -target=module.rds
```

## Validation Commands

```powershell
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier typerush-dev-record-db

# Get endpoint
$RDS_ENDPOINT = terraform output -raw rds_endpoint

# Test connection from Lambda (deploy Record Service first)
aws lambda invoke --function-name typerush-dev-record-service `
  --payload '{"action": "health"}' response.json

# View CloudWatch logs
aws logs tail /aws/rds/instance/typerush-dev-record-db/postgresql --follow
```

## Database Migrations

### Initial Schema Setup

```powershell
# From Record Service directory
cd services/record-service

# Set DATABASE_URL from Secrets Manager
$SECRET = aws secretsmanager get-secret-value --secret-id typerush/record-db/credentials --query SecretString --output text
$DB_URL = "postgresql://..." # Construct from secret

# Run Prisma migrations
$env:DATABASE_URL = $DB_URL
npx prisma migrate deploy
```

### Via CodeBuild (Automated)

- CodePipeline triggers CodeBuild after image build
- CodeBuild runs `npx prisma migrate deploy`
- Migrations applied before ECS deployment

## Cost Impact

**$14.40/month**

- db.t3.micro: $0.018/hour = $12.96/month
- 20 GB GP3 storage: $0.115/GB/month = $2.30/month
- Backup storage (1 day): ~$0.10/month (same as DB size)
- Data transfer: Minimal (private subnet)

**4-day demo**: ~$2/day × 4 = $8

## Performance Considerations

### Dev Environment

- **Expected Load**: 1-10 concurrent users
- **Query Performance**: Single-threaded, no read replicas needed
- **Connection Pool**: 10 connections (sufficient for dev)

### Scaling for Production

```
Dev:       db.t3.micro   (2 vCPU, 1 GB)   → $13/mo
Staging:   db.t3.small   (2 vCPU, 2 GB)   → $26/mo
Prod:      db.t3.medium  (2 vCPU, 4 GB)   → $52/mo Multi-AZ
```

## Security Considerations

### ✅ Network Isolation

```
Record Service Lambda (private subnet)
    ↓ (via Lambda Security Group)
RDS Security Group (allows PostgreSQL:5432 from Lambda SG only)
    ↓
RDS Instance (database subnet, no internet access)
```

### ✅ Encryption

- **At Rest**: KMS encryption (default aws/rds key)
- **In Transit**: SSL/TLS enforced via `sslmode=require`
- **Credentials**: Stored in Secrets Manager

### ✅ Access Control

- **Lambda IAM Role**: Can read RDS credentials from Secrets Manager
- **Security Group**: Only Lambda security group can reach PostgreSQL port
- **No Public Access**: Endpoint not accessible from internet

### ✅ Backup Strategy

```
Dev Environment:
- Automated backups: 1 day retention
- Final snapshot on deletion: Yes (manual cleanup after testing)

Production:
- Automated backups: 7-30 days
- Snapshot before major changes
- Point-in-time recovery enabled
```

## Monitoring and Alerting

### CloudWatch Metrics

- [ ] CPUUtilization > 80% for 5 minutes
- [ ] FreeableMemory < 200 MB
- [ ] DatabaseConnections > 80 (out of 100 max for db.t3.micro)
- [ ] ReadLatency > 100ms
- [ ] WriteLatency > 100ms

### CloudWatch Logs

- PostgreSQL error logs
- Slow query logs (if enabled)
- Connection logs

## Testing Plan

1. [ ] Deploy RDS instance
2. [ ] Verify instance is "available" status
3. [ ] Test Lambda can retrieve credentials from Secrets Manager
4. [ ] Test Lambda can connect to RDS
5. [ ] Run Prisma migrations
6. [ ] Verify tables created (accounts, match_history)
7. [ ] Test CRUD operations via Record Service Lambda
8. [ ] Test SSL/TLS connection enforcement
9. [ ] Verify backups are created
10. [ ] Test final snapshot on deletion

## Rollback Plan

```powershell
# Create final snapshot before deletion
aws rds create-db-snapshot `
  --db-instance-identifier typerush-dev-record-db `
  --db-snapshot-identifier typerush-dev-final-$(Get-Date -Format 'yyyyMMdd-HHmmss')

# Destroy RDS
terraform destroy -target=module.rds

# Restore from snapshot if needed
aws rds restore-db-instance-from-db-snapshot `
  --db-instance-identifier typerush-dev-record-db-restored `
  --db-snapshot-identifier typerush-dev-final-20251123-120000
```

## Next Step

Proceed to [Step 08: ElastiCache Redis](./08_elasticache_redis.md)
