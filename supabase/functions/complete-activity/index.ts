// Daily Practice - Complete Activity Edge Function
// Marks an activity as completed and updates user progress

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CompleteActivityRequest {
  dayNumber: number
  totalScore: number
  sessionId?: string
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
    const { dayNumber, totalScore, sessionId }: CompleteActivityRequest = await req.json()

    if (!dayNumber || totalScore === undefined) {
      return new Response(
        JSON.stringify({ error: 'Missing dayNumber or totalScore' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch user profile
    const { data: userData, error: userError } = await supabase
      .from('user_profiles')
      .select('total_score, daily_practice_scores')
      .eq('id', user.id)
      .single()

    if (userError) {
      console.error('Error fetching user:', userError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch user data', details: userError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate new totals
    const newTotalScore = (userData.total_score || 0) + totalScore
    const updatedScores = userData.daily_practice_scores || {}
    updatedScores[dayNumber] = totalScore

    // Update user profile
    const { error: updateUserError } = await supabase
      .from('user_profiles')
      .update({
        last_completed_daily_practice_activity: dayNumber,
        last_daily_practice_activity_completed_at: new Date().toISOString(),
        total_score: newTotalScore,
        daily_practice_scores: updatedScores
      })
      .eq('id', user.id)

    if (updateUserError) {
      console.error('Error updating user:', updateUserError)
      return new Response(
        JSON.stringify({ error: 'Failed to update user progress', details: updateUserError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update session if provided
    if (sessionId) {
      await supabase
        .from('daily_practice_results')
        .update({
          completed: true,
          end_at: new Date().toISOString(),
          total_score: totalScore
        })
        .eq('id', sessionId)
        .eq('user_id', user.id)
    }

    return new Response(
      JSON.stringify({
        success: true,
        completed_day: dayNumber,
        message: `Day ${dayNumber} completed successfully`
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in complete-activity function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
