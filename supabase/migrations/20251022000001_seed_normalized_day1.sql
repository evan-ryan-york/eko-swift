-- Seed Daily Practice Day 1 Activities - Normalized Schema
-- This migration seeds Day 1 data using the normalized table structure
-- Can be safely run multiple times (uses ON CONFLICT DO NOTHING)

-- =============================================================================
-- Activity 1: Age 6-9
-- =============================================================================

-- Insert Activity
INSERT INTO daily_practice_activities (
    id,
    day_number,
    age_band,
    module_name,
    module_display_name,
    title,
    description,
    skill_focus,
    category,
    activity_type,
    is_reflection,
    scenario,
    research_concept,
    research_key_insight,
    research_citation,
    research_additional_context,
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
    'Emotional Awareness',
    'State Recognition',
    'basic-scenario',
    false,
    'Your 7-year-old comes home from school and immediately slams the door. When you ask "How was your day?", they yell "I don''t want to talk!" and stomp to their room.',
    'polyvagal theory',
    'The nervous system operates in different states that determine whether a child can engage in rational conversation',
    'Porges, S. W. (2011). The Polyvagal Theory',
    'Dr. Dan Siegel describes this as "flipping your lid" - when the emotional brain takes over from the thinking brain',
    null,
    '[]'::jsonb
) ON CONFLICT (day_number, age_band) DO NOTHING;

-- Insert Prompt 1
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '01111111-1111-1111-1111-111111111111',
    'a1111111-1111-1111-1111-111111111111',
    'p1',
    'state-identification',
    'What emotional state is your child in right now?',
    1,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

-- Insert Options for Prompt 1
INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback,
    science_note_brief,
    science_note_citation,
    science_note_show_citation
) VALUES
(
    '01111111-1111-1111-1111-111111111111',
    'o1',
    'Regulated - they''re calm and ready to talk',
    false,
    0,
    'Not quite. The door slamming, yelling, and stomping are all signs that your child''s nervous system is activated.',
    null,
    null,
    false
),
(
    '01111111-1111-1111-1111-111111111111',
    'o2',
    'Dysregulated - they''re emotionally flooded',
    true,
    10,
    'Exactly right! Your child is showing clear signs of dysregulation.',
    'When children are dysregulated, their amygdala is highly active while their prefrontal cortex has reduced activity.',
    'Siegel & Bryson, The Whole-Brain Child (2011)',
    true
),
(
    '01111111-1111-1111-1111-111111111111',
    'o3',
    'Being disrespectful on purpose',
    false,
    0,
    'While the behavior might feel disrespectful, it''s actually a sign of emotional overwhelm.',
    null,
    null,
    false
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Insert Prompt 2
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '02111111-1111-1111-1111-111111111111',
    'a1111111-1111-1111-1111-111111111111',
    'p2',
    'best-response',
    'What should you do first?',
    2,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

-- Insert Options for Prompt 2
INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback,
    science_note_brief,
    science_note_citation,
    science_note_show_citation
) VALUES
(
    '02111111-1111-1111-1111-111111111111',
    'o1',
    'Follow them to their room and insist they talk to you',
    false,
    0,
    'This can escalate the situation. When kids are dysregulated, they need space and calm presence.',
    null,
    null,
    false
),
(
    '02111111-1111-1111-1111-111111111111',
    'o2',
    'Send them to their room as punishment for being rude',
    false,
    0,
    'Punishment in moments of dysregulation teaches kids that their emotions are bad.',
    null,
    null,
    false
),
(
    '02111111-1111-1111-1111-111111111111',
    'o3',
    'Stay calm yourself and give them space to settle',
    true,
    10,
    'Perfect! Your calm presence is the most powerful tool.',
    'Co-regulation works through social baseline theory - children borrow calm from their parents.',
    'Porges, Polyvagal Theory (2011)',
    true
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Insert Actionable Takeaway
INSERT INTO actionable_takeaways (
    activity_id,
    tool_name,
    tool_type,
    when_to_use,
    why_it_works,
    try_it_when,
    how_to,
    example
) VALUES (
    'a1111111-1111-1111-1111-111111111111',
    'Regulated Presence',
    'diagnostic',
    'When your child is dysregulated (upset, angry, overwhelmed)',
    'Your regulated nervous system helps co-regulate your child''s dysregulated state. Their brain literally borrows your calm to return to baseline, making connection and conversation possible again.',
    'Your child comes home upset, has a meltdown, or shuts down emotionally',
    '["Notice signs of dysregulation (yelling, crying, withdrawal)", "Check your own state - take a breath if needed", "Offer calm, non-demanding presence", "Give space while staying emotionally available", "Wait for nervous system to settle before problem-solving"]'::jsonb,
    '{"situation": "7-year-old slams door after bad day at school", "action": "Parent takes a breath, stays calm, says ''I can see you''re upset. I''m here when you''re ready'' and gives space", "outcome": "Child calms down in 10 minutes, comes out and shares what happened"}'::jsonb
) ON CONFLICT (activity_id) DO NOTHING;

-- =============================================================================
-- Activity 2: Age 10-12
-- =============================================================================

-- Insert Activity
INSERT INTO daily_practice_activities (
    id,
    day_number,
    age_band,
    module_name,
    module_display_name,
    title,
    description,
    skill_focus,
    category,
    activity_type,
    is_reflection,
    scenario,
    research_concept,
    research_key_insight,
    research_citation,
    research_additional_context
) VALUES (
    'a1111111-1111-1111-1111-111111111112',
    1,
    '10-12',
    'conversation-state',
    'The Conversation State Model',
    'When Your Tween Shuts Down',
    'Learn to recognize dysregulation in tweens',
    'Emotional Awareness',
    'State Recognition',
    'basic-scenario',
    false,
    'Your 11-year-old comes home, goes straight to their room, and won''t come out for dinner. When you knock, they say "Leave me alone" in a flat voice.',
    'adolescent brain development',
    'During early adolescence, the brain undergoes major reorganization affecting emotional regulation',
    'Jensen & Nutt, The Teenage Brain (2015)',
    'Tweens may withdraw when overwhelmed rather than seek connection due to developmental changes'
) ON CONFLICT (day_number, age_band) DO NOTHING;

-- Insert Prompt 1
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '01111111-1111-1111-1111-111111111112',
    'a1111111-1111-1111-1111-111111111112',
    'p1',
    'state-identification',
    'What state is your tween in?',
    1,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

-- Insert Options for Prompt 1 (Activity 2)
INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback,
    science_note_brief,
    science_note_citation,
    science_note_show_citation
) VALUES
(
    '01111111-1111-1111-1111-111111111112',
    'o1',
    'Regulated and just wanting privacy',
    false,
    0,
    'The flat voice and withdrawal suggest dysregulation. Tweens need privacy, but this behavior shows emotional shutdown.',
    null,
    null,
    false
),
(
    '01111111-1111-1111-1111-111111111112',
    'o2',
    'Dysregulated - emotionally shutdown',
    true,
    10,
    'Yes! Tweens often show dysregulation through withdrawal and flat affect rather than big emotions.',
    'During early adolescence, the brain undergoes major reorganization. Tweens may withdraw when overwhelmed rather than seek connection.',
    'Jensen & Nutt, The Teenage Brain (2015)',
    true
),
(
    '01111111-1111-1111-1111-111111111112',
    'o3',
    'Being moody and difficult',
    false,
    0,
    'What looks like moodiness is usually dysregulation. Their developing brain makes emotional regulation harder.',
    null,
    null,
    false
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Insert Prompt 2 (Activity 2)
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '02111111-1111-1111-1111-111111111112',
    'a1111111-1111-1111-1111-111111111112',
    'p2',
    'best-response',
    'What''s your best first move?',
    2,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

-- Insert Options for Prompt 2 (Activity 2)
INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback,
    science_note_brief,
    science_note_citation,
    science_note_show_citation
) VALUES
(
    '02111111-1111-1111-1111-111111111112',
    'o1',
    'Insist they come out and talk to you',
    false,
    0,
    'Forcing connection when tweens are shut down usually backfires and increases resistance.',
    null,
    null,
    false
),
(
    '02111111-1111-1111-1111-111111111112',
    'o2',
    'Respect their need for space while staying available',
    true,
    10,
    'Perfect! Tweens need autonomy with availability. You might say ''I''m here if you need me'' and check in gently later.',
    'Autonomy support increases teen willingness to seek help. Feeling controlled decreases openness.',
    'Dahl et al., Adolescent Brain Development (2018)',
    true
),
(
    '02111111-1111-1111-1111-111111111112',
    'o3',
    'Leave them alone completely until they come to you',
    false,
    0,
    'Complete withdrawal can feel like abandonment. Brief check-ins show you care while respecting boundaries.',
    null,
    null,
    false
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Insert Actionable Takeaway (Activity 2)
INSERT INTO actionable_takeaways (
    activity_id,
    tool_name,
    tool_type,
    when_to_use,
    why_it_works,
    try_it_when,
    how_to,
    example
) VALUES (
    'a1111111-1111-1111-1111-111111111112',
    'Autonomy with Availability',
    'technique',
    'When your tween or teen is dysregulated and withdrawing',
    'Tweens and teens are developmentally wired to seek independence while still needing parental support. This approach honors both needs, making them more likely to come to you when ready.',
    'Your tween shuts down, withdraws to their room, or pushes you away emotionally',
    '["Acknowledge their need for space", "Communicate your availability without pressure", "Respect their timeline for opening up", "Check in briefly without demanding conversation", "Stay emotionally present even when physically separate"]'::jsonb,
    '{"situation": "11-year-old won''t leave room after hard day", "action": "Parent says ''I can see you need space. I''ll be in the kitchen if you want to talk'' and checks in gently 20 minutes later", "outcome": "Tween comes down later and opens up about friendship issue"}'::jsonb
) ON CONFLICT (activity_id) DO NOTHING;

-- =============================================================================
-- Activity 3: Age 13-16
-- =============================================================================

-- Insert Activity
INSERT INTO daily_practice_activities (
    id,
    day_number,
    age_band,
    module_name,
    module_display_name,
    title,
    description,
    skill_focus,
    category,
    activity_type,
    is_reflection,
    scenario,
    research_concept,
    research_key_insight,
    research_citation,
    research_additional_context
) VALUES (
    'a1111111-1111-1111-1111-111111111113',
    1,
    '13-16',
    'conversation-state',
    'The Conversation State Model',
    'Teen Emotional Flooding',
    'Learn to recognize and respond to teen dysregulation',
    'Emotional Awareness',
    'State Recognition',
    'basic-scenario',
    false,
    'Your 15-year-old storms in, throws their backpack down, and starts ranting about how "everything is so unfair" and "you just don''t understand." They''re talking fast, their voice is raised, and they seem on the verge of tears.',
    'adolescent emotional flooding',
    'Teen brains are particularly prone to emotional flooding due to heightened amygdala reactivity combined with still-developing prefrontal cortex',
    'Steinberg, Age of Opportunity (2014)',
    'What looks like drama is usually genuine overwhelm - teen emotions are intense and real, not manipulative'
) ON CONFLICT (day_number, age_band) DO NOTHING;

-- Insert Prompts and Options for Activity 3 (similar structure)
-- Prompt 1
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '01111111-1111-1111-1111-111111111113',
    'a1111111-1111-1111-1111-111111111113',
    'p1',
    'state-identification',
    'What state is your teen in?',
    1,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback
) VALUES
(
    '01111111-1111-1111-1111-111111111113',
    'o1',
    'Regulated - they''re communicating clearly',
    false,
    0,
    'The fast talking, raised voice, and physical agitation are signs of dysregulation, not effective communication.'
),
(
    '01111111-1111-1111-1111-111111111113',
    'o2',
    'Dysregulated - they''re emotionally flooded',
    true,
    10,
    'Exactly! Your teen is experiencing emotional flooding - their nervous system is overwhelmed.'
),
(
    '01111111-1111-1111-1111-111111111113',
    'o3',
    'Being dramatic for attention',
    false,
    0,
    'What looks like drama is usually genuine overwhelm. Teen emotions are intense and real, not manipulative.'
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Prompt 2
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '02111111-1111-1111-1111-111111111113',
    'a1111111-1111-1111-1111-111111111113',
    'p2',
    'best-response',
    'What''s your first move?',
    2,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback
) VALUES
(
    '02111111-1111-1111-1111-111111111113',
    'o1',
    'Try to solve the problem right away',
    false,
    0,
    'Problem-solving before regulation usually fails. They can''t access rational thinking while flooded.'
),
(
    '02111111-1111-1111-1111-111111111113',
    'o2',
    'Regulate yourself and offer calm presence',
    true,
    10,
    'Perfect! Your regulation helps their regulation. Take a breath, stay calm, and be a safe emotional container.'
),
(
    '02111111-1111-1111-1111-111111111113',
    'o3',
    'Tell them to calm down and talk rationally',
    false,
    0,
    'Being told to calm down when flooded usually increases activation. They need co-regulation, not commands.'
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Prompt 3
INSERT INTO prompts (
    id,
    activity_id,
    prompt_id,
    type,
    prompt_text,
    order_index,
    points
) VALUES (
    '03111111-1111-1111-1111-111111111113',
    'a1111111-1111-1111-1111-111111111113',
    'p3',
    'best-response',
    'After they calm down a bit, what helps most?',
    3,
    10
) ON CONFLICT (activity_id, prompt_id) DO NOTHING;

INSERT INTO prompt_options (
    prompt_id,
    option_id,
    option_text,
    correct,
    points,
    feedback
) VALUES
(
    '03111111-1111-1111-1111-111111111113',
    'o1',
    'Jump straight to advice and solutions',
    false,
    0,
    'Teens need to feel heard before they can hear you. Solutions come after connection.'
),
(
    '03111111-1111-1111-1111-111111111113',
    'o2',
    'Listen with empathy before problem-solving',
    true,
    10,
    'Yes! Feeling heard helps complete the regulation process. Then they can think clearly about solutions.'
),
(
    '03111111-1111-1111-1111-111111111113',
    'o3',
    'Change the subject to lighten the mood',
    false,
    0,
    'Changing the subject can feel dismissive. They need validation of their experience first.'
) ON CONFLICT (prompt_id, option_id) DO NOTHING;

-- Insert Actionable Takeaway (Activity 3)
INSERT INTO actionable_takeaways (
    activity_id,
    tool_name,
    tool_type,
    when_to_use,
    why_it_works,
    try_it_when,
    how_to,
    example
) VALUES (
    'a1111111-1111-1111-1111-111111111113',
    'Regulate, Relate, Reason',
    'framework',
    'When your teen (or any child) is emotionally flooded or dysregulated',
    'This sequence mirrors how the brain processes stress. The prefrontal cortex (reasoning) can''t function until the amygdala (emotion) settles. Your regulation helps their regulation, relationship provides safety, and only then can reasoning happen.',
    'Your teen is upset, ranting, crying, or emotionally overwhelmed',
    '["REGULATE: First, regulate yourself - take a breath, stay calm", "RELATE: Offer empathic presence - ''I can see this is really hard''", "REASON: Only after they calm, engage problem-solving brain", "Never skip steps - each builds on the previous", "Wait for signs of regulation before moving to reason"]'::jsonb,
    '{"situation": "15-year-old storms in ranting about unfairness", "action": "Parent stays calm (regulate), says ''That sounds really frustrating'' (relate), listens empathetically, then later asks ''Want to talk through some options?'' (reason)", "outcome": "Teen calms down, feels heard, and becomes open to problem-solving"}'::jsonb
) ON CONFLICT (activity_id) DO NOTHING;
