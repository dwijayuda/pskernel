#!/usr/bin/env python3
"""G4.4b/P1k exact receipts using the existing fail-closed parser/allowlist.

The original 157-receipt gate runs separately and is unchanged. This stage
adds six operational and five model receipts; it does not replace it.
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
    "PSKernelFast.Spec.member_modelSeparation",
    "PSKernelFast.Spec.universe_separation_closed",
    "PSKernelFast.Spec.universe_no_surjection_from_member",
    "PSKernelFast.Spec.universe_image_closed",
    "PSKernelFast.Spec.modelGraph_member_same_univ",
}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_typed_normalization.py <lean-log>")
    gate.THEOREMS = NAMES
    try:
        gate.test_fail_closed()
        gate.audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"G4.4b/P1k assumption audit FAILED: {error}")
    print(f"G4.4b/P1k theorem-assumptions PASS: {len(NAMES)} exact additional receipts")
