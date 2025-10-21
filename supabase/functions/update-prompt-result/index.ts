// Daily Practice - Update Prompt Result Edge Function
// Updates analytics for a specific prompt within a practice session

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface UpdatePromptRequest {
  sessionId: string
  promptResult: {
    promptId: string
    tries: number
    logs: Array<{
      optionId: string
      correct: boolean
      timestamp: string
    }>
    pointsEarned: number
    completed: boolean
  }
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

    // Initialize Supabase client with user's JWT
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    })

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { sessionId, promptResult }: UpdatePromptRequest = await req.json()

    if (!sessionId || !promptResult) {
      return new Response(
        JSON.stringify({ error: 'Missing sessionId or promptResult' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch existing session
    const { data: session, error: fetchError } = await supabase
      .from('daily_practice_results')
      .select('prompt_results')
      .eq('id', sessionId)
      .eq('user_id', user.id)
      .single()

    if (fetchError) {
      console.error('Error fetching session:', fetchError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch session', details: fetchError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update prompt_results array
    let promptResults = session.prompt_results || []
    const existingIndex = promptResults.findIndex(
      (r: any) => r.promptId === promptResult.promptId
    )

    if (existingIndex >= 0) {
      promptResults[existingIndex] = promptResult
    } else {
      promptResults.push(promptResult)
    }

    // Update session
    const { error: updateError } = await supabase
      .from('daily_practice_results')
      .update({ prompt_results: promptResults })
      .eq('id', sessionId)
      .eq('user_id', user.id)

    if (updateError) {
      console.error('Error updating prompt result:', updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update prompt result', details: updateError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Prompt result updated'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in update-prompt-result function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
