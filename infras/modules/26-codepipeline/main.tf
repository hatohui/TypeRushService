# ==================================
# CodePipeline Module - CI/CD Pipelines
# ==================================
# Purpose: Create AWS CodePipeline for automated CI/CD
# - Game Service: Source → Build → Deploy (ECS)
# - Record Service: Source → Build → Migrate → Deploy (Lambda)
# - Text Service: Source → Build → Deploy (Lambda)
# - Frontend: Source → Build → Deploy (S3 + CloudFront)
# ==================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ==================================
# S3 Bucket for Pipeline Artifacts
# ==================================

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project_name}-${var.environment}-pipeline-artifacts"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-pipeline-artifacts"
      Description = "CodePipeline artifacts storage"
    }
  )
}

# Enable versioning for artifacts bucket
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for artifacts
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to delete old artifacts (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"

    expiration {
      days = 7 # Keep artifacts for 7 days only
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

# ==================================
# 1. Game Service Pipeline
# ==================================
# Stages: Source → Build → Deploy (ECS)

resource "aws_codepipeline" "game_service" {
  count = var.create_game_service_pipeline ? 1 : 0

  name     = "${var.project_name}-${var.environment}-game-service"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.source_provider
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
        DetectChanges    = "true"
      }
    }
  }

  # Build Stage (Build Docker image and push to ECR)
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.game_service_codebuild_project
      }
    }
  }

  # Deploy Stage (Update ECS service)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.game_service_name
        FileName    = "imageDetail.json"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service-pipeline"
      Service = "game-service"
    }
  )
}

# ==================================
# 2. Record Service Pipeline
# ==================================
# Stages: Source → Build → Migrate → Deploy (Lambda)

resource "aws_codepipeline" "record_service" {
  count = var.create_record_service_pipeline ? 1 : 0

  name     = "${var.project_name}-${var.environment}-record-service"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.source_provider
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
        DetectChanges    = "true"
      }
    }
  }

  # Build Stage (Build Lambda package)
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.record_service_codebuild_project
      }
    }
  }

  # Migrate Stage (Run Prisma migrations)
  stage {
    name = "Migrate"

    action {
      name            = "Migrate"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = var.record_service_migrate_codebuild_project
      }
    }
  }

  # Deploy Stage (Update Lambda function)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "Lambda"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        FunctionName = var.record_service_lambda_name
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-record-service-pipeline"
      Service = "record-service"
    }
  )
}

# ==================================
# 3. Text Service Pipeline
# ==================================
# Stages: Source → Build → Deploy (Lambda)

resource "aws_codepipeline" "text_service" {
  count = var.create_text_service_pipeline ? 1 : 0

  name     = "${var.project_name}-${var.environment}-text-service"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.source_provider
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
        DetectChanges    = "true"
      }
    }
  }

  # Build Stage (Build Lambda package)
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.text_service_codebuild_project
      }
    }
  }

  # Deploy Stage (Update Lambda function)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "Lambda"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        FunctionName = var.text_service_lambda_name
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-text-service-pipeline"
      Service = "text-service"
    }
  )
}

# ==================================
# 4. Frontend Pipeline
# ==================================
# Stages: Source → Build → Deploy (S3 + CloudFront)

resource "aws_codepipeline" "frontend" {
  count = var.create_frontend_pipeline ? 1 : 0

  name     = "${var.project_name}-${var.environment}-frontend"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.source_provider
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.repository_id
        BranchName       = var.branch_name
        DetectChanges    = "true"
      }
    }
  }

  # Build Stage (npm build)
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.frontend_codebuild_project
      }
    }
  }

  # Deploy Stage (S3 upload + CloudFront invalidation)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        BucketName = var.frontend_s3_bucket_name
        Extract    = "true"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-frontend-pipeline"
      Service = "frontend"
    }
  )
}

# ==================================
# SNS Notifications (Optional)
# ==================================

resource "aws_codestarnotifications_notification_rule" "game_service" {
  count = var.create_game_service_pipeline && var.enable_pipeline_notifications ? 1 : 0

  name        = "${var.project_name}-${var.environment}-game-service-notifications"
  detail_type = "FULL"
  resource    = aws_codepipeline.game_service[0].arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  target {
    address = var.sns_topic_arn
    type    = "SNS"
  }

  tags = var.tags
}

resource "aws_codestarnotifications_notification_rule" "record_service" {
  count = var.create_record_service_pipeline && var.enable_pipeline_notifications ? 1 : 0

  name        = "${var.project_name}-${var.environment}-record-service-notifications"
  detail_type = "FULL"
  resource    = aws_codepipeline.record_service[0].arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  target {
    address = var.sns_topic_arn
    type    = "SNS"
  }

  tags = var.tags
}

resource "aws_codestarnotifications_notification_rule" "text_service" {
  count = var.create_text_service_pipeline && var.enable_pipeline_notifications ? 1 : 0

  name        = "${var.project_name}-${var.environment}-text-service-notifications"
  detail_type = "FULL"
  resource    = aws_codepipeline.text_service[0].arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  target {
    address = var.sns_topic_arn
    type    = "SNS"
  }

  tags = var.tags
}

resource "aws_codestarnotifications_notification_rule" "frontend" {
  count = var.create_frontend_pipeline && var.enable_pipeline_notifications ? 1 : 0

  name        = "${var.project_name}-${var.environment}-frontend-notifications"
  detail_type = "FULL"
  resource    = aws_codepipeline.frontend[0].arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  target {
    address = var.sns_topic_arn
    type    = "SNS"
  }

  tags = var.tags
}
