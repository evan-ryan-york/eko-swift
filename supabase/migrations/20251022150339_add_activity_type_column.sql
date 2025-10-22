-- Add missing activity_type column
ALTER TABLE daily_practice_activities 
ADD COLUMN IF NOT EXISTS activity_type TEXT NOT NULL DEFAULT 'basic-scenario';

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
