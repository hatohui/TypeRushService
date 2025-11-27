# ==================================
# CloudFront Distribution Module
# ==================================

# Origin Access Control for S3 (replaces legacy OAI)
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for ${var.project_name} S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = var.price_class
  default_root_object = "index.html"
  comment             = "${var.project_name} ${var.environment} CDN"
  aliases             = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : []

  # Origin 1: S3 Frontend Bucket
  origin {
    origin_id                = "S3-frontend"
    domain_name              = var.s3_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Origin 2: API Gateway HTTP API (optional)
  dynamic "origin" {
    for_each = var.api_gateway_domain_name != "" ? [1] : []

    content {
      origin_id   = "API-Gateway"
      domain_name = var.api_gateway_domain_name
      origin_path = var.api_gateway_stage != "" ? "/${var.api_gateway_stage}" : ""

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      # Optional custom header for additional security
      dynamic "custom_header" {
        for_each = var.api_custom_header_value != "" ? [1] : []

        content {
          name  = "X-Origin-Verify"
          value = var.api_custom_header_value
        }
      }
    }
  }

  # Default Cache Behavior (Frontend Static Assets - S3)
  default_cache_behavior {
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Use AWS managed cache policy for static content
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    # Response headers policy for security headers
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  # Ordered Cache Behavior: API Routes (if API Gateway is configured)
  dynamic "ordered_cache_behavior" {
    for_each = var.api_gateway_domain_name != "" ? [1] : []

    content {
      path_pattern           = "/api/*"
      target_origin_id       = "API-Gateway"
      viewer_protocol_policy = "https-only"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true

      # Disable caching for API requests (or use minimal caching)
      cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id

      # Forward all viewer headers, cookies, and query strings
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    }
  }

  # Custom Error Response for SPA routing (403, 404 → index.html)
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # SSL/TLS Certificate Configuration
  viewer_certificate {
    # Use ACM certificate if domain is configured
    cloudfront_default_certificate = var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Geographic Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # WAF Web ACL Association (if WAF is enabled)
  web_acl_id = var.waf_web_acl_arn

  tags = var.tags

  depends_on = [
    aws_cloudfront_origin_access_control.s3
  ]
}

# Response Headers Policy for Security Headers
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${var.project_name}-${var.environment}-security-headers"
  comment = "Security headers for ${var.project_name}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }

  # CORS configuration for frontend
  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }

    access_control_allow_origins {
      items = var.cors_allowed_origins
    }

    access_control_max_age_sec = 3600
    origin_override            = false
  }
}

# Data sources for AWS managed policies
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}
