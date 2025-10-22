// Reset Daily Practice - DEBUG/DEVELOPMENT ONLY
// Resets the user's daily practice progress so they can test again

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🔄 reset-daily-practice function started')

    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.log('❌ Missing authorization header')
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
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
      console.log('❌ Authentication failed:', authError?.message)
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('✅ User authenticated:', user.id)

    // Parse request body to get reset type
    const body = await req.json()
    const resetType = body.resetType || 'current' // 'current' or 'all'

    if (resetType === 'all') {
      // Reset all progress
      console.log('🔄 Resetting ALL daily practice progress for user:', user.id)

      const { error: updateError } = await supabase
        .from('user_profiles')
        .update({
          last_completed_daily_practice_activity: 0,
          last_daily_practice_activity_completed_at: null,
          total_score: 0,
          daily_practice_scores: {}
        })
        .eq('id', user.id)

      if (updateError) {
        console.error('Error resetting progress:', updateError)
        throw updateError
      }

      // Also delete all result records for this user
      const { error: deleteError } = await supabase
        .from('daily_practice_results')
        .delete()
        .eq('user_id', user.id)

      if (deleteError) {
        console.error('Error deleting results:', deleteError)
        // Non-critical, continue
      }

      console.log('✅ All progress reset successfully')
      return new Response(
        JSON.stringify({
          success: true,
          message: 'All daily practice progress has been reset',
          resetType: 'all'
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else {
      // Reset only current day (go back one day)
      console.log('🔄 Resetting current day for user:', user.id)

      const { data: userData, error: userError } = await supabase
        .from('user_profiles')
        .select('last_completed_daily_practice_activity, daily_practice_scores')
        .eq('id', user.id)
        .single()

      if (userError) {
        console.error('Error fetching user:', userError)
        throw userError
      }

      const currentDay = userData.last_completed_daily_practice_activity || 0
      const previousDay = Math.max(0, currentDay - 1)

      // Remove the current day's score from the scores object
      const scores = userData.daily_practice_scores || {}
      if (scores[currentDay]) {
        delete scores[currentDay]
      }

      const { error: updateError } = await supabase
        .from('user_profiles')
        .update({
          last_completed_daily_practice_activity: previousDay,
          last_daily_practice_activity_completed_at: null,
          daily_practice_scores: scores
        })
        .eq('id', user.id)

      if (updateError) {
        console.error('Error resetting current day:', updateError)
        throw updateError
      }

      console.log(`✅ Reset from day ${currentDay} to day ${previousDay}`)
      return new Response(
        JSON.stringify({
          success: true,
          message: `Reset from day ${currentDay} to day ${previousDay}`,
          resetType: 'current',
          previousDay: currentDay,
          newCurrentDay: previousDay + 1
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Error in reset-daily-practice function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
