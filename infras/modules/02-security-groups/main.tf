# ==================================
# Module 02: Security Groups
# All security groups with least-privilege rules
# ==================================

# ==================================
# 1. Internal ALB Security Group
# ==================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for internal Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow HTTP from VPC Link (API Gateway Private Link ENIs)
resource "aws_vpc_security_group_ingress_rule" "alb_http_from_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from VPC (API Gateway VPC Link)"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

# Allow HTTPS from VPC (optional for future)
resource "aws_vpc_security_group_ingress_rule" "alb_https_from_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from VPC (future use)"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

# Allow all outbound to ECS tasks
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow outbound to ECS tasks"

  from_port                    = var.game_service_port
  to_port                      = var.game_service_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

# ==================================
# 2. ECS Security Group (Game Service)
# ==================================

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-"
  description = "Security group for ECS Fargate tasks (Game Service)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow traffic from ALB only
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow traffic from internal ALB"

  from_port                    = var.game_service_port
  to_port                      = var.game_service_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# Allow outbound to ElastiCache
resource "aws_vpc_security_group_egress_rule" "ecs_to_elasticache" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow outbound to ElastiCache Redis"

  from_port                    = var.elasticache_port
  to_port                      = var.elasticache_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.elasticache.id
}

# Allow outbound to VPC endpoints (HTTPS)
resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_endpoints" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow outbound to VPC endpoints"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

# Allow outbound to internet via NAT Gateway (for logs, init)
resource "aws_vpc_security_group_egress_rule" "ecs_to_internet" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow outbound to internet via NAT Gateway"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ==================================
# 3. Lambda Security Group (for VPC Lambdas)
# ==================================

resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  description = "Security group for Lambda functions in VPC"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow outbound to RDS
resource "aws_vpc_security_group_egress_rule" "lambda_to_rds" {
  security_group_id = aws_security_group.lambda.id
  description       = "Allow outbound to RDS PostgreSQL"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

# Allow outbound to VPC endpoints
resource "aws_vpc_security_group_egress_rule" "lambda_to_vpc_endpoints" {
  security_group_id = aws_security_group.lambda.id
  description       = "Allow outbound to VPC endpoints"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

# Allow outbound to internet via NAT Gateway
resource "aws_vpc_security_group_egress_rule" "lambda_to_internet" {
  security_group_id = aws_security_group.lambda.id
  description       = "Allow outbound to internet via NAT Gateway"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ==================================
# 4. RDS Security Group
# ==================================

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS PostgreSQL (Record Service)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow PostgreSQL from Lambda only (Record Service Lambda)
resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL from Lambda (Record Service)"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}

# No egress rules needed for RDS (default deny)

# ==================================
# 5. ElastiCache Security Group
# ==================================

resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-${var.environment}-elasticache-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-elasticache-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow Redis from ECS only (Game Service)
resource "aws_vpc_security_group_ingress_rule" "elasticache_from_ecs" {
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow Redis from ECS (Game Service)"

  from_port                    = var.elasticache_port
  to_port                      = var.elasticache_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

# No egress rules needed for ElastiCache

# ==================================
# 6. VPC Endpoints Security Group
# ==================================

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-${var.environment}-vpce-"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-vpce-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow HTTPS from ECS
resource "aws_vpc_security_group_ingress_rule" "vpce_from_ecs" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow HTTPS from ECS tasks"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

# Allow HTTPS from Lambda
resource "aws_vpc_security_group_ingress_rule" "vpce_from_lambda" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow HTTPS from Lambda functions"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}

# No egress rules needed for VPC endpoints

# ==================================
# 7. Bastion Security Group (Optional)
# ==================================

resource "aws_security_group" "bastion" {
  count       = var.create_bastion ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-bastion-"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow SSH from specific IPs (you must provide IP ranges)
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  count             = var.create_bastion ? 1 : 0
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH from specific IPs"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.bastion_allowed_cidr
}

# Allow outbound to RDS for debugging
resource "aws_vpc_security_group_egress_rule" "bastion_to_rds" {
  count             = var.create_bastion ? 1 : 0
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow outbound to RDS for debugging"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

# Allow RDS ingress from bastion
resource "aws_vpc_security_group_ingress_rule" "rds_from_bastion" {
  count             = var.create_bastion ? 1 : 0
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL from bastion"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion[0].id
}
