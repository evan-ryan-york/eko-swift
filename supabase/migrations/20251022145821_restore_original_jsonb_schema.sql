-- Restore ORIGINAL JSONB schema from migration 20251020000000
-- This is what was working before

-- Drop all tables
DROP TABLE IF EXISTS prompt_options CASCADE;
DROP TABLE IF EXISTS prompts CASCADE;
DROP TABLE IF EXISTS actionable_takeaways CASCADE;
DROP TABLE IF EXISTS daily_practice_results CASCADE;
DROP TABLE IF EXISTS daily_practice_activities CASCADE;

-- =============================================================================
-- 1. Create daily_practice_activities table
-- =============================================================================
CREATE TABLE IF NOT EXISTS daily_practice_activities (
  -- Identity
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_number INTEGER NOT NULL,
  age_band TEXT NOT NULL CHECK (age_band IN ('6-9', '10-12', '13-16')),

  -- Module organization
  module_name TEXT NOT NULL,
  module_display_name TEXT NOT NULL,

  -- Metadata
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  skill_focus TEXT,

  -- Content type
  is_reflection BOOLEAN DEFAULT false,

  -- Main content
  scenario TEXT NOT NULL,

  -- Prompts (JSONB for flexibility)
  prompts JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- Actionable takeaway
  actionable_takeaway JSONB NOT NULL,

  -- Optional enrichment
  best_approach TEXT,
  follow_up_questions TEXT[] DEFAULT ARRAY[]::TEXT[],

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for daily_practice_activities
CREATE UNIQUE INDEX IF NOT EXISTS idx_day_age_band
ON daily_practice_activities(day_number, age_band);

CREATE INDEX IF NOT EXISTS idx_day_number
ON daily_practice_activities(day_number);

CREATE INDEX IF NOT EXISTS idx_module
ON daily_practice_activities(module_name);

CREATE INDEX IF NOT EXISTS idx_age_band
ON daily_practice_activities(age_band);

-- Add constraints (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_age_band') THEN
        ALTER TABLE daily_practice_activities
        ADD CONSTRAINT check_age_band CHECK (age_band IN ('6-9', '10-12', '13-16'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_day_number_positive') THEN
        ALTER TABLE daily_practice_activities
        ADD CONSTRAINT check_day_number_positive CHECK (day_number > 0);
    END IF;
END$$;

-- =============================================================================
-- 2. Create daily_practice_results table (Analytics)
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
CREATE INDEX IF NOT EXISTS idx_results_user
ON daily_practice_results(user_id);

CREATE INDEX IF NOT EXISTS idx_results_user_day
ON daily_practice_results(user_id, day_number);

CREATE INDEX IF NOT EXISTS idx_results_completed
ON daily_practice_results(completed);

CREATE INDEX IF NOT EXISTS idx_results_activity
ON daily_practice_results(activity_id);

-- =============================================================================
-- 3. Create or update updated_at trigger function
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to new tables
DROP TRIGGER IF EXISTS update_daily_practice_activities_updated_at ON daily_practice_activities;
CREATE TRIGGER update_daily_practice_activities_updated_at
BEFORE UPDATE ON daily_practice_activities
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_practice_results_updated_at ON daily_practice_results;
CREATE TRIGGER update_daily_practice_results_updated_at
BEFORE UPDATE ON daily_practice_results
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 4. Enable Row Level Security (RLS)
-- =============================================================================
ALTER TABLE daily_practice_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_practice_results ENABLE ROW LEVEL SECURITY;

-- Activities are readable by all authenticated users
DROP POLICY IF EXISTS "Activities readable by authenticated users" ON daily_practice_activities;
CREATE POLICY "Activities readable by authenticated users"
ON daily_practice_activities FOR SELECT
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
-- 5. Grant permissions
-- =============================================================================
GRANT SELECT ON daily_practice_activities TO authenticated;
GRANT ALL ON daily_practice_results TO authenticated;
