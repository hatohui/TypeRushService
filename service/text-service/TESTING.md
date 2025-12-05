# Testing Guide - Typing Practice Text Service API

## Prerequisites

Make sure all dependencies are installed:

```bash
pip install -r requirements.txt
```

## Method 1: Start the Server

### Option A: Using Uvicorn directly
```bash
# Development mode with auto-reload
uvicorn lambda_handler:app --reload --host 0.0.0.0 --port 8000

# Production mode
uvicorn lambda_handler:app --host 0.0.0.0 --port 8000 --workers 4
```

### Option B: Using Docker Compose
```bash
# Start the FastAPI container (reads .env for AWS details)
docker compose up --build

# Stop services
docker compose down
```

### Option C: Using Python directly
```bash
python3 -m uvicorn lambda_handler:app --reload
```

## Method 2: Interactive API Documentation

Once the server is running, open your browser:

1. **Swagger UI**: http://localhost:8000/docs
   - Interactive API documentation
   - Test endpoints directly in browser
   - See request/response schemas

2. **ReDoc**: http://localhost:8000/redoc
   - Alternative documentation view
   - Clean, organized layout

## Method 3: Using the Test Script

```bash
# Start the server first (in one terminal)
uvicorn lambda_handler:app --reload

# Run tests (in another terminal)
python3 test_api.py
```

## Method 4: Manual Testing with cURL

### Test Health Check
```bash
curl http://localhost:8000/
```

### Type 1: Generate Random Words (DynamoDB)
```bash
curl -X POST http://localhost:8000/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 1, "count": 10}'
```

### Type 2: Generate Sentences (DynamoDB)
```bash
curl -X POST http://localhost:8000/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 2, "count": 15}'
```

### Type 3: Generate Bedrock Paragraphs
```bash
curl -X POST http://localhost:8000/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 3, "count": 1}'
```

### Test Invalid Type (Should return 400 error)
```bash
curl -X POST http://localhost:8000/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 99, "count": 5}'
```

## Method 5: Using Python Requests

```python
import requests

# Health check
response = requests.get("http://localhost:8000/")
print(response.json())

# Generate text
payload = {"type": 1, "count": 10}
response = requests.post(
    "http://localhost:8000/api/generate-text",
    json=payload
)
print(response.json())
```

## Method 6: Using Postman or Thunder Client (VS Code)

### Import Collection:
1. Create a new collection
2. Add requests for each endpoint
3. Set base URL: `http://localhost:8000`

### Example Request:
- **Method**: POST
- **URL**: `http://localhost:8000/api/generate-text`
- **Headers**: `Content-Type: application/json`
- **Body** (JSON):
```json
{
  "type": 1,
  "count": 10
}
```

## Expected Response Format

### Success Response:
```json
{
  "type": 1,
  "count": 10,
  "text": "apple banana cherry date elderberry fig grape honeydew kiwi lemon",
  "taken": 45.23
}
```

### Error Response:
```json
{
  "detail": "Invalid type. Use 1 (words), 2 (sentences), or 3 (Bedrock paragraphs)."
}
```

## Text Generation Types

| Type | Source | Description | Count Meaning |
|------|--------|-------------|---------------|
| 1 | DynamoDB cached words | Random words | Number of words |
| 2 | DynamoDB cached sentences | Random sentences | Words per sentence (1-3 supported) |
| 3 | Bedrock Agent runtime | AI paragraphs | Count is unused placeholder |

## Performance Metrics

The API returns execution time (`taken` field) in milliseconds:
- Type 1 (Dynamo words): ~50-150ms (depending on cache hits)
- Type 2 (Dynamo sentence): ~60-200ms
- Type 3 (Bedrock): ~400-1500ms (LLM generation)

## Troubleshooting

### Server won't start
```bash
# Check if port 8000 is already in use
lsof -i :8000

# Kill process if needed
kill -9 <PID>

# Or use a different port
uvicorn lambda_handler:app --port 8001
```

### DynamoDB/Bedrock issues
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check DynamoDB contents quickly
aws dynamodb scan --table-name <TABLE_NAME> --max-items 5

# Ensure Bedrock agent is reachable
aws bedrock-agent get-agent --agent-id <AGENT_ID>
```

### Module not found errors
```bash
# Install missing packages
pip install fastapi uvicorn boto3 requests pydantic pydantic-settings
```

## Load Testing (Optional)

Using Apache Bench:
```bash
# 100 requests, 10 concurrent
ab -n 100 -c 10 -p payload.json -T application/json http://localhost:8000/api/generate-text
```

Using Python:
```bash
pip install locust
locust -f load_test.py
```

## Next Steps

1. ✅ Test all 3 Lambda generation types
2. ✅ Verify AWS credentials and Lambda access
3. ✅ Check API response times
4. ✅ Test error handling
5. ✅ Review API documentation at /docs
