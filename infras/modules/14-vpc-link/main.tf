# ========================================
# API Gateway VPC Link v2
# ========================================
# VPC Link enables private integration between API Gateway 
# and internal resources (ALB) without requiring internet exposure

resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.project_name}-${var.environment}-vpc-link"
  security_group_ids = [var.alb_security_group_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-link"
    }
  )
}
