// Lyra Complete Conversation Edge Function
// Analyzes conversation, extracts insights, updates child memory, and generates title

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CompleteConversationRequest {
  conversationId: string
}

interface ConversationInsights {
  behavioral_themes?: Array<{
    theme: string
    frequency: number
    first_observed: string
    last_observed: string
  }>
  communication_strategies?: Array<{
    strategy: string
    effectiveness: 'low' | 'medium' | 'high'
    used_count: number
    notes: string
  }>
  significant_events?: Array<{
    event: string
    date: string
    impact: string
  }>
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

    // Initialize Supabase clients
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request body
    const { conversationId }: CompleteConversationRequest = await req.json()

    if (!conversationId) {
      return new Response(
        JSON.stringify({ error: 'Missing conversationId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch conversation details
    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .select('id, user_id, child_id, status')
      .eq('id', conversationId)
      .single()

    if (convError || !conversation) {
      return new Response(
        JSON.stringify({ error: 'Conversation not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (conversation.status === 'completed') {
      return new Response(
        JSON.stringify({ message: 'Conversation already completed' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch all messages in conversation
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('role, content, created_at')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })

    if (messagesError || !messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No messages found in conversation' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch child info for context
    const { data: child, error: childError } = await supabase
      .from('children')
      .select('name, age')
      .eq('id', conversation.child_id)
      .single()

    if (childError || !child) {
      return new Response(
        JSON.stringify({ error: 'Child not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate conversation title using GPT-4
    const title = await generateConversationTitle(messages, child, openaiApiKey)

    // Extract insights using GPT-4
    const insights = await extractInsights(messages, child, openaiApiKey)

    // Update child memory with insights
    if (insights.behavioral_themes && insights.behavioral_themes.length > 0) {
      await supabase.rpc('update_child_memory_insights', {
        p_child_id: conversation.child_id,
        p_new_behavioral_themes: insights.behavioral_themes,
        p_new_strategies: null,
        p_new_events: null,
      })
    }

    if (insights.communication_strategies && insights.communication_strategies.length > 0) {
      await supabase.rpc('update_child_memory_insights', {
        p_child_id: conversation.child_id,
        p_new_behavioral_themes: null,
        p_new_strategies: insights.communication_strategies,
        p_new_events: null,
      })
    }

    if (insights.significant_events && insights.significant_events.length > 0) {
      await supabase.rpc('update_child_memory_insights', {
        p_child_id: conversation.child_id,
        p_new_behavioral_themes: null,
        p_new_strategies: null,
        p_new_events: insights.significant_events,
      })
    }

    // Mark conversation as completed with generated title
    const { error: updateError } = await supabase
      .from('conversations')
      .update({
        status: 'completed',
        title: title,
        updated_at: new Date().toISOString(),
      })
      .eq('id', conversationId)

    if (updateError) {
      console.error('Error updating conversation:', updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to complete conversation' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        title: title,
        insights: insights,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in complete-conversation function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// Generate a concise conversation title using GPT-4
async function generateConversationTitle(
  messages: Array<any>,
  child: { name: string; age: number },
  openaiApiKey: string
): Promise<string> {
  const conversationText = messages
    .filter((m: any) => m.role !== 'system')
    .map((m: any) => `${m.role}: ${m.content}`)
    .join('\n')

  const prompt = `Given this conversation between a parent and Lyra (AI parenting coach) about ${child.name} (age ${child.age}), generate a short, descriptive title (max 60 characters).

The title should capture the main topic or challenge discussed.

Examples:
- "Bedtime routine challenges"
- "Managing screen time boundaries"
- "Helping with homework frustration"
- "Sibling conflict resolution"

Conversation:
${conversationText.substring(0, 2000)}

Title:`

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.7,
        max_tokens: 50,
      }),
    })

    if (!response.ok) {
      console.error('OpenAI title generation failed')
      return 'Conversation with Lyra'
    }

    const data = await response.json()
    let title = data.choices[0]?.message?.content?.trim() || 'Conversation with Lyra'

    // Remove quotes if present
    title = title.replace(/^["']|["']$/g, '')

    // Truncate if too long
    if (title.length > 60) {
      title = title.substring(0, 57) + '...'
    }

    return title
  } catch (error) {
    console.error('Error generating title:', error)
    return 'Conversation with Lyra'
  }
}

// Extract insights from conversation using GPT-4
async function extractInsights(
  messages: Array<any>,
  child: { name: string; age: number },
  openaiApiKey: string
): Promise<ConversationInsights> {
  const conversationText = messages
    .filter((m: any) => m.role !== 'system')
    .map((m: any) => `${m.role}: ${m.content}`)
    .join('\n')

  const today = new Date().toISOString().split('T')[0]

  const prompt = `Analyze this conversation between a parent and Lyra (AI parenting coach) about ${child.name} (age ${child.age}).

Extract actionable insights in JSON format:

{
  "behavioral_themes": [
    {
      "theme": "brief description of behavioral pattern",
      "frequency": 1,
      "first_observed": "${today}",
      "last_observed": "${today}"
    }
  ],
  "communication_strategies": [
    {
      "strategy": "specific communication approach discussed",
      "effectiveness": "high" | "medium" | "low",
      "used_count": 1,
      "notes": "brief context"
    }
  ],
  "significant_events": [
    {
      "event": "important life event mentioned",
      "date": "${today}",
      "impact": "how it affects the child"
    }
  ]
}

Guidelines:
- Only extract themes/strategies/events explicitly discussed
- behavioral_themes: ongoing patterns (e.g., "bedtime resistance", "sibling rivalry")
- communication_strategies: specific approaches mentioned (e.g., "choice framework", "active listening")
- significant_events: major life changes (e.g., "started new school", "parent divorce")
- If nothing relevant in a category, return empty array
- Keep descriptions concise (< 100 chars)

Conversation:
${conversationText.substring(0, 3000)}

Return ONLY valid JSON:`

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.5,
        max_tokens: 800,
        response_format: { type: 'json_object' },
      }),
    })

    if (!response.ok) {
      console.error('OpenAI insights extraction failed')
      return {}
    }

    const data = await response.json()
    const insightsText = data.choices[0]?.message?.content

    if (!insightsText) {
      return {}
    }

    const insights = JSON.parse(insightsText)
    return insights
  } catch (error) {
    console.error('Error extracting insights:', error)
    return {}
  }
}
