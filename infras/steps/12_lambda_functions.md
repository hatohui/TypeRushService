# Step 12: Lambda Functions (Record & Text Services)

## Status: IMPLEMENTED (Not Applied)

**Implemented on**: November 23, 2025  
**Applied to AWS**: Not yet - waiting for full stack implementation

**Note**: This module has been coded and validated in Terraform but NOT yet applied to AWS infrastructure. Build scripts have been created to generate Lambda deployment packages.

## Build Scripts Created

- **Record Service**: `services/record-service/build-lambda.ps1`
- **Text Service**: `services/text-service/build-lambda.ps1`
- **Build All**: `build-all-lambdas.ps1` (builds both services)
- **Placeholder**: `create-placeholder-lambdas.ps1` (for initial Terraform testing)

Output location: `build/` directory

## Terraform Module: `modules/13-lambda`

## Overview

Create two Lambda functions in VPC for Record Service (NestJS + Prisma) and Text Service (Python + FastAPI), handling database operations and AI text generation.

## Architecture Reference

From `architecture-diagram.md`:

- **Record Service**: NestJS + Prisma, accesses RDS PostgreSQL
- **Text Service**: Python + FastAPI, accesses DynamoDB + Bedrock
- **Network**: Private subnet, no public IP
- **Invocation**: Direct from API Gateway + invoked by Game Service
- **Cost**: ~$2/month (minimal dev usage)

## Components to Implement

### 1. Record Service Lambda Function

#### Function Configuration

- [ ] **Function Name**: `typerush-dev-record-service`
- [ ] **Runtime**: nodejs20.x
- [ ] **Handler**: dist/lambda.handler
- [ ] **Memory**: 512 MB
- [ ] **Timeout**: 30 seconds
- [ ] **Architecture**: arm64 (Graviton2, 20% cheaper)
- [ ] **Role**: Record Service Lambda Role (from Module 03)

#### VPC Configuration

- [ ] **Subnets**: Private subnet
- [ ] **Security Groups**: Lambda security group
- [ ] **Purpose**: Access RDS, Secrets Manager, VPC endpoints

#### Environment Variables

- [ ] `NODE_ENV`: production
- [ ] `LOG_LEVEL`: info
- [ ] `DATABASE_URL`: (constructed from secrets)
- [ ] `AWS_REGION`: ap-southeast-1

#### Secrets (from Secrets Manager)

- [ ] `DB_SECRET_ARN`: RDS credentials secret ARN
- [ ] Retrieved at runtime using AWS SDK

#### Layers

- [ ] AWS SDK v3 (optional, included in runtime)
- [ ] Prisma binary layer (generated from Prisma Engine)

### 2. Text Service Lambda Function

#### Function Configuration

- [ ] **Function Name**: `typerush-dev-text-service`
- [ ] **Runtime**: python3.12
- [ ] **Handler**: main.lambda_handler
- [ ] **Memory**: 512 MB
- [ ] **Timeout**: 60 seconds (Bedrock may take time)
- [ ] **Architecture**: arm64
- [ ] **Role**: Text Service Lambda Role (from Module 03)

#### VPC Configuration

- [ ] **Subnets**: Private subnet
- [ ] **Security Groups**: Lambda security group
- [ ] **Purpose**: Access DynamoDB, Bedrock, VPC endpoints

#### Environment Variables

- [ ] `ENVIRONMENT`: production
- [ ] `LOG_LEVEL`: INFO
- [ ] `DYNAMODB_TABLE_NAME`: typerush-dev-texts
- [ ] `BEDROCK_MODEL_ID`: anthropic.claude-3-haiku-20240307-v1:0
- [ ] `AWS_REGION`: ap-southeast-1

#### Layers

- [ ] FastAPI + dependencies (packaged separately)
- [ ] Mangum (ASGI adapter for Lambda)

### 3. CloudWatch Log Groups

- [ ] `/aws/lambda/typerush-dev-record-service` (7-day retention)
- [ ] `/aws/lambda/typerush-dev-text-service` (7-day retention)

### 4. Lambda Function URLs (Optional)

- [ ] Record Service: Function URL with IAM auth
- [ ] Text Service: Function URL with IAM auth
- [ ] **Note**: Using API Gateway instead for production

## Implementation Details

### Record Service - Terraform Configuration

```hcl
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "record_service" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-record-service"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-record-service-logs"
      Service = "record-service"
    }
  )
}

# Lambda Function
resource "aws_lambda_function" "record_service" {
  function_name = "${var.project_name}-${var.environment}-record-service"
  role          = var.record_service_lambda_role_arn

  # Deployment package (uploaded separately or via S3)
  filename         = var.record_service_zip_path
  source_code_hash = filebase64sha256(var.record_service_zip_path)

  runtime       = "nodejs20.x"
  handler       = "dist/lambda.handler"
  architectures = ["arm64"]

  memory_size = 512
  timeout     = 30

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      NODE_ENV          = "production"
      LOG_LEVEL         = "info"
      DB_SECRET_ARN     = var.rds_secret_arn
      AWS_REGION        = data.aws_region.current.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.record_service]

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-record-service"
      Service = "record-service"
    }
  )
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "record_service_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.record_service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# Lambda Permission for ECS (Game Service)
resource "aws_lambda_permission" "record_service_ecs" {
  statement_id  = "AllowECSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.record_service.function_name
  principal     = "ecs-tasks.amazonaws.com"
  source_arn    = var.game_service_task_role_arn
}
```

### Text Service - Terraform Configuration

```hcl
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "text_service" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-text-service"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-text-service-logs"
      Service = "text-service"
    }
  )
}

# Lambda Function
resource "aws_lambda_function" "text_service" {
  function_name = "${var.project_name}-${var.environment}-text-service"
  role          = var.text_service_lambda_role_arn

  # Deployment package
  filename         = var.text_service_zip_path
  source_code_hash = filebase64sha256(var.text_service_zip_path)

  runtime       = "python3.12"
  handler       = "main.lambda_handler"
  architectures = ["arm64"]

  memory_size = 512
  timeout     = 60

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      ENVIRONMENT         = "production"
      LOG_LEVEL           = "INFO"
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      BEDROCK_MODEL_ID    = "anthropic.claude-3-haiku-20240307-v1:0"
      AWS_REGION          = data.aws_region.current.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.text_service]

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-text-service"
      Service = "text-service"
    }
  )
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "text_service_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# Lambda Permission for ECS (Game Service)
resource "aws_lambda_permission" "text_service_ecs" {
  statement_id  = "AllowECSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_service.function_name
  principal     = "ecs-tasks.amazonaws.com"
  source_arn    = var.game_service_task_role_arn
}
```

## Building Deployment Packages

### Record Service (NestJS)

```powershell
# Navigate to Record Service directory
cd services\record-service

# Install production dependencies
npm ci --production

# Build TypeScript
npm run build

# Generate Prisma Client
npx prisma generate

# Create deployment package
$tempDir = "lambda-package"
New-Item -ItemType Directory -Path $tempDir -Force

# Copy built files
Copy-Item -Recurse -Path "dist" -Destination "$tempDir\dist"
Copy-Item -Recurse -Path "node_modules" -Destination "$tempDir\node_modules"
Copy-Item "package.json" -Destination "$tempDir\package.json"

# Create lambda handler
@"
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/app.module');

let server;

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.init();
  return app;
}

exports.handler = async (event, context) => {
  if (!server) {
    server = await bootstrap();
  }
  // Handle Lambda event
  return server.getHttpAdapter().getInstance()(event, context);
};
"@ | Out-File -FilePath "$tempDir\lambda.js" -Encoding UTF8

# Compress to ZIP
Compress-Archive -Path "$tempDir\*" -DestinationPath "record-service-lambda.zip" -Force

# Upload to S3 or reference in Terraform
aws s3 cp record-service-lambda.zip s3://typerush-dev-lambda-packages/record-service.zip
```

### Text Service (Python)

```powershell
# Navigate to Text Service directory
cd services\text-service

# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Create deployment package
$tempDir = "lambda-package"
New-Item -ItemType Directory -Path $tempDir -Force

# Copy Python dependencies
Copy-Item -Recurse -Path "venv\Lib\site-packages\*" -Destination $tempDir

# Copy application code
Copy-Item -Recurse -Path "*.py" -Destination $tempDir
Copy-Item -Recurse -Path "controllers" -Destination $tempDir
Copy-Item -Recurse -Path "models" -Destination $tempDir

# Create Lambda handler wrapper
@"
from mangum import Mangum
from main import app

# Mangum adapter for Lambda
lambda_handler = Mangum(app, lifespan="off")
"@ | Out-File -FilePath "$tempDir\lambda_handler.py" -Encoding UTF8

# Compress to ZIP
Compress-Archive -Path "$tempDir\*" -DestinationPath "text-service-lambda.zip" -Force

# Upload to S3
aws s3 cp text-service-lambda.zip s3://typerush-dev-lambda-packages/text-service.zip
```

## Module Structure

```
modules/11-lambda/
├── main.tf       # Lambda functions, log groups, permissions
├── variables.tf  # Deployment package paths, role ARNs, subnet IDs
└── outputs.tf    # Function ARNs, function names
```

## Dependencies

- **Required**: Module 01 (Networking) - Private subnet
- **Required**: Module 02 (Security Groups) - Lambda security group
- **Required**: Module 03 (IAM) - Lambda roles
- **Required**: Module 06 (RDS) - For Record Service
- **Required**: Module 08 (DynamoDB) - For Text Service
- **Required**: Module 05 (Secrets Manager) - For RDS credentials

## Deployment

```powershell
# Deploy Lambda functions (takes ~2-3 minutes)
terraform apply -var-file="env\dev.tfvars.local" -target=module.lambda
```

## Validation Commands

```powershell
# List functions
aws lambda list-functions

# Get function details
aws lambda get-function --function-name typerush-dev-record-service

# Invoke Record Service (test)
aws lambda invoke --function-name typerush-dev-record-service `
  --payload '{"action":"health"}' response.json

cat response.json

# Invoke Text Service (test)
aws lambda invoke --function-name typerush-dev-text-service `
  --payload '{"action":"get_random_text","difficulty":"easy"}' response.json

cat response.json

# View logs
aws logs tail /aws/lambda/typerush-dev-record-service --follow
aws logs tail /aws/lambda/typerush-dev-text-service --follow
```

## Cost Impact

**$2.00/month** (estimated for dev)

### Lambda Pricing Breakdown

- **Compute**: $0.0000000021 per ms × GB
  - Record Service: 512 MB, 200ms avg, 5,000 invocations/mo = $0.11
  - Text Service: 512 MB, 1000ms avg, 1,000 invocations/mo = $0.11
- **Requests**: $0.20 per 1M requests
  - 6,000 requests/mo = $0.01
- **Data Transfer**: FREE (VPC endpoints)
- **Total**: ~$0.23/month

**Note**: First 1M requests and 400,000 GB-seconds free per month (we're well within free tier!)

**4-day demo**: < $0.10

## Cold Start Optimization

### Record Service (Node.js)

- Use arm64 (faster cold starts)
- Minimize dependencies (tree-shaking)
- Use Prisma Data Proxy (alternative to bundled Prisma Engine)
- Expected cold start: 2-3 seconds

### Text Service (Python)

- Use arm64
- Minimize package size (exclude unnecessary deps)
- Use Mangum for efficient ASGI handling
- Expected cold start: 3-5 seconds

### Provisioned Concurrency (Production)

```hcl
resource "aws_lambda_provisioned_concurrency_config" "record_service" {
  function_name                     = aws_lambda_function.record_service.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_function.record_service.version
}
# Cost: +$10/month for 1 concurrent execution
```

## Monitoring and Alerting

### CloudWatch Metrics

- [ ] Invocations (track usage)
- [ ] Errors > 5 per 5 minutes
- [ ] Throttles > 0 (hitting concurrency limit)
- [ ] Duration > timeout threshold
- [ ] ConcurrentExecutions (monitor scaling)

### CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-record-service-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Record Service Lambda errors"

  dimensions = {
    FunctionName = aws_lambda_function.record_service.function_name
  }
}
```

## Testing Plan

1. [ ] Deploy Lambda functions
2. [ ] Verify functions are created
3. [ ] Test Record Service health check
4. [ ] Test Record Service database connection
5. [ ] Test Text Service health check
6. [ ] Test Text Service DynamoDB access
7. [ ] Test Text Service Bedrock integration
8. [ ] Test invocation from API Gateway
9. [ ] Test invocation from Game Service (ECS)
10. [ ] Monitor cold start times
11. [ ] Check CloudWatch logs for errors

## Common Issues

### Issue: Cold start timeout

```
Error: Task timed out after 30.00 seconds
Solution: Increase timeout or optimize package size
```

### Issue: Cannot connect to RDS

```
Error: ETIMEDOUT or ECONNREFUSED
Solution:
- Verify Lambda is in private subnet
- Check security group allows Lambda → RDS on port 5432
- Verify RDS endpoint is correct
```

### Issue: Prisma binary not found

```
Error: Cannot find module '@prisma/engines'
Solution: Ensure Prisma Engine is bundled in deployment package
Use: npx prisma generate before packaging
```

### Issue: DynamoDB access denied

```
Error: User is not authorized to perform: dynamodb:GetItem
Solution: Verify Text Service Lambda Role has DynamoDB permissions
```

## Next Step

Proceed to [Step 13: Internal ALB](./13_internal_alb.md)
