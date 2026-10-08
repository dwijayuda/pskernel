# @proofscript/pscv-kernel — Lean 4 source package

Implementation: [src/Pscv/Kernel/Checker.lean](src/Pscv/Kernel/Checker.lean). Uses Lean 4.35.0-rc3 Lean.Environment.addDeclCore to check real candidate declarations. Its result is kernel-admission diagnostic data, not PSCV certification or proof of source fidelity.

The separately packaged native/Wasm @proofscript/pskernel-lean@4.34.0 and @proofscript/pskernel-lean-wasm@4.34.0 remain independent exact-version oracles. They must not silently substitute for the normative Lean 4.35 checker. Runtime provider selection and session-bound authority require additional implementation.
