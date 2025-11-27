# ========================================
# API Gateway HTTP API
# ========================================
# HTTP API for REST endpoints with VPC Link and Lambda integrations

data "aws_region" "current" {}

# ========================================
# HTTP API
# ========================================

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-${var.environment}-http-api"
  protocol_type = "HTTP"
  description   = "HTTP API for TypeRush REST endpoints"

  cors_configuration {
    allow_origins     = var.cors_allow_origins
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["content-type", "authorization", "x-amz-date", "x-api-key"]
    allow_credentials = false
    max_age           = 300
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-http-api"
    }
  )
}

# ========================================
# JWT Authorizer (Cognito) - TO BE ADDED
# ========================================
# NOTE: This will be added when Cognito module (Step 18) is implemented
# For now, routes are created without authorization (dev only)
#
# resource "aws_apigatewayv2_authorizer" "cognito" {
#   api_id           = aws_apigatewayv2_api.http.id
#   authorizer_type  = "JWT"
#   identity_sources = ["$request.header.Authorization"]
#   name             = "${var.project_name}-${var.environment}-cognito-authorizer"
#
#   jwt_configuration {
#     audience = [var.cognito_client_id]
#     issuer   = "https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${var.cognito_user_pool_id}"
#   }
# }

# ========================================
# Integrations
# ========================================

# VPC Link Integration to ALB (Game Service)
resource "aws_apigatewayv2_integration" "alb" {
  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.alb_listener_arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = var.vpc_link_id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# Lambda Integration - Record Service
resource "aws_apigatewayv2_integration" "record_service" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.record_service_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Lambda Integration - Text Service
resource "aws_apigatewayv2_integration" "text_service" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.text_service_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ========================================
# Routes - Game Service (via ALB)
# ========================================

resource "aws_apigatewayv2_route" "game_health" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/game/health"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "game_session_create" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /api/game/session"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
  # authorization_type = "JWT"  # TO BE ENABLED with Cognito
  # authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "game_session_get" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/game/session/{sessionId}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "game_complete" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /api/game/complete"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# ========================================
# Routes - Record Service (Lambda)
# ========================================

resource "aws_apigatewayv2_route" "record_account" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/records/account/{accountId}"
  target    = "integrations/${aws_apigatewayv2_integration.record_service.id}"
  # authorization_type = "JWT"  # TO BE ENABLED with Cognito
  # authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "record_match" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /api/records/match"
  target    = "integrations/${aws_apigatewayv2_integration.record_service.id}"
}

resource "aws_apigatewayv2_route" "record_leaderboard" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/records/leaderboard"
  target    = "integrations/${aws_apigatewayv2_integration.record_service.id}"
}

# ========================================
# Routes - Text Service (Lambda)
# ========================================

resource "aws_apigatewayv2_route" "text_random" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/texts/random"
  target    = "integrations/${aws_apigatewayv2_integration.text_service.id}"
}

resource "aws_apigatewayv2_route" "text_generate" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /api/texts/generate"
  target    = "integrations/${aws_apigatewayv2_integration.text_service.id}"
}

resource "aws_apigatewayv2_route" "text_get" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/texts/{textId}"
  target    = "integrations/${aws_apigatewayv2_integration.text_service.id}"
}

# ========================================
# HTTP API Stage
# ========================================

resource "aws_apigatewayv2_stage" "http_dev" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.stage_name
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit   = var.throttle_burst_limit
    throttling_rate_limit    = var.throttle_rate_limit
    detailed_metrics_enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-http-api-stage"
    }
  )
}

# ========================================
# Lambda Permissions for API Gateway
# ========================================

resource "aws_lambda_permission" "record_service" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.record_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "text_service" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.text_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
