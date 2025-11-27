# Step 14: API Gateway (HTTP + WebSocket APIs)

## Status: IMPLEMENTED (Not Applied)

**Implemented on**: November 23, 2025  
**Applied to AWS**: Not yet - waiting for full stack implementation

**Note**: This module has been coded and validated in Terraform but NOT yet applied to AWS infrastructure. JWT authorization with Cognito will be added when Step 18 (Cognito) is implemented.

## Terraform Modules: `modules/14-vpc-link`, `modules/15-api-gateway-http`, and `modules/16-api-gateway-ws`

## Overview

Create Amazon API Gateway with HTTP API (for REST endpoints) and WebSocket API (for real-time gameplay), integrated with internal ALB via VPC Link and Lambda functions for serverless APIs.

## Architecture Reference

From `architecture-diagram.md`:

- **HTTP API**: REST endpoints for Game, Record, and Text services
- **WebSocket API**: Real-time gameplay connections
- **VPC Link v2**: Private integration with internal ALB (Game Service)
- **Direct Integration**: Lambda invocation for Record and Text services
- **Authorization**: AWS Cognito JWT tokens
- **Cost**: ~$5/month (minimal dev usage)

## Components to Implement

### 1. VPC Link v2

VPC Link v2 enables private integration between API Gateway and internal ALB without requiring a Network Load Balancer.

- [ ] **VPC Link Name**: `typerush-dev-vpc-link`
- [ ] **Subnets**: Private subnet IDs
- [ ] **Security Groups**: VPC Link security group (allows egress to ALB)
- [ ] **Type**: VPC_LINK (implicit for HTTP API)
- [ ] **Target**: Internal ALB

**Important**: VPC Links v2 are immutable. Cannot change subnets/security groups after creation.

### 2. HTTP API (REST Endpoints)

- [ ] **API Name**: `typerush-dev-http-api`
- [ ] **Protocol Type**: HTTP
- [ ] **CORS Configuration**:
  - Allow Origins: `https://typerush.example.com` (or `*` for dev)
  - Allow Methods: GET, POST, PUT, DELETE, OPTIONS
  - Allow Headers: Content-Type, Authorization, X-Amz-Date
  - Allow Credentials: true
  - Max Age: 300 seconds

#### Routes and Integrations

##### Game Service Routes (via VPC Link → ALB)

- [ ] `GET /api/game/health` → ALB:80/health
- [ ] `POST /api/game/session` → ALB:80/api/game/session
- [ ] `GET /api/game/session/{sessionId}` → ALB:80/api/game/session/{sessionId}
- [ ] `POST /api/game/complete` → ALB:80/api/game/complete

##### Record Service Routes (Lambda Integration)

- [ ] `GET /api/records/account/{accountId}` → Lambda: record-service
- [ ] `POST /api/records/match` → Lambda: record-service
- [ ] `GET /api/records/leaderboard` → Lambda: record-service

##### Text Service Routes (Lambda Integration)

- [ ] `GET /api/texts/random` → Lambda: text-service
- [ ] `POST /api/texts/generate` → Lambda: text-service (Bedrock AI)
- [ ] `GET /api/texts/{textId}` → Lambda: text-service

#### Authorization

- [ ] **Authorizer Type**: JWT (Cognito)
- [ ] **Issuer**: Cognito User Pool URL
- [ ] **Audience**: Cognito App Client ID
- [ ] **Identity Source**: `$request.header.Authorization`
- [ ] **Routes Requiring Auth**: All except `/health`

### 3. WebSocket API (Real-time Gameplay)

- [ ] **API Name**: `typerush-dev-ws-api`
- [ ] **Protocol Type**: WEBSOCKET
- [ ] **Route Selection Expression**: `$request.body.action`

#### WebSocket Routes

##### Connection Management

- [ ] `$connect` → VPC Link → ALB:80/ws/connect
  - Authorization: JWT authorizer (Cognito)
  - Stores connectionId in ElastiCache
- [ ] `$disconnect` → VPC Link → ALB:80/ws/disconnect
  - Cleanup session data from ElastiCache
- [ ] `$default` → VPC Link → ALB:80/ws/default
  - Handle unknown messages

##### Game Action Routes

- [ ] `startGame` → VPC Link → ALB:80/ws/startGame
- [ ] `keypress` → VPC Link → ALB:80/ws/keypress
- [ ] `gameComplete` → VPC Link → ALB:80/ws/gameComplete
- [ ] `joinRoom` → VPC Link → ALB:80/ws/joinRoom
- [ ] `leaveRoom` → VPC Link → ALB:80/ws/leaveRoom

#### WebSocket Authorization

- [ ] **Authorizer Type**: Lambda authorizer (custom)
- [ ] **Lambda Function**: JWT validator (reuse or create)
- [ ] **Identity Source**: `route.request.querystring.token`
- [ ] **Authorization Caching**: 300 seconds

### 4. API Gateway Stages

#### HTTP API Stage

- [ ] **Stage Name**: `dev`
- [ ] **Auto Deploy**: true
- [ ] **Throttling**:
  - Rate Limit: 100 requests/second
  - Burst Limit: 200 requests
- [ ] **Access Logs**: Disabled (dev, save CloudWatch costs)
- [ ] **Detailed Metrics**: Enabled

#### WebSocket API Stages

- [ ] **Stage Name**: `dev`
- [ ] **Auto Deploy**: true
- [ ] **Default Route Settings**:
  - Throttling: 100 requests/second
  - Data Trace: Enabled (dev only)
- [ ] **Access Logs**: Disabled

### 5. Custom Domain Names (Optional)

- [ ] **HTTP API Domain**: `api.typerush.example.com`
- [ ] **WebSocket API Domain**: `ws.typerush.example.com`
- [ ] **ACM Certificate**: Required (from Step 17)
- [ ] **Base Path Mapping**:
  - HTTP API: `/` → dev stage
  - WebSocket API: `/` → dev stage

**Note**: Skip for dev if testing with default API Gateway URLs.

## Implementation Details

### Terraform Configuration

#### VPC Link v2

```hcl
resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.project_name}-vpc-link"
  security_group_ids = [var.vpc_link_security_group_id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-link"
    }
  )
}
```

#### HTTP API

```hcl
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
  description   = "HTTP API for TypeRush REST endpoints"

  cors_configuration {
    allow_origins     = var.environment == "dev" ? ["*"] : var.allowed_origins
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["content-type", "authorization", "x-amz-date"]
    allow_credentials = true
    max_age           = 300
  }

  tags = var.tags
}

# JWT Authorizer (Cognito)
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-authorizer"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# VPC Link Integration to ALB
resource "aws_apigatewayv2_integration" "alb" {
  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.alb_listener_arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.main.id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# Lambda Integration - Record Service
resource "aws_apigatewayv2_integration" "record_service" {
  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.record_service_lambda_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Lambda Integration - Text Service
resource "aws_apigatewayv2_integration" "text_service" {
  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.text_service_lambda_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Game Service Routes (ALB)
resource "aws_apigatewayv2_route" "game_health" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /api/game/health"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "game_session_create" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /api/game/session"
  target             = "integrations/${aws_apigatewayv2_integration.alb.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Record Service Routes (Lambda)
resource "aws_apigatewayv2_route" "record_account" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /api/records/account/{accountId}"
  target             = "integrations/${aws_apigatewayv2_integration.record_service.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Text Service Routes (Lambda)
resource "aws_apigatewayv2_route" "text_random" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /api/texts/random"
  target             = "integrations/${aws_apigatewayv2_integration.text_service.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# HTTP API Stage
resource "aws_apigatewayv2_stage" "http_dev" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "dev"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 200
    throttling_rate_limit  = 100
    detailed_metrics_enabled = true
  }

  tags = var.tags
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "record_service" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.record_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*"
}

resource "aws_lambda_permission" "text_service" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.text_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*"
}
```

#### WebSocket API

```hcl
resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.project_name}-ws-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  description                = "WebSocket API for TypeRush real-time gameplay"

  tags = var.tags
}

# VPC Link Integration for WebSocket
resource "aws_apigatewayv2_integration" "ws_alb" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.alb_listener_arn
  integration_method = "POST"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.main.id
}

# WebSocket Routes
resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.ws_alb.id}"
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

# WebSocket Stage
resource "aws_apigatewayv2_stage" "ws_dev" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "dev"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit   = 200
    throttling_rate_limit    = 100
    data_trace_enabled       = true
    detailed_metrics_enabled = true
    logging_level            = "INFO"
  }

  tags = var.tags
}

# Outputs
output "http_api_endpoint" {
  description = "HTTP API endpoint URL"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = aws_apigatewayv2_api.websocket.api_endpoint
}

output "vpc_link_id" {
  description = "VPC Link ID"
  value       = aws_apigatewayv2_vpc_link.main.id
}
```

## Deployment Steps

### 1. Verify Prerequisites

```powershell
# Check ALB listener exists
terraform state show module.alb.aws_lb_listener.http

# Check Lambda functions exist
terraform state show module.lambda.aws_lambda_function.record_service
terraform state show module.lambda.aws_lambda_function.text_service
```

### 2. Plan API Gateway Deployment

```powershell
terraform plan -target=module.api_gateway -var-file="env/dev.tfvars.local"
```

### 3. Deploy API Gateway

```powershell
terraform apply -target=module.api_gateway -var-file="env/dev.tfvars.local"
```

### 4. Test HTTP API

```powershell
# Health check (no auth required)
$HTTP_API_ENDPOINT = terraform output -raw http_api_endpoint
curl "$HTTP_API_ENDPOINT/dev/api/game/health"

# Authenticated endpoint (requires Cognito token)
$TOKEN = "YOUR_COGNITO_JWT_TOKEN"
curl -H "Authorization: Bearer $TOKEN" "$HTTP_API_ENDPOINT/dev/api/texts/random"
```

### 5. Test WebSocket API

```powershell
# Use wscat tool
npm install -g wscat

$WS_API_ENDPOINT = terraform output -raw websocket_api_endpoint
wscat -c "$WS_API_ENDPOINT/dev?token=YOUR_COGNITO_JWT_TOKEN"

# Send message
> {"action": "startGame", "gameMode": "solo"}
```

## Integration with Other Modules

### Dependencies

1. **Module 01 - Networking**: VPC Link requires private subnets
2. **Module 02 - Security Groups**: VPC Link security group
3. **Module 12 - Lambda**: Record and Text service functions
4. **Module 13 - ALB**: Internal ALB listener ARN
5. **Module 18 - Cognito**: User Pool for JWT authorization

### Used By

1. **Module 15 - CloudFront**: Origin for HTTP API
2. **Module 16 - Route 53**: DNS records for custom domains
3. **Module 11 - ECS**: Game Service handles WebSocket connections

## Validation Checklist

- [ ] VPC Link is in `AVAILABLE` state
- [ ] HTTP API has CORS configured correctly
- [ ] JWT authorizer validates Cognito tokens
- [ ] VPC Link integration routes to internal ALB
- [ ] Lambda integrations have correct permissions
- [ ] WebSocket API accepts connections
- [ ] All routes return 200 for valid requests
- [ ] Throttling limits are configured

## Cost Estimation

### API Gateway Costs (per month, dev usage)

- **HTTP API**:
  - First 300M requests/month: $1.00/million
  - Estimated 100K requests: **$0.10**
- **WebSocket API**:
  - Connection minutes: $0.25/million minutes
  - Messages: $1.00/million messages
  - Estimated 1000 connections × 10 min = 10K minutes: **$0.003**
  - Estimated 50K messages: **$0.05**
- **VPC Link**: $0.01/hour = **$7.30/month**
- **Data Transfer**: Negligible (internal VPC)
- **Total**: **~$7.50/month**

### Cost Optimization

- Use VPC Link v2 (no NLB required)
- Disable access logs in dev
- Use JWT authorizer (no Lambda cost)
- Throttle at 100 req/sec (dev limit)

## Troubleshooting

### Issue: VPC Link stuck in "PENDING" state

```powershell
# Check subnet and security group
aws ec2 describe-subnets --subnet-ids <subnet-id>
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify private subnet has route to NAT Gateway
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=<subnet-id>"
```

### Issue: API Gateway returns 503 Service Unavailable

```powershell
# Check ALB health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Check VPC Link status
aws apigatewayv2 get-vpc-link --vpc-link-id <vpc-link-id>
```

### Issue: JWT authorization fails

```powershell
# Verify Cognito issuer URL
aws cognito-idp describe-user-pool --user-pool-id <pool-id>

# Test JWT token
jwt decode $TOKEN
```

### Issue: WebSocket connection times out

```powershell
# Check ECS service logs
aws logs tail /ecs/typerush-dev-game-service --follow

# Verify WebSocket route integration
aws apigatewayv2 get-route --api-id <api-id> --route-id <route-id>
```

## References

- [API Gateway VPC Links v2](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-vpc-links-v2.html)
- [HTTP API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [WebSocket API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api.html)
- [JWT Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html)
- [ALB Integration Blog Post](https://aws.amazon.com/blogs/compute/build-scalable-rest-apis-using-amazon-api-gateway-private-integration-with-application-load-balancer/)

## Next Steps

After deploying API Gateway:

1. Create CloudFront distribution with API Gateway origin (Step 15)
2. Set up custom domain names in Route 53 (Step 16)
3. Test end-to-end API flows
4. Configure Cognito for authentication (Step 18)
5. Monitor API Gateway metrics in CloudWatch
