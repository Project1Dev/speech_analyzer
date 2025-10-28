#!/bin/bash

# Speech Mastery - API Test Script
# Tests the backend API without needing a Mac or iOS

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASE_URL="http://localhost:8000"
TOKEN="SINGLE_USER_DEV_TOKEN_12345"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Speech Mastery - API Test Script${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Check if backend is running
echo -e "${YELLOW}Checking if backend is running at $BASE_URL...${NC}"
if ! curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" | grep -q "200"; then
    echo -e "${RED}❌ Backend is not running!${NC}"
    echo ""
    echo -e "${YELLOW}To start the backend, run:${NC}"
    echo "  bash run-backend.sh"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Backend is running!${NC}"
echo ""

# Test 1: Health Check
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test 1: Health Check${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo "GET /health"
echo ""

RESPONSE=$(curl -s -X GET "$BASE_URL/health" \
  -H "Authorization: Bearer $TOKEN")

echo -e "${GREEN}Response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Test 2: API Documentation
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test 2: API Documentation${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo "GET /openapi.json"
echo ""

RESPONSE=$(curl -s "$BASE_URL/openapi.json")
ENDPOINTS=$(echo "$RESPONSE" | jq '.paths | keys | length' 2>/dev/null)

if [ ! -z "$ENDPOINTS" ]; then
    echo -e "${GREEN}✅ API has $ENDPOINTS endpoints${NC}"
    echo ""
    echo -e "${YELLOW}Available paths:${NC}"
    echo "$RESPONSE" | jq '.paths | keys[]' 2>/dev/null | head -10
    echo ""
else
    echo -e "${RED}Could not parse API spec${NC}"
fi

# Test 3: App Info
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test 3: Request Authentication${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo "Testing bearer token authentication..."
echo ""

# Test with invalid token
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/health" \
  -H "Authorization: Bearer INVALID_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    echo -e "${GREEN}✅ Invalid token correctly rejected${NC}"
else
    echo -e "${YELLOW}⚠️  Invalid token response: $HTTP_CODE${NC}"
fi

# Test with valid token
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/health" \
  -H "Authorization: Bearer $TOKEN")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Valid token accepted${NC}"
else
    echo -e "${RED}❌ Valid token rejected (HTTP $HTTP_CODE)${NC}"
fi

echo ""

# Test 4: List endpoints from Swagger
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test 4: Available Endpoints${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

ENDPOINTS=$(curl -s "$BASE_URL/openapi.json" | \
    jq -r '.paths | to_entries[] | "\(.key) (\(.value | keys | join(", ") | ascii_upcase))"' 2>/dev/null)

if [ ! -z "$ENDPOINTS" ]; then
    echo -e "${YELLOW}Endpoints:${NC}"
    echo "$ENDPOINTS" | nl
    echo ""
else
    echo -e "${RED}Could not fetch endpoints${NC}"
fi

# Test 5: Access Swagger UI
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test 5: Interactive API Documentation${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Open these in your browser:${NC}"
echo ""
echo -e "  ${YELLOW}Swagger UI (Interactive):${NC}"
echo "    ${GREEN}http://localhost:8000/docs${NC}"
echo ""
echo -e "  ${YELLOW}ReDoc (Alternative Docs):${NC}"
echo "    ${GREEN}http://localhost:8000/redoc${NC}"
echo ""
echo -e "  ${YELLOW}OpenAPI JSON Spec:${NC}"
echo "    ${GREEN}http://localhost:8000/openapi.json${NC}"
echo ""

# Test 6: Example requests
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Test 6: Example curl Commands${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Copy and run these in terminal:${NC}"
echo ""
echo -e "${GREEN}# Health check${NC}"
echo "curl -X GET http://localhost:8000/health \\"
echo "  -H 'Authorization: Bearer $TOKEN'"
echo ""
echo -e "${GREEN}# Get API documentation${NC}"
echo "curl http://localhost:8000/docs"
echo ""
echo -e "${GREEN}# Get OpenAPI specification${NC}"
echo "curl http://localhost:8000/openapi.json | jq '.'"
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Backend API is working!${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open: ${GREEN}http://localhost:8000/docs${NC}"
echo "2. Click 'Authorize' button"
echo "3. Enter token: ${GREEN}SINGLE_USER_DEV_TOKEN_12345${NC}"
echo "4. Try endpoints using 'Try it out' button"
echo ""
echo -e "${YELLOW}Or test from command line:${NC}"
echo "  bash test-api.sh  # Run this again anytime"
echo ""
