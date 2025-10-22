// Daily Practice - Start Practice Session Edge Function
// Creates an analytics record when a user starts a daily practice activity

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface StartSessionRequest {
  activityId: string
  dayNumber: number
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
    const { activityId, dayNumber }: StartSessionRequest = await req.json()

    if (!activityId || !dayNumber) {
      return new Response(
        JSON.stringify({ error: 'Missing activityId or dayNumber' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create session record
    const { data: session, error: sessionError } = await supabase
      .from('daily_practice_results')
      .insert({
        user_id: user.id,
        activity_id: activityId,
        day_number: dayNumber,
        start_at: new Date().toISOString(),
        completed: false,
        prompt_results: [],
        total_score: 0
      })
      .select('id, user_id, activity_id, day_number, start_at, completed, prompt_results, total_score')
      .single()

    if (sessionError) {
      console.error('Error creating session:', sessionError)
      return new Response(
        JSON.stringify({ error: 'Failed to create session', details: sessionError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        session_id: session.id,
        message: `Session started for day ${dayNumber}`
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in start-practice-session function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
