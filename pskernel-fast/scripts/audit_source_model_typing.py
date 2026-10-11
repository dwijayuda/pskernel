#!/usr/bin/env python3
"""Exact P1o receipts; all earlier independent assumption gates stay enabled."""
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
