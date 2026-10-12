# Continue PSCV0 v7 — Native Lean Phase A

Repository https://github.com/dwijayuda/pskernel
Branch `psc0/pscv0-v7-native-lean-v1`, draft PR #109.
**Latest qualified executable:** `32ee1e2efbeebd08f4c86745bd3d27981cd19f6b`.
**Linux CI:** https://github.com/dwijayuda/pskernel/actions/runs/38275596470.

Read the top of `psc0/AI_WORK_STATE.md`, canonical
`psc0/PSCV0_LANGUAGE_REFERENCE.md` and
`psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md`, then resolve
the live branch HEAD before editing. Latest qualified source:
164 portable/172 native Lean modules; 178 JS/TS/Rust/V8 GC/Wasmtime
runtime observations; runnable three/four-module projects; checked
Option/List Standard APIs, safe List.get?, exact raw/interpolated
strings and selected numerals; typed BEq/ToString/Inhabited classes.

Continue dependency-driven Phase A work, particularly exact Lean RC4
GetElem/index proof semantics, selected deriving handler generation,
Float/scientific/fixed-width scalars and the frozen Standard registry.
Prefer coherent native Lean abstractions to patching tests. Check
the formal interface/erasure/runtime invariants and qualify through
the Linux Actions integration matrix; add only high-value negative
tests. Update exact qualified SHA/CI evidence in AI_WORK_STATE and
roadmap without claiming full v7 from bounded green results.

Mandatory: native portable .lean implementation only; official
Lean 4.35.0-rc4 checking; GitHub for all reads/writes; Linux GitHub
Actions for builds/tests. No local checkout/build, Desktop Commander,
pskernel-core, compiler-source .ps migration, self-hosting, C5 source
reconstruction, main merge, release, branch deletion or force push.
Preserve Wasm GC internally/Canonical ABI linear memory and existing
JS/TS/Rust/Wasm contracts.
