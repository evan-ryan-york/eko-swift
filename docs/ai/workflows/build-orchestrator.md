# docs/ai/workflows/build-orchestrator.md

# Build Workflow Orchestrator

You are orchestrating the Build Flow workflow. This workflow takes an unstructured plan and converts it into a fully implemented feature.

## Overview

This is a multi-agent workflow with validation gates. You coordinate 4 specialist agents:
1. build-context-gatherer
2. build-planner  
3. build-executor
4. build-checker

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
     - `docs/ai/architecture/*` 
     - `docs/ai/golden-paths/*`
     - `package.json`, `README.md`, etc.
   - Tell it to write context to: `docs/ai/features/{feature-id}/project-context.md`

2. Wait for context-gatherer to finish

3. **Automatic validation hook runs**: `build-context-verification.py`
   - If fails: Hook blocks and shows error
   - Fix: Re-run context-gatherer with corrections
   - If passes: Continue

### Step 3: Create Structured Plan

1. Delegate to **build-planner** sub-agent:
   - Tell it to read:
     - `docs/ai/features/{feature-name}/project-context.md`
     - `docs/ai/features/{feature-name}/unstructured-plan.md`
   - Tell it to write:
     - `docs/ai/features/{feature-name}/implementation-plan.md`
     - `docs/ai/features/{feature-name}/status-update.md`

2. Wait for build-planner to finish

3. **Automatic validation hook runs**: `build-plan-verification.py`
   - If fails: Hook blocks and shows error
   - Fix: Re-run build-planner with corrections
   - If passes: Continue

### Step 4: Execute Implementation Loop

Repeat until all steps complete:

1. Read `docs/ai/features/{feature-name}/status-update.md`
2. Identify next incomplete step
3. Delegate to **build-executor** sub-agent:
   - Tell it which step to implement
   - Tell it to update status-update.md when done
4. Wait for executor to finish
5. Delegate to **build-checker** sub-agent:
   - Tell it to verify the step
   - Tell it to update status-update.md with verification results
6. Wait for checker to finish
7. Check completion: Run `python .claude/hooks/check-build-completion.py`
   - If exit code 0: All steps done, go to Step 5
   - If exit code 1: More work needed, return to step 1 of this loop

### Step 5: Complete

1. Report: "Build workflow complete!"
2. Summarize:
   - Feature implemented: `{feature-name}`
   - Files changed: [list]
   - All steps verified: ✅
   - Ready for: Manual testing, PR creation, etc.

## Error Handling

### If Any Validation Fails
- Hook will block automatically
- Show error message from validation script
- Re-run the failed agent with corrections
- Max 3 retries before escalating to user

### If Build-Executor Encounters Blocker
- Stop immediately
- Report blocker to user
- Wait for user guidance
- Do not proceed to build-checker

### If Build-Checker Finds Issues
- Report issues
- Update status-update.md with findings
- Re-run build-executor for that step with corrections

## Important Rules

1. **Feature isolation**: All artifacts for this feature live in `docs/ai/features/{feature-name}/`
2. **No cross-contamination**: Don't mix multiple features in one workflow run
3. **Trust the hooks**: Validation happens automatically, you don't need to validate manually
4. **Follow the DAG**: Always respect dependencies in build-dag.json
5. **Progress visibility**: Always update status-update.md after each step