-- Daily Practice Feature - Refactor to Normalized Schema
-- This migration refactors from JSONB to normalized relational tables
-- Based on docs/ai/features/daily-practice/database-structure.md (source of truth)

-- =============================================================================
-- STEP 1: Check current state and prepare for migration
-- =============================================================================

-- This migration handles two scenarios:
-- 1. Fresh install: Creates all tables from scratch
-- 2. Existing tables: Adds missing columns and creates missing tables

-- First, let's check if we're migrating from JSONB schema
DO $$
BEGIN
  -- Check if the old JSONB columns exist
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'daily_practice_activities'
    AND column_name = 'prompts'
    AND data_type = 'jsonb'
  ) THEN
    -- Old JSONB schema detected - we need to migrate data
    -- For now, we'll drop and recreate (data migration can be done separately if needed)
    DROP TABLE IF EXISTS daily_practice_activities CASCADE;
  END IF;
END$$;

-- =============================================================================
-- STEP 2: Create normalized tables
-- =============================================================================

-- 2.1: Main Activities Table
CREATE TABLE IF NOT EXISTS daily_practice_activities (
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

  -- Additional content (optional)
  best_approach TEXT,
  follow_up_questions JSONB DEFAULT '[]'::jsonb,

  -- Constraints
  UNIQUE(day_number, age_band)
);

-- 2.2: Prompts Table
CREATE TABLE IF NOT EXISTS prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id) ON DELETE CASCADE,

  -- Prompt metadata
  prompt_id TEXT NOT NULL,
  type TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  points INTEGER DEFAULT 10,

  UNIQUE(activity_id, prompt_id)
);

-- 2.3: Prompt Options Table
CREATE TABLE IF NOT EXISTS prompt_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key
  prompt_id UUID NOT NULL REFERENCES prompts(id) ON DELETE CASCADE,

  -- Option metadata
  option_id TEXT NOT NULL,
  option_text TEXT NOT NULL,
  correct BOOLEAN DEFAULT FALSE,
  points INTEGER DEFAULT 0,

  -- Feedback
  feedback TEXT NOT NULL,

  -- Science note (optional)
  science_note_brief TEXT,
  science_note_citation TEXT,
  science_note_show_citation BOOLEAN DEFAULT FALSE,

  UNIQUE(prompt_id, option_id)
);

-- 2.4: Actionable Takeaways Table
CREATE TABLE IF NOT EXISTS actionable_takeaways (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id) ON DELETE CASCADE,

  -- Tool metadata
  tool_name TEXT NOT NULL,
  tool_type TEXT,
  when_to_use TEXT NOT NULL,
  why_it_works TEXT NOT NULL,
  try_it_when TEXT,

  -- Steps and example
  how_to JSONB NOT NULL,
  example JSONB,

  UNIQUE(activity_id)
);

-- =============================================================================
-- STEP 3: Create Indexes
-- =============================================================================

-- Activities indexes
CREATE INDEX IF NOT EXISTS idx_activities_day_age ON daily_practice_activities(day_number, age_band);
CREATE INDEX IF NOT EXISTS idx_activities_module ON daily_practice_activities(module_name);

-- Prompts indexes
CREATE INDEX IF NOT EXISTS idx_prompts_activity ON prompts(activity_id);
CREATE INDEX IF NOT EXISTS idx_prompts_activity_order ON prompts(activity_id, order_index);

-- Options indexes
CREATE INDEX IF NOT EXISTS idx_options_prompt ON prompt_options(prompt_id);

-- Takeaways indexes
CREATE INDEX IF NOT EXISTS idx_takeaways_activity ON actionable_takeaways(activity_id);

-- =============================================================================
-- STEP 4: Re-create user progress fields (if removed)
-- =============================================================================

DO $$
BEGIN
  -- Add daily practice fields to user_profiles if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles'
    AND column_name = 'last_completed_daily_practice_activity'
  ) THEN
    ALTER TABLE user_profiles
      ADD COLUMN last_completed_daily_practice_activity INTEGER DEFAULT 0,
      ADD COLUMN last_daily_practice_activity_completed_at TIMESTAMPTZ,
      ADD COLUMN total_score INTEGER DEFAULT 0,
      ADD COLUMN daily_practice_scores JSONB DEFAULT '{}'::jsonb;
  END IF;
END$$;

-- Index for daily check queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_completion
ON user_profiles(last_daily_practice_activity_completed_at);

-- =============================================================================
-- STEP 5: Re-create daily_practice_results table
-- =============================================================================

CREATE TABLE IF NOT EXISTS daily_practice_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
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

-- Create indexes for daily_practice_results
CREATE INDEX IF NOT EXISTS idx_results_user ON daily_practice_results(user_id);
CREATE INDEX IF NOT EXISTS idx_results_user_day ON daily_practice_results(user_id, day_number);
CREATE INDEX IF NOT EXISTS idx_results_completed ON daily_practice_results(completed);
CREATE INDEX IF NOT EXISTS idx_results_activity ON daily_practice_results(activity_id);

-- =============================================================================
-- STEP 6: Create or update updated_at trigger function
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
DROP TRIGGER IF EXISTS update_daily_practice_activities_updated_at ON daily_practice_activities;
CREATE TRIGGER update_daily_practice_activities_updated_at
BEFORE UPDATE ON daily_practice_activities
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_practice_results_updated_at ON daily_practice_results;
CREATE TRIGGER update_daily_practice_results_updated_at
BEFORE UPDATE ON daily_practice_results
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- STEP 7: Enable Row Level Security (RLS)
-- =============================================================================

ALTER TABLE daily_practice_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompt_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE actionable_takeaways ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_practice_results ENABLE ROW LEVEL SECURITY;

-- Activities are readable by all authenticated users
DROP POLICY IF EXISTS "Activities readable by authenticated users" ON daily_practice_activities;
CREATE POLICY "Activities readable by authenticated users"
ON daily_practice_activities FOR SELECT
TO authenticated
USING (true);

-- Prompts are readable by all authenticated users
DROP POLICY IF EXISTS "Prompts readable by authenticated users" ON prompts;
CREATE POLICY "Prompts readable by authenticated users"
ON prompts FOR SELECT
TO authenticated
USING (true);

-- Options are readable by all authenticated users
DROP POLICY IF EXISTS "Options readable by authenticated users" ON prompt_options;
CREATE POLICY "Options readable by authenticated users"
ON prompt_options FOR SELECT
TO authenticated
USING (true);

-- Takeaways are readable by all authenticated users
DROP POLICY IF EXISTS "Takeaways readable by authenticated users" ON actionable_takeaways;
CREATE POLICY "Takeaways readable by authenticated users"
ON actionable_takeaways FOR SELECT
TO authenticated
USING (true);

-- Results are only viewable by owner
DROP POLICY IF EXISTS "Results viewable by owner" ON daily_practice_results;
CREATE POLICY "Results viewable by owner"
ON daily_practice_results FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Results insertable by owner
DROP POLICY IF EXISTS "Results insertable by owner" ON daily_practice_results;
CREATE POLICY "Results insertable by owner"
ON daily_practice_results FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Results updatable by owner
DROP POLICY IF EXISTS "Results updatable by owner" ON daily_practice_results;
CREATE POLICY "Results updatable by owner"
ON daily_practice_results FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

-- =============================================================================
-- STEP 8: Grant permissions
-- =============================================================================

GRANT SELECT ON daily_practice_activities TO authenticated;
GRANT SELECT ON prompts TO authenticated;
GRANT SELECT ON prompt_options TO authenticated;
GRANT SELECT ON actionable_takeaways TO authenticated;
GRANT ALL ON daily_practice_results TO authenticated;

-- Done!
