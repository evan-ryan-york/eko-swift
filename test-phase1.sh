#!/bin/bash

# Phase 1 Testing Script for Lyra Feature
# This script tests the Supabase backend without needing Docker

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Supabase configuration (from Config.swift)
SUPABASE_URL="https://fqecsmwycvltpnqawtod.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZWNzbXd5Y3ZsdHBucWF3dG9kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxMDM1MTQsImV4cCI6MjA3NTY3OTUxNH0.D_uwSowG3mHmwmzSD8Ahq8cP0BXCW0XWzs3_qE8XeZQ"

# Test user credentials
TEST_EMAIL="test@eko.app"
TEST_PASSWORD="testpassword123"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Lyra Phase 1 Testing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# Step 1: Sign up test user (or sign in if exists)
# ============================================================================

echo -e "${YELLOW}Step 1: Authenticating test user...${NC}"

SIGNUP_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/signup" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\"
  }")

# Check if signup failed (user might already exist)
if echo "$SIGNUP_RESPONSE" | grep -q "error"; then
  echo -e "${YELLOW}  User might already exist, trying sign in...${NC}"

  AUTH_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"email\": \"${TEST_EMAIL}\",
      \"password\": \"${TEST_PASSWORD}\"
    }")
else
  AUTH_RESPONSE="$SIGNUP_RESPONSE"
fi

# Extract access token
ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
USER_ID=$(echo "$AUTH_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo -e "${RED}✗ Failed to authenticate${NC}"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✓ Authenticated successfully${NC}"
echo -e "  User ID: ${USER_ID}"
echo ""

# ============================================================================
# Step 2: Create test child
# ============================================================================

echo -e "${YELLOW}Step 2: Creating test child...${NC}"

CHILD_ID="11111111-1111-1111-1111-111111111111"

CREATE_CHILD=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/children" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"id\": \"${CHILD_ID}\",
    \"name\": \"Emma\",
    \"age\": 8,
    \"temperament\": \"sensitive\",
    \"temperament_talkative\": 6,
    \"temperament_sensitivity\": 9,
    \"temperament_accountability\": 7
  }")

if echo "$CREATE_CHILD" | grep -q "error"; then
  echo -e "${YELLOW}  Child might already exist (this is okay)${NC}"
else
  echo -e "${GREEN}✓ Test child created: Emma (age 8, sensitive)${NC}"
fi
echo ""

# ============================================================================
# Step 3: Test create-conversation
# ============================================================================

echo -e "${YELLOW}Step 3: Testing create-conversation endpoint...${NC}"

CONVERSATION=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/create-conversation" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"childId\": \"${CHILD_ID}\"
  }")

CONVERSATION_ID=$(echo "$CONVERSATION" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$CONVERSATION_ID" ]; then
  echo -e "${RED}✗ Failed to create conversation${NC}"
  echo "$CONVERSATION"
  exit 1
fi

echo -e "${GREEN}✓ Conversation created${NC}"
echo -e "  Conversation ID: ${CONVERSATION_ID}"
echo ""

# ============================================================================
# Step 4: Test send-message (requires OpenAI API key)
# ============================================================================

echo -e "${YELLOW}Step 4: Testing send-message endpoint...${NC}"
echo -e "${YELLOW}  Note: This requires OpenAI API key to be set in Supabase secrets${NC}"

MESSAGE_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/send-message" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  --no-buffer \
  -d "{
    \"conversationId\": \"${CONVERSATION_ID}\",
    \"message\": \"My child is having trouble going to bed on time. What should I do?\",
    \"childId\": \"${CHILD_ID}\"
  }" 2>&1 | head -20)

if echo "$MESSAGE_RESPONSE" | grep -q "error"; then
  echo -e "${RED}✗ Message endpoint failed (likely missing OpenAI API key)${NC}"
  echo "$MESSAGE_RESPONSE"
  echo -e "${YELLOW}  To fix: Set OpenAI API key in Supabase dashboard > Edge Functions > Secrets${NC}"
else
  echo -e "${GREEN}✓ Message sent successfully (streaming response)${NC}"
  echo "  First few lines:"
  echo "$MESSAGE_RESPONSE"
fi
echo ""

# ============================================================================
# Step 5: Test complete-conversation
# ============================================================================

echo -e "${YELLOW}Step 5: Testing complete-conversation endpoint...${NC}"

COMPLETE_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/complete-conversation" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"conversationId\": \"${CONVERSATION_ID}\"
  }")

if echo "$COMPLETE_RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✓ Conversation completed successfully${NC}"
  echo "$COMPLETE_RESPONSE" | jq '.' 2>/dev/null || echo "$COMPLETE_RESPONSE"
else
  echo -e "${RED}✗ Failed to complete conversation${NC}"
  echo "$COMPLETE_RESPONSE"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Phase 1 Testing Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. View your data in Supabase Dashboard:"
echo "   https://supabase.com/dashboard/project/fqecsmwycvltpnqawtod/editor"
echo ""
echo "2. Set OpenAI API key for full functionality:"
echo "   https://supabase.com/dashboard/project/fqecsmwycvltpnqawtod/settings/vault"
echo "   Secret name: OPENAI_API_KEY"
echo ""
echo "3. Test credentials:"
echo "   Email: ${TEST_EMAIL}"
echo "   Password: ${TEST_PASSWORD}"
echo "   Child ID: ${CHILD_ID}"
echo "   Conversation ID: ${CONVERSATION_ID}"
echo ""
echo -e "${GREEN}Ready to proceed to Phase 2: iOS Implementation!${NC}"
echo ""
