# PSKernel-C0 architecture-first execution plan — C → D → E, then B → F → G

**Decision:** 2026-10-13. Architecture-first development is authoritative for the native C0 workstream.  
**Scope:** `dwijayuda/pskernel`, branch `perf/pskernel-c0-v7-rust-20261012`, `psc0/packages/pskernel-c0/`; native Lean 4.35.0 only.  
**Non-goals:** no changes to original `pskernel-core`, PSC0 compiler, generated Rust, Wasm/self-host or metatheory during C–E construction.

## Decision and bounded evidence freeze

Phase B's **exhaustive compatibility exit gate is deferred, not waived**. Preserve all official identical-byte accepted/rejected fixtures, real Init export digest, strict unsupported/rejected/resource distinctions and the independently verified accepted 79,416-record prefix. Preserve the known false rejection at record 86,383 (`Std.PRange.UpwardEnumerable.succMany?_add`) as an open regression. The native [CI 38395502669](https://github.com/dwijayuda/pskernel/actions/runs/38395502669) and real [CI 38395528602](https://github.com/dwijayuda/pskernel/actions/runs/38395528602) both passed on their explicit bounded gates, **not full Init acceptance**.

The full `Init` source is 6,452,982 exported records, 57,919 declarations, 345,690,182 bytes, pinned to Lean 4.35.0 and `lean4export` `5a9a355d`; the official Lean checker accepts it. C0 currently accepts an independently gated *prefix*, not this corpus. Documentation-only commits are not executable qualification.

## Clean architectural choices

**No historical architecture lock-in.** Evaluate three implementations on the same complete checked workload and identical source semantics: (A) lean-native shared recursive expressions, (B) canonical persistent/scratch indexed handles, (C) lazy closure/value execution. Pick a source/arena/closure hybrid only where measured costs, semantic clarity and resource behavior justify it. Never equate a syntax DAG microbenchmark with checker throughput.

**One coherent authority boundary.** A source-checked declaration is valid only if the accepting checked-session implementation has admitted it. The optional closure/arena executor is *not* a checked judgment or proof certificate. Candidate evaluation may produce diagnostic observations only, not admission, proof receipts or build artifacts. Failures classified as malformed, unsupported, resource-exhausted and rejected-invalid remain distinct.

**Cache ownership and invalidation.** A cache key must include all relevant environment revision, local scope, reduction/eager policy, universe instantiation, fuel semantics, safety policy and term ownership. No WHNF/DefEq/type cache can be transported across unqualified environment extensions; provisional mutual declarations are especially sensitive. Source-side syntax-only canonical caches may be shared across contexts only after exact structural equality.

## C: representation and ownership

- Keep source `PsKernelExpr` as independent oracle; introduce private execution terms with explicit provenance (persistent immutable base and disposable scratch lifetimes).
- Enforce acyclic children-before-parents, persistent-to-persistent edges, checked hash collision behavior, immutable abort, selected-root promotion and strict whole-store readback. No externally supplied raw Nat handle determines semantic equality across stores.
- Define a compact execution-state interface independent of source substitution, with explicit resource accounting. Begin with operation-local ownership, then evaluate packed/tagged handle representation against native structural sharing.
- **C exit:** whole-operation benchmarks and error-category equivalence plus an auditable `StoreWF` contract. Formal proof is Phase G; no accepting indexed result until then.

## D: closure/value weak-head evaluator

- Establish an evaluation machine with explicit control closure, delayed environment substitutions, and argument spine. Reduce β and ζ without eagerly reconstructing the entire application spine. Distinguish neutral value, lambda closure, unsupported form and exhausted resource.
- Add typed handling of local binders, constants and universe application, projection, primitive numerals, quotation, recursors and transparency policy as separate coherent families. For any unqualified family, return an explicit decline and use the authoritative checker instead.
- Source reification must be capture avoiding; compare exact β/ζ/metadata behavior and resource/error classes against source WHNF. Never assume absence of syntactic target names proves absence under δ reduction.
- **D exit:** checked evaluator semantics for the supported Lean 4.35 closure; all actual source forms have positive/negative differential tests and bounded resource behavior.

## E: one accepting checker

- Connect the selected engine to one WHNF/DefEq/inference/proof/admission pipeline with explicit trusted boundary. The candidate may accelerate only operations whose complete context and semantic equivalence are qualified.
- Preserve full binder, universe, proof irrelevance, quotient, inductive, recursor, local, literal and safety semantics. Admission must be atomic: a failed mandatory check leaves the preceding environment intact.
- Remove duplicated historical fast paths only after broad positive and negative qualification; never add fallback acceptance based on an unchecked candidate.
- **E exit:** complete coherent accepting kernel over the planned scope, independent same-byte differential CI and resource/error equivalence. Passing only a small synthetic slice does not qualify E.

## Phase B after E

Resume complete pinned `Init` acceptance, then Std and Mathlib with known unsupported features and independent negative cases. Zero false acceptance is mandatory. Treat out-of-fuel as computational failure, not a logical rejection. The record-86,383 counterexample is a regression fixture, not something to bypass.

## F and G

F: independently measure Lean 4.35 official, project-local original, con-leche, con-ron and C0 on identical *fully checked* corpora with p50/p95 time, allocation bytes/events, RSS, memory lifetime, cold/warm and error rates. Do not assert a competitive ranking from unequal datasets.

G: prove source/optimized denotation, substitution/reification, canonical-store invariants and sound refinement or connect an independent verified acceptance gate. Consistency is a theorem under explicit axioms, not inferred from green tests.

## CDE-0 executable foundation (2026-10-13)

The architecture-first route has moved beyond planning. `Architecture/Execution.lean` now contains explicit control closures, delayed binder environments and an argument-spine machine for small syntactic β/ζ/metadata WHNF. `Architecture/Work.lean` implements an exact validated scratch syntax transaction, source-authoritative preview/check and atomic declaration admission through the existing checked kernel, with fresh session caches after environment changes. New `C0ArchitectureExecutionRegression.lean` and `C0ArchitectureWorkRegression.lean` run as mandatory native CI steps. Passing their small coherent source-differential slice establishes no formal refinement, full optimized WHNF or new accepting kernel. Source-owned proof checking remains the exclusive admission authority.

## CDE-1 — environment-aware lazy delta (2026-10-13)

`Architecture/Delta.lean` extends the closure/spine candidate with one source-owned, safety-guarded delta step on precisely reified syntax at a stuck constant head. It reenters the lazy execution machine for subsequent β/ζ steps, preserving an explicit reduction and quotation budget; partial/unsafe definitions are declined, opaque constants remain neutral. `Architecture/Work.lean` exposes `psKernelC0ArchitecturePreviewDelta`, which always computes the authoritative checked WHNF **first** and never publishes the candidate result as a proof. The mandatory `C0ArchitectureDeltaRegression.lean` checks direct/chained and universe-parametric aliases, delta-to-lambda β, ζ, non-reducible opaque heads, malformed/unsafe policy and fuel exhaustion. This is still a **non-accepting partial evaluator**, not complete Lean WHNF or Phase D exit acceptance.

## CDE-2 — lazy primitive Nat literal spine (implementation pending qualification)

The source-authoritative `Execution`/ `Delta` pipeline now includes `Architecture/NatLiteral.lean`, a **candidate-only** operation family. On a stuck primitive Nat head, it reifies only required delayed numeral arguments and delegates arithmetic and size/count limits to the already existing source primitive functions. When no Nat primitive head is recognized, it does **not** quote unrelated neutral arguments. Candidate evaluation tries this family before δ as the source WHNF pipeline does. Nonliteral arguments, full recursive primitive WHNF, projections, Quot, recursors, and full local-context reductions remain outside this feature boundary.

The mandatory delta regression was extended to all 14 binary primitive operation names, successor, captured β/ζ operands, neutral heads, explicit zero fuel and limited numeral size; a non-accepting result cannot enter checker admission. The code was pushed, but there is **no independently confirmed CDE-2 native CI success yet**: do not confuse the prior CDE-1 run 38412434965 with CDE-2 qualification. The next required gate is native compilation and successful source-differential/negative checks on the new HEAD. C, D and E remain incomplete.

## CDE-3 — local context and constructor-head projection (code pushed; CI pending)

`Architecture/Structural.lean` adds a single dispatcher on top of the CDE-2 closure machine, preserving β/ζ, primitive Nat, δ, and the existing checked authority seam. When the machine head is a local `fvar`, only source local-let declarations unfold; hypotheses are neutral. When the head is a `proj`, the delayed scrutinee is reified exactly and the **source** `psKernelReduceProjCore` checks constructor metadata and selects the field with the correct parameter offset. This is a bounded fast WHNF family; it does not recursively normalize a projection scrutinee yet. Unsupported scenarios remain candidate/source disagreements, never checked acceptance.

The mandatory native regression now includes local-let shadowing, constructor field projection with parameter offset, wrong type/index neutrality, β/ζ capture, and zero fuel, plus source-exclusive structural preview and ill-typed rejection tests. Constructor metadata injected by test code is for source-WHNF comparison only, **not inductive declaration admission**. This is implementation evidence, not compilation/CI qualification: previous success 38412434965 predates both CDE-2 and CDE-3. Architectural next step is one shared fuel-threaded nested-demand evaluator rather than ad hoc recursor/Quot helper fallbacks. Full C/D/E exit remains unclaimed.

## CDE-4 — shared-fuel nested demand stack (code pushed, qualification pending)

To avoid building another recursive evaluator with reset per-premise budgets, `Architecture/Demand.lean` adds continuation frames to the existing closure/spine machine. A source-recognized Nat head may demand one or two operands; a projection may demand its scrutinee. Each nested descent, return and primitive/structural transition consumes **the same** structurally recursive transition fuel. Source arithmetic size policy and source projection-selector metadata are reused, but *source WHNF* is never invoked within the candidate evaluation loop. When an operand remains stuck, the exact parent head/spine is restored, preserving source-visible weak-head syntax.

Integration through `Architecture/Work.lean` remains preview-only: the checked session normalizes first; candidates never issue checking verdicts or admission. Mandatory native regression fixtures now cover nested Nat, projection β/ζ majors, projection-as-operand, local lets, neutral/nonmatching heads and low shared fuel. CDE-2, CDE-3, and CDE-4 have **no newly confirmed passing native CI** in this session; [38412434965](https://github.com/dwijayuda/pskernel/actions/runs/38412434965) is a prior CDE-1 checkpoint. CDE-4 does not implement quotient/recursor, full typing/DefEq, globally metered quotation allocation, or C/D/E exit criteria.

**Next gate:** native Lean 4.35 compilation and exhaustive current mandatory source/negative tests, then a semantics-driven quotient/recursor demand extension with one fuel policy. Do not claim independent checked equivalence, whole Init compatibility or verified soundness from this partial candidate.

## CDE-5 — quotient major-demand and qualified CDE-2–5 (2026-10-14)

`Architecture/Demand.lean` now carries Quot.lift and Quot.ind major premises through the existing single-operation fuel/continuation stack; reduction requires the source quotient-initialized flag and exact `Quot.mk` three-argument shape. Function/representative selection and additional application arguments follow the source quotient reduction rule. Unlike Nat primitives, quotient eliminators have universe arguments; the head-dispatcher explicitly checks them before applying the Nat empty-level guard. Synthetic positive/negative source-WHNF differential tests cover lift, ind, nested β/ζ major, quotient result consumed by Nat, surplus args, wrong/missing constructor shapes, no initialization, and budget decline. The source checker is still the sole trusted judgment path.

**Qualified source:** [`e2eaac64`](https://github.com/dwijayuda/pskernel/commit/e2eaac64e8a17325c847e761c62d36a00e440639), full [native CI 38439633705](https://github.com/dwijayuda/pskernel/actions/runs/38439633705) **SUCCESS**. Compilation, source differentials CDE-0–5, official replay fixtures, negative conformance, performance microbenchmarks and independent original-core comparison passed. Prior CDE-2/3/4 historical notes saying 'CI pending' are superseded for their *bounded feature slices*. This is **not** complete Phase D/E qualification, formal refinement, full real Init/Std/Mathlib C0 acceptance, real Quot-admission proof, or competitive full-workload benchmark evidence.

Next architecture focus: ordinary recursor-major demand with precise constructor-rule/universe/fixed-argument semantics and careful K/literal cases, plus globally metered quotation and gradual consolidation of candidate-only execution before any accepting integration.

## CDE-6 — non-K constructor and Nat-literal recursors (2026-10-14)

The candidate continuation evaluator now recognizes source environment `recInfo` before the specialized zero-level Nat primitive gate. It does not admit K or unsafe recursors to the ordinary iota rewrite. A major premise is evaluated in the *same* fuel loop. Ordinary recursor rules are selected from the source environment, with exact occurrence universe instantiation, fixed parameter/motive/minor arguments, trailing constructor fields and surplus recursor arguments. Nat literals are normalized to `Nat.zero`/`Nat.succ` constructor shapes for rule matching; String-literal constructor expansion and structure/K handling are deferred.

Mandatory source-WHNF differentials exercise direct and β/ζ-major constructors, Nat zero/succ, polymorphic RHS, fixed argument ordering, constructor parameter skip, wrong names/arities, low fuel, and explicit K/unsafe policy distinction. The source checker remains the only authority for admission.

**Executable qualification:** [`7917de8a`](https://github.com/dwijayuda/pskernel/commit/7917de8a0f9ad08a967f3399599bbaa665bcb4d7), full [native CI 38441627839](https://github.com/dwijayuda/pskernel/actions/runs/38441627839) **SUCCESS**, including original-vs-C0 checker comparison. These are bounded experimental source differentials with synthetic WHNF fixtures, **not** complete Phase D/E, real checked inductive-recursive conformance or formal soundness evidence. Next: coherent K/structure/String families and one globally metered closure/resource contract, followed by whole-checker integration without candidate acceptance shortcuts.

## Milestone order and current first slice

1. Freeze existing B acceptance evidence and the counterexample (done).
2. **C/D foundation:** implement a separately compiled candidate evaluator using explicit control closure, delayed environment and argument stack. Initially handle only syntactic β/ζ/metadata and neutral heads, not delta/recursors. No trusted emission.
3. **C/D differential gate:** compare that candidate against source-owned WHNF on closed and appropriately scoped terms, including negative resource and binder cases. Keep source authority.
4. Extend coherent type/recursor/equality families with controlled ablations, then implement E end-to-end.
5. Return to Phase B and complete full-library conformance before qualifying performance or formal assurance.

**Current status:** architecture first approved; C–E implementation is ongoing, none of C–E may be declared complete on the basis of this plan or its initial candidate engine.
