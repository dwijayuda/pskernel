# PSKernel-Fast V3 — AI Work State

## Context and binding decisions — 2026-10-11

Repository: `dwijayuda/pskernel`.
Topic branch: `research/pskernel-fast-v3-greenfield-20261011`.
Pinned toolchain: `leanprover/lean4:v4.35.0-rc4`, upstream source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

User's priority: **correctness, Lean compatibility, measured performance, small auditable trusted core, memory efficiency**. Reuse of old source, architecture, proof artifacts and old source profiles has **no design priority**. Explicit architectural freedom is the reason for a fresh package rather than editing the old kernel.

Leave `psc0/pskernel-core-lean435-arena-v1` and draft PR #89 untouched. Git branches/history are retained but no old theorem interface constrains the new design. Do not merge unqualified kernel code or equate differential tests with soundness proofs.

Source of truth: GitHub and cloud CI. No desktop checkout, build or Desktop Commander. Re-read HEAD before every write, use non-force expected-HEAD updates, avoid repeated expensive full-corpus/fully generated selfhost runs.

## G0 implementation checkpoint

Architecture file: `ARCHITECTURE_V3.md` — reset design authority.
Seed source: `PSKernelFast/Core.lean` and `Main.lean` — a **simplified** RawExpr with Nat-only sort placeholder, immutable hash-consed Node array, typed failures, scope validation and bounded total decode. Compile/test is limited to native Lean 4.35; it is NOT a kernel proof checker.

Intended focused tests:
- encode/decode of a closed lambda/application term returns byte-for-byte structurally equal raw syntax;
- a second encoding reuses interned node IDs rather than allocating duplicate nodes;
- unbound de Bruijn input is rejected;
- invalid DAG child IDs and invalid decode root IDs are rejected;
- exhausting a decode budget rejects rather than looping.

**CI evidence:** evaluate the completed `PSKernel-Fast V3 greenfield G0` GitHub Actions job for the exact commit before marking this checkpoint green. A commit alone is *not* compilation evidence. No measured performance, full Lean 4.35 compatibility, soundness theorem or self-host success exists yet.

## Next vertical work

1. Check CI, diagnose any source or build failure at the *shared cause*, update exact evidence.
2. Implement full Lean 4.35 `Level` (including symbolic `imax`), names, binder metadata, literal and environment identities before classifying any expression as kernel checked.
3. Define independent raw reference syntax semantics and compare three evaluators: compact DAG + substitution (B), compact DAG + closure (A), computation-specialized call-by-need (C), on identical input identities.
4. Implement typed checked versus infer-only judgments, WHNF/DefEq and soundness-sensitive proof-irrelevance and annotation checks. Do not copy old proof statements merely to minimize migration.
5. Add safe declaration admission/inductives/recursors/quotients, full negative conformance and official Lean differential checks. Every supported result must be pinned and fail closed.
6. Prove the new chosen runtime's positive-result soundness against an explicit mathematical model and newly extended admitted environment under stated axiom assumptions.
7. Independently qualify generated native/JS/Wasm and future self-host source only after algorithm architecture and runtime are stable.

**No claimed speedup or success beyond G0 tests**; keep benchmarks parser-separated and compare official Lean at matching version and corpus.

## Verified G0 evidence — exact 4.35 toolchain

Source SHA: `48ce7e1ddaddee60bf1b6a108ea420b1469ff40f`.
[Successful workflow 38093806811](https://github.com/dwijayuda/pskernel/actions/runs/38093806811), job `114335443522`.
Log: Lean `4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; six successful Lake build jobs; executable printed G0 representation/scoping checks passed. This is not a proof checker or a benchmark result.

## G1 in progress (unqualified until separately completed CI)

New `PSKernelFast/Level.lean` represents raw `zero`, `succ`, `max`, `imax`, `param`, `mvar` syntactically, without implementing semantic level equivalence, cumulativity or checking. `RawExpr.sort` and constant universe args carry this representation. Add a negative-regression-style structural distinction between `imax 0 u` and `succ (imax 0 u)`, a known dangerous comparison class. Do NOT claim this syntactic test establishes universe soundness. Cloud validation requires a new exact SHA run.

### G1 first cloud attempt — FAILED, retained

[Run 38093952606](https://github.com/dwijayuda/pskernel/actions/runs/38093952606), source `c2a182de91d1916b0f31e422ef89d5e9000d87ba`, job `114335872910`, failed before Lean elaboration of the new level grammar: Lake reported missing `PSKernelFast/Level.olean`, because `lean_lib PSKernelFast` listed only `PSKernelFast.Core` as explicit root. **Architectural root cause:** the package dependency graph failed to include its newly imported module. Corrected by registering both modules in `lakefile.lean`. Requalify the whole G1 focused test from the corrected source before calling any part of G1 passed.

## Verified G1 evidence

**Source:** `5e47d1dcf1d9ee6a82b49148f95511a6d2d267cb`.
[Successful G1 run 38094023391](https://github.com/dwijayuda/pskernel/actions/runs/38094023391), job `114336090132`. Lean 4.35.0-rc4 pinned SHA validated; eight build jobs passed; executable reported symbolic imax syntax and scope checks passed. **G1 is only a representation checkpoint**, not universe equality soundness.

## G2 candidate — toy lazy closure evaluator

`PSKernelFast/EvalPrototype.lean` introduces a standalone closure view and fuel-bounded head evaluation of beta/let, preserving stuck neutrals and refusing zero-fuel execution. It intentionally has no public proof acceptance. The accompanying tests exercise identity beta, let-binding, stuck neutral application and resource failure. This is an architecture experiment, not a real Lean WHNF or type checker. CI must confirm its exact commit before marking G2 qualified.

## Verified G2 evidence — 2026-10-11

Source commit `313af5514e3d5a94bcb35247d83366cc40191a3c`.
[Successful workflow 38094155908](https://github.com/dwijayuda/pskernel/actions/runs/38094155908), job `114336476304`. Log shows exact Lean `4.35.0-rc4` commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; **10/10** build jobs succeeded and the executable reported beta/let closures, symbolic levels and raw DAG/scoping checks passed. This **only** certifies the named G2 tests; no formal soundness, proof admission or performance improvement is established.

### Immediate next architectural implementation milestone

Build a complete and precisely versioned expression/universe/name input layer, an independent reference evaluator and a closure evaluator over the same **well-scoped, well-typed** subset, then compare actual kernel-only cost and negative conformance before selecting the engine. Rewriting old proofs is not a goal and should never veto the implementation choice.

Cloud policy: document-only edits should not trigger costly Lean builds; the workflow now filters on code/toolchain/CI changes only. Keep CI claims bound to exact source and workflow SHAs.

## G3 expanded raw syntax (candidate, not CI-qualified)

New `PSKernelFast/Name.lean`, expanded `Level.lean` and `Core.lean` represent most Lean 4.35 expression constructor *shapes*: anonymous/str/num names; free/bound/metavariables; symbolic universe levels; constants with universe parameters; application; lambda/Pi with binder information; let/nondep; Nat/String literals; metadata and projections. Metadata is still a string placeholder, **not** Lean's full MData interchange.

An explicit closed-export preflight now rejects out-of-scope de Bruijn indices, expr metavariables, raw free variables and universe metavariables. Those checks do NOT establish typing, constant environment lookup, universe equivalence, positivity, or logical proof admission.

G3 code remains experimental until a completed exact-source GitHub workflow run confirms build/test. The G2 toy closure evaluator is adapted to the wider constructors without granting it proof acceptance.

**New acceptance requirement:** compare official Lean Expr round-trip and metadata decoding only after implementing full exact protocol; do not advertise full 4.35 expression import yet.

## G3 completed CI

Source `a6c178259f7a974fb9ec90f67f3cdb9ae81382b1` passed [run 38094975440](https://github.com/dwijayuda/pskernel/actions/runs/38094975440), job `114338913786`. Twelve Lake build jobs completed and focused syntax, metadata/projection, scope, forbidden-mvar and existing closure tests passed. The language is still not a real Lean export parser or a proof checker.

## G4 reference/closure agreement candidate (unqualified)

Added pure `PSKernelFast/Substitution.lean` (de Bruijn lifting, capture-avoiding single-binder instantiation, substitution WHNF) and `PSKernelFast/Quote.lean` (bounded environment reification and explicit closed-term comparison against the G2 lazy closure evaluator). Strengthened G2 to transparently strip inert metadata while exposing the WHNF head. Added nested binder, discarded argument, neutral, eta-shaped and metadata test cases.

This is **untyped beta/let fragment testing only**. Do NOT call successful agreement a Lean proof of correctness or DefEq soundness. Runtime resource outcomes depend on budget placement; this slice compares successful closed cases, not identical fuel consumption.

G4 cloud CI must pass for the exact new source before promotion.

### G4 initial cloud result — failed test harness construction, retained

[Run 38095097366](https://github.com/dwijayuda/pskernel/actions/runs/38095097366), source `62a442660fc51079d384517779622f280650f3e6`, failed compiling `Main.lean`: one lambda fixture supplied three of four required fields; its binder info was missing. All G4 implementation modules (`Substitution` and `Quote`) compiled in that run. Added the missing `BinderInfo.default` argument without changing evaluator rules. No G4 test outcome may be claimed before the replacement run completes.
