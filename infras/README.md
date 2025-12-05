# TypeRush AWS Infrastructure - Terraform

This repository contains Infrastructure as Code (IaC) for the TypeRush typing game application, designed as a **learning project** to understand AWS services and Terraform.

## 🎯 Project Goal

Learn AWS by building a complete microservices architecture, then **tear it down** to avoid ongoing costs (~$15-20 for 3-4 days).

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.5.0 ([Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
3. **AWS CLI** configured (`aws configure`)
4. **Text Editor** (VS Code recommended)

## 🏗️ Architecture Overview

- **Region**: ap-southeast-1 (Singapore)
- **Deployment**: Single-AZ (dev cost optimization)
- **Monthly Cost**: ~$105-120 (or ~$15-20 for 3-4 days)

### Key Components

1. **VPC & Networking**: 4 subnets (public, private, database, cache) + NAT Gateway
2. **Compute**: ECS Fargate (Game Service) + Lambda (Record & Text Services)
3. **Data**: RDS PostgreSQL (single instance), ElastiCache Redis, DynamoDB
4. **API**: API Gateway (HTTP + WebSocket), ALB (internal)
5. **CDN**: CloudFront + WAF
6. **CI/CD**: CodePipeline + CodeBuild + ECR
7. **Monitoring**: CloudWatch + SNS

## 🚀 Quick Start

### Step 1: Configure Variables

```bash
cd infras
cp env/dev.tfvars env/dev.tfvars.local
```

Edit `env/dev.tfvars.local` and update:

- `owner` = "your-email@example.com"
- `alert_email` = "your-email@example.com"

### Step 2: Initialize Terraform

```powershell
terraform init
```

### Step 3: Plan Deployment

```powershell
terraform plan -var-file="env/dev.tfvars.local"
```

### Step 4: Deploy Infrastructure

```powershell
# Deploy networking first
terraform apply -var-file="env/dev.tfvars.local" -target=module.networking

# Review and confirm
```

### Step 5: Deploy Remaining Resources

```powershell
# Full deployment (once networking is complete)
terraform apply -var-file="env/dev.tfvars.local"
```

## 📦 Module Structure

```
infras/
├── main.tf              # Root orchestration
├── variables.tf         # Input variables
├── outputs.tf           # Exported values
├── provider.tf          # AWS provider config
├── terraform.tf         # Terraform version constraints
├── env/
│   └── dev.tfvars       # Dev environment variables
├── modules/
│   ├── 01-networking/         # VPC, Subnets, NAT, IGW
│   ├── 02-security-groups/    # Security Groups
│   ├── 03-iam/                # IAM roles and policies
│   ├── 04-secrets-manager/    # Secrets Manager
│   ├── 05-vpc-endpoints/      # VPC endpoints
│   ├── 06-rds/                # RDS PostgreSQL
│   ├── 07-elasticache/        # ElastiCache Redis
│   ├── 08-dynamodb/           # DynamoDB tables
│   ├── 09-ecr/                # ECR repositories
│   ├── 10-ecs/                # ECS cluster & services
│   ├── 11-lambda/             # Lambda functions
│   ├── 12-alb/                # Internal ALB
│   ├── 13-api-gateway/        # API Gateway (HTTP + WebSocket)
│   ├── 14-cloudfront-waf/     # CloudFront & WAF
│   ├── 15-route53/            # Route 53 DNS
│   ├── 16-acm/                # ACM SSL certificates
│   ├── 17-cognito/            # Cognito User Pool
│   ├── 18-s3/                 # S3 Frontend bucket
│   ├── 19-codebuild/          # CodeBuild projects
│   ├── 20-codepipeline/       # CodePipeline CI/CD
│   ├── 21-cloudwatch/         # CloudWatch logs & alarms
│   └── 22-sns/                # SNS topics
└── steps/
    ├── 00_overview.md                # Project overview
    ├── 01_foundation.md              # Foundation setup
    ├── 02_networking.md              # VPC & Networking
    ├── 03_security_groups.md         # Security groups
    ├── 04_iam_roles.md               # IAM roles
    ├── 05_secrets_manager.md         # Secrets management
    ├── 06_vpc_endpoints.md           # VPC endpoints
    ├── 07_rds_postgresql.md          # RDS database
    ├── 08_elasticache_redis.md       # Redis cache
    ├── 09_dynamodb.md                # DynamoDB
    ├── 10_ecr_repositories.md        # Container registry
    ├── 11_ecs_cluster.md             # ECS cluster
    ├── 12_lambda_functions.md        # Lambda functions
    ├── 13_internal_alb.md            # Internal ALB
    ├── 14_api_gateway.md             # API Gateway
    ├── 15_cloudfront_waf.md          # CloudFront & WAF
    ├── 16_route53_dns.md             # DNS configuration
    ├── 17_acm_certificates.md        # SSL certificates
    ├── 18_cognito_user_pool.md       # User authentication
    ├── 19_s3_frontend_bucket.md      # Frontend hosting
    ├── 20_codebuild_projects.md      # Build projects
    ├── 21_codepipeline.md            # CI/CD pipeline
    ├── 22_cloudwatch_monitoring.md   # Monitoring & alarms
    ├── 23_sns_topics.md              # Alerting topics
    ├── 24_testing_validation.md      # Testing procedures
    └── 25_cleanup_teardown.md        # Teardown guide
```

**Implementation Status**: Steps 01-12 documented with detailed guides, Steps 13-25 completed

## 💰 Cost Breakdown

### Running Costs (per day)

| Service           | Monthly   | Per Day (3-4 days)        |
| ----------------- | --------- | ------------------------- |
| NAT Gateway       | $32.85    | $1.10/day × 4 = **$4.40** |
| VPC Endpoints (4) | $28.80    | $0.96/day × 4 = **$3.84** |
| RDS db.t3.micro   | $14.40    | $0.48/day × 4 = **$1.92** |
| ElastiCache       | $12.41    | $0.41/day × 4 = **$1.64** |
| ECS Fargate       | $10.88    | $0.36/day × 4 = **$1.44** |
| Internal ALB      | $16.20    | $0.54/day × 4 = **$2.16** |
| Lambda/API/misc   | ~$5.00    | ~**$0.67**                |
| **Total**         | **~$120** | **~$16** for 4 days       |

### 💡 Cost Optimization Tips

1. **Destroy after learning**: `terraform destroy` when done
2. **Use RDS snapshots**: Backup before destroying (~$0.10/GB/month)
3. **Skip optional modules**: Route 53, ACM, CloudFront for basics
4. **Monitor costs**: Set up AWS Budget alerts

## 🗑️ Teardown (Important!)

When you're done learning, destroy all resources:

```powershell
# Preview what will be destroyed
terraform plan -destroy -var-file="env/dev.tfvars.local"

# Destroy all resources
terraform destroy -var-file="env/dev.tfvars.local"

# Confirm deletion
```

**Note**: Some resources may require manual deletion:

- S3 buckets with objects
- ECR repositories with images
- CloudWatch log groups (if retention is set)

## 🔐 Security Best Practices

1. **Never commit `dev.tfvars.local`** (contains sensitive data)
2. **Use AWS Secrets Manager** for database passwords
3. **Enable MFA** on your AWS account
4. **Review IAM permissions** regularly
5. **Use least-privilege security groups**

## 📚 Learning Resources

### AWS Services Used

- [VPC Networking](https://docs.aws.amazon.com/vpc/)
- [ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Lambda](https://docs.aws.amazon.com/lambda/)
- [RDS PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/)
- [ElastiCache Redis](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)
- [API Gateway](https://docs.aws.amazon.com/apigateway/)

### Terraform Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🐛 Troubleshooting

### Error: "No valid credential sources found"

```powershell
aws configure
# Enter your AWS Access Key ID and Secret Access Key
```

### Error: "Error creating VPC"

Check your AWS account limits:

```powershell
aws ec2 describe-account-attributes --attribute-names max-vpcs
```

### Error: "Insufficient permissions"

Ensure your IAM user has these policies:

- `AmazonVPCFullAccess`
- `AmazonEC2FullAccess`
- `AmazonRDSFullAccess`
- `AWSLambda_FullAccess`
- `AmazonS3FullAccess`

## 📞 Support

This is a learning project. For issues:

1. Check AWS CloudWatch Logs
2. Review Terraform state: `terraform show`
3. Validate configuration: `terraform validate`

## ⚠️ Important Reminders

- **This is a DEV environment** - not production-ready
- **Costs accrue hourly** - destroy when not in use
- **Single-AZ deployment** - expect downtime if AZ fails
- **Minimal security** - suitable for learning only

## 📝 Deployment Roadmap

### Phase 1: Foundation (Steps 1-6)

1. ✅ **Networking**: VPC, subnets, NAT Gateway, Internet Gateway
2. ✅ **Security Groups**: ALB, ECS, Lambda, RDS, ElastiCache rules
3. ✅ **IAM Roles**: ECS task, Lambda execution, CodePipeline, CodeBuild roles
4. ✅ **Secrets Manager**: RDS credentials, ElastiCache auth token
5. ✅ **VPC Endpoints**: Secrets Manager, ECR, S3, DynamoDB, Bedrock (private access)
6. 📝 Verify: Private subnet can access AWS services without internet

### Phase 2: Data Layer (Steps 7-9)

7. ✅ **RDS PostgreSQL**: Single-AZ db.t3.micro for Record Service
   - **Environment Variables for Record Service**:
     - `DATABASE_URL`: PostgreSQL connection string (retrieve from Terraform output or Secrets Manager)
     - Format: `postgresql://username:password@<rds_endpoint>/typerush_records?sslmode=require`
     - Get endpoint: `terraform output rds_endpoint`
     - Get credentials: `aws secretsmanager get-secret-value --secret-id typerush/record-db/credentials`
8. ✅ **ElastiCache Redis**: Single-node cache.t4g.micro for session state
   - **Environment Variables for Game Service**:
     - `REDIS_ENDPOINT`: Redis primary endpoint address (retrieve from Terraform output)
     - `REDIS_PORT`: Redis port (default 6379)
     - `REDIS_AUTH_TOKEN`: Redis AUTH token (retrieve from Secrets Manager)
     - `REDIS_TLS_ENABLED`: Set to `true` (encryption in transit enabled)
     - Get endpoint: `terraform output redis_primary_endpoint`
     - Get AUTH token: `aws secretsmanager get-secret-value --secret-id typerush/elasticache/auth-token --query SecretString --output text | jq -r .auth_token`
     - Connection string format: `rediss://default:AUTH_TOKEN@<redis_endpoint>:6379`
9. ✅ **DynamoDB**: On-demand table for text storage
10. 📝 Verify: Database connections, Redis ping, DynamoDB read/write

### Phase 3: Container Registry (Step 10)

10. ✅ **ECR Repositories**: game-service, record-service Docker images
11. 📝 Verify: Push test image, image scanning enabled

### Phase 4: Compute Layer (Steps 11-12)

11. ✅ **ECS Cluster**: Fargate cluster with Game Service (0.25 vCPU, 0.5GB)
12. ✅ **Lambda Functions**: Record Service (NestJS+Prisma), Text Service (Python+FastAPI)
13. 📝 Verify: ECS tasks running, Lambda test invocations

### Phase 5: Load Balancing & API (Steps 13-14)

13. ✅ **Internal ALB**: Private load balancer for Game Service
14. ✅ **API Gateway**: HTTP API + WebSocket API with VPC Link, JWT authorizer
15. 📝 Verify: ALB health checks, API Gateway routes, VPC Link connection

### Phase 6: CDN & Security (Steps 15-17)

15. ✅ **CloudFront & WAF**: CDN distribution, rate limiting, managed rules
16. ✅ **Route 53**: DNS hosted zone, A/AAAA records (optional for dev)
17. ✅ **ACM Certificates**: SSL/TLS certificates (us-east-1 for CloudFront)
18. 📝 Verify: HTTPS working, WAF blocking malicious requests

### Phase 7: Authentication & Frontend (Steps 18-19)

18. ✅ **Cognito**: User Pool, app client, JWT tokens
19. ✅ **S3 Frontend**: Static website bucket with CloudFront OAC
20. 📝 Verify: User sign-up/sign-in, JWT validation, frontend served via CloudFront

### Phase 8: CI/CD Pipeline (Steps 20-21)

20. ✅ **CodeBuild**: Build projects for Docker images, Lambda packages, migrations
21. ✅ **CodePipeline**: Automated pipelines for all services
22. 📝 Verify: GitLab webhook triggers, builds succeed, deployments complete

### Phase 9: Monitoring & Alerting (Steps 22-23)

22. ✅ **CloudWatch**: Log groups, metric alarms, dashboards
23. ✅ **SNS Topics**: Email notifications for alarms and deployments
24. 📝 Verify: Logs being captured, alarms triggering, emails received

### Phase 10: Testing & Teardown (Steps 24-25)

24. ✅ **Testing**: End-to-end validation, performance benchmarks
25. ✅ **Cleanup**: Safe teardown procedures, cost verification

## 🚀 Quick Start Guide

### Minimal Dev Setup (Steps 1-14, ~$70/month)

```powershell
# Essential infrastructure only
terraform apply -var-file="env/dev.tfvars.local" `
  -target=module.networking `
  -target=module.security_groups `
  -target=module.iam `
  -target=module.secrets_manager `
  -target=module.vpc_endpoints `
  -target=module.rds `
  -target=module.elasticache `
  -target=module.dynamodb `
  -target=module.ecr `
  -target=module.ecs `
  -target=module.lambda `
  -target=module.alb `
  -target=module.api_gateway
```

### Full Production-Like Setup (Steps 1-23, ~$120/month)

```powershell
# Complete infrastructure with CDN, monitoring, CI/CD
terraform apply -var-file="env/dev.tfvars.local"
```

### Skip Optional Components (Save ~$20/month)

- Route 53 ($0.50/month) - Use API Gateway default URLs
- ACM Certificates (FREE) - Required for custom domains
- CloudFront ($2/month) - Direct API Gateway access
- CloudWatch detailed logs ($3/month) - Reduce retention to 1 day

## 🎓 What You'll Learn

### AWS Services

- **Networking**: VPC, subnets, NAT Gateway, VPC endpoints, private/public routing
- **Compute**: ECS Fargate (containers), Lambda (serverless), auto-scaling
- **Storage**: RDS PostgreSQL (relational), ElastiCache Redis (cache), DynamoDB (NoSQL), S3 (object storage)
- **Networking & Content Delivery**: CloudFront CDN, Route 53 DNS, ALB (Layer 7), VPC Link
- **Security**: WAF rules, Cognito authentication, IAM roles, security groups, Secrets Manager
- **Developer Tools**: CodePipeline, CodeBuild, ECR (container registry)
- **Monitoring**: CloudWatch Logs, CloudWatch Alarms, SNS notifications
- **Certificates**: ACM SSL/TLS certificates

### Infrastructure as Code

- Terraform module design and composition
- Resource dependencies and ordering
- State management and outputs
- Variable interpolation and locals
- Conditional resource creation
- Count and for_each patterns

### Deployment Patterns

- Blue-green deployments with ECS
- Lambda deployment packages
- Database migration strategies
- Immutable infrastructure
- VPC Link for private API integration
- CloudFront cache invalidation

### Cost Optimization

- Single-AZ vs Multi-AZ trade-offs
- NAT Gateway vs VPC endpoints
- On-demand vs provisioned capacity
- Resource right-sizing
- Log retention policies
- Development vs production configurations

## 📚 Step-by-Step Guides

All 25 implementation steps are documented in the `steps/` directory:

### Foundation (Steps 1-6)

- **Step 01**: Foundation & AWS setup
- **Step 02**: VPC & Networking (public, private, database, cache subnets)
- **Step 03**: Security Groups (ALB, ECS, Lambda, RDS, ElastiCache, VPC endpoints)
- **Step 04**: IAM Roles (ECS task, Lambda execution, CodePipeline, CodeBuild)
- **Step 05**: Secrets Manager (RDS credentials, ElastiCache auth token)
- **Step 06**: VPC Endpoints (Secrets Manager, ECR, S3, DynamoDB, Bedrock)

### Data & Storage (Steps 7-10)

- **Step 07**: RDS PostgreSQL (single-AZ, db.t3.micro)
- **Step 08**: ElastiCache Redis (single-node, cache.t4g.micro)
- **Step 09**: DynamoDB (on-demand table for texts)
- **Step 10**: ECR Repositories (Docker image storage)

### Compute (Steps 11-12)

- **Step 11**: ECS Cluster (Fargate, Game Service, auto-scaling)
- **Step 12**: Lambda Functions (Record Service + Text Service)

### API & Load Balancing (Steps 13-14)

- **Step 13**: Internal ALB (private load balancer for ECS)
- **Step 14**: API Gateway (HTTP API + WebSocket, VPC Link, JWT authorizer)

### CDN & DNS (Steps 15-17)

- **Step 15**: CloudFront & WAF (CDN, rate limiting, security rules)
- **Step 16**: Route 53 DNS (hosted zone, A/AAAA records)
- **Step 17**: ACM Certificates (SSL/TLS for CloudFront & API Gateway)

### Authentication & Frontend (Steps 18-19)

- **Step 18**: Cognito User Pool (authentication, JWT tokens)
- **Step 19**: S3 Frontend Bucket (static website hosting)

### CI/CD (Steps 20-21)

- **Step 20**: CodeBuild Projects (Docker builds, migrations)
- **Step 21**: CodePipeline (automated deployments)

### Monitoring (Steps 22-23)

- **Step 22**: CloudWatch Monitoring (logs, metrics, alarms, dashboards)
- **Step 23**: SNS Topics (email notifications for alarms)

### Testing & Cleanup (Steps 24-25)

- **Step 24**: Testing & Validation (comprehensive testing procedures)
- **Step 25**: Cleanup & Teardown (safe infrastructure destruction)

## 🔗 Additional Resources

- [Architecture Diagram](docs/architecture-diagram.md) - Detailed Mermaid diagrams
- [Deployment Guide](infras/DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

Happy Learning! 🚀

---

**Remember**: This is a learning project. Destroy infrastructure after use to avoid costs (~$4/day = $120/month). See Step 25 for teardown procedures.
