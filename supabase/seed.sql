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

-- ============================================================================
-- 6. Daily Practice Sample Activities
-- ============================================================================

-- Day 1, Module 1: The Conversation State Model
-- Three activities (one per age band)

-- Activity 1: Age 6-9 (State Identification)
INSERT INTO daily_practice_activities (
    id,
    day_number,
    age_band,
    module_name,
    module_display_name,
    title,
    description,
    category,
    skill_focus,
    is_reflection,
    scenario,
    prompts,
    actionable_takeaway,
    best_approach,
    follow_up_questions
) VALUES (
    'a1111111-1111-1111-1111-111111111111',
    1,
    '6-9',
    'conversation-state',
    'The Conversation State Model',
    'Understanding When Your Child is Upset',
    'Learn to recognize when your child is dysregulated',
    'State Recognition',
    'Emotional Awareness',
    false,
    'Your 7-year-old comes home from school and immediately slams the door. When you ask "How was your day?", they yell "I don''t want to talk!" and stomp to their room.',
    '[
        {
            "promptId": "p1",
            "type": "state-identification",
            "promptText": "What emotional state is your child in right now?",
            "order": 1,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Regulated - they''re calm and ready to talk",
                    "correct": false,
                    "points": 0,
                    "feedback": "Not quite. The door slamming, yelling, and stomping are all signs that your child''s nervous system is activated. When kids are regulated, they can respond calmly and engage in conversation."
                },
                {
                    "optionId": "o2",
                    "optionText": "Dysregulated - they''re emotionally flooded",
                    "correct": true,
                    "points": 10,
                    "feedback": "Exactly right! Your child is showing clear signs of dysregulation. Their behavior (slamming, yelling, stomping) tells you their nervous system is in a heightened state.",
                    "scienceNote": {
                        "brief": "When children are dysregulated, their amygdala (emotional center) is highly active while their prefrontal cortex (thinking brain) has reduced activity. This makes logical conversation nearly impossible until they calm down.",
                        "citation": "Siegel & Bryson, The Whole-Brain Child (2011)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Being disrespectful on purpose",
                    "correct": false,
                    "points": 0,
                    "feedback": "While the behavior might feel disrespectful, it''s actually a sign of emotional overwhelm. Seven-year-olds don''t have the brain development to intentionally manipulate in moments of distress - they''re genuinely struggling to manage big feelings."
                }
            ]
        },
        {
            "promptId": "p2",
            "type": "best-response",
            "promptText": "What should you do first?",
            "order": 2,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Follow them to their room and insist they talk to you",
                    "correct": false,
                    "points": 0,
                    "feedback": "This can escalate the situation. When kids are dysregulated, they need space and calm presence, not immediate demands for conversation."
                },
                {
                    "optionId": "o2",
                    "optionText": "Send them to their room as punishment for being rude",
                    "correct": false,
                    "points": 0,
                    "feedback": "Punishment in moments of dysregulation teaches kids that their emotions are bad, not how to manage them. They need co-regulation support, not consequences."
                },
                {
                    "optionId": "o3",
                    "optionText": "Stay calm yourself and give them space to settle",
                    "correct": true,
                    "points": 10,
                    "feedback": "Perfect! Your calm presence is the most powerful tool. By staying regulated yourself and giving space, you''re helping their nervous system settle. You might say something like ''I can see you''re upset. I''m here when you''re ready.''",
                    "scienceNote": {
                        "brief": "Co-regulation works through ''social baseline theory'' - children borrow calm from their parents'' regulated nervous systems. Your calm literally helps their brain return to baseline.",
                        "citation": "Porges, Polyvagal Theory (2011)",
                        "showCitation": true
                    }
                }
            ]
        }
    ]'::jsonb,
    '{
        "toolName": "Regulated Presence",
        "whenToUse": "When your child is showing signs of dysregulation (yelling, crying, door slamming, withdrawal)",
        "howTo": [
            "Notice the signs of dysregulation in your child''s body and behavior",
            "Take a breath and regulate yourself first",
            "Give them physical and emotional space",
            "Stay nearby and available",
            "Use a calm, quiet voice if you speak at all",
            "Wait for their nervous system to settle before attempting conversation"
        ],
        "whyItWorks": "Your child''s brain is literally incapable of logical conversation when dysregulated. By staying calm and giving space, you help their nervous system return to baseline through co-regulation. Once regulated, they can actually process what happened.",
        "tryItWhen": "Try it the next time your child comes home from school visibly upset, or when they have a meltdown over homework or screen time",
        "example": {
            "situation": "Eight-year-old has a meltdown when told it''s time to turn off the iPad",
            "action": "Parent takes a deep breath, stays calm, and says ''I can see you''re really upset. I''ll be in the kitchen when you''re ready.'' Then steps back without arguing.",
            "outcome": "After 5 minutes of crying in their room, child emerges calmer and is able to hand over the iPad and transition to the next activity"
        }
    }'::jsonb,
    'In moments of dysregulation, connection before correction. Your child needs your calm presence, not your words.',
    ARRAY['What are other signs of dysregulation you''ve noticed in your child?', 'How do you typically feel in your body when your child is upset?']
);

-- Activity 2: Age 10-12 (Best Response)
INSERT INTO daily_practice_activities (
    id,
    day_number,
    age_band,
    module_name,
    module_display_name,
    title,
    description,
    category,
    skill_focus,
    is_reflection,
    scenario,
    prompts,
    actionable_takeaway,
    best_approach,
    follow_up_questions
) VALUES (
    'a2222222-2222-2222-2222-222222222222',
    1,
    '10-12',
    'conversation-state',
    'The Conversation State Model',
    'When Your Tween Shuts Down',
    'Recognize and respond to emotional withdrawal in pre-teens',
    'State Recognition',
    'Emotional Awareness',
    false,
    'Your 11-year-old just got cut from the basketball team. They come home, go straight to their room, and won''t come out. When you knock and ask if they want to talk, they say "I''m fine. Just leave me alone."',
    '[
        {
            "promptId": "p1",
            "type": "state-identification",
            "promptText": "What state is your child likely in?",
            "order": 1,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Regulated - they said they''re fine",
                    "correct": false,
                    "points": 0,
                    "feedback": "At 11, kids often say ''I''m fine'' when they''re anything but. The immediate withdrawal and refusal to engage suggest they''re overwhelmed and trying to manage alone."
                },
                {
                    "optionId": "o2",
                    "optionText": "Dysregulated - they''re overwhelmed by disappointment",
                    "correct": true,
                    "points": 10,
                    "feedback": "Exactly. While it''s quieter than a younger child''s dysregulation, withdrawal and shutting down are classic signs that a tween is emotionally flooded. They''re managing overwhelm by disconnecting.",
                    "scienceNote": {
                        "brief": "Tweens often ''shut down'' rather than ''melt down'' when dysregulated. This is their developing prefrontal cortex trying to suppress emotions, but they''re still flooded internally and can''t access higher-order thinking.",
                        "citation": "Jensen & Nutt, The Teenage Brain (2015)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Just being a typical moody pre-teen",
                    "correct": false,
                    "points": 0,
                    "feedback": "While emotional ups and downs are normal at this age, dismissing genuine distress as ''just being moody'' misses an opportunity to support them. This is real dysregulation triggered by a real disappointment."
                }
            ]
        },
        {
            "promptId": "p2",
            "type": "best-response",
            "promptText": "What''s the best approach right now?",
            "order": 2,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Respect their space and check back in 20-30 minutes",
                    "correct": true,
                    "points": 10,
                    "feedback": "Perfect! Tweens need autonomy, especially when processing disappointment. By respecting their need for space while staying available, you''re showing trust in their process. You might say: ''I''ll be in the kitchen if you want company. No pressure.''",
                    "scienceNote": {
                        "brief": "Pre-teens are developing their identity and autonomy. Respecting their processing style while staying available builds trust and teaches them that you believe in their ability to self-regulate - while knowing support is there if needed.",
                        "citation": "Dahl et al., Adolescent Brain Development (2018)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o2",
                    "optionText": "Insist they come out and talk about their feelings",
                    "correct": false,
                    "points": 0,
                    "feedback": "This can backfire with tweens. Forced emotional conversations when they''re not ready often lead to more shutdown or conflict. They need to feel in control of when they open up."
                },
                {
                    "optionId": "o3",
                    "optionText": "Leave them alone completely until they come to you",
                    "correct": false,
                    "points": 0,
                    "feedback": "While space is important, completely withdrawing can feel like abandonment. Tweens need to know you''re there and available, even if they''re not ready to talk yet."
                },
                {
                    "optionId": "o4",
                    "optionText": "Try to cheer them up by minimizing it (''There''s always next year!'')",
                    "correct": false,
                    "points": 0,
                    "feedback": "Toxic positivity invalidates their real grief. At 11, not making the team is a genuine loss. They need their feelings acknowledged, not dismissed."
                }
            ]
        }
    ]'::jsonb,
    '{
        "toolName": "Autonomy with Availability",
        "whenToUse": "When your tween withdraws or shuts down after a disappointment or conflict",
        "howTo": [
            "Acknowledge their request for space verbally",
            "State clearly that you''re available when they''re ready",
            "Set a specific time to check back (20-30 minutes)",
            "Actually check back - don''t forget or get distracted",
            "When checking back, offer low-pressure connection (''Want to help me with dinner?'' vs ''Ready to talk now?'')",
            "Accept whatever they''re ready for - presence without conversation is still connection"
        ],
        "whyItWorks": "Tweens are caught between needing independence and needing support. This approach honors both needs. You''re showing you trust their ability to self-regulate while making it clear that support is available - they get to choose when to access it.",
        "tryItWhen": "Use this when your tween experiences social rejection, academic disappointment, or conflict with friends or family",
        "example": {
            "situation": "12-year-old didn''t get invited to a birthday party that most of their friends are attending",
            "action": "Parent says: ''That really sucks, I''m sorry. I''m going to be doing some stuff around the house. Find me if you want company.'' Checks back after 30 minutes with ''Want to watch that show together?'' (not ''Ready to talk?'')",
            "outcome": "After an episode together, child opens up about feeling left out, and parent gets to offer support when they''re actually ready for it"
        }
    }'::jsonb,
    'Tweens need space to process, but they shouldn''t feel abandoned. Be available, not invasive.',
    ARRAY['How do you typically respond when your child shuts down?', 'What helps you stay available without hovering?']
);

-- Activity 3: Age 13-16 (Sequential Choice)
INSERT INTO daily_practice_activities (
    id,
    day_number,
    age_band,
    module_name,
    module_display_name,
    title,
    description,
    category,
    skill_focus,
    is_reflection,
    scenario,
    prompts,
    actionable_takeaway,
    best_approach,
    follow_up_questions
) VALUES (
    'a3333333-3333-3333-3333-333333333333',
    1,
    '13-16',
    'conversation-state',
    'The Conversation State Model',
    'Teen Emotional Flooding',
    'Navigate your teen''s intense emotions without escalating',
    'State Recognition',
    'Emotional Regulation',
    false,
    'Your 15-year-old just had a huge fight with their best friend over text. They''re pacing in their room, occasionally typing furiously and then stopping. You hear frustrated sounds through the door. You know this friendship has been rocky lately.',
    '[
        {
            "promptId": "p1",
            "type": "state-identification",
            "promptText": "What emotional state is your teen in?",
            "order": 1,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Regulated but upset",
                    "correct": false,
                    "points": 0,
                    "feedback": "The pacing, frustrated sounds, and typing-then-stopping pattern suggest they''re not in control of their emotions right now. If they were regulated, they''d be able to respond more thoughtfully."
                },
                {
                    "optionId": "o2",
                    "optionText": "Dysregulated and at risk of making it worse",
                    "correct": true,
                    "points": 10,
                    "feedback": "Exactly. The pacing and starting-stopping texts are classic signs of emotional flooding. When teens are in this state, they''re likely to send messages they''ll regret or make impulsive decisions that escalate the conflict.",
                    "scienceNote": {
                        "brief": "The adolescent brain is particularly vulnerable to emotional flooding because the limbic system (emotions) is highly active while the prefrontal cortex (impulse control) is still developing. This creates a gap where intense emotions can drive impulsive actions.",
                        "citation": "Steinberg, Age of Opportunity (2014)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "This is typical teen drama, not a real problem",
                    "correct": false,
                    "points": 0,
                    "feedback": "While friendship conflicts are developmentally normal, dismissing them as ''drama'' misses the opportunity to teach emotional regulation skills. For teens, peer relationships are neurologically as important as survival - this is a real crisis to them."
                }
            ]
        },
        {
            "promptId": "p2",
            "type": "best-response",
            "promptText": "What''s your first move?",
            "order": 2,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Knock and ask if they''re okay, offering to listen",
                    "correct": true,
                    "points": 10,
                    "feedback": "Good! This opens the door without being intrusive. Your teen gets to choose whether to accept support. If they say ''I''m fine,'' you''ve still planted the seed that you''re available.",
                    "scienceNote": {
                        "brief": "Teens'' social pain activates the same brain regions as physical pain. Offering support during peer conflict isn''t ''babying'' them - it''s responding to genuine distress while respecting their autonomy to accept or decline.",
                        "citation": "Eisenberger & Lieberman, Social Pain (2004)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o2",
                    "optionText": "Take away their phone so they can''t make it worse",
                    "correct": false,
                    "points": 0,
                    "feedback": "This will likely escalate into a parent-teen conflict on top of the peer conflict. It also robs them of agency and doesn''t teach them to self-regulate in the moment."
                },
                {
                    "optionId": "o3",
                    "optionText": "Leave them completely alone - they''re almost an adult",
                    "correct": false,
                    "points": 0,
                    "feedback": "While teens need more autonomy than younger kids, they still need support during emotional flooding. Offering (not forcing) your presence teaches them that needing help isn''t weakness."
                },
                {
                    "optionId": "o4",
                    "optionText": "Text them ''Everything okay?'' to avoid awkward in-person conversation",
                    "correct": false,
                    "points": 0,
                    "feedback": "While text might feel less confrontational, in-person offers of support carry more weight and show you''re willing to be present in their discomfort. Save text for following up later."
                }
            ]
        },
        {
            "promptId": "p3",
            "type": "what-happens-next",
            "promptText": "They let you in and start venting about how their friend is ''being so fake.'' What do you do?",
            "order": 3,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Just listen and validate their feelings without solving",
                    "correct": true,
                    "points": 10,
                    "feedback": "Perfect! In the moment of dysregulation, they don''t need advice - they need to feel heard. You might say ''That sounds really hurtful'' or ''I can see why you''re upset.'' This helps their nervous system settle so they can think clearly later.",
                    "scienceNote": {
                        "brief": "Validation activates the brain''s reward centers and reduces amygdala activity. When teens feel understood, their nervous system literally calms down, making problem-solving possible.",
                        "citation": "Linehan, DBT Skills Training Manual (2014)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o2",
                    "optionText": "Immediately offer solutions for fixing the friendship",
                    "correct": false,
                    "points": 0,
                    "feedback": "Jumping to solutions when they''re emotionally flooded won''t work - they can''t access logical thinking yet. Plus, it can feel dismissive, like you''re not really listening to their pain."
                },
                {
                    "optionId": "o3",
                    "optionText": "Suggest they''re overreacting and should calm down",
                    "correct": false,
                    "points": 0,
                    "feedback": "''Calm down'' has never calmed anyone down in the history of parenting. This invalidates their experience and often escalates the situation."
                },
                {
                    "optionId": "o4",
                    "optionText": "Share a story about your own teen friendship drama",
                    "correct": false,
                    "points": 0,
                    "feedback": "While relating can be helpful later, right now they need to be heard, not hear about you. Save your stories for when they''re regulated and can actually benefit from perspective."
                }
            ]
        }
    ]'::jsonb,
    '{
        "toolName": "Regulate Then Relate Then Reason",
        "whenToUse": "When your teen is in emotional crisis over social conflicts, academic stress, or identity struggles",
        "howTo": [
            "First, help them REGULATE: Offer calm presence, validate feelings, maybe suggest a walk or physical outlet",
            "Then, RELATE: Show you understand by reflecting what you hear (''So it feels like she betrayed your trust?'')",
            "Only then, REASON: Once calm, help them think through options (''What do you think your next move could be?'')"
        ],
        "whyItWorks": "This mirrors how the brain works: the emotional centers must settle before the thinking brain can engage. Trying to reason with a dysregulated teen is like trying to have a conversation with someone who''s drowning - they need to get to shore first.",
        "tryItWhen": "Use this sequence whenever your teen is upset about: peer conflicts, romantic relationships, academic stress, sports/performance pressure, identity questions, or perceived injustice",
        "example": {
            "situation": "16-year-old didn''t get into their dream college''s early admission program",
            "action": "Parent first validates (''This is a huge disappointment, I''m so sorry''), then relates (''You worked so hard on that application''), and waits until the next day to reason (''Want to look at your other options together?'')",
            "outcome": "Teen feels supported through the grief, and the next day is actually able to engage in problem-solving about other schools"
        }
    }'::jsonb,
    'You can''t reason with someone who''s emotionally flooded. Regulate first, reason later.',
    ARRAY['What makes it hard for you to ''just listen'' without solving?', 'How do you know when your teen is ready to move from venting to problem-solving?']
);
