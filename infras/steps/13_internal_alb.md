# Step 13: Internal Application Load Balancer

## Status: IMPLEMENTED (Not Applied)

**Implemented on**: November 23, 2025  
**Applied to AWS**: Not yet - waiting for full stack implementation

**Note**: This module has been coded and validated in Terraform but NOT yet applied to AWS infrastructure. All modules will be applied together.

## Terraform Module: `modules/12-alb`

## Overview

Create an internal Application Load Balancer (ALB) to route traffic from API Gateway (via VPC Link) to ECS Game Service. The ALB provides health checking, connection draining, and Layer 7 load balancing.

## Architecture Reference

From `architecture-diagram.md`:

- **Type**: Internal ALB (not internet-facing)
- **Access**: Via VPC Link from API Gateway only
- **Target**: ECS Game Service (port 3000)
- **Health Check**: `/health` endpoint
- **Cost**: $16.20/month (~$0.0225/hour + LCU charges)
- **Network**: Private subnet only

## Components to Implement

### 1. Target Group

- [ ] **Target Group Name**: `typerush-dev-game-service-tg`
- [ ] **Target Type**: IP (required for Fargate)
- [ ] **Protocol**: HTTP
- [ ] **Port**: 3000
- [ ] **VPC**: typerush-dev-vpc
- [ ] **IP Address Type**: IPv4
- [ ] **Protocol Version**: HTTP1

#### Health Check Configuration

- [ ] **Path**: `/health`
- [ ] **Protocol**: HTTP
- [ ] **Port**: traffic-port (3000)
- [ ] **Healthy Threshold**: 2 consecutive successes
- [ ] **Unhealthy Threshold**: 3 consecutive failures
- [ ] **Timeout**: 5 seconds
- [ ] **Interval**: 30 seconds
- [ ] **Success Codes**: 200
- [ ] **Matcher**: `200`

#### Advanced Settings

- [ ] **Deregistration Delay**: 30 seconds
- [ ] **Slow Start**: 0 seconds (disabled)
- [ ] **Stickiness**: Disabled (stateless service, session in Redis)
- [ ] **Load Balancing Algorithm**: round_robin

### 2. Application Load Balancer

- [ ] **ALB Name**: `typerush-dev-internal-alb`
- [ ] **Scheme**: internal (not internet-facing)
- [ ] **IP Address Type**: ipv4
- [ ] **Subnets**: Private subnet (single AZ for dev)
- [ ] **Security Groups**: ALB security group (from Module 02)
- [ ] **Drop Invalid Headers**: true
- [ ] **Enable Deletion Protection**: false (dev environment)
- [ ] **Enable HTTP/2**: true
- [ ] **Enable Cross-Zone Load Balancing**: false (single AZ)
- [ ] **Idle Timeout**: 60 seconds

### 3. Listener Configuration

#### HTTP Listener (Port 80)

- [ ] **Port**: 80
- [ ] **Protocol**: HTTP
- [ ] **Default Action**: Forward to Game Service target group
- [ ] **Rules**: None (single service for now)

**Note**: No HTTPS listener needed (internal-only, API Gateway handles TLS termination)

### 4. Listener Rules (Optional - Future)

- [ ] **Priority**: 1
- [ ] **Condition**: Path pattern = `/api/game/*`
- [ ] **Action**: Forward to game-service-tg
- [ ] **Note**: Can add more services later with path-based routing

### 5. Access Logs (Optional - Dev)

- [ ] **Enabled**: false (to save S3 costs in dev)
- [ ] **Production**: Store in S3 bucket with 7-day lifecycle

### 6. CloudWatch Alarms

- [ ] **TargetUnhealthyHostCount**: Alarm if > 0 for 2 minutes
- [ ] **TargetResponseTime**: Alarm if p99 > 2 seconds
- [ ] **HTTPCode_Target_5XX_Count**: Alarm if sum > 10 in 5 minutes

## Implementation Details

### Terraform Configuration

```hcl
# Target Group for Game Service
resource "aws_lb_target_group" "game_service" {
  name                 = "${var.project_name}-game-service-tg"
  port                 = 3000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-game-service-tg"
      Service = "game-service"
    }
  )
}

# Internal Application Load Balancer
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false
  enable_http2               = true
  drop_invalid_header_fields = true
  idle_timeout               = 60

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-internal-alb"
    }
  )
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.game_service.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-http-listener"
    }
  )
}

# CloudWatch Alarm - Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when ALB has unhealthy targets"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
    TargetGroup  = aws_lb_target_group.game_service.arn_suffix
  }

  tags = var.tags
}

# CloudWatch Alarm - High Response Time
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2.0
  alarm_description   = "Alert when ALB target response time exceeds 2 seconds"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
    TargetGroup  = aws_lb_target_group.game_service.arn_suffix
  }

  tags = var.tags
}

# Outputs
output "alb_arn" {
  description = "ARN of the internal ALB"
  value       = aws_lb.internal.arn
}

output "alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.internal.dns_name
}

output "target_group_arn" {
  description = "ARN of the Game Service target group"
  value       = aws_lb_target_group.game_service.arn
}

output "listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}
```

### Variables (variables.tf)

```hcl
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

## Deployment Steps

### 1. Verify Prerequisites

```powershell
# Check if VPC and subnets exist
terraform state show module.networking.aws_vpc.main
terraform state show module.networking.aws_subnet.private

# Check if security groups exist
terraform state show module.security_groups.aws_security_group.alb
```

### 2. Plan ALB Deployment

```powershell
terraform plan -target=module.alb -var-file="env/dev.tfvars.local"
```

### 3. Deploy ALB

```powershell
terraform apply -target=module.alb -var-file="env/dev.tfvars.local"
```

### 4. Verify Deployment

```powershell
# Get ALB details
aws elbv2 describe-load-balancers --names typerush-dev-internal-alb --region ap-southeast-1

# Get target group health
aws elbv2 describe-target-health `
  --target-group-arn <target-group-arn> `
  --region ap-southeast-1
```

### 5. Test Health Check Endpoint (After ECS Deployment)

```powershell
# From within VPC (use EC2 bastion or VPC endpoint)
curl http://<alb-dns-name>/health
# Expected: {"status":"healthy"}
```

## Integration with Other Modules

### Dependencies

1. **Module 01 - Networking**: Requires VPC and private subnet
2. **Module 02 - Security Groups**: Requires ALB security group
3. **Module 22 - SNS**: Requires SNS topic for alarms

### Used By

1. **Module 11 - ECS**: ECS service registers targets with ALB target group
2. **Module 14 - API Gateway**: VPC Link forwards to ALB
3. **Module 21 - CloudWatch**: Monitors ALB metrics

## Validation Checklist

- [ ] ALB is created with `internal` scheme (not internet-facing)
- [ ] ALB is in private subnet only
- [ ] Target group has correct health check path (`/health`)
- [ ] Security group allows ingress from API Gateway VPC Link
- [ ] CloudWatch alarms are created and linked to SNS topic
- [ ] ALB DNS name resolves within VPC
- [ ] Listener forwards to correct target group

## Cost Estimation

### ALB Costs (per month)

- **Fixed**: $0.0225/hour × 730 hours = **$16.43**
- **LCU (Load Balancer Capacity Units)**:
  - New connections: ~10/sec
  - Active connections: ~100
  - Processed bytes: ~1 GB/hour
  - Rule evaluations: ~1 rule
  - Estimated LCU cost: **~$1-3/month** (minimal dev traffic)
- **Total**: **~$17-20/month**

### Cost Optimization

- Single AZ deployment (no cross-AZ data transfer)
- No access logs (save S3 costs)
- Internal-only (no internet egress charges)

## Troubleshooting

### Issue: ALB marked as "provisioning" for too long

```powershell
# Check subnet availability
aws ec2 describe-subnets --subnet-ids <subnet-id>

# Check security group rules
aws ec2 describe-security-groups --group-ids <alb-sg-id>
```

### Issue: Target group shows no healthy targets

```powershell
# Check if ECS tasks are running
aws ecs list-tasks --cluster typerush-dev-ecs-cluster --region ap-southeast-1

# Check ECS service health
aws ecs describe-services `
  --cluster typerush-dev-ecs-cluster `
  --services typerush-dev-game-service `
  --region ap-southeast-1
```

### Issue: Health checks failing

```powershell
# Check security group rules (allow ALB -> ECS on port 3000)
aws ec2 describe-security-group-rules --filters Name=group-id,Values=<ecs-sg-id>

# Check ECS task logs
aws logs tail /ecs/typerush-dev-game-service --follow --region ap-southeast-1
```

## References

- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Target Group Health Checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [VPC Link Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-vpc-links-v2.html)
- [ALB Monitoring](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html)

## Next Steps

After deploying the ALB:

1. Deploy ECS Cluster and Game Service (Step 11)
2. Verify ECS tasks register with target group
3. Create VPC Link in API Gateway (Step 14)
4. Test end-to-end connectivity
