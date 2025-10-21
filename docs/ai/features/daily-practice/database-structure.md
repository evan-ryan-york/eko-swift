# Daily Practice Activities - Complete Database Schema

## Table of Contents
1. [Main Activity Table](#daily_practice_activities)
2. [Prompts Table](#prompts)
3. [Prompt Options Table](#prompt_options)
4. [Actionable Takeaways Table](#actionable_takeaways)
5. [Relationships & Constraints](#relationships)
6. [Enum Values & Data Shapes](#enums-and-data-shapes)

---

## 1. daily_practice_activities

Main table storing activity metadata, scenario, and research information.

### Schema

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

  -- Additional content (optional)
  best_approach TEXT,
  follow_up_questions JSONB DEFAULT '[]'::jsonb,

  -- Constraints
  UNIQUE(day_number, age_band)
);
```

### Column Definitions

| Column | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | Primary key |
| `created_at` | TIMESTAMPTZ | Auto | NOW() | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | Auto | NOW() | Record update timestamp (auto-updated) |
| `day_number` | INTEGER | **YES** | - | Day 1-61 in Foundation curriculum |
| `age_band` | TEXT | **YES** | - | Child age range (see [Allowed Values](#age_band)) |
| `module_name` | TEXT | **YES** | - | Module identifier (e.g., 'state-recognition') |
| `module_display_name` | TEXT | **YES** | - | Human-readable module name |
| `title` | TEXT | **YES** | - | Activity title |
| `description` | TEXT | No | NULL | Activity description |
| `skill_focus` | TEXT | **YES** | - | Primary skill being taught |
| `category` | TEXT | No | NULL | Category classification |
| `activity_type` | TEXT | **YES** | 'basic-scenario' | Activity format (see [Allowed Values](#activity_type)) |
| `is_reflection` | BOOLEAN | No | FALSE | Whether this is a reflection activity |
| `scenario` | TEXT | **YES** | - | The scenario narrative (2-4 sentences) |
| `research_concept` | TEXT | No | NULL | Research concept being referenced |
| `research_key_insight` | TEXT | No | NULL | Key research finding |
| `research_citation` | TEXT | No | NULL | Citation for research |
| `research_additional_context` | TEXT | No | NULL | Additional research context |
| `best_approach` | TEXT | No | NULL | Optional best approach guidance |
| `follow_up_questions` | JSONB | No | `[]` | Array of follow-up question strings |

### Constraints
- **UNIQUE**: `(day_number, age_band)` - Each day can only have one activity per age band
- **CHECK**: `age_band IN ('6-9', '10-12', '13-16')`

---

## 2. prompts

Questions/prompts within each activity. Each activity has 2-4 prompts.

### Schema

```sql
CREATE TABLE prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id) ON DELETE CASCADE,

  -- Prompt metadata
  prompt_id TEXT NOT NULL,
  type TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  points INTEGER DEFAULT 10,

  UNIQUE(activity_id, prompt_id)
);
```

### Column Definitions

| Column | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | Primary key |
| `created_at` | TIMESTAMPTZ | Auto | NOW() | Record creation timestamp |
| `activity_id` | UUID | **YES** | - | Foreign key to daily_practice_activities |
| `prompt_id` | TEXT | **YES** | - | Prompt identifier (e.g., 'p1', 'p2', 'p3') |
| `type` | TEXT | **YES** | - | Prompt type (see [Allowed Values](#prompt_type)) |
| `prompt_text` | TEXT | **YES** | - | The actual question text |
| `order_index` | INTEGER | **YES** | - | Display order (1, 2, 3, etc.) |
| `points` | INTEGER | No | 10 | Points awarded for correct answer |

### Constraints
- **UNIQUE**: `(activity_id, prompt_id)` - Each prompt_id must be unique within an activity
- **CASCADE DELETE**: When activity is deleted, all prompts are deleted

---

## 3. prompt_options

Answer choices for each prompt. Each prompt has exactly 4 options (1 correct, 3 wrong).

### Schema

```sql
CREATE TABLE prompt_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key
  prompt_id UUID NOT NULL REFERENCES prompts(id) ON DELETE CASCADE,

  -- Option metadata
  option_id TEXT NOT NULL,
  option_text TEXT NOT NULL,
  correct BOOLEAN DEFAULT FALSE,
  points INTEGER DEFAULT 0,

  -- Feedback
  feedback TEXT NOT NULL,

  -- Science note (optional)
  science_note_brief TEXT,
  science_note_citation TEXT,
  science_note_show_citation BOOLEAN DEFAULT FALSE,

  UNIQUE(prompt_id, option_id)
);
```

### Column Definitions

| Column | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | Primary key |
| `created_at` | TIMESTAMPTZ | Auto | NOW() | Record creation timestamp |
| `prompt_id` | UUID | **YES** | - | Foreign key to prompts |
| `option_id` | TEXT | **YES** | - | Option identifier (e.g., 'opt-1', 'opt-2') |
| `option_text` | TEXT | **YES** | - | The answer choice text |
| `correct` | BOOLEAN | No | FALSE | Whether this is the correct answer |
| `points` | INTEGER | No | 0 | Points awarded (usually 10 for correct, 0 for wrong) |
| `feedback` | TEXT | **YES** | - | Feedback shown after selection (2-3 sentences) |
| `science_note_brief` | TEXT | No | NULL | Brief science explanation (1-2 sentences) |
| `science_note_citation` | TEXT | No | NULL | Citation for science note |
| `science_note_show_citation` | BOOLEAN | No | FALSE | Whether to display citation |

### Constraints
- **UNIQUE**: `(prompt_id, option_id)` - Each option_id must be unique within a prompt
- **CASCADE DELETE**: When prompt is deleted, all options are deleted
- **Business Rule**: Each prompt should have exactly 4 options, with exactly 1 correct

---

## 4. actionable_takeaways

Actionable tool/technique provided at the end of each activity. One per activity.

### Schema

```sql
CREATE TABLE actionable_takeaways (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key
  activity_id UUID NOT NULL REFERENCES daily_practice_activities(id) ON DELETE CASCADE,

  -- Tool metadata
  tool_name TEXT NOT NULL,
  tool_type TEXT,
  when_to_use TEXT NOT NULL,
  why_it_works TEXT NOT NULL,
  try_it_when TEXT,

  -- Steps and example
  how_to JSONB NOT NULL,
  example JSONB,

  UNIQUE(activity_id)
);
```

### Column Definitions

| Column | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | Auto | gen_random_uuid() | Primary key |
| `created_at` | TIMESTAMPTZ | Auto | NOW() | Record creation timestamp |
| `activity_id` | UUID | **YES** | - | Foreign key to daily_practice_activities |
| `tool_name` | TEXT | **YES** | - | Name of the tool/technique |
| `tool_type` | TEXT | No | NULL | Type classification (see [Allowed Values](#tool_type)) |
| `when_to_use` | TEXT | **YES** | - | When to apply this tool |
| `why_it_works` | TEXT | **YES** | - | Explanation of why it's effective |
| `try_it_when` | TEXT | No | NULL | Specific prompt to try this week |
| `how_to` | JSONB | **YES** | - | Array of step strings (see [Data Shape](#how_to_shape)) |
| `example` | JSONB | No | NULL | Example object (see [Data Shape](#example_shape)) |

### Constraints
- **UNIQUE**: `activity_id` - Each activity can have only one takeaway
- **CASCADE DELETE**: When activity is deleted, takeaway is deleted

---

## 5. Relationships & Constraints

### Relationship Diagram

```
daily_practice_activities (1)
  ├── prompts (2-4)
  │   └── prompt_options (4 each)
  └── actionable_takeaways (1)
```

### Cascade Deletion Rules

- Deleting an **activity** deletes all related prompts, options, and takeaways
- Deleting a **prompt** deletes all related options
- **Cannot delete** if it would leave orphaned records

### Indexes

```sql
-- Performance indexes
CREATE INDEX idx_activities_day_age ON daily_practice_activities(day_number, age_band);
CREATE INDEX idx_activities_module ON daily_practice_activities(module_name);
CREATE INDEX idx_prompts_activity ON prompts(activity_id);
CREATE INDEX idx_options_prompt ON prompt_options(prompt_id);
```

---

## 6. Enums and Data Shapes

### <a name="age_band"></a>age_band (Enum)

**Allowed Values:**
- `'6-9'` - Elementary age children
- `'10-12'` - Middle childhood
- `'13-16'` - Teenagers

**Database Constraint:**
```sql
CHECK (age_band IN ('6-9', '10-12', '13-16'))
```

---

### <a name="activity_type"></a>activity_type (Enum)

**Allowed Values:**

| Value | Description |
|-------|-------------|
| `'basic-scenario'` | Standard scenario with state identification |
| `'spot-the-mistake'` | Identify what went wrong in a scenario |
| `'before-after-comparison'` | Compare two approaches to the same situation |
| `'sequential-decision'` | Multi-step decision-making scenario |
| `'skill-application'` | Apply a specific skill to a new situation |
| `'self-assessment'` | Reflection on own parenting patterns |

**Default:** `'basic-scenario'`

---

### <a name="prompt_type"></a>prompt_type (Enum-like)

**Common Values:**

| Value | Description |
|-------|-------------|
| `'state-identification'` | Identify the child's conversation state |
| `'best-response'` | Choose the best parenting response |
| `'spot-mistake'` | Identify the mistake in the scenario |
| `'dialogue-completion'` | Complete the dialogue appropriately |
| `'sequencing'` | Order steps correctly |
| `'what-happens-next'` | Predict outcome of an approach |
| `'reflection'` | Self-reflection question |

**Note:** Not database-constrained. Can be any string.

---

### <a name="tool_type"></a>tool_type (Enum-like)

**Common Values:**

| Value | Description |
|-------|-------------|
| `'diagnostic'` | Tool for assessing/identifying situations |
| `'technique'` | Active parenting technique |
| `'framework'` | Conceptual framework for understanding |
| `'response-pattern'` | Pattern for how to respond |

**Note:** Optional field. Not database-constrained.

---

### <a name="how_to_shape"></a>how_to (JSONB Array)

**Data Shape:**
```json
[
  "Step 1: First action to take",
  "Step 2: Second action to take",
  "Step 3: Third action to take"
]
```

**Example:**
```json
[
  "Pause and observe: What do you see and hear right now?",
  "Ask yourself: Can my child think and talk calmly in this moment?",
  "If NO → They need help calming down first",
  "If YES → They can engage in conversation"
]
```

**Requirements:**
- Array of strings
- Each string is one step
- Typically 3-5 steps
- Steps should be concrete and actionable

---

### <a name="example_shape"></a>example (JSONB Object)

**Data Shape:**
```json
{
  "situation": "Brief description of the situation",
  "action": "What the parent does/says",
  "outcome": "What happens as a result"
}
```

**Example:**
```json
{
  "situation": "Your child comes inside crying because their friend said something mean at the playground",
  "action": "Before jumping in to fix it, you pause and do a State Check. You notice they're sobbing but trying to tell you what happened. They CAN talk = they can engage. You sit close and say, 'That sounds really hard' and listen.",
  "outcome": "Your child calms down as they share the story, and together you problem-solve what to do next time."
}
```

**Requirements:**
- Object with exactly 3 keys
- All values are strings
- Should tell a complete mini-story

---

### follow_up_questions (JSONB Array)

**Data Shape:**
```json
[
  "Question 1 text here?",
  "Question 2 text here?",
  "Question 3 text here?"
]
```

**Example:**
```json
[
  "How might this look different with a teenager versus a 7-year-old?",
  "What would you do if your child was in State 1 (dysregulated)?",
  "When has a similar situation happened in your family?"
]
```

**Requirements:**
- Array of strings
- Each string is a question
- Typically 0-5 questions
- Defaults to empty array `[]`

---

## Complete Example Record

### Activity JSON (as generated by AI)

```json
{
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
  "scenario": "Your 8-year-old asks for screen time right after school...",
  "research_concept": "polyvagal theory",
  "research_key_insight": "The nervous system operates in different states...",
  "research_citation": "Porges, S. W. (2011). The Polyvagal Theory",
  "research_additional_context": "Dr. Dan Siegel describes this as 'flipping your lid'...",
  "best_approach": null,
  "follow_up_questions": [],
  "prompts": [
    {
      "promptId": "p1",
      "type": "best-response",
      "promptText": "Why did the same words get different reactions?",
      "order": 1,
      "points": 10,
      "options": [
        {
          "optionId": "opt-1",
          "optionText": "Different nervous system states",
          "correct": true,
          "points": 10,
          "feedback": "Exactly! Your child's nervous system state determines...",
          "scienceNote": {
            "brief": "When dysregulated, the amygdala hijacks the prefrontal cortex",
            "citation": "Porges, S. W. (2011)",
            "showCitation": false
          }
        },
        {
          "optionId": "opt-2",
          "optionText": "Child is being manipulative",
          "correct": false,
          "points": 0,
          "feedback": "Different reactions aren't manipulation—they reflect real differences..."
        }
      ]
    }
  ],
  "actionable_takeaway": {
    "toolName": "The State Check",
    "toolType": "diagnostic",
    "whenToUse": "before you respond to any challenging behavior",
    "howTo": [
      "Pause and observe: What do you see and hear right now?",
      "Ask yourself: Can my child think and talk calmly?",
      "If NO → They need help calming down first",
      "If YES → They can engage in conversation"
    ],
    "whyItWorks": "Different nervous system states require different responses...",
    "tryItWhen": "Your child is upset about something this week",
    "example": {
      "situation": "Your child comes inside crying...",
      "action": "You pause and do a State Check...",
      "outcome": "Your child calms down as they share..."
    }
  }
}
```

---

## Summary Statistics

**Database Structure:**
- **4 tables** (1 main + 3 related)
- **46 total columns** across all tables
- **8 foreign key relationships**
- **4 unique constraints**
- **4 indexes** for query performance

**Typical Activity Contains:**
- 1 scenario (2-4 sentences)
- 2-4 prompts
- 8-16 options (4 per prompt)
- 1 actionable takeaway
- 3-5 how-to steps
- 1 example story

**Data Volume (61-day Foundation curriculum):**
- 183 activities (61 days × 3 age bands)
- ~550 prompts (avg 3 per activity)
- ~2,200 options (4 per prompt)
- 183 takeaways (1 per activity)
