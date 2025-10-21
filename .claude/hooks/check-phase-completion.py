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


def find_current_phase(status_file):
    """
    Find the current phase being worked on by looking for the first phase
    with all steps checked off but no verification report yet, or the first
    phase with unchecked steps.
    """
    try:
        content = status_file.read_text()
    except Exception as e:
        return None, f"Error reading status file: {e}"
    
    # Find all phase sections
    phase_pattern = r"###\s+Phase\s+(\d+):"
    phases = re.findall(phase_pattern, content)
    
    if not phases:
        return None, "No phases found in status file"
    
    # For each phase, check if all steps are complete
    for phase_num in phases:
        phase_num = int(phase_num)
        
        # Find this phase's section
        phase_section_pattern = rf"###\s+Phase\s+{phase_num}:.*?(?=###\s+Phase\s+\d+:|$)"
        phase_match = re.search(phase_section_pattern, content, re.DOTALL)
        
        if not phase_match:
            continue
        
        phase_content = phase_match.group(0)
        
        # Count checked and unchecked steps
        checked_steps = len(re.findall(r"- \[x\]", phase_content))
        unchecked_steps = len(re.findall(r"- \[ \]", phase_content))
        
        if unchecked_steps > 0:
            # This phase has unchecked steps - it's the current phase
            return phase_num, "current_in_progress"
        elif checked_steps > 0:
            # This phase has all steps checked - it's the current phase to verify
            return phase_num, "current_needs_verification"
    
    # All phases complete
    return int(phases[-1]), "all_phases_complete"


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
    
    # Find current phase
    current_phase, phase_status = find_current_phase(status_file)
    
    if current_phase is None:
        print(f"❌ Error: {phase_status}")
        sys.exit(1)
    
    # Handle different phase states
    if phase_status == "current_in_progress":
        print(f"⏳ Phase {current_phase} still in progress (has unchecked steps)")
        print("   Executor should continue working on this phase")
        sys.exit(1)
    
    elif phase_status == "current_needs_verification":
        print(f"⏳ Phase {current_phase} implementation complete, waiting for checker verification")
        print("   Checker should review this phase")
        sys.exit(1)
    
    elif phase_status == "all_phases_complete":
        # Check if final phase has verification report
        verification_file = feature_dir / f"verification-phase-{current_phase}.md"
        
        if not verification_file.exists():
            print(f"⏳ Phase {current_phase} (final phase) needs verification")
            print("   Checker should review this phase")
            sys.exit(1)
        
        # Check final phase verification
        passed, message = check_verification_report(verification_file)
        
        if not passed:
            print(f"❌ Phase {current_phase} (final phase) verification failed")
            print(f"   {message}")
            print(f"   Read: {verification_file}")
            sys.exit(1)
        
        # All phases complete and verified!
        print(f"✅ All phases complete and verified!")
        print(f"   Final phase {current_phase}: {message}")
        print("   🎉 Workflow complete!")
        sys.exit(0)
    
    # Should not reach here
    print(f"❌ Error: Unexpected phase status: {phase_status}")
    sys.exit(1)


if __name__ == "__main__":
    main()