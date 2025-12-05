# TypeRush Infrastructure - Pre-Deployment Report

**Generated**: November 23, 2025  
**Region**: ap-southeast-1 (Singapore)  
**Environment**: Development (Single-AZ)  
**Terraform Version**: >= 1.5.0  
**AWS Provider**: ~> 6.22.0 (Latest: 6.22.1 ✅)

---

## 📋 Executive Summary

**Status**: ✅ **READY FOR PLANNING - NOT YET READY TO APPLY**

All 26 Terraform modules have been implemented and validated. The infrastructure code is syntactically correct and ready for `terraform plan`. However, **configuration updates are required** before deployment.

### Readiness Checklist

- ✅ All 26 Terraform modules implemented
- ✅ Terraform syntax validation passed
- ✅ Lambda deployment packages built (record-service, text-service)
- ✅ AWS services verified available in ap-southeast-1
- ✅ Provider versions up to date
- ⚠️ **Configuration variables need update** (2 email placeholders)
- ⚠️ **Backend configuration needs update** (Terraform Cloud workspace)
- ⚠️ **AWS credentials must be configured**
- ⏳ Terraform plan not yet generated
- ⏳ Infrastructure not yet applied

---

## 🚨 Required Actions Before Deployment

### 1. Update Email Configuration ⚠️ REQUIRED

**File**: `infras/dev.auto.tfvars`

```terraform
# Line 7 - Change this
owner = "your-email@example.com"  # ❌ Placeholder
# To:
owner = "your-actual-email@example.com"  # ✅ Real email

# Line 52 - Change this
alert_email = "your-email@example.com"  # ❌ Placeholder
# To:
alert_email = "your-actual-email@example.com"  # ✅ Real email
```

**Purpose**:

- `owner`: Tags all resources with owner identification
- `alert_email`: Receives CloudWatch alarms and SNS notifications

### 2. Configure Terraform Backend

**File**: `infras/terraform.tf` (Lines 17-23)

Current configuration uses Terraform Cloud:

```terraform
backend "remote" {
  organization = "typerush"
  workspaces {
    name = "typerush-dev"
  }
}
```

**Options**:

#### Option A: Use Terraform Cloud (Recommended for Team)

1. Create account at https://app.terraform.io/
2. Create organization named `typerush`
3. Create workspace named `typerush-dev`
4. Run `terraform login` to authenticate
5. Proceed with deployment

#### Option B: Use Local State (For Solo Learning)

1. Comment out or remove the `backend "remote"` block in `terraform.tf`
2. State will be stored locally in `terraform.tfstate`
3. ⚠️ Warning: Local state is not backed up or version-controlled

#### Option C: Use S3 Backend (Production-Ready)

Replace the backend block with:

```terraform
backend "s3" {
  bucket         = "typerush-terraform-state"
  key            = "dev/terraform.tfstate"
  region         = "ap-southeast-1"
  encrypt        = true
  dynamodb_table = "typerush-terraform-locks"
}
```

### 3. Configure AWS Credentials

Ensure AWS CLI is configured with valid credentials:

```powershell
# Check current configuration
aws configure list

# Configure if needed
aws configure
# AWS Access Key ID: [Enter your access key]
# AWS Secret Access Key: [Enter your secret key]
# Default region: ap-southeast-1
# Default output format: json

# Verify access
aws sts get-caller-identity
```

**Required IAM Permissions**: Administrator or equivalent access to create VPC, EC2, RDS, Lambda, ECS, etc.

### 4. Review Optional Configuration

**Domain Name** (Optional - Can be left empty for dev):

```terraform
domain_name         = ""  # Leave empty if not using custom domain
create_route53_zone = false
```

**GitLab/GitHub Integration** (Optional - For CI/CD):

```terraform
gitlab_repository_url       = ""  # Add if using GitLab
codestar_connection_arn     = ""  # Add for CodePipeline
repository_id               = ""  # e.g., "username/repo"
```

**CI/CD Pipelines** (Disabled by default):

```terraform
create_game_service_pipeline   = false  # Enable when ready
create_record_service_pipeline = false
create_text_service_pipeline   = false
create_frontend_pipeline       = false
```

---

## 🏗️ Infrastructure Overview

### Module Implementation Status

All 26 modules are **IMPLEMENTED** and **VALIDATED**:

| Module | Name                           | Status         | Critical     |
| ------ | ------------------------------ | -------------- | ------------ |
| 01     | Networking (VPC, Subnets, NAT) | ✅ Implemented | 🔴 Critical  |
| 02     | Security Groups                | ✅ Implemented | 🔴 Critical  |
| 03     | IAM Roles & Policies           | ✅ Implemented | 🔴 Critical  |
| 04     | Secrets Manager                | ✅ Implemented | 🔴 Critical  |
| 05     | VPC Endpoints                  | ✅ Implemented | 🟡 Important |
| 06     | RDS PostgreSQL                 | ✅ Implemented | 🔴 Critical  |
| 08     | ElastiCache Redis              | ✅ Implemented | 🔴 Critical  |
| 09     | DynamoDB                       | ✅ Implemented | 🔴 Critical  |
| 10     | ECR Repositories               | ✅ Implemented | 🔴 Critical  |
| 11     | ECS Cluster & Game Service     | ✅ Implemented | 🔴 Critical  |
| 12     | Internal ALB                   | ✅ Implemented | 🔴 Critical  |
| 13     | Lambda Functions               | ✅ Implemented | 🔴 Critical  |
| 14     | VPC Link v2                    | ✅ Implemented | 🔴 Critical  |
| 15     | API Gateway HTTP               | ✅ Implemented | 🔴 Critical  |
| 16     | API Gateway WebSocket          | ✅ Implemented | 🟡 Important |
| 17     | S3 Frontend Bucket             | ✅ Implemented | 🟡 Important |
| 18     | ACM Certificates               | ✅ Implemented | 🟢 Optional  |
| 19     | WAF Web ACL                    | ✅ Implemented | 🟡 Important |
| 20     | CloudFront CDN                 | ✅ Implemented | 🟡 Important |
| 21     | Route 53 DNS                   | ✅ Implemented | 🟢 Optional  |
| 22     | Cognito User Pool              | ✅ Implemented | 🟡 Important |
| 23     | SNS Topics                     | ✅ Implemented | 🟡 Important |
| 24     | CloudWatch Monitoring          | ✅ Implemented | 🟡 Important |
| 25     | CodeBuild Projects             | ✅ Implemented | 🟢 Optional  |
| 26     | CodePipeline                   | ✅ Implemented | 🟢 Optional  |

**Legend**:

- 🔴 Critical: Required for core functionality
- 🟡 Important: Recommended for production-readiness
- 🟢 Optional: Can be enabled later

### Lambda Deployment Packages

✅ **Built and Ready**:

- `build/record-service-lambda.zip` - NestJS + Prisma
- `build/text-service-lambda.zip` - Python + FastAPI

**Note**: Game Service uses Docker image (will be built and pushed to ECR after infrastructure is deployed)

---

## 💰 Cost Estimates

### Monthly Cost Breakdown (Full Month)

| Component         | Service                | Configuration                    | Monthly Cost        |
| ----------------- | ---------------------- | -------------------------------- | ------------------- |
| **Networking**    | NAT Gateway            | Single AZ                        | $32.85              |
| **VPC Endpoints** | 4 Interface Endpoints  | Secrets, Bedrock, ECR API/Docker | $28.80              |
| **Database**      | RDS PostgreSQL         | db.t3.micro, 20GB GP3            | $14.40              |
| **Cache**         | ElastiCache Redis      | cache.t4g.micro                  | $12.41              |
| **Compute**       | ECS Fargate            | 0.25 vCPU, 0.5GB, 1 task         | $10.88              |
| **Load Balancer** | Internal ALB           | Single AZ                        | $16.20              |
| **Lambda**        | Record + Text Services | Minimal usage                    | $2-5                |
| **API Gateway**   | HTTP + WebSocket       | Dev traffic                      | $3-5                |
| **Storage**       | S3, DynamoDB           | Minimal data                     | $1-3                |
| **Monitoring**    | CloudWatch Logs        | 7-day retention                  | $2-4                |
| **Security**      | WAF + Secrets Manager  | Basic rules + 2 secrets          | $2-3                |
| **CDN**           | CloudFront             | PriceClass_100                   | $1-2                |
| **Total**         |                        |                                  | **~$120-135/month** |

### Short-Term Testing Cost

| Duration | Total Cost | Cost per Day |
| -------- | ---------- | ------------ |
| 1 day    | $4-4.50    | $4-4.50      |
| 3 days   | $12-15     | $4-5         |
| 7 days   | $28-35     | $4-5         |
| 1 month  | $120-135   | $4-4.50      |

**Cost Optimization Notes**:

- ⚠️ **NAT Gateway** ($32.85/month) is the largest cost - required for ECS/Lambda
- ⚠️ **VPC Interface Endpoints** ($28.80/month) reduce NAT data transfer but have hourly charges
- Gateway endpoints (S3, DynamoDB) are FREE
- All services use smallest available instance types
- No reserved capacity or savings plans (on-demand pricing)
- **Recommendation**: Destroy infrastructure after testing to avoid ongoing costs

---

## 🔍 AWS Service Regional Availability

**Region**: ap-southeast-1 (Asia Pacific - Singapore)

✅ **All Required Services Available**:

- ✅ Amazon Bedrock (AI text generation)
- ✅ Amazon ECS (Fargate containers)
- ✅ AWS Lambda (serverless functions)
- ✅ Amazon RDS (PostgreSQL 17)
- ✅ Amazon ElastiCache (Redis 7.1)
- ✅ Amazon API Gateway (HTTP + WebSocket)
- ✅ Amazon CloudFront (global CDN)
- ✅ AWS WAF (web application firewall)
- ✅ Amazon Route 53 (DNS)
- ✅ AWS Cognito (authentication)
- ✅ Amazon DynamoDB (NoSQL database)
- ✅ Amazon ECR (container registry)
- ✅ AWS Secrets Manager
- ✅ Amazon CloudWatch
- ✅ AWS CodeBuild
- ✅ AWS CodePipeline
- ✅ Amazon VPC (networking)

**No regional limitations detected** for this architecture.

---

## 📝 Deployment Sequence

### Phase 1: Foundation (Required First)

**Order matters** - these must be deployed before other resources:

1. **Networking** (Module 01) - VPC, subnets, NAT, IGW
2. **Security Groups** (Module 02) - Firewall rules
3. **IAM** (Module 03) - Service roles and policies
4. **Secrets Manager** (Module 04) - Credential storage
5. **VPC Endpoints** (Module 05) - Private AWS service access

**Estimated time**: 10-15 minutes  
**Why first**: All other resources depend on network and IAM

### Phase 2: Data Layer (Required Second)

6. **RDS PostgreSQL** (Module 06) - Record database
7. **ElastiCache Redis** (Module 08) - Game session cache
8. **DynamoDB** (Module 09) - Text storage

**Estimated time**: 10-15 minutes  
**Why second**: Compute services need database endpoints

### Phase 3: Compute & API (Required Third)

9. **ECR** (Module 10) - Container registry
10. **Internal ALB** (Module 12) - Load balancer (must be before ECS)
11. **ECS** (Module 11) - Game Service containers
12. **Lambda** (Module 13) - Record & Text Services
13. **VPC Link** (Module 14) - API Gateway ↔ VPC connection
14. **API Gateway HTTP** (Module 15) - REST API
15. **API Gateway WebSocket** (Module 16) - Real-time API

**Estimated time**: 15-20 minutes  
**Why third**: Core application layer

### Phase 4: Frontend & CDN (Required Fourth)

16. **S3** (Module 17) - Frontend static hosting
17. **ACM** (Module 18) - SSL certificates (optional if no domain)
18. **WAF** (Module 19) - Web application firewall
19. **CloudFront** (Module 20) - CDN
20. **Route 53** (Module 21) - DNS (optional if no domain)

**Estimated time**: 15-20 minutes  
**Why fourth**: Public-facing layer

### Phase 5: Security & Monitoring (Recommended)

21. **Cognito** (Module 22) - User authentication
22. **SNS** (Module 23) - Alert notifications
23. **CloudWatch** (Module 24) - Monitoring dashboards

**Estimated time**: 5-10 minutes  
**Why last**: Cross-cutting concerns

### Phase 6: CI/CD (Optional)

24. **CodeBuild** (Module 25) - Build projects
25. **CodePipeline** (Module 26) - Deployment pipelines

**Estimated time**: 5-10 minutes  
**Why optional**: Can be added later

### Total Deployment Time

- **Minimum (without CI/CD)**: 55-80 minutes
- **Full deployment**: 60-90 minutes

**Note**: Times are estimates. First-time deployments may take longer due to AWS resource provisioning delays.

---

## 🎯 Deployment Strategy Recommendations

### Option 1: All-at-Once (Recommended for Learning)

**Command**:

```powershell
cd d:\Repository\TypeRushService\infras
terraform apply -var-file="dev.auto.tfvars"
```

**Pros**:

- Single command deployment
- Terraform handles dependency order automatically
- Fastest way to get everything running

**Cons**:

- Harder to troubleshoot if errors occur
- All-or-nothing approach

**Best for**: Learning, testing, demo purposes

### Option 2: Phased Deployment (Recommended for Production)

**Phase 1 - Foundation**:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.networking \
  -target=module.security_groups \
  -target=module.iam \
  -target=module.secrets_manager \
  -target=module.vpc_endpoints
```

**Phase 2 - Data Layer**:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.rds \
  -target=module.elasticache \
  -target=module.dynamodb
```

**Phase 3 - Compute**:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.ecr \
  -target=module.alb \
  -target=module.ecs \
  -target=module.lambda
```

**Phase 4 - API Gateway**:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.vpc_link \
  -target=module.api_gateway_http \
  -target=module.api_gateway_ws
```

**Phase 5 - Frontend**:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.s3 \
  -target=module.acm \
  -target=module.waf \
  -target=module.cloudfront \
  -target=module.route53
```

**Phase 6 - Monitoring & CI/CD**:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.cognito \
  -target=module.sns \
  -target=module.cloudwatch \
  -target=module.codebuild \
  -target=module.codepipeline
```

**Pros**:

- Better error isolation
- Can pause between phases
- Easier troubleshooting

**Cons**:

- More manual steps
- Takes longer

**Best for**: Production deployments, troubleshooting

### Option 3: Critical Path Only (Minimal Deployment)

Deploy only what's needed for core functionality:

```powershell
terraform apply -var-file="dev.auto.tfvars" \
  -target=module.networking \
  -target=module.security_groups \
  -target=module.iam \
  -target=module.secrets_manager \
  -target=module.vpc_endpoints \
  -target=module.rds \
  -target=module.elasticache \
  -target=module.dynamodb \
  -target=module.ecr \
  -target=module.alb \
  -target=module.ecs \
  -target=module.lambda \
  -target=module.vpc_link \
  -target=module.api_gateway_http
```

**Estimated cost**: $70-80/month  
**What's excluded**: CloudFront, WAF, Route 53, Cognito, monitoring, CI/CD

**Best for**: Backend-only testing, minimal cost

---

## ⚠️ Known Considerations & Limitations

### 1. ECS Service Health Checks

**Issue**: ECS service requires a `/health` endpoint in Game Service application.

**Solution**: Ensure `services/game-service/src/app.ts` has:

```typescript
app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});
```

### 2. Lambda Cold Starts

**Issue**: First invocation of Lambda functions will be slow (2-5 seconds).

**Mitigation**:

- Lambda functions are configured with VPC access
- Subsequent calls will be faster (warmed up)
- Consider provisioned concurrency for production

### 3. Docker Image Required for ECS

**Issue**: ECS task definition references ECR image that doesn't exist yet.

**Solution**: After infrastructure deployment:

```powershell
cd services/game-service
docker build -t typerush/game-service:latest .
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <ECR_URL>
docker tag typerush/game-service:latest <ECR_URL>/typerush/game-service:latest
docker push <ECR_URL>/typerush/game-service:latest
```

**Placeholder image**: ECS will use a placeholder image initially - service will fail health checks until real image is pushed.

### 4. Database Migrations

**Issue**: RDS database is empty after creation.

**Solution**: Run Prisma migrations for Record Service:

```powershell
cd services/record-service
# Set DATABASE_URL from Secrets Manager
$env:DATABASE_URL = "postgresql://user:pass@<RDS_ENDPOINT>:5432/typerush_records"
npx prisma migrate deploy
```

**Recommended**: Use CodeBuild migration project (Module 25) for automated migrations.

### 5. Cognito JWT Integration

**Note**: API Gateway authorization is **not yet configured** for Cognito.

**Manual step required** after deployment:

1. Get Cognito User Pool ID from outputs
2. Update API Gateway HTTP API with JWT authorizer
3. Reference Cognito issuer URL

**Status**: Infrastructure supports it, but authorization is not enforced by default.

### 6. Domain Name Configuration

**If not using custom domain**:

- Leave `domain_name = ""` in tfvars
- ACM module will skip certificate creation
- Route 53 module will skip zone creation
- CloudFront will use default `*.cloudfront.net` domain

**If using custom domain**:

- Update `domain_name = "typerush.com"` in tfvars
- Set `create_route53_zone = true` if AWS should manage DNS
- Manually verify ACM certificate via email or DNS validation

### 7. NAT Gateway Cost Optimization

**Current**: Single NAT Gateway required ($32.85/month)

**Cannot eliminate** because:

- ECS tasks need internet access during startup
- Lambda cold starts require ENI creation
- CloudWatch Logs writes (no VPC endpoint configured for dev)

**Alternative**: Add CloudWatch Logs VPC endpoint (+$7.20/month) to reduce NAT data transfer, but doesn't eliminate NAT need.

### 8. Terraform State Locking

**With Terraform Cloud**: State locking handled automatically  
**With local state**: No locking - don't run terraform in parallel  
**With S3 backend**: Requires DynamoDB table for locking (must create manually)

---

## 🧪 Post-Deployment Verification

### Step 1: Check Terraform Outputs

```powershell
terraform output
```

**Verify**:

- VPC ID created
- RDS endpoint available
- ElastiCache endpoint available
- ALB DNS name generated
- API Gateway endpoints active

### Step 2: Test Database Connectivity

```powershell
# Get RDS secret from Secrets Manager
aws secretsmanager get-secret-value --secret-id typerush-dev-rds-secret --query SecretString --output text

# Test connection (requires psql client)
psql "postgresql://<USERNAME>:<PASSWORD>@<RDS_ENDPOINT>:5432/typerush_records"
```

### Step 3: Test Redis Connectivity

```powershell
# Get Redis auth token from Secrets Manager
aws secretsmanager get-secret-value --secret-id typerush-dev-elasticache-secret --query SecretString --output text

# Test connection (requires redis-cli)
redis-cli -h <REDIS_ENDPOINT> -p 6379 -a <AUTH_TOKEN> PING
# Expected: PONG
```

### Step 4: Check ECS Service Status

```powershell
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service \
  --region ap-southeast-1
```

**Expected**: Desired count = Running count = 1 (after Docker image is pushed)

### Step 5: Test Lambda Functions

```powershell
# Invoke Record Service Lambda
aws lambda invoke \
  --function-name typerush-dev-record-service \
  --payload '{"path": "/health", "httpMethod": "GET"}' \
  --region ap-southeast-1 \
  response.json

# Check response
cat response.json
```

### Step 6: Test API Gateway Endpoints

```powershell
# Get HTTP API endpoint
$API_ENDPOINT = terraform output -raw api_gateway_http_endpoint

# Test health endpoint (via Game Service)
curl "$API_ENDPOINT/health"

# Test Record Service
curl "$API_ENDPOINT/api/records"

# Test Text Service
curl "$API_ENDPOINT/api/texts"
```

### Step 7: Check CloudWatch Logs

```powershell
# List log groups
aws logs describe-log-groups --region ap-southeast-1 | grep typerush

# Tail ECS logs
aws logs tail /ecs/typerush-dev-game-service --follow --region ap-southeast-1

# Tail Lambda logs
aws logs tail /aws/lambda/typerush-dev-record-service --follow --region ap-southeast-1
```

### Step 8: Verify Monitoring Alarms

```powershell
# List CloudWatch alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix typerush-dev \
  --region ap-southeast-1
```

**Expected**: Multiple alarms in OK or INSUFFICIENT_DATA state

---

## 📊 Important Outputs Reference

After deployment, you'll need these outputs for application configuration:

### Database Connections

| Output                   | Usage                 | Where               |
| ------------------------ | --------------------- | ------------------- |
| `rds_endpoint`           | PostgreSQL connection | Record Service      |
| `rds_secret_arn`         | Database credentials  | Lambda environment  |
| `elasticache_endpoint`   | Redis connection      | Game Service        |
| `elasticache_secret_arn` | Redis auth token      | ECS task definition |

### API Endpoints

| Output                      | Usage                | Where           |
| --------------------------- | -------------------- | --------------- |
| `api_gateway_http_endpoint` | REST API base URL    | Frontend config |
| `api_gateway_ws_endpoint`   | WebSocket API URL    | Frontend config |
| `cloudfront_domain_name`    | CDN URL for frontend | DNS CNAME       |

### Container & Lambda

| Output                 | Usage                 | Where                   |
| ---------------------- | --------------------- | ----------------------- |
| `ecr_game_service_url` | Docker image registry | CI/CD, local build      |
| `record_lambda_name`   | Lambda function name  | API Gateway integration |
| `text_lambda_name`     | Lambda function name  | API Gateway integration |

### Authentication

| Output                 | Usage                 | Where                |
| ---------------------- | --------------------- | -------------------- |
| `cognito_user_pool_id` | User pool identifier  | Frontend auth config |
| `cognito_client_id`    | App client ID         | Frontend auth config |
| `cognito_domain`       | Cognito hosted UI URL | OAuth redirects      |

---

## 🗑️ Teardown Instructions

**IMPORTANT**: Remember to destroy resources after testing to avoid ongoing costs!

### Quick Destroy (All Resources)

```powershell
cd d:\Repository\TypeRushService\infras
terraform destroy -var-file="dev.auto.tfvars"
```

**Estimated time**: 15-30 minutes

### Manual Pre-Destroy Steps

Some resources may need manual cleanup:

1. **Empty S3 Bucket** (if versioning enabled):

```powershell
aws s3 rm s3://typerush-dev-frontend --recursive
```

2. **Delete ECR Images** (optional - will auto-delete with repository):

```powershell
aws ecr batch-delete-image \
  --repository-name typerush/game-service \
  --image-ids imageTag=latest \
  --region ap-southeast-1
```

3. **Delete Log Groups** (optional - will auto-delete):

```powershell
aws logs delete-log-group --log-group-name /ecs/typerush-dev-game-service
```

### Verify Complete Deletion

```powershell
# Check no resources remain
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=typerush \
  --region ap-southeast-1
```

**Expected**: No resources found

---

## 📚 Next Steps

### Before Running Terraform Plan

1. ✅ Update email addresses in `dev.auto.tfvars`
2. ✅ Configure Terraform backend (Cloud, Local, or S3)
3. ✅ Verify AWS credentials with `aws sts get-caller-identity`
4. ✅ Review cost estimates and confirm budget
5. ✅ Read through deployment strategy options

### To Generate Terraform Plan

```powershell
cd d:\Repository\TypeRushService\infras
terraform plan -var-file="dev.auto.tfvars" -out=tfplan
```

This will:

- Show all resources that will be created
- Estimate infrastructure changes
- Save plan to `tfplan` file for review

### After Reviewing Plan

If everything looks correct:

```powershell
terraform apply tfplan
```

Or re-run with auto-approve (not recommended for first deployment):

```powershell
terraform apply -var-file="dev.auto.tfvars" -auto-approve
```

---

## 🆘 Troubleshooting Common Issues

### Issue: "Error: No valid credential sources found"

**Solution**: Configure AWS credentials

```powershell
aws configure
```

### Issue: "Error: Backend initialization required"

**Solution**:

```powershell
terraform init
```

### Issue: "Error: Workspace 'typerush-dev' not found"

**Solution**:

- Login to Terraform Cloud and create workspace, OR
- Switch to local backend by removing `backend "remote"` block

### Issue: VPC Link creation takes too long (15+ minutes)

**Solution**: This is normal - VPC Links can take 15-20 minutes to create. Be patient.

### Issue: ECS tasks failing health checks

**Solution**:

1. Verify Game Service Docker image exists in ECR
2. Check Game Service has `/health` endpoint implemented
3. Review ECS task logs in CloudWatch

### Issue: Lambda "Cannot connect to database"

**Solution**:

1. Verify Lambda is in VPC with correct security group
2. Check RDS security group allows Lambda security group
3. Verify Secrets Manager secret contains correct credentials
4. Run Prisma migrations to create tables

---

## ✅ Sign-Off Checklist

Before proceeding with `terraform apply`, confirm:

- [ ] Email addresses updated in `dev.auto.tfvars`
- [ ] Terraform backend configured (Cloud, Local, or S3)
- [ ] AWS credentials configured and tested
- [ ] Budget confirmed (willing to spend ~$4-5/day)
- [ ] Understand deployment will take 60-90 minutes
- [ ] Plan to destroy resources after testing (to save costs)
- [ ] Read through verification steps for post-deployment
- [ ] Know how to access CloudWatch logs for troubleshooting

---

## 📞 Support Resources

- **Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Documentation**: https://docs.aws.amazon.com/
- **TypeRush Architecture**: `docs/architecture-diagram.md`
- **Step-by-Step Guide**: `infras/steps/00_overview.md`

---

**Report Generated By**: GitHub Copilot with AWS Knowledge, Terraform, and Context7 MCP servers  
**Validation Status**: ✅ All checks passed - Ready for planning phase
