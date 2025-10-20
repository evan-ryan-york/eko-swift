# Daily Practice Database Structure

## Overview

This document defines the complete database schema for the Daily Practice feature, including all tables, columns, indexes, constraints, and relationships.

---

## Tables

### 1. `daily_practice_activities`

**Purpose:** Stores the content library of daily practice activities

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| `day_number` | INTEGER | NOT NULL | Sequential day (1, 2, 3...) |
| `age_band` | TEXT | NOT NULL, CHECK IN ('6-9', '10-12', '13-16') | Target age range |
| `module_name` | TEXT | NOT NULL | Internal module identifier (e.g., 'state-recognition') |
| `module_display_name` | TEXT | NOT NULL | User-facing module name (e.g., 'The Conversation State Model') |
| `title` | TEXT | NOT NULL | Activity title |
| `description` | TEXT | NULLABLE | Optional description |
| `category` | TEXT | NULLABLE | Optional category for filtering |
| `skill_focus` | TEXT | NULLABLE | Primary skill being taught |
| `is_reflection` | BOOLEAN | DEFAULT false | Whether this is a reflection activity |
| `scenario` | TEXT | NOT NULL | The main scenario text |
| `prompts` | JSONB | NOT NULL, DEFAULT '[]'::jsonb | Array of prompt objects |
| `actionable_takeaway` | JSONB | NOT NULL | The tool/takeaway object |
| `best_approach` | TEXT | NULLABLE | Optional best practices summary |
| `follow_up_questions` | TEXT[] | DEFAULT ARRAY[]::TEXT[] | Optional follow-up questions |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Indexes:**

```sql
CREATE UNIQUE INDEX idx_day_age_band 
ON daily_practice_activities(day_number, age_band);

CREATE INDEX idx_day_number 
ON daily_practice_activities(day_number);

CREATE INDEX idx_module 
ON daily_practice_activities(module_name);

CREATE INDEX idx_age_band 
ON daily_practice_activities(age_band);
```

**Constraints:**

```sql
ALTER TABLE daily_practice_activities 
ADD CONSTRAINT check_age_band 
CHECK (age_band IN ('6-9', '10-12', '13-16'));

ALTER TABLE daily_practice_activities 
ADD CONSTRAINT check_day_number_positive 
CHECK (day_number > 0);
```

**Important Notes:**
- Unique index on `(day_number, age_band)` ensures only one activity per day per age group
- JSONB columns allow flexible content structure without schema changes
- `updated_at` automatically updates via trigger

---

### 2. `users` (Extensions to Existing Table)

**Purpose:** Track user progress through Daily Practice

**New Columns to Add:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `last_completed_daily_practice_activity` | INTEGER | DEFAULT 0 | Highest day number completed |
| `last_daily_practice_activity_completed_at` | TIMESTAMPTZ | NULLABLE | ISO timestamp of last completion |
| `total_score` | INTEGER | DEFAULT 0 | Cumulative points across all days |
| `daily_practice_scores` | JSONB | DEFAULT '{}'::jsonb | Map of day numbers to scores |

**Index:**

```sql
CREATE INDEX idx_users_last_completion 
ON users(last_daily_practice_activity_completed_at);
```

**Example `daily_practice_scores` Structure:**

```json
{
  "1": 25,
  "2": 30,
  "3": 28,
  "4": 21
}
```