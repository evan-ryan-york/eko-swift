-- Base Tables for Eko App
-- This creates the foundational children table that Lyra depends on

-- ============================================================================
-- 1. Children table
-- ============================================================================

CREATE TABLE IF NOT EXISTS children (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 6 AND age <= 16),
    temperament TEXT NOT NULL CHECK (temperament IN ('easygoing', 'sensitive', 'spirited', 'cautious')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_children_user_id ON children(user_id);
CREATE INDEX IF NOT EXISTS idx_children_age ON children(age);

-- Row Level Security
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own children"
ON children FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own children"
ON children FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own children"
ON children FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own children"
ON children FOR DELETE
USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_children_updated_at ON children;
CREATE TRIGGER update_children_updated_at
    BEFORE UPDATE ON children
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE children IS 'Child profiles for Eko parenting app';
COMMENT ON COLUMN children.temperament IS 'Child temperament type: easygoing, sensitive, spirited, or cautious';
