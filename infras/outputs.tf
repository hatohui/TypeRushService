# TypeRush Infrastructure - Outputs

# ==================================
# Networking Outputs
# ==================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP (for whitelist if needed)"
  value       = module.networking.nat_gateway_public_ip
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for ECS, Lambda, ALB)"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs (for RDS)"
  value       = module.networking.database_subnet_ids
}

output "cache_subnet_ids" {
  description = "Cache subnet IDs (for ElastiCache)"
  value       = module.networking.cache_subnet_ids
}

# ==================================
# Cost Tracking Outputs
# ==================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    nat_gateway   = "$32.85"
    vpc_endpoints = "$28.80 (4 × $7.20)"
    rds_instance  = "$14.40"
    elasticache   = "$12.41"
    ecs_fargate   = "$10.88"
    internal_alb  = "$16.20"
    misc_services = "$5-10"
    total_monthly = "$120-135"
    daily_rate    = "$4-4.50"
    four_day_demo = "$16-20"
  }
}

# ==================================
# Deployment Info
# ==================================

output "deployment_info" {
  description = "Important deployment information"
  value = {
    region             = var.aws_region
    environment        = var.environment
    availability_zones = var.availability_zones
    vpc_cidr           = var.vpc_cidr
    deployment_time    = timestamp()
  }
}

# ==================================
# IAM Outputs
# ==================================

output "iam_roles" {
  description = "IAM roles created for services"
  value       = module.iam.iam_roles_summary
}

output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN (use in ECS task definitions)"
  value       = module.iam.ecs_task_execution_role_arn
}

output "game_service_task_role_arn" {
  description = "Game Service Task Role ARN (use in Game Service task definition)"
  value       = module.iam.game_service_task_role_arn
}

output "record_service_lambda_role_arn" {
  description = "Record Service Lambda Role ARN"
  value       = module.iam.record_service_lambda_role_arn
}

output "text_service_lambda_role_arn" {
  description = "Text Service Lambda Role ARN"
  value       = module.iam.text_service_lambda_role_arn
}

output "cloudfront_oai_iam_arn" {
  description = "CloudFront Origin Access Identity ARN (use in S3 bucket policy)"
  value       = module.iam.cloudfront_oai_iam_arn
}

# ==================================
# Secrets Manager Outputs
# ==================================

output "rds_secret_arn" {
  description = "ARN of the RDS credentials secret"
  value       = module.secrets_manager.rds_secret_arn
}

output "rds_secret_name" {
  description = "Name of the RDS credentials secret"
  value       = module.secrets_manager.rds_secret_name
}

output "elasticache_secret_arn" {
  description = "ARN of the ElastiCache AUTH token secret"
  value       = module.secrets_manager.elasticache_secret_arn
}

output "elasticache_secret_name" {
  description = "Name of the ElastiCache AUTH token secret"
  value       = module.secrets_manager.elasticache_secret_name
}

output "rds_master_username" {
  description = "Master username for RDS"
  value       = module.secrets_manager.rds_master_username
  sensitive   = true
}

output "rds_database_name" {
  description = "Database name for RDS"
  value       = module.secrets_manager.rds_database_name
}

# ==================================
# VPC Endpoints Outputs
# ==================================

output "vpc_endpoints_summary" {
  description = "Summary of all VPC endpoints created"
  value       = module.vpc_endpoints.endpoint_summary
}

output "secretsmanager_endpoint_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = module.vpc_endpoints.secretsmanager_endpoint_id
}

output "bedrock_runtime_endpoint_id" {
  description = "ID of the Bedrock Runtime VPC endpoint"
  value       = module.vpc_endpoints.bedrock_runtime_endpoint_id
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway endpoint"
  value       = module.vpc_endpoints.s3_endpoint_id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB Gateway endpoint"
  value       = module.vpc_endpoints.dynamodb_endpoint_id
}

# ==================================
# RDS PostgreSQL Outputs
# ==================================

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = module.rds.db_instance_id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "RDS hostname (without port)"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "RDS port number"
  value       = module.rds.db_instance_port
}

output "rds_connection_string_format" {
  description = "Format for PostgreSQL connection string (replace <PASSWORD>)"
  value       = module.rds.connection_string_format
  sensitive   = true
}

output "rds_engine_version" {
  description = "Actual PostgreSQL engine version deployed"
  value       = module.rds.db_engine_version
}

output "rds_cloudwatch_log_groups" {
  description = "CloudWatch log groups for RDS PostgreSQL logs"
  value       = module.rds.cloudwatch_log_groups
}

# ==================================
# ElastiCache Redis Outputs
# ==================================

output "redis_primary_endpoint" {
  description = "Primary endpoint address for Redis"
  value       = module.elasticache.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = module.elasticache.port
}

output "redis_connection_string" {
  description = "Redis connection string (use AUTH_TOKEN from Secrets Manager)"
  value       = module.elasticache.redis_connection_string
  sensitive   = false
}

output "redis_connection_info" {
  description = "Redis connection information for ECS environment variables"
  value       = module.elasticache.redis_connection_info
}

output "redis_engine_version" {
  description = "Actual Redis engine version deployed"
  value       = module.elasticache.engine_version
}

output "redis_node_type" {
  description = "Redis node type"
  value       = module.elasticache.node_type
}

output "redis_replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = module.elasticache.replication_group_id
}

# ==================================
# DynamoDB Outputs
# ==================================

output "dynamodb_texts_table_name" {
  description = "Name of the DynamoDB texts table"
  value       = module.dynamodb.texts_table_name
}

output "dynamodb_texts_table_arn" {
  description = "ARN of the DynamoDB texts table"
  value       = module.dynamodb.texts_table_arn
}

output "dynamodb_difficulty_language_index" {
  description = "Name of the difficulty-language GSI"
  value       = module.dynamodb.difficulty_language_index_name
}

output "dynamodb_category_created_index" {
  description = "Name of the category-created GSI"
  value       = module.dynamodb.category_created_index_name
}

# ==================================
# ECR Repository Outputs
# ==================================

output "game_service_repository_url" {
  description = "ECR repository URL for Game Service (use for docker push)"
  value       = module.ecr.game_service_repository_url
}

output "game_service_repository_arn" {
  description = "ARN of the Game Service ECR repository"
  value       = module.ecr.game_service_repository_arn
}

output "record_service_repository_url" {
  description = "ECR repository URL for Record Service (use for docker push)"
  value       = module.ecr.record_service_repository_url
}

output "record_service_repository_arn" {
  description = "ARN of the Record Service ECR repository"
  value       = module.ecr.record_service_repository_arn
}

output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = module.ecr.registry_id
}

# ==================================
# Internal ALB Outputs
# ==================================

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB (for VPC Link)"
  value       = module.alb.alb_dns_name
}

output "internal_alb_arn" {
  description = "ARN of the internal ALB"
  value       = module.alb.alb_arn
}

output "game_service_target_group_arn" {
  description = "ARN of the Game Service target group"
  value       = module.alb.target_group_arn
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = module.alb.listener_arn
}

# ==================================
# ECS Cluster Outputs
# ==================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "game_service_name" {
  description = "Name of the Game Service ECS service"
  value       = module.ecs.game_service_name
}

output "game_service_task_definition_arn" {
  description = "ARN of the Game Service task definition"
  value       = module.ecs.task_definition_arn
}

output "game_service_log_group" {
  description = "CloudWatch log group for Game Service"
  value       = module.ecs.log_group_name
}

# ==================================
# Lambda Outputs
# ==================================

output "record_service_function_name" {
  description = "Name of the Record Service Lambda function"
  value       = module.lambda.record_service_function_name
}

output "text_service_function_name" {
  description = "Name of the Text Service Lambda function"
  value       = module.lambda.text_service_function_name
}

# ==================================
# API Gateway Outputs
# ==================================

output "vpc_link_id" {
  description = "VPC Link ID for private API Gateway integration"
  value       = module.vpc_link.vpc_link_id
}

output "http_api_endpoint" {
  description = "HTTP API Gateway endpoint URL"
  value       = module.api_gateway_http.http_stage_invoke_url
}

output "websocket_api_endpoint" {
  description = "WebSocket API Gateway endpoint URL"
  value       = module.api_gateway_ws.websocket_stage_invoke_url
}

output "http_api_id" {
  description = "HTTP API Gateway ID"
  value       = module.api_gateway_http.http_api_id
}

output "websocket_api_id" {
  description = "WebSocket API Gateway ID"
  value       = module.api_gateway_ws.websocket_api_id
}

# ==================================
# Frontend & CDN Outputs
# ==================================

output "s3_bucket_name" {
  description = "S3 bucket name for frontend files"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name (use this to access your app)"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_url" {
  description = "Full CloudFront URL"
  value       = "https://${module.cloudfront.distribution_domain_name}"
}

# ==================================
# DNS Outputs
# ==================================

output "route53_hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.route53.hosted_zone_id
}

output "route53_name_servers" {
  description = "Name servers for Route 53 (add these to your domain registrar)"
  value       = module.route53.name_servers
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "Not configured"
}

# ==================================
# Security Outputs
# ==================================

output "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront"
  value       = module.acm.cloudfront_certificate_arn
}

output "acm_certificate_status" {
  description = "ACM certificate validation status"
  value       = module.acm.cloudfront_certificate_status
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = var.enable_waf ? module.waf.web_acl_id : "WAF not enabled"
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enable_waf ? module.waf.web_acl_arn : "WAF not enabled"
}

# ==================================
# Authentication Outputs
# ==================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = module.cognito.user_pool_arn
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID (use in frontend)"
  value       = module.cognito.user_pool_client_id
}

output "cognito_hosted_ui_url" {
  description = "Cognito Hosted UI URL"
  value       = module.cognito.hosted_ui_url
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = module.cognito.user_pool_domain
}

# ==================================
# CodePipeline Outputs
# ==================================

output "codepipeline_artifacts_bucket" {
  description = "S3 bucket for CodePipeline artifacts"
  value       = "${var.project_name}-${var.environment}-pipeline-artifacts"
}

output "codepipeline_summary" {
  description = "Summary of CodePipeline pipelines"
  value       = module.codepipeline.pipelines_summary
}

# ==================================
# Environment Variables for Services
# ==================================

output "service_environment_variables" {
  description = "Environment variables needed by services (save these securely)"
  value = {
    # Frontend Environment Variables
    VITE_COGNITO_USER_POOL_ID = module.cognito.user_pool_id
    VITE_COGNITO_CLIENT_ID    = module.cognito.user_pool_client_id
    VITE_COGNITO_DOMAIN       = module.cognito.user_pool_domain
    VITE_API_ENDPOINT         = module.api_gateway_http.http_stage_invoke_url
    VITE_WEBSOCKET_ENDPOINT   = module.api_gateway_ws.websocket_stage_invoke_url
    VITE_APP_URL              = var.domain_name != "" ? "https://${var.domain_name}" : "https://${module.cloudfront.distribution_domain_name}"

    # Game Service Environment Variables (already configured in ECS)
    REDIS_ENDPOINT = module.elasticache.primary_endpoint_address
    REDIS_PORT     = "6379"

    # Record Service Environment Variables (already configured in Lambda)
    DATABASE_URL = "Retrieved from Secrets Manager"

    # Text Service Environment Variables (already configured in Lambda)
    DYNAMODB_TABLE_NAME = module.dynamodb.texts_table_name
  }
  sensitive = false
}

# ==================================
# Next Steps
# ==================================

output "next_steps" {
  description = "Next steps after deployment"
  value = {
    step_1 = "Build and upload frontend: npm run build && aws s3 sync dist/ s3://${module.s3.bucket_id}"
    step_2 = "Invalidate CloudFront cache: aws cloudfront create-invalidation --distribution-id ${module.cloudfront.distribution_id} --paths '/*'"
    step_3 = "Access your app: https://${module.cloudfront.distribution_domain_name}"
    step_4 = var.domain_name != "" ? "Or use custom domain: https://${var.domain_name}" : "Configure custom domain in variables if needed"
    step_5 = "Create Cognito test user: aws cognito-idp admin-create-user --user-pool-id ${module.cognito.user_pool_id} --username testuser@example.com"
    step_6 = "When done: terraform destroy (remember to empty S3 bucket first)"
  }
}
