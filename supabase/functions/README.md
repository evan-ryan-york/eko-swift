# Lyra Edge Functions

This directory contains Supabase Edge Functions for the Lyra AI parenting coach feature.

## Functions Overview

### 1. `create-conversation`
Creates a new conversation between a user and Lyra for a specific child.

**Endpoint:** `POST /functions/v1/create-conversation`

**Request Body:**
```json
{
  "childId": "uuid-of-child"
}
```

**Response:**
```json
{
  "id": "conversation-uuid",
  "userId": "user-uuid",
  "childId": "child-uuid",
  "status": "active",
  "title": null,
  "createdAt": "2025-10-11T...",
  "updatedAt": "2025-10-11T..."
}
```

**Notes:**
- Returns existing active conversation if one exists for this user+child
- Automatically creates child_memory record if needed
- Requires authenticated user (JWT in Authorization header)

---

### 2. `send-message`
Sends a message and streams AI response in real-time.

**Endpoint:** `POST /functions/v1/send-message`

**Request Body:**
```json
{
  "conversationId": "conversation-uuid",
  "message": "How do I handle bedtime resistance?",
  "childId": "child-uuid"
}
```

**Response:** Server-Sent Events (SSE) stream
```
data: How\n\n
data:  about\n\n
data:  trying\n\n
...
```

**Features:**
- Fetches child context and memory for personalization
- Builds conversation history (last 20 messages)
- Streams OpenAI GPT-4 response token-by-token
- Saves both user and assistant messages to database
- Includes crisis keyword detection in system prompt

---

### 3. `complete-conversation`
Marks conversation as complete, extracts insights, updates child memory, and generates title.

**Endpoint:** `POST /functions/v1/complete-conversation`

**Request Body:**
```json
{
  "conversationId": "conversation-uuid"
}
```

**Response:**
```json
{
  "success": true,
  "title": "Bedtime routine challenges",
  "insights": {
    "behavioral_themes": [...],
    "communication_strategies": [...],
    "significant_events": [...]
  }
}
```

**Features:**
- Uses GPT-4 to analyze conversation and extract insights
- Updates child_memory table with new learnings
- Auto-generates descriptive conversation title
- Marks conversation status as 'completed'

---

### 4. `create-realtime-session`
Creates OpenAI Realtime API session for voice conversations.

**Endpoint:** `POST /functions/v1/create-realtime-session`

**Request Body:**
```json
{
  "sdp": "WebRTC SDP offer from iOS",
  "conversationId": "conversation-uuid",
  "childId": "child-uuid"
}
```

**Response:**
```json
{
  "sdp": "WebRTC SDP answer from OpenAI",
  "callId": "optional-call-id"
}
```

**Features:**
- Configures OpenAI Realtime API with child-specific context
- Sets up voice parameters (model, voice type, VAD settings)
- Returns SDP answer for iOS WebRTC connection
- Optimized for conversational voice interactions

---

## Deployment

### Deploy all functions:
```bash
supabase functions deploy create-conversation
supabase functions deploy send-message
supabase functions deploy complete-conversation
supabase functions deploy create-realtime-session
```

### Set environment secrets:
```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

**Required secrets:**
- `OPENAI_API_KEY` - Your OpenAI API key
- `SUPABASE_URL` - Auto-set by Supabase
- `SUPABASE_ANON_KEY` - Auto-set by Supabase
- `SUPABASE_SERVICE_ROLE_KEY` - Auto-set by Supabase

---

## Testing with cURL

### 1. Create Conversation
```bash
curl -X POST 'http://localhost:54321/functions/v1/create-conversation' \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "childId": "your-child-uuid"
  }'
```

### 2. Send Message (streaming)
```bash
curl -X POST 'http://localhost:54321/functions/v1/send-message' \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "conversation-uuid",
    "message": "How do I handle tantrums?",
    "childId": "child-uuid"
  }' \
  --no-buffer
```

### 3. Complete Conversation
```bash
curl -X POST 'http://localhost:54321/functions/v1/complete-conversation' \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "conversation-uuid"
  }'
```

### 4. Create Realtime Session
```bash
curl -X POST 'http://localhost:54321/functions/v1/create-realtime-session' \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sdp": "your-webrtc-sdp-offer",
    "conversationId": "conversation-uuid",
    "childId": "child-uuid"
  }'
```

---

## Local Development

1. **Start Supabase:**
   ```bash
   supabase start
   ```

2. **Serve functions locally:**
   ```bash
   supabase functions serve
   ```

3. **Test with local endpoint:**
   ```
   http://localhost:54321/functions/v1/{function-name}
   ```

---

## Error Handling

All functions return standard error responses:

```json
{
  "error": "Error message",
  "details": "Optional detailed error info"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (missing/invalid parameters)
- `401` - Unauthorized (missing/invalid JWT)
- `404` - Not Found (resource doesn't exist)
- `500` - Internal Server Error

---

## Security

- All functions require authentication via JWT (Authorization header)
- Row Level Security (RLS) enforced on database tables
- Service role key used only for bypassing RLS in Edge Functions
- CORS configured for iOS app access
- No sensitive data exposed in error messages

---

## Performance Considerations

- **send-message:** Streams responses for better UX (no waiting for full response)
- **Message history:** Limited to last 20 messages to control token usage
- **Indexes:** Database properly indexed for fast queries
- **Memory updates:** Appends new insights rather than replacing (preserves history)

---

## Future Improvements

- [ ] Add rate limiting per user
- [ ] Implement conversation analytics
- [ ] Add support for image uploads (visual context)
- [ ] Cache frequently accessed child contexts
- [ ] Add webhook for async memory processing
- [ ] Implement conversation branching/forking
- [ ] Add export conversation feature
