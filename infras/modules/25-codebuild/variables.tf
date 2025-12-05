# ========================================
# CodeBuild Module Variables
# ========================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "codebuild_role_arn" {
  description = "ARN of the IAM role for CodeBuild"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 7
}

# ========================================
# Source Configuration
# ========================================

variable "source_type" {
  description = "Source type for CodeBuild (GITHUB, GITLAB, CODECOMMIT, etc.)"
  type        = string
  default     = "GITHUB"
}

variable "source_location" {
  description = "Source repository URL"
  type        = string
  default     = ""
}

# ========================================
# Feature Flags
# ========================================

variable "create_game_service_build" {
  description = "Create Game Service build project"
  type        = bool
  default     = false
}

variable "create_record_service_build" {
  description = "Create Record Service build project"
  type        = bool
  default     = false
}

variable "create_record_service_migrate" {
  description = "Create Record Service migration project"
  type        = bool
  default     = false
}

variable "create_text_service_build" {
  description = "Create Text Service build project"
  type        = bool
  default     = false
}

variable "create_frontend_build" {
  description = "Create Frontend build project"
  type        = bool
  default     = false
}

# ========================================
# ECR Configuration
# ========================================

variable "game_service_ecr_uri" {
  description = "URI of the Game Service ECR repository"
  type        = string
  default     = ""
}

# ========================================
# Lambda Configuration
# ========================================

variable "record_lambda_name" {
  description = "Name of the Record Service Lambda function"
  type        = string
  default     = ""
}

variable "text_lambda_name" {
  description = "Name of the Text Service Lambda function"
  type        = string
  default     = ""
}

# ========================================
# RDS Configuration
# ========================================

variable "rds_secret_arn" {
  description = "ARN of the RDS secret in Secrets Manager"
  type        = string
  default     = ""
}

# ========================================
# S3 and CloudFront Configuration
# ========================================

variable "frontend_s3_bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  type        = string
  default     = ""
}

# Artifacts bucket for build outputs (used to upload lambda zips)
variable "artifacts_bucket_name" {
  description = "S3 bucket name for pipeline artifacts (used by build projects to upload lambda zips)"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for cache invalidation"
  type        = string
  default     = ""
}

# ========================================
# API Gateway Configuration
# ========================================

variable "api_gateway_endpoint" {
  description = "API Gateway HTTP API endpoint"
  type        = string
  default     = ""
}

variable "ws_gateway_endpoint" {
  description = "API Gateway WebSocket endpoint"
  type        = string
  default     = ""
}
