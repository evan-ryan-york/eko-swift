# docs/ai/workflows/build-orchestrator.md

# Build Workflow Orchestrator

You are orchestrating the Build Flow workflow. This workflow takes an unstructured plan and converts it into a fully implemented feature using test-driven development (TDD).

## Overview

This is a multi-agent workflow with validation gates. You coordinate 4 specialist agents:
1. **build-context-gatherer** - Gathers project context
2. **build-planner** - Creates phased implementation plan with test specifications
3. **build-executor** - Implements entire phases using TDD
4. **build-checker** - Reviews completed phases for architecture and quality

## DAG Definition

Read `docs/ai/workflows/build-dag.json` for the complete dependency graph, inputs, outputs, and validation rules.

## Execution Instructions

### Step 1: Initialize

**If feature ID was provided (via $ARGUMENTS):**

1. Feature ID: `{feature-id}` (from command arguments)
2. Check if `docs/ai/features/{feature-id}/` exists
   - If yes: Continue to step 2
   - If no: Create the directory
3. Check if `docs/ai/features/{feature-id}/unstructured-plan.md` exists
   - If yes: "Found existing plan. Proceeding with build."
   - If no: Ask user: "Please paste your unstructured plan" and save it to that location

**If no feature ID was provided:**

1. Ask user: "What feature are we building? This will be the feature ID (use kebab-case, e.g., 'dashboard-redesign')."
2. User provides: `{feature-id}`
3. Create directory: `docs/ai/features/{feature-id}/`
4. Ask user: "Please paste your unstructured plan"
5. Save to: `docs/ai/features/{feature-id}/unstructured-plan.md`

### Step 2: Gather Context

1. Delegate to **build-context-gatherer** sub-agent:
   - Tell it the feature ID: `{feature-id}`
   - Tell it to read:
     - `docs/ai/features/{feature-id}/unstructured-plan.md`
     - `docs/ai/architecture/*` 
     - `docs/ai/golden-paths/*`
     - `CLAUDE.md`, `package.json`, `README.md`, etc.
   - Tell it to write context to: `docs/ai/features/{feature-id}/project-context.md`

2. Wait for context-gatherer to finish

3. **Automatic validation hook runs**: `build-context-verification.py`
   - If fails: Hook blocks and shows error
   - Fix: Re-run context-gatherer with corrections
   - If passes: Continue

### Step 3: Create Structured Plan

1. Delegate to **build-planner** sub-agent:
   - Tell it to read:
     - `docs/ai/features/{feature-id}/project-context.md`
     - `docs/ai/features/{feature-id}/unstructured-plan.md`
   - Tell it to write:
     - `docs/ai/features/{feature-id}/implementation-plan.md` (with test specifications)
     - `docs/ai/features/{feature-id}/status-update.md`

2. Wait for build-planner to finish

3. **Automatic validation hook runs**: `build-plan-verification.py`
   - If fails: Hook blocks and shows error
   - Fix: Re-run build-planner with corrections
   - If passes: Continue

### Step 4: Execute Implementation Loop (PHASE-LEVEL)

This is a **phase-level loop** - executor implements entire phases, checker reviews entire phases.

**For each phase, repeat until all phases complete:**

1. **Identify Current Phase**
   - Read `docs/ai/features/{feature-id}/status-update.md`
   - Find the next incomplete phase (first phase with unchecked steps)
   - Note phase number (e.g., "Phase 2")

2. **Delegate to build-executor** (implements ENTIRE phase):
   - Tell it: "Implement Phase {N}: {Phase Name}"
   - Tell it to read:
     - `docs/ai/features/{feature-id}/implementation-plan.md` (full plan for context)
     - `docs/ai/features/{feature-id}/project-context.md` (architecture, golden paths)
     - `docs/ai/features/{feature-id}/status-update.md` (current progress)
   - Tell it to implement ALL steps in Phase {N} using TDD:
     - For each step: write tests first, then implementation
     - Run tests after each step completion
     - Update status-update.md after each step
   - Executor will work autonomously on the entire phase

3. **Wait for build-executor to complete**
   - Executor will report when Phase {N} is complete
   - All steps in the phase will be marked [x] in status-update.md

4. **Delegate to build-checker** (reviews ENTIRE phase):
   - Tell it: "Review Phase {N}: {Phase Name}"
   - Tell it to read:
     - `docs/ai/features/{feature-id}/implementation-plan.md` (what should have been built)
     - `docs/ai/features/{feature-id}/status-update.md` (what was built)
     - The actual code files changed in Phase {N}
     - `docs/ai/architecture/*` (architecture standards)
     - `docs/ai/golden-paths/*` (coding standards)
   - Tell it to verify:
     - Architecture compliance
     - Golden path adherence
     - Integration quality
     - Code organization
   - Tell it to write: `docs/ai/features/{feature-id}/verification-phase-{N}.md`

5. **Wait for build-checker to complete**
   - Checker will write verification report with PASS/FAIL status

6. **Check Phase Completion**: Run `python .claude/hooks/check-phase-completion.py {feature-id}`
   - Script reads verification report for Phase {N}
   - **Exit code 0 (phase passed, more phases remain)**: Continue to next phase (return to step 1)
   - **Exit code 0 (all phases complete)**: All done, go to Step 5
   - **Exit code 1 (phase failed verification)**: Return to step 2 with checker feedback:
     - Re-delegate to build-executor with specific fixes needed
     - Tell it to address issues from `verification-phase-{N}.md`
     - After fixes, return to step 4 (checker reviews again)

### Step 5: Complete

1. Report: "Build workflow complete! 🎉"
2. Summarize:
   - **Feature implemented**: `{feature-id}`
   - **Phases completed**: {total phases}
   - **Total steps**: {total steps}
   - **Files changed**: [list major files]
   - **All phases verified**: ✅
   - **All tests passing**: ✅
3. Next steps for user:
   - Manual testing and QA
   - Create pull request
   - Deploy to staging

## Important Phase-Level Loop Rules

### Why Phase-Level?

**NOT step-level** (too much context switching, too slow)  
**NOT all-phases-at-once** (errors compound, hard to debug)  
**Phase-level is optimal** (balance between catching errors early and execution efficiency)

### What Executor Does Per Phase

The executor implements **ALL steps in a phase** before returning control:
- Reads full implementation plan (for big picture context)
- Implements Phase 2, steps 2.1 through 2.5
- Uses TDD for each step (tests first, then implementation)
- Sees hook output after each file edit (TypeScript errors, test failures)
- Marks each step complete in status-update.md
- Reports when entire phase is done

### What Checker Does Per Phase

The checker reviews **architectural quality** of the completed phase:
- Does NOT check TypeScript errors (hooks already did)
- Does NOT check if tests pass (hooks already did)
- DOES check: architecture compliance, golden path adherence, code organization
- DOES check: integration quality, design patterns, separation of concerns
- Writes verification report with PASS/FAIL and specific feedback

### Continuous Validation via Hooks

Hooks run automatically after every file edit (configured in `.claude/settings.json`):
- TypeScript compilation check
- Test execution for changed files
- Executor sees output immediately
- Prevents technical errors from compounding

This means checker can focus on **architectural review** only.

## Error Handling

### If Context Gathering Validation Fails
- Hook will block automatically
- Show error message from validation script
- Re-run build-context-gatherer with corrections
- Max 3 retries before escalating to user

### If Plan Validation Fails
- Hook will block automatically  
- Show error message from validation script
- Re-run build-planner with corrections
- Max 3 retries before escalating to user

### If Build-Executor Encounters Blocker
- Executor should report blocker immediately
- Stop work on current phase
- Report blocker to you (orchestrator)
- You report to user
- Wait for user guidance
- Do NOT proceed to build-checker

### If Build-Checker Finds Issues (Phase Failed)
- check-phase-completion.py returns exit code 1
- Read verification report for specific issues
- Re-delegate to build-executor with feedback from checker
- Executor fixes specific issues in the phase
- Return to build-checker for re-verification
- Loop until checker gives PASS
- Max 5 iterations per phase before escalating to user

### If Check Script Fails to Run
- Report error to user
- Show script output
- User may need to fix script or environment
- Do not proceed without successful check

## Progress Tracking

### Status Update File

The `status-update.md` file is the single source of truth for progress:
- Updated by executor after each step completion
- Read by you to determine current phase
- Read by checker to see what was implemented
- Shows clear checkboxes: [ ] incomplete, [x] complete

### Verification Reports

Each phase gets its own verification report:
- `verification-phase-1.md`
- `verification-phase-2.md`
- `verification-phase-3.md`
- etc.

These contain:
- PASS/FAIL status
- Issues found (if any)
- Required fixes (if failed)
- Architectural feedback

## Critical Rules

1. **Feature isolation**: All artifacts for this feature live in `docs/ai/features/{feature-id}/`
2. **No cross-contamination**: Don't mix multiple features in one workflow run
3. **Trust the hooks**: TypeScript and test validation happens automatically via hooks
4. **Phase-level execution**: Executor implements entire phases, not individual steps
5. **Checker reviews architecture**: Don't ask checker to verify TypeScript or tests (hooks do that)
6. **Follow the DAG**: Always respect dependencies in build-dag.json
7. **Read verification reports**: check-phase-completion.py reads these to decide next action
8. **Update status visibility**: status-update.md must always reflect current state
9. **Big picture context**: Executor always has full plan and project context
10. **TDD discipline**: Every step with logic must have tests written first

## Communication Examples

### Delegating to Executor