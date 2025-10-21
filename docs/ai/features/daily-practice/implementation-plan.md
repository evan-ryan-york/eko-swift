# Daily Practice Feature - Complete Implementation Plan

## Overview

This document provides a complete, step-by-step implementation plan for building the Daily Practice feature in a Swift/SwiftUI iOS app with Supabase backend. Follow this sequentially for systematic development.

---

## Phase 1: Database & Backend Setup

### Step 1.1: Create Database Tables

Create these tables in Supabase in this order:

#### Table 1: `daily_practice_activities`

```sql
CREATE TABLE daily_practice_activities (
  -- System fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Core identifiers (ALL REQUIRED)
  day_number INTEGER NOT NULL,
  age_band TEXT NOT NULL CHECK (age_band IN ('6-9', '10-12', '13-16')),
  module_name TEXT NOT NULL,
  module_display_name TEXT NOT NULL,

  -- Activity metadata
  title TEXT NOT NULL,
  description TEXT,
  skill_focus TEXT NOT NULL,
  category TEXT,
  activity_type TEXT NOT NULL DEFAULT 'basic-scenario',
  is_reflection BOOLEAN DEFAULT FALSE,

  -- Scenario content (REQUIRED)
  scenario TEXT NOT NULL,

  -- Research and learning (all optional)
  research_concept TEXT,
  research_key_insight TEXT,
  research_citation TEXT,
  research_additional_context TEXT,

  -- Additional content
  best_approach TEXT,
  follow_up_questions JSONB DEFAULT '[]'::jsonb,

  -- Complex data as JSONB (REQUIRED)
  prompts JSONB NOT NULL,
  actionable_takeaway JSONB NOT NULL,

  -- Constraints
  UNIQUE(day_number, age_band)
);

-- Indexes
CREATE UNIQUE INDEX idx_day_age_band ON daily_practice_activities(day_number, age_band);
CREATE INDEX idx_day_number ON daily_practice_activities(day_number);
CREATE INDEX idx_module ON daily_practice_activities(module_name);
CREATE INDEX idx_age_band ON daily_practice_activities(age_band);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_daily_practice_activities_updated_at 
BEFORE UPDATE ON daily_practice_activities
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### Table 2: Update `users` table

```sql
-- Add Daily Practice fields to existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_completed_daily_practice_activity INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_daily_practice_activity_completed_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_score INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_practice_scores JSONB DEFAULT '{}'::jsonb;

-- Index for daily check queries
CREATE INDEX IF NOT EXISTS idx_users_last_completion 
ON users(last_daily_practice_activity_completed_at);
```

#### Table 3: `daily_practice_results` (Analytics)

```sql
CREATE TABLE daily_practice_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id),
  day_number INTEGER NOT NULL,
  
  -- Session timing
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  
  -- Detailed tracking
  prompt_results JSONB DEFAULT '[]'::jsonb,
  total_score INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_results_user ON daily_practice_results(user_id);
CREATE INDEX idx_results_user_day ON daily_practice_results(user_id, day_number);
CREATE INDEX idx_results_completed ON daily_practice_results(completed);
CREATE INDEX idx_results_activity ON daily_practice_results(activity_id);

-- Updated_at trigger
CREATE TRIGGER update_daily_practice_results_updated_at 
BEFORE UPDATE ON daily_practice_results
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### Step 1.2: Enable Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE daily_practice_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_practice_results ENABLE ROW LEVEL SECURITY;

-- Activities are readable by all authenticated users
CREATE POLICY "Activities readable by authenticated users"
ON daily_practice_activities FOR SELECT
TO authenticated
USING (true);

-- Results are only viewable by owner
CREATE POLICY "Results viewable by owner"
ON daily_practice_results FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Results insertable by owner
CREATE POLICY "Results insertable by owner"
ON daily_practice_results FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Results updatable by owner
CREATE POLICY "Results updatable by owner"
ON daily_practice_results FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);
```

---

### Step 1.3: Create Supabase Edge Functions

Create these Edge Functions using `supabase functions new [name]`:

#### Function 1: `get-daily-activity`

```typescript
// supabase/functions/get-daily-activity/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Get auth token
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Fetch user record
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('last_completed_daily_practice_activity, last_daily_practice_activity_completed_at, child_ids')
      .eq('id', user.id)
      .single()

    if (userError) throw userError

    // Check if completed today (UTC date comparison)
    const now = new Date()
    const todayUTC = now.toISOString().split('T')[0]
    
    if (userData.last_daily_practice_activity_completed_at) {
      const completionDate = new Date(userData.last_daily_practice_activity_completed_at)
        .toISOString().split('T')[0]
      
      if (completionDate === todayUTC) {
        return new Response(JSON.stringify({
          error: 'already_completed',
          message: 'Daily practice already completed today',
          lastCompleted: userData.last_completed_daily_practice_activity,
          completedAt: userData.last_daily_practice_activity_completed_at
        }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        })
      }
    }

    // Calculate next day
    const nextDay = (userData.last_completed_daily_practice_activity || 0) + 1

    // Get child age band
    let ageBand = '6-9' // Default
    if (userData.child_ids && userData.child_ids.length > 0) {
      const { data: child } = await supabase
        .from('children')
        .select('birthday')
        .eq('id', userData.child_ids[0])
        .single()
      
      if (child && child.birthday) {
        const age = calculateAge(child.birthday)
        ageBand = mapAgeToAgeBand(age)
      }
    }

    // Fetch activity
    const { data: activity, error: activityError } = await supabase
      .from('daily_practice_activities')
      .select('*')
      .eq('day_number', nextDay)
      .eq('age_band', ageBand)
      .single()

    if (activityError || !activity) {
      return new Response(JSON.stringify({
        error: 'not_found',
        message: `No activity available for day ${nextDay}`,
        dayNumber: nextDay
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Return activity
    return new Response(JSON.stringify({
      dayNumber: nextDay,
      activity: activity,
      userProgress: {
        lastCompleted: userData.last_completed_daily_practice_activity || 0,
        currentDay: nextDay
      }
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
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
```

#### Function 2: `start-practice-session`

```typescript
// supabase/functions/start-practice-session/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { activityId, dayNumber } = await req.json()

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
      .select()
      .single()

    if (sessionError) throw sessionError

    return new Response(JSON.stringify({
      success: true,
      sessionId: session.id,
      message: `Session started for day ${dayNumber}`
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

#### Function 3: `update-prompt-result`

```typescript
// supabase/functions/update-prompt-result/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { sessionId, promptResult } = await req.json()

    // Fetch existing session
    const { data: session, error: fetchError } = await supabase
      .from('daily_practice_results')
      .select('prompt_results')
      .eq('id', sessionId)
      .eq('user_id', user.id)
      .single()

    if (fetchError) throw fetchError

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

    if (updateError) throw updateError

    return new Response(JSON.stringify({
      success: true,
      message: 'Prompt result updated'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Error updating prompt result:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

#### Function 4: `complete-activity`

```typescript
// supabase/functions/complete-activity/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { dayNumber, totalScore, sessionId } = await req.json()

    // Fetch user record
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('total_score, daily_practice_scores')
      .eq('id', user.id)
      .single()

    if (userError) throw userError

    // Calculate new totals
    const newTotalScore = (userData.total_score || 0) + totalScore
    const updatedScores = userData.daily_practice_scores || {}
    updatedScores[dayNumber] = totalScore

    // Update user record
    const { error: updateUserError } = await supabase
      .from('users')
      .update({
        last_completed_daily_practice_activity: dayNumber,
        last_daily_practice_activity_completed_at: new Date().toISOString(),
        total_score: newTotalScore,
        daily_practice_scores: updatedScores
      })
      .eq('id', user.id)

    if (updateUserError) throw updateUserError

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
    }

    return new Response(JSON.stringify({
      success: true,
      completedDay: dayNumber,
      message: `Day ${dayNumber} completed successfully`
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

---

## Phase 2: Swift Data Models

### Step 2.1: Create Swift Models

Create these models in `Models/DailyPractice/`:

```swift
// Models/DailyPractice/Activity.swift

import Foundation

struct Activity: Codable, Identifiable {
    let id: UUID
    let dayNumber: Int
    let ageBand: String
    let moduleName: String
    let moduleDisplayName: String
    let title: String
    let description: String?
    let skillFocus: String
    let category: String?
    let activityType: String
    let isReflection: Bool
    let scenario: String
    let researchConcept: String?
    let researchKeyInsight: String?
    let researchCitation: String?
    let researchAdditionalContext: String?
    let bestApproach: String?
    let followUpQuestions: [String]?
    let prompts: [Prompt]
    let actionableTakeaway: ActionableTakeaway

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, scenario, prompts
        case dayNumber = "day_number"
        case ageBand = "age_band"
        case moduleName = "module_name"
        case moduleDisplayName = "module_display_name"
        case skillFocus = "skill_focus"
        case activityType = "activity_type"
        case isReflection = "is_reflection"
        case researchConcept = "research_concept"
        case researchKeyInsight = "research_key_insight"
        case researchCitation = "research_citation"
        case researchAdditionalContext = "research_additional_context"
        case bestApproach = "best_approach"
        case followUpQuestions = "follow_up_questions"
        case actionableTakeaway = "actionable_takeaway"
    }
}

struct Prompt: Codable, Identifiable {
    let promptId: String
    let type: PromptType
    let promptText: String
    let order: Int
    let points: Int
    let branchLogic: BranchLogic?
    let options: [PromptOption]
    let config: PromptConfig?
    
    var id: String { promptId }
    
    enum CodingKeys: String, CodingKey {
        case promptId, type, order, points, options, config
        case promptText = "promptText"
        case branchLogic = "branchLogic"
    }
}

enum PromptType: String, Codable {
    case stateIdentification = "state-identification"
    case bestResponse = "best-response"
    case sequentialChoice = "sequential-choice"
    case spotMistake = "spot-mistake"
    case dialogueCompletion = "dialogue-completion"
    case beforeAfterComparison = "before-after-comparison"
    case whatHappensNext = "what-happens-next"
    case sequencing = "sequencing"
    case selectAll = "select-all"
    case rating = "rating"
    case matching = "matching"
    case textInput = "text-input"
    case reflection = "reflection"
}

struct BranchLogic: Codable {
    let condition: BranchCondition
    let nextPrompt: String
}

struct BranchCondition: Codable {
    let ifSelected: String
    let `operator`: String
}

struct PromptOption: Codable, Identifiable {
    let optionId: String
    let optionText: String
    let correct: Bool
    let points: Int
    let feedback: String
    let metadata: OptionMetadata?
    let scienceNote: ScienceNote?
    
    var id: String { optionId }
    
    enum CodingKeys: String, CodingKey {
        case optionId, correct, points, feedback, metadata
        case optionText = "optionText"
        case scienceNote = "scienceNote"
    }
}

struct OptionMetadata: Codable {
    let version: String?
    let matchTarget: String?
    let correctOrder: Int?
}

struct ScienceNote: Codable {
    let brief: String
    let citation: String?
    let showCitation: Bool
}

struct PromptConfig: Codable {
    let allowMultiple: Bool?
    let minCorrect: Int?
    let scaleType: String?
    let scaleRange: [Int]?
    let inputType: String?
    let wordBank: [String]?
    let sequenceType: String?
}

struct ActionableTakeaway: Codable {
    let toolName: String
    let toolType: String?
    let whenToUse: String
    let howTo: [String]
    let whyItWorks: String
    let tryItWhen: String?
    let example: TakeawayExample?
}

struct TakeawayExample: Codable {
    let situation: String
    let action: String
    let outcome: String
}
```

### Step 2.2: Create Response Models

```swift
// Models/DailyPractice/ActivityResponse.swift

struct GetActivityResponse: Codable {
    let dayNumber: Int?
    let activity: Activity?
    let userProgress: UserProgress?
    let error: String?
    let message: String?
    let lastCompleted: Int?
    let completedAt: String?
}

struct UserProgress: Codable {
    let lastCompleted: Int
    let currentDay: Int
}

struct CompleteActivityResponse: Codable {
    let success: Bool
    let completedDay: Int?
    let message: String?
    let error: String?
}

struct SessionResponse: Codable {
    let success: Bool
    let sessionId: UUID?
    let message: String?
    let error: String?
}
```

---

## Phase 3: API Service Layer

### Step 3.1: Create API Service

```swift
// Services/DailyPracticeAPI.swift

import Foundation
import Supabase

@MainActor
class DailyPracticeAPI {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // Fetch today's activity
    func getTodayActivity() async throws -> GetActivityResponse {
        let response = try await supabase.functions.invoke(
            "get-daily-activity",
            options: FunctionInvokeOptions()
        )
        
        let decoder = JSONDecoder()
        let data = response.data
        return try decoder.decode(GetActivityResponse.self, from: data)
    }
    
    // Start analytics session (non-blocking)
    func startSession(activityId: UUID, dayNumber: Int) async {
        do {
            let body = [
                "activityId": activityId.uuidString,
                "dayNumber": dayNumber
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            
            _ = try await supabase.functions.invoke(
                "start-practice-session",
                options: FunctionInvokeOptions(body: bodyData)
            )
        } catch {
            print("Failed to start session (non-critical):", error)
        }
    }
    
    // Update prompt result (non-blocking)
    func updatePromptResult(sessionId: UUID?, promptResult: PromptResult) async {
        guard let sessionId = sessionId else { return }
        
        do {
            let encoder = JSONEncoder()
            let promptData = try encoder.encode(promptResult)
            let body = [
                "sessionId": sessionId.uuidString,
                "promptResult": try JSONSerialization.jsonObject(with: promptData)
            ] as [String : Any]
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            
            _ = try await supabase.functions.invoke(
                "update-prompt-result",
                options: FunctionInvokeOptions(body: bodyData)
            )
        } catch {
            print("Failed to update prompt result (non-critical):", error)
        }
    }
    
    // Complete activity (CRITICAL - must succeed)
    func completeActivity(dayNumber: Int, totalScore: Int, sessionId: UUID?) async throws -> CompleteActivityResponse {
        var body: [String: Any] = [
            "dayNumber": dayNumber,
            "totalScore": totalScore
        ]
        
        if let sessionId = sessionId {
            body["sessionId"] = sessionId.uuidString
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response = try await supabase.functions.invoke(
            "complete-activity",
            options: FunctionInvokeOptions(body: bodyData)
        )
        
        let decoder = JSONDecoder()
        return try decoder.decode(CompleteActivityResponse.self, from: response.data)
    }
}

// Analytics tracking model
struct PromptResult: Codable {
    let promptId: String
    let tries: Int
    let logs: [AttemptLog]
    let pointsEarned: Int
    let completed: Bool
}

struct AttemptLog: Codable {
    let optionId: String
    let correct: Bool
    let timestamp: String
}
```

---

## Phase 4: View Models

### Step 4.1: Home View Model

```swift
// ViewModels/DailyPracticeHomeViewModel.swift

import Foundation
import Observation

@Observable
@MainActor
class DailyPracticeHomeViewModel {
    enum LoadingState {
        case idle
        case loading
        case loaded
        case alreadyCompleted
        case noneAvailable
        case error(String)
    }
    
    var loadingState: LoadingState = .idle
    var activity: Activity?
    var dayNumber: Int?
    var lastCompletedDay: Int = 0
    var completedAt: String?
    
    private let api: DailyPracticeAPI
    
    init(api: DailyPracticeAPI) {
        self.api = api
    }
    
    func loadTodayActivity() async {
        loadingState = .loading
        
        do {
            let response = try await api.getTodayActivity()
            
            // Handle already completed
            if let error = response.error, error == "already_completed" {
                lastCompletedDay = response.lastCompleted ?? 0
                completedAt = response.completedAt
                loadingState = .alreadyCompleted
                return
            }
            
            // Handle not found
            if let error = response.error, error == "not_found" {
                loadingState = .noneAvailable
                return
            }
            
            // Handle success
            if let activity = response.activity, let dayNumber = response.dayNumber {
                self.activity = activity
                self.dayNumber = dayNumber
                self.lastCompletedDay = response.userProgress?.lastCompleted ?? 0
                loadingState = .loaded
            } else {
                loadingState = .error("Unexpected response format")
            }
            
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func retry() async {
        await loadTodayActivity()
    }
}
```

### Step 4.2: Activity View Model

```swift
// ViewModels/DailyPracticeActivityViewModel.swift

import Foundation
import Observation

@Observable
@MainActor
class DailyPracticeActivityViewModel {
    // Activity data
    let activity: Activity
    let dayNumber: Int
    
    // Session tracking
    private(set) var sessionId: UUID?
    
    // Progress tracking
    private(set) var currentPromptIndex = 0
    private(set) var totalScore = 0
    private(set) var promptAttempts: [String: PromptAttempt] = [:]
    
    // UI state
    var selectedOption: String?
    var selectedOptions: Set<String> = []
    var orderedOptions: [String] = []
    var showFeedback = false
    var currentFeedback: PromptOption?
    var isSubmitting = false
    var isCompleting = false
    
    private let api: DailyPracticeAPI
    
    var currentPrompt: Prompt {
        activity.prompts[currentPromptIndex]
    }
    
    var isLastPrompt: Bool {
        currentPromptIndex == activity.prompts.count - 1
    }
    
    var canSubmit: Bool {
        switch currentPrompt.type {
        case .selectAll:
            return !selectedOptions.isEmpty
        case .sequencing:
            return orderedOptions.count == currentPrompt.options.count
        default:
            return selectedOption != nil
        }
    }
    
    init(activity: Activity, dayNumber: Int, api: DailyPracticeAPI) {
        self.activity = activity
        self.dayNumber = dayNumber
        self.api = api
        
        // Start session (non-blocking)
        Task {
            await startSession()
        }
    }
    
    private func startSession() async {
        await api.startSession(activityId: activity.id, dayNumber: dayNumber)
        // We don't wait for response or store sessionId since it's optional analytics
    }
    
    func selectOption(_ optionId: String) {
        selectedOption = optionId
    }
    
    func toggleOptionSelection(_ optionId: String) {
        if selectedOptions.contains(optionId) {
            selectedOptions.remove(optionId)
        } else {
            selectedOptions.insert(optionId)
        }
    }
    
    func submitAnswer() {
        isSubmitting = true
        
        // Get current attempts for this prompt
        var attempt = promptAttempts[currentPrompt.promptId] ?? PromptAttempt(
            promptId: currentPrompt.promptId,
            attemptedOptions: [],
            pointsEarned: 0,
            completed: false
        )
        
        // Determine selected option(s)
        let selectedIds: [String]
        switch currentPrompt.type {
        case .selectAll:
            selectedIds = Array(selectedOptions)
        case .sequencing:
            selectedIds = [orderedOptions.first ?? ""] // Simplified for now
        default:
            selectedIds = selectedOption.map { [$0] } ?? []
        }
        
        guard let selectedId = selectedIds.first else {
            isSubmitting = false
            return
        }
        
        // Find the option
        guard let option = currentPrompt.options.first(where: { $0.optionId == selectedId }) else {
            isSubmitting = false
            return
        }
        
        // Calculate points
        let attemptNumber = attempt.attemptedOptions.count + 1
        let pointsEarned = calculatePoints(
            totalPoints: currentPrompt.points,
            totalOptions: currentPrompt.options.count,
            attemptNumber: attemptNumber,
            isCorrect: option.correct
        )
        
        // Update attempt
        attempt.attemptedOptions.append(selectedId)
        if option.correct {
            attempt.completed = true
            attempt.pointsEarned = pointsEarned
            totalScore += pointsEarned
        }
        promptAttempts[currentPrompt.promptId] = attempt
        
        // Show feedback
        currentFeedback = option
        showFeedback = true
        isSubmitting = false
        
        // Track analytics (non-blocking)
        Task {
            let promptResult = PromptResult(
                promptId: currentPrompt.promptId,
                tries: attemptNumber,
                logs: attempt.attemptedOptions.map { optId in
                    AttemptLog(
                        optionId: optId,
                        correct: currentPrompt.options.first(where: { $0.optionId == optId })?.correct ?? false,
                        timestamp: ISO8601DateFormatter().string(from: Date())
                    )
                },
                pointsEarned: attempt.pointsEarned,
                completed: attempt.completed
            )
            await api.updatePromptResult(sessionId: sessionId, promptResult: promptResult)
        }
    }
    
    func tryAgain() {
        showFeedback = false
        selectedOption = nil
        selectedOptions = []
        currentFeedback = nil
    }
    
    func continueToNext() {
        showFeedback = false
        selectedOption = nil
        selectedOptions = []
        currentFeedback = nil
        currentPromptIndex += 1
    }
    
    func completeActivity() async throws {
        isCompleting = true
        
        do {
            let response = try await api.completeActivity(
                dayNumber: dayNumber,
                totalScore: totalScore,
                sessionId: sessionId
            )
            
            if !response.success {
                throw NSError(domain: "DailyPractice", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: response.message ?? "Failed to complete activity"
                ])
            }
            
            isCompleting = false
        } catch {
            isCompleting = false
            throw error
        }
    }
    
    func isOptionDisabled(_ optionId: String) -> Bool {
        guard let attempt = promptAttempts[currentPrompt.promptId] else {
            return false
        }
        return attempt.attemptedOptions.contains(optionId)
    }
    
    private func calculatePoints(totalPoints: Int, totalOptions: Int, attemptNumber: Int, isCorrect: Bool) -> Int {
        // Full points on first correct attempt
        if attemptNumber == 1 && isCorrect {
            return totalPoints
        }
        
        // No points for wrong answers
        if !isCorrect {
            return 0
        }
        
        // No partial credit for binary choices
        if totalOptions <= 2 {
            return 0
        }
        
        // Calculate partial credit
        let remainingAttempts = totalOptions - attemptNumber
        if remainingAttempts <= 0 {
            return 0
        }
        
        let numerator = Double(totalPoints * remainingAttempts)
        let denominator = Double(totalOptions - 1)
        let points = Int(ceil(numerator / denominator))
        
        return max(0, points)
    }
}

struct PromptAttempt {
    let promptId: String
    var attemptedOptions: [String]
    var pointsEarned: Int
    var completed: Bool
}
```

---

## Phase 5: UI Components

### Step 5.1: Home Screen

```swift
// Views/DailyPractice/DailyPracticeHomeView.swift

import SwiftUI

struct DailyPracticeHomeView: View {
    @State private var viewModel: DailyPracticeHomeViewModel
    @State private var navigateToActivity = false
    
    init(api: DailyPracticeAPI) {
        self.viewModel = DailyPracticeHomeViewModel(api: api)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadingState {
                case .idle, .loading:
                    LoadingView()
                    
                case .loaded:
                    if let activity = viewModel.activity, let dayNumber = viewModel.dayNumber {
                        ReadyToStartView(
                            dayNumber: dayNumber,
                            title: activity.title,
                            onStart: { navigateToActivity = true }
                        )
                    }
                    
                case .alreadyCompleted:
                    CompletedTodayView(
                        lastCompletedDay: viewModel.lastCompletedDay,
                        completedAt: viewModel.completedAt
                    )
                    
                case .noneAvailable:
                    NoneAvailableView()
                    
                case .error(let message):
                    ErrorView(message: message, onRetry: {
                        Task { await viewModel.retry() }
                    })
                }
            }
            .navigationTitle("Daily Practice")
            .navigationDestination(isPresented: $navigateToActivity) {
                if let activity = viewModel.activity, let dayNumber = viewModel.dayNumber {
                    DailyPracticeActivityView(
                        activity: activity,
                        dayNumber: dayNumber,
                        api: DailyPracticeAPI(supabase: /* inject */)
                    )
                }
            }
        }
        .task {
            await viewModel.loadTodayActivity()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading daily practice...")
                .foregroundColor(.secondary)
        }
    }
}

struct ReadyToStartView: View {
    let dayNumber: Int
    let title: String
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Day \(dayNumber)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .italic()
            
            // Placeholder for illustration
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text(title)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: onStart) {
                Text("Start Today's Daily Practice")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

struct CompletedTodayView: View {
    let lastCompletedDay: Int
    let completedAt: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 80))
            
            Text("Great work!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've finished your daily practice for today. Come back tomorrow for a new challenge.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if lastCompletedDay > 0 {
                Text("You've completed Day \(lastCompletedDay)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct NoneAvailableView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're all caught up!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please check back later for new activities.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
```

### Step 5.2: Activity Screen

```swift
// Views/DailyPractice/DailyPracticeActivityView.swift

import SwiftUI

struct DailyPracticeActivityView: View {
    @State private var viewModel: DailyPracticeActivityViewModel
    @State private var showTakeaway = false
    @State private var showResults = false
    @State private var showCompletionError = false
    @State private var completionErrorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    init(activity: Activity, dayNumber: Int, api: DailyPracticeAPI) {
        self.viewModel = DailyPracticeActivityViewModel(
            activity: activity,
            dayNumber: dayNumber,
            api: api
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HeaderView(
                    dayNumber: viewModel.dayNumber,
                    title: viewModel.activity.title,
                    totalScore: viewModel.totalScore
                )
                
                // Progress
                ProgressView(
                    current: viewModel.currentPromptIndex + 1,
                    total: viewModel.activity.prompts.count
                )
                
                // Scenario
                ScenarioCard(text: viewModel.activity.scenario)
                
                // Prompt
                PromptCard(
                    prompt: viewModel.currentPrompt,
                    selectedOption: $viewModel.selectedOption,
                    selectedOptions: $viewModel.selectedOptions,
                    orderedOptions: $viewModel.orderedOptions,
                    isOptionDisabled: viewModel.isOptionDisabled
                )
                
                // Feedback
                if viewModel.showFeedback, let feedback = viewModel.currentFeedback {
                    FeedbackCard(option: feedback)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            ActionButtonView(
                showFeedback: viewModel.showFeedback,
                isCorrect: viewModel.currentFeedback?.correct ?? false,
                isLastPrompt: viewModel.isLastPrompt,
                canSubmit: viewModel.canSubmit,
                isSubmitting: viewModel.isSubmitting,
                dayNumber: viewModel.dayNumber,
                onSubmit: viewModel.submitAnswer,
                onTryAgain: viewModel.tryAgain,
                onContinue: viewModel.continueToNext,
                onComplete: { showTakeaway = true }
            )
            .padding()
            .background(Color(uiColor: .systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTakeaway) {
            ActionableTakeawayView(
                takeaway: viewModel.activity.actionableTakeaway,
                onDismiss: {
                    showTakeaway = false
                    Task {
                        do {
                            try await viewModel.completeActivity()
                            showResults = true
                        } catch {
                            completionErrorMessage = error.localizedDescription
                            showCompletionError = true
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showResults) {
            ResultsView(
                dayNumber: viewModel.dayNumber,
                totalScore: viewModel.totalScore,
                onDismiss: {
                    showResults = false
                    dismiss()
                }
            )
        }
        .alert("Error Completing Activity", isPresented: $showCompletionError) {
            Button("Try Again") {
                Task {
                    do {
                        try await viewModel.completeActivity()
                        showResults = true
                    } catch {
                        completionErrorMessage = error.localizedDescription
                        showCompletionError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(completionErrorMessage)
        }
    }
}

// Sub-components would go here (HeaderView, ScenarioCard, PromptCard, FeedbackCard, ActionButtonView, etc.)
// These are omitted for brevity but should be implemented as separate View structs
```

---

## Phase 6: Testing & Deployment

### Step 6.1: Unit Tests

Create tests for:
- Scoring algorithm
- Date comparison logic
- View model state transitions

### Step 6.2: Integration Tests

Test:
- API calls with mock responses
- Database queries
- Edge Functions end-to-end

### Step 6.3: Seed Database

Add initial activities (minimum 14 days × 3 age bands = 42 activities)

### Step 6.4: Deploy

1. Deploy Edge Functions to Supabase
2. Test in production environment
3. Monitor error rates and completion metrics

---

## Success Criteria

- [ ] User can complete one daily practice per day
- [ ] Content filters correctly by age
- [ ] Scoring calculates accurately
- [ ] Completion updates user record
- [ ] Analytics tracked (non-blocking failures okay)
- [ ] All interaction patterns render correctly
- [ ] Takeaway screen appears after final prompt
- [ ] Results screen shows accurate data

---

## Estimated Timeline

- **Phase 1 (Database):** 1 day
- **Phase 2 (Models):** 1 day
- **Phase 3 (API):** 2 days
- **Phase 4 (ViewModels):** 2 days
- **Phase 5 (UI):** 4 days
- **Phase 6 (Testing):** 2 days

**Total:** ~12 days of focused development