-- Lyra AI Chat Feature - Database Schema
-- This migration creates tables for conversations, messages, and child memory

-- ============================================================================
-- 1. Update children table to include temperament scores
-- ============================================================================

-- Add temperament scoring columns (1-10 scale)
ALTER TABLE children
ADD COLUMN IF NOT EXISTS temperament_talkative INTEGER DEFAULT 5 CHECK (temperament_talkative >= 1 AND temperament_talkative <= 10),
ADD COLUMN IF NOT EXISTS temperament_sensitivity INTEGER DEFAULT 5 CHECK (temperament_sensitivity >= 1 AND temperament_sensitivity <= 10),
ADD COLUMN IF NOT EXISTS temperament_accountability INTEGER DEFAULT 5 CHECK (temperament_accountability >= 1 AND temperament_accountability <= 10);

COMMENT ON COLUMN children.temperament_talkative IS 'How talkative/communicative the child is (1=quiet, 10=very talkative)';
COMMENT ON COLUMN children.temperament_sensitivity IS 'Emotional sensitivity level (1=low, 10=high)';
COMMENT ON COLUMN children.temperament_accountability IS 'Level of personal accountability (1=low, 10=high)';

-- ============================================================================
-- 2. Conversations table
-- ============================================================================

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
    title TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_child_id ON conversations(child_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user_child ON conversations(user_id, child_id);
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

-- Composite index for common query pattern (active conversation for user+child)
CREATE INDEX IF NOT EXISTS idx_conversations_user_child_status_updated
ON conversations(user_id, child_id, status, updated_at DESC);

COMMENT ON TABLE conversations IS 'Lyra AI chat conversations between parents and AI';
COMMENT ON COLUMN conversations.status IS 'active = ongoing, completed = finished and summarized';
COMMENT ON COLUMN conversations.title IS 'Auto-generated summary title after completion';

-- ============================================================================
-- 3. Messages table
-- ============================================================================

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    sources JSONB DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
ON messages(conversation_id, created_at);

COMMENT ON TABLE messages IS 'Individual messages within Lyra conversations';
COMMENT ON COLUMN messages.role IS 'user = parent, assistant = Lyra AI, system = automated messages';
COMMENT ON COLUMN messages.sources IS 'JSON array of citations/sources for assistant responses';

-- Example sources structure:
-- [
--   {
--     "id": "uuid",
--     "title": "Understanding Child Development",
--     "url": "https://example.com/article",
--     "excerpt": "Relevant text excerpt..."
--   }
-- ]

-- ============================================================================
-- 4. Child Memory table (Long-term AI context)
-- ============================================================================

CREATE TABLE IF NOT EXISTS child_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE UNIQUE,
    behavioral_themes JSONB DEFAULT '[]'::jsonb,
    communication_strategies JSONB DEFAULT '[]'::jsonb,
    significant_events JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_child_memory_child_id ON child_memory(child_id);
CREATE INDEX IF NOT EXISTS idx_child_memory_updated_at ON child_memory(updated_at DESC);

-- GIN indexes for JSONB searching (if needed later)
CREATE INDEX IF NOT EXISTS idx_child_memory_behavioral_themes
ON child_memory USING GIN (behavioral_themes);

CREATE INDEX IF NOT EXISTS idx_child_memory_communication_strategies
ON child_memory USING GIN (communication_strategies);

COMMENT ON TABLE child_memory IS 'Long-term AI memory for personalized child context';
COMMENT ON COLUMN child_memory.behavioral_themes IS 'Recurring behavioral patterns observed';
COMMENT ON COLUMN child_memory.communication_strategies IS 'Effective communication approaches';
COMMENT ON COLUMN child_memory.significant_events IS 'Important life events affecting behavior';

-- Example JSON structures:
-- behavioral_themes: [
--   {
--     "theme": "bedtime resistance",
--     "frequency": 5,
--     "first_observed": "2025-01-15",
--     "last_observed": "2025-02-10"
--   }
-- ]
--
-- communication_strategies: [
--   {
--     "strategy": "choice framework",
--     "effectiveness": "high",
--     "used_count": 3,
--     "notes": "Works well before bedtime"
--   }
-- ]
--
-- significant_events: [
--   {
--     "event": "Started new school",
--     "date": "2025-01-08",
--     "impact": "Increased anxiety around transitions"
--   }
-- ]

-- ============================================================================
-- 5. Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_memory ENABLE ROW LEVEL SECURITY;

-- Conversations: Users can only access their own conversations
CREATE POLICY "Users can view their own conversations"
ON conversations FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conversations"
ON conversations FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations"
ON conversations FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
ON conversations FOR DELETE
USING (auth.uid() = user_id);

-- Messages: Users can access messages in their own conversations
CREATE POLICY "Users can view messages in their conversations"
ON messages FOR SELECT
USING (
    conversation_id IN (
        SELECT id FROM conversations WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert messages in their conversations"
ON messages FOR INSERT
WITH CHECK (
    conversation_id IN (
        SELECT id FROM conversations WHERE user_id = auth.uid()
    )
);

-- Note: No UPDATE/DELETE policies for messages (append-only for audit trail)

-- Child Memory: Users can access memory for their own children
CREATE POLICY "Users can view memory for their children"
ON child_memory FOR SELECT
USING (
    child_id IN (
        SELECT id FROM children WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert memory for their children"
ON child_memory FOR INSERT
WITH CHECK (
    child_id IN (
        SELECT id FROM children WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can update memory for their children"
ON child_memory FOR UPDATE
USING (
    child_id IN (
        SELECT id FROM children WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    child_id IN (
        SELECT id FROM children WHERE user_id = auth.uid()
    )
);

-- ============================================================================
-- 6. Triggers for updated_at timestamps
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for conversations
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for child_memory
DROP TRIGGER IF EXISTS update_child_memory_updated_at ON child_memory;
CREATE TRIGGER update_child_memory_updated_at
    BEFORE UPDATE ON child_memory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. Helper Functions
-- ============================================================================

-- Function to get or create child memory record
CREATE OR REPLACE FUNCTION get_or_create_child_memory(p_child_id UUID)
RETURNS UUID AS $$
DECLARE
    v_memory_id UUID;
BEGIN
    -- Try to get existing memory record
    SELECT id INTO v_memory_id
    FROM child_memory
    WHERE child_id = p_child_id;

    -- If not found, create it
    IF v_memory_id IS NULL THEN
        INSERT INTO child_memory (child_id)
        VALUES (p_child_id)
        RETURNING id INTO v_memory_id;
    END IF;

    RETURN v_memory_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update child memory with new insights
CREATE OR REPLACE FUNCTION update_child_memory_insights(
    p_child_id UUID,
    p_new_behavioral_themes JSONB DEFAULT NULL,
    p_new_strategies JSONB DEFAULT NULL,
    p_new_events JSONB DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Ensure memory record exists
    PERFORM get_or_create_child_memory(p_child_id);

    -- Update behavioral themes (append new, don't replace)
    IF p_new_behavioral_themes IS NOT NULL THEN
        UPDATE child_memory
        SET behavioral_themes = behavioral_themes || p_new_behavioral_themes
        WHERE child_id = p_child_id;
    END IF;

    -- Update communication strategies
    IF p_new_strategies IS NOT NULL THEN
        UPDATE child_memory
        SET communication_strategies = communication_strategies || p_new_strategies
        WHERE child_id = p_child_id;
    END IF;

    -- Update significant events
    IF p_new_events IS NOT NULL THEN
        UPDATE child_memory
        SET significant_events = significant_events || p_new_events
        WHERE child_id = p_child_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_child_memory_insights IS 'Appends new insights to child memory from completed conversations';

-- ============================================================================
-- 8. Sample Data (Optional - for testing)
-- ============================================================================

-- This section would be populated by seed.sql in development
-- Uncomment for local testing:

/*
-- Insert sample child memory (requires existing child)
INSERT INTO child_memory (child_id, behavioral_themes, communication_strategies, significant_events)
SELECT
    id,
    '[
        {
            "theme": "bedtime resistance",
            "frequency": 5,
            "first_observed": "2025-01-15",
            "last_observed": "2025-02-10"
        }
    ]'::jsonb,
    '[
        {
            "strategy": "choice framework",
            "effectiveness": "high",
            "used_count": 3,
            "notes": "Works well before bedtime"
        }
    ]'::jsonb,
    '[
        {
            "event": "Started new school",
            "date": "2025-01-08",
            "impact": "Increased anxiety around transitions"
        }
    ]'::jsonb
FROM children
LIMIT 1
ON CONFLICT (child_id) DO NOTHING;
*/
