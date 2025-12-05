# ==================================
# CodePipeline Module Variables
# ==================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------
# IAM Configuration
# -----------------------------------------------------

variable "codepipeline_role_arn" {
  description = "ARN of the IAM role for CodePipeline"
  type        = string
}

# -----------------------------------------------------
# Source Configuration (GitLab/GitHub)
# -----------------------------------------------------

variable "source_provider" {
  description = "Source provider type (CodeStarSourceConnection for GitLab/GitHub)"
  type        = string
  default     = "CodeStarSourceConnection"
}

variable "codestar_connection_arn" {
  description = "ARN of AWS CodeStar connection for GitLab/GitHub"
  type        = string
  default     = ""
}

variable "repository_id" {
  description = "Full repository ID (e.g., 'owner/repo-name')"
  type        = string
  default     = ""
}

variable "branch_name" {
  description = "Branch to trigger pipeline"
  type        = string
  default     = "main"
}

# -----------------------------------------------------
# S3 Artifact Store
# -----------------------------------------------------

variable "artifacts_bucket_name" {
  description = "S3 bucket name for pipeline artifacts"
  type        = string
}

variable "artifacts_bucket_arn" {
  description = "S3 bucket ARN for pipeline artifacts"
  type        = string
}

# -----------------------------------------------------
# ECS Configuration (Game Service)
# -----------------------------------------------------

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "game_service_name" {
  description = "Name of the Game Service ECS service"
  type        = string
}

variable "game_service_codebuild_project" {
  description = "CodeBuild project name for Game Service"
  type        = string
}

# -----------------------------------------------------
# Lambda Configuration (Record & Text Services)
# -----------------------------------------------------

variable "record_service_lambda_name" {
  description = "Name of the Record Service Lambda function"
  type        = string
}

variable "record_service_codebuild_project" {
  description = "CodeBuild project name for Record Service"
  type        = string
}

variable "record_service_migrate_codebuild_project" {
  description = "CodeBuild project name for Record Service migrations"
  type        = string
}

variable "text_service_lambda_name" {
  description = "Name of the Text Service Lambda function"
  type        = string
}

variable "text_service_codebuild_project" {
  description = "CodeBuild project name for Text Service"
  type        = string
}

# -----------------------------------------------------
# Frontend Configuration (S3 + CloudFront)
# -----------------------------------------------------

variable "frontend_s3_bucket_name" {
  description = "S3 bucket name for frontend hosting"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  type        = string
}

variable "frontend_codebuild_project" {
  description = "CodeBuild project name for Frontend"
  type        = string
}

# -----------------------------------------------------
# Feature Flags
# -----------------------------------------------------

variable "create_game_service_pipeline" {
  description = "Whether to create Game Service pipeline"
  type        = bool
  default     = false
}

variable "create_record_service_pipeline" {
  description = "Whether to create Record Service pipeline"
  type        = bool
  default     = false
}

variable "create_text_service_pipeline" {
  description = "Whether to create Text Service pipeline"
  type        = bool
  default     = false
}

variable "create_frontend_pipeline" {
  description = "Whether to create Frontend pipeline"
  type        = bool
  default     = false
}

# -----------------------------------------------------
# SNS Configuration (Optional)
# -----------------------------------------------------

variable "enable_pipeline_notifications" {
  description = "Enable SNS notifications for pipeline events"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for pipeline notifications"
  type        = string
  default     = ""
}
