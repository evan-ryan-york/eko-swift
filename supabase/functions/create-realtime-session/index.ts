// Lyra Create Realtime Session Edge Function
// Sets up OpenAI Realtime API session for voice conversations
// Updated for GA API (ephemeral keys)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateRealtimeSessionRequest {
  conversationId: string
  childId: string
}

interface RealtimeSessionResponse {
  clientSecret: string
  model: string
  voice: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request body
    const { conversationId, childId }: CreateRealtimeSessionRequest = await req.json()

    if (!conversationId || !childId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: conversationId, childId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify conversation exists and belongs to authenticated user
    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .select('user_id, child_id')
      .eq('id', conversationId)
      .single()

    if (convError || !conversation) {
      return new Response(
        JSON.stringify({ error: 'Conversation not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch child context with memory
    const { data: child, error: childError } = await supabase
      .from('children')
      .select(`
        id,
        name,
        age,
        temperament,
        temperament_talkative,
        temperament_sensitivity,
        temperament_accountability
      `)
      .eq('id', childId)
      .single()

    if (childError || !child) {
      return new Response(
        JSON.stringify({ error: 'Child not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch child memory
    const { data: memory } = await supabase
      .from('child_memory')
      .select('behavioral_themes, communication_strategies, significant_events')
      .eq('child_id', childId)
      .single()

    // Build voice instructions
    const instructions = buildVoiceInstructions(child, memory)

    // Create ephemeral key using GA API
    // The /v1/realtime/client_secrets endpoint creates an ephemeral token.
    // Session configuration is sent in the request body.
    const keyResponse = await fetch('https://api.openai.com/v1/realtime/client_secrets', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        session: {
          type: 'realtime',
          model: 'gpt-realtime',
          instructions: instructions,
          audio: {
            input: {
              transcription: {
                model: 'whisper-1'
              },
              turn_detection: {
                type: 'server_vad',
                threshold: 0.5,
                prefix_padding_ms: 300,
                silence_duration_ms: 500
              }
            },
            output: { voice: 'alloy' }
          }
        }
      }),
    })

    if (!keyResponse.ok) {
      const errorText = await keyResponse.text()
      console.error('OpenAI API error:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to create realtime session', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const openaiResponse = await keyResponse.json()

    // OpenAI GA API returns {value: "ek_..."} directly
    const clientSecretValue = openaiResponse.value

    const response: RealtimeSessionResponse = {
      clientSecret: clientSecretValue,
      model: 'gpt-realtime',
      voice: 'alloy'
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in create-realtime-session function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// Build voice conversation instructions
function buildVoiceInstructions(child: any, memory: any): string {
  const behavioralThemes = memory?.behavioral_themes || []
  const strategies = memory?.communication_strategies || []
  const events = memory?.significant_events || []

  const themesText = behavioralThemes.length > 0
    ? behavioralThemes.slice(0, 3).map((t: any) => t.theme).join(', ')
    : 'None observed yet'

  const strategiesText = strategies.length > 0
    ? strategies.slice(0, 3).map((s: any) => s.strategy).join(', ')
    : 'None identified yet'

  const recentEvents = events.length > 0
    ? events.slice(-2).map((e: any) => `${e.event} (${e.date})`).join('; ')
    : 'None recorded'

  return `You are Lyra, an empathetic AI parenting coach helping a parent with their child, ${child.name}, age ${child.age}.

# Personality & Voice

You're having a VOICE conversation. Speak naturally, warmly, and conversationally. Keep responses brief (2-4 sentences per turn) to maintain natural dialogue flow.

# Child Context

**Name:** ${child.name}
**Age:** ${child.age} years old
**Temperament:** ${child.temperament}

**Traits (1-10):**
- Talkativeness: ${child.temperament_talkative}/10
- Sensitivity: ${child.temperament_sensitivity}/10
- Accountability: ${child.temperament_accountability}/10

**Recent Themes:** ${themesText}
**Effective Strategies:** ${strategiesText}
**Recent Events:** ${recentEvents}

# Voice Conversation Guidelines

1. **Be Conversational:** Speak like you're talking to a friend who's asking for parenting advice. Use natural speech patterns, not essay-style responses.

2. **Keep It Short:** Voice conversations work best with brief exchanges. Aim for 2-4 sentences, then let the parent respond. Don't lecture.

3. **Be Specific:** Reference ${child.name} by name. Use their age and temperament in your suggestions.

4. **Ask Questions:** If you need more context, ask ONE clarifying question at a time.

5. **Natural Fillers:** It's okay to use phrases like "Hmm," "I see," "That makes sense" - it makes the conversation feel human.

6. **Empathize First:** Before jumping to advice, validate the parent's feelings. "That sounds really challenging" or "I can understand why that's frustrating."

7. **Actionable & Concrete:** Give specific strategies the parent can try today, not generic advice.

8. **Safety First:** If you hear anything about child safety, abuse, or severe crisis, immediately provide:
   - "I'm concerned about what you've shared. Please call 911 if there's immediate danger, or reach out to the National Child Abuse Hotline at 1-800-4-A-CHILD."

# Tone Examples

❌ Wrong (too formal): "Based on the developmental stage of a ${child.age}-year-old, I recommend implementing a structured bedtime routine with consistent expectations and positive reinforcement mechanisms."

✅ Right (conversational): "At ${child.age}, kids really thrive on predictability. What if you tried keeping bedtime the same every night and maybe adding a small reward when ${child.name} cooperates?"

# Remember

You're a trusted parenting expert having a real-time conversation. Be warm, be brief, be specific to ${child.name}. The parent is probably multitasking or feeling stressed - make your advice easy to understand and remember.`
}
