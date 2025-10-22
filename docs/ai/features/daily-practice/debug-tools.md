# Daily Practice Debug Tools

## Overview

Developer tools for testing the Daily Practice feature in DEBUG builds only. These tools allow you to reset progress and test any specific day without having to wait or manually manipulate the database.

## Features

### 1. Debug Controls Access

A wrench icon (🔧) appears in the top-right corner of the Daily Practice home screen **only in DEBUG builds**. Tapping this icon opens the Debug Controls sheet.

### 2. Reset Progress

**Reset Current Day**
- Resets only the most recently completed day
- Decrements `last_completed_daily_practice_activity` by 1
- Removes the current day's score from the scores object
- Allows you to re-test the current day

**Reset All Progress**
- Completely resets all Daily Practice progress
- Sets `last_completed_daily_practice_activity` to 0
- Clears `last_daily_practice_activity_completed_at`
- Resets `total_score` to 0
- Clears all `daily_practice_scores`
- Deletes all `daily_practice_results` records
- Allows you to start from Day 1 again

### 3. Day Picker

- Wheel picker to select any day from 1-60
- "Load Day" button fetches the selected day's activity
- Bypasses the normal progression logic
- Allows testing any day regardless of completion status

## Implementation

### Edge Functions

**`reset-daily-practice`** (`supabase/functions/reset-daily-practice/index.ts`)
- POST endpoint that accepts `resetType: "current" | "all"`
- Modifies user_profiles table to reset progress
- Optionally deletes daily_practice_results records

**`get-activity-by-day`** (`supabase/functions/get-activity-by-day/index.ts`)
- POST endpoint that accepts `dayNumber: number`
- Fetches specific day's activity regardless of user progress
- Returns activity with debug_mode flag set to true

### Swift Service Layer

**`SupabaseService.swift`** (lines 997-1069)

```swift
#if DEBUG
func resetDailyPractice(resetAll: Bool = false) async throws
func getActivityByDay(_ dayNumber: Int) async throws -> GetDailyActivityResponse
#endif
```

Both methods are only compiled in DEBUG builds using `#if DEBUG` compiler directives.

### ViewModel

**`DailyPracticeHomeViewModel.swift`** (lines 84-137)

```swift
#if DEBUG
func resetCurrentDay() async
func resetAllProgress() async
func loadDay(_ dayNumber: Int) async
#endif
```

### UI

**`DailyPracticeHomeView.swift`** (lines 11-14, 53-67, 200-268)

Debug controls include:
- Toolbar button (wrench icon) - only visible in DEBUG
- Sheet with Form containing:
  - Current progress display
  - Reset buttons
  - Day picker
  - Disclaimer text

## Usage

### Testing a Specific Day

1. Open Daily Practice home screen
2. Tap the wrench icon (🔧) in top-right
3. Scroll to "Load Specific Day" section
4. Use the wheel to select a day (e.g., Day 5)
5. Tap "Load Day 5"
6. The activity for that day will load and you can complete it

### Resetting to Re-test

1. Complete a daily practice activity
2. Return to home screen (shows "completed today")
3. Tap the wrench icon (🔧)
4. Tap "Reset Current Day"
5. Home screen now shows the activity again as available

### Starting Over

1. Tap the wrench icon (🔧)
2. Tap "Reset All Progress" (destructive action)
3. Confirms and returns to Day 1

## Production Safety

All debug tools are wrapped in `#if DEBUG` compiler directives:
- Code is completely removed in Release builds
- No UI elements appear in production
- No API endpoints are exposed (though they exist, they can't be called from production builds)
- Zero performance impact on production

## Testing Checklist

- [ ] Verify wrench icon only appears in DEBUG builds
- [ ] Test "Reset Current Day" functionality
- [ ] Test "Reset All Progress" functionality
- [ ] Test loading specific days (1, 5, 10, 30, 60)
- [ ] Verify day picker shows days 1-60
- [ ] Confirm no debug controls in Release build
- [ ] Test that completing a loaded day updates progress correctly

## Future Enhancements

Potential additions for v2:
- View all available days with their titles
- Quick jump to specific modules
- Mock different age bands
- Simulate completing multiple days at once
- Export/import progress for testing scenarios
- Analytics viewer showing prompt-level data

## Related Files

**Edge Functions:**
- `supabase/functions/reset-daily-practice/index.ts`
- `supabase/functions/get-activity-by-day/index.ts`

**Swift:**
- `Eko/Core/Services/SupabaseService.swift` (lines 997-1069)
- `Eko/Features/DailyPractice/ViewModels/DailyPracticeHomeViewModel.swift` (lines 84-137)
- `Eko/Features/DailyPractice/Views/DailyPracticeHomeView.swift` (debug sections)

## Notes

- Edge Functions need to be deployed to Supabase for this to work
- Database must have activities seeded for the days you want to test
- Reset operations are immediate and cannot be undone
- Loading a day doesn't mark it as completed until you actually complete it
