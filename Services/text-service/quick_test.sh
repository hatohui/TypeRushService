#!/bin/bash
# Quick Test Script for Typing Practice Text Service API

echo "🚀 Testing Typing Practice Text Service API"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8000"

# Test 1: Health Check
echo -e "${BLUE}Test 1: Health Check${NC}"
curl -s $BASE_URL/ | jq '.'
echo ""
echo ""

# Test 2: Type 1 - Words from DynamoDB cache
echo -e "${BLUE}Test 2: Generate 10 Words from DynamoDB cache${NC}"
curl -s -X POST $BASE_URL/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 1, "count": 10}' | jq '.'
echo ""
echo ""

# Test 3: Type 2 - Sentences from DynamoDB cache
echo -e "${BLUE}Test 3: Generate 15-word Sentence from DynamoDB cache${NC}"
curl -s -X POST $BASE_URL/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 2, "count": 15}' | jq '.'
echo ""
echo ""

# Test 4: Type 3 - Bedrock paragraphs
echo -e "${BLUE}Test 4: Generate paragraphs from Bedrock${NC}"
curl -s -X POST $BASE_URL/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 3, "count": 1}' | jq '.'
echo ""
echo ""

# Test 5: Invalid Type (should fail)
echo -e "${BLUE}Test 5: Invalid Type (Expected to Fail)${NC}"
curl -s -X POST $BASE_URL/api/generate-text \
  -H "Content-Type: application/json" \
  -d '{"type": 99, "count": 5}' | jq '.'
echo ""
echo ""

echo -e "${GREEN}✅ All tests completed!${NC}"
echo ""
echo "📖 View interactive docs at: http://localhost:8000/docs"
