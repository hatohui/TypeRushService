# IAM Roles and Policies Module
# Purpose: Create IAM roles for ECS, Lambda, CodePipeline, and CloudFront
# 
# This module creates the following roles:
# 1. ECS Task Execution Role - For pulling images from ECR, getting secrets
# 2. Game Service Task Role - For accessing ElastiCache, Secrets, invoking Lambda
# 3. Record Service Lambda Role - For accessing RDS, Secrets Manager
# 4. Text Service Lambda Role - For accessing DynamoDB, Bedrock
# 5. CodeBuild Role - For CI/CD build process
# 6. CodePipeline Role - For CI/CD pipeline orchestration
# 7. CloudFront OAI - For secure S3 access

# -----------------------------------------------------
# Data Sources - Current AWS Account and Region
# -----------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
}

# -----------------------------------------------------
# 1. ECS Task Execution Role
# Purpose: Used by ECS to pull images from ECR, get secrets from Secrets Manager
# Attached to ALL ECS task definitions
# -----------------------------------------------------

# Trust policy allowing ECS tasks to assume this role
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-${var.environment}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-task-execution"
    }
  )
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
data "aws_iam_policy_document" "ecs_task_execution_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.project_name}/${var.environment}/*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name   = "secrets-manager-access"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_task_execution_secrets.json
}

# -----------------------------------------------------
# 2. Game Service ECS Task Role
# Purpose: Used by Game Service container to access ElastiCache, Secrets, invoke Lambda
# Attached to Game Service task definition
# -----------------------------------------------------

resource "aws_iam_role" "game_service_task" {
  name               = "${var.project_name}-${var.environment}-game-service-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service-task"
      Service = "game-service"
    }
  )
}

# Policy for Game Service
data "aws_iam_policy_document" "game_service_task" {
  # ElastiCache Redis access (authentication via AUTH token from Secrets Manager)
  statement {
    effect = "Allow"
    actions = [
      "elasticache:DescribeCacheClusters",
      "elasticache:DescribeReplicationGroups"
    ]
    resources = ["*"]
  }

  # Secrets Manager access for Redis AUTH token
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.project_name}/${var.environment}/elasticache/*"
    ]
  }

  # Lambda invoke permissions (for Record Service and Text Service)
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${var.project_name}-${var.environment}-record-service",
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${var.project_name}-${var.environment}-text-service"
    ]
  }

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/ecs/${var.project_name}-${var.environment}-game-service:*"
    ]
  }
}

resource "aws_iam_role_policy" "game_service_task" {
  name   = "game-service-permissions"
  role   = aws_iam_role.game_service_task.id
  policy = data.aws_iam_policy_document.game_service_task.json
}

# -----------------------------------------------------
# 3. Record Service Lambda Role
# Purpose: Used by Record Service Lambda to access RDS and Secrets Manager
# Attached to Record Service Lambda function
# -----------------------------------------------------

# Trust policy allowing Lambda to assume this role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "record_service_lambda" {
  name               = "${var.project_name}-${var.environment}-record-service-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-record-service-lambda"
      Service = "record-service"
    }
  )
}

# Attach AWS managed policy for Lambda VPC execution
resource "aws_iam_role_policy_attachment" "record_service_lambda_vpc_execution" {
  role       = aws_iam_role.record_service_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy for Record Service Lambda
data "aws_iam_policy_document" "record_service_lambda" {
  # RDS access (via security groups, no direct IAM permissions needed for PostgreSQL)
  # But include describe permissions for monitoring
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = ["*"]
  }

  # Secrets Manager access for RDS credentials
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${var.project_name}/${var.environment}/record-db/*"
    ]
  }

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-record-service:*"
    ]
  }
}

resource "aws_iam_role_policy" "record_service_lambda" {
  name   = "record-service-permissions"
  role   = aws_iam_role.record_service_lambda.id
  policy = data.aws_iam_policy_document.record_service_lambda.json
}

# -----------------------------------------------------
# 4. Text Service Lambda Role
# Purpose: Used by Text Service Lambda to access DynamoDB and Bedrock
# Attached to Text Service Lambda function
# -----------------------------------------------------

resource "aws_iam_role" "text_service_lambda" {
  name               = "${var.project_name}-${var.environment}-text-service-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-text-service-lambda"
      Service = "text-service"
    }
  )
}

# Attach AWS managed policy for Lambda VPC execution
resource "aws_iam_role_policy_attachment" "text_service_lambda_vpc_execution" {
  role       = aws_iam_role.text_service_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy for Text Service Lambda
data "aws_iam_policy_document" "text_service_lambda" {
  # DynamoDB access for text storage
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${var.project_name}-${var.environment}-texts",
      "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${var.project_name}-${var.environment}-texts/index/*"
    ]
  }

  # Bedrock access for AI text generation
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:${local.region}::foundation-model/*"
    ]
  }

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-text-service:*"
    ]
  }
}

resource "aws_iam_role_policy" "text_service_lambda" {
  name   = "text-service-permissions"
  role   = aws_iam_role.text_service_lambda.id
  policy = data.aws_iam_policy_document.text_service_lambda.json
}

# -----------------------------------------------------
# 5. CodeBuild Role
# Purpose: Used by CodeBuild to build Docker images and push to ECR
# Attached to CodeBuild projects
# -----------------------------------------------------

# Trust policy allowing CodeBuild to assume this role
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project_name}-${var.environment}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-codebuild"
    }
  )
}

# Policy for CodeBuild
data "aws_iam_policy_document" "codebuild" {
  # ECR permissions for pushing images
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/${var.project_name}-*"
    ]
  }

  # S3 access for build artifacts (CodePipeline artifact bucket)
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-${var.environment}-pipeline-artifacts/*"
    ]
  }

  # VPC permissions (if CodeBuild needs to run in VPC)
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = [
      "arn:aws:ec2:${local.region}:${local.account_id}:network-interface/*"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "codebuild-permissions"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild.json
}

# -----------------------------------------------------
# 6. CodePipeline Role
# Purpose: Used by CodePipeline to orchestrate CI/CD pipeline
# Attached to CodePipeline pipelines
# -----------------------------------------------------

# Trust policy allowing CodePipeline to assume this role
data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.project_name}-${var.environment}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-codepipeline"
    }
  )
}

# Policy for CodePipeline
data "aws_iam_policy_document" "codepipeline" {
  # S3 access for artifacts
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-${var.environment}-pipeline-artifacts/*"
    ]
  }

  # CodeBuild permissions
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "arn:aws:codebuild:${local.region}:${local.account_id}:project/${var.project_name}-*"
    ]
  }

  # ECS permissions for deployment
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }

  # IAM permissions to pass roles to ECS
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_task_execution.arn,
      aws_iam_role.game_service_task.arn
    ]
  }

  # Lambda permissions for deployment
  statement {
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration"
    ]
    resources = [
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${var.project_name}-${var.environment}-*"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "codepipeline-permissions"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline.json
}

# -----------------------------------------------------
# 7. CloudFront Origin Access Identity (OAI)
# Purpose: Used by CloudFront to access S3 bucket privately
# Note: This is legacy, but still widely used. Consider using Origin Access Control (OAC) in production
# -----------------------------------------------------

resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "${var.project_name}-${var.environment} Frontend OAI"
}

# S3 bucket policy will be created in the S3 module to allow CloudFront OAI access
