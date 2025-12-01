# ========================================
# Lambda Module Variables
# ========================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ========================================
# Network Configuration
# ========================================

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Lambda VPC configuration"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  type        = string
}

# ========================================
# IAM Configuration
# ========================================

variable "record_service_lambda_role_arn" {
  description = "IAM role ARN for Record Service Lambda function"
  type        = string
}

variable "text_service_lambda_role_arn" {
  description = "IAM role ARN for Text Service Lambda function"
  type        = string
}

# ========================================
# Database Configuration
# ========================================

variable "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS credentials"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for text storage"
  type        = string
}

# ========================================
# Lambda Deployment Package Paths
# ========================================

variable "record_service_package_path" {
  description = "Path to the Record Service Lambda deployment package (ZIP file) relative to Terraform root"
  type        = string
  default     = "../build/record-service-lambda.zip"
}

# Optional: Use S3 object instead of local filename
variable "record_use_s3" {
  description = "If true, deploy Record Service Lambda from S3 (s3_bucket + s3_key) instead of local filename"
  type        = bool
  default     = false
}

variable "record_service_s3_bucket" {
  description = "S3 bucket name where record service package is stored"
  type        = string
  default     = ""
}

variable "record_service_s3_key" {
  description = "S3 object key (path) for record service package"
  type        = string
  default     = ""
}

variable "record_service_s3_object_version" {
  description = "Optional S3 object version for record service package"
  type        = string
  default     = ""
}

# (Duplicate S3 deployment option for the Record Service was removed —
# the earlier declarations are kept to avoid variable name collisions.)

variable "text_service_package_path" {
  description = "Path to the Text Service Lambda deployment package (ZIP file) relative to Terraform root"
  type        = string
  default     = "../build/text-service-lambda.zip"
}

# Optional: Use S3 object instead of local filename
variable "text_use_s3" {
  description = "If true, deploy Text Service Lambda from S3 (s3_bucket + s3_key) instead of local filename"
  type        = bool
  default     = false
}

variable "text_service_s3_bucket" {
  description = "S3 bucket name where text service package is stored"
  type        = string
  default     = ""
}

variable "text_service_s3_key" {
  description = "S3 object key (path) for text service package"
  type        = string
  default     = ""
}

variable "text_service_s3_object_version" {
  description = "Optional S3 object version for text service package"
  type        = string
  default     = ""
}

# (Duplicate S3 deployment option for the Text Service was removed —
# the earlier declarations are kept to avoid variable name collisions.)

# ========================================
# Lambda Function Configuration
# ========================================

variable "lambda_record_memory" {
  description = "Memory allocation for Record Service Lambda in MB"
  type        = number
  default     = 512
}

variable "lambda_record_timeout" {
  description = "Timeout for Record Service Lambda in seconds"
  type        = number
  default     = 30
}

variable "lambda_text_memory" {
  description = "Memory allocation for Text Service Lambda in MB"
  type        = number
  default     = 512
}

variable "lambda_text_timeout" {
  description = "Timeout for Text Service Lambda in seconds"
  type        = number
  default     = 60
}

# ========================================
# Logging Configuration
# ========================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
