# Lyra Feature Testing Guide

This guide walks through testing the Lyra database schema and Edge Functions.

## Prerequisites

1. **Supabase CLI installed:**
   ```bash
   brew install supabase/tap/supabase
   ```

2. **OpenAI API Key:**
   - Get from: https://platform.openai.com/api-keys
   - Set as environment variable: `export OPENAI_API_KEY=sk-...`

3. **Local Supabase running:**
   ```bash
   cd /Users/ryanyork/Software/Eko/Eko
   supabase start
   ```

---

## Phase 1: Database Migration Testing

### 1.1 Apply Migration

```bash
# Reset database (if needed)
supabase db reset

# Or just apply new migration
supabase migration up
```

### 1.2 Verify Tables Created

```sql
-- Connect to local database
psql postgresql://postgres:postgres@localhost:54322/postgres

-- List all Lyra tables
\dt

-- Should see:
-- conversations
-- messages
-- child_memory
-- children (already exists, but enhanced)

-- Check conversations schema
\d conversations

-- Check messages schema
\d messages

-- Check child_memory schema
\d child_memory

-- Verify children table has new columns
\d children
-- Should see: temperament_talkative, temperament_sensitivity, temperament_accountability
```

### 1.3 Test Row Level Security (RLS)

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('conversations', 'messages', 'child_memory');

-- Should return rowsecurity = true for all

-- Check policies exist
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public';

-- Should see policies like:
-- "Users can view their own conversations"
-- "Users can view messages in their conversations"
-- etc.
```

### 1.4 Test Helper Functions

```sql
-- Test get_or_create_child_memory function
-- (Requires existing child - create one first if needed)

-- Insert test child
INSERT INTO children (id, user_id, name, age, temperament, temperament_talkative, temperament_sensitivity, temperament_accountability)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  (SELECT id FROM auth.users LIMIT 1),
  'Test Child',
  8,
  'easygoing',
  7,
  5,
  6
);

-- Test helper function
SELECT get_or_create_child_memory('11111111-1111-1111-1111-111111111111');

-- Verify memory record created
SELECT * FROM child_memory WHERE child_id = '11111111-1111-1111-1111-111111111111';
```

### 1.5 Test Triggers

```sql
-- Test updated_at trigger on conversations
INSERT INTO conversations (user_id, child_id, status)
VALUES (
  (SELECT id FROM auth.users LIMIT 1),
  '11111111-1111-1111-1111-111111111111',
  'active'
) RETURNING id, created_at, updated_at;

-- Wait a moment, then update
UPDATE conversations
SET title = 'Test Conversation'
WHERE child_id = '11111111-1111-1111-1111-111111111111'
RETURNING updated_at, created_at;

-- updated_at should be newer than created_at
```

---

## Phase 2: Edge Functions Testing

### 2.1 Deploy Functions Locally

```bash
# Set OpenAI API key as secret
supabase secrets set OPENAI_API_KEY=sk-...

# Serve functions locally
supabase functions serve
```

Functions will be available at: `http://localhost:54321/functions/v1/{function-name}`

### 2.2 Get Test JWT Token

```bash
# Get anon key
supabase status | grep "anon key"

# Or get from Supabase dashboard
# For testing, you can use the anon key directly
# For authenticated requests, you need a user JWT

# Sign up a test user via Supabase dashboard or:
curl -X POST 'http://localhost:54321/auth/v1/signup' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'

# Get JWT from response: response.access_token
```

### 2.3 Test: create-conversation

```bash
# Replace with your actual values
export JWT_TOKEN="your-jwt-token"
export CHILD_ID="11111111-1111-1111-1111-111111111111"

curl -X POST 'http://localhost:54321/functions/v1/create-conversation' \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"childId\": \"$CHILD_ID\"
  }" | jq

# Expected response:
# {
#   "id": "conversation-uuid",
#   "userId": "user-uuid",
#   "childId": "child-uuid",
#   "status": "active",
#   "title": null,
#   "createdAt": "...",
#   "updatedAt": "..."
# }

# Save conversation ID for next tests
export CONVERSATION_ID="returned-conversation-id"
```

### 2.4 Test: send-message (Streaming)

```bash
curl -X POST 'http://localhost:54321/functions/v1/send-message' \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"conversationId\": \"$CONVERSATION_ID\",
    \"message\": \"My child is having trouble going to bed on time. What should I do?\",
    \"childId\": \"$CHILD_ID\"
  }" \
  --no-buffer

# Expected: Streaming response with SSE format
# data: I'd
# data: suggest
# data: creating
# ...

# Check message saved to database
psql postgresql://postgres:postgres@localhost:54322/postgres -c \
  "SELECT role, content FROM messages WHERE conversation_id = '$CONVERSATION_ID' ORDER BY created_at;"
```

### 2.5 Test: complete-conversation

```bash
curl -X POST 'http://localhost:54321/functions/v1/complete-conversation' \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"conversationId\": \"$CONVERSATION_ID\"
  }" | jq

# Expected response:
# {
#   "success": true,
#   "title": "Bedtime routine challenges",
#   "insights": {
#     "behavioral_themes": [...],
#     "communication_strategies": [...],
#     "significant_events": [...]
#   }
# }

# Verify conversation marked complete
psql postgresql://postgres:postgres@localhost:54322/postgres -c \
  "SELECT status, title FROM conversations WHERE id = '$CONVERSATION_ID';"

# Verify memory updated
psql postgresql://postgres:postgres@localhost:54322/postgres -c \
  "SELECT behavioral_themes, communication_strategies FROM child_memory WHERE child_id = '$CHILD_ID';"
```

### 2.6 Test: create-realtime-session

**Note:** This requires a real WebRTC SDP offer from iOS. For basic testing:

```bash
# Mock SDP offer (won't actually work, but tests endpoint)
export MOCK_SDP="v=0\no=- 0 0 IN IP4 127.0.0.1\ns=-\nt=0 0\na=group:BUNDLE 0\na=msid-semantic: WMS\nm=audio 9 UDP/TLS/RTP/SAVPF 111\nc=IN IP4 0.0.0.0\na=rtcp:9 IN IP4 0.0.0.0\na=ice-ufrag:test\na=ice-pwd:test\na=fingerprint:sha-256 00:00:00\na=setup:actpass\na=mid:0\na=sendrecv\na=rtcp-mux"

curl -X POST 'http://localhost:54321/functions/v1/create-realtime-session' \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"sdp\": \"$MOCK_SDP\",
    \"conversationId\": \"$CONVERSATION_ID\",
    \"childId\": \"$CHILD_ID\"
  }" | jq

# This will likely fail with OpenAI error (invalid SDP)
# But confirms endpoint is working and child context is fetched
```

---

## Phase 3: Integration Testing Checklist

### Database
- [x] Migration applies without errors
- [x] All tables created with correct schema
- [x] RLS policies active
- [x] Indexes created
- [x] Triggers working (updated_at)
- [x] Helper functions operational

### create-conversation
- [ ] Creates new conversation successfully
- [ ] Returns existing active conversation if present
- [ ] Validates child belongs to user
- [ ] Creates child_memory record if needed
- [ ] Requires authentication

### send-message
- [ ] Fetches child context correctly
- [ ] Builds personalized system prompt
- [ ] Streams OpenAI responses
- [ ] Saves user message immediately
- [ ] Saves assistant message after stream completes
- [ ] Updates conversation timestamp
- [ ] Handles network errors gracefully

### complete-conversation
- [ ] Generates appropriate conversation title
- [ ] Extracts behavioral themes
- [ ] Extracts communication strategies
- [ ] Extracts significant events
- [ ] Updates child_memory correctly
- [ ] Marks conversation as completed
- [ ] Handles already-completed conversations

### create-realtime-session
- [ ] Fetches child context
- [ ] Builds voice instructions
- [ ] Configures OpenAI Realtime API
- [ ] Returns valid SDP answer (with real iOS SDP)
- [ ] Handles authentication

---

## Phase 4: Performance Testing

### Load Testing send-message

```bash
# Install Apache Bench
brew install ab

# Test endpoint (replace with real values)
ab -n 10 -c 2 \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -p test-payload.json \
  http://localhost:54321/functions/v1/send-message

# Create test-payload.json:
# {
#   "conversationId": "uuid",
#   "message": "Test message",
#   "childId": "uuid"
# }
```

### Database Query Performance

```sql
-- Test conversation query performance
EXPLAIN ANALYZE
SELECT * FROM conversations
WHERE user_id = 'some-uuid' AND child_id = 'some-uuid' AND status = 'active'
ORDER BY updated_at DESC
LIMIT 1;

-- Should use composite index

-- Test message fetch performance
EXPLAIN ANALYZE
SELECT role, content FROM messages
WHERE conversation_id = 'some-uuid'
ORDER BY created_at
LIMIT 20;

-- Should use conversation_id index
```

---

## Troubleshooting

### Migration Issues

**Problem:** Migration fails with "table already exists"
```bash
# Solution: Reset database
supabase db reset
```

**Problem:** RLS policies blocking queries
```bash
# Check auth context
SELECT auth.uid();

# If NULL, you're not authenticated
# Solution: Pass proper JWT token
```

### Edge Function Issues

**Problem:** OpenAI API returns 401
```bash
# Check API key is set
supabase secrets list

# Re-set if needed
supabase secrets set OPENAI_API_KEY=sk-...
```

**Problem:** "Conversation not found" error
```bash
# Verify conversation exists
psql postgresql://postgres:postgres@localhost:54322/postgres -c \
  "SELECT * FROM conversations WHERE id = 'your-conversation-id';"
```

**Problem:** Streaming not working
```bash
# Ensure you use --no-buffer flag
curl ... --no-buffer
```

---

## Next Steps

After all Phase 1 tests pass:
1. ✅ Deploy migrations to production Supabase
2. ✅ Deploy Edge Functions to production
3. ✅ Move to Phase 2: iOS Services & Models implementation
4. ✅ Test end-to-end with iOS app

---

## Production Deployment

When ready for production:

```bash
# Link to production project
supabase link --project-ref your-project-ref

# Run migration
supabase db push

# Deploy functions
supabase functions deploy create-conversation
supabase functions deploy send-message
supabase functions deploy complete-conversation
supabase functions deploy create-realtime-session

# Set production secrets
supabase secrets set OPENAI_API_KEY=sk-prod-...
```
