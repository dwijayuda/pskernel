# PSKernel-C0 — Independent kernel assurance and architecture audit (2026-10-17)

> **Scope and provenance:** Research/checkpoint audit of the native PSKernel-C0 at `dwijayuda/pskernel`, base `perf/pskernel-c0-v7-rust-20261012` commit `1a33b20e306b97fb05da92670636b8ae9ad13094`. The experimental audit changes *no accepting kernel rule*. This document is a source- and CI-grounded snapshot, not a consistency proof or a claim that all remaining defects have been discovered.

## 1. Reproducible baseline

| Item | Observed identity |
| --- | --- |
| Kernel source | `psc0/packages/pskernel-c0/src/Ps/KernelCore/` |
| Correct native toolchain | `psc0/packages/pskernel-c0/lean-toolchain` = `leanprover/lean4:v4.35.0`, Lean Git `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` |
| Export producer | `lean4export` commit `5a9a355dc6c5fd82b69058d433e2ae2e8dfbf8fe`, export format 3.1.0 |
| Source authority | Existing fully checking `PsKernelExpr` checker and its declaration-admission APIs, not the indexed syntax store, diagnostic candidate or hash |
| Current work-state | [AI_WORK_STATE.md](AI_WORK_STATE.md), especially 17 October accepted Array and Init dependency checkpoints |
| Active plan | [C0_ARCHITECTURE_FIRST_CDE_PLAN.md](C0_ARCHITECTURE_FIRST_CDE_PLAN.md), C→D→E followed by B→F→G |
| Native full source gate | [run 38994521926](https://github.com/dwijayuda/pskernel/actions/runs/38994521926), successful 67-step native checks at `40111b9f` |
| Native adversarial gate | [run 38994521942](https://github.com/dwijayuda/pskernel/actions/runs/38994521942), official and C0 agree on two independently re-exported invalid cases |

The *repository-root* `psc0/lean-toolchain` and old `pskernel-core/README.md` refer to historical Lean 4.34/PSC1 goals. Do not accidentally substitute those for C0's local 4.35 target. Prior `C0_LEAN4_KERNEL_COMPARATIVE_SOURCE_RESEARCH_2026-10-13.md` explicitly studies a *4.34* snapshot; retain its architectural insights but re-pin behavior/compatibility claims for 4.35.

## 2. Critical distinctions in evidence

- **Definitional equality is not an arbitrary transitive union-find relation.** Lean's real algorithm is sound but may be incomplete and evaluation-order-sensitive. The Arena `rec-missing-ih` and `proj-of-stuck-prop` classes demonstrate the danger of indiscriminately taking transitive closure of successful operational conversions, especially when hash collisions and fresh-name choices affect lookup. See [upstream rec-missing-ih source/description](https://github.com/leanprover/lean-kernel-arena/blob/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/bugs/rec-missing-ih.yaml). Do not install Lean4Lean's union-find policy or any proof-inadequate success closure into C0.
- **A source-exact refinement theorem is not a kernel soundness theorem.** `Architecture/CertifiedInstantiateMemo.lean`, `Architecture/CertifiedCheckedDAGMemo.lean` and the related `Qualified*` modules record equality to C0's existing source operations under explicit context, state, fuel, immutable store and/or exact binder offsets. This is valuable optimization correctness evidence, but says nothing by itself about whether *that source checker* implements a sound mathematical typing judgment.
- **Checked receipt ownership must remain contextual.** A canonical DAG node ID or syntactic hash cannot be transported across local contexts, environment revisions, resource budgets or checker states without a proof. The current source stores prove narrower owner- and source-operation facts; no generic cross-state admission cache transport has been established.
- **A verified external checker is not a universal oracle.** Con-leche's verified checker/consistency statement comes with an explicit axiom/model/pure-checker boundary. Native Lean, Lean4Lean and independent Rust checkers provide distinct evidence, but neither majority vote nor shared implementation lineage establishes soundness.
- **A decline is not a rejection.** A version mismatch, unsupported syntax, malformed export or timeout does not pass a soundness/completeness case.

## 3. Cross-kernel architectural choices and tradeoffs

Versions inspected for architecture/provenance (not asserted to be mutually compatible verdict oracles):

| Implementation | Source revision or checked reference | Relevant design | Important caution |
| --- | --- | --- | --- |
| Official Lean 4 | [v4.35.0](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel) | Immutable shared runtime expressions, compact per-node metadata, staged WHNF/DefEq, strict inductive/recursor checking | Native C++ runtime semantics and resource accounting are not automatically copied by a Lean implementation |
| Lean4Lean | [67f63b0](https://github.com/digama0/lean4lean/tree/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3) | Kernel reimplementation in Lean, formal verification work and extensive bug/divergence study | Source similarity increases compatibility but can preserve shared semantic defects; verify actual theorem scope and version |
| Con-leche | [b47ea19](https://github.com/leanprover/con-leche/tree/b47ea19d6864a1fd09db6144528f91baa5c550dd) | An independently formalized checker and a set-theoretic consistency result in its verified mode | Its theorem, assumptions and input-mode restrictions do not transfer to C0 by analogy |
| nanoda | [f67473b](https://github.com/ammkrn/nanoda_lib/tree/f67473ba5f9397266f89c7852082c9c914b5d219) | Independent compact Rust term/checker design; useful performance and rejection oracle | Different exact exporter/kernel versions; implementation properties require source review |
| Sokonanoda | [e648a9f](https://github.com/intgrah/sokonanoda/tree/e648a9f7dfafd0fae67ba087007fcd8d6157a365) | Closure/normalization-by-evaluation techniques to reduce repeated syntax rebuilding | Performance results alone are insufficient, and historical Arena wrong acceptances make rejection gates mandatory |
| MathGraph | [Arena checker profile](https://arena.lean-lang.org/checker/mathgraph/) | Sokonanoda-lineage checker with measured recursor, environment and conversion improvements | Not an independent semantic rewrite; avoid double-counting as a separate oracle |
| PSKernel-C0 | [current branch](https://github.com/dwijayuda/pskernel/tree/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0) | Native Lean source checker, source-refined accelerators, owner-bound checked receipts, optional indexed substrate | Neither proven consistent nor yet qualified on complete Init, Std and Mathlib |

**Architectural decision:** Keep one authoritative source acceptance engine. Compare three complete checker *execution* alternatives under identical Lean-4.35 same-byte real checked exports: (A) recursive terms with cheap computed metadata and structural sharing, (B) owner-sealed indexed DAG with incremental typed results, (C) lazy closures/values plus reification and strict dependency/resource policy. Do not promote a syntax-only benchmark or a candidate partial evaluator as accepting authority. Independent soundness/refinement proof requirements precede switching engines.

Lean 4.35 also introduces `lake check`, `lake comparator`, and a `--paranoid` external-checker mode; these are candidates for *secondary checking gates*, subject to exact-version export and axiom-policy compatibility. It removes historical native `Lean.reduceNat`/`Lean.reduceBool`; avoid carrying 4.34 semantics forward implicitly. See [Lean 4.35 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/).

## 4. Findings and risks (no speculative false accepts)

| ID | Classification | Evidence and root cause | Status, correctness boundary, next proof |
| --- | --- | --- | --- |
| C0-AUD-01 (P1) | **Confirmed assurance coverage gap** | [External Arena run 38994521898](https://github.com/dwijayuda/pskernel/actions/runs/38994521898): **193/193** September 2026 cases were `unsupported`/declined under C0's native 4.35 pin; **0/193** qualified as actual case acceptance/rejection. Native 4.35 controls were **7/7**. Historic source headers are not the native 4.35 format; `arena_conformance.py` already reports `full_coverage=NOT_ESTABLISHED` and [C0_ARENA_PSC0_V72_PORTABILITY_GATES.md](C0_ARENA_PSC0_V72_PORTABILITY_GATES.md) documents this limitation. | This is **not** a semantic kernel failure. Keep immutable archive as version-integrity negative test. Re-export the original, reproducible Arena-*source* cases at 4.35 into a *different* coverage denominator; demand true official/C0 matched verdicts. |
| C0-AUD-02 (P1) | **Unqualified compatibility coverage** | Strict [123,090-record](https://github.com/dwijayuda/pskernel/actions/runs/38993186413) `Array.toList_reverse.go._unary` dependency accepted; strict [499,130-record](https://github.com/dwijayuda/pskernel/actions/runs/38992902255) isolated Init dependency accepted with host time budget increased. Full **6,452,982-record Init**, Std and Mathlib have **not** been qualified. | Do not present the isolated dependency result as full Init acceptance. Complete a native 4.35 *whole-Init* persistent replay with exact verdict and resource classifications, then Std/Mathlib. |
| C0-AUD-03 (P2) | **Confirmed proof-body throughput deficit** | Native proof sampler [38991331625](https://github.com/dwijayuda/pskernel/actions/runs/38991331625) observed checked-app/recursive inference in **19/19** sampled stacks, lambda **16/19**, Pi **12/19**; counts are inclusive frames, not CPU shares. Real Array proof has **24,520** distinct handles, including **24,138 application nodes**. | Focus on source-equivalent subexpression reuse, binder substitution and checked inference across shared syntax, not speculative scalar fingerprints. Require exact context/state/fuel equivalence and matched whole-operation A/B. |
| C0-AUD-04 (P2) | **Confirmed ineffective optimization family** | Source-hash depth-5, staged bucket hints, app-arity-only hints and sparse-spine experiments yielded negligible improvement or regression on same-runner accepted Array proofs; see [AI_WORK_STATE.md](AI_WORK_STATE.md). The latest source-proven immutable atom leaf bypass showed ~**1–2%** improvement on one accepted Array proof. | Keep the simpler proof-carrying implementation and reject unmeasured index layers. Latest [38994615300](https://github.com/dwijayuda/pskernel/actions/runs/38994615300): baseline **6:45.52**, leaf variant **6:37.32**, same runner and exact proof (single run, not full-library estimate). |
| C0-AUD-05 (P1, historical formal model only) | **Confirmed external specification defect; no C0 executable false acceptance established** | Older proof branch `PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic` lacked infer-type/proposition premises; historical `JudgmentAdequacy.lean` demonstrates universal relation. Current C0 `Checker/Knot.lean` has infer/type tests and did not import that judgment. See [C0_PROOF_FINDINGS_AUDIT.md](C0_PROOF_FINDINGS_AUDIT.md). | Repair the formal model in its proper branch and prove graded recursive checking against an adequate judgment. Do **not** call this a remaining executable C0 bug or weaken current C0 proof irrelevance. |
| C0-AUD-06 (P1, fixed in native C0) | **Previously confirmed FVar semantic-cache scope defect** | Previous proof-guided inspection found local-context cache reuse risks. Native `Checker/State.lean` now restores parent 5 expression caches and 2 pair caches on local scope exit; `CachePolicy.lean` forbids semantic cache transport of FVar-containing syntax. Qualified [native CI 38951397701](https://github.com/dwijayuda/pskernel/actions/runs/38951397701). | Preserve regression and all-context source refinement proofs; seek independent general cache-context soundness proof, not a new quick fix. |
| C0-AUD-07 (P1, closed representative cases) | **Adversarial recursor and elimination validation** | [Native Arena CI 38994521942](https://github.com/dwijayuda/pskernel/actions/runs/38994521942) truly rejects official-negative `imaxPropBadFalse` and `largeElimBoom`, and accepts native `Or.rec` and mutual prefix. Two forged metadata variants were **unsupported**, not semantically rejected. | Extend **native 4.35 re-export** of upstream `k-rec-conv` and `proj-non-structure`, two different bug classes. Refuse approval if source generation fails, official reference does not reject, C0 accepts, or no C0 rejection is obtained. Other historical dynamic-hash `rec-missing-ih` exploits must remain frozen **old-version static export** (regenerating changes the exploit), not spurious adapted positives. |

Severity here ranks verified *assurance and engineering risk*; it does **not** imply any confirmed current invalid-proof acceptance. No P0 executable false accept was found by the inspections recorded here.

## 5. High-risk invariants and reproduction plan

1. **DefEq and reduction:** Same-state/same-fuel success checks, recursive WHNF, left/right lazy delta, proof irrelevance, eta/K-like reduction, context-sensitive fresh names. Adversarial `rec-missing-ih`, `proj-of-stuck-prop`, `k-rec-conv` are useful *distinct* classes; preserve their precise exported versions and expected status. Prove each acceptance shortcut against the source algorithm before constructing independent semantic soundness proofs.
2. **Recursor generation:** Strict positivity, mutual and nested recursors, rule-argument count, motive universes, `k` flag, complete reconstruction of generated rule RHS, type preservation. Fuzz exact exported recursor metadata, never rely on raw user annotations. Negative `unsupported` is unqualified, not proof of rejection.
3. **Scope and cache:** Structural vs pointer equality, hash collisions as index selectors only, definite equality proof on hits, FVar/mvar/binder namespace ownership, local scope teardown, environment update semantics. Preserve clean exception boundaries for resource, malformed, unsupported and actual rejection.
4. **Exports and admission:** The raw bytes, header target, per-node indices, generated declaration metadata, axiom policy, atomic environment updates and checked-root publication must be pinned. The separate portable parser is part of the security boundary and cannot silently accept old Arena formats.
5. **Performance:** Measure actual source-checker phases in one run, avoiding inclusive-frame-samples-as-CPU% and expanded-DAG-counts-as-runtime. Track per-type checked inference call counts, exact-expression comparisons after hash collisions, binder instantiations, and full WHNF/DefEq invocation counts.

## 6. Minimal trustworthy target architecture

```text
Pinned, untrusted Lean export bytes (versioned; cryptographic provenance)
          |
          v
Total parser + version/format gate --> malformed / unsupported
          |
          v
Validated declaration and canonical expression representations
          |
          v
Validated environment snapshot + explicit allowed axioms
          |
          +--> optional syntax owner-sealed DAG / scratch store (NO admission authority)
          |
          v
Source-authoritative checked inference <--> WHNF / DefEq / recursors
          |                                      ^
          +--> optional source-refined acceleration (pure results only)
          |
          v
Strict declaration admission + atomic checked environment history
          |
          +--> checked-root ownership receipts / audit trail
          |
          v
Accepted declaration / rejected / resource exhausted / inconclusive
```

**Trust budget:** parser and decoder, kernel definitions and native computation, permitted axioms and special capabilities, checker resource policy, and any compiler/runtime behavior used to execute the kernel must be inventoried. Checked receipts currently witness **execution of source checker**, not independent mathematical soundness. An optional purely specified reference checker and set-theoretic model may shrink the *semantic* trust gap later, but should not duplicate acceptance paths casually.

## 7. Correctness and performance work sequencing

1. **P0 security stop rule:** Every independently demonstrated false acceptance halts promotion of affected kernel rules and receives a minimized exact-version negative regression, root-cause repair and independent verification. No such current C0 exploit has been reproduced by this research checkpoint.
2. **P1 version-matched negative coverage:** Keep historical archived Arena SHA-qualified but `unqualified=193`; broaden matched 4.35 replay tests with upstream-authored source. Add genuine different recursor/projection classes and explicit per-case official-vs-C0 verdicts. Do not regenerate known **hash-dependent historical static exports** as if the same exploit were preserved.
3. **P1 complete compatibility:** Advance original 4.35 Init→Std→Mathlib *full checked* replay (not merely isolated subdependency or parse success) under bounded explicit resource budgets; log first exact failing declaration, original bytes and parser/semantic classification.
4. **P2 hotspot reduction:** Start with repeated checked application/lambda/Pi recursion and binder substitution on real Array proof; prototype a single coherent indexed/metadata-rich checked inference operation with precise source proof. Reject special-case policies lacking > noise-level repeatable whole-operation improvement.
5. **P3 proof strengthening:** Prove pure infer/WHNF/DefEq/admission correspondence under full contexts and explicit allowed-axiom policy; separately study a model-consistency theorem and the gap to runtime/decoder correctness. Learn from Lean4Lean/con-leche *without inheriting their unproved or version-specific assumptions*.
6. **P4 PSC0 v7.2 migration readiness:** Only after semantic/throughput gates, list required language features and exact runtime/FFI assumptions. Do not change accepting code to match hypothetical self-hosting requirements before the current kernel is qualified.

For each gate report: commit, toolchain and exporter commit, exact export SHA and record counts, official verdict, C0 verdict, resource settings, distinct source proof/test evidence, and (when performance) same-runner A/B wall/RSS samples.

## 8. Current engineering change accompanying this audit

[Updated targeted native Arena workflow](../../../.github/workflows/pskernel-c0-arena-adversarial435.yml) adds PR-based qualification and **two separate third-party-authored bug classes**:

- `k-rec-conv`: K-like recursor conversion incorrectly considered definitional equality.
- `proj-non-structure`: projecting from a non-structure inductive proposition.

Each test is fetched from immutable upstream source `5d7ca987618f1136aaa296057b50a2c10c4ce77a`, rebuilt with the **real Lean 4.35.0** toolchain, exported with the pinned exporter, verifies the exporter/version header, requires the official `leanchecker --from-export` to **reject**, and requires C0 itself to **reject** the *identical* NDJSON export. Thus a silent version decline, host error, false acceptance, or mere parser skip cannot pass.

**Qualification is PENDING until a terminal CI job proves these two new cases on this exact branch/commit.** No new checker acceptance rule, semantic fast path, compiler code, Rust experiment or self-host implementation was modified.

### Final disposition

This is **partial, evidence-based completion of the requested large research program**, not closure of full Lean correctness, a consistency theorem, performance parity or the full Init/Std/Mathlib corpus. The present engineering return is a risk-ranked audit and targeted native negative-gate expansion. Continue from the scoped, source-grounded defects above; preserve other concurrent C0 work.
