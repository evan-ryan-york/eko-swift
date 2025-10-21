-- Seed Daily Practice Day 1 Activities (3 activities, one per age band)
-- This migration can be safely run multiple times (uses ON CONFLICT DO NOTHING)

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
    actionable_takeaway
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
                    "feedback": "Not quite. The door slamming, yelling, and stomping are all signs that your child''s nervous system is activated."
                },
                {
                    "optionId": "o2",
                    "optionText": "Dysregulated - they''re emotionally flooded",
                    "correct": true,
                    "points": 10,
                    "feedback": "Exactly right! Your child is showing clear signs of dysregulation.",
                    "scienceNote": {
                        "brief": "When children are dysregulated, their amygdala is highly active while their prefrontal cortex has reduced activity.",
                        "citation": "Siegel & Bryson, The Whole-Brain Child (2011)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Being disrespectful on purpose",
                    "correct": false,
                    "points": 0,
                    "feedback": "While the behavior might feel disrespectful, it''s actually a sign of emotional overwhelm."
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
                    "feedback": "This can escalate the situation. When kids are dysregulated, they need space and calm presence."
                },
                {
                    "optionId": "o2",
                    "optionText": "Send them to their room as punishment for being rude",
                    "correct": false,
                    "points": 0,
                    "feedback": "Punishment in moments of dysregulation teaches kids that their emotions are bad."
                },
                {
                    "optionId": "o3",
                    "optionText": "Stay calm yourself and give them space to settle",
                    "correct": true,
                    "points": 10,
                    "feedback": "Perfect! Your calm presence is the most powerful tool.",
                    "scienceNote": {
                        "brief": "Co-regulation works through social baseline theory - children borrow calm from their parents.",
                        "citation": "Porges, Polyvagal Theory (2011)",
                        "showCitation": true
                    }
                }
            ]
        }
    ]',
    '{
        "toolName": "Regulated Presence",
        "whenToUse": "When your child is dysregulated (upset, angry, overwhelmed)",
        "howTo": [
            "Notice signs of dysregulation (yelling, crying, withdrawal)",
            "Check your own state - take a breath if needed",
            "Offer calm, non-demanding presence",
            "Give space while staying emotionally available",
            "Wait for nervous system to settle before problem-solving"
        ],
        "whyItWorks": "Your regulated nervous system helps co-regulate your child''s dysregulated state. Their brain literally borrows your calm to return to baseline, making connection and conversation possible again.",
        "tryItWhen": "Your child comes home upset, has a meltdown, or shuts down emotionally",
        "example": {
            "situation": "7-year-old slams door after bad day at school",
            "action": "Parent takes a breath, stays calm, says ''I can see you''re upset. I''m here when you''re ready'' and gives space",
            "outcome": "Child calms down in 10 minutes, comes out and shares what happened"
        }
    }'
) ON CONFLICT (day_number, age_band) DO NOTHING;

-- Activity 2: Age 10-12
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
    actionable_takeaway
) VALUES (
    'a1111111-1111-1111-1111-111111111112',
    1,
    '10-12',
    'conversation-state',
    'The Conversation State Model',
    'When Your Tween Shuts Down',
    'Learn to recognize dysregulation in tweens',
    'State Recognition',
    'Emotional Awareness',
    false,
    'Your 11-year-old comes home, goes straight to their room, and won''t come out for dinner. When you knock, they say "Leave me alone" in a flat voice.',
    '[
        {
            "promptId": "p1",
            "type": "state-identification",
            "promptText": "What state is your tween in?",
            "order": 1,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Regulated and just wanting privacy",
                    "correct": false,
                    "points": 0,
                    "feedback": "The flat voice and withdrawal suggest dysregulation. Tweens need privacy, but this behavior shows emotional shutdown."
                },
                {
                    "optionId": "o2",
                    "optionText": "Dysregulated - emotionally shutdown",
                    "correct": true,
                    "points": 10,
                    "feedback": "Yes! Tweens often show dysregulation through withdrawal and flat affect rather than big emotions.",
                    "scienceNote": {
                        "brief": "During early adolescence, the brain undergoes major reorganization. Tweens may withdraw when overwhelmed rather than seek connection.",
                        "citation": "Jensen & Nutt, The Teenage Brain (2015)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Being moody and difficult",
                    "correct": false,
                    "points": 0,
                    "feedback": "What looks like moodiness is usually dysregulation. Their developing brain makes emotional regulation harder."
                }
            ]
        },
        {
            "promptId": "p2",
            "type": "best-response",
            "promptText": "What''s your best first move?",
            "order": 2,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Insist they come out and talk to you",
                    "correct": false,
                    "points": 0,
                    "feedback": "Forcing connection when tweens are shut down usually backfires and increases resistance."
                },
                {
                    "optionId": "o2",
                    "optionText": "Respect their need for space while staying available",
                    "correct": true,
                    "points": 10,
                    "feedback": "Perfect! Tweens need autonomy with availability. You might say ''I''m here if you need me'' and check in gently later.",
                    "scienceNote": {
                        "brief": "Autonomy support increases teen willingness to seek help. Feeling controlled decreases openness.",
                        "citation": "Dahl et al., Adolescent Brain Development (2018)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Leave them alone completely until they come to you",
                    "correct": false,
                    "points": 0,
                    "feedback": "Complete withdrawal can feel like abandonment. Brief check-ins show you care while respecting boundaries."
                }
            ]
        }
    ]',
    '{
        "toolName": "Autonomy with Availability",
        "whenToUse": "When your tween or teen is dysregulated and withdrawing",
        "howTo": [
            "Acknowledge their need for space",
            "Communicate your availability without pressure",
            "Respect their timeline for opening up",
            "Check in briefly without demanding conversation",
            "Stay emotionally present even when physically separate"
        ],
        "whyItWorks": "Tweens and teens are developmentally wired to seek independence while still needing parental support. This approach honors both needs, making them more likely to come to you when ready.",
        "tryItWhen": "Your tween shuts down, withdraws to their room, or pushes you away emotionally",
        "example": {
            "situation": "11-year-old won''t leave room after hard day",
            "action": "Parent says ''I can see you need space. I''ll be in the kitchen if you want to talk'' and checks in gently 20 minutes later",
            "outcome": "Tween comes down later and opens up about friendship issue"
        }
    }'
) ON CONFLICT (day_number, age_band) DO NOTHING;

-- Activity 3: Age 13-16
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
    actionable_takeaway
) VALUES (
    'a1111111-1111-1111-1111-111111111113',
    1,
    '13-16',
    'conversation-state',
    'The Conversation State Model',
    'Teen Emotional Flooding',
    'Learn to recognize and respond to teen dysregulation',
    'State Recognition',
    'Emotional Awareness',
    false,
    'Your 15-year-old storms in, throws their backpack down, and starts ranting about how "everything is so unfair" and "you just don''t understand." They''re talking fast, their voice is raised, and they seem on the verge of tears.',
    '[
        {
            "promptId": "p1",
            "type": "state-identification",
            "promptText": "What state is your teen in?",
            "order": 1,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Regulated - they''re communicating clearly",
                    "correct": false,
                    "points": 0,
                    "feedback": "The fast talking, raised voice, and physical agitation are signs of dysregulation, not effective communication."
                },
                {
                    "optionId": "o2",
                    "optionText": "Dysregulated - they''re emotionally flooded",
                    "correct": true,
                    "points": 10,
                    "feedback": "Exactly! Your teen is experiencing emotional flooding - their nervous system is overwhelmed.",
                    "scienceNote": {
                        "brief": "Teen brains are particularly prone to emotional flooding due to heightened amygdala reactivity combined with still-developing prefrontal cortex.",
                        "citation": "Steinberg, Age of Opportunity (2014)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Being dramatic for attention",
                    "correct": false,
                    "points": 0,
                    "feedback": "What looks like drama is usually genuine overwhelm. Teen emotions are intense and real, not manipulative."
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
                    "optionText": "Try to solve the problem right away",
                    "correct": false,
                    "points": 0,
                    "feedback": "Problem-solving before regulation usually fails. They can''t access rational thinking while flooded."
                },
                {
                    "optionId": "o2",
                    "optionText": "Regulate yourself and offer calm presence",
                    "correct": true,
                    "points": 10,
                    "feedback": "Perfect! Your regulation helps their regulation. Take a breath, stay calm, and be a safe emotional container.",
                    "scienceNote": {
                        "brief": "Social buffering - a calm, supportive presence - reduces amygdala activation and helps the prefrontal cortex come back online.",
                        "citation": "Eisenberger et al., Social Neuroscience (2011)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Tell them to calm down and talk rationally",
                    "correct": false,
                    "points": 0,
                    "feedback": "Being told to calm down when flooded usually increases activation. They need co-regulation, not commands."
                }
            ]
        },
        {
            "promptId": "p3",
            "type": "best-response",
            "promptText": "After they calm down a bit, what helps most?",
            "order": 3,
            "points": 10,
            "options": [
                {
                    "optionId": "o1",
                    "optionText": "Jump straight to advice and solutions",
                    "correct": false,
                    "points": 0,
                    "feedback": "Teens need to feel heard before they can hear you. Solutions come after connection."
                },
                {
                    "optionId": "o2",
                    "optionText": "Listen with empathy before problem-solving",
                    "correct": true,
                    "points": 10,
                    "feedback": "Yes! Feeling heard helps complete the regulation process. Then they can think clearly about solutions.",
                    "scienceNote": {
                        "brief": "Empathic listening activates the vagal brake, helping shift from sympathetic (fight/flight) to parasympathetic (rest/digest) nervous system.",
                        "citation": "Linehan, DBT Skills Training (2015)",
                        "showCitation": true
                    }
                },
                {
                    "optionId": "o3",
                    "optionText": "Change the subject to lighten the mood",
                    "correct": false,
                    "points": 0,
                    "feedback": "Changing the subject can feel dismissive. They need validation of their experience first."
                }
            ]
        }
    ]',
    '{
        "toolName": "Regulate, Relate, Reason",
        "whenToUse": "When your teen (or any child) is emotionally flooded or dysregulated",
        "howTo": [
            "REGULATE: First, regulate yourself - take a breath, stay calm",
            "RELATE: Offer empathic presence - ''I can see this is really hard''",
            "REASON: Only after they calm, engage problem-solving brain",
            "Never skip steps - each builds on the previous",
            "Wait for signs of regulation before moving to reason"
        ],
        "whyItWorks": "This sequence mirrors how the brain processes stress. The prefrontal cortex (reasoning) can''t function until the amygdala (emotion) settles. Your regulation helps their regulation, relationship provides safety, and only then can reasoning happen.",
        "tryItWhen": "Your teen is upset, ranting, crying, or emotionally overwhelmed",
        "example": {
            "situation": "15-year-old storms in ranting about unfairness",
            "action": "Parent stays calm (regulate), says ''That sounds really frustrating'' (relate), listens empathetically, then later asks ''Want to talk through some options?'' (reason)",
            "outcome": "Teen calms down, feels heard, and becomes open to problem-solving"
        }
    }'
) ON CONFLICT (day_number, age_band) DO NOTHING;
