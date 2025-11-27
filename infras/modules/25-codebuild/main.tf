# ========================================
# CodeBuild Projects for TypeRush Services
# ========================================

data "aws_region" "current" {}

# ========================================
# 1. Game Service Build Project
# ========================================

resource "aws_codebuild_project" "game_service" {
  count         = var.create_game_service_build ? 1 : 0
  name          = "${var.project_name}-${var.environment}-game-service-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 30

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.game_service_ecr_uri
    }

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    buildspec       = "services/game-service/buildspec.yml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-game-service"
      stream_name = "build"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service-build"
      Service = "game-service"
    }
  )
}

# ========================================
# 2. Record Service Build Project
# ========================================

resource "aws_codebuild_project" "record_service" {
  count         = var.create_record_service_build ? 1 : 0
  name          = "${var.project_name}-${var.environment}-record-service-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 30

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = false # Lambda doesn't need Docker
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = var.record_lambda_name
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    buildspec       = "services/record-service/buildspec.yml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-record-service"
      stream_name = "build"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-record-service-build"
      Service = "record-service"
    }
  )
}

# ========================================
# 3. Record Service Migration Project
# ========================================

resource "aws_codebuild_project" "record_service_migrate" {
  count         = var.create_record_service_migrate ? 1 : 0
  name          = "${var.project_name}-${var.environment}-record-service-migrate"
  service_role  = var.codebuild_role_arn
  build_timeout = 10

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "DB_SECRET_ARN"
      value = var.rds_secret_arn
    }

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    buildspec       = "services/record-service/buildspec-migrate.yml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-record-service-migrate"
      stream_name = "migrate"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-record-service-migrate"
      Service = "record-service"
      Purpose = "database-migration"
    }
  )
}

# ========================================
# 4. Text Service Build Project
# ========================================

resource "aws_codebuild_project" "text_service" {
  count         = var.create_text_service_build ? 1 : 0
  name          = "${var.project_name}-${var.environment}-text-service-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 20

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = var.text_lambda_name
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    buildspec       = "services/text-service/buildspec.yml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-text-service"
      stream_name = "build"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-text-service-build"
      Service = "text-service"
    }
  )
}

# ========================================
# 5. Frontend Build Project
# ========================================

resource "aws_codebuild_project" "frontend" {
  count         = var.create_frontend_build ? 1 : 0
  name          = "${var.project_name}-${var.environment}-frontend-build"
  service_role  = var.codebuild_role_arn
  build_timeout = 20

  artifacts {
    type      = "S3"
    location  = var.frontend_s3_bucket_name
    name      = "/"
    packaging = "NONE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:7.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "S3_BUCKET"
      value = var.frontend_s3_bucket_name
    }

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
    }

    # API endpoints for frontend
    environment_variable {
      name  = "NEXT_PUBLIC_API_ENDPOINT"
      value = var.api_gateway_endpoint
    }

    environment_variable {
      name  = "NEXT_PUBLIC_WS_ENDPOINT"
      value = var.ws_gateway_endpoint
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    buildspec       = "frontend/buildspec.yml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-frontend"
      stream_name = "build"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-frontend-build"
      Service = "frontend"
    }
  )
}

# ========================================
# CloudWatch Log Groups
# ========================================

resource "aws_cloudwatch_log_group" "game_service" {
  count             = var.create_game_service_build ? 1 : 0
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-game-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "record_service" {
  count             = var.create_record_service_build ? 1 : 0
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-record-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "record_service_migrate" {
  count             = var.create_record_service_migrate ? 1 : 0
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-record-service-migrate"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "text_service" {
  count             = var.create_text_service_build ? 1 : 0
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-text-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  count             = var.create_frontend_build ? 1 : 0
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-frontend"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
