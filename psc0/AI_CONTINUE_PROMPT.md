# PSCV0 v7 — Native Lean continuation from latest qualified source

Repository: https://github.com/dwijayuda/pskernel
Branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
Latest executable checkpoint: `54899bd8dbfaa5d118a3cc8c1b2a744bd40d5049`.
Linux CI green: https://github.com/dwijayuda/pskernel/actions/runs/38257103317.

Read the TOP of `psc0/AI_WORK_STATE.md`, canonical
`psc0/PSCV0_LANGUAGE_REFERENCE.md`, and
`psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` FIRST. Resolve live
GitHub HEAD before editing. The new native source supports checked
module-private identity, entry-reachable project closure, RC4-style public
definition opacity/exposed abbreviations, runnable 3-file JS/TS/Rust
linking, Wasm GC binary validation, raw strings and grouped radix literals.
The source profile stays `pscv0-v7-native-bounded/48`.
All 171 shared JS/TS/Rust/V8 Wasm/Wasmtime observations passed.

Continue dependency-driven work to complete all remaining core and essential
v7 language features, starting with full module/Standard semantic rules,
deriving, GetElem, interpolated strings and scalar numeric families, then
mutual/termination, generalized typed do/effects, proof-producing rewriting,
contracts/VCs and assurance closure. Implement coherent native Lean
abstractions before testing; reuse the compact Linux Actions integration
matrix. Avoid test-driven special-case patches.

Mandatory: .lean-only source, official Lean 4.35.0-rc4 checking, GitHub
connector-only reads/writes and Linux GitHub Actions builds/tests. Never
use local checkout/build, Desktop Commander, pskernel-core, .ps compiler
migration, bootstrap/self-hosting, C5 source reconstruction, main merge,
release, force push or branch deletion. Preserve Wasm GC internals/Canonical
ABI linear memory and all backend contracts. Keep AI_WORK_STATE and roadmap
current with *qualified executable* commit and CI SHA; do not infer full v7
from green bounded evidence.

