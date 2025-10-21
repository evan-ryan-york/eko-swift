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

    // Fetch user profile
    const { data: userData, error: userError} = await supabase
      .from('user_profiles')
      .select('last_completed_daily_practice_activity, last_daily_practice_activity_completed_at')
      .eq('id', user.id)
      .single()

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

    // Get child age band
    let ageBand = '6-9' // Default

    if (children && children.length > 0) {
      const child = children[0]
      if (child.birthday) {
        const age = calculateAge(child.birthday)
        ageBand = mapAgeToAgeBand(age)
      }
    }

    // Fetch activity (main table only)
    const { data: activity, error: activityError } = await supabase
      .from('daily_practice_activities')
      .select('*')
      .eq('day_number', nextDay)
      .eq('age_band', ageBand)
      .single()

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

    // Fetch prompts for this activity
    const { data: prompts, error: promptsError } = await supabase
      .from('prompts')
      .select('*')
      .eq('activity_id', activity.id)
      .order('order_index', { ascending: true })

    if (promptsError) {
      console.error('Error fetching prompts:', promptsError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch prompts', details: promptsError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch options for all prompts
    const promptIds = prompts?.map(p => p.id) || []
    const { data: allOptions, error: optionsError } = await supabase
      .from('prompt_options')
      .select('*')
      .in('prompt_id', promptIds)

    if (optionsError) {
      console.error('Error fetching options:', optionsError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch options', details: optionsError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch actionable takeaway
    const { data: takeaways, error: takeawayError } = await supabase
      .from('actionable_takeaways')
      .select('*')
      .eq('activity_id', activity.id)
      .single()

    if (takeawayError) {
      console.error('Error fetching takeaway:', takeawayError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch takeaway', details: takeawayError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build the complete activity structure
    const completePrompts = prompts?.map(prompt => {
      // Get options for this prompt
      const promptOptions = allOptions?.filter(opt => opt.prompt_id === prompt.id) || []

      // Transform options to match Swift model structure
      const formattedOptions = promptOptions.map(opt => ({
        optionId: opt.option_id,
        optionText: opt.option_text,
        correct: opt.correct,
        points: opt.points,
        feedback: opt.feedback,
        scienceNote: (opt.science_note_brief || opt.science_note_citation) ? {
          brief: opt.science_note_brief,
          citation: opt.science_note_citation,
          showCitation: opt.science_note_show_citation
        } : null
      }))

      return {
        promptId: prompt.prompt_id,
        type: prompt.type,
        promptText: prompt.prompt_text,
        order: prompt.order_index,
        points: prompt.points,
        options: formattedOptions
      }
    }) || []

    // Build complete activity with all related data
    const completeActivity = {
      ...activity,
      prompts: completePrompts,
      actionable_takeaway: takeaways
    }

    // Return activity with snake_case (database format)
    return new Response(
      JSON.stringify({
        day_number: nextDay,
        activity: completeActivity,
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
