Continue my **PSCV0 v7 native Lean language-first compiler**, autonomously and dependency-first, through *all* core/essential Phase A–E acceptance gates.

**Repository:** https://github.com/dwijayuda/pskernel
**Working branch:** `psc0/pscv0-v7-native-lean-v1`
**Existing draft PR:** https://github.com/dwijayuda/pskernel/pull/109

### 1. Start here (mandatory)

Resolve the **live GitHub branch HEAD** before editing. Read these GitHub-branch files in order:
1. `psc0/AI_WORK_STATE.md` — **CURRENT TOP HANDOFF**, including all A–E phases; old sections below the historical divider are not latest state.
2. `psc0/PSCV0_LANGUAGE_REFERENCE.md` — canonical v7/Lean 4.35.0-rc4 semantic/syntax target.
3. `psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` — complete A–E dependency plan and per-phase exit gates.
4. `psc0/docs/PSCV0_STANDARD_SNAPSHOT_V1.md` — current deterministic Standard serialization/fingerprint and its trust limits.
5. Inspect the affected native `.lean` source, tests and pinned upstream official Lean 4.35.0-rc4 definitions as required.

**Latest qualified EXECUTABLE SHA (as of this handoff):** `fc8bc8b1f16ed993fb144e2d396c0760c068630b`.
**Linux Actions all-green:** https://github.com/dwijayuda/pskernel/actions/runs/38323422371.
**Historical FNV-only executable baseline:** `c810d6fe15d064968008d09849efd9ac5b2820de` ([Linux 38292170524](https://github.com/dwijayuda/pskernel/actions/runs/38292170524)). Resolve newer live GitHub HEAD and CI before editing; documentation may be newer than this qualified executable source.
**Pinned official checker:** Lean `4.35.0-rc4` at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
**Bounded source profile:** `pscv0-v7-native-bounded/48` — not complete language conformance.

**Current evidence:** **198** shared runtime observations through direct JS, strict TS, Rust, V8 Wasm GC and native Wasmtime; 170 portable/178 native `.lean` modules; selected Standard **230 declarations, 14 classes, 40 ordered instances** at FNV `fnv1a64:17137083495666611555` and SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`. M1 has actual checked `GetElem`, selected low-priority automatic `GetElem?` from dependent `Decidable`, positive/negative optional outcomes and target-level `outOfBounds` panic. The generic automatically LawfulGetElem instance is NOT proven; the proof class requires real equalities. M2 has checked invocation-scoped answer reuse, Pi-index synthesis, independent budget caps and postponed-input scheduling. Qualified executable `fc8bc8b1f16ed993fb144e2d396c0760c068630b`, [Linux 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371). Do not claim full Lean or v7 conformance.

**NEW QUALIFIED M0 ARCHITECTURE:** Read `psc0/docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md`. The checked Core→IR erasure now has separate roles for runtime value, reified type, erased higher-kinded dependent index and erased Prop evidence, with retained Core source-parameter masks shared by structures, inductives, declarations, applications, recursors and projections. The first selected end-to-end GetElem program and 192 JS/TS/Rust/Wasm-related observations passed. Next: complete true `GetElem?`, `LawfulGetElem`, List/Array/Fin index proofs and exact `!` runtime behavior, then tabled instance search and Phase B–E. No full-Lean parity, Pskernel-core, C5 or self-hosting claim.

**Historical M1/M2 precursor:** `f8900407eaaa921097e6cd49d58551ca6558ed96` first qualified Type-0 user-defined optional methods and checked answer memoization at 194 observations. The CURRENT qualified implementation and blockers are specified above; use the M1/M2 audit for the subsequent default-decider, panic and bounded scheduling milestones.

**CURRENT QUALIFIED M1/M2 IMPLEMENTATION:** [`fc8bc8b1f16ed993fb144e2d396c0760c068630b`](https://github.com/dwijayuda/pskernel/commit/fc8bc8b1f16ed993fb144e2d396c0760c068630b), [Linux 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371) **PASSED**. **198** shared cross-backend observations, 170 portable/178 native modules, selected Standard **230 declarations/14 classes/40 instances**, FNV `fnv1a64:17137083495666611555`, SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`. M1 derives selected low-priority `GetElem?` from genuine dependent decidability, exact typed runtime panic, and proof-bearing GetElem. The generic `LawfulGetElem` automatically derived proof was rejected (independent decision witnesses are not definitionally equal); it must be reconstructed by genuine proof theory, not `rfl` or an axiom. M2 uses per-invocation checked positive-answer table, Pi-indexed synthesis, separate candidate/visit caps, and input readiness postponement. Next solve Lean-grade generator/consumer waiters, full dependent class / universe closures, quantitative benchmarks. The source/audit above contains older historical figures: DO NOT use them as current. Review `psc0/docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md`.

### 2. Execute complete language plan without stopping at progress reports

**Phase A — Finish Standard/everyday language (CURRENT).** Prioritize faithful RC4 `GetElem`/`GetElem?` plus Prop-valued index validity and Decidable/proof obligations for `xs[i]`, `xs[i]'h`, `xs[i]?`, `xs[i]!`. Verify `src/Init/GetElem.lean` at pinned upstream SHA; NEVER substitute unchecked bounds/Bool comparisons for a proof. Then finish allowlisted deriving `Inhabited`/`BEq`/`DecidableEq`/`Repr`/`Hashable`, Float/Float32/scientific, fixed-width/BitVec, selected Array/List/ByteArray/string/codec APIs and true RC4 instance/notation/module fidelity. Complete and cryptographically pin the comprehensive Standard/import/deriving/tactic/effect/assumption manifest. Review any intentional change against the current Standard fingerprint and qualify it.

**Phase B — Dependent data/termination.** Complete dependent/heterogeneous indexed elimination, selected nested/mutual inductives, positivity, dependent patterns and motives, total mutual/structural/well-founded recursion and all-target erasure/runtime lowering. Reject unsupported or unproven recursion.

**Phase C — Generic typed control/effects.** Complete shared class-driven `do`, Option/Except/State/Reader/transformer behavior, mutable and erased state, loops, early return, throw/try/catch/finally, effect/capability boundaries and cross-target preservation. Do not invent JS exception semantics for Lean.

**Phase D — Proofs/contracts/VCs.** Complete selected proof-producing rewrite/simp/omega/grind with pinned sources; exact Lean RC4 `given`/`requires`/`ensures`, assert, invariant/decreasing, `Std.WP`/`vcgen` and spec proof attachment. Build an auditable proof/spec/effect/assumption/termination/erasure ledger. **Verified executable emission is blocked until EVERY mandatory obligation is discharged**.

**Phase E — Full v7 core/essential conformance and assurance.** Close every normative requirement with a `PS-CONF-*` matrix and exact accepted/refused phases, differential Lean 4.35 RC4 term/semantic checking, final crypto-pinned environment + axiom/effect provenance, meaningful multi-module applications and full JS/TS/Rust/Wasm GC/Wasmtime regressions. Mark v7 complete **only** when this exit gate is independently satisfied. Do not extrapolate from green bounded tests or subjective percentage estimates.

Later `C5` source reconstruction, backend `D` performance measurement, compiler-source `.ps` migration, bootstrap/self-hosting, `pskernel-core` integration and P2 extensions are **DEFERRED/OUT OF SCOPE** for now; do not start them.

### 3. Engineering discipline

Understand specifications, dependency graph and invariants *before* editing. Inspect the whole affected subsystem. Prefer clean, correct, performant, extensible native Lean abstractions; freely replace weak internal architecture when a better coherent design exists, but preserve externally required semantics, soundness, checked graph, runtime behavior and Wasm/ABI constraints. Fix shared root causes, not individual test failures. Implement related functionality together, then run minimal high-value positive/negative checking and the existing Linux cross-target matrix at meaningful milestones. Never weaken correctness or acceptance to get a green run. Record exact source commit, CI and residual gaps after every qualified milestone.

**Mandatory constraints:** keep compiler source entirely native portable `.lean`; official Lean 4.35.0-rc4 checker; GitHub connector ONLY for repository reads/writes and **Linux GitHub Actions** for builds/tests. No local checkout, local build, Desktop Commander, pskernel-core, `.ps` source migration, self-hosting, C5 reconstruction, main merge, release, force push or branch deletion. Preserve the draft PR and branches/history. Keep Wasm GC internally and linear memory only at explicit Canonical ABI boundaries. Keep shared JS/TS/Rust/Wasm contracts and actual source/member provenance. Treat foreign data/effects as untrusted boundaries.

**Autonomy:** continue from one coherent qualified milestone to the next rather than stopping for reports or asking for repeated confirmation. When actually blocked, reconstruct the architecture/Lean semantics first, then choose a system-level fix. Keep `AI_WORK_STATE.md`, the roadmap and this prompt synchronized with exact executable SHA/CI; retain history. Do not promise background execution.
