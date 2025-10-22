// Get Activity by Day - DEBUG/DEVELOPMENT ONLY
// Fetches a specific daily practice activity by day number (for testing)

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
    console.log('🎯 get-activity-by-day function started')

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

    // Get day number from request body
    const body = await req.json()
    const requestedDay = body.dayNumber

    if (!requestedDay || requestedDay < 1) {
      return new Response(
        JSON.stringify({ error: 'Invalid day number' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('📅 Requested day:', requestedDay)

    // Get user profile for current progress
    const { data: userData, error: userError } = await supabase
      .from('user_profiles')
      .select('last_completed_daily_practice_activity')
      .eq('id', user.id)
      .single()

    if (userError) {
      console.error('Error fetching user:', userError)
      throw userError
    }

    // Get child age band
    let ageBand = '6-9' // Default

    const { data: children } = await supabase
      .from('children')
      .select('id, birthday')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(1)

    if (children && children.length > 0) {
      const child = children[0]
      if (child.birthday) {
        const age = calculateAge(child.birthday)
        ageBand = mapAgeToAgeBand(age)
      }
    }

    console.log('👶 Age band:', ageBand)

    // Fetch the specific activity
    console.log('🎯 Fetching activity for day', requestedDay, 'age band', ageBand)
    const { data: activity, error: activityError } = await supabase
      .from('daily_practice_activities')
      .select('*')
      .eq('day_number', requestedDay)
      .eq('age_band', ageBand)
      .single()

    console.log('🎯 Activity fetch result:', activity ? 'found' : 'not found', activityError?.message || '')

    if (activityError || !activity) {
      return new Response(
        JSON.stringify({
          error: 'not_found',
          message: `No activity available for day ${requestedDay}`,
          day_number: requestedDay
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Return the activity (even if user has already completed it - this is for testing)
    console.log('✅ Returning activity for testing')
    return new Response(
      JSON.stringify({
        day_number: requestedDay,
        activity: activity,
        user_progress: {
          last_completed: userData.last_completed_daily_practice_activity || 0,
          current_day: requestedDay
        },
        debug_mode: true
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in get-activity-by-day function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function calculateAge(birthday: string): number {
  const birthDate = new Date(birthday)
  const today = new Date()
  let age = today.getFullYear() - birthDate.getFullYear()
  const monthDiff = today.getMonth() - birthDate.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--
  }
  return age
}

function mapAgeToAgeBand(age: number): string {
  if (age >= 6 && age <= 9) return '6-9'
  if (age >= 10 && age <= 12) return '10-12'
  if (age >= 13 && age <= 16) return '13-16'
  if (age < 6) return '6-9'
  return '13-16'
}
