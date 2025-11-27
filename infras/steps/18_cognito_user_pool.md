# Step 18: AWS Cognito User Authentication

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/09-cognito`

## Overview

Set up AWS Cognito User Pool for user authentication, registration, and JWT token management for API Gateway authorization.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: User authentication and authorization
- **Integration**: API Gateway JWT authorizer
- **Features**: Sign-up, sign-in, password reset, MFA (optional)
- **Cost**: Free tier: 50,000 MAUs, then $0.0055/MAU
- **Token**: JWT tokens for API authorization

## Components to Implement

### 1. Cognito User Pool

- [ ] **Pool Name**: typerush-dev-users
- [ ] **Sign-in Options**: Email, Username (or email only)
- [ ] **Password Policy**:
  - Minimum length: 8 characters
  - Require uppercase: Yes
  - Require lowercase: Yes
  - Require numbers: Yes
  - Require symbols: Optional
- [ ] **MFA**: Optional (SMS or TOTP)
- [ ] **Self-service Account Recovery**: Email
- [ ] **Auto-verify**: Email

### 2. User Pool Domain

- [ ] **Domain Prefix**: typerush-dev (must be globally unique)
- [ ] **Custom Domain**: auth.typerush.example.com (optional, requires ACM cert)

### 3. App Client

- [ ] **Client Name**: typerush-web-client
- [ ] **Auth Flows**: ALLOW_USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH
- [ ] **OAuth 2.0 Grants**: Authorization code grant, Implicit grant
- [ ] **OAuth Scopes**: openid, email, profile
- [ ] **Callback URLs**: https://typerush.example.com/callback
- [ ] **Sign-out URLs**: https://typerush.example.com/
- [ ] **Identity Providers**: Cognito User Pool (can add Google, Facebook later)
- [ ] **Generate Secret**: No (public client for SPA)

### 4. Token Configuration

- [ ] **ID Token Expiration**: 60 minutes
- [ ] **Access Token Expiration**: 60 minutes
- [ ] **Refresh Token Expiration**: 30 days
- [ ] **Refresh Token Rotation**: Enabled

### 5. User Attributes

Standard attributes:

- [ ] Email (required, mutable)
- [ ] Name (optional, mutable)
- [ ] Preferred Username (optional)

Custom attributes (if needed):

- [ ] custom:player_id (string)
- [ ] custom:total_games (number)

### 6. Email Configuration

- [ ] **Email Provider**: Cognito (default, 50 emails/day limit)
- [ ] **From Email**: no-reply@verificationemail.com (Cognito default)
- [ ] **Reply-to Email**: support@typerush.example.com
- [ ] **Production**: Use SES for higher limits

### 7. Lambda Triggers (Optional)

- [ ] **Pre Sign-up**: Auto-confirm users (skip email verification in dev)
- [ ] **Post Authentication**: Log user login events
- [ ] **Pre Token Generation**: Add custom claims to JWT

## Implementation Details

### Terraform Configuration

```hcl
# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-users"

  # Sign-in options
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Custom attribute for player ID
  schema {
    name                = "player_id"
    attribute_data_type = "String"
    mutable             = false
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # MFA configuration (optional in dev)
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  # Deletion protection
  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-user-pool"
    }
  )
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# App Client
resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project_name}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH" # For testing only
  ]

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  # Token configuration
  id_token_validity      = 60  # minutes
  access_token_validity  = 60  # minutes
  refresh_token_validity = 30  # days

  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }

  # No client secret (public client for SPA)
  generate_secret = false

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Enable token revocation
  enable_token_revocation = true
  enable_propagate_additional_user_context_data = false

  # Read/write attributes
  read_attributes  = ["email", "name", "custom:player_id"]
  write_attributes = ["email", "name"]
}

# Lambda trigger for auto-confirm (dev only)
resource "aws_lambda_permission" "cognito_pre_signup" {
  count = var.auto_confirm_users ? 1 : 0

  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_signup[0].function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_lambda_function" "pre_signup" {
  count = var.auto_confirm_users ? 1 : 0

  function_name = "${var.project_name}-cognito-pre-signup"
  role          = var.lambda_execution_role_arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename = "${path.module}/lambda/pre-signup.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/pre-signup.zip")

  environment {
    variables = {
      AUTO_CONFIRM = "true"
    }
  }

  tags = var.tags
}

# Cognito Lambda trigger configuration
resource "aws_cognito_user_pool" "main_with_lambda" {
  count = var.auto_confirm_users ? 1 : 0

  lambda_config {
    pre_sign_up = aws_lambda_function.pre_signup[0].arn
  }
}

# Outputs
output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "app_client_id" {
  description = "App client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "user_pool_domain" {
  description = "Cognito hosted UI domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "issuer_url" {
  description = "JWT issuer URL for API Gateway"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}
```

### Lambda Pre-Signup Function (lambda/pre-signup/index.js)

```javascript
exports.handler = async (event) => {
  // Auto-confirm users (dev only - skip email verification)
  event.response.autoConfirmUser = true;
  event.response.autoVerifyEmail = true;

  return event;
};
```

## Deployment Steps

### 1. Plan Cognito Deployment

```powershell
terraform plan -target=module.cognito -var-file="env/dev.tfvars.local"
```

### 2. Deploy Cognito

```powershell
terraform apply -target=module.cognito -var-file="env/dev.tfvars.local"
```

### 3. Get Cognito Details

```powershell
$USER_POOL_ID = terraform output -raw user_pool_id
$APP_CLIENT_ID = terraform output -raw app_client_id
$ISSUER_URL = terraform output -raw issuer_url

Write-Output "User Pool ID: $USER_POOL_ID"
Write-Output "App Client ID: $APP_CLIENT_ID"
Write-Output "Issuer URL: $ISSUER_URL"
```

### 4. Test User Sign-up

```powershell
# Create test user
aws cognito-idp sign-up `
  --client-id $APP_CLIENT_ID `
  --username testuser@example.com `
  --password "Test@1234" `
  --user-attributes Name=email,Value=testuser@example.com Name=name,Value="Test User" `
  --region ap-southeast-1

# Confirm user (admin command)
aws cognito-idp admin-confirm-sign-up `
  --user-pool-id $USER_POOL_ID `
  --username testuser@example.com `
  --region ap-southeast-1
```

### 5. Test User Sign-in

```powershell
# Initiate auth
aws cognito-idp initiate-auth `
  --auth-flow USER_PASSWORD_AUTH `
  --client-id $APP_CLIENT_ID `
  --auth-parameters USERNAME=testuser@example.com,PASSWORD="Test@1234" `
  --region ap-southeast-1

# Get tokens from response
# IdToken, AccessToken, RefreshToken
```

### 6. Test JWT with API Gateway

```powershell
# Get ID token from sign-in response
$ID_TOKEN = "eyJraWQ..."

# Test protected API endpoint
curl -H "Authorization: Bearer $ID_TOKEN" `
  "https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/dev/api/texts/random"
```

## Integration with Other Modules

### Dependencies

None (standalone service)

### Used By

1. **Module 14 - API Gateway**: JWT authorizer configuration
2. **Module 19 - Frontend**: Authentication flow
3. **Module 12 - Lambda**: User context for record operations

## Validation Checklist

- [ ] User Pool is created successfully
- [ ] App client has correct configuration
- [ ] Hosted UI domain is available
- [ ] Users can sign up successfully
- [ ] Email verification works (or auto-confirm in dev)
- [ ] Users can sign in and get JWT tokens
- [ ] JWT tokens are valid (check with jwt.io)
- [ ] API Gateway validates JWT tokens correctly
- [ ] Password policy enforced
- [ ] Token refresh works

## Cost Estimation

### Cognito Costs

- **Free Tier**: 50,000 MAUs (Monthly Active Users)
- **Above Free Tier**: $0.0055/MAU
- **Dev Usage**: ~100 users = FREE
- **SMS MFA**: $0.00645/SMS (if enabled)
- **Total**: **$0.00** (within free tier)

## Troubleshooting

### Issue: JWT validation fails in API Gateway

```powershell
# Verify issuer URL matches
# Format: https://cognito-idp.{region}.amazonaws.com/{userPoolId}
aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID

# Verify App Client ID in API Gateway authorizer
aws apigatewayv2 get-authorizer --api-id <api-id> --authorizer-id <authorizer-id>

# Decode JWT token to check issuer and audience
# Use jwt.io or:
$TOKEN_PAYLOAD = $ID_TOKEN.Split('.')[1]
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($TOKEN_PAYLOAD))
```

### Issue: Users not receiving verification emails

```powershell
# Check email configuration
aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID

# Verify email delivery in CloudWatch Logs
aws logs tail /aws/cognito/userpools/$USER_POOL_ID --follow

# Use auto-confirm for dev (pre-signup Lambda trigger)
# Or manually confirm users:
aws cognito-idp admin-confirm-sign-up `
  --user-pool-id $USER_POOL_ID `
  --username user@example.com
```

### Issue: Sign-up fails with password policy error

```powershell
# Check password policy
aws cognito-idp describe-user-pool `
  --user-pool-id $USER_POOL_ID `
  --query "UserPool.Policies.PasswordPolicy"

# Ensure password meets requirements:
# - At least 8 characters
# - Contains uppercase, lowercase, numbers
# Example valid password: "Test@1234"
```

## References

- [Cognito User Pools Documentation](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [JWT with API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html)
- [Cognito Hosted UI](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-app-integration.html)
- [Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html)

## Next Steps

After deploying Cognito:

1. Update API Gateway JWT authorizer with Cognito details (Step 14)
2. Integrate frontend authentication (Step 19)
3. Test sign-up/sign-in flow end-to-end
4. Add social identity providers (Google, Facebook) if needed
5. Configure SES for email sending in production
6. Enable MFA for production security
