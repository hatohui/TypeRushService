# Step 03: Security Groups ✅

## Status: COMPLETED

## Terraform Module: `modules/02-security-groups`

## Overview

Create 7 security groups with least-privilege rules implementing defense-in-depth security for all services.

## Architecture Reference

From `architecture-diagram.md`:

- Internal ALB: Private only, accessed via VPC Link
- ECS: Only accepts traffic from ALB
- Lambda: Outbound only to RDS and VPC endpoints
- RDS: Only accepts PostgreSQL from Lambda
- ElastiCache: Only accepts Redis from ECS
- VPC Endpoints: Only accept HTTPS from ECS/Lambda

## Components

### 1. Internal ALB Security Group

- [x] **Ingress Rules**:
  - [x] HTTP (80) from VPC CIDR (10.0.0.0/16)
  - [x] HTTPS (443) from VPC CIDR (10.0.0.0/16)
  - [x] Rationale: ALB is private, only accessed via VPC Link from API Gateway
- [x] **Egress Rules**:
  - [x] Custom TCP (3000) to ECS security group
  - [x] Rationale: Forward requests to Game Service on port 3000

### 2. ECS Security Group (Game Service)

- [x] **Ingress Rules**:
  - [x] TCP 3000 from ALB security group only
  - [x] Rationale: Only ALB can reach Game Service container
- [x] **Egress Rules**:
  - [x] Redis (6379) to ElastiCache security group
  - [x] HTTPS (443) to VPC Endpoints security group (for Secrets Manager, ECR)
  - [x] HTTPS (443) to 0.0.0.0/0 via NAT (for Lambda invoke, logs, init)
  - [x] Rationale: Game Service needs ElastiCache, secrets, and Lambda invocation

### 3. Lambda Security Group (Record + Text Services)

- [x] **Ingress Rules**:
  - [x] None (Lambda is invoked via API, not network traffic)
- [x] **Egress Rules**:
  - [x] PostgreSQL (5432) to RDS security group (Record Service)
  - [x] HTTPS (443) to VPC Endpoints security group (Secrets, Bedrock, DynamoDB gateway)
  - [x] HTTPS (443) to 0.0.0.0/0 via NAT (for logs, init, external APIs)
  - [x] Rationale: Lambda functions need database, VPC endpoints, and internet

### 4. RDS Security Group (Record Database)

- [x] **Ingress Rules**:
  - [x] PostgreSQL (5432) from Lambda security group only
  - [x] Rationale: Only Record Service Lambda accesses the database
- [x] **Egress Rules**:
  - [x] None required (database doesn't initiate connections)

### 5. ElastiCache Security Group (Redis)

- [x] **Ingress Rules**:
  - [x] Redis (6379) from ECS security group only
  - [x] Rationale: Only Game Service accesses Redis for session state
- [x] **Egress Rules**:
  - [x] None required (Redis doesn't initiate connections)

### 6. VPC Endpoints Security Group

- [x] **Ingress Rules**:
  - [x] HTTPS (443) from ECS security group
  - [x] HTTPS (443) from Lambda security group
  - [x] Rationale: Allow ECS and Lambda to reach VPC endpoints privately
- [x] **Egress Rules**:
  - [x] None required (endpoints don't initiate connections)

### 7. Bastion Security Group (Optional)

- [x] **Ingress Rules**:
  - [x] SSH (22) from configurable CIDR (default: 0.0.0.0/32 - must be updated)
  - [x] Rationale: For debugging database access during development
- [x] **Egress Rules**:
  - [x] PostgreSQL (5432) to RDS security group
  - [x] Redis (6379) to ElastiCache security group
  - [x] HTTPS (443) to 0.0.0.0/0 (for package updates)
- [x] **Controlled by**: `create_bastion` variable (default: false)

## Security Principles Applied

### ✅ Least Privilege

- Each security group only allows the minimum required access
- No wildcard 0.0.0.0/0 ingress except bastion (which must be configured)
- All ingress rules reference specific security groups when possible

### ✅ Defense in Depth

- Network isolation via security groups
- VPC subnet isolation (private, database, cache)
- No public IPs on private resources
- Multiple layers: API Gateway → ALB → ECS

### ✅ Stateless Architecture Support

- Game Service is stateless (uses ElastiCache)
- Lambda functions are stateless
- Allows horizontal scaling without security group changes

## Module Structure

```
modules/02-security-groups/
├── main.tf       # 7 security group definitions
├── variables.tf  # Module inputs
└── outputs.tf    # Security group IDs
```

## Files Created

- `infras/modules/02-security-groups/main.tf`
- `infras/modules/02-security-groups/variables.tf`
- `infras/modules/02-security-groups/outputs.tf`

## Deployment

```powershell
# Deploy security groups (requires networking module deployed)
terraform apply -var-file="env\dev.tfvars.local" -target=module.security_groups
```

## Validation

```powershell
# Get VPC ID
$VPC_ID = terraform output -raw vpc_id

# List all security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID"

# Verify no public ingress (except bastion if enabled)
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" `
  --query "SecurityGroups[?IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']]].GroupName"
```

## Expected Outputs

- `alb_security_group_id`: Internal ALB SG
- `ecs_security_group_id`: Game Service SG
- `lambda_security_group_id`: Record/Text Service SG
- `rds_security_group_id`: PostgreSQL SG
- `elasticache_security_group_id`: Redis SG
- `vpc_endpoints_security_group_id`: VPC Endpoints SG
- `bastion_security_group_id`: Bastion SG (if enabled)

## Cost Impact

**$0/month** - Security groups are free

## Traffic Flow Diagram

```
Internet → API Gateway (VPC Link) → ALB SG → ECS SG → ElastiCache SG
                                                ↓
                                            Lambda SG → RDS SG
                                                ↓
                                        VPC Endpoints SG
```

## Next Step

Proceed to [Step 04: IAM Roles](./04_iam_roles.md)
