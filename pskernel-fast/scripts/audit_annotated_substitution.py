#!/usr/bin/env python3
"""P1n exact substitution/source receipts. Prior 157+17+28 gates unchanged."""
import pathlib
import sys
import audit_axioms as gate

NAMES = {
    "PSKernelFast.Spec.AnnotatedModelTerm.forget_lift",
    "PSKernelFast.Spec.AnnotatedModelTerm.forget_instantiate",
    "PSKernelFast.Spec.interpAnnotated_lift",
    "PSKernelFast.Spec.interpAnnotated_instantiate",
    "PSKernelFast.Spec.interpAnnotated_instantiate_zero",
    "PSKernelFast.Proof.PiModelTerm.toAnnotated_forget",
    "PSKernelFast.Proof.PiModelTerm.toAnnotated_interp",
    "PSKernelFast.Proof.source_annotated_lift",
    "PSKernelFast.Proof.source_annotated_instantiate",
    "PSKernelFast.Proof.source_annotated_substitution_model",
    "PSKernelFast.Proof.source_annotated_beta",
    "PSKernelFast.Proof.source_annotated_zeta",
    "PSKernelFast.Proof.AnnotatedContextValid.empty",
    "PSKernelFast.Proof.AnnotatedContextValid.extend",
    "PSKernelFast.Proof.source_bound_annotated_model",
    "PSKernelFast.Proof.polyIdentity_model_member",
    "PSKernelFast.Proof.polyIdentity_source_erasure",
    "PSKernelFast.Proof.polyIdentity_checked_cases",
}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_annotated_substitution.py <lean-log>")
    gate.THEOREMS = NAMES
    try:
        gate.test_fail_closed()
        gate.audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"P1n substitution audit FAILED: {error}")
    print(f"P1n substitution PASS: {len(NAMES)} exact additional theorem receipts")
