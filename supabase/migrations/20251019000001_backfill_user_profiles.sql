-- Backfill user_profiles for existing users
-- This script ensures all existing users have a user_profile record
-- Run this AFTER the main onboarding migration (20251019000000_create_onboarding_tables.sql)

-- Insert user_profiles for existing users who don't have one
-- Set them to 'COMPLETE' to skip onboarding (assuming they're already using the app)
INSERT INTO user_profiles (id, onboarding_state)
SELECT
    id,
    'COMPLETE' -- Existing users skip onboarding
FROM auth.users
WHERE id NOT IN (SELECT id FROM user_profiles)
ON CONFLICT (id) DO NOTHING;

-- Log the backfill results
DO $$
DECLARE
    backfilled_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO backfilled_count
    FROM user_profiles
    WHERE onboarding_state = 'COMPLETE';

    RAISE NOTICE 'Backfilled % existing users with COMPLETE onboarding state', backfilled_count;
END $$;
