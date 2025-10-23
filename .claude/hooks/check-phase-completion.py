#!/usr/bin/env python3
"""
Checks if the current phase has passed verification and determines next action.

This hook runs after build-checker completes. It reads the verification report
for the current phase and returns exit codes to control workflow:
- Exit 0: Phase passed, check if more phases remain (orchestrator continues or exits)
- Exit 1: Phase failed, executor must fix issues (orchestrator loops back to executor)

Usage: python .claude/hooks/check-phase-completion.py {feature_id}
"""

import sys
import re
from pathlib import Path


def find_current_phase_and_status(status_file, feature_dir):
    """
    Find the current phase and determine its status by checking:
    1. Which phases have all steps completed
    2. Which phases have verification reports
    3. Which verification reports passed/failed

    Returns: (phase_num, status, message)
    Status can be: "not_started", "in_progress", "awaiting_verification", "failed", "passed_more_remain", "all_complete"
    """
    try:
        content = status_file.read_text()
    except Exception as e:
        return None, "error", f"Error reading status file: {e}"

    # Find all phase sections
    phase_pattern = r"###\s+Phase\s+(\d+):"
    phases = re.findall(phase_pattern, content)

    if not phases:
        return None, "error", "No phases found in status file"

    phase_numbers = [int(p) for p in phases]
    total_phases = len(phase_numbers)

    # For each phase, check completion and verification status
    for phase_num in phase_numbers:
        # Find this phase's section
        phase_section_pattern = rf"###\s+Phase\s+{phase_num}:.*?(?=###\s+Phase\s+\d+:|$)"
        phase_match = re.search(phase_section_pattern, content, re.DOTALL)

        if not phase_match:
            continue

        phase_content = phase_match.group(0)

        # Count checked and unchecked steps
        checked_steps = len(re.findall(r"- \[x\]", phase_content, re.IGNORECASE))
        unchecked_steps = len(re.findall(r"- \[ \]", phase_content))
        total_steps = checked_steps + unchecked_steps

        # Phase not started or in progress
        if unchecked_steps > 0:
            if checked_steps == 0:
                return phase_num, "not_started", f"Phase {phase_num} not started"
            else:
                return phase_num, "in_progress", f"Phase {phase_num} in progress ({checked_steps}/{total_steps} steps complete)"

        # Phase has all steps checked - check for verification report
        if checked_steps > 0 and unchecked_steps == 0:
            verification_file = feature_dir / f"verification-phase-{phase_num}.md"

            if not verification_file.exists():
                return phase_num, "awaiting_verification", f"Phase {phase_num} complete, awaiting verification"

            # Check verification report status
            passed, message = check_verification_report(verification_file)

            if not passed:
                return phase_num, "failed", f"Phase {phase_num} failed verification: {message}"

            # Phase passed - check if this is the last phase
            if phase_num == total_phases:
                return phase_num, "all_complete", f"Phase {phase_num} passed (final phase) - all complete!"
            else:
                # More phases remain - but check if next phase has started
                next_phase_num = phase_num + 1
                continue  # Check next phase

    # If we get here, all phases are complete and verified
    return phase_numbers[-1], "all_complete", "All phases complete and verified"


def check_verification_report(verification_file):
    """
    Read the verification report and determine if phase passed or failed.
    Returns: (passed: bool, message: str)
    """
    if not verification_file.exists():
        return False, f"Verification report not found: {verification_file}"
    
    try:
        content = verification_file.read_text()
    except Exception as e:
        return False, f"Error reading verification report: {e}"
    
    # Look for status line
    status_match = re.search(r"\*\*Status\*\*:\s*(PASS|FAIL)", content, re.IGNORECASE)
    
    if not status_match:
        return False, "Could not find status in verification report (expected '**Status**: PASS' or '**Status**: FAIL')"
    
    status = status_match.group(1).upper()
    
    if status == "PASS":
        return True, "Phase verification passed"
    elif status == "FAIL":
        # Extract reason if available
        reason_match = re.search(r"\*\*Reason\*\*:\s*(.+?)(?:\n|$)", content)
        reason = reason_match.group(1) if reason_match else "See verification report for details"
        return False, f"Phase verification failed: {reason}"
    else:
        return False, f"Unknown status in verification report: {status}"


def main():
    """Main entry point for phase completion check."""

    # Get feature ID from command line argument
    if len(sys.argv) < 2:
        print("❌ Error: Feature ID required")
        print("Usage: python check-phase-completion.py {feature_id}")
        sys.exit(1)

    feature_id = sys.argv[1]
    features_dir = Path("docs/ai/features")
    feature_dir = features_dir / feature_id

    if not feature_dir.exists():
        print(f"❌ Error: Feature directory not found: {feature_dir}")
        sys.exit(1)

    # Check status file
    status_file = feature_dir / "status-update.md"
    if not status_file.exists():
        print(f"❌ Error: Status file not found: {status_file}")
        sys.exit(1)

    # Find current phase and status
    phase_num, status, message = find_current_phase_and_status(status_file, feature_dir)

    if phase_num is None:
        print(f"❌ Error: {message}")
        sys.exit(1)

    # Handle different statuses
    if status == "not_started":
        print(f"⏳ {message}")
        print(f"   Orchestrator should delegate Phase {phase_num} to build-executor")
        sys.exit(0)  # Not an error - just waiting to start

    elif status == "in_progress":
        print(f"⏳ {message}")
        print(f"   Executor is still working on Phase {phase_num}")
        sys.exit(1)  # Phase not done yet - should not have reached checker

    elif status == "awaiting_verification":
        print(f"⏳ {message}")
        print(f"   Orchestrator should delegate Phase {phase_num} to build-checker")
        sys.exit(1)  # Not ready to move on - needs checker review first

    elif status == "failed":
        print(f"❌ {message}")
        print(f"   Orchestrator should send Phase {phase_num} back to build-executor with fixes")
        print(f"   Read: {feature_dir}/verification-phase-{phase_num}.md for details")
        sys.exit(1)  # Phase failed - executor must fix

    elif status == "all_complete":
        print(f"✅ {message}")
        print("   🎉 All phases verified and complete!")
        print("   Workflow finished successfully")
        sys.exit(0)  # Success - all done

    elif status == "passed_more_remain" or (status == "passed" and message.find("final phase") == -1):
        # Phase passed and more phases remain
        print(f"✅ Phase {phase_num} passed verification")
        print(f"   Orchestrator should continue to next phase")
        sys.exit(0)  # Phase passed - move to next phase

    else:
        print(f"❌ Error: Unknown phase status: {status}")
        print(f"   Message: {message}")
        sys.exit(1)


if __name__ == "__main__":
    main()