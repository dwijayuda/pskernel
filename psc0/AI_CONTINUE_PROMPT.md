# Continue PSCV0 v7 — native Lean, core/essential Phase A

Repository: https://github.com/dwijayuda/pskernel
Branch: `psc0/pscv0-v7-native-lean-v1` (draft PR #109).
**Latest qualified executable:** `70415686f1e7c13e4690c4f8bed549b1c882fe61`.
**Linux CI:** https://github.com/dwijayuda/pskernel/actions/runs/38286641968.

Read the CURRENT TOP of `psc0/AI_WORK_STATE.md`, the authoritative
`psc0/PSCV0_LANGUAGE_REFERENCE.md`, and
`psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md`; resolve live GitHub
branch HEAD before editing.

Qualified source: 168 portable / 176 native .lean modules; 185 shared
direct JS, TypeScript, Rust, V8 Wasm GC and Wasmtime runtime observations.
Selected Lean RC4 module-private/public identity and linked application
execution work. Typechecked Standard provides checked BEq/Inhabited/ToString,
polymorphic List/Option/Product instances, and now Type-0 Except.bind/map/
mapError/tryCatch/isOk/toOption with kernel-reducible proof cases and real
runtime error/recovery observations. All checks are bounded; not full v7.

Continue dependency-driven implementation of core/essential Phase A:
faithful RC4 GetElem/GetElem? classes and genuine index proofs,
allowlisted deriving Repr/DecidableEq/Hashable and broader recursive/
parametric generated dictionaries, Float/Float32/scientific/fixed-width
source and selected library semantics, and the full frozen Standard
environment/notation/import/instance manifest + digest. Preserve true
typeclass dependencies, proof checking, effect/assumption closure and
separate check/erasure/runtime evidence. Implement coherent mechanisms
before testing, reuse compact Linux integration; fix causes, not cases.
Keep AI_WORK_STATE and roadmap synchronized with executable SHA and CI.

Constraints: portable native .lean compiler only, official Lean 4.35.0-rc4,
GitHub connector reads/writes and Linux GitHub Actions builds/tests.
No local checkout/build, Desktop Commander, pskernel-core, alternate kernel,
compiler-source .ps migration, bootstrap/self-hosting, C5 source
reconstruction, main merge, release, force push or branch deletion.
Keep PR #109 draft; preserve Wasm GC internally, linear memory only at
Canonical ABI boundaries, and JS/TS/Rust/Wasm contracts.
