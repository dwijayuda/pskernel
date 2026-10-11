#!/usr/bin/env python3
"""Exact P1o typing/execution receipts; earlier independent gates stay enabled."""
import pathlib
import sys
import audit_axioms as gate

NAMES = {
    "PSKernelFast.Proof.generalPiRule_type_unique",
    "PSKernelFast.Proof.sourceModelTyping_typed",
    "PSKernelFast.Proof.sourceModelTyping_erases",
    "PSKernelFast.Proof.sourceModelTyping_sound",
    "PSKernelFast.Proof.sourceModelTyping_executed",
    "PSKernelFast.Proof.sourceModelTyping_beta",
    "PSKernelFast.Proof.sourceModelTyping_no_false",
    "PSKernelFast.Proof.polyIdentity_sourceModelTyping",
    "PSKernelFast.Proof.sourceBetaZeta_certificates",
    "PSKernelFast.Proof.sourceBetaZeta_executed_model",
    "PSKernelFast.Proof.sourceBetaZeta_equal_denotations",
    "PSKernelFast.Proof.polyIdentity_executed_via_sourceModelTyping",
}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_source_model_typing.py <lean-log>")
    gate.THEOREMS = NAMES
    try:
        gate.test_fail_closed()
        gate.audit(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    except ValueError as error:
        raise SystemExit(f"P1o source-model assumption audit FAILED: {error}")
    print(f"P1o source-model assumptions PASS: {len(NAMES)} exact additional receipts")
