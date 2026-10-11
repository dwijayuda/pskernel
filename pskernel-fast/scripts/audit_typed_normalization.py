#!/usr/bin/env python3
"""G4.4b exact receipts, using the existing fail-closed parser/allowlist.

The original 157-receipt gate runs separately and is unchanged. This stage
adds six precisely enumerated receipts; it does not replace or weaken it.
"""
import pathlib
import sys
import audit_axioms as gate

NAMES = {
    "PSKernelFast.Core.TypedSteps.source_typed",
    "PSKernelFast.Core.TypedSteps.target_typed",
    "PSKernelFast.Core.TypedSteps.denotation_preserved",
    "PSKernelFast.Core.compareTypedWH_positive",
    "PSKernelFast.Core.compareTypedWH_zero",
    "PSKernelFast.Core.JoinedCertificate.total_steps_bound",
}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_typed_normalization.py <lean-log>")
    gate.THEOREMS = NAMES
    try:
        gate.test_fail_closed()
        gate.audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"G4.4b assumption audit FAILED: {error}")
    print(f"G4.4b theorem-assumptions PASS: {len(NAMES)} exact additional receipts")
