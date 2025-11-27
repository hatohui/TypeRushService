# ========================================
# Internal Application Load Balancer
# ========================================

# ========================================
# Target Group for Game Service
# ========================================

resource "aws_lb_target_group" "game_service" {
  name                 = "${var.project_name}-${var.environment}-game-tg"
  port                 = 3000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip" # Required for Fargate
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  stickiness {
    enabled = false # Stateless service, session state in Redis
    type    = "lb_cookie"
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-game-service-tg"
      Service = "game-service"
    }
  )
}

# ========================================
# Internal Application Load Balancer
# ========================================

resource "aws_lb" "internal" {
  name               = "${var.project_name}-${var.environment}-internal-alb"
  internal           = true # Not internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  drop_invalid_header_fields = true
  idle_timeout               = var.idle_timeout

  # Access logs disabled for dev to save S3 costs
  # Enable in production
  # access_logs {
  #   bucket  = var.access_logs_bucket
  #   enabled = true
  #   prefix  = "alb"
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-internal-alb"
    }
  )
}

# ========================================
# HTTP Listener
# ========================================

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
      Name = "${var.project_name}-${var.environment}-http-listener"
    }
  )
}

# ========================================
# CloudWatch Alarms (Optional)
# ========================================

# Alarm: Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count = var.sns_topic_arn != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when ALB has unhealthy targets"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
    TargetGroup  = aws_lb_target_group.game_service.arn_suffix
  }

  tags = var.tags
}

# Alarm: High Response Time
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  count = var.sns_topic_arn != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2.0
  alarm_description   = "Alert when ALB target response time exceeds 2 seconds"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
    TargetGroup  = aws_lb_target_group.game_service.arn_suffix
  }

  tags = var.tags
}

# Alarm: 5XX Errors
resource "aws_cloudwatch_metric_alarm" "target_5xx_errors" {
  count = var.sns_topic_arn != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-alb-target-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when ALB targets return > 10 5XX errors in 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
    TargetGroup  = aws_lb_target_group.game_service.arn_suffix
  }

  tags = var.tags
}
