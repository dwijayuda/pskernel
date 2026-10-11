#!/usr/bin/env python3
"""Exact P1l/P1m model and source receipts; original 157+17 gates remain unchanged."""
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
    "PSKernelFast.Spec.modelApp_point",
    "PSKernelFast.Spec.modelApp_graph",
    "PSKernelFast.Spec.modelPi_member_sort",
    "PSKernelFast.Spec.modelLam_intro",
    "PSKernelFast.Spec.modelPi_elim",
    "PSKernelFast.Spec.modelPi_beta",
    "PSKernelFast.Spec.modelLam_congr",
    "PSKernelFast.Spec.modelPi_eta",
    "PSKernelFast.Spec.modelPi_ext",
    "PSKernelFast.Spec.modelPi_congr",
    "PSKernelFast.Proof.sourcePiAnnotation_typed",
    "PSKernelFast.Proof.sourcePiAnnotation_erases",
    "PSKernelFast.Proof.sourcePiAnnotation_model_member",
    "PSKernelFast.Proof.sourcePiAnnotation_result_exact",
    "PSKernelFast.Proof.sourcePiAnnotation_executed_model",
    "PSKernelFast.Proof.sourcePiIdentityFamily_annotation",
    "PSKernelFast.Proof.sourcePiIdentityProp_exec",
    "PSKernelFast.Proof.sourcePiIdentityType_exec",
    "PSKernelFast.Proof.sourcePiIdentityType_exec_model",
}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_graph_model.py <lean-log>")
    gate.THEOREMS = NAMES
    try:
        gate.test_fail_closed()
        gate.audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"P1l/P1m model/source assumption audit FAILED: {error}")
    print(f"P1l/P1m model/source PASS: {len(NAMES)} exact additional theorem receipts")
