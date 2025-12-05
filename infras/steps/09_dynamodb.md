# Step 09: DynamoDB Table for Text Storage

## Status: COMPLETED

**Completion Time:** November 23, 2025

## Terraform Module: `modules/09-dynamodb`

## Overview

Create a DynamoDB table for the Text Service to store typing test texts. Configured with on-demand billing for cost-effective dev usage and encryption at rest.

## Architecture Reference

From `architecture-diagram.md`:

- **Purpose**: Store typing test texts and metadata
- **Billing**: On-demand (pay per request)
- **Cost**: ~$1-2/month (minimal dev usage)
- **Access**: Text Service Lambda via DynamoDB Gateway endpoint (free)
- **Network**: Accessed privately via VPC Gateway endpoint

## Components to Implement

### 1. DynamoDB Table

- [ ] **Table Name**: `typerush-dev-texts`
- [ ] **Billing Mode**: PAY_PER_REQUEST (on-demand)
- [ ] **Encryption**: Enabled with AWS-managed key
- [ ] **Point-in-Time Recovery**: Disabled (dev, enable in prod)
- [ ] **Deletion Protection**: Disabled (dev, enable in prod)
- [ ] **Stream**: Disabled (not needed for this use case)
- [ ] **Table Class**: STANDARD (not infrequent access)

### 2. Primary Key Structure

- [ ] **Partition Key**: `text_id` (String, UUID)
- [ ] **Sort Key**: None (simple key schema)
- [ ] **Rationale**: Direct access by text_id, no range queries needed

### 3. Attributes

```
text_id: String (UUID, Primary Key)
content: String (the typing text, 200-500 chars)
difficulty: String ("easy" | "medium" | "hard")
language: String ("en", "es", "fr", etc.)
category: String ("programming", "literature", "general", etc.)
source: String ("ai_generated" | "curated" | "user_submitted")
length: Number (character count)
word_count: Number (word count)
created_at: String (ISO 8601 timestamp)
created_by: String ("bedrock" | "admin" | user_id)
usage_count: Number (times used in games)
avg_wpm: Number (average WPM for this text)
tags: List<String> (searchable tags)
```

### 4. Global Secondary Indexes (GSI)

#### GSI 1: Query by Difficulty and Language

- [ ] **Index Name**: `difficulty-language-index`
- [ ] **Partition Key**: `difficulty` (String)
- [ ] **Sort Key**: `language` (String)
- [ ] **Projection Type**: ALL (include all attributes)
- [ ] **Purpose**: Quickly fetch texts by difficulty for specific language
- [ ] **Query Pattern**: "Get all medium texts in English"

#### GSI 2: Query by Category

- [ ] **Index Name**: `category-created-index`
- [ ] **Partition Key**: `category` (String)
- [ ] **Sort Key**: `created_at` (String)
- [ ] **Projection Type**: ALL
- [ ] **Purpose**: Browse texts by category, sorted by recency
- [ ] **Query Pattern**: "Get latest programming texts"

### 5. TTL Configuration

- [ ] **TTL Attribute**: `expires_at` (Number, Unix timestamp)
- [ ] **Purpose**: Auto-delete AI-generated texts after 90 days
- [ ] **Benefit**: Keep table size small, reduce storage costs

### 6. Tags and Encryption

- [ ] **Tags**: Project, Environment, Purpose
- [ ] **Encryption**: Server-side encryption with AWS-managed key (default)
- [ ] **KMS Key**: Default `aws/dynamodb` (free)

## Sample Data Structure

### Example Text Item

```json
{
  "text_id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the English alphabet at least once.",
  "difficulty": "easy",
  "language": "en",
  "category": "general",
  "source": "curated",
  "length": 123,
  "word_count": 19,
  "created_at": "2025-11-23T10:30:00Z",
  "created_by": "admin",
  "usage_count": 45,
  "avg_wpm": 62.5,
  "tags": ["pangram", "beginner-friendly"],
  "expires_at": null
}
```

### AI-Generated Text (with TTL)

```json
{
  "text_id": "660e8400-e29b-41d4-a716-446655440001",
  "content": "In the realm of cloud computing, serverless architectures have revolutionized how developers build and deploy applications...",
  "difficulty": "hard",
  "language": "en",
  "category": "programming",
  "source": "ai_generated",
  "length": 342,
  "word_count": 56,
  "created_at": "2025-11-23T12:00:00Z",
  "created_by": "bedrock",
  "usage_count": 2,
  "avg_wpm": 48.3,
  "tags": ["cloud", "serverless", "technical"],
  "expires_at": 1740308400
}
```

## Implementation Details

### Terraform Configuration

```hcl
resource "aws_dynamodb_table" "texts" {
  name         = "${var.project_name}-${var.environment}-texts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "text_id"

  # Primary key attribute
  attribute {
    name = "text_id"
    type = "S"
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
  global_secondary_index {
    name            = "difficulty-language-index"
    hash_key        = "difficulty"
    range_key       = "language"
    projection_type = "ALL"
  }

  # GSI 2: Query by category
  global_secondary_index {
    name            = "category-created-index"
    hash_key        = "category"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # TTL configuration
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Encryption
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery (optional for dev)
  point_in_time_recovery {
    enabled = false
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-texts"
      Purpose = "Typing test text storage"
    }
  )
}
```

## Module Structure

```
modules/17-dynamodb/
├── main.tf       # DynamoDB table with GSIs
├── variables.tf  # Table name, billing mode
└── outputs.tf    # Table name, ARN, stream ARN
```

## Dependencies

- **Required**: None (DynamoDB is serverless, no VPC dependencies)
- **Recommended**: Deploy after VPC endpoints (use Gateway endpoint)

## Deployment

```powershell
# Deploy DynamoDB table (takes ~1-2 minutes)
terraform apply -var-file="env\dev.tfvars.local" -target=module.dynamodb
```

## Validation Commands

```powershell
# Describe table
aws dynamodb describe-table --table-name typerush-dev-texts

# List tables
aws dynamodb list-tables

# Get table ARN
$TABLE_ARN = terraform output -raw dynamodb_texts_table_arn

# Put sample item
aws dynamodb put-item --table-name typerush-dev-texts `
  --item '{
    "text_id": {"S": "test-123"},
    "content": {"S": "Sample typing test text"},
    "difficulty": {"S": "easy"},
    "language": {"S": "en"},
    "category": {"S": "general"},
    "source": {"S": "curated"},
    "length": {"N": "25"},
    "word_count": {"N": "4"},
    "created_at": {"S": "2025-11-23T10:00:00Z"},
    "created_by": {"S": "admin"},
    "usage_count": {"N": "0"},
    "tags": {"L": [{"S": "test"}]}
  }'

# Get item
aws dynamodb get-item --table-name typerush-dev-texts `
  --key '{"text_id": {"S": "test-123"}}'

# Query by difficulty (using GSI 1)
aws dynamodb query --table-name typerush-dev-texts `
  --index-name difficulty-language-index `
  --key-condition-expression "difficulty = :diff AND language = :lang" `
  --expression-attribute-values '{":diff": {"S": "easy"}, ":lang": {"S": "en"}}'

# Scan table (use sparingly!)
aws dynamodb scan --table-name typerush-dev-texts --max-items 10
```

## Cost Impact

**$1.25-2.00/month** (estimated for dev)

### On-Demand Pricing Breakdown

- **Write Requests**: $1.25 per million write request units
  - Dev usage: ~10,000 writes/month = $0.01
- **Read Requests**: $0.25 per million read request units
  - Dev usage: ~100,000 reads/month = $0.03
- **Storage**: $0.25 per GB-month
  - Dev usage: ~500 texts × 0.5 KB = 0.25 MB = $0.01
- **GSI Storage**: Same as base table
  - 2 GSIs × 0.25 MB = $0.01
- **Data Transfer**: FREE (within VPC via Gateway endpoint)

**Total Dev**: ~$0.06-0.50/month (minimal usage)
**4-day demo**: < $0.10

### Provisioned vs On-Demand

```
On-Demand (Dev):   $0.06-0.50/month (unpredictable usage)
Provisioned (Prod): $13/month (1 RCU + 1 WCU + storage)
```

## Query Patterns

### 1. Get Random Text by Difficulty

```python
# Lambda function: Text Service
import boto3
import random

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('typerush-dev-texts')

response = table.query(
    IndexName='difficulty-language-index',
    KeyConditionExpression='difficulty = :diff AND language = :lang',
    ExpressionAttributeValues={
        ':diff': 'medium',
        ':lang': 'en'
    }
)

# Select random text
texts = response['Items']
random_text = random.choice(texts) if texts else None
```

### 2. Get Latest Texts in Category

```python
response = table.query(
    IndexName='category-created-index',
    KeyConditionExpression='category = :cat',
    ExpressionAttributeValues={
        ':cat': 'programming'
    },
    ScanIndexForward=False,  # Descending order (newest first)
    Limit=10
)
```

### 3. Update Usage Statistics

```python
table.update_item(
    Key={'text_id': 'text-uuid-123'},
    UpdateExpression='SET usage_count = usage_count + :inc, avg_wpm = :wpm',
    ExpressionAttributeValues={
        ':inc': 1,
        ':wpm': 65.4
    }
)
```

### 4. Batch Get Texts

```python
response = dynamodb.batch_get_item(
    RequestItems={
        'typerush-dev-texts': {
            'Keys': [
                {'text_id': 'uuid-1'},
                {'text_id': 'uuid-2'},
                {'text_id': 'uuid-3'}
            ]
        }
    }
)
```

## Security Considerations

### ✅ Access Control

- **Text Service Lambda IAM Role**: Full DynamoDB CRUD on texts table
- **Game Service ECS**: No direct DynamoDB access (calls Lambda)
- **Record Service Lambda**: No DynamoDB access

### ✅ Encryption

- **At Rest**: AWS-managed key (aws/dynamodb)
- **In Transit**: HTTPS enforced by SDK
- **VPC Endpoint**: Private communication via DynamoDB Gateway endpoint

### ✅ Data Validation

- Text content: Max 1000 characters
- Difficulty: Enum validation in Lambda
- Language: ISO 639-1 code validation
- Source: Enum validation

## Monitoring and Alerting

### CloudWatch Metrics

- [ ] ConsumedReadCapacityUnits (track usage)
- [ ] ConsumedWriteCapacityUnits (track usage)
- [ ] UserErrors > 10 per minute (application bugs)
- [ ] SystemErrors > 0 (AWS issues)
- [ ] ThrottledRequests > 0 (rate limiting)

### Cost Anomaly Detection

- [ ] Set up AWS Cost Anomaly Detection for DynamoDB
- [ ] Alert if daily cost > $1 (unusual for dev)

## Testing Plan

1. [ ] Deploy DynamoDB table with GSIs
2. [ ] Verify table status is ACTIVE
3. [ ] Verify GSIs status is ACTIVE
4. [ ] Test PutItem operation
5. [ ] Test GetItem operation
6. [ ] Test Query on GSI 1 (difficulty-language)
7. [ ] Test Query on GSI 2 (category-created)
8. [ ] Test UpdateItem (usage statistics)
9. [ ] Test BatchGetItem (multiple texts)
10. [ ] Test TTL expiration (set item with past expires_at)
11. [ ] Verify encryption at rest
12. [ ] Test access via DynamoDB Gateway endpoint from Lambda

## Data Seeding

### Initial Text Collection (Admin Script)

```python
# Seed 50 curated texts
texts = [
    {
        "text_id": str(uuid.uuid4()),
        "content": "...",
        "difficulty": "easy",
        "language": "en",
        "category": "general",
        "source": "curated",
        # ... other attributes
    }
    # ... 49 more texts
]

# Batch write
with table.batch_writer() as batch:
    for text in texts:
        batch.put_item(Item=text)
```

### AI-Generated Texts (Text Service Lambda)

```python
# Call Bedrock to generate text
bedrock = boto3.client('bedrock-runtime')
response = bedrock.invoke_model(
    modelId='anthropic.claude-3-haiku-20240307-v1:0',
    body=json.dumps({
        'prompt': 'Generate a technical typing test about {topic}',
        'max_tokens': 200
    })
)

# Store in DynamoDB with TTL
text_item = {
    'text_id': str(uuid.uuid4()),
    'content': generated_text,
    'source': 'ai_generated',
    'expires_at': int(time.time()) + (90 * 24 * 3600)  # 90 days
    # ... other attributes
}

table.put_item(Item=text_item)
```

## Rollback Plan

```powershell
# Export table data before deletion
aws dynamodb scan --table-name typerush-dev-texts > texts-backup.json

# Destroy DynamoDB table
terraform destroy -target=module.dynamodb

# Restore from backup if needed
# (Requires script to convert scan output to batch-write format)
```

## Next Step

Proceed to [Step 10: ECR Repositories](./10_ecr_repositories.md)
