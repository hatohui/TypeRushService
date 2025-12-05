# TypeRush Dev Environment Configuration
# ======================================

# Core Settings
project_name = "typerush"
environment  = "dev"
owner        = "hatospapal@example.com"

# Region Configuration
aws_region         = "ap-southeast-1"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

# Networking
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
database_subnet_cidrs = ["10.0.201.0/24", "10.0.202.0/24"]
cache_subnet_cidrs    = ["10.0.203.0/24", "10.0.204.0/24"]

# RDS PostgreSQL
rds_instance_class          = "db.t3.micro"
rds_engine_version          = "17"
rds_allocated_storage       = 20
rds_backup_retention_period = 1
rds_database_name           = "typerush_records"
rds_master_username         = "typerush_admin"

# ElastiCache Redis
elasticache_node_type      = "cache.t4g.micro"
elasticache_engine_version = "7.1"
elasticache_port           = 6379

# ECS Fargate
ecs_task_cpu              = 256 # 0.25 vCPU
ecs_task_memory           = 512 # 0.5 GB
ecs_desired_count         = 1
ecs_min_capacity          = 1
ecs_max_capacity          = 2
ecs_target_cpu_percentage = 70
game_service_port         = 3000

# Lambda
lambda_record_memory  = 512
lambda_record_timeout = 30
lambda_text_memory    = 512
lambda_text_timeout   = 60

# CloudWatch
log_retention_days = 7

# Alerts
alert_email = "hatospapal@example.com" # CHANGE THIS

# Domain (Optional - leave empty if not using custom domain)
domain_name         = ""
create_route53_zone = false

# Feature Flags
enable_waf                  = true
enable_vpc_flow_logs        = false
enable_performance_insights = false
create_bastion              = false

# GitLab Integration (Optional)
gitlab_webhook_token  = "" # Add if using GitLab CI/CD
gitlab_repository_url = ""

# CloudFront Configuration
cloudfront_price_class = "PriceClass_100" # US, Canada, Europe - cheapest
cors_allowed_origins   = ["*"]            # Change to specific domains in production

# WAF Configuration
waf_rate_limit_general = 2000 # Requests per 5 minutes per IP
waf_rate_limit_api     = 500  # API requests per 5 minutes per IP
waf_blocked_countries  = []   # e.g., ["CN", "RU"] to block countries

# Cognito Configuration
cognito_domain_suffix       = "auth" # Must be globally unique, will become: typerush-dev-auth
cognito_password_min_length = 8
cognito_enable_mfa          = false # Enable for production
# cognito_callback_urls and cognito_logout_urls use defaults from variables.tf
# Defaults include: localhost:3000 and localhost:5173 (Vite dev server)
# After first deploy, add CloudFront URL: cognito_callback_urls = ["http://localhost:3000/callback", "http://localhost:5173/callback", "https://<cloudfront-domain>/callback"]


# CodePipeline Configuration (GitLab Integration)
# IMPORTANT: After running terraform apply, follow setup instructions in docs/GITLAB_CODEPIPELINE_SETUP.md
codestar_connection_arn = "" # Will be filled after creating GitLab connection (see setup guide)
repository_id           = "" # e.g., "hatohui/TypeRushService" - your GitLab username/repo
pipeline_branch_name    = "main"

# Enable pipelines (set to true to create)
create_game_service_pipeline   = true
create_record_service_pipeline = true
create_text_service_pipeline   = true
create_frontend_pipeline       = true