# Eko Onboarding Flow

## Overview
The onboarding flow collects essential information about the parent user and their children to personalize the Eko experience. This flow is designed to be completed after authentication and before accessing the main application features.

## Onboarding States
The onboarding process progresses through the following states:

1. `NOT_STARTED` - Initial state before onboarding begins
2. `USER_INFO` - Collecting parent information
3. `CHILD_INFO` - Collecting child information
4. `GOALS` - Setting conversation goals for the child
5. `TOPICS` - Selecting conversation topics of interest
6. `DISPOSITIONS` - Defining the child's behavioral dispositions
7. `REVIEW` - Reviewing entered information and option to add more children
8. `COMPLETE` - Onboarding finished, user can access the app

## Step-by-Step Flow

### Step 1: User Information
**State:** `USER_INFO`

**Purpose:** Collect basic information about the parent user.

**UI Elements:**
- Title: "Welcome!"
- Subtitle: "Let's get to know each other"
- Input field: "What's your name?"
- Next button (disabled until name is entered)

**Data Collected:**
- `displayName` (string, required)

**Validation:**
- Name cannot be empty or whitespace only

**Next State:** `CHILD_INFO`

---

### Step 2: Child Information
**State:** `CHILD_INFO`

**Purpose:** Collect basic information about the parent's child.

**UI Elements:**
- Title: "Child Information"
- Subtitle: "Tell us about your child"
- Input field: "Child's Name"
- Date picker: "Child's Birthday"
- Next button (disabled until name is entered)

**Data Collected:**
- `name` (string, required)
- `birthday` (ISO date string, required)

**Validation:**
- Name cannot be empty or whitespace only
- Birthday cannot be in the future
- Birthday should be selected from a date picker

**Notes:**
- If editing an existing child (during "Add Another Child" flow), pre-populate fields
- Maximum date for birthday picker is today's date

**Next State:** `GOALS`

---

### Step 3: Conversation Goals
**State:** `GOALS`

**Purpose:** Help parents define what they want to achieve in conversations with their child.

**UI Elements:**
- Title: "Conversation Goals"
- Subtitle: "What are your goals for conversations with [Child's Name]? Select up to 3."
- Scrollable list of selectable goal cards
- "Other" option with custom text input
- Helper text showing selection count
- Next button (disabled until at least 1 goal is selected)

**Available Goals:**
- "Understanding their thoughts and feelings better"
- "Helping them navigate challenges"
- "Connecting with them on a deeper level"
- "Encouraging them to open up more"
- "Teaching them life skills or values"
- "Supporting their mental and emotional well-being"
- "Other" (allows custom text input)

**Data Collected:**
- `goals` (array of strings, 1-3 items required)

**Validation:**
- Must select at least 1 goal
- Cannot select more than 3 goals
- If "Other" is selected, custom text cannot be empty

**UI Behavior:**
- Goals are displayed as selectable cards
- Selected goals are visually highlighted (e.g., blue background)
- When "Other" is tapped, show a text input field
- Display count of selected goals as helper text

**Next State:** `TOPICS`

---

### Step 4: Conversation Topics
**State:** `TOPICS`

**Purpose:** Identify which conversation topics the parent wants to focus on with their child.

**UI Elements:**
- Title: "Conversation Topics"
- Subtitle: "Select at least 3 topics you'd like to focus on with [Child's Name]"
- 2-column grid of topic cards
- Helper text showing selection count
- Next button (disabled until at least 3 topics are selected)

**Available Topics:**
| Topic ID | Display Name |
|----------|-------------|
| `emotions` | Emotions & Feelings |
| `friends` | Friendship & Relationships |
| `school` | School & Learning |
| `family` | Family Dynamics |
| `conflict` | Conflict Resolution |
| `values` | Values & Ethics |
| `confidence` | Self-Confidence |
| `health` | Health & Wellness |
| `diversity` | Diversity & Inclusion |
| `future` | Future & Goals |
| `technology` | Technology & Screen Time |
| `creativity` | Creativity & Imagination |

**Data Collected:**
- `topics` (array of topic IDs, minimum 3 required)

**Validation:**
- Must select at least 3 topics
- No maximum limit on topic selection

**UI Behavior:**
- Topics displayed in a 2-column grid layout
- Selected topics are visually highlighted (e.g., blue background with white text)
- Helper text dynamically updates: "Select X more topics" or "X topics selected"

**Next State:** `DISPOSITIONS`

---

### Step 5: Child's Disposition
**State:** `DISPOSITIONS`

**Purpose:** Understand the child's behavioral tendencies to personalize AI interactions.

**UI Elements:**
- Title: "Child's Disposition"
- Subtitle: "Help us understand [Child's Name]'s disposition"
- Paginated slider interface (one disposition per screen)
- Pagination dots showing progress (3 total)
- Back and Next/Finish navigation buttons

**Disposition Scales (1-10):**

1. **Communication Style**
   - Left label: "Quiet"
   - Right label: "Talkative"
   - Property: `talkative`

2. **Emotional Response**
   - Left label: "Argumentative"
   - Right label: "Sensitive"
   - Property: `sensitive`

3. **Responsibility**
   - Left label: "Denial of Responsibility"
   - Right label: "Accountable"
   - Property: `accountable`

**Data Collected:**
- `dispositions` (object)
  - `talkative` (integer 1-10, default: 5)
  - `sensitive` (integer 1-10, default: 5)
  - `accountable` (integer 1-10, default: 5)

**Validation:**
- Each disposition value must be between 1 and 10
- All three dispositions must be set

**UI Behavior:**
- Display one disposition at a time with horizontal slider
- Show current slider value prominently
- Back button is disabled on first slide
- Next button changes to "Finish" on last slide
- Pagination dots indicate which disposition (1 of 3, 2 of 3, 3 of 3)
- When "Finish" is tapped on last slide, save and proceed

**Next State:** `REVIEW`

---

### Step 6: Review & Summary
**State:** `REVIEW`

**Purpose:** Allow parents to review entered information and optionally add more children.

**UI Elements:**
- Title: "All Set!"
- Subtitle: "Hi [Parent Name], here's a summary of your children:"
- List of child cards showing:
  - Child's name
  - Birthday (formatted: "Month Day, Year")
  - Selected topics (bulleted list with readable names)
- "Add Another Child" button (secondary style)
- "Complete Setup" button (primary style)

**Data Displayed:**
For each child:
- Name
- Birthday (formatted for readability)
- Topics (converted from IDs to readable names)

**User Actions:**

1. **Add Another Child**
   - Returns to `CHILD_INFO` state with blank fields
   - Generates new temporary child ID
   - Follows same flow: CHILD_INFO → GOALS → TOPICS → DISPOSITIONS → REVIEW

2. **Complete Setup**
   - Marks onboarding as complete
   - Updates user's onboarding state to `COMPLETE`
   - Navigates to main application

**Notes:**
- Goals and dispositions are not displayed in review (only stored)
- Empty state message if no children added yet: "No children added yet"

**Next State:** `COMPLETE`

---

## Data Model

### User Object
```
{
  displayName: string,
  onboardingState: OnboardingState,
  currentChildId?: string  // Temporary field during onboarding
}
```

### Child Object
```
{
  id: string,
  name: string,
  birthday: string (ISO date),
  goals: string[],
  topics: string[],
  dispositions: {
    talkative: number (1-10),
    sensitive: number (1-10),
    accountable: number (1-10)
  }
}
```

## Flow Behaviors

### Linear Progression
The onboarding follows a strict linear progression through states. Users cannot skip steps or navigate freely between them.

### Multiple Children Support
- After completing the first child's setup, users reach the Review screen
- From Review, users can choose to "Add Another Child"
- Adding another child returns them to CHILD_INFO with a new child ID
- The flow repeats: CHILD_INFO → GOALS → TOPICS → DISPOSITIONS → REVIEW
- Review screen always shows all added children

### State Persistence
- The `onboardingState` is saved to the backend after each step
- If the app is closed and reopened during onboarding, user resumes at their last saved state
- The `currentChildId` tracks which child is being edited during the flow

### Error Handling
- If child data cannot be loaded, display error state with message
- If save operations fail, show alert and allow retry
- User cannot proceed if required fields are not filled

### Loading States
- Show loading indicator when:
  - Fetching existing child data
  - Saving data to backend
  - Transitioning between states

### Completion
Once onboarding is complete (`COMPLETE` state):
- User is redirected to the main application
- Cannot return to onboarding unless manually reset by system
- All child data is saved and available throughout the app

## Design Principles

### User-Friendly
- Clear, friendly language throughout
- Contextual help text (e.g., "Select 2 more topics")
- Visual feedback for selections
- Disabled states prevent invalid actions

### Efficient
- Minimal required fields
- Smart defaults (dispositions default to middle value: 5)
- Quick to complete (estimated 3-5 minutes)

### Flexible
- Support for multiple children
- Custom goal input ("Other" option)
- No maximum on topic selection (only minimum)

### Personalized
- All prompts reference child by name after Step 2
- Parent name used in Review screen greeting
- Data directly feeds into AI personalization

## Technical Considerations

### API Integration
Each step completion should:
1. Call backend API to save data
2. Update user's `onboardingState`
3. Handle success/error responses appropriately
4. Show loading states during API calls

### Data Validation
- Validate all input on the client before submission
- Handle server-side validation errors gracefully
- Prevent submission of invalid data

### Navigation
- Implement proper state management to handle flow
- Prevent back navigation to authentication screens during onboarding
- Clear any temporary data (`currentChildId`) when onboarding completes

### Accessibility
- All form fields should have proper labels
- Slider controls should have accessible values
- Buttons should have clear action names
- Support for screen readers where applicable
