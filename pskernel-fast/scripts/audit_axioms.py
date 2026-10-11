#!/usr/bin/env python3
"""Fail-closed P0/P1 theorem-assumption audit (NOT a kernel soundness proof).

The Lean source itself emits '#print axioms <theorem>' for all qualified
cross-layer P1 lemmas. GitHub CI obtains these statements from the exact
pinned Lean compiler and this script pins their names and allowed
assumptions. This is deliberately limited to the theorems listed below.
"""
import pathlib
import re
import sys

REPORTED = re.compile(
    r"'(?P<theorem>[^']+)' depends on axioms:\s*\[(?P<axioms>[^\]]*)\]"
)
ALLOWED = {"propext", "Classical.choice", "Quot.sound"}
THEOREMS = {
    "PSKernelFast.Spec.ContextScoped.lookup_scoped",
    "PSKernelFast.Spec.closedInput_iff",
    "PSKernelFast.Proof.generalPiRule_scope",
    "PSKernelFast.Proof.generalPiContextWF_scoped",
    "PSKernelFast.Proof.certified_ne_malformedResult",
    "PSKernelFast.Proof.inferred_success_certifiable",
    "PSKernelFast.Proof.inferClosedGeneralPi_source_and_result_scoped",
    "PSKernelFast.Proof.liftBVars_one_instantiate_cancel",
    "PSKernelFast.Proof.liftBVars_zero",
    "PSKernelFast.Proof.bound_zero_substitution_preserves_type",
    "PSKernelFast.Proof.dependent_identity_beta_preserves_type",
    "PSKernelFast.Proof.dependent_let_variable_zeta_preserves_type",
    "PSKernelFast.Proof.dependent_outer_variable_beta_preserves_type",
    "PSKernelFast.Proof.dependent_outer_variable_let_preserves_type",
    "PSKernelFast.Proof.eraseExpr_lift",
    "PSKernelFast.Proof.eraseExpr_instantiate",
    "PSKernelFast.Proof.generalPiRule_erasable",
    "PSKernelFast.Proof.generalPiContextWF_erasable",
    "PSKernelFast.Proof.inferClosedGeneralPi_erasable",
    "PSKernelFast.Proof.liftBVars_add",
    "PSKernelFast.Proof.liftBVars_comm",
    "PSKernelFast.Proof.checked_bound_variable_weakens",
}


def audit(content: str) -> None:
    if "sorryAx" in content or "native_decide" in content:
        raise ValueError("Unreviewed proof assumption token detected")
    records = {}
    for result in REPORTED.finditer(content):
        name = result.group("theorem")
        ax = {
            item.strip() for item in result.group("axioms").split(",")
            if item.strip()
        }
        if name in records:
            raise ValueError(f"Duplicate theorem-assumption record: {name}")
        records[name] = ax

    if records.keys() != THEOREMS:
        missing = sorted(THEOREMS - records.keys())
        extra = sorted(records.keys() - THEOREMS)
        raise ValueError(f"Missing/extra theorem receipts: missing={missing} extra={extra}")
    for name, axioms in records.items():
        unknown = axioms - ALLOWED
        if unknown:
            raise ValueError(f"{name} imported unreviewed axioms: {sorted(unknown)}")
    print(f"G4.3b P1 theorem-assumptions gate PASS: {len(records)} exact theorems")
    print(f"Reviewed possible assumptions: {sorted(ALLOWED)}")


def test_fail_closed() -> None:
    valid = "\n".join(
        f"'{name}' depends on axioms: [propext, Quot.sound]"
        for name in sorted(THEOREMS)
    )
    audit(valid)
    for bad in (
        valid.replace("Quot.sound", "sorryAx", 1),
        valid.replace("Quot.sound", "Axiom.ofUnchecked", 1),
        valid.replace("depends on axioms:", "not-an-audit:", 1),
        valid + "\n'PSKernelFast.Proof.Fake' depends on axioms: []",
    ):
        try:
            audit(bad)
        except ValueError:
            pass
        else:
            raise ValueError("Proof-assumption audit fails open on synthetic bad input")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_axioms.py <lean-axiom-log>")
    try:
        test_fail_closed()
        audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"G4.3b proof-assumptions gate FAILED: {error}")
