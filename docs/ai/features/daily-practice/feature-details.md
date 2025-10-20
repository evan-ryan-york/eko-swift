# Daily Practice Feature - Overview

## What is Daily Practice?

Daily Practice is a core feature of Eko that helps parents build parenting skills through bite-sized, scenario-based learning activities. Each day, parents complete one practice activity (5-10 minutes) that teaches them research-backed parenting strategies, tools, and frameworks through realistic situations they can immediately apply with their children.

**Core Value Proposition:** Parents walk away from every daily practice feeling like they have something concrete they can use *today* that makes them a better parent.

---

## How It Works

### For Parents (User Experience)

**Daily Rhythm:**
1. **Open app** → See "Start Today's Daily Practice" (or "Completed for today!" if done)
2. **Start activity** → Read a realistic parenting scenario matched to their child's age
3. **Answer prompts** → Make choices about what to do, receive immediate feedback with embedded research
4. **Learn a tool** → Get one actionable takeaway they can use immediately
5. **See results** → View their score and progress

**Key UX Principles:**
- **One per day** (UTC-based to prevent timezone exploitation)
- **Sequential progression** (Day 1 → Day 2 → Day 3...)
- **Age-appropriate** (Content automatically filtered to child's age: 6-9, 10-12, or 13-16)
- **Immediately actionable** (Every activity ends with a concrete tool to use today)

---

## Content Architecture

### Four-Bucket Content Model

**1. Foundations (Days 1-60+)**
Core curriculum of 10 essential parenting modules everyone completes:
- Module 1: The Conversation State Model
- Module 2: Parent Self-Regulation
- Module 3: Co-Regulation (State 1 Response)
- Module 4: Emotion Coaching (State 2 Response)
- Module 5: The Attachment Foundation
- Module 6: Proactive Connection (Play & Presence)
- Module 7: Autonomy Support
- Module 8: Setting Clear, Kind Boundaries
- Module 9: Collaborative Problem-Solving
- Module 10: Repair After Rupture

Each module = 5-7 days of activities

**2. Extensions (Unlimited)**
More specialized topics unlocked after completing Foundations:
- Apologizing effectively as a parent
- Balancing privacy and online safety
- Handling sibling conflict
- Supporting anxious children
- etc.

**3. Reviews (Unlimited)**
Spaced repetition activities that revisit Foundation concepts with new scenarios

**4. Applied Scenarios (Unlimited)**
Complex, multi-step scenarios that combine multiple tools and concepts

---

## Activity Structure

### Scenario-Based Learning

Every activity follows this structure:

**1. Scenario (The Setup)**
A realistic parenting situation matched to the child's age band:
- 6-9 years: "Your 7-year-old comes home and immediately starts crying..."
- 10-12 years: "Your 11-year-old just got cut from the basketball team..."
- 13-16 years: "Your 15-year-old had a huge fight with their best friend..."

**2. Prompts (2-4 Questions)**
Multiple-choice questions that test understanding and application:
- "What state is your child in?"
- "What should you do first?"
- "What will likely happen if you say X?"

**3. Feedback (After Each Answer)**
Immediate feedback that includes:
- Whether they're correct
- Why this answer works (or doesn't)
- Embedded research/science explaining the mechanism
- Points awarded (with partial credit for multiple attempts)

**4. Actionable Takeaway (End of Activity)**
One concrete tool they can use immediately:
- Tool name (e.g., "Regulated Presence")
- When to use it
- Step-by-step how-to
- Real example in action
- "Try it when..." specific situations

**5. Results Screen**
- Total points earned
- Module progress
- Option to continue to next day (if available)

---

## Interaction Variety

To prevent monotony, activities use different interaction patterns:

**Core Patterns (90% of days):**
- **State Identification:** "What state is your child in?"
- **Best Response Selection:** "What should you do first?"
- **Spot the Mistake:** "Where did this parent lose connection?"
- **Sequential Decision Tree:** Branching choices where your first answer affects what happens next
- **Dialogue Completion:** "Fill in what you'd say next"
- **Before/After Comparison:** "What's different in these two approaches?"

**Variety Patterns (10% of days):**
- **Sequencing:** "Put these steps in order"
- **Select All That Apply:** "Which responses show emotion coaching?"
- **Reflection:** Self-assessment questions (no wrong answers)

All patterns share the same core UI (header, scenario, progress, feedback) but vary the question format to keep engagement high.

---

## Scoring System

**Goal:** Reward learning while encouraging thoughtful attempts

**Rules:**
- **First correct answer:** Full points (typically 10)
- **Second correct answer:** ~70% points (7 points)
- **Third correct answer:** ~40% points (4 points)
- **Fourth+ correct answer:** 0 points
- **Wrong answers:** 0 points, but can retry
- **Already-tried options:** Disabled to prevent random guessing

**Session Scoring:**
- Each prompt worth 10 points
- Activity with 3 prompts = 30 points maximum
- Points accumulate across all days into user's total score

**Why this works:**
- Encourages thinking before answering (first attempt matters)
- Doesn't punish learning (can retry wrong answers)
- Provides partial credit (recognizes effort)
- Prevents gaming (already-tried options disabled)

---

## Daily Completion Logic

**Rule:** One activity per UTC calendar day

**How it works:**
1. User completes Day 5 on January 15th at 11pm
2. Completion timestamp stored: `2025-01-15T23:00:00Z`
3. User opens app on January 16th at 6am
4. System extracts dates: `2025-01-15` vs `2025-01-16` → Different days
5. Day 6 becomes available

**Why UTC:** Prevents timezone manipulation and ensures global consistency

**Edge cases handled:**
- **Midnight rollover:** User starts at 11:55pm, finishes at 12:05am → Still counts as completed for the new day
- **Timezone travel:** UTC normalization prevents exploitation
- **Multiple devices:** Server-authoritative completion prevents conflicts

---

## Age Band Filtering

**How it works:**
1. System gets user's child profile (or defaults to 6-9)
2. Calculates age from birthday
3. Maps to age band: 6-9, 10-12, or 13-16
4. Queries for activity matching: `day_number` AND `age_band`

**Content differentiation:**
- Same concepts across all ages (e.g., "recognizing dysregulation")
- Different scenarios/contexts (7-year-old's toy vs 15-year-old's social drama)
- Age-appropriate language and complexity
- Same module structure for everyone

---

## Module Progression

**Linear progression through Foundations:**

**Week 1-2:** Understanding States
- Days 1-7: Conversation State Model
- Days 8-12: Parent Self-Regulation

**Week 3-4:** Responding to Crisis
- Days 13-18: Co-Regulation
- Days 19-24: Emotion Coaching

**Week 5-6:** Building Connection
- Days 25-30: Attachment Foundation
- Days 31-36: Proactive Connection

**Week 7-9:** Collaboration & Structure
- Days 37-42: Autonomy Support
- Days 43-48: Clear, Kind Boundaries
- Days 49-54: Collaborative Problem-Solving

**Week 10:** Repair & Integration
- Days 55-60: Repair After Rupture

**After Day 60:** Enter Extensions + Reviews + Applied Scenarios phase

---

## Success Metrics

**Engagement:**
- Daily completion rate
- Streak length (consecutive days)
- Time to complete activity
- Drop-off points within activities

**Learning:**
- First-attempt accuracy rate
- Improvement over time on similar concepts
- Module completion rate

**Value Perception:**
- "Actionable Takeaway" screen engagement
- Return rate next day
- Retention after completing Foundations

**Business:**
- Feature usage as predictor of subscription retention
- Conversion from free trial based on Daily Practice completion

---

## Integration with Other Features

**Child Profiles:**
- Age determines content filtering
- Personality traits could influence scenario selection (future)

**Conversation Playbook:**
- Daily Practice teaches HOW to have conversations (skills)
- Playbook teaches WHAT to talk about (topics like puberty, bullying, etc.)
- Clear separation: tools vs. topics

**Lyra (AI Coach):**
- Tools learned in Daily Practice inform Lyra's recommendations
- Lyra can reference: "Remember the 'Regulated Presence' tool from Day 3?"

**Analytics:**
- Module completion unlocks more personalized Lyra guidance
- Tool library accessible from profile

---

## Future Enhancements

**Post-MVP:**
- **Tool Library:** Saved collection of all tools learned, searchable by situation
- **Custom Practice:** Choose specific modules to revisit
- **Multi-child Support:** Different age bands for different children
- **Shared Progress:** Partner/co-parent can see your progress
- **Applied Scenarios:** Complex 10-minute scenarios combining multiple tools
- **Voice-Based Scenarios:** Audio scenarios with verbal response practice
- **Community Insights:** "87% of parents found this tool helpful for bedtime"

---

## Why This Feature Matters

**For Product Success:**
- Creates daily habit loop (open app → complete practice → feel accomplished)
- Demonstrates clear value quickly (learn something useful in first 5 minutes)
- Builds parent confidence incrementally (not overwhelming)
- Provides measurable progress (Day 15 of 60, Module 3 complete)

**For Parent Outcomes:**
- Concrete tools they can use immediately
- Research-backed confidence (not just opinions)
- Realistic scenarios (not abstract theory)
- Accumulating skill set (60+ tools after Foundations)

**For Business Model:**
- High engagement → Higher retention
- Clear progression → Natural upgrade path to premium
- Completion milestones → Celebration moments → Sharing opportunities
- Foundations as "core value" → Extensions as "continued value"

---

## Technical Architecture Summary

**Client (Swift/SwiftUI):**
- One flexible activity screen with multiple interaction patterns
- Optimistic UI for feedback, server-authoritative for completion
- Local state for session, server state for progress
- Offline-capable scenario viewing (cached after fetch)

**Server (Supabase):**
- PostgreSQL database with JSONB for flexible prompt structures
- Edge Functions for business logic (daily check, completion, scoring)
- Row-level security for user data isolation
- Real-time updates not required (daily cadence, not live)

**Content Management:**
- AI-assisted generation tool for creating activities
- Templates per interaction pattern
- Age-band variation generation
- Quality review workflow before publishing

---

## Key Design Principles

1. **Respect parent's time:** 5-10 minutes max, clear progress
2. **Immediate value:** Every activity = one usable tool
3. **Research-backed credibility:** Science embedded, not optional
4. **Age-appropriate realism:** Scenarios feel like "my actual life"
5. **Non-judgmental learning:** Wrong answers are learning opportunities
6. **Accumulating confidence:** Skills build on each other
7. **Sustainable engagement:** Can miss days without penalty, but daily rhythm encouraged

---

## Content Pipeline

**Creation:**
1. Define module learning goals
2. Identify key tools/concepts per day
3. Generate age-appropriate scenarios (3 versions per day)
4. Write prompts with research-backed feedback
5. Create actionable takeaway
6. QA for accuracy, tone, and applicability

**Launch Requirements:**
- Minimum: Days 1-14 (2 weeks) across all age bands = 42 activities
- Recommended: Days 1-30 (1 month) = 90 activities
- Ideal: Full Foundations (Days 1-60) = 180 activities

**Ongoing:**
- Add 1-2 new days per week to stay ahead of power users
- Extensions added based on user requests/needs
- Reviews auto-generated from existing Foundation content
- Applied Scenarios created quarterly