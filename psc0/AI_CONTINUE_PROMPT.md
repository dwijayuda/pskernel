# Continue PSCV0 v7 — native Lean Phase A

Repository https://github.com/dwijayuda/pskernel; branch `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
Latest qualified executable: `c810d6fe15d064968008d09849efd9ac5b2820de`.
Linux Actions green: https://github.com/dwijayuda/pskernel/actions/runs/38292170524.
Official checker: Lean 4.35.0-rc4, `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
Bounded source profile `pscv0-v7-native-bounded/48`, not full conformance.

First read TOP `psc0/AI_WORK_STATE.md`, canonical `psc0/PSCV0_LANGUAGE_REFERENCE.md`,
`psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` and
`psc0/docs/PSCV0_STANDARD_SNAPSHOT_V1.md`, then resolve live GitHub
HEAD. The new portable `Ps.Environment.StandardSnapshot` pins
`fnv1a64:3890664716772208725` across 208 checked declarations,
11 classes and 36 instances, with class metadata and source aliases.
168 portable/176 native modules and 187 JS/TS/Rust/V8 GC/Wasmtime
shared observations all qualify. Source/instance body audits and
negative alias-drift refusal also pass.

Continue autonomously and dependency-first toward all core and essentials
v7 features. Next Phase A: faithful Lean RC4 GetElem validity proofs
and safe/checked indexing, remaining allowlisted deriving/float/fixed-width
and Standard registry/notation completeness. Use the pinned upstream
Lean `src/Init/GetElem.lean` to preserve GetElem versus GetElem?
semantic differences; do not replace proof validity with Bool bounds.
Implement substantial coherent native Lean abstractions first, then
focused negative checking and the existing Linux CI integration matrix.
Update the expected selected Standard fingerprint only after reviewing
and qualifying intentional changes to the installed environment.

Mandatory: native portable .lean compiler only; official Lean 4.35 RC4
checking, GitHub-only repo reads/writes and Linux Actions builds/tests.
No local checkout, Desktop Commander, pskernel-core integration,
compiler .ps migration, bootstrap/self-hosting, C5 readable reconstruction,
main merge, release, force push or branch deletion. Preserve existing draft
PR, Wasm GC internals/Canonical ABI linear memory, JS/TS/Rust/Wasm contracts
and all trust/assurance boundaries.
