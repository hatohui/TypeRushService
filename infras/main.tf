# ==================================
# TypeRush Infrastructure - Main Orchestration
# ==================================

# Local variables for common values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# ==================================
# Module 01: Networking
# ==================================

module "networking" {
  source = "./modules/01-networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  cache_subnet_cidrs    = var.cache_subnet_cidrs

  enable_vpc_flow_logs = var.enable_vpc_flow_logs
  log_retention_days   = var.log_retention_days
}

# ==================================
# Module 02: Security Groups
# ==================================

module "security_groups" {
  source = "./modules/02-security-groups"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  vpc_cidr             = var.vpc_cidr
  game_service_port    = var.game_service_port
  elasticache_port     = var.elasticache_port
  create_bastion       = var.create_bastion
  bastion_allowed_cidr = "0.0.0.0/32" # Update with your IP if using bastion
}

# ==================================
# Module 03: IAM Roles and Policies
# ==================================

module "iam" {
  source = "./modules/03-iam"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# ==================================
# Module 04: Secrets Manager
# ==================================

module "secrets_manager" {
  source = "./modules/04-secrets-manager"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Secret recovery configuration
  secret_recovery_window_days = var.secret_recovery_window_days

  # RDS configuration (will be updated after RDS module is created)
  rds_master_username = var.rds_master_username
  rds_database_name   = var.rds_database_name
  rds_port            = var.rds_port
  # rds_endpoint and rds_instance_id will be empty initially
  # They will be updated via terraform apply after RDS is created

  # ElastiCache configuration (will be updated after ElastiCache module is created)
  elasticache_port = var.elasticache_port
  # elasticache_endpoint will be empty initially
  # It will be updated via terraform apply after ElastiCache is created
}

# ==================================
# Module 05: VPC Endpoints
# ==================================

module "vpc_endpoints" {
  source = "./modules/05-vpc-endpoints"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # VPC and subnet configuration
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Security group for interface endpoints
  vpc_endpoints_security_group_id = module.security_groups.vpc_endpoints_security_group_id

  # Route tables for gateway endpoints
  private_route_table_id  = module.networking.private_route_table_id
  database_route_table_id = module.networking.database_route_table_id
  cache_route_table_id    = module.networking.cache_route_table_id
}

# ==================================
# Module 06: RDS PostgreSQL Database
# ==================================

module "rds" {
  source = "./modules/06-rds"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Network configuration
  database_subnet_ids   = module.networking.database_subnet_ids
  rds_security_group_id = module.security_groups.rds_security_group_id

  # Instance configuration
  instance_class    = var.rds_instance_class
  engine_version    = var.rds_engine_version
  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # Database configuration
  database_name   = var.rds_database_name
  database_port   = var.rds_port
  master_username = module.secrets_manager.rds_master_username
  master_password = module.secrets_manager.rds_master_password

  # Backup configuration
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00" # Singapore night time (UTC)
  maintenance_window      = "sun:04:00-sun:05:00"
  skip_final_snapshot     = false
  copy_tags_to_snapshot   = true

  # Monitoring configuration
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = var.enable_performance_insights
  monitoring_interval             = 0 # Disable enhanced monitoring for dev

  # Security configuration
  multi_az            = false 
  publicly_accessible = false
  deletion_protection = false # Allow deletion in dev
}

# ==================================
# Module 08: ElastiCache Redis
# ==================================

module "elasticache" {
  source = "./modules/08-elasticache"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Network configuration
  cache_subnet_ids              = module.networking.cache_subnet_ids
  elasticache_security_group_id = module.security_groups.elasticache_security_group_id

  # Redis configuration
  node_type          = var.elasticache_node_type
  engine_version     = var.elasticache_engine_version
  port               = var.elasticache_port
  num_cache_clusters = 1 # Single-node for dev

  # Authentication and encryption
  auth_token                 = module.secrets_manager.elasticache_auth_token
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  # Backup and maintenance
  snapshot_retention_limit   = 0 # No automatic snapshots for dev
  maintenance_window         = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade = false

  # Monitoring (optional for dev)
  enable_cloudwatch_logs = false
  log_retention_days     = var.log_retention_days
}

# ==================================
# Module 09: DynamoDB Tables
# ==================================

module "dynamodb" {
  source = "./modules/09-dynamodb"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Dev configuration: no PITR, no deletion protection
  point_in_time_recovery_enabled = false
  deletion_protection_enabled    = false
}

# ==================================
# Module 10: ECR Repositories
# ==================================

module "ecr" {
  source = "./modules/10-ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# ==================================
# Module 12: Internal Application Load Balancer
# ==================================

module "alb" {
  source = "./modules/12-alb"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Network configuration
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id

  # Health check configuration
  health_check_path     = "/health"
  health_check_interval = 30
  health_check_timeout  = 5
  healthy_threshold     = 2
  unhealthy_threshold   = 3
  deregistration_delay  = 30

  # ALB configuration
  idle_timeout               = 60
  enable_deletion_protection = false # Dev environment

  # SNS topic for alarms (optional, will be added when SNS module is implemented)
  # sns_topic_arn = module.sns.topic_arn
}

# ==================================
# Module 11: ECS Cluster and Game Service
# ==================================

module "ecs" {
  source = "./modules/11-ecs"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Network configuration
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.security_groups.ecs_security_group_id

  # IAM roles
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  game_service_task_role_arn  = module.iam.game_service_task_role_arn

  # ECR configuration
  game_service_ecr_url = module.ecr.game_service_repository_url

  # ElastiCache configuration
  redis_endpoint   = module.elasticache.primary_endpoint_address
  redis_secret_arn = module.secrets_manager.elasticache_secret_arn

  # Load balancer configuration
  game_service_target_group_arn = module.alb.target_group_arn
  alb_listener_arn              = module.alb.listener_arn

  # Task configuration
  game_service_cpu    = 256 # 0.25 vCPU
  game_service_memory = 512 # 0.5 GB
  log_retention_days  = var.log_retention_days

  # Auto-scaling configuration
  game_service_min_capacity = 1
  game_service_max_capacity = 2
  game_service_cpu_target   = 70
}

# ==================================
# Module 13: Lambda Functions
# ==================================

module "lambda" {
  source = "./modules/13-lambda"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Network configuration
  private_subnet_ids       = module.networking.private_subnet_ids
  lambda_security_group_id = module.security_groups.lambda_security_group_id

  # IAM roles
  record_service_lambda_role_arn = module.iam.record_service_lambda_role_arn
  text_service_lambda_role_arn   = module.iam.text_service_lambda_role_arn

  # Database configuration
  rds_secret_arn      = module.secrets_manager.rds_secret_arn
  dynamodb_table_name = module.dynamodb.texts_table_name

  # Lambda configuration
  lambda_record_memory  = var.lambda_record_memory
  lambda_record_timeout = var.lambda_record_timeout
  lambda_text_memory    = var.lambda_text_memory
  lambda_text_timeout   = var.lambda_text_timeout
  log_retention_days    = var.log_retention_days

  # ------------------------------------------------------------------
  # NOTE (bootstrapping): If you'd like lambdas to load code from the
  # CodePipeline artifacts bucket (manual upload or CI/CD), you can set:
  #
  # record_use_s3 = true
  # record_service_s3_bucket = "${var.project_name}-${var.environment}-pipeline-artifacts"
  # record_service_s3_key = "record-service-lambda.zip"
  #
  # text_use_s3 = true
  # text_service_s3_bucket = "${var.project_name}-${var.environment}-pipeline-artifacts"
  # text_service_s3_key = "text-service-lambda.zip"
  #
  # Recommended bootstrap order to avoid circular references with the
  # CodePipeline module:
  # 1) terraform apply -target=module.codepipeline
  # 2) upload zips to the artifacts bucket
  # 3) terraform apply -target=module.lambda (or set the *_use_s3 flags and apply)
  # ------------------------------------------------------------------
}

# ==================================
# Module 14: VPC Link v2
# ==================================

module "vpc_link" {
  source = "./modules/14-vpc-link"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Network configuration
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
}

# ==================================
# Module 15: API Gateway HTTP API
# ==================================

module "api_gateway_http" {
  source = "./modules/15-api-gateway-http"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # VPC Link configuration
  vpc_link_id      = module.vpc_link.vpc_link_id
  alb_listener_arn = module.alb.listener_arn

  # Lambda configuration
  record_service_lambda_invoke_arn = module.lambda.record_service_invoke_arn
  record_service_lambda_name       = module.lambda.record_service_function_name
  text_service_lambda_invoke_arn   = module.lambda.text_service_invoke_arn
  text_service_lambda_name         = module.lambda.text_service_function_name

  # API configuration
  stage_name           = "dev"
  cors_allow_origins   = ["*"] # Change to specific domains in production
  throttle_rate_limit  = 100
  throttle_burst_limit = 200
}

# ==================================
# Module 16: API Gateway WebSocket API
# ==================================

module "api_gateway_ws" {
  source = "./modules/16-api-gateway-ws"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # ALB configuration (WebSocket APIs do NOT support VPC Link V2)
  # Using direct INTERNET connection to ALB DNS
  alb_dns_name     = "http://${module.alb.alb_dns_name}"
  alb_listener_arn = module.alb.listener_arn

  # API configuration
  stage_name           = "dev"
  throttle_rate_limit  = 100
  throttle_burst_limit = 200
  enable_data_trace    = true
  logging_level        = "INFO"
}

# ==================================
# Module 17: S3 Frontend Bucket
# ==================================

module "s3" {
  source = "./modules/17-s3"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # S3 configuration
  enable_versioning    = false # Disabled for dev cost optimization
  cors_allowed_origins = var.cors_allowed_origins

  # CloudFront OAC bucket policy (will be updated after CloudFront is created)
  # The bucket policy uses concat() to conditionally include CloudFront access
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

# ==================================
# Module 18: ACM Certificates
# ==================================

module "acm" {
  source = "./modules/18-acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Domain configuration (leave empty to skip)
  domain_name     = var.domain_name
  route53_zone_id = var.domain_name != "" ? try(module.route53.hosted_zone_id, "") : ""

  # Optional API Gateway custom domain certificate
  use_api_custom_domain = false # Set to true if using custom API domains

  # Certificate monitoring
  enable_cert_expiry_alarm = false # Enable in production with SNS
  sns_topic_arn            = try(module.sns.alerts_topic_arn, "")
}

# ==================================
# Module 19: AWS WAF Web ACL
# ==================================

module "waf" {
  source = "./modules/19-waf"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # WAF configuration
  enable_waf         = var.enable_waf
  enable_waf_logging = true
  log_retention_days = var.log_retention_days

  # Rate limiting
  rate_limit_general = var.waf_rate_limit_general
  rate_limit_api     = var.waf_rate_limit_api

  # Geo blocking (empty list = disabled)
  blocked_countries = var.waf_blocked_countries
}

# ==================================
# Module 20: CloudFront Distribution
# ==================================

module "cloudfront" {
  source = "./modules/20-cloudfront"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # S3 origin configuration
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name

  # Domain and SSL configuration
  domain_name         = var.domain_name
  acm_certificate_arn = var.domain_name != "" ? try(module.acm.cloudfront_certificate_arn, "") : ""

  # WAF association
  waf_web_acl_arn = var.enable_waf ? try(module.waf.web_acl_arn, "") : ""

  # API Gateway origin (optional)
  api_gateway_domain_name = replace(module.api_gateway_http.http_api_endpoint, "https://", "")
  api_gateway_stage       = "dev"
  api_custom_header_value = "" # Add random value for extra security if needed

  # CloudFront configuration
  price_class          = var.cloudfront_price_class
  cors_allowed_origins = var.cors_allowed_origins
}

# ==================================
# Module 21: Route 53 DNS
# ==================================

module "route53" {
  source = "./modules/21-route53"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Domain configuration (leave empty to skip Route 53)
  domain_name         = var.domain_name
  create_route53_zone = var.create_route53_zone

  # CloudFront alias records
  cloudfront_domain_name    = try(module.cloudfront.distribution_domain_name, "")
  cloudfront_hosted_zone_id = try(module.cloudfront.distribution_hosted_zone_id, "")

  # Optional API Gateway custom domains
  api_gateway_custom_domain = "" # Add if using custom API domain
  ws_gateway_custom_domain  = "" # Add if using custom WebSocket domain

  # Health checks (optional for production)
  enable_health_check            = false
  health_check_path              = "/health"
  health_check_interval          = 30
  health_check_failure_threshold = 3
  sns_topic_arn                  = try(module.sns.alerts_topic_arn, "")
}

# ==================================
# Module 22: Cognito User Authentication
# ==================================

module "cognito" {
  source = "./modules/22-cognito"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Cognito domain (must be globally unique)
  cognito_domain_suffix = var.cognito_domain_suffix

  # Password policy
  password_minimum_length = var.cognito_password_min_length

  # MFA configuration
  enable_mfa = var.cognito_enable_mfa

  # OAuth callback and logout URLs
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  # Identity pool (optional - for direct AWS service access)
  create_identity_pool = false # Set to true if frontend needs AWS credentials
}

# ==================================
# Module 23: SNS Topics for Alerting
# ==================================

module "sns" {
  source = "./modules/23-sns"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Email configuration
  alert_email                   = var.alert_email
  deployment_notification_email = var.alert_email # Use same email for both

  # Feature flags
  enable_pipeline_notifications = false # Enable when CodePipeline is implemented
}

# ==================================
# Module 24: CloudWatch Monitoring
# ==================================

module "cloudwatch" {
  source = "./modules/24-cloudwatch"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # SNS topic for alarms
  sns_topic_arn = module.sns.alerts_topic_arn

  # ECS configuration
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.game_service_name

  # Lambda configuration
  record_lambda_name = module.lambda.record_service_function_name
  text_lambda_name   = module.lambda.text_service_function_name

  # RDS configuration
  rds_instance_id = module.rds.db_instance_id

  # ElastiCache configuration
  elasticache_cluster_id = module.elasticache.replication_group_id

  # API Gateway configuration
  api_gateway_id = module.api_gateway_http.http_api_id

  # Feature flags (enable alarms you want)
  enable_ecs_alarms         = true
  enable_lambda_alarms      = true
  enable_rds_alarms         = true
  enable_elasticache_alarms = true
  enable_api_gateway_alarms = true
  create_dashboard          = true
}

# ==================================
# Module 25: CodeBuild Projects
# ==================================

module "codebuild" {
  source = "./modules/25-codebuild"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # IAM role
  codebuild_role_arn = module.iam.codebuild_role_arn

  # Source configuration
  source_type     = "GITHUB" # Change to GITLAB if using GitLab
  source_location = var.gitlab_repository_url

  # Feature flags (enable builds you need)
  create_game_service_build     = false # Enable when ready to build
  create_record_service_build   = false
  create_record_service_migrate = false
  create_text_service_build     = false
  create_frontend_build         = false

  # ECR configuration
  game_service_ecr_uri = module.ecr.game_service_repository_url

  # Lambda configuration
  record_lambda_name = module.lambda.record_service_function_name
  text_lambda_name   = module.lambda.text_service_function_name

  # RDS configuration (for migrations)
  rds_secret_arn = module.secrets_manager.rds_secret_arn

  # S3 and CloudFront configuration
  frontend_s3_bucket_name    = module.s3.bucket_id
  cloudfront_distribution_id = module.cloudfront.distribution_id

  # Artifacts bucket used by pipelines and codebuild (pipeline module will create this bucket)
  artifacts_bucket_name = "${var.project_name}-${var.environment}-pipeline-artifacts"

  # API Gateway endpoints for frontend
  api_gateway_endpoint = module.api_gateway_http.http_api_endpoint
  ws_gateway_endpoint  = module.api_gateway_ws.websocket_api_endpoint

  # Logs
  log_retention_days = var.log_retention_days
}

# ==================================
# Module 26: CodePipeline CI/CD
# ==================================

module "codepipeline" {
  source = "./modules/26-codepipeline"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # IAM configuration
  codepipeline_role_arn = module.iam.codepipeline_role_arn

  # Source configuration
  codestar_connection_arn = var.codestar_connection_arn
  repository_id           = var.repository_id
  branch_name             = var.pipeline_branch_name

  # S3 artifact store (created by module)
  artifacts_bucket_name = "${var.project_name}-${var.environment}-pipeline-artifacts"
  artifacts_bucket_arn  = "arn:aws:s3:::${var.project_name}-${var.environment}-pipeline-artifacts"

  # ECS configuration (Game Service)
  ecs_cluster_name               = module.ecs.cluster_name
  game_service_name              = module.ecs.game_service_name
  game_service_codebuild_project = "${var.project_name}-${var.environment}-game-service"

  # Lambda configuration (Record Service)
  record_service_lambda_name               = module.lambda.record_service_function_name
  record_service_codebuild_project         = "${var.project_name}-${var.environment}-record-service"
  record_service_migrate_codebuild_project = "${var.project_name}-${var.environment}-record-service-migrate"

  # Lambda configuration (Text Service)
  text_service_lambda_name       = module.lambda.text_service_function_name
  text_service_codebuild_project = "${var.project_name}-${var.environment}-text-service"

  # Frontend configuration (S3 + CloudFront)
  frontend_s3_bucket_name    = module.s3.bucket_id
  cloudfront_distribution_id = module.cloudfront.distribution_id
  frontend_codebuild_project = "${var.project_name}-${var.environment}-frontend"

  # Feature flags (all disabled by default)
  create_game_service_pipeline   = var.create_game_service_pipeline
  create_record_service_pipeline = var.create_record_service_pipeline
  create_text_service_pipeline   = var.create_text_service_pipeline
  create_frontend_pipeline       = var.create_frontend_pipeline

  # SNS notifications (optional)
  enable_pipeline_notifications = false # Enable when SNS is configured
  sns_topic_arn                 = try(module.sns.deployment_topic_arn, "")
}

# ==================================
# Additional modules will be added progressively
# ==================================
