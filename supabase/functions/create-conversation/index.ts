// Lyra Create Conversation Edge Function
// Creates a new conversation record for a user and child

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateConversationRequest {
  childId: string
}

interface ConversationResponse {
  id: string
  userId: string
  childId: string
  status: string
  title: string | null
  createdAt: string
  updatedAt: string
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
    const { childId }: CreateConversationRequest = await req.json()

    if (!childId) {
      return new Response(
        JSON.stringify({ error: 'Missing childId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify child belongs to user
    const { data: child, error: childError } = await supabase
      .from('children')
      .select('id')
      .eq('id', childId)
      .eq('user_id', user.id)
      .single()

    if (childError || !child) {
      return new Response(
        JSON.stringify({ error: 'Child not found or does not belong to user' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if there's already an active conversation for this child
    const { data: existingConversation } = await supabase
      .from('conversations')
      .select('id, user_id, child_id, status, title, created_at, updated_at')
      .eq('user_id', user.id)
      .eq('child_id', childId)
      .eq('status', 'active')
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()

    // If active conversation exists, return it
    if (existingConversation) {
      const response: ConversationResponse = {
        id: existingConversation.id,
        userId: existingConversation.user_id,
        childId: existingConversation.child_id,
        status: existingConversation.status,
        title: existingConversation.title,
        createdAt: existingConversation.created_at,
        updatedAt: existingConversation.updated_at,
      }

      return new Response(
        JSON.stringify(response),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Create new conversation
    const { data: newConversation, error: insertError } = await supabase
      .from('conversations')
      .insert({
        user_id: user.id,
        child_id: childId,
        status: 'active',
      })
      .select('id, user_id, child_id, status, title, created_at, updated_at')
      .single()

    if (insertError) {
      console.error('Error creating conversation:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to create conversation', details: insertError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Ensure child memory record exists (for future personalization)
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const adminSupabase = createClient(supabaseUrl, serviceRoleKey)

    await adminSupabase.rpc('get_or_create_child_memory', { p_child_id: childId })

    const response: ConversationResponse = {
      id: newConversation.id,
      userId: newConversation.user_id,
      childId: newConversation.child_id,
      status: newConversation.status,
      title: newConversation.title,
      createdAt: newConversation.created_at,
      updatedAt: newConversation.updated_at,
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in create-conversation function:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
