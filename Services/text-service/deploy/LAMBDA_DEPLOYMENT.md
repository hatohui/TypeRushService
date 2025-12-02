# AWS Lambda Deployment Guide

This guide covers deploying the text-service FastAPI application to AWS Lambda using Mangum.

## Architecture

```
API Gateway (HTTP API)
        │
        ▼
   AWS Lambda
   (Mangum + FastAPI)
        │
        ├──► DynamoDB (words/sentences)
        │
        └──► Bedrock Agent (paragraphs - optional)
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Python 3.12+
- Lambda function created in AWS

## Lambda Handler

The entry point for AWS Lambda is:

```
main.handler
```

## Environment Variables

Set these in Lambda configuration:

| Variable | Required | Description |
|----------|----------|-------------|
| `AWS_REGION` | Yes | AWS region (e.g., `ap-southeast-2`) |
| `DYNAMODB_TABLE_NAME` | Yes | DynamoDB table name (default: `wordsntexts`) |
| `BEDROCK_AGENT_ID` | No | Bedrock agent ID (1-10 alphanumeric chars) |
| `BEDROCK_AGENT_ALIAS` | No | Bedrock agent alias (1-10 alphanumeric chars) |

## IAM Permissions

The Lambda execution role needs:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:GetItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/wordsntexts"
        },
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeAgent"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Health check |
| POST | `/api/generate-text` | Generate text |
| GET | `/docs` | OpenAPI documentation |

### Request Body

```json
{
    "type": 1,    // 1=words, 2=sentences, 3=Bedrock paragraphs
    "count": 10   // Number of words or sentence length (1-3)
}
```

---

## CI/CD Pipeline (GitLab → CodePipeline → Lambda)

### Architecture

```
┌─────────┐      ┌──────────────┐      ┌───────────┐      ┌────────┐
│ GitLab  │ ───► │ CodePipeline │ ───► │ CodeBuild │ ───► │ Lambda │
│ (push)  │      │  (trigger)   │      │  (build)  │      │(deploy)│
└─────────┘      └──────────────┘      └───────────┘      └────────┘
```

### Prerequisites

1. **Create GitLab Connection** in AWS Console:
   - Go to **CodePipeline** → **Settings** → **Connections**
   - Click **Create connection** → Select **GitLab**
   - Authorize AWS to access your GitLab account
   - Copy the **Connection ARN**

2. **Create Lambda Function** (if not exists):
   ```bash
   aws lambda create-function \
       --function-name text-service \
       --runtime python3.12 \
       --handler main.handler \
       --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
       --zip-file fileb://text-service-lambda.zip
   ```

### Deploy Pipeline

```bash
# Deploy the CI/CD pipeline stack
aws cloudformation deploy \
    --template-file deploy/pipeline.yaml \
    --stack-name text-service-pipeline \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        GitLabConnectionArn=arn:aws:codestar-connections:REGION:ACCOUNT:connection/CONN_ID \
        GitLabRepoId=hatohui/TypeRushService \
        BranchName=main \
        LambdaFunctionName=text-service \
        Environment=dev
```

### Pipeline Files

| File | Purpose |
|------|---------|
| `deploy/buildspec.yml` | CodeBuild instructions (install, build, deploy) |
| `deploy/pipeline.yaml` | CloudFormation template for pipeline infrastructure |

### How It Works

1. **Push to GitLab** → CodeStar Connection detects changes
2. **CodePipeline triggers** → Pulls source code
3. **CodeBuild runs** → Executes `buildspec.yml`:
   - Installs Python dependencies
   - Packages Lambda ZIP
   - Deploys to Lambda function
4. **Lambda updated** → New version published

### Trigger Pipeline Manually

```bash
aws codepipeline start-pipeline-execution \
    --name text-service-pipeline-dev
```

### Monitor Pipeline

```bash
# View pipeline status
aws codepipeline get-pipeline-state \
    --name text-service-pipeline-dev

# View build logs
aws logs tail /aws/codebuild/text-service-build-dev --follow
```

### buildspec.yml Overview

```yaml
phases:
  install:    # Install Python 3.12
  pre_build:  # Prepare build directory
  build:      # pip install, copy code, create ZIP
  post_build: # Deploy to Lambda
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Module not found` | Ensure all dependencies are in the ZIP package |
| `Timeout` | Increase Lambda timeout (cold starts can take 5-10s) |
| `Permission denied` | Check IAM role has DynamoDB/Bedrock permissions |
| `Bedrock validation error` | Agent ID/Alias must be 1-10 alphanumeric chars |
| `Text service not initialized` | Ensure `.env` has region/table configured |

---

## Manual Deployment (Alternative)

If you need to deploy manually without CI/CD:

```bash
# 1. Create build directory
mkdir -p build/package

# 2. Install dependencies
pip install -r requirements.txt -t build/package/

# 3. Copy application code
cp main.py build/package/
cp -r models build/package/
cp -r controllers build/package/

# 4. Create ZIP
cd build/package
zip -r ../text-service-lambda.zip . -x "*.pyc" -x "__pycache__/*"

# 5. Deploy to Lambda
aws lambda update-function-code \
    --function-name text-service \
    --zip-file fileb://build/text-service-lambda.zip
```
