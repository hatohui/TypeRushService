# ==================================
# Core Project Variables
# ==================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "typerush"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner email or name for tagging"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-southeast-1"
}

# ==================================
# Networking Variables
# ==================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones (single AZ for dev)"
  type        = list(string)
  default     = ["ap-southeast-1a"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.201.0/24"]
}

variable "cache_subnet_cidrs" {
  description = "CIDR blocks for ElastiCache subnets"
  type        = list(string)
  default     = ["10.0.202.0/24"]
}

# ==================================
# RDS Variables
# ==================================

variable "rds_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 1
}

variable "rds_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "typerush_records"
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "typerush_admin"
  sensitive   = true
}

variable "rds_port" {
  description = "Port for RDS PostgreSQL"
  type        = number
  default     = 5432
}

# ==================================
# Secrets Manager Variables
# ==================================

variable "secret_recovery_window_days" {
  description = "Number of days to retain deleted secrets (0 for immediate deletion, max 30)"
  type        = number
  default     = 7
}

# ==================================
# ElastiCache Variables
# ==================================

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "elasticache_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "elasticache_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

# ==================================
# ECS Variables
# ==================================

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_target_cpu_percentage" {
  description = "Target CPU utilization for auto-scaling"
  type        = number
  default     = 70
}

variable "game_service_port" {
  description = "Port for Game Service container"
  type        = number
  default     = 3000
}

# ==================================
# Lambda Variables
# ==================================

variable "lambda_record_memory" {
  description = "Memory allocation for Record Service Lambda"
  type        = number
  default     = 512
}

variable "lambda_record_timeout" {
  description = "Timeout for Record Service Lambda in seconds"
  type        = number
  default     = 30
}

variable "lambda_text_memory" {
  description = "Memory allocation for Text Service Lambda"
  type        = number
  default     = 512
}

variable "lambda_text_timeout" {
  description = "Timeout for Text Service Lambda in seconds"
  type        = number
  default     = 60
}

# ==================================
# CloudWatch Variables
# ==================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ==================================
# Alert Variables
# ==================================

variable "alert_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
}

# ==================================
# Domain Variables (Optional)
# ==================================

variable "domain_name" {
  description = "Domain name for Route 53 (leave empty to skip)"
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Whether to create Route 53 hosted zone"
  type        = bool
  default     = false
}

# ==================================
# Feature Flags
# ==================================

variable "enable_waf" {
  description = "Enable WAF for CloudFront"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = false
}

variable "create_bastion" {
  description = "Create bastion host for debugging"
  type        = bool
  default     = false
}

# ==================================
# GitLab/GitHub Integration (CodePipeline)
# ==================================

variable "gitlab_webhook_token" {
  description = "GitLab webhook token for CodePipeline"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitlab_repository_url" {
  description = "GitLab repository URL"
  type        = string
  default     = ""
}

variable "codestar_connection_arn" {
  description = "ARN of AWS CodeStar connection for GitLab/GitHub integration"
  type        = string
  default     = ""
}

variable "repository_id" {
  description = "Full repository ID for CodePipeline (e.g., 'owner/repo-name')"
  type        = string
  default     = ""
}

variable "pipeline_branch_name" {
  description = "Branch name to trigger CodePipeline"
  type        = string
  default     = "main"
}

# ==================================
# CodePipeline Feature Flags
# ==================================

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

# ==================================
# CloudFront Variables
# ==================================

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

# ==================================
# WAF Variables
# ==================================

variable "waf_rate_limit_general" {
  description = "General WAF rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

variable "waf_rate_limit_api" {
  description = "API WAF rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 500
}

variable "waf_blocked_countries" {
  description = "List of country codes to block (e.g., ['CN', 'RU']). Empty list disables geo blocking."
  type        = list(string)
  default     = []
}

# ==================================
# Cognito Variables
# ==================================

variable "cognito_domain_suffix" {
  description = "Suffix for Cognito hosted UI domain (must be globally unique)"
  type        = string
  default     = "auth"
}

variable "cognito_password_min_length" {
  description = "Minimum password length for Cognito"
  type        = number
  default     = 8
}

variable "cognito_enable_mfa" {
  description = "Enable MFA for Cognito user pool"
  type        = bool
  default     = false
}

variable "cognito_callback_urls" {
  description = "List of callback URLs for Cognito OAuth (include localhost for dev + production URLs)"
  type        = list(string)
  default     = ["http://localhost:3000/callback", "http://localhost:5173/callback"]
}

variable "cognito_logout_urls" {
  description = "List of logout URLs for Cognito OAuth (include localhost for dev + production URLs)"
  type        = list(string)
  default     = ["http://localhost:3000/", "http://localhost:5173/"]
}