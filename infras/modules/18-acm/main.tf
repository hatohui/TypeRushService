# ==================================
# ACM Certificate Module
# ==================================

# CloudFront Certificate (us-east-1 region is REQUIRED for CloudFront)
resource "aws_acm_certificate" "cloudfront" {
  count    = var.domain_name != "" ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-cloudfront-cert"
      Environment = var.environment
      Region      = "us-east-1"
    }
  )
}

# DNS Validation Records for CloudFront Certificate
# Only create if Route 53 zone is provided
resource "aws_route53_record" "cloudfront_validation" {
  for_each = var.domain_name != "" && var.route53_zone_id != "" ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  provider = aws.us_east_1

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "cloudfront" {
  count    = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}

# API Gateway Certificate (ap-southeast-1) - Optional for custom API domains
resource "aws_acm_certificate" "api_gateway" {
  count = var.use_api_custom_domain && var.domain_name != "" ? 1 : 0

  domain_name               = "api.${var.domain_name}"
  subject_alternative_names = ["ws.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-cert"
      Environment = var.environment
      Region      = "ap-southeast-1"
    }
  )
}

# DNS Validation for API Gateway Certificate
resource "aws_route53_record" "api_gateway_validation" {
  for_each = var.use_api_custom_domain && var.domain_name != "" && var.route53_zone_id != "" ? {
    for dvo in aws_acm_certificate.api_gateway[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Wait for API Gateway certificate validation
resource "aws_acm_certificate_validation" "api_gateway" {
  count = var.use_api_custom_domain && var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.api_gateway[0].arn
  validation_record_fqdns = [for record in aws_route53_record.api_gateway_validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}

# CloudWatch Metric Alarm for Certificate Expiry (optional SNS topic)
resource "aws_cloudwatch_metric_alarm" "cert_expiry" {
  count    = var.domain_name != "" && var.enable_cert_expiry_alarm && var.sns_topic_arn != "" ? 1 : 0
  provider = aws.us_east_1

  alarm_name          = "${var.project_name}-${var.environment}-cert-expiry"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400 # 1 day
  statistic           = "Minimum"
  threshold           = 45
  alarm_description   = "Certificate expires in less than 45 days"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    CertificateArn = aws_acm_certificate.cloudfront[0].arn
  }

  tags = var.tags
}
