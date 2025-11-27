# ==================================
# DynamoDB Table for Text Service
# ==================================

# DynamoDB table for storing typing test texts
resource "aws_dynamodb_table" "texts" {
  name         = "${var.project_name}-${var.environment}-texts"
  billing_mode = "PAY_PER_REQUEST" # On-demand billing for dev

  # Primary key
  hash_key = "text_id"

  # Primary key attribute definition
  attribute {
    name = "text_id"
    type = "S" # String
  }

  # GSI 1 attributes
  attribute {
    name = "difficulty"
    type = "S"
  }

  attribute {
    name = "language"
    type = "S"
  }

  # GSI 2 attributes
  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  # GSI 1: Query by difficulty and language
  # Query pattern: "Get all medium texts in English"
  global_secondary_index {
    name            = "difficulty-language-index"
    hash_key        = "difficulty"
    range_key       = "language"
    projection_type = "ALL"
  }

  # GSI 2: Query by category
  # Query pattern: "Get latest programming texts"
  global_secondary_index {
    name            = "category-created-index"
    hash_key        = "category"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # TTL configuration for auto-deletion
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Server-side encryption with AWS-managed key
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery (disabled for dev)
  point_in_time_recovery {
    enabled = false
  }

  # Deletion protection (disabled for dev)
  deletion_protection_enabled = false

  # Table class
  table_class = "STANDARD"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-texts"
      Purpose = "Typing test text storage"
    }
  )
}
