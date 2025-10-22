-- Seed Data for Lyra Feature Testing
-- This creates sample data for local development and testing

-- Note: This assumes you have at least one authenticated user in auth.users
-- You can create a test user via Supabase dashboard or signup API

-- ============================================================================
-- 1. Create Test Children
-- ============================================================================

-- Get a test user (or use a specific UUID if you know it)
DO $$
DECLARE
    test_user_id UUID;
    child1_id UUID := '11111111-1111-1111-1111-111111111111';
    child2_id UUID := '22222222-2222-2222-2222-222222222222';
BEGIN
    -- Get first user (create one via dashboard if none exist)
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;

    IF test_user_id IS NULL THEN
        RAISE NOTICE 'No users found. Please create a test user first via Supabase Dashboard or signup API.';
        RETURN;
    END IF;

    RAISE NOTICE 'Using test user: %', test_user_id;

    -- Insert test children (if not already exists)
    INSERT INTO children (id, user_id, name, age, temperament, temperament_talkative, temperament_sensitivity, temperament_accountability, created_at, updated_at)
    VALUES
        (
            child1_id,
            test_user_id,
            'Emma',
            8,
            'sensitive',
            6,
            9,
            7,
            NOW(),
            NOW()
        ),
        (
            child2_id,
            test_user_id,
            'Liam',
            12,
            'spirited',
            9,
            4,
            5,
            NOW(),
            NOW()
        )
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Test children created: Emma (%), Liam (%)', child1_id, child2_id;

    -- ============================================================================
    -- 2. Create Child Memory Records
    -- ============================================================================

    -- Memory for Emma (sensitive, needs gentle approach)
    INSERT INTO child_memory (
        child_id,
        behavioral_themes,
        communication_strategies,
        significant_events,
        created_at,
        updated_at
    )
    VALUES (
        child1_id,
        '[
            {
                "theme": "bedtime anxiety",
                "frequency": 7,
                "first_observed": "2025-01-10",
                "last_observed": "2025-10-05"
            },
            {
                "theme": "difficulty with transitions",
                "frequency": 5,
                "first_observed": "2025-02-15",
                "last_observed": "2025-09-28"
            }
        ]'::jsonb,
        '[
            {
                "strategy": "advance warning for transitions",
                "effectiveness": "high",
                "used_count": 8,
                "notes": "Give 5-10 minute warning before changes"
            },
            {
                "strategy": "calming bedtime routine",
                "effectiveness": "high",
                "used_count": 12,
                "notes": "Reading + soft music helps with sleep anxiety"
            }
        ]'::jsonb,
        '[
            {
                "event": "Started new school year",
                "date": "2025-09-01",
                "impact": "Increased anxiety around mornings and transitions"
            }
        ]'::jsonb,
        NOW(),
        NOW()
    )
    ON CONFLICT (child_id) DO UPDATE SET
        behavioral_themes = EXCLUDED.behavioral_themes,
        communication_strategies = EXCLUDED.communication_strategies,
        significant_events = EXCLUDED.significant_events,
        updated_at = NOW();

    -- Memory for Liam (spirited, needs clear boundaries)
    INSERT INTO child_memory (
        child_id,
        behavioral_themes,
        communication_strategies,
        significant_events,
        created_at,
        updated_at
    )
    VALUES (
        child2_id,
        '[
            {
                "theme": "testing boundaries",
                "frequency": 9,
                "first_observed": "2025-01-05",
                "last_observed": "2025-10-10"
            },
            {
                "theme": "screen time arguments",
                "frequency": 6,
                "first_observed": "2025-03-20",
                "last_observed": "2025-10-08"
            },
            {
                "theme": "homework resistance",
                "frequency": 4,
                "first_observed": "2025-09-15",
                "last_observed": "2025-10-11"
            }
        ]'::jsonb,
        '[
            {
                "strategy": "clear consequences upfront",
                "effectiveness": "high",
                "used_count": 10,
                "notes": "State rules and consequences before situations arise"
            },
            {
                "strategy": "choice framework",
                "effectiveness": "medium",
                "used_count": 5,
                "notes": "Give two acceptable options to preserve autonomy"
            },
            {
                "strategy": "physical activity before homework",
                "effectiveness": "high",
                "used_count": 3,
                "notes": "15 minutes of movement helps focus"
            }
        ]'::jsonb,
        '[
            {
                "event": "Started middle school",
                "date": "2025-09-01",
                "impact": "More homework, increased social pressures"
            },
            {
                "event": "Joined soccer team",
                "date": "2025-09-10",
                "impact": "Positive outlet for energy, less conflict at home"
            }
        ]'::jsonb,
        NOW(),
        NOW()
    )
    ON CONFLICT (child_id) DO UPDATE SET
        behavioral_themes = EXCLUDED.behavioral_themes,
        communication_strategies = EXCLUDED.communication_strategies,
        significant_events = EXCLUDED.significant_events,
        updated_at = NOW();

    RAISE NOTICE 'Child memory records created';

    -- ============================================================================
    -- 3. Create Sample Conversations (Optional)
    -- ============================================================================

    -- Sample completed conversation for Emma
    DECLARE
        conv1_id UUID := gen_random_uuid();
    BEGIN
        INSERT INTO conversations (id, user_id, child_id, status, title, created_at, updated_at)
        VALUES (
            conv1_id,
            test_user_id,
            child1_id,
            'completed',
            'Bedtime anxiety strategies',
            NOW() - INTERVAL '2 days',
            NOW() - INTERVAL '2 days'
        );

        -- Sample messages
        INSERT INTO messages (conversation_id, role, content, created_at)
        VALUES
            (conv1_id, 'user', 'Emma has been really anxious at bedtime lately. She keeps coming out of her room saying she can''t sleep.', NOW() - INTERVAL '2 days'),
            (conv1_id, 'assistant', 'I understand how challenging bedtime anxiety can be, especially for sensitive kids like Emma. At 8 years old, this is actually quite common. Let me suggest a few strategies that might help...', NOW() - INTERVAL '2 days' + INTERVAL '30 seconds'),
            (conv1_id, 'user', 'What kind of strategies do you recommend?', NOW() - INTERVAL '2 days' + INTERVAL '1 minute'),
            (conv1_id, 'assistant', 'Given Emma''s sensitivity, I''d recommend creating a very predictable, calming bedtime routine. This might include: 1) Starting wind-down time 30 minutes before bed, 2) Dim lighting and quiet activities like reading together, 3) A "worry dump" journal where she can write down any concerns before bed...', NOW() - INTERVAL '2 days' + INTERVAL '1 minute 30 seconds');

        RAISE NOTICE 'Sample conversation created for Emma: %', conv1_id;
    END;

    -- Sample active conversation for Liam
    DECLARE
        conv2_id UUID := gen_random_uuid();
    BEGIN
        INSERT INTO conversations (id, user_id, child_id, status, created_at, updated_at)
        VALUES (
            conv2_id,
            test_user_id,
            child2_id,
            'active',
            NOW() - INTERVAL '1 hour',
            NOW() - INTERVAL '30 minutes'
        );

        -- Sample messages
        INSERT INTO messages (conversation_id, role, content, created_at)
        VALUES
            (conv2_id, 'user', 'Liam is refusing to do his homework again. Every night it''s a battle.', NOW() - INTERVAL '1 hour'),
            (conv2_id, 'assistant', 'Homework battles are exhausting, I know. At 12, Liam is at an age where he''s really pushing for independence, especially with that spirited temperament. Let''s think about what might be driving this resistance...', NOW() - INTERVAL '59 minutes');

        RAISE NOTICE 'Sample active conversation created for Liam: %', conv2_id;
    END;

END $$;

-- ============================================================================
-- 4. Verification Queries
-- ============================================================================

-- Show created test data
SELECT
    c.id,
    c.name,
    c.age,
    c.temperament,
    c.temperament_talkative as talkative,
    c.temperament_sensitivity as sensitivity,
    c.temperament_accountability as accountability,
    CASE WHEN cm.id IS NOT NULL THEN '✓ Has memory' ELSE '✗ No memory' END as memory_status
FROM children c
LEFT JOIN child_memory cm ON cm.child_id = c.id
ORDER BY c.created_at DESC
LIMIT 5;

-- Show sample conversations
SELECT
    conv.id,
    c.name as child_name,
    conv.status,
    conv.title,
    COUNT(m.id) as message_count,
    conv.created_at
FROM conversations conv
JOIN children c ON c.id = conv.child_id
LEFT JOIN messages m ON m.conversation_id = conv.id
GROUP BY conv.id, c.name, conv.status, conv.title, conv.created_at
ORDER BY conv.created_at DESC
LIMIT 5;

-- ============================================================================
-- 5. Cleanup (Optional - uncomment to remove test data)
-- ============================================================================

/*
-- To clean up test data:
DELETE FROM conversations WHERE child_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222'
);

DELETE FROM child_memory WHERE child_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222'
);

DELETE FROM children WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222'
);
*/
