# ========================================
# API Gateway WebSocket API
# ========================================
# WebSocket API for real-time gameplay connections

# ========================================
# WebSocket API
# ========================================

resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.project_name}-${var.environment}-ws-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  description                = "WebSocket API for TypeRush real-time gameplay"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ws-api"
    }
  )
}

# ========================================
# VPC Link Integration for WebSocket
# ========================================

resource "aws_apigatewayv2_integration" "ws_alb" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.alb_listener_arn
  integration_method = "POST"
  connection_type    = "VPC_LINK"
  connection_id      = var.vpc_link_id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# ========================================
# WebSocket Connection Management Routes
# ========================================

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
  # Authorization will be added when Cognito module is implemented
  # authorization_type = "CUSTOM"
  # authorizer_id      = aws_apigatewayv2_authorizer.websocket.id
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

# ========================================
# Game Action Routes
# ========================================

resource "aws_apigatewayv2_route" "start_game" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "startGame"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

resource "aws_apigatewayv2_route" "keypress" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "keypress"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

resource "aws_apigatewayv2_route" "game_complete" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "gameComplete"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

resource "aws_apigatewayv2_route" "join_room" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "joinRoom"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

resource "aws_apigatewayv2_route" "leave_room" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "leaveRoom"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
}

# ========================================
# WebSocket API Stage
# ========================================

resource "aws_apigatewayv2_stage" "ws_dev" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = var.stage_name
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit   = var.throttle_burst_limit
    throttling_rate_limit    = var.throttle_rate_limit
    data_trace_enabled       = false
    detailed_metrics_enabled = true
    logging_level            = "OFF"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ws-api-stage"
    }
  )
}

# ========================================
# WebSocket API Deployment
# ========================================
# WebSocket APIs require explicit deployment when routes change

resource "aws_apigatewayv2_deployment" "ws" {
  api_id      = aws_apigatewayv2_api.websocket.id
  description = "WebSocket API deployment for ${var.environment}"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_route.connect.id,
      aws_apigatewayv2_route.disconnect.id,
      aws_apigatewayv2_route.default.id,
      aws_apigatewayv2_route.start_game.id,
      aws_apigatewayv2_route.keypress.id,
      aws_apigatewayv2_route.game_complete.id,
      aws_apigatewayv2_route.join_room.id,
      aws_apigatewayv2_route.leave_room.id,
      aws_apigatewayv2_integration.ws_alb.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route.disconnect,
    aws_apigatewayv2_route.default,
    aws_apigatewayv2_route.start_game,
    aws_apigatewayv2_route.keypress,
    aws_apigatewayv2_route.game_complete,
    aws_apigatewayv2_route.join_room,
    aws_apigatewayv2_route.leave_room,
  ]
}
