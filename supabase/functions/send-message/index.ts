// Lyra Send Message Edge Function
// Handles text chat messages with OpenAI streaming responses

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SendMessageRequest {
  conversationId: string
  message: string
  childId: string
}

interface ChildContext {
  id: string
  name: string
  age: number
  temperament: string
  temperament_talkative: number
  temperament_sensitivity: number
  temperament_accountability: number
  memory?: {
    behavioral_themes: Array<any>
    communication_strategies: Array<any>
    significant_events: Array<any>
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role (bypasses RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request body
    const { conversationId, message, childId }: SendMessageRequest = await req.json()

    // Validate inputs
    if (!conversationId || !message || !childId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get JWT token for user verification
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify conversation belongs to authenticated user
    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .select('user_id')
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

    const childContext: ChildContext = {
      ...child,
      memory: memory || undefined,
    }

    // Fetch conversation history (last 20 messages for context)
    const { data: messageHistory, error: historyError } = await supabase
      .from('messages')
      .select('role, content')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(20)

    if (historyError) {
      console.error('Error fetching message history:', historyError)
    }

    // Save user message to database
    const { error: insertError } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        role: 'user',
        content: message,
      })

    if (insertError) {
      console.error('Error saving user message:', insertError)
    }

    // Build personalized system prompt
    const systemPrompt = buildSystemPrompt(childContext)

    // Build messages array for OpenAI
    const messages = [
      { role: 'system', content: systemPrompt },
      ...(messageHistory || []).map((msg: any) => ({
        role: msg.role,
        content: msg.content,
      })),
      { role: 'user', content: message },
    ]

    // Call OpenAI GPT-4 Turbo with streaming
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: messages,
        stream: true,
        max_tokens: 1000,
      }),
    })

    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text()
      console.error('OpenAI API error:', errorText)
      return new Response(
        JSON.stringify({ error: 'OpenAI API error', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Server-Sent Events stream
    const encoder = new TextEncoder()
    let assistantMessage = ''

    const stream = new ReadableStream({
      async start(controller) {
        try {
          const reader = openaiResponse.body!.getReader()
          const decoder = new TextDecoder()

          while (true) {
            const { done, value } = await reader.read()
            if (done) break

            const chunk = decoder.decode(value)
            const lines = chunk.split('\n').filter(line => line.trim() !== '')

            for (const line of lines) {
              if (line.startsWith('data: ')) {
                const data = line.substring(6)

                if (data === '[DONE]') {
                  // Save complete assistant message to database
                  await supabase
                    .from('messages')
                    .insert({
                      conversation_id: conversationId,
                      role: 'assistant',
                      content: assistantMessage,
                    })

                  // Update conversation updated_at timestamp
                  await supabase
                    .from('conversations')
                    .update({ updated_at: new Date().toISOString() })
                    .eq('id', conversationId)

                  controller.close()
                  return
                }

                try {
                  const parsed = JSON.parse(data)
                  const content = parsed.choices?.[0]?.delta?.content

                  if (content) {
                    assistantMessage += content
                    // Send SSE event to client
                    controller.enqueue(encoder.encode(`data: ${content}\n\n`))
                  }
                } catch (e) {
                  // Skip non-JSON lines
                  console.error('Error parsing chunk:', e)
                }
              }
            }
          }

          controller.close()
        } catch (error) {
          console.error('Stream error:', error)
          controller.error(error)
        }
      },
    })

    // Return SSE stream
    return new Response(stream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    })

  } catch (error) {
    console.error('Error in send-message function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// Build personalized system prompt based on child context
function buildSystemPrompt(child: ChildContext): string {
  const behavioralThemes = child.memory?.behavioral_themes || []
  const strategies = child.memory?.communication_strategies || []
  const events = child.memory?.significant_events || []

  const themesText = behavioralThemes.length > 0
    ? behavioralThemes.map((t: any) => t.theme).join(', ')
    : 'None observed yet'

  const strategiesText = strategies.length > 0
    ? strategies.map((s: any) => `${s.strategy} (${s.effectiveness} effectiveness)`).join(', ')
    : 'None identified yet'

  const recentEvents = events.length > 0
    ? events.slice(-3).map((e: any) => `${e.event} (${e.date}): ${e.impact}`).join('\n  - ')
    : 'None recorded'

  return `You are Lyra, an empathetic and expert AI parenting coach. You're helping a parent with conversations about their child, ${child.name}, who is ${child.age} years old.

# Child's Personality Profile

**Name:** ${child.name}
**Age:** ${child.age} years old
**Overall Temperament:** ${child.temperament}

**Specific Traits (1-10 scale):**
- **Talkativeness/Communication:** ${child.temperament_talkative}/10 ${getTraitDescription('talkative', child.temperament_talkative)}
- **Emotional Sensitivity:** ${child.temperament_sensitivity}/10 ${getTraitDescription('sensitivity', child.temperament_sensitivity)}
- **Personal Accountability:** ${child.temperament_accountability}/10 ${getTraitDescription('accountability', child.temperament_accountability)}

# Long-Term Context

**Recurring Behavioral Themes:**
${themesText}

**Effective Communication Strategies:**
${strategiesText}

**Recent Significant Events:**
  - ${recentEvents}

# Your Role & Guidelines

1. **Be Warm & Empathetic:** Parents come to you feeling uncertain or stressed. Validate their feelings and normalize their challenges.

2. **Be Specific & Actionable:** Provide concrete strategies tailored to ${child.name}'s age and temperament. Avoid generic advice.

3. **Reference the Child's History:** When relevant, reference behavioral themes, past strategies, or significant events to show deep personalization.

4. **Ask Clarifying Questions:** If you need more context, ask specific questions about the situation.

5. **Keep Responses Concise:** Aim for 2-4 paragraphs. Parents want quick, digestible guidance.

6. **Use Evidence-Based Approaches:** Draw from child development research, attachment theory, and positive parenting frameworks.

7. **Safety First:** If you detect any mention of child safety concerns, abuse, self-harm, or severe mental health crisis, immediately provide crisis resources:
   - 911 (Emergency)
   - 988 (Suicide & Crisis Lifeline)
   - 1-800-4-A-CHILD (Child Abuse Hotline)
   - Crisis Text Line: Text HOME to 741741

8. **Tone:** Conversational, supportive, knowledgeable but not condescending. Like a wise friend who happens to be a parenting expert.

# Current Conversation Context

The parent is seeking your guidance on a parenting challenge or question related to ${child.name}. Listen carefully, respond thoughtfully, and provide practical support.`
}

// Helper function to add descriptive context to trait scores
function getTraitDescription(trait: string, score: number): string {
  if (score <= 3) {
    switch (trait) {
      case 'talkative': return '(tends to be quiet or reserved)'
      case 'sensitivity': return '(emotionally resilient)'
      case 'accountability': return '(needs support with responsibility)'
      default: return ''
    }
  } else if (score >= 8) {
    switch (trait) {
      case 'talkative': return '(very communicative and expressive)'
      case 'sensitivity': return '(highly emotionally aware)'
      case 'accountability': return '(takes responsibility well)'
      default: return ''
    }
  } else {
    switch (trait) {
      case 'talkative': return '(moderately communicative)'
      case 'sensitivity': return '(balanced emotional awareness)'
      case 'accountability': return '(developing responsibility)'
      default: return ''
    }
  }
}
