#!/usr/bin/env python3
"""Build/audit/test certified execution and relative search completeness.

All older 232-receipt gates remain unchanged. This gate reuses the same
strict parser/allowlist and negative-input self-tests.
"""
import subprocess
import sys
import audit_axioms as gate

MODULES = [
    "Proof/SourceCertificateCoherence.lean",
    "Proof/SourceCertificateSynthesis.lean",
    "Proof/CertifiedReduction.lean",
    "Proof/CertifiedNormalization.lean",
    "Proof/SourceCertificateCompleteness.lean",
]
NAMES = {
    "PSKernelFast.Proof.sourceModelTyping_annotations_unique",
    "PSKernelFast.Proof.synthesizedModel_unique",
    "PSKernelFast.Proof.certifyClosedModel_sound",
    "PSKernelFast.Proof.certifyClosedModel_no_false",
    "PSKernelFast.Proof.certifyClosedModel_zero",
    "PSKernelFast.Proof.sourceModelTyping_step",
    "PSKernelFast.Proof.ModelSteps.sound",
    "PSKernelFast.Proof.ModelSteps.operational",
    "PSKernelFast.Proof.compareCertifiedWH_sound",
    "PSKernelFast.Proof.compareCertifiedWH_operational",
    "PSKernelFast.Proof.compareCertifiedWH_zero",
    "PSKernelFast.Proof.synthesizeSourceCertificate_complete",
}
SMOKES = ["pskernel_fast_source_certificate_smoke", "pskernel_fast_certified_normalization_smoke"]


def main() -> None:
    targets = ["PSKernelFast." + p.removesuffix(".lean").replace("/", ".")
               for p in MODULES]
    subprocess.run(["lake", "build", *targets, *SMOKES], check=True)
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
    for target in SMOKES:
        subprocess.run(["lake", "exe", target], check=True)


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, ValueError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.stdout:
            print(error.stdout, file=sys.stderr)
        raise SystemExit(f"Source-certificate gate FAILED: {error}")
