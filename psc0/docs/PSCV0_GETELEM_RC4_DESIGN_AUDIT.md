# PSCV0 v7 — Lean 4.35.0-rc4 GetElem parity and design audit

**Date:** 13 October 2026. **Status:** native proof-carrying GetElem foundation **qualified**, full RC4 indexing **not qualified**. No compatibility or performance superiority claim is made.

- **ProofScript repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel), branch `psc0/pscv0-v7-native-lean-v1`, draft PR [#109](https://github.com/dwijayuda/pskernel/pull/109).
- **Latest qualified executable:** `a678594001d94c9aaade968ce951f44e1e66ba81`, [Linux Actions 38312162188](https://github.com/dwijayuda/pskernel/actions/runs/38312162188) — passed official Lean 4.35.0-rc4 compile/validation and established integration.
- **Upstream pin:** Lean `v4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Key source: [`Init/GetElem.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean), [`Init/Tactics.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Tactics.lean), [`Init/Prelude.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Prelude.lean), [`Init/Data/List/Basic.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Basic.lean), [`Init/Data/List/Impl.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Impl.lean).

## Exact Lean4 design decisions that must be preserved

**GetElem / proof obligation.** `GetElem (coll : Type u) (idx : Type v) (elem : outParam (Type w)) (valid : outParam (coll → idx → Prop))` holds `getElem (xs : coll) (i : idx) (h : valid xs i) : elem`. `coll` and `idx` drive typeclass search; `elem` and `valid` are output parameters, not source-level unchecked bounds. The proof parameter is actual erased `Prop` evidence, validated by Lean. `xs[i]` requests elaborator proof search; `xs[i]'h` supplies a specific proof.

**GetElem? / optional/panic.** Lean's `GetElem?` **extends** `GetElem`, rather than being an unrelated convenience function. It provides `getElem? : coll → idx → Option elem` and `getElem! [Inhabited elem] : coll → idx → elem`. The default `getElem!` branches on `getElem?`; out-of-range access triggers a runtime panic, even though `outOfBounds` is definitionally equal to `default` for proof reduction. Replacing this with silent default return is not an admissible equivalence. The low-priority default `GetElem?` instance depends on a `GetElem` dictionary and **decidability for each `valid xs i`**. A `Bool` shortcut is not enough.

**Lawfulness.** `LawfulGetElem` is a *proof class* requiring optional and panic operations to agree with the validity predicate and checked lookup. Bare `GetElem?` instances are not automatically lawful; genuine proof-producing lawfulness must be represented explicitly.

**Specialization.** Lean's `List` instance uses `i < xs.length` and a proof-carrying `List.get`; `List.get?Internal` and `List.get!Internal` preserve optimized reduction/runtime behavior. `Array` uses `i < xs.size`, `getInternal`, and specialized optional and panic implementations, not a generic fake `Option.getD` substitute. `Fin` delegates to the Nat index while preserving the validity relation. These need to be compared separately before claiming observable or performance parity.

**Tactic priority.** Lean's `get_elem_tactic` first recognizes an already discharged goal and local assumptions, then allows extensible automation including `omega`, arithmetic simplification and `trivial`. Tactic extensions are order-sensitive. A custom solver must preserve the invariant that only a fully constructed, kernel-checked proof discharges the obligation; a successful constructor that leaves goals open is not sufficient.

## Current PSCV0 implementation versus Lean4

| Area | PSCV0 qualification | Further work |
|---|---|---|
| `GetElem` three universes / four arguments, outParams, true `Prop` validity | **Qualified**; real checked class, method projection and user instances | Keep differential checker evidence for wider dependent types |
| `xs[i]` and `xs[i]'h` with typed proof term | **Qualified** for user-defined checked validity relations | Full Lean-style elaborator diagnostics/priority/notation combinations |
| `xs[i]?` and `xs[i]!` lexical/postfix ownership | **Parsed**, not API admission | `GetElem?`, superclass, `Decidable`, exact panic/erasure/backends |
| Implicit index proof search | **Qualified bounded subset:** assumption, reflexivity, recursive trivial constructor proof; deterministic fuel and fail-closed goals | `omega`, `simp`, external extension registry, generalized arithmetic facts |
| `LawfulGetElem` and defaults | **Not implemented** | Produce and check actual lawfulness proofs, no lawfulness-by-assertion |
| List/Array/Fin proof-aware indexing | **Not implemented** | Exact Nat order proposition, total proof-dependent accessor and optimized checked/runtime paths |
| Type/universe-wide `GetElem?` | **Not implemented** | Selected `Option` and other library families are still Type-0-specialized; generalize without fabricating a false RC4 signature |
| Runtime parity and performance for new indexes | **Five selected indexed cases now execute** in the 192-observation shared JS/TS/Rust/Wasm GC/Wasmtime matrix | Broader dependent cases, exact panic behavior and quantitative benchmarks remain pending |

The `GetElem` foundation adds **three Core declarations and one class registration** to the previous selected Standard roster: now **215 declarations, 12 classes and 36 ordered instance entries**. Both roster drift gates are enforced in production: FNV **`fnv1a64:2902463666082847583`** and SHA-256 **`sha256:9c865069b931ad1bb44a9c4861cb9748964c99368d3a7e2c4f2c75e5a099d265`**. Source closure: **170 portable / 178 native Lean modules**. Established **192** shared JS/TS/Rust/Wasm runtime observations passed at the qualified SHA, including five proof-indexed dictionary cases. No broader indexed collection performance conclusion can be drawn from those observations.

## Quality issue outside indexing: List.take / List.drop

Lean's [`List.take` and `List.drop`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Basic.lean) structurally recurse on the count **and** the list; their algorithm can stop after the requested number of elements or upon exhausting the list. Lean also uses a specialized [tail-recursive `takeTR` with `@[csimp]` correspondence](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Impl.lean).

PSCV0's current selected `List.take/drop` worker constructs its result by `List.rec` over the collection with an index-to-result function as the inductive hypothesis. This is proof-checkable, but a strict runtime evaluator may traverse the whole source list even for a small requested count. In particular, the current representation does not establish the `O(min count length)` complexity of Lean's direct implementation. This is a concrete **performance-parity debt**, not an invented benchmark or a correctness justification for replacing a checked implementation with an unchecked optimization. A direct total worker or verified backend specialization with independent equivalence/regression evidence is required before a speed claim.

## Required next coherent implementation phases

1. **Complete prerequisite Standard universes and propositions.** Make `Option`/dependent collection APIs sufficiently universe-polymorphic to express the actual Lean RC4 `GetElem?` signature; pin checked `Nat.le` / `Nat.lt` and the corresponding decidability and proof constructors. Avoid a public `GetElem?` class with silently reduced universes as a permanent design.
2. **Complete GetElem? in one compatible family.** Implement the superclass relationship, checked optional lookup, low-priority decidable fallback, lawful proofs, and the actual panicking `!` runtime primitive/semantics. Only then qualify `xs[i]?` and `xs[i]!`; preserve the error phase for unmet obligations.
3. **Integrate built-in collection instances and proof automation.** Correct `List`/`Array`/`Fin` validity propositions and total accessors. Extend the existing pure, fuel-limited solver with checked arithmetic proof production (`omega`/simplification subset), not Boolean positivity heuristics. Measure effect on instance-search complexity.
4. **Qualify semantic and performance parity.** Differential official Lean RC4 cases, checked positive/negative `PS-CONF-INDEX-*` obligations, dependent proof erasure, cross-target (JS/TS/Rust/Wasm GC and Wasmtime) runtime behavior, deep/big-list complexity, panic observability and module/API exports. Record exact source SHA/CI and any assumptions.

## High-value conformance case register

| Rule | Case | Status |
|---|---|---|
| PS-CONF-INDEX-01 | Source `xs[i]'h` supplies a real proof | Qualified |
| PS-CONF-INDEX-02 | Source `xs[i]` uses local validity hypothesis | Qualified |
| PS-CONF-INDEX-03 | Closed equality validity discharged by `rfl` | Qualified |
| PS-CONF-INDEX-04 | `True` validity discharged by constructor | Qualified |
| PS-CONF-INDEX-05 | `True ∧ True` recursively discharges all constructor goals | Qualified at `e1d463e10cbf5edd817e362ed35b21ee82c8c85b` |
| PS-CONF-INDEX-06 | Invalid `i=1` against `i=0` is refused during elaboration | Qualified |
| PS-CONF-INDEX-07 | List/Array bounds proofs and typeclass instances | Pending |
| PS-CONF-INDEX-08 | `xs[i]?` returns `Option` and agrees with validity | Pending |
| PS-CONF-INDEX-09 | `xs[i]!` panics, with RC4 proof/runtime contract | Pending |
| PS-CONF-INDEX-10 | Fin dispatch, lawful instance proofs, imports | Pending |
| PS-CONF-INDEX-11 | Arithmetical/extended tactic proof generation | Pending |
| PS-CONF-INDEX-12 | Execution and complexity benchmark against pinned Lean | Pending |

**Assurance position:** Existing checked-index terms pass the official Lean kernel and have no unresolved proof metavariables before executable preparation. This selected boundary does **not** certify full `pscv0` v7, the complete Standard environment, proof/effect/assumption closure, or verified-emission acceptance. Preserve native `.lean`, GitHub-first writes, Linux CI, Wasm GC internals, explicit Canonical ABI boundaries, and the existing no-pskernel-core/no-self-host/C5-deferred decisions.
