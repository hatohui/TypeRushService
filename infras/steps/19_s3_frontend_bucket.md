# Step 19: S3 Frontend Bucket

## Status: IMPLEMENTED (Not Applied)

## Completed: 2025-11-23

## Terraform Module: `modules/04-s3`

## Overview

Create an Amazon S3 bucket to host static frontend files (HTML, CSS, JavaScript, images) served via CloudFront CDN.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: Static website hosting for React/Vue/Angular frontend
- **Access**: CloudFront Origin Access Control (OAC) only
- **Deployment**: CodePipeline uploads built frontend files
- **Cost**: ~$0.50/month (10GB storage + minimal requests)

## Components to Implement

### 1. S3 Bucket

- [ ] **Bucket Name**: `typerush-dev-frontend` (must be globally unique)
- [ ] **Region**: ap-southeast-1
- [ ] **Public Access**: Blocked (access via CloudFront only)
- [ ] **Versioning**: Disabled (dev cost optimization)
- [ ] **Encryption**: AES256 (SSE-S3)

### 2. Bucket Policy

- [ ] **CloudFront OAC**: Allow GetObject from CloudFront only
- [ ] **CodePipeline**: Allow PutObject for deployments
- [ ] **Public Access**: Deny all direct public access

### 3. Lifecycle Rules

- [ ] **Old Versions**: Delete after 7 days (if versioning enabled)
- [ ] **Incomplete Multipart Uploads**: Abort after 1 day

### 4. Static Website Hosting (Optional)

- [ ] **Enabled**: No (using CloudFront, not S3 website endpoint)
- [ ] **Index Document**: index.html
- [ ] **Error Document**: index.html (SPA routing)

## Implementation Details

### Terraform Configuration

```hcl
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.environment}-frontend"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-frontend"
      Purpose = "Static website hosting"
    }
  )
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rule
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Bucket policy for CloudFront OAC
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      },
      {
        Sid    = "AllowCodePipelineUpload"
        Effect = "Allow"
        Principal = {
          AWS = var.codepipeline_role_arn
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      }
    ]
  })
}

output "bucket_name" {
  value = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
}
```

## Deployment Steps

```powershell
terraform apply -target=module.s3 -var-file="env/dev.tfvars.local"

# Upload sample index.html for testing
echo "<h1>TypeRush</h1>" > index.html
aws s3 cp index.html s3://typerush-dev-frontend/

# Test via CloudFront (after CloudFront setup)
curl https://<cloudfront-domain>/
```

## Cost Estimation

- **Storage**: $0.023/GB × 10GB = $0.23
- **Requests**: $0.0004/1K GET × 100K = $0.04
- **Data Transfer to CloudFront**: FREE
- **Total**: ~$0.27/month

## References

- [S3 Documentation](https://docs.aws.amazon.com/s3/)
- [CloudFront OAC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)

## Next Steps

1. Deploy frontend application code
2. Configure CodePipeline for auto-deployment (Step 21)
3. Test CloudFront distribution serves frontend correctly
