# Step 15: CloudFront and AWS WAF

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/07-cloudfront` and `modules/08-waf`

## Overview

Create Amazon CloudFront CDN distribution to serve static frontend assets and cache API responses, with AWS WAF for DDoS protection, rate limiting, and security rules.

## Architecture Reference

From `architecture-diagram.md`:

- **CloudFront**: Global CDN for frontend (S3) and API caching
- **AWS WAF**: Rate limiting, IP filtering, bot protection
- **Origins**: S3 bucket (static files) + API Gateway (APIs)
- **Cost**: ~$2-5/month (minimal dev traffic + WAF rules)
- **SSL**: ACM certificate (free) for custom domain

## Components to Implement

### 1. CloudFront Distribution

- [ ] **Distribution Name**: typerush-dev-cdn
- [ ] **Price Class**: PriceClass_100 (US, Canada, Europe - cheapest)
- [ ] **HTTP Version**: HTTP/2 and HTTP/3 enabled
- [ ] **IPv6**: Enabled
- [ ] **Default Root Object**: index.html
- [ ] **Comment**: TypeRush Dev CDN Distribution

#### Origins

##### Origin 1: S3 Frontend Bucket

- [ ] **Origin ID**: S3-typerush-frontend
- [ ] **Domain Name**: typerush-dev-frontend.s3.ap-southeast-1.amazonaws.com
- [ ] **Origin Access**: Origin Access Control (OAC) - recommended
- [ ] **Origin Protocol Policy**: HTTPS only
- [ ] **Origin Shield**: Disabled (dev cost optimization)

##### Origin 2: API Gateway HTTP API

- [ ] **Origin ID**: API-Gateway-HTTP
- [ ] **Domain Name**: <api-id>.execute-api.ap-southeast-1.amazonaws.com
- [ ] **Origin Path**: /dev
- [ ] **Origin Protocol Policy**: HTTPS only
- [ ] **Custom Headers**:
  - `x-api-key`: <random-value> (protect API Gateway from direct access)

##### Origin 3: API Gateway WebSocket (Optional)

- [ ] **Note**: WebSocket connections bypass CloudFront, access API Gateway directly
- [ ] **Reason**: CloudFront doesn't support WebSocket forwarding

### 2. Cache Behaviors

#### Default Behavior (Frontend Assets - S3)

- [ ] **Path Pattern**: Default (\*)
- [ ] **Origin**: S3-typerush-frontend
- [ ] **Viewer Protocol Policy**: Redirect HTTP to HTTPS
- [ ] **Allowed HTTP Methods**: GET, HEAD, OPTIONS
- [ ] **Cached HTTP Methods**: GET, HEAD
- [ ] **Compress Objects**: Yes (Gzip/Brotli)
- [ ] **Cache Policy**: CachingOptimized (AWS managed)
- [ ] **TTL**:
  - Min: 0
  - Default: 86400 (1 day)
  - Max: 31536000 (1 year)
- [ ] **Query Strings**: None (static assets)
- [ ] **Cookies**: None

#### Behavior 2: API Routes

- [ ] **Path Pattern**: /api/\*
- [ ] **Origin**: API-Gateway-HTTP
- [ ] **Viewer Protocol Policy**: HTTPS only
- [ ] **Allowed HTTP Methods**: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
- [ ] **Cached HTTP Methods**: GET, HEAD
- [ ] **Compress Objects**: Yes
- [ ] **Cache Policy**: CachingDisabled (AWS managed) or custom
- [ ] **Origin Request Policy**: AllViewer (forward all headers, cookies, query strings)
- [ ] **Forward Headers**:
  - Authorization
  - Content-Type
  - x-api-key
- [ ] **Query Strings**: All
- [ ] **Cookies**: All

### 3. Error Pages

- [ ] **403 Forbidden**: Redirect to /index.html (SPA routing)
- [ ] **404 Not Found**: Redirect to /index.html (SPA routing)
- [ ] **Response Code**: 200
- [ ] **TTL**: 300 seconds

### 4. SSL/TLS Certificate

- [ ] **Certificate**: ACM certificate (from Step 17)
- [ ] **Domain**: typerush.example.com, www.typerush.example.com
- [ ] **Minimum TLS Version**: TLSv1.2_2021
- [ ] **Security Policy**: TLSv1.2_2021 (recommended)

### 5. AWS WAF Web ACL

- [ ] **Web ACL Name**: typerush-dev-waf
- [ ] **Resource Type**: CloudFront
- [ ] **Scope**: CloudFront (global)
- [ ] **Default Action**: Allow
- [ ] **CloudWatch Metrics**: Enabled

#### WAF Rules

##### Rule 1: AWS Managed - Core Rule Set

- [ ] **Priority**: 1
- [ ] **Rule Type**: AWS Managed Rules
- [ ] **Rule Group**: AWSManagedRulesCommonRuleSet
- [ ] **Action**: Block
- [ ] **Purpose**: Protect against OWASP Top 10 vulnerabilities

##### Rule 2: AWS Managed - Known Bad Inputs

- [ ] **Priority**: 2
- [ ] **Rule Type**: AWS Managed Rules
- [ ] **Rule Group**: AWSManagedRulesKnownBadInputsRuleSet
- [ ] **Action**: Block
- [ ] **Purpose**: Block malformed requests

##### Rule 3: Rate Limiting (General)

- [ ] **Priority**: 3
- [ ] **Rule Type**: Rate-based rule
- [ ] **Rate Limit**: 2000 requests per 5 minutes (per IP)
- [ ] **Action**: Block
- [ ] **Scope**: All requests
- [ ] **Aggregate Key**: IP address

##### Rule 4: Rate Limiting (API Endpoints)

- [ ] **Priority**: 4
- [ ] **Rule Type**: Rate-based rule
- [ ] **Rate Limit**: 500 requests per 5 minutes (per IP)
- [ ] **Action**: Block
- [ ] **Scope**: URI path starts with `/api/`
- [ ] **Aggregate Key**: IP address

##### Rule 5: Geo Blocking (Optional)

- [ ] **Priority**: 5
- [ ] **Rule Type**: Geo match rule
- [ ] **Countries**: CN, RU (example - block if needed)
- [ ] **Action**: Block
- [ ] **Purpose**: Block specific countries if under attack
- [ ] **Note**: Disabled by default for dev

##### Rule 6: IP Reputation List (AWS Managed)

- [ ] **Priority**: 6
- [ ] **Rule Type**: AWS Managed Rules
- [ ] **Rule Group**: AWSManagedRulesAmazonIpReputationList
- [ ] **Action**: Block
- [ ] **Purpose**: Block known malicious IPs

### 6. Logging and Monitoring

- [ ] **Standard Logs**: Disabled (dev, save S3 costs)
- [ ] **Real-time Logs**: Disabled
- [ ] **WAF Logging**: Enabled, sent to CloudWatch Logs
- [ ] **Log Group**: /aws/waf/typerush-dev
- [ ] **Retention**: 7 days

## Implementation Details

### Terraform Configuration

#### CloudFront Distribution

```hcl
# Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-s3-oac"
  description                       = "OAC for S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  comment             = "TypeRush ${var.environment} CDN"

  # Origin 1: S3 Frontend
  origin {
    origin_id                = "S3-frontend"
    domain_name              = var.s3_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Origin 2: API Gateway HTTP API
  origin {
    origin_id   = "API-Gateway"
    domain_name = replace(var.api_gateway_endpoint, "https://", "")
    origin_path = "/dev"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-api-key"
      value = var.api_gateway_custom_header_value
    }
  }

  # Default Cache Behavior (Frontend)
  default_cache_behavior {
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_router.arn
    }
  }

  # API Cache Behavior
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "API-Gateway"
    viewer_protocol_policy = "https-only"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  # Custom Error Response for SPA routing
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 0
  }

  # SSL Certificate
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Custom Domain
  aliases = var.domain_names

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # WAF Association
  web_acl_id = aws_wafv2_web_acl.main.arn

  tags = var.tags
}

# CloudFront Function for SPA Routing
resource "aws_cloudfront_function" "spa_router" {
  name    = "${var.project_name}-spa-router"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite requests for SPA routing"
  publish = true
  code    = file("${path.module}/functions/spa-router.js")
}

# Data sources for managed policies
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}
```

#### AWS WAF Web ACL

```hcl
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf"
  scope       = "CLOUDFRONT"
  description = "WAF for TypeRush ${var.environment}"

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Rate Limiting - General
  rule {
    name     = "RateLimitGeneral"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitGeneralMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Rate Limiting - API Endpoints
  rule {
    name     = "RateLimitAPI"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string = "/api/"
            positional_constraint = "STARTS_WITH"

            field_to_match {
              uri_path {}
            }

            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitAPIMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: IP Reputation List
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSIPReputationListMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "TypeRushWAFMetric"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# WAF Logging
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/waf/${var.project_name}"
  retention_in_days = 7

  tags = var.tags
}

# Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}
```

#### SPA Router Function (functions/spa-router.js)

```javascript
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // Check if URI has a file extension
  if (!uri.includes(".")) {
    // No extension, assume SPA route
    request.uri = "/index.html";
  }

  return request;
}
```

## Deployment Steps

### 1. Verify Prerequisites

```powershell
# Check S3 bucket exists
terraform state show module.s3.aws_s3_bucket.frontend

# Check API Gateway exists
terraform state show module.api_gateway.aws_apigatewayv2_api.http

# Check ACM certificate is issued
aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='typerush.example.com']"
```

### 2. Plan CloudFront and WAF Deployment

```powershell
terraform plan -target=module.cloudfront -var-file="env/dev.tfvars.local"
```

### 3. Deploy CloudFront and WAF

```powershell
terraform apply -target=module.cloudfront -var-file="env/dev.tfvars.local"
```

**Note**: CloudFront distribution takes 10-20 minutes to deploy globally.

### 4. Update S3 Bucket Policy for OAC

```powershell
# CloudFront OAC requires S3 bucket policy update
# This should be done automatically by Terraform
aws s3api get-bucket-policy --bucket typerush-dev-frontend
```

### 5. Test CloudFront Distribution

```powershell
# Get CloudFront domain
$CF_DOMAIN = terraform output -raw cloudfront_domain_name

# Test frontend
curl https://$CF_DOMAIN/

# Test API
curl https://$CF_DOMAIN/api/game/health
```

### 6. Invalidate Cache (When Needed)

```powershell
aws cloudfront create-invalidation `
  --distribution-id <distribution-id> `
  --paths "/*"
```

## Integration with Other Modules

### Dependencies

1. **Module 14 - API Gateway**: HTTP API endpoint as origin
2. **Module 17 - ACM**: SSL certificate for custom domain
3. **Module 19 - S3**: Frontend bucket as origin
4. **Module 21 - CloudWatch**: WAF logs destination

### Used By

1. **Module 16 - Route 53**: CNAME/Alias record pointing to CloudFront
2. **Module 21 - CI/CD**: Invalidate CloudFront cache after deployments

## Validation Checklist

- [ ] CloudFront distribution is deployed and enabled
- [ ] S3 origin has OAC configured correctly
- [ ] API Gateway origin has custom header for protection
- [ ] SSL certificate is valid and attached
- [ ] WAF Web ACL is associated with distribution
- [ ] Rate limiting rules are active
- [ ] Managed rule groups are enabled
- [ ] CloudFront domain resolves and serves content
- [ ] API routes work through CloudFront
- [ ] SPA routing (404 → index.html) works
- [ ] WAF logs are being written to CloudWatch

## Cost Estimation

### CloudFront Costs (per month, dev usage)

- **Data Transfer Out**:
  - First 10 TB: $0.085/GB
  - Estimated 10 GB: **$0.85**
- **HTTP/HTTPS Requests**:
  - Per 10,000 requests: $0.0075
  - Estimated 100K requests: **$0.75**
- **Invalidations**: First 1,000/month free, then $0.005/path
- **Total CloudFront**: **~$1.60/month**

### AWS WAF Costs (per month)

- **Web ACL**: $5.00/month
- **Rules**: $1.00/rule/month × 5 rules = $5.00
- **Requests**: $0.60/million requests
  - Estimated 100K requests: **$0.06**
- **Total WAF**: **~$10.06/month**

### Combined Total

- **Total**: **~$11.66/month**

### Cost Optimization

- Use PriceClass_100 (cheapest regions)
- Disable standard logging in dev
- Use managed cache policies (no custom)
- Limit WAF rules to essentials

## Troubleshooting

### Issue: CloudFront shows "Access Denied" for S3

```powershell
# Check S3 bucket policy allows CloudFront OAC
aws s3api get-bucket-policy --bucket typerush-dev-frontend

# Verify OAC is attached to origin
aws cloudfront get-distribution --id <distribution-id>
```

### Issue: API Gateway returns 403 through CloudFront

```powershell
# Check custom header is forwarded
# Verify API Gateway resource policy allows CloudFront
aws apigatewayv2 get-api --api-id <api-id>
```

### Issue: WAF blocks legitimate traffic

```powershell
# Check WAF sampled requests
aws wafv2 get-sampled-requests `
  --web-acl-arn <web-acl-arn> `
  --scope CLOUDFRONT `
  --time-window StartTime=<unix-timestamp>,EndTime=<unix-timestamp> `
  --max-items 100

# Review CloudWatch Logs
aws logs tail /aws/waf/typerush-dev --follow
```

### Issue: SPA routes return 404

```powershell
# Check CloudFront function is attached
aws cloudfront get-distribution-config --id <distribution-id>

# Verify custom error responses
# Should redirect 403/404 to /index.html
```

## References

- [CloudFront Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [CloudFront Functions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/)
- [Rate Limiting Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/WAF-one-click-rate-limiting.html)
- [Origin Access Control (OAC)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)

## Next Steps

After deploying CloudFront and WAF:

1. Create Route 53 DNS records pointing to CloudFront (Step 16)
2. Test end-to-end with custom domain
3. Monitor WAF metrics in CloudWatch
4. Adjust rate limits based on traffic patterns
5. Configure CI/CD to invalidate cache on deployments (Step 21)
