#!/bin/bash
# test-infrastructure.sh
# Quick verification script for TypeRush infrastructure

set -e

echo "🔍 TypeRush Infrastructure Verification"
echo "========================================"
echo ""

cd "$(dirname "$0")/infras"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check Terraform state
echo "Checking Terraform state..."
if terraform output > /dev/null 2>&1; then
    success "Terraform state OK"
else
    error "Terraform state not found. Run 'terraform apply' first"
    exit 1
fi

echo ""

# 2. Check DynamoDB
echo "Testing DynamoDB..."
TABLE_NAME=$(terraform output -raw dynamodb_texts_table_name 2>/dev/null)
if aws dynamodb describe-table --table-name "$TABLE_NAME" > /dev/null 2>&1; then
    success "DynamoDB table accessible: $TABLE_NAME"
else
    error "Cannot access DynamoDB table"
fi

# 3. Check Lambda functions
echo "Testing Lambda functions..."
TEXT_LAMBDA=$(terraform output -raw text_service_function_name 2>/dev/null)
RECORD_LAMBDA=$(terraform output -raw record_service_function_name 2>/dev/null)

if aws lambda get-function --function-name "$TEXT_LAMBDA" > /dev/null 2>&1; then
    success "Text Service Lambda exists: $TEXT_LAMBDA"
else
    error "Text Service Lambda not found"
fi

if aws lambda get-function --function-name "$RECORD_LAMBDA" > /dev/null 2>&1; then
    success "Record Service Lambda exists: $RECORD_LAMBDA"
else
    error "Record Service Lambda not found"
fi

# 4. Check ECR repositories and images
echo "Testing ECR repositories..."
for repo in "typerush/game-service" "typerush/record-service" "typerush/text-service"; do
    if aws ecr describe-repositories --repository-names "$repo" > /dev/null 2>&1; then
        success "ECR repository exists: $repo"
        
        # Check if images exist
        IMAGE_COUNT=$(aws ecr list-images --repository-name "$repo" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
        if [ "$IMAGE_COUNT" -gt 0 ]; then
            success "  └─ Has $IMAGE_COUNT image(s)"
        else
            warning "  └─ No images pushed yet (needs deployment)"
        fi
    else
        error "ECR repository not found: $repo"
    fi
done

# 5. Check ECS cluster and service
echo "Testing ECS cluster..."
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null)
SERVICE_NAME=$(terraform output -raw game_service_name 2>/dev/null)

if aws ecs describe-clusters --clusters "$CLUSTER_NAME" --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
    success "ECS Cluster active: $CLUSTER_NAME"
    
    # Check service status
    SERVICE_STATUS=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].{running:runningCount,desired:desiredCount}' --output json 2>/dev/null)
    RUNNING=$(echo "$SERVICE_STATUS" | jq -r '.running')
    DESIRED=$(echo "$SERVICE_STATUS" | jq -r '.desired')
    
    if [ "$RUNNING" = "$DESIRED" ] && [ "$RUNNING" -gt 0 ]; then
        success "  └─ Service running: $RUNNING/$DESIRED tasks"
    elif [ "$RUNNING" = "0" ] && [ "$DESIRED" = "0" ]; then
        warning "  └─ Service scaled to 0 (no tasks running)"
    else
        warning "  └─ Service scaling: $RUNNING/$DESIRED tasks (may need Docker image)"
    fi
else
    error "ECS Cluster not active"
fi

# 6. Check API Gateways
echo "Testing API Gateways..."
HTTP_API_ID=$(terraform output -raw http_api_id 2>/dev/null)
WS_API_ID=$(terraform output -raw websocket_api_id 2>/dev/null)

if aws apigatewayv2 get-api --api-id "$HTTP_API_ID" > /dev/null 2>&1; then
    HTTP_ENDPOINT=$(terraform output -raw http_api_endpoint)
    success "HTTP API exists: $HTTP_ENDPOINT"
else
    error "HTTP API not found"
fi

if aws apigatewayv2 get-api --api-id "$WS_API_ID" > /dev/null 2>&1; then
    WS_ENDPOINT=$(terraform output -raw websocket_api_endpoint)
    success "WebSocket API exists: $WS_ENDPOINT"
else
    error "WebSocket API not found"
fi

# 7. Check CloudFront
echo "Testing CloudFront..."
CF_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)
CF_URL=$(terraform output -raw cloudfront_distribution_url 2>/dev/null)

if aws cloudfront get-distribution --id "$CF_ID" --query 'Distribution.Status' --output text 2>/dev/null | grep -q "Deployed"; then
    success "CloudFront Distribution deployed: $CF_URL"
else
    warning "CloudFront Distribution exists but may still be deploying"
fi

# 8. Check Cognito
echo "Testing Cognito..."
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)

if aws cognito-idp describe-user-pool --user-pool-id "$USER_POOL_ID" > /dev/null 2>&1; then
    success "Cognito User Pool exists: $USER_POOL_ID"
else
    error "Cognito User Pool not found"
fi

# 9. Check RDS
echo "Testing RDS..."
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null)
RDS_ID=$(terraform output -raw rds_instance_id 2>/dev/null)

if aws rds describe-db-instances --db-instance-identifier "$RDS_ID" --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null | grep -q "available"; then
    success "RDS instance available: $RDS_ENDPOINT"
else
    warning "RDS instance exists but may not be available yet"
fi

# 10. Check ElastiCache
echo "Testing ElastiCache..."
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint 2>/dev/null)

if [ -n "$REDIS_ENDPOINT" ]; then
    success "ElastiCache Redis endpoint: $REDIS_ENDPOINT"
else
    warning "ElastiCache endpoint not found in outputs"
fi

echo ""
echo "========================================"
echo "🎉 Infrastructure Verification Complete!"
echo "========================================"
echo ""

# Summary
echo "📊 Quick Stats:"
echo "  VPC: $(terraform output -raw vpc_id)"
echo "  Region: $(terraform output -raw deployment_info | jq -r '.region')"
echo "  ECS Cluster: $CLUSTER_NAME"
echo "  HTTP API: $HTTP_ENDPOINT"
echo "  CloudFront: $CF_URL"
echo ""

# Check if services need deployment
GAME_ECR_IMAGES=$(aws ecr list-images --repository-name "typerush/game-service" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")

if [ "$GAME_ECR_IMAGES" = "0" ]; then
    echo "⚠️  Next Steps - Services Need Deployment:"
    echo ""
    echo "1. 🐳 Push Docker image for Game Service:"
    echo "   cd services/game-service"
    echo "   ECR_REPO=\$(cd ../../infras && terraform output -raw game_service_repository_url)"
    echo "   aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 630633962130.dkr.ecr.ap-southeast-1.amazonaws.com"
    echo "   docker build -t typerush/game-service:latest ."
    echo "   docker tag typerush/game-service:latest \$ECR_REPO:latest"
    echo "   docker push \$ECR_REPO:latest"
    echo "   aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment"
    echo ""
    echo "2. 📦 Deploy Lambda functions:"
    echo "   See VERIFICATION_AND_DEPLOYMENT_GUIDE.md (Step 3)"
    echo ""
    echo "3. 🌐 Deploy Frontend:"
    echo "   cd frontend && npm install && npm run build"
    echo "   aws s3 sync dist/ s3://\$(cd ../infras && terraform output -raw frontend_bucket_name)/"
    echo ""
else
    echo "✅ Docker images found in ECR - services may be deployed"
    echo ""
fi

echo "For detailed deployment instructions, see:"
echo "  📖 VERIFICATION_AND_DEPLOYMENT_GUIDE.md"
echo ""
