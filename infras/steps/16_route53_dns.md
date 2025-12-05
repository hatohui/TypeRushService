# Step 16: Route 53 DNS Configuration

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/05-route53`

## Overview

Configure Amazon Route 53 for DNS management, creating hosted zones and DNS records to route traffic to CloudFront distribution and API Gateway endpoints.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: DNS resolution for custom domains
- **Hosted Zone**: typerush.example.com
- **Records**: CloudFront (A/AAAA Alias), API subdomains
- **Cost**: $0.50/hosted zone/month + $0.40/million queries
- **Note**: Optional for dev (can use CloudFront/API Gateway default URLs)

## Components to Implement

### 1. Hosted Zone

- [ ] **Domain Name**: typerush.example.com (replace with your domain)
- [ ] **Type**: Public hosted zone
- [ ] **Name Servers**: AWS-provided (4 NS records)
- [ ] **SOA Record**: Auto-generated
- [ ] **Cost**: $0.50/month

### 2. DNS Records

#### A Record (IPv4) - CloudFront Alias

- [ ] **Name**: typerush.example.com
- [ ] **Type**: A (IPv4 address)
- [ ] **Alias**: Yes
- [ ] **Alias Target**: CloudFront distribution domain name
- [ ] **Routing Policy**: Simple
- [ ] **Evaluate Target Health**: No

#### AAAA Record (IPv6) - CloudFront Alias

- [ ] **Name**: typerush.example.com
- [ ] **Type**: AAAA (IPv6 address)
- [ ] **Alias**: Yes
- [ ] **Alias Target**: CloudFront distribution domain name
- [ ] **Routing Policy**: Simple
- [ ] **Evaluate Target Health**: No

#### CNAME Record - www Subdomain

- [ ] **Name**: www.typerush.example.com
- [ ] **Type**: CNAME
- [ ] **Value**: typerush.example.com
- [ ] **TTL**: 300 seconds

#### CNAME Record - API Subdomain (Optional)

- [ ] **Name**: api.typerush.example.com
- [ ] **Type**: CNAME
- [ ] **Value**: API Gateway custom domain name
- [ ] **TTL**: 300 seconds
- [ ] **Note**: Only if using API Gateway custom domain

#### CNAME Record - WebSocket Subdomain (Optional)

- [ ] **Name**: ws.typerush.example.com
- [ ] **Type**: CNAME
- [ ] **Value**: WebSocket API Gateway domain
- [ ] **TTL**: 300 seconds

### 3. Health Checks (Optional - Production)

- [ ] **Endpoint**: https://typerush.example.com/health
- [ ] **Protocol**: HTTPS
- [ ] **Port**: 443
- [ ] **Path**: /api/game/health
- [ ] **Interval**: 30 seconds
- [ ] **Failure Threshold**: 3
- [ ] **Alarm**: SNS notification on failure

### 4. Traffic Policies (Optional - Advanced)

- [ ] **Geolocation Routing**: Route users to nearest region
- [ ] **Latency Routing**: Route to lowest latency endpoint
- [ ] **Failover**: Primary/secondary endpoints
- [ ] **Note**: Not needed for single-region dev setup

## Implementation Details

### Terraform Configuration

```hcl
# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Hosted zone for ${var.project_name} ${var.environment}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-hosted-zone"
    }
  )
}

# A Record - CloudFront (IPv4)
resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA Record - CloudFront (IPv6)
resource "aws_route53_record" "root_aaaa" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# CNAME Record - www subdomain
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}

# CNAME Record - API subdomain (if custom domain used)
resource "aws_route53_record" "api" {
  count   = var.use_api_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.api_gateway_custom_domain]
}

# Health Check (optional)
resource "aws_route53_health_check" "main" {
  count             = var.enable_health_check ? 1 : 0
  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/api/game/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-health-check"
    }
  )
}

# CloudWatch Alarm for Health Check
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = var.enable_health_check ? 1 : 0
  alarm_name          = "${var.project_name}-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Alert when health check fails"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.main[0].id
  }

  tags = var.tags
}

# Outputs
output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}
```

### Variables (variables.tf)

```hcl
variable "domain_name" {
  description = "Primary domain name (e.g., typerush.example.com)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "use_api_custom_domain" {
  description = "Whether to create API subdomain"
  type        = bool
  default     = false
}

variable "api_gateway_custom_domain" {
  description = "API Gateway custom domain name"
  type        = string
  default     = ""
}

variable "enable_health_check" {
  description = "Enable Route 53 health checks"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for health check alarms"
  type        = string
  default     = ""
}
```

## Deployment Steps

### 1. Domain Prerequisites

**Option A: Using Existing Domain**

```powershell
# If you own a domain registered elsewhere (e.g., GoDaddy, Namecheap):
# 1. Note your current name servers
# 2. Prepare to update them after Route 53 deployment
```

**Option B: Register Domain in Route 53**

```powershell
# Register a new domain (costs $12-$15/year)
aws route53domains register-domain `
  --domain-name typerush.example.com `
  --duration-in-years 1 `
  --admin-contact file://contact.json `
  --registrant-contact file://contact.json `
  --tech-contact file://contact.json `
  --auto-renew
```

### 2. Plan Route 53 Deployment

```powershell
terraform plan -target=module.route53 -var-file="env/dev.tfvars.local"
```

### 3. Deploy Route 53

```powershell
terraform apply -target=module.route53 -var-file="env/dev.tfvars.local"
```

### 4. Get Name Servers

```powershell
# Get the name servers AWS assigned
$NAME_SERVERS = terraform output -json name_servers | ConvertFrom-Json
Write-Output $NAME_SERVERS
```

### 5. Update Domain Registrar

**If domain is registered outside AWS:**

1. Log into your domain registrar (GoDaddy, Namecheap, etc.)
2. Find DNS management or name server settings
3. Replace existing name servers with AWS name servers from step 4
4. Save changes (propagation takes 24-48 hours)

### 6. Verify DNS Propagation

```powershell
# Check DNS resolution (may take up to 48 hours)
nslookup typerush.example.com

# Check with specific name server
nslookup typerush.example.com <aws-name-server>

# Check A record
Resolve-DnsName -Name typerush.example.com -Type A

# Check AAAA record (IPv6)
Resolve-DnsName -Name typerush.example.com -Type AAAA
```

### 7. Test Custom Domain

```powershell
# Test frontend
curl https://typerush.example.com/

# Test API
curl https://typerush.example.com/api/game/health

# Test www redirect
curl https://www.typerush.example.com/
```

## Integration with Other Modules

### Dependencies

1. **Module 15 - CloudFront**: CloudFront distribution domain name
2. **Module 14 - API Gateway**: (Optional) Custom domain name
3. **Module 17 - ACM**: SSL certificate must be issued for domain
4. **Module 23 - SNS**: (Optional) Health check alarm notifications

### Used By

1. **Module 17 - ACM**: Domain validation via DNS records
2. **Module 18 - Cognito**: Callback URLs use custom domain

## Validation Checklist

- [ ] Hosted zone is created successfully
- [ ] Name servers are obtained from AWS
- [ ] Name servers are updated in domain registrar
- [ ] DNS propagation is complete (nslookup works)
- [ ] A record resolves to CloudFront
- [ ] AAAA record resolves to CloudFront (IPv6)
- [ ] www subdomain redirects to root domain
- [ ] SSL certificate is valid for custom domain
- [ ] Custom domain loads frontend correctly
- [ ] API endpoints work via custom domain

## Cost Estimation

### Route 53 Costs (per month)

- **Hosted Zone**: $0.50/hosted zone
- **DNS Queries**: $0.40/million queries
  - Estimated 100K queries: **$0.04**
- **Health Checks**: $0.50/endpoint (if enabled)
- **Total**: **~$0.54-1.04/month**

### Domain Registration (annual)

- **Generic TLD (.com, .net)**: $12-15/year
- **Premium TLD**: Varies

### Cost Optimization

- Skip Route 53 for dev (use default URLs)
- Disable health checks in dev
- Use simple routing (no geolocation/latency)

## Troubleshooting

### Issue: DNS not resolving after 48 hours

```powershell
# Check name servers at registrar match AWS
nslookup -type=NS typerush.example.com

# Verify hosted zone name servers
aws route53 get-hosted-zone --id <hosted-zone-id>

# Check DNS propagation status
# Use online tools: https://dnschecker.org
```

### Issue: SSL certificate invalid for custom domain

```powershell
# Verify certificate covers all domains
aws acm describe-certificate --certificate-arn <cert-arn> --region us-east-1

# Check CloudFront alternate domain names (aliases)
aws cloudfront get-distribution-config --id <distribution-id>
```

### Issue: CloudFront returns "Bad Request" with custom domain

```powershell
# Verify CloudFront has correct alternate domain names
# Verify ACM certificate is attached
# Check certificate status is "Issued"
aws acm list-certificates --region us-east-1
```

### Issue: Health check failing

```powershell
# Test health check endpoint manually
curl -I https://typerush.example.com/api/game/health

# Check Route 53 health check status
aws route53 get-health-check-status --health-check-id <health-check-id>

# Review CloudWatch metrics
aws cloudwatch get-metric-statistics `
  --namespace AWS/Route53 `
  --metric-name HealthCheckStatus `
  --dimensions Name=HealthCheckId,Value=<health-check-id> `
  --start-time 2024-01-01T00:00:00Z `
  --end-time 2024-01-02T00:00:00Z `
  --period 300 `
  --statistics Minimum
```

## References

- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [DNS Record Types](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ResourceRecordTypes.html)
- [CloudFront Alias Records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-cloudfront-distribution.html)
- [Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)
- [Domain Registration](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)

## Next Steps

After configuring Route 53:

1. Verify DNS propagation is complete
2. Test all subdomains (www, api, ws)
3. Update Cognito callback URLs to use custom domain
4. Update CORS origins in API Gateway
5. Monitor DNS query patterns in CloudWatch
6. Consider registering additional domains (.net, .io) for protection

## Important Notes

- **DNS Propagation**: Can take 24-48 hours worldwide
- **Name Server Update**: Critical - must match AWS exactly
- **ACM Certificate**: Must be in us-east-1 for CloudFront
- **Domain Validation**: ACM requires DNS or email validation
- **WWW vs Non-WWW**: Choose one as primary, redirect the other
- **Dev Environment**: Consider skipping Route 53 and using default URLs to save $0.50/month
