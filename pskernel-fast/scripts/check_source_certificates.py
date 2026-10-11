#!/usr/bin/env python3
"""Build/audit the current certificate closure before the older full suite.

Runs in pinned GitHub Actions, not on a developer workstation. The existing
232-receipt gates run separately and remain unchanged. This gate reuses
the same strict assumption parser and negative-input self-tests.
"""
import subprocess
import sys
import audit_axioms as gate

MODULES = ["Proof/SourceCertificateCoherence.lean"]
NAMES = {"PSKernelFast.Proof.sourceModelTyping_annotations_unique"}


def main() -> None:
    targets = ["PSKernelFast." + p.removesuffix(".lean").replace("/", ".")
               for p in MODULES]
    subprocess.run(["lake", "build", *targets], check=True)
    texts = []
    for path in MODULES:
        result = subprocess.run(
            ["lake", "env", "lean", "src/PSKernelFast/" + path],
            check=True, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT)
        print(result.stdout, end="", flush=True)
        texts.append(result.stdout)
    gate.THEOREMS = NAMES
    gate.test_fail_closed()
    gate.audit("\n".join(texts))
    print(f"Source-certificate gate PASS: {len(NAMES)} exact additional receipts", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, ValueError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.stdout:
            print(error.stdout, file=sys.stderr)
        raise SystemExit(f"Source-certificate gate FAILED: {error}")
