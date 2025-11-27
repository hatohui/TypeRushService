# IAM Module Outputs

# -----------------------------------------------------
# ECS Roles
# -----------------------------------------------------

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role (for pulling images, getting secrets)"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "game_service_task_role_arn" {
  description = "ARN of the Game Service ECS Task Role (for ElastiCache, Lambda invocation)"
  value       = aws_iam_role.game_service_task.arn
}

output "game_service_task_role_name" {
  description = "Name of the Game Service ECS Task Role"
  value       = aws_iam_role.game_service_task.name
}

# -----------------------------------------------------
# Lambda Roles
# -----------------------------------------------------

output "record_service_lambda_role_arn" {
  description = "ARN of the Record Service Lambda Role (for RDS access)"
  value       = aws_iam_role.record_service_lambda.arn
}

output "record_service_lambda_role_name" {
  description = "Name of the Record Service Lambda Role"
  value       = aws_iam_role.record_service_lambda.name
}

output "text_service_lambda_role_arn" {
  description = "ARN of the Text Service Lambda Role (for DynamoDB and Bedrock)"
  value       = aws_iam_role.text_service_lambda.arn
}

output "text_service_lambda_role_name" {
  description = "Name of the Text Service Lambda Role"
  value       = aws_iam_role.text_service_lambda.name
}

# -----------------------------------------------------
# CI/CD Roles
# -----------------------------------------------------

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild Role"
  value       = aws_iam_role.codebuild.arn
}

output "codebuild_role_name" {
  description = "Name of the CodeBuild Role"
  value       = aws_iam_role.codebuild.name
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline Role"
  value       = aws_iam_role.codepipeline.arn
}

output "codepipeline_role_name" {
  description = "Name of the CodePipeline Role"
  value       = aws_iam_role.codepipeline.name
}

# -----------------------------------------------------
# CloudFront
# -----------------------------------------------------

output "cloudfront_oai_id" {
  description = "CloudFront Origin Access Identity ID"
  value       = aws_cloudfront_origin_access_identity.frontend.id
}

output "cloudfront_oai_iam_arn" {
  description = "CloudFront Origin Access Identity IAM ARN (for S3 bucket policy)"
  value       = aws_cloudfront_origin_access_identity.frontend.iam_arn
}

output "cloudfront_oai_path" {
  description = "CloudFront Origin Access Identity path"
  value       = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
}

# -----------------------------------------------------
# Summary Output
# -----------------------------------------------------

output "iam_roles_summary" {
  description = "Summary of all IAM roles created"
  value = {
    ecs = {
      task_execution_role = aws_iam_role.ecs_task_execution.name
      game_service_role   = aws_iam_role.game_service_task.name
    }
    lambda = {
      record_service_role = aws_iam_role.record_service_lambda.name
      text_service_role   = aws_iam_role.text_service_lambda.name
    }
    cicd = {
      codebuild_role    = aws_iam_role.codebuild.name
      codepipeline_role = aws_iam_role.codepipeline.name
    }
    cloudfront = {
      oai_id = aws_cloudfront_origin_access_identity.frontend.id
    }
  }
}
