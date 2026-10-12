# Next-chat prompt — PSCV0 v7 native Lean language-first continuation

Continue my public open-source ProofScript PSCV0 v7 compiler at https://github.com/dwijayuda/pskernel.
Branch: `psc0/pscv0-v7-native-lean-v1`. Existing draft PR #109 (do not merge).

First read `psc0/AI_WORK_STATE.md` (the top active handoff takes precedence over older records), `psc0/PSCV0_LANGUAGE_REFERENCE.md`, and `psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md`. Resolve the current GitHub branch HEAD before any writes and inspect the affected implementation.

Latest fully green executable checkpoint: `754108eb861ef19642b6f3ae9e17e7313ef179bb`; Linux CI: https://github.com/dwijayuda/pskernel/actions/runs/38244878977. Current bounded source profile is `pscv0-v7-native-bounded/48`. The user calls the newly qualified module foundation Profile 49; this does not imply full v7 conformance. CI passed 171 shared observations in JS, TS, Rust and Wasm; 159 portable and 167 native Lean modules, 4 checked programs, 92 phase-specific refusals and the compact module-planning check.

Recent implementation: `packages/compiler/src/Ps/Compiler/Pscv0Modules.lean` handles named, in-memory .ps modules, explicit `import`/`public import`, topological dependency planning, checked imported interfaces and missing/cycle refusal. The native host and `scripts/Pscv0Native.lean` now support manifest-driven project checking/emission. Full RC4 module visibility and standalone multi-file executable conformance are still pending.

PRIORITY: Finish multi-module language semantics and runnable linking before unrelated features: default public/private source declarations, RC4 imported-body opacity, public-import and namespace/open visibility, diamonds/collisions, deterministic class/instance identity, runtime library linking, entry-only exports, and project-relative provenance. Prove actual prepared project closure through official Lean checking, and run a compact multi-file executable case across the existing backend matrix. Do not infer new CLI end-to-end coverage solely from a green legacy integration run.

Then continue all other essential language families from the canonical v7 roadmap: Standard manifest and typeclass completeness, literals/typed scalars/GetElem/deriving, dependent and mutual data, well-founded termination, generalized typed do/effects/state/control, proof-producing rewriting and tactics, contracts/VCs and the assumption/effect/erasure assurance ledger. Think systemically and fix shared causes, not individual failing tests. Keep minimal high-value tests.

CONSTRAINTS: The compiler stays fully native, clean, extensible, portable `.lean` and checked against official pinned Lean 4.35.0-rc4. Use GitHub tools for ALL repository reads/writes, and Linux GitHub Actions for compiling/testing; no local checkout/build or Desktop Commander. Keep the same branch/PR; non-force expected-head writes; preserve history and previously qualified backends, source maps and Wasm GC semantics (linear memory only at Canonical ABI boundaries). No pskernel-core, compiler-source migration to .ps, self-hosting, bootstrap checks, C5 source reconstruction, main merge or release yet.

Work autonomously as far as possible in this chat. Keep `psc0/AI_WORK_STATE.md` and the roadmap current with exact commits and CI receipts. Report qualified capability limits, not just green status.
