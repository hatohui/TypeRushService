# Step 04: IAM Roles and Policies ✅

## Status: COMPLETED

## Terraform Module: `modules/03-iam`

## Overview

Create 7 IAM roles with least-privilege policies for ECS, Lambda, CI/CD, and CloudFront services.

## Architecture Reference

From `architecture-diagram.md`:

- ECS needs: ECR image pull, Secrets Manager, Lambda invoke
- Lambda needs: VPC execution, RDS access, DynamoDB, Bedrock
- CodeBuild needs: ECR push, S3 artifacts, VPC networking
- CodePipeline needs: ECS/Lambda deployment orchestration
- CloudFront needs: S3 bucket access via OAI

## Components

### 1. ECS Task Execution Role ✅

- [x] **Trust Policy**: ECS tasks service
- [x] **Managed Policies**:
  - [x] AmazonECSTaskExecutionRolePolicy (ECR, CloudWatch Logs)
- [x] **Custom Policies**:
  - [x] Secrets Manager: GetSecretValue for `typerush/*` secrets
- [x] **Purpose**: Used by ALL ECS task definitions for infrastructure-level operations
- [x] **Used By**: Game Service task definition (executionRoleArn)

### 2. Game Service Task Role ✅

- [x] **Trust Policy**: ECS tasks service
- [x] **Custom Policies**:
  - [x] **ElastiCache**:
    - [x] DescribeCacheClusters, DescribeReplicationGroups
  - [x] **Secrets Manager**:
    - [x] GetSecretValue for `typerush/elasticache/*`
  - [x] **Lambda**:
    - [x] InvokeFunction for record-service and text-service
  - [x] **CloudWatch Logs**:
    - [x] CreateLogGroup, CreateLogStream, PutLogEvents
- [x] **Purpose**: Application-level permissions for Game Service container
- [x] **Used By**: Game Service task definition (taskRoleArn)

### 3. Record Service Lambda Role ✅

- [x] **Trust Policy**: Lambda service
- [x] **Managed Policies**:
  - [x] AWSLambdaVPCAccessExecutionRole (VPC ENI management)
- [x] **Custom Policies**:
  - [x] **RDS**:
    - [x] DescribeDBInstances (for monitoring)
  - [x] **Secrets Manager**:
    - [x] GetSecretValue for `typerush/record-db/*`
  - [x] **CloudWatch Logs**:
    - [x] CreateLogGroup, CreateLogStream, PutLogEvents
- [x] **Purpose**: Access RDS PostgreSQL for accounts and game history
- [x] **Used By**: Record Service Lambda function

### 4. Text Service Lambda Role ✅

- [x] **Trust Policy**: Lambda service
- [x] **Managed Policies**:
  - [x] AWSLambdaVPCAccessExecutionRole (VPC ENI management)
- [x] **Custom Policies**:
  - [x] **DynamoDB**:
    - [x] PutItem, GetItem, Query, Scan, UpdateItem, DeleteItem
    - [x] On table: `typerush-dev-texts` and indexes
  - [x] **Bedrock**:
    - [x] InvokeModel, InvokeModelWithResponseStream
    - [x] On all foundation models
  - [x] **CloudWatch Logs**:
    - [x] CreateLogGroup, CreateLogStream, PutLogEvents
- [x] **Purpose**: Generate and store AI-powered typing texts
- [x] **Used By**: Text Service Lambda function

### 5. CodeBuild Role ✅

- [x] **Trust Policy**: CodeBuild service
- [x] **Custom Policies**:
  - [x] **ECR**:
    - [x] GetAuthorizationToken, BatchCheckLayerAvailability
    - [x] PutImage, InitiateLayerUpload, UploadLayerPart, CompleteLayerUpload
  - [x] **S3**:
    - [x] GetObject, PutObject on `typerush-dev-pipeline-artifacts/*`
  - [x] **VPC** (for builds in VPC if needed):
    - [x] CreateNetworkInterface, DescribeNetworkInterfaces, DeleteNetworkInterface
    - [x] CreateNetworkInterfacePermission
  - [x] **CloudWatch Logs**:
    - [x] CreateLogGroup, CreateLogStream, PutLogEvents
- [x] **Purpose**: Build Docker images and Lambda packages
- [x] **Used By**: CodeBuild projects for each service

### 6. CodePipeline Role ✅

- [x] **Trust Policy**: CodePipeline service
- [x] **Custom Policies**:
  - [x] **S3**:
    - [x] GetObject, GetObjectVersion, PutObject on artifacts bucket
  - [x] **CodeBuild**:
    - [x] BatchGetBuilds, StartBuild
  - [x] **ECS**:
    - [x] DescribeServices, DescribeTaskDefinition, RegisterTaskDefinition, UpdateService
  - [x] **Lambda**:
    - [x] GetFunction, UpdateFunctionCode, UpdateFunctionConfiguration
  - [x] **IAM**:
    - [x] PassRole to ECS Task Execution Role and Game Service Task Role
- [x] **Purpose**: Orchestrate CI/CD pipeline
- [x] **Used By**: CodePipeline pipelines for all services

### 7. CloudFront Origin Access Identity (OAI) ✅

- [x] **Type**: CloudFront OAI (legacy but still widely used)
- [x] **Purpose**: Allow CloudFront to access S3 bucket privately
- [x] **Used By**: CloudFront distribution for frontend static files
- [x] **S3 Bucket Policy**: Created in S3 module to allow OAI access
- [x] **Note**: Consider upgrading to Origin Access Control (OAC) in production

## IAM Best Practices Applied

### ✅ Least Privilege

- Each role has only the permissions it needs
- Resource-level restrictions where possible (e.g., specific secret paths)
- No wildcard `*` resources except where AWS requires it (describe operations)

### ✅ Separation of Concerns

- **Execution Role** vs **Task Role** for ECS:
  - Execution Role: Infrastructure (pull images, get secrets)
  - Task Role: Application logic (invoke Lambda, read ElastiCache)
- **Lambda VPC Execution**: Separate managed policy for ENI management

### ✅ Resource Naming Conventions

- All roles follow pattern: `{project}-{environment}-{service}-{role-type}`
- Example: `typerush-dev-game-service-task`
- Makes CloudTrail auditing easier

### ✅ Tagging Strategy

- All roles tagged with: Project, Environment, Service
- Enables cost allocation and resource tracking

## Module Structure

```
modules/03-iam/
├── main.tf       # 7 IAM roles with policies
├── variables.tf  # Module inputs
└── outputs.tf    # Role ARNs for other modules
```

## Files Created

- `infras/modules/03-iam/main.tf`
- `infras/modules/03-iam/variables.tf`
- `infras/modules/03-iam/outputs.tf`

## Deployment

```powershell
# Deploy IAM roles (no dependencies, can be deployed anytime)
terraform apply -var-file="env\dev.tfvars.local" -target=module.iam
```

## Validation

```powershell
# List IAM roles
aws iam list-roles --query "Roles[?starts_with(RoleName, 'typerush')].RoleName"

# Get role details
aws iam get-role --role-name typerush-dev-ecs-task-execution

# List attached policies
aws iam list-attached-role-policies --role-name typerush-dev-ecs-task-execution

# List inline policies
aws iam list-role-policies --role-name typerush-dev-game-service-task
```

## Expected Outputs

- `ecs_task_execution_role_arn`: For ECS task definitions
- `game_service_task_role_arn`: For Game Service task definition
- `record_service_lambda_role_arn`: For Record Service Lambda
- `text_service_lambda_role_arn`: For Text Service Lambda
- `codebuild_role_arn`: For CodeBuild projects
- `codepipeline_role_arn`: For CodePipeline pipelines
- `cloudfront_oai_iam_arn`: For S3 bucket policy

## Cost Impact

**$0/month** - IAM roles are free

## Security Considerations

### 🔒 Secrets Access Pattern

```
ECS Task Execution Role → Get secrets during task startup
Game Service Task Role → Get ElastiCache auth token during runtime
Lambda Roles → Get DB credentials during cold start
```

### 🔒 Lambda Invocation Pattern

```
Game Service (via Task Role) → Invoke Record Service Lambda
Game Service (via Task Role) → Invoke Text Service Lambda
API Gateway → Direct invoke (no IAM role needed, uses resource-based policy)
```

### 🔒 VPC ENI Management

```
Lambda Functions in VPC → AWSLambdaVPCAccessExecutionRole
- CreateNetworkInterface (on cold start)
- DescribeNetworkInterfaces (for monitoring)
- DeleteNetworkInterface (on function deletion)
```

## Next Step

Proceed to [Step 05: Secrets Manager](./05_secrets_manager.md)
