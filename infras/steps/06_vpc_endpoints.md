# Step 06: VPC Endpoints

## Status: COMPLETED

**Completed on:** 2025-11-23

## Terraform Module: `modules/15-vpc-endpoints`

## Overview

Create 6 VPC endpoints (4 Interface + 2 Gateway) to enable private communication with AWS services, reducing NAT Gateway data transfer costs and improving security.

## Architecture Reference

From `architecture-diagram.md`:

- **Interface Endpoints** (4 × $7.20/mo = $28.80/mo):
  - Secrets Manager
  - Bedrock Runtime
  - ECR API
  - ECR Docker (dkr)
- **Gateway Endpoints** (FREE):
  - S3
  - DynamoDB
- **Why not CloudWatch Logs?**: $7.20/mo extra, minimal log traffic in dev justifies using NAT

## Components to Implement

### 1. Interface Endpoints (4)

#### A. Secrets Manager VPC Endpoint

- [ ] **Service Name**: `com.amazonaws.ap-southeast-1.secretsmanager`
- [ ] **Type**: Interface
- [ ] **Subnet**: Private subnet
- [ ] **Security Group**: VPC Endpoints SG (allows HTTPS from ECS/Lambda)
- [ ] **Private DNS**: Enabled (use standard endpoint URLs)
- [ ] **Cost**: $7.20/month + $0.01/GB data processed
- [ ] **Benefit**:
  - [ ] Secrets retrieval via private network
  - [ ] Reduces NAT data transfer costs
  - [ ] Lower latency for cold starts

#### B. Bedrock Runtime VPC Endpoint

- [ ] **Service Name**: `com.amazonaws.ap-southeast-1.bedrock-runtime`
- [ ] **Type**: Interface
- [ ] **Subnet**: Private subnet
- [ ] **Security Group**: VPC Endpoints SG
- [ ] **Private DNS**: Enabled
- [ ] **Cost**: $7.20/month + data processed
- [ ] **Benefit**:
  - [ ] Text Service Lambda calls Bedrock privately
  - [ ] No NAT cost for AI text generation
  - [ ] Faster inference requests

#### C. ECR API VPC Endpoint

- [ ] **Service Name**: `com.amazonaws.ap-southeast-1.ecr.api`
- [ ] **Type**: Interface
- [ ] **Subnet**: Private subnet
- [ ] **Security Group**: VPC Endpoints SG
- [ ] **Private DNS**: Enabled
- [ ] **Cost**: $7.20/month
- [ ] **Benefit**:
  - [ ] ECS pulls image manifests privately
  - [ ] Reduces NAT data transfer
  - [ ] Required with ECR Docker endpoint

#### D. ECR Docker VPC Endpoint

- [ ] **Service Name**: `com.amazonaws.ap-southeast-1.ecr.dkr`
- [ ] **Type**: Interface
- [ ] **Subnet**: Private subnet
- [ ] **Security Group**: VPC Endpoints SG
- [ ] **Private DNS**: Enabled
- [ ] **Cost**: $7.20/month
- [ ] **Benefit**:
  - [ ] ECS pulls Docker layers privately
  - [ ] Significant NAT savings (images can be large)
  - [ ] Must be used with ECR API endpoint

### 2. Gateway Endpoints (2)

#### A. S3 Gateway Endpoint

- [ ] **Service Name**: `com.amazonaws.ap-southeast-1.s3`
- [ ] **Type**: Gateway
- [ ] **Route Tables**: Associate with private, database, cache route tables
- [ ] **Policy**: Allow all actions (can be restricted later)
- [ ] **Cost**: FREE
- [ ] **Benefit**:
  - [ ] Lambda functions access S3 privately
  - [ ] ECS pulls Lambda layers from S3
  - [ ] CodeBuild artifacts storage
  - [ ] No NAT cost for S3 traffic

#### B. DynamoDB Gateway Endpoint

- [ ] **Service Name**: `com.amazonaws.ap-southeast-1.dynamodb`
- [ ] **Type**: Gateway
- [ ] **Route Tables**: Associate with private, database, cache route tables
- [ ] **Policy**: Allow all actions
- [ ] **Cost**: FREE
- [ ] **Benefit**:
  - [ ] Text Service Lambda accesses DynamoDB privately
  - [ ] No NAT cost for DynamoDB operations
  - [ ] Lower latency

## Why Not CloudWatch Logs Endpoint?

### Cost-Benefit Analysis

| Option           | Monthly Cost        | Data Transfer Cost | Total  |
| ---------------- | ------------------- | ------------------ | ------ |
| **VPC Endpoint** | $7.20               | $0.01/GB           | ~$7.30 |
| **NAT Gateway**  | $0 (already paying) | $0.09/GB           | ~$0.50 |

**Dev Environment Log Volume**: ~5GB/month

- **NAT Cost**: $0.45/month
- **Endpoint Cost**: $7.20/month
- **Savings**: -$6.75/month (NOT cost-effective)

**Production Consideration**: With 100GB+ logs/month, endpoint becomes cost-effective

## Implementation Details

### Interface Endpoint Pattern

```hcl
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_security_group_id]

  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-secretsmanager-endpoint"
      Service = "secretsmanager"
    }
  )
}
```

### Gateway Endpoint Pattern

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = var.vpc_id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    var.private_route_table_id,
    var.database_route_table_id,
    var.cache_route_table_id
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-s3-endpoint"
      Service = "s3"
    }
  )
}
```

## Module Structure

```
modules/15-vpc-endpoints/
├── main.tf       # 4 interface + 2 gateway endpoints
├── variables.tf  # VPC ID, subnet IDs, security group IDs
└── outputs.tf    # Endpoint IDs and DNS names
```

## Dependencies

- **Required**: Module 01 (Networking) - VPC, subnets, route tables
- **Required**: Module 02 (Security Groups) - VPC Endpoints SG

## Deployment

```powershell
# Deploy VPC endpoints
terraform apply -var-file="env\dev.tfvars.local" -target=module.vpc_endpoints
```

## Validation Commands

```powershell
# List VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID"

# Test Secrets Manager endpoint from private subnet
# (Requires test Lambda or EC2 in private subnet)

# Verify private DNS enabled
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $ENDPOINT_ID `
  --query 'VpcEndpoints[0].PrivateDnsEnabled'

# Check endpoint status
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $ENDPOINT_ID `
  --query 'VpcEndpoints[0].State'  # Should be "available"
```

## Cost Impact

**$28.80/month** (Interface endpoints only)

- Secrets Manager: $7.20/mo
- Bedrock Runtime: $7.20/mo
- ECR API: $7.20/mo
- ECR Docker: $7.20/mo
- S3 Gateway: FREE
- DynamoDB Gateway: FREE

**NAT Gateway Savings**: ~$5-10/month in data transfer costs

- ECR image pulls: ~2GB/month × $0.09/GB = $0.18 saved
- Secrets Manager: ~0.1GB/month × $0.09/GB = $0.01 saved
- Bedrock: ~1GB/month × $0.09/GB = $0.09 saved
- S3: ~2GB/month × $0.09/GB = $0.18 saved
- DynamoDB: ~0.5GB/month × $0.09/GB = $0.05 saved

**Net Cost**: +$28 - $5 = **+$23/month** (worth it for security and performance)

## Security Benefits

### ✅ Private Communication

- All traffic stays within AWS network
- No internet exposure for sensitive operations
- Compliant with data sovereignty requirements

### ✅ Defense in Depth

- Even if NAT Gateway compromised, VPC endpoint traffic unaffected
- Separate network path for critical services

### ✅ Reduced Attack Surface

- Less traffic through NAT Gateway
- Fewer external connections to monitor

## Performance Benefits

### ✅ Lower Latency

- Direct connection to AWS services
- No NAT translation overhead
- Faster cold starts for Lambda

### ✅ Higher Bandwidth

- VPC endpoints have higher throughput than NAT
- Better for large ECR image pulls

## Testing Plan

1. [ ] Deploy VPC endpoints
2. [ ] Verify endpoints are "available" status
3. [ ] Test ECS can pull ECR images via endpoint
4. [ ] Test Lambda can retrieve secrets via endpoint
5. [ ] Test Text Service can call Bedrock via endpoint
6. [ ] Verify S3 and DynamoDB traffic uses gateway endpoints
7. [ ] Monitor CloudWatch for endpoint metrics

## Monitoring

```powershell
# Check endpoint metrics in CloudWatch
aws cloudwatch get-metric-statistics `
  --namespace AWS/VPC `
  --metric-name PacketsTransferred `
  --dimensions Name=VpcEndpointId,Value=$ENDPOINT_ID `
  --start-time 2025-11-23T00:00:00Z `
  --end-time 2025-11-24T00:00:00Z `
  --period 3600 `
  --statistics Sum
```

## Rollback Plan

```powershell
# Delete VPC endpoints
terraform destroy -target=module.vpc_endpoints

# Verify services still work via NAT Gateway
```

## Next Step

Proceed to [Step 07: RDS PostgreSQL](./07_rds_postgresql.md)
