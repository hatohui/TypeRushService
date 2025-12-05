# Step 24: Testing and Validation

## Status: NOT STARTED

## Terraform Module: N/A (uses all deployed modules)

## Overview

Comprehensive testing and validation procedures to verify the entire TypeRush infrastructure is deployed correctly and functioning as expected.

## Testing Checklist

### 1. Network Layer Tests

#### VPC and Subnets

```powershell
# Verify VPC exists
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=typerush-dev-vpc"

# Verify subnets
aws ec2 describe-subnets --filters "Name=tag:Project,Values=typerush-dev" | ConvertFrom-Json | Select-Object -ExpandProperty Subnets | Select-Object SubnetId, CidrBlock, AvailabilityZone, Tags

# Test NAT Gateway connectivity (from private subnet)
# Expected: Can reach internet from private subnet
```

#### Security Groups

```powershell
# List all security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=typerush-dev"

# Verify ALB security group allows API Gateway VPC Link
# Verify ECS security group allows ALB traffic
# Verify RDS security group allows ECS/Lambda traffic
```

### 2. Data Layer Tests

#### RDS PostgreSQL

```powershell
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier typerush-dev-rds

# Test connection (from Lambda or ECS task)
$DB_SECRET = aws secretsmanager get-secret-value --secret-id typerush/rds/credentials --query SecretString --output text | ConvertFrom-Json

# Connect using psql (if available)
psql -h <rds-endpoint> -U $DB_SECRET.username -d typerush_db
```

#### ElastiCache Redis

```powershell
# Check Redis cluster status
aws elasticache describe-cache-clusters --cache-cluster-id typerush-dev-redis --show-cache-node-info

# Test connection (redis-cli)
redis-cli -h <redis-endpoint> -p 6379 -a <auth-token>
> PING
> SET test "Hello Redis"
> GET test
```

#### DynamoDB

```powershell
# Check table status
aws dynamodb describe-table --table-name typerush-dev-texts

# Insert test item
aws dynamodb put-item `
  --table-name typerush-dev-texts `
  --item '{\"textId\":{\"S\":\"test-1\"},\"content\":{\"S\":\"The quick brown fox\"}}'

# Query test item
aws dynamodb get-item `
  --table-name typerush-dev-texts `
  --key '{\"textId\":{\"S\":\"test-1\"}}'
```

### 3. Compute Layer Tests

#### ECS Service

```powershell
# Check ECS service status
aws ecs describe-services `
  --cluster typerush-dev-ecs-cluster `
  --services typerush-dev-game-service

# Check running tasks
aws ecs list-tasks --cluster typerush-dev-ecs-cluster --service-name typerush-dev-game-service

# Check task logs
aws logs tail /ecs/typerush-dev-game-service --follow
```

#### Lambda Functions

```powershell
# Test Record Service Lambda
aws lambda invoke `
  --function-name typerush-dev-record-service `
  --payload '{\"httpMethod\":\"GET\",\"path\":\"/api/records/health\"}' `
  response.json

cat response.json

# Test Text Service Lambda
aws lambda invoke `
  --function-name typerush-dev-text-service `
  --payload '{\"httpMethod\":\"GET\",\"path\":\"/api/texts/random\"}' `
  response.json
```

### 4. API Layer Tests

#### Internal ALB Health Check

```powershell
# Get ALB DNS name
$ALB_DNS = terraform output -raw alb_dns_name

# Test health endpoint (from within VPC)
curl http://$ALB_DNS/health
# Expected: {"status":"healthy"}

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
# Expected: "State": "healthy"
```

#### API Gateway HTTP API

```powershell
# Get API Gateway endpoint
$API_ENDPOINT = terraform output -raw http_api_endpoint

# Test public health endpoint (no auth)
curl "$API_ENDPOINT/dev/api/game/health"
# Expected: {"status":"healthy"}

# Test protected endpoint (requires auth token)
$TOKEN = "<cognito-jwt-token>"
curl -H "Authorization: Bearer $TOKEN" "$API_ENDPOINT/dev/api/texts/random"
# Expected: {"textId":"...","content":"..."}
```

#### WebSocket API

```powershell
# Install wscat if not available
npm install -g wscat

# Connect to WebSocket
$WS_ENDPOINT = terraform output -raw websocket_api_endpoint
wscat -c "$WS_ENDPOINT/dev?token=<jwt-token>"

# Send test message
> {"action":"startGame","gameMode":"solo"}

# Expected response with session data
```

### 5. CDN and Security Tests

#### CloudFront Distribution

```powershell
# Get CloudFront domain
$CF_DOMAIN = terraform output -raw cloudfront_domain_name

# Test frontend
curl https://$CF_DOMAIN/
# Expected: Frontend HTML

# Test API through CloudFront
curl https://$CF_DOMAIN/api/game/health
# Expected: {"status":"healthy"}

# Check HTTPS certificate
openssl s_client -connect $CF_DOMAIN:443 -servername $CF_DOMAIN | Select-String "Verify return code"
# Expected: "Verify return code: 0 (ok)"
```

#### AWS WAF

```powershell
# Test rate limiting (send 2001 requests in 5 minutes)
for ($i = 1; $i -le 2001; $i++) {
    curl -s https://$CF_DOMAIN/ | Out-Null
    if ($i % 100 -eq 0) { Write-Output "Sent $i requests" }
}
# Expected: 429 Too Many Requests after 2000 requests

# Check WAF logs
aws logs tail /aws/waf/typerush-dev --follow
```

### 6. Authentication Tests

#### Cognito User Pool

```powershell
# Get Cognito details
$USER_POOL_ID = terraform output -raw user_pool_id
$APP_CLIENT_ID = terraform output -raw app_client_id

# Create test user
aws cognito-idp sign-up `
  --client-id $APP_CLIENT_ID `
  --username testuser@example.com `
  --password "Test@1234"

# Confirm user
aws cognito-idp admin-confirm-sign-up `
  --user-pool-id $USER_POOL_ID `
  --username testuser@example.com

# Sign in
aws cognito-idp initiate-auth `
  --auth-flow USER_PASSWORD_AUTH `
  --client-id $APP_CLIENT_ID `
  --auth-parameters USERNAME=testuser@example.com,PASSWORD="Test@1234"

# Get IdToken from response
```

### 7. CI/CD Pipeline Tests

#### CodePipeline

```powershell
# Trigger manual pipeline execution
aws codepipeline start-pipeline-execution `
  --name typerush-dev-game-service-pipeline

# Check pipeline status
aws codepipeline get-pipeline-state `
  --name typerush-dev-game-service-pipeline

# View execution details
aws codepipeline list-pipeline-executions `
  --pipeline-name typerush-dev-game-service-pipeline `
  --max-results 5
```

#### CodeBuild

```powershell
# Start manual build
aws codebuild start-build --project-name typerush-dev-game-service-build

# Check build logs
aws logs tail /aws/codebuild/typerush-dev-game-service-build --follow
```

### 8. Monitoring and Alerting Tests

#### CloudWatch Logs

```powershell
# Query ECS logs
aws logs tail /ecs/typerush-dev-game-service --follow --filter-pattern "ERROR"

# Query Lambda logs
aws logs tail /aws/lambda/typerush-dev-record-service --follow

# Run CloudWatch Insights query
aws logs start-query `
  --log-group-name /ecs/typerush-dev-game-service `
  --start-time (Get-Date).AddHours(-1).ToUniversalTime() `
  --end-time (Get-Date).ToUniversalTime() `
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'
```

#### CloudWatch Alarms

```powershell
# List all alarms
aws cloudwatch describe-alarms --query "MetricAlarms[?contains(AlarmName,'typerush-dev')]"

# Trigger test alarm
aws cloudwatch set-alarm-state `
  --alarm-name typerush-dev-ecs-high-cpu `
  --state-value ALARM `
  --state-reason "Manual test"

# Verify SNS email received
```

### 9. End-to-End User Flow Test

```powershell
# 1. User visits website
curl -I https://typerush.example.com/

# 2. User signs up
aws cognito-idp sign-up `
  --client-id $APP_CLIENT_ID `
  --username testuser2@example.com `
  --password "Test@1234"

# 3. User signs in and gets token
$AUTH_RESPONSE = aws cognito-idp initiate-auth `
  --auth-flow USER_PASSWORD_AUTH `
  --client-id $APP_CLIENT_ID `
  --auth-parameters USERNAME=testuser2@example.com,PASSWORD="Test@1234" | ConvertFrom-Json

$ID_TOKEN = $AUTH_RESPONSE.AuthenticationResult.IdToken

# 4. User requests random text
curl -H "Authorization: Bearer $ID_TOKEN" `
  "https://typerush.example.com/api/texts/random"

# 5. User starts game session
curl -X POST -H "Authorization: Bearer $ID_TOKEN" `
  -H "Content-Type: application/json" `
  -d '{"gameMode":"solo"}' `
  "https://typerush.example.com/api/game/session"

# 6. User completes game (via WebSocket or HTTP)
curl -X POST -H "Authorization: Bearer $ID_TOKEN" `
  -H "Content-Type: application/json" `
  -d '{"sessionId":"...", "wpm": 65, "accuracy": 95}' `
  "https://typerush.example.com/api/game/complete"

# 7. Game result saved to RDS (check Record Service)
curl -H "Authorization: Bearer $ID_TOKEN" `
  "https://typerush.example.com/api/records/account/<accountId>"
```

## Validation Checklist

- [ ] All VPC components deployed correctly
- [ ] NAT Gateway provides internet access to private subnet
- [ ] RDS PostgreSQL is accessible and healthy
- [ ] ElastiCache Redis is accessible and responsive
- [ ] DynamoDB table is functional
- [ ] ECS service has healthy tasks running
- [ ] Lambda functions execute successfully
- [ ] ALB health checks pass
- [ ] API Gateway validates JWT tokens
- [ ] WebSocket connections work
- [ ] CloudFront serves frontend assets
- [ ] WAF blocks malicious requests
- [ ] Cognito user registration and login work
- [ ] CI/CD pipeline executes successfully
- [ ] CloudWatch logs are being captured
- [ ] CloudWatch alarms trigger correctly
- [ ] SNS notifications are received
- [ ] End-to-end user flow completes successfully

## Performance Benchmarks (Dev Environment)

- **API Gateway Latency**: < 100ms (p50), < 500ms (p99)
- **Lambda Cold Start**: < 2 seconds
- **Lambda Warm**: < 200ms
- **ECS Task Startup**: < 30 seconds
- **RDS Query**: < 50ms (simple queries)
- **Redis GET**: < 5ms
- **CloudFront Cache Hit**: < 50ms
- **CloudFront Cache Miss**: < 200ms

## Common Issues and Resolutions

### Issue: ECS tasks failing health checks

```powershell
# Check task logs
aws logs tail /ecs/typerush-dev-game-service --follow

# Check security group rules (ALB → ECS port 3000)
# Verify health check path is correct (/health)
# Increase health check grace period
```

### Issue: Lambda timeout

```powershell
# Check Lambda execution time
# Increase timeout if needed (max 15 minutes)
# Verify VPC endpoints are configured (no NAT Gateway delays)
# Check CloudWatch Logs for errors
```

### Issue: API Gateway 403 Forbidden

```powershell
# Verify JWT token is valid (jwt.io)
# Check Cognito issuer URL matches API Gateway authorizer
# Verify token hasn't expired (60 minutes)
# Check API Gateway resource policy
```

## References

- [AWS Testing Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/framework/test.html)
- [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)

## Next Steps

After successful validation:

1. Document any issues encountered and resolutions
2. Create runbook for common operational tasks
3. Set up automated testing (integration tests, load tests)
4. Review and optimize resource configurations
5. Prepare for production deployment (Module 25)
6. Consider implementing:
   - Automated testing in CI/CD pipeline
   - Performance monitoring dashboards
   - Cost optimization analysis
   - Security audit and penetration testing
