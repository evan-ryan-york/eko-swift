-- Restore normalized schema (separate tables for prompts, options, takeaways)
-- This is the schema that was working before

DROP TABLE IF EXISTS daily_practice_activities CASCADE;
DROP TABLE IF EXISTS daily_practice_results CASCADE;

-- Main activities table (no JSONB columns)
CREATE TABLE daily_practice_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  day_number INTEGER NOT NULL,
  age_band TEXT NOT NULL CHECK (age_band IN ('6-9', '10-12', '13-16')),
  module_name TEXT NOT NULL,
  module_display_name TEXT NOT NULL,
  
  title TEXT NOT NULL,
  description TEXT,
  skill_focus TEXT NOT NULL,
  category TEXT,
  activity_type TEXT NOT NULL DEFAULT 'basic-scenario',
  is_reflection BOOLEAN DEFAULT FALSE,
  
  scenario TEXT NOT NULL,
  
  research_concept TEXT,
  research_key_insight TEXT,
  research_citation TEXT,
  research_additional_context TEXT,
  
  best_approach TEXT,
  follow_up_questions JSONB DEFAULT '[]'::jsonb,
  
  UNIQUE(day_number, age_band)
);

-- Prompts table
CREATE TABLE prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id) ON DELETE CASCADE,
  
  prompt_id TEXT NOT NULL,
  type TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  points INTEGER DEFAULT 10,
  
  UNIQUE(activity_id, prompt_id)
);

-- Prompt options table
CREATE TABLE prompt_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  prompt_id UUID NOT NULL REFERENCES prompts(id) ON DELETE CASCADE,
  
  option_id TEXT NOT NULL,
  option_text TEXT NOT NULL,
  correct BOOLEAN DEFAULT FALSE,
  points INTEGER DEFAULT 0,
  feedback TEXT NOT NULL,
  
  science_note_brief TEXT,
  science_note_citation TEXT,
  science_note_show_citation BOOLEAN DEFAULT FALSE,
  
  UNIQUE(prompt_id, option_id)
);

-- Actionable takeaways table
CREATE TABLE actionable_takeaways (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id) ON DELETE CASCADE,
  
  tool_name TEXT NOT NULL,
  tool_type TEXT,
  when_to_use TEXT NOT NULL,
  why_it_works TEXT NOT NULL,
  try_it_when TEXT,
  
  how_to JSONB NOT NULL,
  example JSONB,
  
  UNIQUE(activity_id)
);

-- Results table
CREATE TABLE daily_practice_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id),
  day_number INTEGER NOT NULL,
  
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  
  prompt_results JSONB DEFAULT '[]'::jsonb,
  total_score INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_activities_day_age ON daily_practice_activities(day_number, age_band);
CREATE INDEX idx_activities_module ON daily_practice_activities(module_name);
CREATE INDEX idx_prompts_activity ON prompts(activity_id);
CREATE INDEX idx_prompts_activity_order ON prompts(activity_id, order_index);
CREATE INDEX idx_options_prompt ON prompt_options(prompt_id);
CREATE INDEX idx_takeaways_activity ON actionable_takeaways(activity_id);
CREATE INDEX idx_results_user ON daily_practice_results(user_id);
CREATE INDEX idx_results_user_day ON daily_practice_results(user_id, day_number);
CREATE INDEX idx_results_completed ON daily_practice_results(completed);
CREATE INDEX idx_results_activity ON daily_practice_results(activity_id);

-- Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_daily_practice_activities_updated_at ON daily_practice_activities;
CREATE TRIGGER update_daily_practice_activities_updated_at
BEFORE UPDATE ON daily_practice_activities
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_practice_results_updated_at ON daily_practice_results;
CREATE TRIGGER update_daily_practice_results_updated_at
BEFORE UPDATE ON daily_practice_results
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE daily_practice_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompt_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE actionable_takeaways ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_practice_results ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Activities readable by authenticated users" ON daily_practice_activities;
CREATE POLICY "Activities readable by authenticated users"
ON daily_practice_activities FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Prompts readable by authenticated users" ON prompts;
CREATE POLICY "Prompts readable by authenticated users"
ON prompts FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Options readable by authenticated users" ON prompt_options;
CREATE POLICY "Options readable by authenticated users"
ON prompt_options FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Takeaways readable by authenticated users" ON actionable_takeaways;
CREATE POLICY "Takeaways readable by authenticated users"
ON actionable_takeaways FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Results viewable by owner" ON daily_practice_results;
CREATE POLICY "Results viewable by owner"
ON daily_practice_results FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Results insertable by owner" ON daily_practice_results;
CREATE POLICY "Results insertable by owner"
ON daily_practice_results FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Results updatable by owner" ON daily_practice_results;
CREATE POLICY "Results updatable by owner"
ON daily_practice_results FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Permissions
GRANT SELECT ON daily_practice_activities TO authenticated;
GRANT SELECT ON prompts TO authenticated;
GRANT SELECT ON prompt_options TO authenticated;
GRANT SELECT ON actionable_takeaways TO authenticated;
GRANT ALL ON daily_practice_results TO authenticated;
