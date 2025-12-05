# ==================================
# ACM Module Outputs
# ==================================

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate (us-east-1)"
  value       = var.domain_name != "" ? aws_acm_certificate.cloudfront[0].arn : ""
}

output "cloudfront_certificate_status" {
  description = "Status of the CloudFront certificate"
  value       = var.domain_name != "" ? aws_acm_certificate.cloudfront[0].status : "Not Created"
}

output "cloudfront_certificate_domain" {
  description = "Domain name of the CloudFront certificate"
  value       = var.domain_name != "" ? aws_acm_certificate.cloudfront[0].domain_name : ""
}

output "api_gateway_certificate_arn" {
  description = "ARN of the API Gateway certificate (ap-southeast-1)"
  value       = var.use_api_custom_domain && var.domain_name != "" ? aws_acm_certificate.api_gateway[0].arn : ""
}

output "api_gateway_certificate_status" {
  description = "Status of the API Gateway certificate"
  value       = var.use_api_custom_domain && var.domain_name != "" ? aws_acm_certificate.api_gateway[0].status : "Not Created"
}

output "validation_records" {
  description = "DNS validation records (for manual setup if Route 53 is not used)"
  value = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}
