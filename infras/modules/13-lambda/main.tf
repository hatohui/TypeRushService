# ========================================
# Lambda Functions for TypeRush Services
# ========================================

# Data source for current AWS region
data "aws_region" "current" {}

# ========================================
# Record Service Lambda Function
# ========================================

# CloudWatch Log Group for Record Service
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

# Record Service Lambda Function
resource "aws_lambda_function" "record_service" {
  function_name = "${var.project_name}-${var.environment}-record-service"
  role          = var.record_service_lambda_role_arn

  # Deployment package from build directory
  # Build using: cd services/record-service && ./build-lambda.ps1
  filename         = "${path.root}/${var.record_service_package_path}"
  source_code_hash = fileexists("${path.root}/${var.record_service_package_path}") ? filebase64sha256("${path.root}/${var.record_service_package_path}") : null

  runtime       = "nodejs20.x"
  handler       = "lambda.handler"
  architectures = ["arm64"]

  memory_size = var.lambda_record_memory
  timeout     = var.lambda_record_timeout

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      NODE_ENV      = "production"
      LOG_LEVEL     = "info"
      DB_SECRET_ARN = var.rds_secret_arn
      AWS_REGION    = data.aws_region.current.id
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

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }
}

# ========================================
# Text Service Lambda Function
# ========================================

# CloudWatch Log Group for Text Service
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

# Text Service Lambda Function
resource "aws_lambda_function" "text_service" {
  function_name = "${var.project_name}-${var.environment}-text-service"
  role          = var.text_service_lambda_role_arn

  # Deployment package from build directory
  # Build using: cd services/text-service && ./build-lambda.ps1
  filename         = "${path.root}/${var.text_service_package_path}"
  source_code_hash = fileexists("${path.root}/${var.text_service_package_path}") ? filebase64sha256("${path.root}/${var.text_service_package_path}") : null

  runtime       = "python3.12"
  handler       = "lambda_handler.lambda_handler"
  architectures = ["arm64"]

  memory_size = var.lambda_text_memory
  timeout     = var.lambda_text_timeout

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      ENVIRONMENT         = "production"
      LOG_LEVEL           = "INFO"
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      BEDROCK_MODEL_ID    = "amazon.titan-text-express-v1"
      AWS_REGION          = data.aws_region.current.id
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

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }
}

# ========================================
# Lambda Permissions
# ========================================

# Note: API Gateway permissions will be added when API Gateway module is implemented
# Note: These functions will be invoked directly by API Gateway (no permissions needed for direct integration)
# The IAM roles already have the necessary permissions configured in the IAM module

# Optional: Lambda Permission for internal ECS invocation (if Game Service invokes directly)
resource "aws_lambda_permission" "record_service_internal" {
  statement_id  = "AllowInternalInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.record_service.function_name
  principal     = "ecs-tasks.amazonaws.com"
}

resource "aws_lambda_permission" "text_service_internal" {
  statement_id  = "AllowInternalInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_service.function_name
  principal     = "ecs-tasks.amazonaws.com"
}
