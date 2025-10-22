-- Add ALL missing columns to daily_practice_activities
ALTER TABLE daily_practice_activities 
ADD COLUMN IF NOT EXISTS research_concept TEXT,
ADD COLUMN IF NOT EXISTS research_key_insight TEXT,
ADD COLUMN IF NOT EXISTS research_citation TEXT,
ADD COLUMN IF NOT EXISTS research_additional_context TEXT;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
