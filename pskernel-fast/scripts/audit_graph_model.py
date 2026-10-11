#!/usr/bin/env python3
"""Exact P1l graph application receipts; original 157+17 gates remain unchanged."""
import pathlib
import sys
import audit_axioms as gate

NAMES = {
    "PSKernelFast.Spec.modelOrderedPair_inj",
    "PSKernelFast.Spec.orderedPair_member_modelGraph",
    "PSKernelFast.Spec.modelGraph_ext",
    "PSKernelFast.Spec.modelGraph_functional",
    "PSKernelFast.Spec.modelGraphApp_beta",
    "PSKernelFast.Spec.modelGraphPi_intro",
    "PSKernelFast.Spec.modelGraphPi_app_member",
    "PSKernelFast.Spec.modelGraphPi_eta",
    "PSKernelFast.Spec.modelGraphPi_ext",
}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_graph_model.py <lean-log>")
    gate.THEOREMS = NAMES
    try:
        gate.test_fail_closed()
        gate.audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"P1l graph model assumption audit FAILED: {error}")
    print(f"P1l graph model PASS: {len(NAMES)} exact additional theorem receipts")
