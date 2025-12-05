# Step 17: ACM SSL/TLS Certificates

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/06-acm`

## Overview

Request and validate SSL/TLS certificates using AWS Certificate Manager (ACM) for secure HTTPS communication with CloudFront, API Gateway, and custom domains.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: Enable HTTPS for CloudFront and API Gateway
- **Certificate Authority**: AWS Certificate Manager (free)
- **Validation**: DNS validation (automated via Route 53)
- **Regions**: us-east-1 (CloudFront), ap-southeast-1 (API Gateway)
- **Cost**: FREE (AWS managed certificates)

## Components to Implement

### 1. CloudFront Certificate (us-east-1)

**Important**: CloudFront requires certificates in us-east-1 region only.

- [ ] **Domain Names**:
  - typerush.example.com
  - www.typerush.example.com
  - \*.typerush.example.com (wildcard - optional)
- [ ] **Validation Method**: DNS validation
- [ ] **Region**: us-east-1 (required for CloudFront)
- [ ] **Key Algorithm**: RSA 2048
- [ ] **Transparency Logging**: Enabled

### 2. API Gateway Certificate (ap-southeast-1) - Optional

Only needed if using custom domain names for API Gateway regional endpoints.

- [ ] **Domain Names**:
  - api.typerush.example.com
  - ws.typerush.example.com
- [ ] **Validation Method**: DNS validation
- [ ] **Region**: ap-southeast-1 (same as API Gateway)
- [ ] **Key Algorithm**: RSA 2048
- [ ] **Note**: Skip if using CloudFront + default API Gateway URLs

### 3. DNS Validation Records

ACM creates CNAME records for validation that must be added to Route 53.

- [ ] **Auto-creation**: Enable if using Route 53 (Terraform can automate)
- [ ] **Manual**: Add CNAME records if using external DNS provider
- [ ] **Validation Time**: 5-30 minutes after DNS records added

### 4. Certificate Renewal

- [ ] **Auto-renewal**: ACM automatically renews before expiration
- [ ] **Notification**: SNS alert 45 days before expiration (if manual validation)
- [ ] **Validation**: Must maintain DNS records for auto-renewal

## Implementation Details

### Terraform Configuration

```hcl
# Provider for us-east-1 (CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# CloudFront Certificate (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}", "*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-cloudfront-cert"
      Environment = var.environment
    }
  )
}

# DNS Validation Records (Auto-created in Route 53)
resource "aws_route53_record" "cloudfront_validation" {
  provider = aws.us_east_1

  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate Validation Wait
resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}

# API Gateway Certificate (ap-southeast-1) - Optional
resource "aws_acm_certificate" "api_gateway" {
  count = var.use_api_custom_domain ? 1 : 0

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
    }
  )
}

# DNS Validation for API Gateway Certificate
resource "aws_route53_record" "api_gateway_validation" {
  count = var.use_api_custom_domain ? 1 : 0

  for_each = {
    for dvo in aws_acm_certificate.api_gateway[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "api_gateway" {
  count = var.use_api_custom_domain ? 1 : 0

  certificate_arn         = aws_acm_certificate.api_gateway[0].arn
  validation_record_fqdns = [for record in aws_route53_record.api_gateway_validation[0] : record.fqdn]

  timeouts {
    create = "30m"
  }
}

# CloudWatch Metric for Certificate Expiry
resource "aws_cloudwatch_metric_alarm" "cert_expiry" {
  provider = aws.us_east_1

  alarm_name          = "${var.project_name}-cert-expiry"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400
  statistic           = "Minimum"
  threshold           = 45
  alarm_description   = "Certificate expires in less than 45 days"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    CertificateArn = aws_acm_certificate.cloudfront.arn
  }

  tags = var.tags
}

# Outputs
output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate (us-east-1)"
  value       = aws_acm_certificate.cloudfront.arn
}

output "cloudfront_certificate_status" {
  description = "Status of the CloudFront certificate"
  value       = aws_acm_certificate.cloudfront.status
}

output "api_gateway_certificate_arn" {
  description = "ARN of the API Gateway certificate (ap-southeast-1)"
  value       = var.use_api_custom_domain ? aws_acm_certificate.api_gateway[0].arn : null
}

output "validation_records" {
  description = "DNS validation records (for manual setup)"
  value = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}
```

### Variables (variables.tf)

```hcl
variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation"
  type        = string
}

variable "use_api_custom_domain" {
  description = "Whether to create API Gateway custom domain certificate"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for certificate expiry alarms"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

## Deployment Steps

### 1. Verify Prerequisites

```powershell
# Verify Route 53 hosted zone exists
terraform state show module.route53.aws_route53_zone.main

# Verify domain name servers are updated
nslookup -type=NS typerush.example.com
```

### 2. Plan ACM Deployment

```powershell
terraform plan -target=module.acm -var-file="env/dev.tfvars.local"
```

### 3. Deploy ACM Certificates

```powershell
terraform apply -target=module.acm -var-file="env/dev.tfvars.local"
```

**Note**: Terraform will:

1. Request certificate from ACM
2. Create DNS validation CNAME records in Route 53
3. Wait for validation (5-30 minutes)
4. Mark certificate as "Issued"

### 4. Verify Certificate Status

```powershell
# Check CloudFront certificate (us-east-1)
aws acm describe-certificate `
  --certificate-arn <cloudfront-cert-arn> `
  --region us-east-1

# Check status
aws acm list-certificates --region us-east-1 `
  --query "CertificateSummaryList[?DomainName=='typerush.example.com']"

# Check validation records
aws route53 list-resource-record-sets `
  --hosted-zone-id <zone-id> `
  --query "ResourceRecordSets[?Type=='CNAME' && contains(Name, '_acm-validations')]"
```

### 5. Test Certificate

```powershell
# After CloudFront deployment, test HTTPS
curl -I https://typerush.example.com/

# Check certificate details
openssl s_client -connect typerush.example.com:443 -servername typerush.example.com
```

## Manual DNS Validation (If Not Using Route 53)

If your domain is managed outside Route 53:

### 1. Get Validation Records

```powershell
$CERT_ARN = terraform output -raw cloudfront_certificate_arn
$VALIDATION_RECORDS = terraform output -json validation_records | ConvertFrom-Json
Write-Output $VALIDATION_RECORDS
```

### 2. Add CNAME Records to Your DNS Provider

Example output:

```
Name: _abc123.typerush.example.com
Type: CNAME
Value: _xyz789.acm-validations.aws.
```

Add these CNAME records to your DNS provider (GoDaddy, Namecheap, etc.).

### 3. Wait for Validation

```powershell
# Check validation status (repeat every 5 minutes)
aws acm describe-certificate `
  --certificate-arn <cert-arn> `
  --region us-east-1 `
  --query "Certificate.Status"
```

## Integration with Other Modules

### Dependencies

1. **Module 16 - Route 53**: Hosted zone for DNS validation
2. **Module 23 - SNS**: Certificate expiry notifications

### Used By

1. **Module 15 - CloudFront**: CloudFront distribution SSL certificate
2. **Module 14 - API Gateway**: (Optional) Custom domain SSL certificate

## Validation Checklist

- [ ] Certificate request is created in ACM
- [ ] DNS validation CNAME records are created
- [ ] Certificate status is "Issued" (not "Pending Validation")
- [ ] Certificate covers all required domains (including wildcard)
- [ ] Certificate is in correct region (us-east-1 for CloudFront)
- [ ] CloudFront can attach the certificate
- [ ] HTTPS works with custom domain
- [ ] Certificate auto-renewal is enabled
- [ ] CloudWatch alarm is set for expiry

## Cost Estimation

### ACM Costs

- **Certificate Issuance**: FREE
- **Certificate Renewal**: FREE (automatic)
- **Unlimited Certificates**: FREE
- **Public Certificates**: FREE
- **Private CA**: Not used (requires AWS Private CA - $400/month)

**Total: $0.00** - ACM public certificates are completely free!

## Troubleshooting

### Issue: Certificate stuck in "Pending Validation"

```powershell
# Check DNS validation records exist
aws route53 list-resource-record-sets `
  --hosted-zone-id <zone-id> `
  --query "ResourceRecordSets[?Type=='CNAME']"

# Verify CNAME record resolves
nslookup -type=CNAME _abc123.typerush.example.com

# Check certificate validation options
aws acm describe-certificate `
  --certificate-arn <cert-arn> `
  --region us-east-1 `
  --query "Certificate.DomainValidationOptions"
```

### Issue: CloudFront can't find certificate

```powershell
# Verify certificate is in us-east-1
aws acm list-certificates --region us-east-1

# Verify certificate status is "ISSUED"
aws acm describe-certificate --certificate-arn <cert-arn> --region us-east-1

# Check certificate domain names match CloudFront aliases
aws cloudfront get-distribution-config --id <distribution-id>
```

### Issue: Certificate validation fails after 72 hours

```powershell
# ACM times out after 72 hours
# Delete and recreate certificate
terraform destroy -target=module.acm.aws_acm_certificate.cloudfront
terraform apply -target=module.acm

# Verify DNS records are correct
# May need to wait for DNS propagation (24-48 hours)
```

### Issue: Wildcard certificate not covering subdomains

```powershell
# Wildcard *.example.com covers:
#   ✅ api.example.com
#   ✅ www.example.com
# Wildcard does NOT cover:
#   ❌ example.com (root domain - add explicitly)
#   ❌ sub.api.example.com (nested subdomains)

# Solution: Include both in subject_alternative_names
# - example.com
# - *.example.com
```

## References

- [ACM Documentation](https://docs.aws.amazon.com/acm/)
- [DNS Validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [CloudFront Certificate Requirements](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html)
- [Certificate Renewal](https://docs.aws.amazon.com/acm/latest/userguide/managed-renewal.html)

## Next Steps

After certificates are issued:

1. Attach CloudFront certificate to distribution (Step 15)
2. Update CloudFront alternate domain names (aliases)
3. Test HTTPS with custom domain
4. (Optional) Create API Gateway custom domains with certificate
5. Monitor certificate expiry via CloudWatch alarm
6. Verify auto-renewal is working (check 60 days before expiry)

## Important Notes

- **Region Requirement**: CloudFront certificates MUST be in us-east-1
- **DNS Validation**: Recommended over email validation (automatic)
- **Auto-Renewal**: ACM handles renewal automatically (no action needed)
- **Wildcard Limitations**: `*.example.com` doesn't cover `example.com` (add both)
- **Validation Records**: Keep DNS validation records permanently for auto-renewal
- **Free Service**: ACM public certificates are completely free
- **Certificate Transparency**: All certificates are logged publicly (can't be disabled)
- **Multiple Domains**: Can add up to 100 domain names to one certificate
