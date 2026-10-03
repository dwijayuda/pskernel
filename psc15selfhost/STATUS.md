# PSC2 minimal self-host status

Status (2026-10-03): the project has returned to a **compiler-only bootstrap**.
`@proofscript/pskernel-lean-wasm` (Lean 4.34.0 WASM) is the default host-side
checker. No kernel package is in the generated compiler bootstrap closure.

The generated owned `@proofscript/pskernel-core` work through checker.14 is
preserved as a private experimental alternative, with its historical evidence intact,
but it is no longer a bootstrap dependency or the default checker. No fallback is
performed between checker implementations.

The acceptance target is now the compiler fixed point:

1. canonical compiler source closure generated from PSC1-compatible Lean;
2. admissions checked by the selected host-side Lean WASM kernel;
3. generated compiler re-emits the same canonical ProofScript workspace;
4. generated TypeScript compiler output is byte-identical at the fixed point.

This target does **not** claim owned-kernel self-hosting or a joint compiler/kernel
fixed point.
