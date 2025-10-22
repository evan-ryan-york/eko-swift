// Daily Practice - Get Daily Activity Edge Function
// Fetches the next available daily practice activity for the authenticated user

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
    console.log('🚀 get-daily-activity function started')

    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.log('❌ Missing authorization header')
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with user's JWT
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    console.log('🔧 Creating Supabase client')
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    })

    // Get authenticated user
    console.log('🔐 Authenticating user')
    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
      console.log('❌ Authentication failed:', authError?.message)
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('✅ User authenticated:', user.id)

    // Fetch user profile
    console.log('📊 Fetching user profile for:', user.id)
    const { data: userData, error: userError} = await supabase
      .from('user_profiles')
      .select('last_completed_daily_practice_activity, last_daily_practice_activity_completed_at')
      .eq('id', user.id)
      .single()

    console.log('📊 User profile fetched:', userData ? 'success' : 'failed', userError?.message || '')

    // Get child IDs from children table
    const { data: children } = await supabase
      .from('children')
      .select('id, birthday')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(1)

    if (userError) {
      console.error('Error fetching user:', userError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch user data', details: userError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if completed today (UTC date comparison)
    const now = new Date()
    const todayUTC = now.toISOString().split('T')[0]

    if (userData.last_daily_practice_activity_completed_at) {
      const completionDate = new Date(userData.last_daily_practice_activity_completed_at)
        .toISOString().split('T')[0]

      if (completionDate === todayUTC) {
        return new Response(
          JSON.stringify({
            error: 'already_completed',
            message: 'Daily practice already completed today',
            last_completed: userData.last_completed_daily_practice_activity,
            completed_at: userData.last_daily_practice_activity_completed_at
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Calculate next day
    const nextDay = (userData.last_completed_daily_practice_activity || 0) + 1
    console.log('📅 Next day to fetch:', nextDay)

    // Get child age band
    let ageBand = '6-9' // Default

    if (children && children.length > 0) {
      const child = children[0]
      if (child.birthday) {
        const age = calculateAge(child.birthday)
        ageBand = mapAgeToAgeBand(age)
      }
    }
    console.log('👶 Age band:', ageBand)

    // Fetch activity from single table with JSONB columns
    console.log('🎯 Fetching activity for day', nextDay, 'age band', ageBand)
    const { data: activity, error: activityError } = await supabase
      .from('daily_practice_activities')
      .select('*')
      .eq('day_number', nextDay)
      .eq('age_band', ageBand)
      .single()

    console.log('🎯 Activity fetch result:', activity ? 'found' : 'not found', activityError?.message || '')

    if (activityError || !activity) {
      return new Response(
        JSON.stringify({
          error: 'not_found',
          message: `No activity available for day ${nextDay}`,
          day_number: nextDay
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Activity already contains prompts and actionable_takeaway as JSONB
    // Just return it directly
    console.log('✅ Returning activity with', activity.prompts?.length || 0, 'prompts')
    return new Response(
      JSON.stringify({
        day_number: nextDay,
        activity: activity,
        user_progress: {
          last_completed: userData.last_completed_daily_practice_activity || 0,
          current_day: nextDay
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in get-daily-activity function:', error)
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
