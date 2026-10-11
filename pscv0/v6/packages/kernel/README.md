# @proofscript/pscv-kernel — Lean 4 source package

Implementation: [src/Pscv/Kernel/Checker.lean](src/Pscv/Kernel/Checker.lean). Uses Lean 4.35.0-rc3 Lean.Environment.addDeclCore to check real candidate declarations. Its result is kernel-admission diagnostic data, not PSCV certification or proof of source fidelity.

The separately packaged native/Wasm @proofscript/pskernel-lean@4.34.0 and @proofscript/pskernel-lean-wasm@4.34.0 remain independent exact-version oracles. They must not silently substitute for the normative Lean 4.35 checker. Runtime provider selection and session-bound authority require additional implementation.

The checker rejects arbitrary axiom declarations and unsafe/partial declarations in its closed-profile candidate path **before** sending terms to Lean's kernel. Lean's kernel intentionally admits axioms in general, so this extra PSCV policy restriction is essential for preventing unapproved extension assumptions. The current development checker is a separate native executable (PscvKernelMain.lean), not linked into the small pscv_v6_dev binary. A fully versioned provider protocol and explicit boundary-assumption policy remain future work.
