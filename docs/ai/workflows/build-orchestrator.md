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
     - `CLAUDE.md`, `README.md`, Xcode project files, etc.
   - Tell it to write context to: `docs/ai/features/{feature-id}/project-context.md`

2. Wait for context-gatherer to finish

3. **The validation hook runs AUTOMATICALLY** via SubagentStop hook
   - Hook: `python3 .claude/hooks/build-context-verification.py {feature-id}`
   - The hook runs automatically when the sub-agent completes (configured in .claude/settings.json)
   - You will see the hook output in the response
   - If the hook fails (exit 1): The error message will appear. Return to build-context-gatherer with corrections.
   - If the hook passes (exit 0): You'll see success message. Proceed to next step.

### Step 3: Create Structured Plan

1. Delegate to **build-planner** sub-agent:
   - Tell it to read:
     - `docs/ai/features/{feature-id}/project-context.md`
     - `docs/ai/features/{feature-id}/unstructured-plan.md`
   - Tell it to write:
     - `docs/ai/features/{feature-id}/implementation-plan.md` (with test specifications)
     - `docs/ai/features/{feature-id}/status-update.md`

2. Wait for build-planner to finish

3. **The validation hook runs AUTOMATICALLY** via SubagentStop hook
   - Hook: `python3 .claude/hooks/build-plan-verification.py {feature-id}`
   - The hook runs automatically when the sub-agent completes (configured in .claude/settings.json)
   - You will see the hook output in the response
   - If the hook fails (exit 1): The error message will appear. Return to build-planner with corrections.
   - If the hook passes (exit 0): You'll see success message. Proceed to implementation loop.

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

6. **Now, YOU (the orchestrator) MUST EXPLICITLY RUN the phase completion check**:
   ```bash
   python3 .claude/hooks/check-phase-completion.py {feature-id}
   ```
   - This script does NOT run automatically - you must run it via Bash tool
   - The script reads status-update.md and verification-phase-{N}.md
   - Check the script's exit code and output message

   **Exit code 0 with "Phase {N} passed"**: Phase passed, more phases remain
   - Continue to next phase (return to step 1)

   **Exit code 0 with "All phases complete"**: All phases verified successfully
   - Go to Step 5 (workflow complete)

   **Exit code 1 with "Phase {N} failed"**: Phase failed verification
   - Read `verification-phase-{N}.md` for specific issues
   - Re-delegate to build-executor with fixes needed from verification report
   - Tell it to address the issues found by the checker
   - After fixes, return to step 4 (checker reviews the fixed phase again)

   **Exit code 1 with "awaiting_verification"**: Phase implementation not complete
   - Executor hasn't finished yet, wait for completion

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

Hooks run automatically after every file edit by the build-executor (configured in `.claude/settings.json`):
- Swift compilation check (`xcodebuild build`)
- Test execution for changed files (`xcodebuild test`)
- Executor sees output immediately after each Write/Edit tool use
- Prevents technical errors from compounding

These are NOT the Python validation scripts - these are the Swift compile/test hooks that run automatically during execution.

This means build-checker can focus on **architectural review** only, since technical correctness (compilation, test pass/fail) is already validated by these hooks.

## Error Handling

### If Context Gathering Validation Fails
- SubagentStop hook runs automatically: `python3 .claude/hooks/build-context-verification.py`
- If exit code is 1: You'll see error message in hook output
- Re-delegate to build-context-gatherer with corrections from the error message
- Max 3 retries before escalating to user

### If Plan Validation Fails
- SubagentStop hook runs automatically: `python3 .claude/hooks/build-plan-verification.py`
- If exit code is 1: You'll see error message in hook output
- Re-delegate to build-planner with corrections from the error message
- Max 3 retries before escalating to user

### If Build-Executor Encounters Blocker
- Executor should report blocker immediately
- Stop work on current phase
- Report blocker to you (orchestrator)
- You report to user
- Wait for user guidance
- Do NOT proceed to build-checker

### If Build-Checker Finds Issues (Phase Failed)
- You (the orchestrator) explicitly run: `python3 .claude/hooks/check-phase-completion.py {feature-id}`
- If it returns exit code 1 with "failed verification" message: Phase failed verification
- Read the verification report at `docs/ai/features/{feature-id}/verification-phase-{N}.md`
- Re-delegate to build-executor with detailed feedback from the verification report
- Tell executor which specific issues to fix (from the verification report)
- Executor fixes specific issues in the phase
- Return to build-checker for re-verification of same phase
- Loop until check-phase-completion.py returns exit code 0 (checker gave PASS)
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
3. **Trust the hooks**: Swift compilation (`xcodebuild build`) and test validation (`xcodebuild test`) happens automatically via PostToolUse hooks after every file edit during execution
4. **Hook types**:
   - **SubagentStop hooks** (automatic): Run when sub-agents complete (build-context-verification.py, build-plan-verification.py)
   - **check-phase-completion.py** (manual): You must explicitly run this script via Bash after checker completes
5. **Phase-level execution**: Executor implements entire phases, not individual steps
6. **Checker reviews architecture**: Don't ask checker to verify Swift compilation or tests (hooks already did that continuously)
7. **Follow the DAG**: Always respect dependencies in build-dag.json
8. **Read verification reports**: You run check-phase-completion.py to read verification reports and decide next action
9. **Update status visibility**: status-update.md must always reflect current state
10. **Big picture context**: Executor always has full plan and project context
11. **TDD discipline**: Every step with business logic must have tests written first

## Communication Examples

### Delegating to Executor