# ==================================
# Route 53 DNS Module
# ==================================

# Route 53 Hosted Zone (only create if domain is provided and create_route53_zone is true)
resource "aws_route53_zone" "main" {
  count = var.create_route53_zone && var.domain_name != "" ? 1 : 0

  name    = var.domain_name
  comment = "Hosted zone for ${var.project_name} ${var.environment}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-hosted-zone"
    }
  )
}

# Use existing hosted zone if provided
data "aws_route53_zone" "existing" {
  count = !var.create_route53_zone && var.domain_name != "" ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

# Local value for zone ID (either created or existing)
locals {
  zone_id = var.domain_name != "" ? (
    var.create_route53_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  ) : ""
}

# A Record - CloudFront Distribution (IPv4)
resource "aws_route53_record" "root_a" {
  count = var.domain_name != "" && var.cloudfront_domain_name != "" ? 1 : 0

  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA Record - CloudFront Distribution (IPv6)
resource "aws_route53_record" "root_aaaa" {
  count = var.domain_name != "" && var.cloudfront_domain_name != "" ? 1 : 0

  zone_id = local.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# A Record - www subdomain
resource "aws_route53_record" "www_a" {
  count = var.domain_name != "" && var.cloudfront_domain_name != "" ? 1 : 0

  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA Record - www subdomain
resource "aws_route53_record" "www_aaaa" {
  count = var.domain_name != "" && var.cloudfront_domain_name != "" ? 1 : 0

  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# CNAME Record - API subdomain (optional for API Gateway custom domain)
resource "aws_route53_record" "api" {
  count = var.domain_name != "" && var.api_gateway_custom_domain != "" ? 1 : 0

  zone_id = local.zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.api_gateway_custom_domain]
}

# CNAME Record - WebSocket subdomain (optional)
resource "aws_route53_record" "ws" {
  count = var.domain_name != "" && var.ws_gateway_custom_domain != "" ? 1 : 0

  zone_id = local.zone_id
  name    = "ws.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.ws_gateway_custom_domain]
}

# Health Check (optional - for production monitoring)
resource "aws_route53_health_check" "main" {
  count = var.enable_health_check && var.domain_name != "" ? 1 : 0

  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = var.health_check_failure_threshold
  request_interval  = var.health_check_interval

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-health-check"
    }
  )
}

# CloudWatch Alarm for Health Check Failure
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count = var.enable_health_check && var.domain_name != "" && var.sns_topic_arn != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Alert when Route 53 health check fails"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.main[0].id
  }

  tags = var.tags
}
