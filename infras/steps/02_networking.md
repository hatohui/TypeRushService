# Step 02: Networking Infrastructure ✅

## Status: COMPLETED

## Terraform Module: `modules/01-networking`

## Overview

Create the VPC networking foundation with 4 subnet types across a single AZ, NAT Gateway for private subnet internet access, and proper routing configuration.

## Architecture Reference

From `architecture-diagram.md`:

- VPC: 10.0.0.0/16 in ap-southeast-1
- Single AZ deployment (ap-southeast-1a) for dev cost optimization
- 4 subnet types: public, private, database, cache
- NAT Gateway in public subnet (⚠️ REQUIRED - $32.40/mo)
- Internet Gateway for public subnet access

## Components

### 1. VPC Configuration

- [x] VPC with 10.0.0.0/16 CIDR block
- [x] DNS hostnames enabled
- [x] DNS support enabled
- [x] Proper tagging

### 2. Subnets (4 Types)

- [x] **Public Subnet** (10.0.1.0/24)
  - [x] Internet Gateway attached
  - [x] NAT Gateway deployed here
  - [x] Auto-assign public IP enabled
- [x] **Private Subnet** (10.0.101.0/24)
  - [x] For ECS tasks and Lambda functions
  - [x] Routes through NAT Gateway
  - [x] Internal ALB deployed here
- [x] **Database Subnet** (10.0.201.0/24)
  - [x] For RDS PostgreSQL instance
  - [x] Isolated from internet
  - [x] Routes through NAT Gateway for updates
- [x] **Cache Subnet** (10.0.202.0/24)
  - [x] For ElastiCache Redis node
  - [x] Isolated from internet
  - [x] Routes through NAT Gateway for updates

### 3. Internet Gateway

- [x] IGW created and attached to VPC
- [x] Route table entry for public subnet (0.0.0.0/0 → IGW)

### 4. NAT Gateway (⚠️ Required)

- [x] Elastic IP allocated
- [x] NAT Gateway in public subnet
- [x] Cost: $32.40/month base + data transfer
- [x] **Why Required**: ECS/Lambda need internet for:
  - [x] Initialization and bootstrap
  - [x] CloudWatch Logs (no VPC endpoint in dev)
  - [x] External API calls
  - [x] Docker layer downloads

### 5. Route Tables (4 Tables)

- [x] **Public Route Table**
  - [x] 0.0.0.0/0 → Internet Gateway
  - [x] Associated with public subnet
- [x] **Private Route Table**
  - [x] 0.0.0.0/0 → NAT Gateway
  - [x] Associated with private subnet
- [x] **Database Route Table**
  - [x] 0.0.0.0/0 → NAT Gateway
  - [x] Associated with database subnet
- [x] **Cache Route Table**
  - [x] 0.0.0.0/0 → NAT Gateway
  - [x] Associated with cache subnet

### 6. VPC Flow Logs (Optional)

- [x] Optional CloudWatch log group for VPC flow logs
- [x] IAM role for flow logs
- [x] Controlled by `enable_vpc_flow_logs` variable
- [x] Default: disabled in dev to save costs

## Module Structure

```
modules/01-networking/
├── main.tf       # VPC, subnets, IGW, NAT, route tables
├── variables.tf  # Module inputs
└── outputs.tf    # VPC ID, subnet IDs, NAT IP
```

## Files Created

- `infras/modules/01-networking/main.tf`
- `infras/modules/01-networking/variables.tf`
- `infras/modules/01-networking/outputs.tf`

## Deployment

```powershell
# Create local variables file
cp env\dev.tfvars env\dev.tfvars.local

# Edit dev.tfvars.local with your email
# owner = "your-email@example.com"

# Deploy networking
terraform apply -var-file="env\dev.tfvars.local" -target=module.networking
```

## Validation

```powershell
# Get VPC ID
$VPC_ID = terraform output -raw vpc_id

# Verify VPC
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# Verify subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

# Verify NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
```

## Expected Outputs

- `vpc_id`: VPC ID (vpc-xxxxx)
- `public_subnet_ids`: Public subnet ID
- `private_subnet_ids`: Private subnet ID
- `database_subnet_ids`: Database subnet ID
- `cache_subnet_ids`: Cache subnet ID
- `nat_gateway_public_ip`: NAT Gateway Elastic IP

## Cost Impact

**$32.40/month** - NAT Gateway only (data transfer extra)

- NAT Gateway: $0.045/hour = $32.40/month
- Data transfer: ~$0.10-$2/month (minimal dev traffic)
- **Total: ~$33-35/month**

## Why NAT Gateway Cannot Be Removed

Despite VPC endpoints for some services, NAT Gateway is required because:

1. **ECS Task Initialization**
   - Docker daemon needs internet access during startup
   - Even with ECR VPC endpoints, some layers from public registries
2. **Lambda Cold Starts**
   - Lambda needs internet for package initialization
   - Python/Node.js dependencies may call external resources
3. **CloudWatch Logs** (No VPC Endpoint in Dev)
   - ECS and Lambda logs go to CloudWatch
   - CloudWatch Logs VPC endpoint: $7.20/mo (skipped in dev)
   - More cost-effective to use NAT for minimal log traffic
4. **Application Dependencies**
   - Game Service may need to fetch external content
   - Text Service may need external APIs
   - Health checks and monitoring endpoints

## Next Step

Proceed to [Step 03: Security Groups](./03_security_groups.md)
