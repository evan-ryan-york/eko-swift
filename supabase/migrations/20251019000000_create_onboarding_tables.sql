-- Onboarding Feature - Database Schema
-- This migration adds user profiles and extends children table for onboarding flow

-- ============================================================================
-- 1. Create user_profiles table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    onboarding_state TEXT NOT NULL DEFAULT 'NOT_STARTED',
    current_child_id UUID REFERENCES children(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add constraint for valid onboarding states
ALTER TABLE user_profiles
ADD CONSTRAINT valid_onboarding_state CHECK (
    onboarding_state IN (
        'NOT_STARTED',
        'USER_INFO',
        'CHILD_INFO',
        'GOALS',
        'TOPICS',
        'DISPOSITIONS',
        'REVIEW',
        'COMPLETE'
    )
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding_state
ON user_profiles(onboarding_state);

-- Add updated_at trigger
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE user_profiles IS 'Extended user data including onboarding state';
COMMENT ON COLUMN user_profiles.onboarding_state IS 'Current step in onboarding flow';
COMMENT ON COLUMN user_profiles.current_child_id IS 'Temporary field tracking which child is being edited during onboarding';

-- ============================================================================
-- 2. Add onboarding fields to children table
-- ============================================================================

ALTER TABLE children
ADD COLUMN IF NOT EXISTS birthday DATE,
ADD COLUMN IF NOT EXISTS goals TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS topics TEXT[] DEFAULT '{}';

-- Add validation
ALTER TABLE children
ADD CONSTRAINT valid_birthday CHECK (birthday <= CURRENT_DATE);

COMMENT ON COLUMN children.birthday IS 'Child''s date of birth (ISO date)';
COMMENT ON COLUMN children.goals IS 'Parent conversation goals (1-3 items from onboarding)';
COMMENT ON COLUMN children.topics IS 'Selected conversation topic IDs (minimum 3 from onboarding)';

-- ============================================================================
-- 3. Auto-create user_profile on signup (trigger function)
-- ============================================================================

CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, onboarding_state)
    VALUES (NEW.id, 'NOT_STARTED')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

COMMENT ON FUNCTION create_user_profile IS 'Automatically creates user_profile record when new user signs up';

-- ============================================================================
-- 4. Row Level Security (RLS) Policies
-- ============================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Note: No delete policy - user_profiles cascade deletes with auth.users

-- ============================================================================
-- 5. Helper function to get user profile with onboarding state
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_with_profile(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    display_name TEXT,
    onboarding_state TEXT,
    current_child_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        au.id,
        au.email,
        au.raw_user_meta_data->>'full_name' as display_name,
        COALESCE(up.onboarding_state, 'NOT_STARTED') as onboarding_state,
        up.current_child_id
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON up.id = au.id
    WHERE au.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_with_profile IS 'Fetches user data combined with profile/onboarding state';
