# Daily Practice Activities - ACTUAL Database Schema

**⚠️ IMPORTANT: This is the ACTUAL schema based on your database, not the migration files.**

---

## Database Structure

**ONE TABLE ONLY**: `daily_practice_activities`

Everything is stored in a single table with JSONB columns for complex data:
- `prompts` - JSONB column containing all prompts and their options
- `actionable_takeaway` - JSONB column containing the takeaway

**NO separate tables for prompts, options, or takeaways.**

---

## daily_practice_activities Table

### Complete Schema

```sql
CREATE TABLE daily_practice_activities (
  -- System fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Core identifiers (ALL REQUIRED)
  day_number INTEGER NOT NULL,
  age_band TEXT NOT NULL CHECK (age_band IN ('6-9', '10-12', '13-16')),
  module_name TEXT NOT NULL,
  module_display_name TEXT NOT NULL,

  -- Activity metadata
  title TEXT NOT NULL,
  description TEXT,
  skill_focus TEXT NOT NULL,
  category TEXT,
  activity_type TEXT NOT NULL DEFAULT 'basic-scenario',
  is_reflection BOOLEAN DEFAULT FALSE,

  -- Scenario content (REQUIRED)
  scenario TEXT NOT NULL,

  -- Research and learning (all optional)
  research_concept TEXT,
  research_key_insight TEXT,
  research_citation TEXT,
  research_additional_context TEXT,

  -- Additional content
  best_approach TEXT,
  follow_up_questions JSONB DEFAULT '[]'::jsonb,

  -- Complex data as JSONB (REQUIRED)
  prompts JSONB NOT NULL,
  actionable_takeaway JSONB NOT NULL,

  -- Constraints
  UNIQUE(day_number, age_band)
);
```

---

## Column Definitions

| Column | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | Primary key |
| `created_at` | TIMESTAMPTZ | Auto | NOW() | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | Auto | NOW() | Record update timestamp |
| `day_number` | INTEGER | **YES** | - | Day 1-61 in Foundation curriculum |
| `age_band` | TEXT | **YES** | - | `'6-9'` \| `'10-12'` \| `'13-16'` |
| `module_name` | TEXT | **YES** | - | Module identifier (e.g., 'state-recognition') |
| `module_display_name` | TEXT | **YES** | - | Human-readable module name |
| `title` | TEXT | **YES** | - | Activity title |
| `description` | TEXT | No | NULL | Activity description |
| `skill_focus` | TEXT | **YES** | - | Primary skill being taught |
| `category` | TEXT | No | NULL | Category classification |
| `activity_type` | TEXT | **YES** | 'basic-scenario' | See [Activity Types](#activity-types) |
| `is_reflection` | BOOLEAN | No | FALSE | Whether this is a reflection activity |
| `scenario` | TEXT | **YES** | - | The scenario narrative (2-4 sentences) |
| `research_concept` | TEXT | No | NULL | Research concept being referenced |
| `research_key_insight` | TEXT | No | NULL | Key research finding |
| `research_citation` | TEXT | No | NULL | Citation for research |
| `research_additional_context` | TEXT | No | NULL | Additional research context |
| `best_approach` | TEXT | No | NULL | Optional best approach guidance |
| `follow_up_questions` | JSONB | No | `[]` | Array of question strings |
| `prompts` | JSONB | **YES** | - | Array of prompt objects (see [shape](#prompts-jsonb)) |
| `actionable_takeaway` | JSONB | **YES** | - | Takeaway object (see [shape](#actionable_takeaway-jsonb)) |

---

## JSONB Column Shapes

### <a name="prompts-jsonb"></a>prompts (JSONB Array)

**Structure:**
```json
[
  {
    "promptId": "p1",
    "type": "state-identification",
    "promptText": "What state is your child in?",
    "order": 1,
    "points": 10,
    "options": [
      {
        "optionId": "opt-1",
        "optionText": "Dysregulated (State 1)",
        "correct": true,
        "points": 10,
        "feedback": "Correct! The inability to speak indicates...",
        "scienceNote": {
          "brief": "When dysregulated, the amygdala hijacks the prefrontal cortex",
          "citation": "Porges, S. W. (2011). The Polyvagal Theory",
          "showCitation": false
        }
      },
      {
        "optionId": "opt-2",
        "optionText": "Emotionally Activated (State 2)",
        "correct": false,
        "points": 0,
        "feedback": "In State 2, children can still use words..."
      }
      // ... 2 more options (total of 4)
    ]
  }
  // ... more prompts (typically 2-4 total)
]
```

**Prompt Object Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `promptId` | string | **YES** | Unique ID like 'p1', 'p2', 'p3' |
| `type` | string | **YES** | Prompt type (see [types](#prompt-types)) |
| `promptText` | string | **YES** | The question text |
| `order` | number | **YES** | Display order (1, 2, 3...) |
| `points` | number | No | Points for correct answer (default: 10) |
| `options` | array | **YES** | Array of 4 option objects |

**Option Object Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `optionId` | string | **YES** | Unique ID like 'opt-1', 'opt-2' |
| `optionText` | string | **YES** | The answer choice text |
| `correct` | boolean | **YES** | Whether this is correct (exactly 1 per prompt) |
| `points` | number | **YES** | Points (10 for correct, 0 for wrong) |
| `feedback` | string | **YES** | Feedback text (2-3 sentences) |
| `scienceNote` | object | No | Science explanation (optional) |
| `scienceNote.brief` | string | No | Brief explanation (1-2 sentences) |
| `scienceNote.citation` | string | No | Citation text |
| `scienceNote.showCitation` | boolean | No | Whether to show citation (default: false) |

**Business Rules:**
- Each activity must have 2-4 prompts
- Each prompt must have exactly 4 options
- Exactly 1 option per prompt must have `correct: true`
- Only correct options should have `scienceNote`

---

### <a name="actionable_takeaway-jsonb"></a>actionable_takeaway (JSONB Object)

**Structure:**
```json
{
  "toolName": "The State Check",
  "toolType": "diagnostic",
  "whenToUse": "before you respond to any challenging behavior",
  "howTo": [
    "Pause and observe: What do you see and hear right now?",
    "Ask yourself: Can my child think and talk calmly in this moment?",
    "If NO → They need help calming down first",
    "If YES → They can engage in conversation"
  ],
  "whyItWorks": "Different nervous system states require completely different responses...",
  "tryItWhen": "Your child is upset about something this week",
  "example": {
    "situation": "Your child comes inside crying because their friend said something mean",
    "action": "You pause and do a State Check. You notice they're sobbing but trying to tell you what happened. You sit close and say, 'That sounds really hard' and listen.",
    "outcome": "Your child calms down as they share the story, and together you problem-solve."
  }
}
```

**Takeaway Object Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `toolName` | string | **YES** | Name of the tool/technique |
| `toolType` | string | No | Type (see [types](#tool-types)) |
| `whenToUse` | string | **YES** | When to apply this tool |
| `howTo` | array | **YES** | Array of step strings (3-5 steps) |
| `whyItWorks` | string | **YES** | Explanation of effectiveness |
| `tryItWhen` | string | No | Specific prompt for this week |
| `example` | object | No | Example story object |
| `example.situation` | string | **YES** | Brief situation description |
| `example.action` | string | **YES** | What parent does/says |
| `example.outcome` | string | **YES** | What happens as a result |

---

## Enums and Allowed Values

### <a name="activity-types"></a>Activity Types

| Value | Description |
|-------|-------------|
| `'basic-scenario'` | Standard scenario with state identification (default) |
| `'spot-the-mistake'` | Identify what went wrong in a scenario |
| `'before-after-comparison'` | Compare two approaches to the same situation |
| `'sequential-decision'` | Multi-step decision-making scenario |
| `'skill-application'` | Apply a specific skill to a new situation |
| `'self-assessment'` | Reflection on own parenting patterns |

---

### <a name="prompt-types"></a>Prompt Types

**Common values** (not database-constrained):

| Value | Description |
|-------|-------------|
| `'state-identification'` | Identify the child's conversation state |
| `'best-response'` | Choose the best parenting response |
| `'spot-mistake'` | Identify the mistake in the scenario |
| `'dialogue-completion'` | Complete the dialogue appropriately |
| `'sequencing'` | Order steps correctly |
| `'what-happens-next'` | Predict outcome of an approach |
| `'reflection'` | Self-reflection question |

---

### <a name="tool-types"></a>Tool Types

**Common values** (optional, not database-constrained):

| Value | Description |
|-------|-------------|
| `'diagnostic'` | Tool for assessing/identifying situations |
| `'technique'` | Active parenting technique |
| `'framework'` | Conceptual framework for understanding |
| `'response-pattern'` | Pattern for how to respond |

---

## Complete Example Record

```json
{
  "id": "9146282d-0c00-435b-b906-a2c86cdc8f7a",
  "created_at": "2025-10-21T10:34:55.260340Z",
  "updated_at": "2025-10-21T10:34:55.260340Z",

  "day_number": 1,
  "age_band": "6-9",
  "module_name": "state-recognition",
  "module_display_name": "The Conversation State Model",
  "title": "What Are Conversation States?",
  "description": "Discover why the same words work sometimes but not others",
  "skill_focus": "Understanding conversation states as a diagnostic framework",
  "category": null,
  "activity_type": "basic-scenario",
  "is_reflection": false,

  "scenario": "Your 8-year-old bursts through the door around 3:30pm, immediately asking for screen time. You say no because homework needs to be done first. First attempt: they throw the tablet, scream 'I hate you!' and run to their room, slamming the door. Second attempt (next day, same request): they sigh heavily, say 'That's not fair,' but sit down at the table.",

  "research_concept": "polyvagal theory and the neurobiology of emotional regulation",
  "research_key_insight": "The nervous system operates in different states that determine what's neurologically possible...",
  "research_citation": "Porges, S. W. (2011). The Polyvagal Theory: Neurophysiological Foundations...",
  "research_additional_context": "Dr. Dan Siegel describes this as 'flipping your lid'—when the thinking brain goes offline...",

  "best_approach": null,
  "follow_up_questions": [],

  "prompts": [
    {
      "promptId": "p1",
      "type": "best-response",
      "promptText": "Why did the same words ('no screen time until homework is done') get such different reactions?",
      "order": 1,
      "points": 10,
      "options": [
        {
          "optionId": "opt-1",
          "optionText": "Different nervous system states",
          "correct": true,
          "points": 10,
          "feedback": "Exactly! Your child's nervous system state determines what they can hear and process. Same words + different state = different outcome.",
          "scienceNote": {
            "brief": "When dysregulated, the amygdala hijacks the prefrontal cortex, making reasoning impossible.",
            "citation": "Porges, S. W. (2011). The Polyvagal Theory",
            "showCitation": false
          }
        },
        {
          "optionId": "opt-2",
          "optionText": "Child is being manipulative",
          "correct": false,
          "points": 0,
          "feedback": "Different reactions aren't manipulation—they reflect real differences in nervous system capacity. Your child isn't choosing to be difficult; their brain is in a different state."
        },
        {
          "optionId": "opt-3",
          "optionText": "You need better words",
          "correct": false,
          "points": 0,
          "feedback": "The problem isn't your words—it's the mismatch between your approach and your child's state. Perfect words won't work if your child's thinking brain is offline."
        },
        {
          "optionId": "opt-4",
          "optionText": "Child should control reactions",
          "correct": false,
          "points": 0,
          "feedback": "When dysregulated, children cannot 'just control themselves.' Self-control requires a calm nervous system and an online prefrontal cortex."
        }
      ]
    }
  ],

  "actionable_takeaway": {
    "toolName": "The State Check",
    "toolType": "diagnostic",
    "whenToUse": "before you respond to any challenging behavior or difficult moment with your child",
    "howTo": [
      "Pause and observe: What do you see and hear right now?",
      "Ask yourself: Can my child think and talk calmly in this moment?",
      "If NO (screaming, can't talk, extremely upset) → They need help calming down first",
      "If YES (can talk, even if upset or resistant) → They can engage in conversation"
    ],
    "whyItWorks": "Different nervous system states require completely different responses. What works when your child is calm will backfire when they're overwhelmed.",
    "tryItWhen": "Your child is upset about something this week",
    "example": {
      "situation": "Your child comes inside crying because their friend said something mean at the playground",
      "action": "Before jumping in to fix it or give advice, you pause and do a State Check. You notice they're sobbing but trying to tell you what happened. They CAN talk = they can engage. You sit close and say, 'That sounds really hard' and listen, instead of immediately problem-solving.",
      "outcome": "Your child calms down as they share the story, and together you problem-solve what to do next time."
    }
  }
}
```

---

## Summary

**Database Structure:**
- **1 table only**: `daily_practice_activities`
- **23 total columns**
- **2 JSONB columns** for complex nested data (prompts, actionable_takeaway)
- **1 unique constraint**: (day_number, age_band)

**Typical Activity Contains:**
- 1 scenario (2-4 sentences)
- 2-4 prompts in JSONB
- 8-16 options total (4 per prompt) in JSONB
- 1 actionable takeaway in JSONB
- 3-5 how-to steps
- 1 example story

**Data Volume (61-day Foundation curriculum):**
- 183 total records (61 days × 3 age bands)
- All prompts, options, and takeaways stored as JSONB within each record
