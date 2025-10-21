# Build Workflow Sub-Agent System: Complete Blueprint

**Version**: 1.0.0  
**Date**: 2025-01-15  
**Purpose**: Blueprint for implementing autonomous build workflows using Claude Code sub-agents with test-driven development (TDD) and continuous validation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Core Design Principles](#core-design-principles)
4. [Architecture Overview](#architecture-overview)
5. [File Structure](#file-structure)
6. [Detailed File Specifications](#detailed-file-specifications)
7. [Critical Design Decisions](#critical-design-decisions)
8. [How The Workflow Executes](#how-the-workflow-executes)
9. [Adaptation Guide](#adaptation-guide)
10. [Troubleshooting](#troubleshooting)

---

## Executive Summary

This blueprint describes a **phase-level, TDD-driven autonomous build workflow** for Claude Code that:

- Takes unstructured plans from chat LLMs and converts them into working code
- Uses 4 specialized sub-agents (context-gatherer, planner, executor, checker)
- Implements test-driven development (TDD) with tests written before code
- Validates continuously via hooks (TypeScript + tests after every file edit)
- Reviews architecture per phase (not per step, not all-at-once)
- Prevents compounding errors while maintaining execution efficiency

**Key Innovation**: Phase-level execution with continuous technical validation (hooks) + periodic architectural review (checker) prevents both "test gaming" and "losing the big picture."

---

## Problem Statement

### The Challenge

**80% of development work is unpredictable, one-shot tasks** that don't justify complex workflow setup. But **20% follows predictable patterns** that benefit from autonomous execution.

For that 20%, developers want:
1. **Paste a plan from ChatGPT/Claude** (unstructured notes from ideation)
2. **Hit a button** (`/new-build`)
3. **Get working, tested code** (with minimal intervention)

### The Problems This Solves

**Without this workflow:**
- ❌ Manual context gathering every time (tech stack, architecture, conventions)
- ❌ Converting vague plans to actionable steps (mental overhead)
- ❌ Remembering to write tests first (TDD discipline hard to maintain)
- ❌ Tests that "game" validation (tests that just match existing code)
- ❌ Compounding errors (TypeScript breaks cascade, architecture drift)
- ❌ Losing the big picture (implementing steps in isolation)

**With this workflow:**
- ✅ Automatic context gathering (one-time setup, reused forever)
- ✅ Structured phased plans with test specifications
- ✅ Enforced TDD (tests before implementation, every time)
- ✅ Continuous validation (hooks catch errors immediately)
- ✅ Architectural review (checker ensures coherence per phase)
- ✅ Big picture maintained (executor sees full plan + context)

---

## Core Design Principles

### 1. Phase-Level Execution (Not Step, Not All-At-Once)

**Why Phase-Level?**
- **Too granular (step-level)**: Constant context switching between agents, inefficient
- **Too coarse (all-phases-at-once)**: Errors compound, hard to debug, architecture drifts
- **Just right (phase-level)**: Balance between catching errors early and execution efficiency

**A phase typically has 3-8 steps, taking 1-3 hours to implement.**

### 2. Test-Driven Development (TDD) Enforced

**Why TDD?**
- Tests written BEFORE implementation provide concrete goals for AI
- Prevents "test gaming" (writing tests that just match existing code)
- Catches logic errors early via hooks
- Provides living documentation of expected behavior

**How Enforced?**
- Planner specifies test files and what to test for each step
- Executor instructions mandate tests-first workflow
- Hooks run tests after every file edit (immediate feedback)

### 3. Continuous Technical Validation (Hooks)

**Why Hooks?**
- Catches TypeScript errors after EVERY file edit (prevents compounding)
- Runs tests immediately after code changes (catches logic errors fast)
- Executor sees feedback in real-time, fixes issues before moving on
- Prevents technical debt from accumulating

**What Hooks Check:**
- TypeScript compilation (`tsc --noEmit`)
- Test execution (`npm test -- --findRelatedTests`)
- NOT: Architecture, patterns, design (checker does that)

### 4. Periodic Architectural Review (Checker)

**Why Checker After Each Phase?**
- Hooks catch technical issues (types, tests)
- Checker catches design issues (architecture, patterns, integration)
- Separation of concerns: technical vs. architectural validation
- Phase-level review is frequent enough to prevent drift

**What Checker Reviews:**
- Architecture compliance (layering, separation of concerns)
- Golden path adherence (naming, patterns, conventions)
- Integration quality (do steps work together well?)
- Code organization (duplication, structure, maintainability)

### 5. Big Picture Context Always Available

**Why Full Context?**
- Executor gets full implementation plan (not just current step)
- Executor gets project context (architecture, golden paths)
- Prevents narrow, isolated implementations
- Enables intelligent decisions about integration

### 6. Orchestrator = Claude Code Main Thread

**Why Not a Sub-Agent Orchestrator?**
- User's practical experience: main thread orchestration works better
- No orchestrator latency or context overhead
- Natural conversation flow with user
- Flexible control and error handling

---

## Architecture Overview

### The 4-Agent Pipeline
```
User → /new-build → Orchestrator (Claude Code Main Thread)
                           ↓
                    ┌──────────────────┐
                    │ 1. Context       │
                    │    Gatherer      │ → project-context.md
                    │    (Sonnet)      │
                    └────────┬─────────┘
                             ↓ [validation hook]
                    ┌──────────────────┐
                    │ 2. Build         │
                    │    Planner       │ → implementation-plan.md
                    │    (Opus)        │ → status-update.md
                    └────────┬─────────┘
                             ↓ [validation hook]
                    ┌────────────────────────────┐
                    │ PHASE LOOP (per phase)     │
                    │                            │
                    │  ┌──────────────────┐     │
                    │  │ 3. Build         │     │
                    │  │    Executor      │     │
                    │  │    (Sonnet)      │     │
                    │  │    • Implements  │     │
                    │  │      all steps   │     │
                    │  │    • TDD cycle   │     │
                    │  │    • Sees hooks  │     │
                    │  └────────┬─────────┘     │
                    │           ↓ [hooks: TypeScript + Tests continuously]
                    │  ┌──────────────────┐     │
                    │  │ 4. Build         │     │
                    │  │    Checker       │     │
                    │  │    (Sonnet)      │     │
                    │  │    • Reviews     │     │
                    │  │      architecture│     │
                    │  │    • Checks      │     │
                    │  │      patterns    │     │
                    │  └────────┬─────────┘     │
                    │           ↓                │
                    │  [check-phase-completion]  │
                    │     PASS? → Next Phase     │
                    │     FAIL? → Executor fixes │
                    └────────────────────────────┘
                             ↓
                    All Phases Complete ✅
```

### Data Flow
```
Inputs:
  unstructured-plan.md    (user's rough plan from chat LLM)
  CLAUDE.md               (project essentials)
  docs/ai/architecture/*  (architecture standards)
  docs/ai/golden-paths/*  (coding patterns)

Processing:
  project-context.md      (context-gatherer output)
  implementation-plan.md  (planner output)
  status-update.md        (progress tracking)
  verification-phase-N.md (checker outputs)

Outputs:
  Source files            (executor creates/modifies)
  Test files              (executor creates with TDD)
  Updated documentation   (if specified in plan)
```

---

## File Structure

### Required Directory Structure
```
project/
├── CLAUDE.md                              # Minimal project essentials
│
├── .claude/
│   ├── agents/
│   │   ├── build-context-gatherer.md     # Step 1: Gather context
│   │   ├── build-planner.md              # Step 2: Create plan
│   │   ├── build-executor.md             # Step 3: Implement phases
│   │   └── build-checker.md              # Step 4: Review quality
│   │
│   ├── commands/
│   │   └── new-build.md                  # Slash command entry point
│   │
│   ├── hooks/
│   │   ├── build-context-verification.py # Validates context output
│   │   ├── build-plan-verification.py    # Validates plan output
│   │   └── check-phase-completion.py     # Controls phase loop
│   │
│   └── settings.json                     # Hook configuration
│
└── docs/
    └── ai/
        ├── workflows/
        │   ├── build-orchestrator.md     # Orchestration instructions
        │   └── build-dag.json            # Workflow definition (DAG)
        │
        ├── features/
        │   └── {feature-id}/
        │       ├── unstructured-plan.md      # User input
        │       ├── project-context.md        # Context-gatherer output
        │       ├── implementation-plan.md    # Planner output
        │       ├── status-update.md          # Progress tracking
        │       └── verification-phase-N.md   # Checker outputs
        │
        ├── architecture/                 # YOUR architecture docs
        │   └── layered-architecture.md   # (example)
        │
        └── golden-paths/                 # YOUR coding standards
            └── api-conventions.md        # (example)
```

---

## Detailed File Specifications

### 1. `/new-build` Slash Command

**File**: `.claude/commands/new-build.md`

**Purpose**: Entry point for the workflow. User types `/new-build feature-name`.

**Contents**:
```markdown
---
Read docs/ai/workflows/build-orchestrator.md and follow the instructions there to execute the build workflow.
---
```

**Why So Simple?**
- All logic lives in orchestrator.md (easier to update)
- Slash command just points to the orchestration instructions
- Follows Claude Code best practice: commands delegate to detailed instructions

---

### 2. Build Orchestrator

**File**: `docs/ai/workflows/build-orchestrator.md`

**Purpose**: Instructions for Claude Code main thread on how to orchestrate the 4-agent workflow.

**Key Sections**:
- Step 1: Initialize (get feature ID, create directories, get plan)
- Step 2: Gather Context (delegate to context-gatherer, validate)
- Step 3: Create Plan (delegate to planner, validate)
- Step 4: Phase Loop (delegate to executor → checker, repeat until done)
- Step 5: Complete (report success to user)

**Critical Details**:
- **Phase-level loop logic**: Clearly explains how phase loop works
- **Hook trust**: Explains that hooks validate technical issues
- **Checker focus**: Explains checker reviews architecture, not tests
- **Error handling**: What to do when validation fails, executor blocks, checker fails

**Why It Lives Here**:
- Not in CLAUDE.md (too large, only used for builds)
- Not in agent definition (orchestrator is not an agent)
- In docs/ai/ (version controlled, shareable across team)

---

### 3. Build DAG (Workflow Definition)

**File**: `docs/ai/workflows/build-dag.json`

**Purpose**: Formal definition of the workflow structure, dependencies, inputs, outputs, validation gates.

**Structure**:
```json
{
  "name": "build-flow",
  "nodes": {
    "context-gatherer": { /* agent config */ },
    "build-planner": { /* agent config */ },
    "build-executor": { /* agent config, TDD workflow */ },
    "build-checker": { /* agent config, validation focus */ }
  },
  "workflow": {
    "execution_order": [
      "context-gatherer",
      "build-planner",
      { "loop": { "nodes": ["build-executor", "build-checker"], /* ... */ } }
    ]
  },
  "validation_gates": [ /* hooks configuration */ ]
}
```

**Key Sections**:
- **nodes**: Each agent's configuration, inputs, outputs, success criteria
- **workflow.execution_order**: Sequential execution with phase loop
- **continuous_validation**: Hook definitions for executor
- **validation_gates**: When hooks run and what they check

**Why JSON?**
- Machine-readable workflow definition
- Clear documentation of dependencies
- Easier to visualize in tools
- Separates structure from execution instructions

---

### 4. Build Context Gatherer Agent

**File**: `.claude/agents/build-context-gatherer.md`

**Purpose**: Gathers project-specific context (tech stack, architecture, conventions) into structured format.

**Agent Config**:
```yaml
name: build-context-gatherer
tools: Read, Grep, Glob, Bash, Write
model: sonnet
```

**Process**:
1. Read unstructured plan (understand what's being built)
2. Read CLAUDE.md, package.json, README.md (tech stack)
3. Read docs/ai/architecture/* (architecture patterns)
4. Read docs/ai/golden-paths/* (coding standards)
5. Write structured context with 4 required sections:
   - Tech Stack
   - Architecture
   - Conventions
   - Key Files

**Output**: `docs/ai/features/{feature-id}/project-context.md`

**Why This Agent**:
- Context gathering is repetitive but critical
- One-time setup (architecture docs), infinite reuse
- Provides executor with big picture context
- Validation ensures quality before planning begins

---

### 5. Build Context Verification Hook

**File**: `.claude/hooks/build-context-verification.py`

**Purpose**: Validates that project-context.md has required sections before workflow continues.

**Checks**:
- File exists
- Has 4 required sections (Tech Stack, Architecture, Conventions, Key Files)
- Sections have content (not just headers)
- Auto-fixes: Adds missing section templates

**Exit Codes**:
- 0 = Pass (workflow continues)
- 1 = Fail (blocks workflow, shows error message)

**Why Python Script**:
- Validation is objective, rule-based (perfect for script)
- Runs automatically after agent completes (SubagentStop hook)
- Fails fast if output is incomplete
- Provides clear error messages for fixes

---

### 6. Build Planner Agent

**File**: `.claude/agents/build-planner.md`

**Purpose**: Converts unstructured plan into phased implementation plan with test specifications.

**Agent Config**:
```yaml
name: build-planner
tools: Read, Write
model: opus  # Strategic thinking needed
```

**Process**:
1. Read project-context.md (understand project)
2. Read unstructured-plan.md (understand feature)
3. Analyze and strategize (dependencies, phases, risks)
4. Break into 2-5 phases (logical groupings)
5. Break phases into steps with test specifications
6. Write two files:
   - implementation-plan.md (the plan)
   - status-update.md (progress tracking)

**Key Innovation: Test Specifications**

Each step includes test guidance:
```markdown
- Step 2.1: Create User model (tests: models/user.test.ts - test validation, required fields, edge cases)
```

**Why Opus Model**:
- Planning requires strategic thinking
- Quality of plan determines quality of execution
- Worth the extra cost for better planning

**Why Test Specifications**:
- Guides executor on what to test before implementing
- Prevents vague testing ("write some tests")
- Enables true TDD (clear test goals before coding)

---

### 7. Build Plan Verification Hook

**File**: `.claude/hooks/build-plan-verification.py`

**Purpose**: Validates implementation plan has proper structure and test specifications.

**Checks**:
- At least one phase exists
- Each phase has steps
- Has overview section
- Step count reasonable (10-30 typical, max 50)
- Step numbering sequential
- Test specifications present for logic steps (50%+ coverage)

**Exit Codes**:
- 0 = Pass (workflow continues)
- 1 = Fail (blocks workflow, shows error with helpful message)

**Why Check Test Specifications**:
- Ensures planner actually specified tests
- Low test coverage triggers warning
- Prevents executor from guessing what to test

---

### 8. Build Executor Agent

**File**: `.claude/agents/build-executor.md`

**Purpose**: Implements ENTIRE PHASES using test-driven development (TDD).

**Agent Config**:
```yaml
name: build-executor
tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
model: sonnet  # Execution specialist
```

**Process Per Phase**:
1. Read full implementation plan (big picture)
2. Read project-context.md (architecture, golden paths)
3. Read status-update.md (current state)
4. For each step in assigned phase:
   - **RED**: Write failing test(s) first
   - **GREEN**: Write minimal implementation to pass
   - **REFACTOR**: Improve while keeping tests passing
   - See hook output (TypeScript + tests run automatically)
   - Fix any hook errors immediately
   - Update status-update.md with timestamp
5. Report phase complete

**Critical Instructions**:
- **Big picture awareness**: Read full plan, not just current phase
- **TDD discipline**: Tests BEFORE implementation, always
- **Hook feedback**: Fix errors immediately when hooks report issues
- **Golden path compliance**: Follow project patterns from context
- **Blocker reporting**: Stop and report if unclear/blocked

**Why Sonnet Model**:
- Execution is tactical, not strategic
- Sonnet is fast and excellent at implementation
- Cost-effective for potentially many iterations

**Why Full Context**:
- Prevents narrow, isolated implementations
- Executor understands how phase fits in bigger picture
- Enables intelligent integration decisions

---

### 9. PostToolUse Hooks (Continuous Validation)

**File**: `.claude/settings.json`

**Purpose**: Run TypeScript compilation and tests after EVERY file edit during execution.

**Configuration**:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npx tsc --noEmit --pretty false 2>&1 | head -20 || echo '⚠️ TypeScript errors'",
            "description": "TypeScript validation after every file edit"
          },
          {
            "type": "command",
            "command": "npm test -- --findRelatedTests $CLAUDE_FILE_PATHS --passWithNoTests 2>&1 | tail -10 || echo '⚠️ Tests failed'",
            "description": "Test execution for changed files"
          }
        ]
      }
    ]
  }
}
```

**What Hooks Check**:
- **TypeScript**: `tsc --noEmit` (type checking without compilation)
- **Tests**: `npm test` for changed files only (fast, targeted)

**Why After Every Edit**:
- Catches errors immediately (prevents compounding)
- Executor sees feedback in real-time
- Forces TDD discipline (tests fail → implement → tests pass)

**Performance Considerations**:
- Only checks changed files (`--findRelatedTests`)
- Truncates output (`head -20`, `tail -10`) for readability
- Fast enough to not slow down execution

**THE MAGIC**: This is what prevents "test gaming" and compounding errors. Executor can't move forward with broken code.

---

### 10. Build Checker Agent

**File**: `.claude/agents/build-checker.md`

**Purpose**: Reviews completed phases for architectural quality and golden path compliance.

**Agent Config**:
```yaml
name: build-checker
tools: Read, Bash, Grep, Glob  # Read-only by design
model: sonnet  # Good architectural judgment
```

**Process Per Phase**:
1. Read implementation-plan.md (what should exist)
2. Read status-update.md (what executor claims)
3. Read actual code files (what was actually built)
4. Read architecture docs (standards to check against)
5. Read golden path docs (patterns to check against)
6. Check architectural compliance:
   - Layered architecture respected
   - Separation of concerns maintained
   - Dependency directions correct
   - Integration quality good
7. Check golden path adherence:
   - Naming conventions
   - File structure
   - Error handling patterns
   - API patterns
   - Testing patterns
8. Check code organization:
   - File sizes reasonable
   - No duplication
   - Imports organized
   - Adequate documentation
9. Write verification report (PASS/FAIL + specific feedback)

**Critical Instructions**:
- **Do NOT check**: TypeScript errors, test failures, syntax (hooks did that)
- **Do check**: Architecture, patterns, design, integration
- **Be specific**: File, line number, exact issue, how to fix
- **Reference docs**: Link to architecture/golden path standards
- **Be constructive**: Help executor improve, don't just criticize

**Output**: `docs/ai/features/{feature-id}/verification-phase-{N}.md`

**Why Read-Only Tools**:
- Checker only reviews, never modifies
- Prevents checker from "fixing" issues (that's executor's job)
- Clear separation of responsibilities

**Why Not Check Tests/TypeScript**:
- Hooks already validated during execution
- Eliminates duplication of validation
- Lets checker focus on higher-level concerns

---

### 11. Phase Completion Check Script

**File**: `.claude/hooks/check-phase-completion.py`

**Purpose**: Reads verification report and returns exit code to control phase loop.

**Logic**:
1. Read current phase number from status-update.md
2. Check if verification report exists for that phase
3. Read verification report
4. Parse status (PASS or FAIL)
5. Return exit code:
   - **Exit 0 + more phases**: Phase passed, continue to next phase
   - **Exit 0 + all done**: All phases complete, workflow done
   - **Exit 1**: Phase failed, executor must fix

**Exit Code Usage**:
- Orchestrator uses exit code to decide next action
- Exit 0 → continue forward
- Exit 1 → loop back to executor with checker feedback

**Why Script Instead of Agent**:
- Decision is mechanical (read status, return code)
- No AI reasoning needed
- Fast, deterministic
- Clear contract with orchestrator

---

### 12. Settings Configuration

**File**: `.claude/settings.json`

**Purpose**: Configure permissions and hook behavior for the workflow.

**Key Sections**:

**Permissions**:
```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(git:*)",
      "Bash(python3:*)"
    ]
  }
}
```

**Hooks**:
```json
{
  "hooks": {
    "PostToolUse": [ /* TypeScript + Test hooks */ ],
    "SubagentStop": [
      { "matcher": "build-context-gatherer", /* validation */ },
      { "matcher": "build-planner", /* validation */ }
    ]
  }
}
```

**Why Configure Here**:
- Central configuration for all hooks
- Easy to enable/disable validation
- Clear permissions model
- Version controlled with project

---

### 13. Project Documentation (You Create These)

**Architecture Docs**: `docs/ai/architecture/*.md`

**Purpose**: Define your project's architecture standards.

**Examples**:
- `layered-architecture.md` - Layer boundaries, dependencies
- `data-flow.md` - How data moves through system
- `authentication.md` - Auth/authz patterns
- `error-handling.md` - Error handling strategy

**Golden Path Docs**: `docs/ai/golden-paths/*.md`

**Purpose**: Define your project's coding standards and patterns.

**Examples**:
- `api-conventions.md` - REST API patterns, validation, responses
- `naming-conventions.md` - Variables, functions, files, classes
- `testing-conventions.md` - Test structure, mocking, coverage
- `file-organization.md` - Directory structure, imports

**Why These Matter**:
- Context-gatherer reads these to build project context
- Executor follows these patterns during implementation
- Checker validates against these standards
- One-time investment, infinite reuse

**Investment**: 1-2 hours to document your patterns pays off forever.

---

## Critical Design Decisions

### Decision 1: Phase-Level Loop Granularity

**Options Considered**:
- Step-level (executor does 1 step, checker reviews, repeat)
- Phase-level (executor does 3-8 steps, checker reviews, repeat)
- All-at-once (executor does all phases, checker reviews once)

**Decision**: Phase-level

**Rationale**:
- Step-level: Too much context switching, inefficient
- All-at-once: Errors compound, hard to debug
- Phase-level: Sweet spot for early error detection + efficiency

**Research Backing**: Continuous validation via hooks + periodic architectural review matches best practices from research on AI agent reliability.

---

### Decision 2: TDD Enforcement via Test Specifications

**Options Considered**:
- Let executor decide when to write tests
- Require tests but don't specify what
- Specify test files and what to test in plan

**Decision**: Planner specifies test files and what to test

**Rationale**:
- Provides concrete goals for executor
- Prevents vague testing
- Enables true TDD (write tests first with clear purpose)
- Research shows AI agents perform better with concrete targets

**Risk Mitigated**: Prevents "test gaming" (writing tests that just match existing code)

---

### Decision 3: Continuous Validation via Hooks

**Options Considered**:
- No hooks, executor runs tests manually
- Hooks after every file edit
- Hooks after each step completion

**Decision**: Hooks after every file edit

**Rationale**:
- Immediate feedback prevents compounding errors
- Executor can't move forward with broken code
- TypeScript errors caught instantly
- Test failures caught instantly

**Trade-off**: Some noise if executor writes multiple files for a step, but benefit outweighs cost.

---

### Decision 4: Checker Focus (Architecture, Not Tests)

**Options Considered**:
- Checker validates everything (TypeScript, tests, architecture)
- Checker only validates architecture/patterns
- No checker, hooks validate everything

**Decision**: Checker validates architecture/patterns only

**Rationale**:
- Hooks already validate technical correctness
- Checker adds value by reviewing design/patterns
- Separation of concerns: technical vs. architectural
- Prevents duplication of validation

**Key Insight**: "Don't check TypeScript or test pass/fail - hooks already did that"

---

### Decision 5: Orchestrator = Main Thread

**Options Considered**:
- Separate orchestrator sub-agent
- Claude Code main thread orchestrates
- Fully autonomous system with no orchestration

**Decision**: Claude Code main thread orchestrates

**Rationale**:
- User's practical experience: main thread works better
- No orchestrator latency
- Natural conversation flow
- Flexible error handling
- Official Anthropic pattern

---

### Decision 6: Opus for Planning, Sonnet for Execution

**Options Considered**:
- All agents use same model
- Different models based on task complexity
- Always use most powerful model

**Decision**: Opus for planner, Sonnet for others

**Rationale**:
- Planning requires strategic thinking (Opus strength)
- Execution is tactical (Sonnet is fast and excellent)
- Context gathering is straightforward (Sonnet sufficient)
- Checking requires good judgment (Sonnet sufficient)
- Cost-effective: Only pay for Opus where it matters

---

### Decision 7: Feature Isolation (Separate Directories)

**Options Considered**:
- All features share same directory
- Each feature gets own directory
- Single flat file structure

**Decision**: Each feature gets `docs/ai/features/{feature-id}/` directory

**Rationale**:
- Clean separation
- Easy to find artifacts
- Supports parallel work (multiple features)
- No cross-contamination
- Easy to clean up (delete directory)

---

## How The Workflow Executes

### End-to-End Flow

**1. User Starts Workflow**
```bash
# User in terminal
> /new-build user-dashboard

# Or
> /new-build
# "What feature are we building? This will be the feature ID"
```

**2. Orchestrator Initializes**

- Creates `docs/ai/features/user-dashboard/` directory
- Asks for unstructured plan if not exists
- Saves to `unstructured-plan.md`

**3. Context Gathering**
```
Orchestrator → build-context-gatherer:
  "Gather context for user-dashboard"
  
Context-gatherer:
  1. Reads unstructured-plan.md (understand feature)
  2. Reads CLAUDE.md, package.json (tech stack)
  3. Reads docs/ai/architecture/* (architecture)
  4. Reads docs/ai/golden-paths/* (patterns)
  5. Writes project-context.md with 4 sections
  
build-context-verification.py runs:
  ✓ File exists
  ✓ Has Tech Stack, Architecture, Conventions, Key Files
  ✓ Sections have content
  Exit 0 → Continue
```

**4. Planning**
```
Orchestrator → build-planner:
  "Create implementation plan for user-dashboard"
  
Build-planner:
  1. Reads project-context.md (project info)
  2. Reads unstructured-plan.md (feature requirements)
  3. Analyzes dependencies, risks, phases
  4. Creates 4 phases with 18 total steps
  5. Adds test specifications to each logic step
  6. Writes implementation-plan.md
  7. Writes status-update.md (all steps unchecked)
  
build-plan-verification.py runs:
  ✓ Has phases
  ✓ Phases have steps
  ✓ Has overview
  ✓ Step count reasonable (18)
  ✓ Test specs present (14/18 steps)
  Exit 0 → Continue
```

**5. Phase 1 Execution**
```
Orchestrator identifies Phase 1 from status-update.md

Orchestrator → build-executor:
  "Implement Phase 1: Foundation & Data Layer (steps 1.1-1.5)"
  
Build-executor:
  Step 1.1: Create dashboard routes
    - No test needed (just route files)
    - Creates app/dashboard/page.tsx
    - Hook runs: TypeScript ✓
    - Updates status: [x] Step 1.1
    
  Step 1.2: API endpoint for metrics
    - Reads test spec: "test auth, response format, error cases"
    - Writes api/dashboard/metrics.test.ts (RED - tests fail)
    - Hook runs: Tests fail ✓ (expected)
    - Writes api/dashboard/metrics/route.ts (GREEN - tests pass)
    - Hook runs: TypeScript ✓, Tests ✓
    - Updates status: [x] Step 1.2
    
  [Steps 1.3, 1.4, 1.5 continue similarly...]
  
  All Phase 1 steps complete
  Executor reports: "Phase 1 complete"
```

**6. Phase 1 Review**
```
Orchestrator → build-checker:
  "Review Phase 1: Foundation & Data Layer"
  
Build-checker:
  1. Reads implementation-plan.md (what should exist)
  2. Reads status-update.md (what was built)
  3. Runs: git diff --name-only HEAD~5 HEAD
  4. Reads changed files
  5. Reads docs/ai/architecture/layered-architecture.md
  6. Reads docs/ai/golden-paths/api-conventions.md
  7. Checks:
     ✓ Architecture: Layers respected
     ✓ Golden paths: API patterns followed
     ✓ Organization: Files in correct locations
     ✓ Integration: Steps work together well
  8. Writes verification-phase-1.md:
     Status: PASS ✅
     Observations: Clean implementation, good TDD
```

**7. Phase Completion Check**
```
Orchestrator runs:
  python .claude/hooks/check-phase-completion.py user-dashboard
  
check-phase-completion.py:
  1. Reads status-update.md
  2. Finds Phase 1 all steps checked
  3. Reads verification-phase-1.md
  4. Sees: Status: PASS
  5. Checks: More phases? Yes (Phases 2-4 remain)
  6. Exit 0 → Continue to Phase 2
```

**8. Phases 2-4 Execute**

(Same loop: executor → checker → check script → next phase)

**9. All Phases Complete**
```
check-phase-completion.py:
  1. Reads status-update.md
  2. All phases checked
  3. Reads verification-phase-4.md
  4. Sees: Status: PASS
  5. Checks: More phases? No (all done)
  6. Exit 0 + "All phases complete"
  
Orchestrator:
  "Build workflow complete! 🎉"
  
  Summary:
  - Feature: user-dashboard
  - Phases: 4
  - Steps: 18
  - Files changed: 23
  - Tests added: 41
  - All verified ✅
  
  Next: Manual QA, create PR, deploy
```

### Error Handling Examples

**Example 1: Context Validation Fails**
```
build-context-verification.py:
  ✗ Missing section: Conventions
  Exit 1
  
Orchestrator sees failure:
  "Context validation failed: Missing Conventions section"
  
Orchestrator → build-context-gatherer:
  "Please regenerate context and include Conventions section"
  
[Retry up to 3 times, then escalate to user]
```

**Example 2: Hook Catches TypeScript Error**
```
Build-executor writes: services/auth.ts

PostToolUse hook runs:
  npx tsc --noEmit
  
  ⚠️ TypeScript errors detected:
  services/auth.ts(42,15): error TS2322: 
    Type 'string' is not assignable to type 'number'
  
Executor sees error in next message:
  "I see a TypeScript error. Let me fix that."
  
Executor edits: services/auth.ts (fixes type)

Hook runs again:
  npx tsc --noEmit
  ✓ No errors
  
Executor continues to next step
```

**Example 3: Checker Finds Architecture Violation**
```
Build-checker reviews Phase 2:
  Finds: services/user.ts imports from components/UserCard
  
  This violates layered architecture!
  
Writes verification-phase-2.md:
  Status: FAIL
  Issue: Service imports UI component (critical)
  Fix: Remove UI import, pass data not components
  
check-phase-completion.py:
  Reads: Status: FAIL
  Exit 1
  
Orchestrator:
  "Phase 2 failed verification"
  
Orchestrator → build-executor:
  "Fix Phase 2 based on verification-phase-2.md"
  
Executor:
  1. Reads verification report
  2. Removes component import
  3. Refactors to pass plain data
  4. Updates files
  5. Reports: "Phase 2 fixes complete"
  
Orchestrator → build-checker:
  "Re-review Phase 2"
  
Checker:
  ✓ Issue fixed
  Status: PASS
  
Loop continues
```

---

## Adaptation Guide

### How to Adapt This to Your Project

**Step 1: Document Your Patterns (1-2 hours)**

Create these files:

**Minimal CLAUDE.md**:
```markdown
# Project: {Your Project Name}

## Tech Stack
- Framework: {Next.js, React, Vue, etc.}
- Language: {TypeScript, Python, etc.}
- Database: {PostgreSQL, MongoDB, etc.}
- Testing: {Jest, Pytest, etc.}

## Commands
npm run dev      # Start development
npm test         # Run tests
npm run build    # Build for production

## Code Standards
- {Your key standards, 3-5 bullets}

## Testing Requirements
- {Your coverage requirements}
```

**Architecture Docs** (`docs/ai/architecture/`):

Create 2-4 docs:
- `layered-architecture.md` - Your layer boundaries
- `data-flow.md` - How data moves in your system
- Others as needed for your domain

**Golden Path Docs** (`docs/ai/golden-paths/`):

Create 3-5 docs:
- `api-conventions.md` - Your API patterns
- `naming-conventions.md` - Your naming rules
- `testing-conventions.md` - Your test patterns
- Others as needed

**Step 2: Copy This Blueprint's Files**

Copy these files exactly:
- `.claude/commands/new-build.md`
- `.claude/agents/build-context-gatherer.md`
- `.claude/hooks/build-context-verification.py`
- `.claude/hooks/check-phase-completion.py`
- `docs/ai/workflows/build-orchestrator.md`
- `docs/ai/workflows/build-dag.json`

**Step 3: Customize These Files**

Customize for your project:

**`.claude/agents/build-planner.md`**:
- Update test specification format to match your test framework
- Update phase types to match your typical work
- Update examples to match your domain

**`.claude/agents/build-executor.md`**:
- Update TDD examples to match your test framework
- Update golden path examples to match your patterns
- Update tool commands to match your project (npm vs. yarn vs. pnpm)

**`.claude/agents/build-checker.md`**:
- Update architecture checks to match your architecture
- Update golden path checks to match your patterns
- Update examples to match your domain

**`.claude/hooks/build-plan-verification.py`**:
- Adjust step count ranges if needed (default: 10-50)
- Adjust test coverage threshold if needed (default: 50%)

**`.claude/settings.json`**:
- Update PostToolUse hooks for your test command
- Add any project-specific permissions
- Adjust hook commands for your tools (npm vs. yarn, tsc vs. mypy, etc.)

**Step 4: Test on Simple Feature**

Create a test feature:
```bash
mkdir -p docs/ai/features/test-button
echo "Add a button to the home page that says 'Click me'" > docs/ai/features/test-button/unstructured-plan.md
```

Run workflow:
```bash
> /new-build test-button
```

Verify:
- Context gathered correctly
- Plan created with phases
- Executor implements with TDD
- Hooks catch any errors
- Checker reviews architecture

**Step 5: Iterate and Improve**

After first feature:
- Update architecture docs if gaps found
- Add golden paths as patterns emerge
- Refine agent instructions based on behavior
- Adjust hook sensitivity if too noisy

---

### Framework-Specific Adaptations

**For Python Projects**:

**PostToolUse Hooks**:
```json
{
  "command": "mypy $CLAUDE_FILE_PATHS || echo '⚠️ Type errors'",
  "command": "pytest --collect-only -q $CLAUDE_FILE_PATHS || echo '⚠️ Tests failed'"
}
```

**Test Specifications**:
```markdown
- Step 2.1: Create User model (tests: tests/test_user.py - test validation, required fields)
```

**For Mobile Projects (React Native, Swift)**:

**PostToolUse Hooks**:
```json
{
  "command": "npx tsc --noEmit || echo '⚠️ Type errors'",
  "command": "npm test -- --findRelatedTests $CLAUDE_FILE_PATHS || echo '⚠️ Tests failed'"
}
```

Or for Swift:
```json
{
  "command": "swift build || echo '⚠️ Build failed'",
  "command": "swift test --filter $CLAUDE_FILE_PATHS || echo '⚠️ Tests failed'"
}
```

**For Backend/API Projects**:

Focus golden paths on:
- API contract patterns
- Database migration patterns
- Error response formats
- Authentication/authorization patterns

**For Frontend Projects**:

Focus golden paths on:
- Component structure
- State management patterns
- Styling conventions
- Accessibility standards

---

### Scaling Considerations

**For Small Teams (1-3 developers)**:
- This blueprint as-is works well
- Invest 1-2 hours in documentation upfront
- Reap benefits immediately

**For Medium Teams (4-10 developers)**:
- Add team review process for architecture docs
- Create shared golden path library
- Regular refinement sessions (monthly)

**For Large Teams (10+ developers)**:
- Centralized architecture council
- Automated golden path compliance checking
- Integration with CI/CD pipelines
- Metrics tracking (velocity, quality, patterns)

---

## Troubleshooting

### Common Issues and Solutions

**Issue 1: Context Validation Keeps Failing**

**Symptom**: `build-context-verification.py` repeatedly fails

**Causes**:
- Architecture docs don't exist
- Golden path docs don't exist
- CLAUDE.md is empty or malformed

**Solution**:
- Create minimal architecture doc (even just 1 paragraph)
- Create minimal golden path doc (even just 3 bullets)
- Ensure CLAUDE.md has basic tech stack info

---

**Issue 2: Plan Has No Test Specifications**

**Symptom**: `build-plan-verification.py` fails with "Low test specification coverage"

**Causes**:
- Planner didn't follow instructions
- Feature is mostly documentation/config (legitimately needs few tests)

**Solution**:
- Re-run planner with emphasis: "Include test specifications for all logic steps"
- If legitimately few tests needed: Adjust threshold in verification script
- Review planner output, provide feedback

---

**Issue 3: Hooks Too Noisy (Failing Constantly)**

**Symptom**: TypeScript/test hooks fail after every edit, slowing executor

**Causes**:
- Executor writing multiple files for a step (hooks run after each)
- Test suite slow
- TypeScript strictness high

**Solutions**:
- Expected behavior during multi-file steps (executor should handle)
- Optimize test suite (use `--findRelatedTests`, `--maxWorkers=2`)
- Adjust hook commands to be less verbose (`head -5` instead of `head -20`)
- Consider disabling hooks, let executor run manually: `npm test && tsc` after each step

---

**Issue 4: Checker Always Fails Phase**

**Symptom**: Checker consistently marks phases as FAIL

**Causes**:
- Architecture docs too strict/detailed
- Golden paths too prescriptive
- Checker misunderstanding standards

**Solutions**:
- Review architecture docs - are they realistic?
- Review golden paths - are they practical?
- Update checker instructions with your specific patterns
- Provide examples in architecture docs

---

**Issue 5: Executor Ignores Test Specifications**

**Symptom**: Executor writes implementation before tests

**Causes**:
- Executor instructions not clear enough
- Model not following TDD discipline
- Test specs too vague

**Solutions**:
- Update executor instructions to emphasize TDD
- Make test specs more explicit in plan
- Try Opus for executor (more expensive but better discipline)

---

**Issue 6: Phase Loop Never Ends**

**Symptom**: Executor and checker keep looping on same phase

**Causes**:
- Checker requirements unclear
- Executor can't fix the issues
- Architectural problem too complex

**Solutions**:
- Check `max_retries_per_phase: 5` limit
- Review verification report - is feedback actionable?
- User intervention may be needed for complex architectural decisions

---

**Issue 7: Hooks Don't Run**

**Symptom**: No TypeScript/test validation happening

**Causes**:
- `settings.json` not in correct location
- Hook syntax error
- Tools not available (npm, tsc not in PATH)

**Solutions**:
- Verify `.claude/settings.json` exists
- Check JSON syntax validity
- Test commands manually: `npx tsc --noEmit`, `npm test`
- Check permissions in `settings.json`

---

**Issue 8: Features Directory Gets Messy**

**Symptom**: Too many feature directories, hard to find things

**Solutions**:
- Archive completed features: Move to `docs/ai/features/archive/`
- Use clear naming: `2025-01-user-dashboard` (date prefix)
- Regular cleanup: Delete abandoned features
- Create `docs/ai/features/README.md` with active features list

---

## Conclusion

This blueprint provides a complete, production-ready system for autonomous build workflows with Claude Code. The key innovations are:

1. **Phase-level execution** balances efficiency with error prevention
2. **TDD enforcement** via test specifications provides concrete goals
3. **Continuous validation** via hooks prevents compounding errors
4. **Architectural review** per phase maintains big picture coherence
5. **Big picture context** prevents narrow implementations

**Investment**: 2-3 hours to set up, infinite reuse  
**ROI**: 10-30% productivity improvement on the 20% of work that's predictable  
**Quality**: Higher test coverage, better architecture compliance, fewer bugs

**Next Steps**:
1. Document your patterns (1-2 hours)
2. Copy and customize files (1 hour)
3. Test on simple feature (30 minutes)
4. Iterate and refine based on feedback

---

**Version History**:
- v1.0.0 (2025-01-15): Initial blueprint based on research and practical implementation

**License**: Open for use, modification, and distribution

**Contact**: Share improvements and lessons learned with the community!