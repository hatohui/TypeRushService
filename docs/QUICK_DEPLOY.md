# Quick Deployment Reference Card

## 🚀 How to Deploy Services

### Option 1: Manual Deployment (Quick & Simple)

#### Deploy Game Service (ECS)

```bash
cd services/game-service

# Get ECR URL
ECR_REPO=$(cd ../../infras && terraform output -raw game_service_repository_url)

# Login to ECR
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin 630633962130.dkr.ecr.ap-southeast-1.amazonaws.com

# Build & Push
docker build -t typerush/game-service:latest .
docker tag typerush/game-service:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# Deploy to ECS
aws ecs update-service \
  --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service \
  --force-new-deployment
```

#### Deploy Lambda Functions

```bash
# Record Service
cd services/record-service
npm install --production
zip -r function.zip src/ node_modules/ package.json
aws lambda update-function-code \
  --function-name typerush-dev-record-service \
  --zip-file fileb://function.zip

# Text Service
cd services/text-service
pip install -r requirements.txt -t .
zip -r function.zip lambda_handler.py controllers/ [dependencies]
aws lambda update-function-code \
  --function-name typerush-dev-text-service \
  --zip-file fileb://function.zip
```

#### Deploy Frontend

```bash
cd frontend
npm install
npm run build

S3_BUCKET=$(cd ../infras && terraform output -raw frontend_bucket_name)
aws s3 sync dist/ s3://$S3_BUCKET/ --delete

CLOUDFRONT_ID=$(cd ../infras && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"
```

---

### Option 2: Enable CodePipeline (Automated CI/CD)

#### Step 1: Enable Pipelines

Edit `infras/dev.auto.tfvars`:

```hcl
# CI/CD Configuration
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

#### Step 2: Configure GitHub Connection

**In AWS Console:**

1. Go to **CodePipeline** → **Settings** → **Connections**
2. Create a **GitHub** connection
3. Authenticate with GitHub
4. Note the connection ARN

**Update `dev.auto.tfvars`:**

```hcl
# Source Configuration
source_location = "https://github.com/hatohui/TypeRushService.git"
source_type     = "CODEPIPELINE"  # For GitHub integration

# Add GitHub connection ARN to CodePipeline configuration
# (You may need to add this variable in variables.tf if not present)
```

#### Step 3: Trigger Pipelines

**Manual Trigger:**

```bash
# Trigger specific pipeline
aws codepipeline start-pipeline-execution \
  --name typerush-dev-game-service

aws codepipeline start-pipeline-execution \
  --name typerush-dev-record-service

aws codepipeline start-pipeline-execution \
  --name typerush-dev-text-service

aws codepipeline start-pipeline-execution \
  --name typerush-dev-frontend
```

**Automatic Trigger (GitHub Push):**

```bash
# Just push to your repository
git add .
git commit -m "Deploy to AWS"
git push origin main

# Pipeline automatically triggers on push
```

**Monitor Pipeline:**

```bash
# Check pipeline status
aws codepipeline get-pipeline-state \
  --name typerush-dev-game-service

# Watch in Console:
# AWS Console → CodePipeline → Select pipeline → View execution
```

---

## 🔍 Test Connectivity

### Quick Connectivity Test

```bash
# Run the verification script
./test-infrastructure.sh
```

### Manual Connectivity Tests

#### Test HTTP API

```bash
HTTP_API=$(cd infras && terraform output -raw http_api_endpoint)

# Test Lambda endpoints
curl $HTTP_API/records/health
curl $HTTP_API/texts/health
```

#### Test WebSocket API

```bash
WS_API=$(cd infras && terraform output -raw websocket_api_endpoint)

# Install wscat if not present
npm install -g wscat

# Connect
wscat -c $WS_API
```

#### Test CloudFront

```bash
CLOUDFRONT_URL=$(cd infras && terraform output -raw cloudfront_distribution_url)
curl -I $CLOUDFRONT_URL
```

#### Test ECS Service (from inside VPC)

```bash
ALB_DNS=$(cd infras && terraform output -raw internal_alb_dns_name)
curl http://$ALB_DNS/health
```

---

## 📊 Check Service Status

### ECS Service

```bash
aws ecs describe-services \
  --cluster typerush-dev-ecs-cluster \
  --services typerush-dev-game-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

### Lambda Functions

```bash
aws lambda get-function \
  --function-name typerush-dev-text-service \
  --query 'Configuration.{Runtime:Runtime,LastModified:LastModified,Version:Version}'
```

### ECR Images

```bash
aws ecr list-images \
  --repository-name typerush/game-service \
  --query 'imageIds[*].imageTag'
```

### CloudWatch Logs

```bash
# Game Service logs
aws logs tail /ecs/typerush-dev-game-service --follow

# Record Service Lambda
aws logs tail /aws/lambda/typerush-dev-record-service --follow

# Text Service Lambda
aws logs tail /aws/lambda/typerush-dev-text-service --follow
```

---

## 🎯 Common Tasks

### Update Environment Variables

**ECS (Game Service):**

```bash
# Edit task definition in AWS Console
# Or update via Terraform in modules/11-ecs/main.tf
cd infras
terraform apply
aws ecs update-service --cluster typerush-dev-ecs-cluster --service typerush-dev-game-service --force-new-deployment
```

**Lambda:**

```bash
aws lambda update-function-configuration \
  --function-name typerush-dev-text-service \
  --environment "Variables={LOG_LEVEL=DEBUG,APP_ENV=production}"
```

### Scale Services

**ECS:**

```bash
# Scale up
aws ecs update-service \
  --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service \
  --desired-count 2

# Scale down to save costs
aws ecs update-service \
  --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service \
  --desired-count 0
```

### Rollback Deployment

**ECS:**

```bash
# List task definition revisions
aws ecs list-task-definitions \
  --family-prefix typerush-dev-game-service

# Update to previous revision
aws ecs update-service \
  --cluster typerush-dev-ecs-cluster \
  --service typerush-dev-game-service \
  --task-definition typerush-dev-game-service:3
```

**Lambda:**

```bash
# List versions
aws lambda list-versions-by-function \
  --function-name typerush-dev-text-service

# Update alias to point to previous version
aws lambda update-alias \
  --function-name typerush-dev-text-service \
  --name PROD \
  --function-version 2
```

---

## 🔐 Access Secrets

### RDS Password

```bash
aws secretsmanager get-secret-value \
  --secret-id $(cd infras && terraform output -raw rds_secret_arn) \
  --query SecretString --output text | jq -r .password
```

### Redis AUTH Token

```bash
aws secretsmanager get-secret-value \
  --secret-id $(cd infras && terraform output -raw elasticache_secret_arn) \
  --query SecretString --output text | jq -r .authToken
```

---

## 💰 Cost Management

### Stop All Services

```bash
# Stop ECS
aws ecs update-service --cluster typerush-dev-ecs-cluster --service typerush-dev-game-service --desired-count 0

# Lambda and DynamoDB only charge on usage - no action needed
```

### Destroy Everything

```bash
cd infras
terraform destroy
```

---

## 🆘 Troubleshooting

### ECS Task Won't Start

```bash
# Check logs
aws logs tail /ecs/typerush-dev-game-service --follow

# Check task stopped reason
aws ecs describe-tasks \
  --cluster typerush-dev-ecs-cluster \
  --tasks $(aws ecs list-tasks --cluster typerush-dev-ecs-cluster --service typerush-dev-game-service --query 'taskArns[0]' --output text) \
  --query 'tasks[0].stoppedReason'
```

### Lambda Timeout/Error

```bash
# Check recent logs
aws logs tail /aws/lambda/typerush-dev-text-service --since 5m

# Get function config
aws lambda get-function-configuration \
  --function-name typerush-dev-text-service
```

### API Gateway 502 Error

- Check if backend service (ECS or Lambda) is running
- Verify security groups allow traffic
- Check integration configuration in API Gateway console

---

## 📞 Quick Reference

**Get all endpoints:**

```bash
cd infras
terraform output | grep -E "(endpoint|url|dns)"
```

**Check infrastructure status:**

```bash
./test-infrastructure.sh
```

**Full deployment guide:**

```bash
cat VERIFICATION_AND_DEPLOYMENT_GUIDE.md
```
