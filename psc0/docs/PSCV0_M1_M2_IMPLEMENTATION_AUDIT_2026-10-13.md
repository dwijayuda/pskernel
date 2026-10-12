# PSCV0 native M1 and M2 — Implementation evidence and remaining Lean parity

**Date:** 2026-10-13 · **Repository:** https://github.com/dwijayuda/pskernel · **Branch:** `psc0/pscv0-v7-native-lean-v1` · **Draft PR:** [#109](https://github.com/dwijayuda/pskernel/pull/109).

**Latest green executable:** [`f8900407eaaa921097e6cd49d58551ca6558ed96`](https://github.com/dwijayuda/pskernel/commit/f8900407eaaa921097e6cd49d58551ca6558ed96), [Linux CI 38315275940](https://github.com/dwijayuda/pskernel/actions/runs/38315275940) — **PASSED**. **Pinned upstream Lean:** 4.35.0-rc4, [`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364). **Qualification remains bounded:** NOT full PSCV0 v7, Lean feature parity, metatheory, verified-emission or self-hosting.

## 1. Milestones actually implemented

| Area | Source of truth | Observed evidence | Not yet established |
|---|---|---|---|
| M1: checked optional class | `packages/environment/src/Ps/Environment/StandardGetElem.lean` | Added selected `GetElem?` class, `toGetElem` superclass dictionary, `getElem?` and `getElem!` fields, checked projections; low-priority superclass projection instance. Native source and artifacts accepted. | Full 3-universe Lean `GetElem?` signature; generic default instance from decidability; built-in lawful indexing; automatic panic |
| M1: syntax/typing/erasure | `packages/syntax/src/Ps/Syntax/Pscv0/TermParts.lean`, `packages/erasure/src/Ps/Erasure/{Basic,Definition,Inductive,Expr}.lean` | Existing four `xs[i]`, `xs[i]'h`, `xs[i]?`, `xs[i]!` source spellings now include selected executable optional and bang methods; checked Core source masks still eliminate predicate family `valid` and proofs safely | Unrestricted dependent indices, optional method universe closure |
| M1: central Standard ownership | `packages/compiler/src/Ps/Compiler/Api.lean`, `packages/environment/src/Ps/Environment/SelfHostProd.lean` | Native compiler derives its internal runtime names from the **same runtime-prelude declaration list** used for code generation; accidental public export of new Standard names is refused and was corrected at the root | Provenance and complete trust closure of all selected runtime primitives |
| M2: checked answer-table solver | `packages/meta/src/Ps/Meta/SynthInstance.lean` | Replaced duplicate depth-first recursive candidate selection with a **per-synthesis answer table**, closed positive-answer reuse, rechecking with `psInferType` and `psUnify`, class input/output reconciliation, priority-preserving candidate selection, dependency worklist and context rollback | Lean's generator/consumer graph, suspended waiters, full tabling of cyclic goals, maximal universe/unification completeness |
| M2: search resource behavior | `Ps.Meta.SynthInstance.psSynthInstanceSearch` | 64-depth default fuel and separate 4096 visit budget prevent unbounded growth. An independent source-level native check observed a ground witness reused with **no new expansion**, initial count **1**. Failed/rejected goals are not cached. | Benchmark parity with Lean, terminal memory bounds for all environments and real-world concurrent IDE workloads |
| Regression evidence | `test/Pscv0NativeTests.lean`, `scripts/pscv0-native-observations.mjs`, CI | **194 shared observations** ran in strict TypeScript, direct JS, Rust and the Wasm GC / Wasmtime workflows, including 7 new indexed behaviors since the original 187 baseline. Official Lean oracle and invalid-proof refusal remain green. | Exhaustive conformance, quantified performance and formal compiler semantic preservation |

### Selected Standard snapshot

**221 declarations, 13 registered classes, 37 ordered instances**. Reviewed fingerprints:
- FNV: `fnv1a64:4160132988510892817`.
- SHA-256: `sha256:a02c9f39e6de1830497114edfaad5e9bdd5730110b562585e3f6ecc30b80b6d3`.

These identify the checked **selected** Standard payload, not the upstream Lean environment, an approved trusted supply chain, the backend runtime interpretation, or any consistency proof. The official Lean native provider remains the admission authority.

## 2. Intentional semantic restrictions

**Optional indexing:** The selected executable `GetElem?` currently requires `elem : Type 0`, because the runtime `Option` family is not yet universe-polymorphic. The superclass dictionary is computationally real, not an axiom. `xs[i]?` dispatches to an explicitly checked optional instance. `xs[i]!` dispatches to its checked method, but the current positive sample is in bounds and supplies that method; we have **not** validated general out-of-bounds panic behavior. Declaring this equivalent to unrestricted Lean `GetElem?` would be inaccurate.

**Proofs:** `xs[i]` requires real `Prop` evidence. The native tactic covers local assumptions, definitional reflexivity and bounded trivial constructors. Invalid `xs[1]` where only `i=0` is valid continues to fail at elaboration; proofs do not survive as executable data.

**Class table:** Successful answers are reused only after all expression metavariables are instantiated, with a full-target key (not the `outParam`-masked candidate lookup key). Cached expressions are **re-typechecked and re-unified**. Entries are local to the immutable environment, local instances and registry for one synthesis invocation; they must never be shared between modules, snapshots or distinct local contexts. This is answer memoization and dependency scheduling, not yet complete SLG/tabled generation with consumer waiters.

**Trust:** No pskernel-core integration, compiler self-hosting, unchecked `Bool ⇒ Prop` evidence, suppression of `PsVerifiedIrType.unknown` checks, hidden proof admission, or silent fallback in verified compilation was added.

## 3. Pinned Lean RC4 architectural comparison

- Lean [`Init/GetElem.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean) defines full-universe `GetElem?` **extending** `GetElem`, a low-priority `Decidable`-based optional instance, exact `getElem!` runtime panic semantics and the two-proposition `LawfulGetElem` contract. The current PSC subset has superclass storage and selected optional methods but does not yet cover these advanced rules.
- Lean [`Lean/Meta/SynthInstance.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean) uses a true answer table with goal generators, answer consumers, suspended waiters, normalized keys, local-instance and size/resource constraints. The new PSC memo reuses validated completed answers and preserves fail-closed recursion; cyclic producer/consumer dependencies are pending.
- Lean [`Lean/Compiler/LCNF/ToMono.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/ToMono.lean) and [`MonoTypes.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/MonoTypes.lean) explicitly erase proofs and higher-kinded type formers. PSCV0's qualified M0 roles and source masks follow this separation.

## 4. Next coherent implementation gates (without weakening acceptance)

**M1 remaining (mandatory for exact Lean parity):**
1. Generalize `Option`, `Inhabited`, and related runtime class families across selected Lean universe levels before lifting `GetElem?` beyond Type 0.
2. Implement the general `GetElem? ← GetElem + ∀ xs i, Decidable(valid xs i)` instance. The decision must produce checked `Decidable` evidence, not a raw Boolean presumed to prove bounds.
3. Provide `LawfulGetElem` with real kernel-checked `getElem?_def` and `getElem!_def` obligations. Build sound List/Array/Fin validity and lawful instances rather than inventing a generic index validity axiom.
4. Implement Lean's `outOfBounds` **kernel-definition/runtime-panic split** through an explicitly audited compilation boundary and all target backends. Check both positive and negative runtime paths, including Wasm traps; do not replace panics with defaults.
5. Expand `omega`/simplification and index proof tactic extensibility with proof-producing, bounded tactics.

**M2 remaining (mandatory for Lean-grade completeness):**
1. Upgrade completed-answer memoization to actual generator/consumer goal scheduling with suspended waiters, canonical goals and stable ordering across recursion cycles.
2. Integrate synthetic metas, postponed expected-type/universe constraints, output parameter resolution, local/ordered imported instances and deterministic rollback into a single constraint engine.
3. Benchmark class diamonds, cyclic refusal, polymorphic outputs and real compiler compile-time/peak-memory growth against the pinned Lean reference. Reject resource exhaustion without weakening proof obligations.

**After M1/M2:** continue source/recursor completeness, generic typed effects, assurance ledger and all Phase B–E gates. No C5, pskernel-core or self-hosting until explicitly requested.

## 5. Qualification and handoff

The **last green executable** is `f8900407eaaa921097e6cd49d58551ca6558ed96` at [CI 38315275940](https://github.com/dwijayuda/pskernel/actions/runs/38315275940). Documentation commits following it do not change the qualified executable. The draft PR remains open. Always resolve live branch HEAD first, read the CURRENT TOP of `psc0/AI_WORK_STATE.md`, this report and the canonical `PSCV0_LANGUAGE_REFERENCE.md`, then implement a coherent next layer, run Linux qualification, and update the evidence.
