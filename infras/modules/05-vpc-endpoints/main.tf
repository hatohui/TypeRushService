# ==================================
# VPC Endpoints Module
# ==================================
# This module creates VPC endpoints for private AWS service access:
# - 4 Interface Endpoints: Secrets Manager, Bedrock, ECR API, ECR Docker
# - 2 Gateway Endpoints: S3, DynamoDB (FREE)
# 
# Benefits:
# - Improved security (traffic stays in AWS network)
# - Lower latency
# - Reduced NAT Gateway data transfer costs
# - Better for compliance requirements

# Get current region
data "aws_region" "current" {}

# ==================================
# Interface Endpoints (4)
# ==================================

# 1. Secrets Manager VPC Endpoint
# Used by: ECS Task Execution, Game Service, Record Service Lambda
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-secretsmanager-endpoint"
      Service = "secretsmanager"
      Type    = "interface"
    }
  )
}

# 2. Bedrock Runtime VPC Endpoint
# Used by: Text Service Lambda for AI text generation
resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-bedrock-runtime-endpoint"
      Service = "bedrock-runtime"
      Type    = "interface"
    }
  )
}

# 3. ECR API VPC Endpoint
# Used by: ECS for image manifest retrieval during task startup
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-ecr-api-endpoint"
      Service = "ecr-api"
      Type    = "interface"
    }
  )
}

# 4. ECR Docker VPC Endpoint
# Used by: ECS for pulling Docker image layers during task startup
# Note: Must be used together with ECR API endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-ecr-dkr-endpoint"
      Service = "ecr-dkr"
      Type    = "interface"
    }
  )
}

# ==================================
# Gateway Endpoints (2 - FREE)
# ==================================

# 5. S3 Gateway Endpoint
# Used by: Lambda for layers, CodeBuild for artifacts, ECS for ECR layer storage
# Note: Gateway endpoints are free and don't require security groups
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  # Associate with all route tables (private, database, cache)
  route_table_ids = [
    var.private_route_table_id,
    var.database_route_table_id,
    var.cache_route_table_id
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-s3-endpoint"
      Service = "s3"
      Type    = "gateway"
      Cost    = "FREE"
    }
  )
}

# 6. DynamoDB Gateway Endpoint
# Used by: Text Service Lambda for text storage and retrieval
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"

  # Associate with all route tables
  route_table_ids = [
    var.private_route_table_id,
    var.database_route_table_id,
    var.cache_route_table_id
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-dynamodb-endpoint"
      Service = "dynamodb"
      Type    = "gateway"
      Cost    = "FREE"
    }
  )
}
