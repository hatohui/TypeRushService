# TypeRush Infrastructure Verification & Deployment Guide

**Last Updated**: December 5, 2025  
**Environment**: dev (ap-southeast-1)

---

## 📋 Quick Status Check

### ✅ Successfully Deployed Infrastructure

Run this command to see all outputs:

```bash
cd infras && terraform output
```

**Key Components Deployed:**

- ✅ VPC with networking (NAT Gateway, Subnets)
- ✅ RDS PostgreSQL (10.0.10.210:5432)
- ✅ ElastiCache Redis (typerush-dev-redis.4fjuaq.0001.apse1.cache.amazonaws.com:6379)
- ✅ DynamoDB (typerush-dev-texts)
- ✅ ECR Repositories (game-service, record-service, text-service)
- ✅ ECS Cluster with Game Service task definition
- ✅ Internal ALB
- ✅ Lambda Functions (Record Service, Text Service) - Placeholder code
- ✅ API Gateway HTTP (n337ebtno3.execute-api.ap-southeast-1.amazonaws.com)
- ✅ API Gateway WebSocket
- ✅ CloudFront Distribution (d2xzaxd1v11d8p.cloudfront.net)
- ✅ S3 Frontend Bucket
- ✅ Cognito User Pool
- ✅ VPC Endpoints (Secrets Manager, Bedrock, S3, DynamoDB)
- ✅ IAM Roles for all services
- ✅ CodeBuild projects
- ❌ CodePipeline (intentionally disabled by default)

---

## 🔗 Connectivity Testing

### 1. Check VPC Connectivity

**VPC Endpoints Status:**

```bash
# View VPC endpoints
terraform output vpc_endpoints_summary

# Test from AWS Console
# EC2 → VPC → Endpoints → Verify all are "Available"
```

**Deployed VPC Endpoints:**

- Secrets Manager (Interface)
- Bedrock Runtime (Interface)
- S3 (Gateway)
- DynamoDB (Gateway)

### 2. Test Database Connectivity

#### RDS PostgreSQL

```bash
# Get RDS endpoint
terraform output rds_endpoint

# From a bastion host or VPC resource:
psql -h $(terraform output -raw rds_address) \
     -p 5432 \
     -U typerush_admin \
     -d typerush_db

# Password is stored in Secrets Manager:
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw rds_secret_arn) \
  --query SecretString --output text | jq -r .password
```

#### ElastiCache Redis

```bash
# Get Redis endpoint
terraform output redis_endpoint

# Test from VPC (requires redis-cli):
redis-cli -h $(terraform output -raw redis_endpoint) \
          -p 6379 \
          --tls \
          -a "$(aws secretsmanager get-secret-value --secret-id $(terraform output -raw elasticache_secret_arn) --query SecretString --output text | jq -r .authToken)" \
          PING
# Expected: PONG
```

#### DynamoDB

```bash
# Test DynamoDB access
aws dynamodb describe-table \
  --table-name $(terraform output -raw dynamodb_texts_table_name)

# List items (should be empty initially)
aws dynamodb scan \
  --table-name $(terraform output -raw dynamodb_texts_table_name) \
  --limit 10
```

### 3. Test Lambda Functions

#### Text Service Lambda

```bash
# Get function name
terraform output text_service_function_name

# Invoke Lambda (will return 503 - placeholder code)
aws lambda invoke \
  --function-name $(terraform output -raw text_service_function_name) \
  --payload '{"action":"test"}' \
  response.json

cat response.json
# Expected: {"statusCode": 503, "body": "{\"message\": \"Lambda not deployed yet..."}
```

#### Record Service Lambda

```bash
# Invoke Record Service
aws lambda invoke \
  --function-name $(terraform output -raw record_service_function_name) \
  --payload '{"action":"test"}' \
  response.json

cat response.json
# Expected: {"statusCode": 503, "body": "{\"message\": \"Lambda not deployed yet..."}
```

### 4. Test ECS Service

```bash
# Check if ECS service is running
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw game_service_name)

# Check task status
aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name $(terraform output -raw game_service_name)

# NOTE: Service won't run yet because there's NO DOCKER IMAGE in ECR
# You need to push an image first (see below)
```

### 5. Test Internal ALB

```bash
# Get ALB DNS name
terraform output internal_alb_dns_name

# Test from inside VPC (requires bastion or Cloud9)
curl http://$(terraform output -raw internal_alb_dns_name)/health
# Expected: 502 Bad Gateway (no ECS tasks running yet)
```

### 6. Test API Gateway

```bash
# HTTP API (for Lambda functions)
HTTP_API=$(terraform output -raw http_api_endpoint)
echo "HTTP API: $HTTP_API"

# Test record service endpoint
curl $HTTP_API/records/health
# Expected: 503 or timeout (placeholder Lambda)

# Test text service endpoint
curl $HTTP_API/texts/health
# Expected: 503 or timeout (placeholder Lambda)

# WebSocket API
WS_API=$(terraform output -raw websocket_api_endpoint)
echo "WebSocket API: $WS_API"
# Test with wscat: wscat -c $WS_API
```

### 7. Test CloudFront

```bash
# Get CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_distribution_url)
echo "CloudFront: $CLOUDFRONT_URL"

# Test access
curl -I $CLOUDFRONT_URL
# Expected: 200 OK or 403 Forbidden (if S3 bucket empty)

# Check distribution status
aws cloudfront get-distribution \
  --id $(terraform output -raw cloudfront_distribution_id) \
  --query 'Distribution.Status'
# Expected: "Deployed"
```

---

## 🚀 Deploy Application Code

### Step 1: Build & Push Docker Image for Game Service

```bash
# Navigate to game service directory
cd services/game-service

# Get ECR repository URL
ECR_REPO=$(cd ../../infras && terraform output -raw game_service_repository_url)
AWS_REGION="ap-southeast-1"
AWS_ACCOUNT_ID="630633962130"

echo "ECR Repository: $ECR_REPO"

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
docker build -t typerush/game-service:latest .

# Tag for ECR
docker tag typerush/game-service:latest $ECR_REPO:latest

# Push to ECR
docker push $ECR_REPO:latest

# Verify image in ECR
aws ecr list-images --repository-name typerush/game-service
```

### Step 2: Update ECS Service to Use New Image

```bash
# Force new deployment with the pushed image
aws ecs update-service \
  --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service \
  --force-new-deployment

# Monitor deployment
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service \
  --query 'services[0].deployments'

# Watch tasks starting
aws ecs list-tasks \
  --cluster typerush-dev-ecs-cluster \
  --service-name typerush-dev-game-service

# Check task logs in CloudWatch:
# Log group: /ecs/typerush-dev-game-service
```

### Step 3: Deploy Lambda Functions Manually

#### Option A: Using AWS CLI (Quick)

**Record Service:**

```bash
cd services/record-service

# Package Lambda code
zip -r record-service.zip src/ package.json package-lock.json node_modules/

# Update Lambda function
aws lambda update-function-code \
  --function-name typerush-dev-record-service \
  --zip-file fileb://record-service.zip

# Wait for update
aws lambda wait function-updated \
  --function-name typerush-dev-record-service

# Test
aws lambda invoke \
  --function-name typerush-dev-record-service \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json && cat response.json
```

**Text Service:**

```bash
cd services/text-service

# Package Lambda code
zip -r text-service.zip lambda_handler.py controllers/ requirements.txt

# Update Lambda function
aws lambda update-function-code \
  --function-name typerush-dev-text-service \
  --zip-file fileb://text-service.zip

# Wait for update
aws lambda wait function-updated \
  --function-name typerush-dev-text-service

# Test
aws lambda invoke \
  --function-name typerush-dev-text-service \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json && cat response.json
```

#### Option B: Using CodeBuild (Automated - via CodePipeline)

**Enable CodePipeline in Terraform:**

Edit `infras/dev.auto.tfvars`:

```hcl
# Enable CI/CD Pipelines
create_game_service_pipeline    = true
create_record_service_pipeline  = true
create_text_service_pipeline    = true
create_frontend_pipeline        = true
```

Apply changes:

```bash
cd infras
terraform apply
```

**Trigger Pipelines Manually:**

```bash
# Trigger Game Service pipeline
aws codepipeline start-pipeline-execution \
  --name typerush-dev-game-service

# Trigger Record Service pipeline
aws codepipeline start-pipeline-execution \
  --name typerush-dev-record-service

# Trigger Text Service pipeline
aws codepipeline start-pipeline-execution \
  --name typerush-dev-text-service

# Trigger Frontend pipeline
aws codepipeline start-pipeline-execution \
  --name typerush-dev-frontend

# Monitor pipeline status
aws codepipeline get-pipeline-state \
  --name typerush-dev-game-service
```

**Or Push to GitHub (Automatic Trigger):**

```bash
# CodePipeline watches your GitHub repository
# Any push to main/master branch triggers deployment automatically

git add .
git commit -m "Deploy services"
git push origin main

# Watch in AWS Console:
# CodePipeline → Pipelines → Select pipeline → View progress
```

### Step 4: Deploy Frontend

```bash
cd frontend

# Install dependencies
npm install

# Build frontend
npm run build

# Get S3 bucket name
S3_BUCKET=$(cd ../infras && terraform output -raw frontend_bucket_name)

# Sync to S3
aws s3 sync dist/ s3://$S3_BUCKET/ --delete

# Invalidate CloudFront cache
CLOUDFRONT_ID=$(cd ../infras && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_ID \
  --paths "/*"

# Test
CLOUDFRONT_URL=$(cd ../infras && terraform output -raw cloudfront_distribution_url)
curl $CLOUDFRONT_URL
```

---

## 🧪 End-to-End Testing Script

Create this script to test everything:

```bash
#!/bin/bash
# test-infrastructure.sh

set -e

echo "🔍 TypeRush Infrastructure Verification"
echo "========================================"

cd infras

# 1. Check Terraform state
echo "✅ Checking Terraform outputs..."
terraform output > /dev/null && echo "✓ Terraform state OK" || exit 1

# 2. Check DynamoDB
echo "✅ Testing DynamoDB..."
aws dynamodb describe-table --table-name $(terraform output -raw dynamodb_texts_table_name) > /dev/null && echo "✓ DynamoDB accessible"

# 3. Check Lambda functions
echo "✅ Testing Lambda functions..."
aws lambda get-function --function-name $(terraform output -raw text_service_function_name) > /dev/null && echo "✓ Text Service Lambda exists"
aws lambda get-function --function-name $(terraform output -raw record_service_function_name) > /dev/null && echo "✓ Record Service Lambda exists"

# 4. Check ECR repositories
echo "✅ Testing ECR repositories..."
aws ecr describe-repositories --repository-names typerush/game-service > /dev/null && echo "✓ Game Service ECR exists"
aws ecr describe-repositories --repository-names typerush/record-service > /dev/null && echo "✓ Record Service ECR exists"
aws ecr describe-repositories --repository-names typerush/text-service > /dev/null && echo "✓ Text Service ECR exists"

# 5. Check ECS cluster
echo "✅ Testing ECS cluster..."
aws ecs describe-clusters --clusters $(terraform output -raw ecs_cluster_name) > /dev/null && echo "✓ ECS Cluster exists"

# 6. Check API Gateways
echo "✅ Testing API Gateways..."
aws apigatewayv2 get-api --api-id $(terraform output -raw http_api_id) > /dev/null && echo "✓ HTTP API exists"
aws apigatewayv2 get-api --api-id $(terraform output -raw websocket_api_id) > /dev/null && echo "✓ WebSocket API exists"

# 7. Check CloudFront
echo "✅ Testing CloudFront..."
aws cloudfront get-distribution --id $(terraform output -raw cloudfront_distribution_id) > /dev/null && echo "✓ CloudFront Distribution exists"

# 8. Check Cognito
echo "✅ Testing Cognito..."
aws cognito-idp describe-user-pool --user-pool-id $(terraform output -raw cognito_user_pool_id) > /dev/null && echo "✓ Cognito User Pool exists"

echo ""
echo "🎉 All infrastructure components verified!"
echo ""
echo "📊 Quick Stats:"
echo "  VPC: $(terraform output -raw vpc_id)"
echo "  ECS Cluster: $(terraform output -raw ecs_cluster_name)"
echo "  HTTP API: $(terraform output -raw http_api_endpoint)"
echo "  CloudFront: $(terraform output -raw cloudfront_distribution_url)"
echo ""
echo "Next steps:"
echo "  1. Push Docker image: See 'Deploy Application Code' section"
echo "  2. Deploy Lambda code: See Step 3 in deployment guide"
echo "  3. Deploy frontend: See Step 4 in deployment guide"
```

Make it executable and run:

```bash
chmod +x test-infrastructure.sh
./test-infrastructure.sh
```

---

## 📊 Monitoring & Logs

### CloudWatch Log Groups

```bash
# Game Service logs
aws logs tail /ecs/typerush-dev-game-service --follow

# Record Service Lambda logs
aws logs tail /aws/lambda/typerush-dev-record-service --follow

# Text Service Lambda logs
aws logs tail /aws/lambda/typerush-dev-text-service --follow

# CodeBuild logs
aws logs tail /aws/codebuild/typerush-dev-game-service --follow
```

### Check Service Health

```bash
# ECS Service
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Health:healthCheckGracePeriodSeconds}'

# Lambda concurrency
aws lambda get-function-concurrency \
  --function-name typerush-dev-text-service

# ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $(cd infras && terraform output -raw game_service_target_group_arn)
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: ECS Service Not Starting

**Symptom**: No tasks running, service stuck at 0/1 running
**Cause**: No Docker image in ECR
**Solution**: Push Docker image first (see Step 1 above)

### Issue 2: Lambda Returns 503

**Symptom**: Lambda invocation returns `{"statusCode": 503}`
**Cause**: Placeholder code still deployed
**Solution**: Deploy actual Lambda code (see Step 3 above)

### Issue 3: CloudFront Returns 403

**Symptom**: CloudFront URL returns "AccessDenied"
**Cause**: S3 bucket is empty
**Solution**: Deploy frontend (see Step 4 above)

### Issue 4: ALB Health Checks Failing

**Symptom**: Target group shows unhealthy targets
**Cause**: ECS task not responding on /health endpoint
**Solutions**:

1. Check ECS task logs: `aws logs tail /ecs/typerush-dev-game-service`
2. Verify security group allows ALB → ECS traffic
3. Ensure health endpoint returns 200

### Issue 5: Lambda Can't Connect to RDS

**Symptom**: Lambda times out when accessing database
**Cause**: VPC configuration or security groups
**Solutions**:

1. Verify Lambda is in same VPC as RDS
2. Check Lambda security group allows outbound to RDS port
3. Check RDS security group allows inbound from Lambda SG

### Issue 6: Can't Connect to ElastiCache

**Symptom**: Redis connection timeout
**Cause**: TLS/AUTH requirements or VPC configuration
**Solutions**:

1. Use `--tls` flag with redis-cli
2. Provide AUTH token from Secrets Manager
3. Verify security groups allow port 6379

---

## 💰 Cost Management

### Check Current Costs

```bash
# This month's costs (requires AWS Cost Explorer enabled)
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --filter file://<(echo '{
    "Tags": {
      "Key": "Project",
      "Values": ["typerush"]
    }
  }')
```

### Stop Services to Reduce Costs

```bash
# Scale ECS service to 0
aws ecs update-service \
  --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service \
  --desired-count 0

# Disable API Gateway stages (won't be charged for idle)
# DynamoDB on-demand: only pay for actual usage
# Lambda: only pay for invocations
```

### Destroy Everything When Done

```bash
cd infras
terraform destroy
```

---

## 🎯 Quick Reference

**Essential Commands:**

```bash
# See all outputs
cd infras && terraform output

# Get specific value
terraform output -raw game_service_repository_url

# Push Docker image
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 630633962130.dkr.ecr.ap-southeast-1.amazonaws.com
docker build -t typerush/game-service .
docker tag typerush/game-service:latest $(cd infras && terraform output -raw game_service_repository_url):latest
docker push $(cd infras && terraform output -raw game_service_repository_url):latest

# Deploy ECS
aws ecs update-service --cluster typerush-dev-ecs-cluster --service typerush-dev-game-service --force-new-deployment

# View logs
aws logs tail /ecs/typerush-dev-game-service --follow
```

**Important URLs:**

```bash
terraform output cloudfront_distribution_url  # Frontend
terraform output http_api_endpoint            # REST API
terraform output websocket_api_endpoint       # WebSocket API
terraform output cognito_hosted_ui_url        # Auth UI
```
