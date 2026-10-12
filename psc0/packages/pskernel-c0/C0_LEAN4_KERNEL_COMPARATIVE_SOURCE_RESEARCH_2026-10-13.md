# PSKernel-C0 comparative source research: Lean 4 and independent kernels

**Research date:** 2026-10-13 (Asia/Jakarta).  
**Scope:** public open-source compiler/kernel correctness and architecture research, not a soundness proof or implementation acceptance.  
**PSKernel-C0 repository:** https://github.com/dwijayuda/pskernel  
**Working branch:** perf/pskernel-c0-v7-rust-20261012  
**Reviewed source HEAD:** 497df6a39947aa3532b2d1a6ffe84342125fd2fc  
**Latest native qualifying CI:** https://github.com/dwijayuda/pskernel/actions/runs/38305932773 (success)  
**Compatibility target:** Lean 4.34.0.  
**Prohibited workstreams in this phase:** no self-hosting, generated Rust, bootstrap/fixed-point, metatheory or consistency tests; no original pskernel-core/PSC0 compiler/Rust backend modifications.

## 1. Executive verdict

PSKernel-C0 already has a working native-Lean accepting checker with substantive source-level performance improvements, including checked wide/dependent application inference, binder-heavy DefEq, checked let/zeta inference, and specialized WHNF. Its new canonical indexed expression store, memoized indexed lifting and substitution, share-aware decoding, level instantiation, context-sensitive delta/local-let/projection/Quot fragments, and persistent indexed diagnostic sessions are real and tested engineering work. **They are NOT a complete indexed accepting kernel.**

The central architectural conclusion of this study: **A global, hash-consed indexed DAG should not be assumed to be the correct final evaluation engine.** The official C++ Lean 4 kernel benefits from runtime-managed immutable sharing plus per-node metadata, tight substitution routines and carefully scoped caches. Con-leche achieves a proven consistency result using an independent Lean term type and cached computed fields while explicitly avoiding a global hash-cons table. Rust Sokonanoda/MathGraph derive their most distinctive performance from closure-based value evaluation and conversion, not just an indexed syntax table. They are valuable alternatives to benchmark under identical, complete checked workloads.

A second conclusion: **matching the unchanged repository-local pskernel-core is necessary regression evidence but not independent proof of exact Lean 4.34 behavior.** Both checkers share lineage. Official v4.34.0, Lean Kernel Arena, and a materially independent checker must be added as external acceptance references.

A third conclusion: con-leche's consistency theorem proves its own checker in its **verified** mode under a set-theoretic model and restricted axiom policy. It is not a transferable theorem for arbitrary PSKernel-C0 code, untrusted raw IDs, optional indexed fragments or unrestricted axioms.

## 2. Source and version inventory (reproducible snapshot)

| Project | Source reference studied | Architecture role |
| --- | --- | --- |
| Official Lean 4 | [leanprover/lean4 v4.34.0, 293d5d0](https://github.com/leanprover/lean4/tree/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel) | Authoritative v4.34.0 acceptance/rejection and source semantics |
| Lean4Lean | [digama0/lean4lean 67f63b0](https://github.com/digama0/lean4lean/tree/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3) | Lean implementation with correctness-development and declared divergences |
| con-leche | [leanprover/con-leche 3b37939](https://github.com/leanprover/con-leche/tree/3b37939f0d9d37bfd86299dc92d9a97fbacba29e) | Model-consistency-verified Lean checker and performance alternative |
| Nanoda | [ammkrn/nanoda_lib 7357334](https://github.com/ammkrn/nanoda_lib/tree/735733408022619f5ccf2133e34dd002e8ae861c) | Independent Rust external checker |
| Sokonanoda | [intgrah/sokonanoda e648a9f](https://github.com/intgrah/sokonanoda/tree/e648a9f7dfafd0fae67ba087007fcd8d6157a365) | Closure-based Rust value/conversion engine |
| MathGraph | [metalogiclabs/mathgraph-lean-kernel flash 78c7502](https://github.com/metalogiclabs/mathgraph-lean-kernel/tree/78c7502bac8a5ba000057b3f083bc0595ac65750) | Nanoda-family, closure-based, profiling-driven experimental checker |
| Lean Kernel Arena | [September 2026 archived round](https://arena.lean-lang.org/round/2026-09/) | Controlled external suite and full-corpus performance reference |
| PSKernel-C0 | [dwijayuda/pskernel 497df6a](https://github.com/dwijayuda/pskernel/commit/497df6a39947aa3532b2d1a6ffe84342125fd2fc) | Target of the comparison; native Lean 4.34 |

**Version warning:** Lean4Lean master at the inspected commit pins leanprover/lean4:v4.33.0-rc2; con-leche master pins v4.35.0-rc3. Their source design is informative but their exact verdict behavior is not automatically a Lean 4.34.0 oracle. September Arena checker revisions also differ from some inspected repository HEADs. Do not compare raw timings across different rounds or claim exhaustive compatibility from cross-version matches.

**Another distinct tool:** [leanchecker](https://github.com/leanprover/lean4checker) is the official kernel environment replay facility distributed inside Lean since v4.28.0. It replays declarations through Lean's kernel; it is **not** an independent second kernel implementation. It is still a useful official acceptance reference for supported compiled Lean artifacts.

## 3. Official Lean 4 kernel: source-level architecture

Primary code: [type_checker.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/type_checker.cpp), [type_checker.h](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/type_checker.h), [expr.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/expr.cpp), [expr_eq_fn.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/expr_eq_fn.cpp), [environment.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/environment.cpp), [inductive.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/inductive.cpp), [quot.cpp](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/quot.cpp).

### 3.1 Term representation and low-level execution

Official expressions are runtime-managed immutable, shared expressions. The C++ wrappers use Lean runtime constructors and accessors. A per-node packed data word supplies a hash, approximate depth, loose de Bruijn-variable range, and flags for free variables, expression metavariables, universe metavariables and level parameters; many operations can read this in O(1). Expression comparison checks pointer identity first, then hash equality, then structural fields, and memoizes comparison pairs for shared nodes. Rewrites reuse unchanged source nodes.

This is **not** equivalent to mandatory global hash-consing of every expression. Pointer sharing, cheap metadata and specialized traversal reduce much of the same repeated work without always paying a canonicalization index cost.

**PSKernel-C0 contrast:** authoritative PsKernelExpr is a recursive Lean inductive. Its source expression hashes are recomputed recursively in some accepted-cache paths; the experimental store has per-node exact hash, checker-compatible hash, depth and looseBVarRange but is still opt-in. Its custom radix trie uses four 16-way levels and a source hash modulo 65521, so wide distinct working sets can create expensive collision buckets even though exact comparisons protect correctness. C0 currently lacks equivalent per-node cheap has-level-param / has-fvar flags and the official packed-word representation.

### 3.2 Type checking and conversion

Official state contains separate inference-only and checked inference caches, core WHNF and full WHNF caches, delta unfolding, and positive/negative definitional-equality pair sets. The C++ state is tied to an environment and a fresh-name generator; the checker carries a local context, safety, universe level parameters and eager-reduction mode.

Crucial detail: [type_checker.h lines 33-39](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/type_checker.h#L25-L42) explicitly rejects blindly replacing successful DefEq pairs with an equivalence-closure/union-find cache, because the algorithm is a **sound but incomplete semi-decision procedure** whose success relation can be sensitive to resource/evaluation order. C0's existing exact pair-set approach is a conservative and useful choice. Lean4Lean uses an EquivManager/union-find with its own implementation and proof obligations; copying it without its invariants would be unsafe.

The official DefEq pipeline includes fast structural checks, binder-domain/body conversion, cheap projection-aware WHNF, proof irrelevance before potentially expensive unfolding, lazy two-sided delta, staged projection comparison, application congruence, function and structure eta, string-literal expansion, and unit-like conversion. Reduction priority is behaviorally significant; a different evaluator that eventually reaches a superficially equivalent expression may not preserve fuel, errors or false-rejection behavior.

The official checked application path checks head Pi type and each argument; inference-only uses faster application-spine traversal. PSKernel-C0 already mirrors this distinction and has meaningful checked wide-application optimizations in the authoritative recursive checker.

### 3.3 WHNF, trusted primitives and resources

Official WHNF has a cheap core reduction phase (beta, zeta, metadata, local-let, projection, inductive/quotient hooks), plus native reduction, Nat arithmetic and delta. The cheap projection and cheap recursor flags deliberately change how deeply major premises are normalized. Delta unfolds with exact universe level instantiation and a context-local cache. Native Lean.reduceBool/Lean.reduceNat invoke the reference kernel's runtime native evaluator; this is a special trusted capability, not an ordinary reduction inferred from syntax.

Runtime recursion checks, interruption/heartbeat accounting, definition safety, fresh-name generation, and exact error ordering matter. C0's Nat fuel and maxRecDepth policy are useful explicit controls, **not evidence by themselves** that the values or precedence exactly reproduce official v4.34's runtime limits. Differential tests with the sibling core do not close this external parity gap.

### 3.4 Declaration validation and inductives

Official environment admission checks universe parameters, header sorts, metavariable/free-variable exclusion, declaration safety, and body type equality before committing. Unsafe recursive definitions and mutual blocks use temporary/work environments; failed validation must not mutate the prior immutable environment.

Inductive processing checks positivity, constructors, elimination restrictions, generated recursor types, and whether recursor computation rules are **type preserving** (not merely typable). C0's native paths [RecursorValidation](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/src/Ps/KernelCore/Admission/Inductive/Common/RecursorValidation.lean), mutual recursor validation, and nested recursor validation contain analogous checks: a genuine architectural strength. Exact full v4.34 acceptance/rejection, nested transformations and recursor K/iota behavior are still unqualified externally.

## 4. Source comparisons across other checkers

### 4.1 Lean4Lean: implementation fidelity plus theorem-development

[TypeChecker.lean](https://github.com/digama0/lean4lean/blob/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3/Lean4Lean/TypeChecker.lean) closely reconstructs the official typing/WHNF/DefEq pipeline in Lean, carries context through ReaderT and state through StateT, uses Lean.Expr with existing runtime-backed hash/metadata, and has a dedicated recursion/fuel configuration. [EquivManager.lean](https://github.com/digama0/lean4lean/blob/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3/Lean4Lean/EquivManager.lean) implements structural/equality acceleration using union-find.

[Verify](https://github.com/digama0/lean4lean/tree/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3/Lean4Lean/Verify) contains substantial correctness and metatheory work. This is valuable for organizing C0's eventual verification boundaries, but not an already established C0 soundness theorem.

Read [divergences.md](https://github.com/digama0/lean4lean/blob/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3/divergences.md) carefully: Lean4Lean explicitly diverges from C++ in universe normalization/decidability and some optimizations, and does not implement native reduceBool in the same way. Thus it is a strong comparison and research reference, **not automatically an exact acceptance/rejection oracle** for v4.34.0.

### 4.2 con-leche: independently model-proven consistency

[README](https://github.com/leanprover/con-leche/blob/3b37939f0d9d37bfd86299dc92d9a97fbacba29e/README.md), [Kernel/Expr.lean](https://github.com/leanprover/con-leche/blob/3b37939f0d9d37bfd86299dc92d9a97fbacba29e/ConLeche/Kernel/Expr.lean), [Cached/StateC.lean](https://github.com/leanprover/con-leche/blob/3b37939f0d9d37bfd86299dc92d9a97fbacba29e/ConLeche/Cached/StateC.lean), [Kernel/Core.lean](https://github.com/leanprover/con-leche/blob/3b37939f0d9d37bfd86299dc92d9a97fbacba29e/ConLeche/Kernel/Core.lean), [MainTheorem.lean](https://github.com/leanprover/con-leche/blob/3b37939f0d9d37bfd86299dc92d9a97fbacba29e/ConLeche/MainTheorem.lean).

Con-leche uses its **own** expression type, locally nameless free variables carrying a de Bruijn level and type, no expression metavariables or metadata in its normalized internal terms, and per-node computed hash/ranges/flags. The current implementation intentionally does **not** use the large global expression hash-cons table. It obtains cheap memo keys through cached computed fields and pointer-first/exact equality.

The core is designed with open recursion and a record of checker operations shared by pure and cached instantiations; a refinement bridge connects the executable cached checker to the verified semantics. On environment transitions, context-dependent memo tables are flushed while independently valid level-operation caches can survive. This is directly relevant to C0's session redesign.

The proved theorem is about **accepted inputs in verified mode**: their declarations admit a model in the specified set theory, with the corollary excluding a proof of False. The model uses assumptions such as sufficient inaccessible cardinals and the checker restricts accepted axioms to propext, Classical.choice and Quot.sound, with pinned prelude behaviors. The alternate trusted mode is not covered by that theorem. The current theorem does not establish arbitrary PSKernel-C0 soundness, exact official C++ compatibility for every accepted input, or whole-binary correctness independent of trusted runtime/compiler assumptions.

**Proof adaptation option:** redesign C0 to share an explicitly modeled kernel judgment with con-leche and prove a refinement from the native C0 accepting code, or use con-leche in verified mode as an additional policy-gated acceptance checker. Simply reproducing its expression constructors or algorithms does not inherit the proof.

### 4.3 Nanoda, Sokonanoda and MathGraph: independent performance architectures

[Nanoda](https://github.com/ammkrn/nanoda_lib/tree/735733408022619f5ccf2133e34dd002e8ae861c/src) uses Rust expression handles, precomputed hashes, memoized instantiation/WHNF/inference/DefEq and environment-specific contexts. It is independent of the official C++ checker but may deliberately choose different algorithms and resource behaviors. Its conversion logic is a useful independent comparison for C0.

[Sokonanoda](https://github.com/intgrah/sokonanoda/tree/e648a9f7dfafd0fae67ba087007fcd8d6157a365/src/checker) uses closure/value evaluation, environment slots, rigid/neutral heads and elimination spines. A value can carry its environment and delayed body instead of immediately reconstructing a fully substituted source expression. Its implementation uses bump allocation, interning, pointer-aware caches and carefully controlled value comparison. The Arena build also uses profile-guided optimization and multiple checker threads.

[MathGraph](https://github.com/metalogiclabs/mathgraph-lean-kernel/tree/78c7502bac8a5ba000057b3f083bc0595ac65750/src) is a Nanoda-family derivative, not an independent rewrite; its conversion/value modules preserve the closure-based idea and add profiling-led optimizations. It is explicitly experimental.

**C0 implication:** test a **closure-based internal WHNF/DefEq value machine** as a realistic competing architecture against a globally interned syntactic DAG, rather than assuming the latter is the final performance winner. This does not require copying a Rust backend: the algorithm can be written in native Lean.

## 5. External performance evidence: pinned Arena round

[Lean Kernel Arena 2026-09](https://arena.lean-lang.org/round/2026-09/) is an archived, reproducible **same-round** comparison. Representative Mathlib corpus results:

| Checker | Mathlib wall time | Max RSS | Invalid / valid test coverage in round |
| --- | ---: | ---: | --- |
| Official Lean v4.34.0 | 32.9 min | 7.6 GB | 71/71 rejected, 130/130 accepted |
| Lean4Lean | 39.9 min | 9.3 GB | 71/71 rejected, 130/130 accepted |
| Nanoda | 18.0 min | 7.4 GB | 71/71 rejected, 128/130 accepted, 2 declined |
| Sokonanoda | 2.1 min | 5.9 GB | 71/71 rejected, 130/130 accepted |
| MathGraph | 2.0 min | 5.6 GB | 71/71 rejected, 130/130 accepted |
| con-leche | 22.3 min | 8.0 GB | 64/71 rejected, 7 declined; 124/130 accepted, 6 declined |
| PSKernel-C0 | **not submitted/qualified** | **not measured on Mathlib** | **not established** |

These are empirical checker runs under different build and parallelism configurations. Relative standings can change with input mix, compiler version, required trust policy and round. The very fast Rust results are an important architecture signal, **not** proof that a particular transformation alone is faster or sounder than the official kernel.

The Arena provides a small downloadable soundness/completeness corpus plus machine-readable results. C0 should integrate this corpus *before* attempting broad claims about full Lean kernel compatibility.

## 6. PSKernel-C0 current actual implementation inventory

Source: [pskernel-c0](https://github.com/dwijayuda/pskernel/tree/497df6a39947aa3532b2d1a6ffe84342125fd2fc/psc0/packages/pskernel-c0).

| Capability | Current accepting C0 | Experimental indexed C0 | Qualification |
| --- | --- | --- | --- |
| Exact syntax + universes | Recursive source representation with Lean-like levels | Canonical term IDs, stored exact/checker hashes, shared DAG | Independent source round-trip/differential fixtures; **not full Lean.Expr representation parity** |
| Substitution / lift | Accepted specialized source operations | Memoized DAG lift, one-binder substitution, universe rewriting | Synthetic independent differential tests pass |
| WHNF | Recursive authoritative beta/zeta/recursor/quot/projection/Nat/native/delta pipeline | Context fragments for beta/zeta/local/delta/direct projection/direct Quot.mk | **Partial indexed reduction only**, explicit fail-closed halt categories |
| DefEq | Recursive accepted checker, binder/Pi source optimizations | **No complete indexed accepting DefEq** | Deep-binder synthetic performance strong |
| Inference | Recursive accepted checker, checked app/Pi/let/binder summaries | **No complete indexed accepting inference** | Checked positive/negative fixtures qualify source changes |
| Declaration admission | Source checker; positive/negative safe and inductive workloads | Opt-in session retention and admission delegate to source checker | Atomic admission/cache invalidation tested; indexed admission is **not** an independent checker |
| Axioms/primitive trust | Own Lean 4.34-like environment/safety rules | Context-sensitive syntax-only experiments | Full official v4.34 policy/differential coverage outstanding |
| Kernel metatheory | **No qualified C0 consistency/refinement proof** | None | Defer formal proofs under current workstream restriction |
| Real-library/Mathlib performance | **No qualified large official corpus** | None | Synthetic complete-checker measurements only |

Recent successful implementation HEAD 497df6a / [CI 38305932773](https://github.com/dwijayuda/pskernel/actions/runs/38305932773):

| Same-run operation | C0 or candidate | Baseline | Interpretation |
| --- | ---: | ---: | --- |
| 120 checked sequential definitions | 17 ms lazy indexed session | 16 ms source / 24 ms eager indexed retention | Removing unused syntax retention eliminates much overhead; still no source win |
| 1,200 fully checked WHNF operations | 27 ms lazy indexed session | 26 ms source / 43 ms eager retention | Laziness reaches near parity; still no improvement over source |
| 200 experimental work invocations | 65 ms retained indexed root | 65 ms source re-import | No meaningful win |
| 30 shared-DAG indexed universe rewrites | 7 ms indexed | 523 ms recursive-source | Synthetic representation-specific operation only |
| 24 samples of 12 complete checked declarations | 25 ms C0 p50/p95 | 47 ms unchanged original p50/p95 | ~1.9x for constructed mixed admission batches, **not all Lean libraries** |
| Small allocation-count proxy, same batch | 36,206 C0 | 34,971 unchanged original | ~3.5% more C0 small-allocation events |
| Whole benchmark-process VmHWM | 1,165,716 kB C0 | 1,165,844 kB original | Near parity; not attributable memory improvement |

The benchmark baseline is the repository-local unchanged **pskernel-core**, not Lean's C++ kernel. No self-hosting, bootstrap, metatheory or generated-Rust tests were used to establish these native C0 performance results.

## 7. High-priority source discrepancies and risks

### R1. Exact representation coverage: needs explicit specification

At [official expr.h](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/expr.h), C++ binder_info includes Default, Implicit, StrictImplicit, InstImplicit, and **Rec**. [C0 Expr.lean](https://github.com/dwijayuda/pskernel/blob/497df6a39947aa3532b2d1a6ffe84342125fd2fc/psc0/packages/pskernel-c0/src/Ps/KernelCore/Core/Expr.lean) currently represents only the first four. Official metadata is a structured key/value object; C0 records **mdata : Nat**. These are **source-visible exact representation gaps**, not proof of false acceptance in current restricted checker inputs. An import/export adapter must preserve or explicitly reject unsupported cases; it may never claim full lossless Lean.Expr parity while silently discarding fields.

### R2. Hash-cost and forced canonicalization

[C0 Cache.lean](https://github.com/dwijayuda/pskernel/blob/497df6a39947aa3532b2d1a6ffe84342125fd2fc/psc0/packages/pskernel-c0/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean) uses 16-bit-scale fingerprints modulo 65521 and a four-level radix index. Exact bucket equality avoids hash-based soundness errors, but potential long collision chains and repeated root encoding are serious large-library costs. Do **not** switch blindly to another global hash table: ablate eager canonicalization versus immutable structural sharing, optional hash-consing and packed cached metadata.

### R3. Raw indexed handles, provenance and untrusted stores

[C0 IndexedExpr.lean](https://github.com/dwijayuda/pskernel/blob/497df6a39947aa3532b2d1a6ffe84342125fd2fc/psc0/packages/pskernel-c0/src/Ps/KernelCore/Core/IndexedExpr.lean) stores child references as Nat. [IndexedSession.lean](https://github.com/dwijayuda/pskernel/blob/497df6a39947aa3532b2d1a6ffe84342125fd2fc/psc0/packages/pskernel-c0/src/Ps/KernelCore/Checker/IndexedSession.lean) exposes diagnostic work containing a Nat term handle. A numerically valid handle can refer to a completely different expression in another arena, and public structures can be constructed with inconsistent derived metadata. Current opt-in status does not issue trusted verdicts, so this is not a demonstrated accepting-checker soundness defect. **Before promotion**, seal construction and ownership, validate imported terms, and ensure cache provenance cannot be forged or confused across stores/environments/locals/fuel policies.

### R4. Caches and partial conversion are not proof oracles

Official DefEq uses exact pair caches and staged inference/WHNF; C0 follows much of that design. Do not turn a hash equality, a cached loose-variable bound from untrusted storage, a reduction-fragment halt state, or a partial conversion success into a type-checking result. Fail closed, distinguish unsupported from rejected, and maintain the source checker until the entire pathway is accepted.

### R5. External checker fidelity remains unmeasured

The C0 negative/exact fuel and unchanged-sibling differential suites are valuable, but C0 lacks a measured full Lean Kernel Arena acceptance/rejection result and representative Init/Std/Mathlib corpus. Implementing only a subset of the official kernel is acceptable **if it explicitly declines unsupported inputs**; silently accepting them is not.

### R6. Soundness proof and axiom policy cannot be transplanted

con-leche's theorem depends on specific implemented checks, verified mode, recognized basis constants, standard axioms, and semantic refinement between cached execution and pure/model tiers. A proof about con-leche says nothing about an arbitrary C0 optimization until C0 establishes a refinement theorem or delegates an independently checked artifact to that exact verified implementation. Full Lean-compatible unrestricted axioms and con-leche's certified restricted-axiom mode are distinct contracts.

### R7. Performance metrics have different scopes

C0's 24 latency samples per run are within-run batches of crafted declarations and its heartbeat count is small allocations, not allocated bytes. Arena Mathlib results are end-to-end external checkers under their run configurations. Do not extrapolate a source-side 1.9x fixture gain into an official kernel win, or a deep-DAG 70x rewrite gain into average program performance.

## 8. Recommended clean target architecture

1. **Sealed immutable expression core.** Make official v4.34-conforming syntax explicit, distinguish display information from semantic identity, use full-width cheap cached metadata (hash, bound-variable range, universe-parameter/fvar flags), and provide immutable provenance-safe internal terms. Implement low-cost direct allocation first, with optional interning only when observed beneficial.
2. **Closure/value-based evaluation candidate.** Evaluate terms as closures (syntax, environment and binder context), with neutral rigid heads and application/projection spines. Delay capture-avoiding substitution and reconstruct a source term only when necessary. Compare this architecture head-to-head against the canonical DAG design in the *same Lean* implementation and workload.
3. **One authoritative checked operation graph.** Keep core WHNF, full WHNF, DefEq, infer-only, checked inference and admission as distinct but composed responsibilities. Preserve exact official ordering (cheap recursor/projection flags, Quot, native, Nat, delta, proof irrelevance, eta and unit-like rules).
4. **Explicit contextual and resource provenance.** Key every context-dependent memo by its owning environment revision, local context, universe scope, safety/evaluator capability, and relevant resource regime. The syntax store itself must not encode contextual judgments. Preserve typed error/rejection/decline/resource outcomes.
5. **Open-recursion and verification-friendly design.** Consider a single family of checker operation bodies with an explicit recursive interface, as in con-leche, instead of duplicating independent production inference/DefEq languages. Optimize implementation behind a proven/refutable refinement boundary; until proof exists, differential test against official Lean and another checker.
6. **Atomic declaration admission.** Reuse the exact checked graph for definitions, theorems, opaque, axiom policy, recursors, mutual/nested inductives and quotient initialization. Commit only after all checks. Preserve environment and fresh-name state on failure, and do not eagerly index unused accepted bodies.
7. **Separate compatibility and assurance profiles if required.** A full Lean 4 compatibility checker and a con-leche-style certified, axiom-restricted mode have different acceptance contracts. Avoid claiming both until both are implemented and externally qualified.

Do not preserve the existing trie, global hash-consing or source-wrapper architecture just because implementation effort has been invested. Performance architecture should be selected by complete-operation profiles, not isolated helper benchmark ratios.

## 9. Prioritized research-to-implementation plan

| Phase | Coherent deliverable | Gate |
| --- | --- | --- |
| P0 — compatibility characterization | Pin official Lean 4.34.0 and another independent checker; adapt Lean Kernel Arena NDJSON cases to a C0 CLI/library harness with accept/reject/decline and exact corpus manifests | No false acceptance; explicit unsupported categories; version-pinned differential results |
| P1 — trust boundary + term representation | Seal arena construction and handle ownership, close or explicitly decline binder-info/metadata representation gaps, introduce cached level/fvar flags, prototype immutable non-global-hashcons allocation | Lossless supported syntax, malformed-node/fuel/arena-origin regression, end-to-end allocation ablation |
| P2 — candidate evaluation machine | Complete closure-based WHNF/DefEq and its standard reduction-family semantics in native Lean, with resource and environment provenance; compare with indexed DAG | Independent reference parity on reductions, negative/error cases and true library workloads |
| P3 — accepting inference and admission | Route all typed operations and checked declarations through one qualified engine; preserve original C0 and official oracles | Lean v4.34 target compatibility including recursors, quotient, native, universes and full admission |
| P4 — performance qualification | Cold/warm real Init/Std/representative libraries, source-vs-closure-vs-indexed ablations, p50/p95/p99, measured allocated bytes and process RSS | Statistically repeatable complete checker gains with no safety regression |
| P5 — optional verification (deferred) | Formal operational semantics/refinement or integrate a verified external checker gate with precise axiom policy | Explicit assumptions, verified-mode evidence, no claimed proof by imitation |

P0 is the highest-leverage next step: proving exact behavior externally before replacing trusted source internals. P1 and P2 can then be designed coherently instead of optimizing in response to individual synthetic cases.

## 10. Progress conclusion and evidence boundaries

- **Implemented and qualified (C0 accepting source):** broad native Lean checker syntax/type/DefEq/WHNF/admission subsystems, source-level checked app/let/binder and deep DefEq optimizations; native positive/negative/differential suite and checked declaration benchmarks.
- **Implemented and qualified only as opt-in syntax experiments:** indexed DAG, memoized lift/substitution/level instantiation/decoding, immediate local/global/Quot/constructor-projection reductions, explicit fragment halt statuses and session-owned diagnostic work.
- **Demonstrated complete-operation synthetic advantage:** mixed checked admissions approximately 1.9x faster than unchanged project-local core in latest measured CI, alongside more small-allocation events.
- **Not demonstrated:** full independent indexed accepting checker, exact C++ kernel parity, Lean Kernel Arena acceptance, realistic whole-library performance leadership, memory reduction, PSKernel-C0 consistency or formal refinement theorem.
- **Decision:** keep native source acceptance authoritative. Start official-source plus Arena differential qualification. Prototype evaluation architecture comparatively; only promote on soundness parity and complete workload measurement. Do not mistake green native CI for the completion of the remaining P0-P4 architecture.

## 11. References

- [Official Lean v4.34 C++ type checker](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/type_checker.cpp)
- [Official Lean v4.34 expression metadata and equality](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/expr.cpp)
- [Official Lean v4.34 environment admission](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/environment.cpp)
- [Official Lean v4.34 inductive validation](https://github.com/leanprover/lean4/blob/v4.34.0/src/kernel/inductive.cpp)
- [Lean4Lean source, verification and declared divergences](https://github.com/digama0/lean4lean)
- [con-leche checker, model theorem and design](https://github.com/leanprover/con-leche)
- [Nanoda source](https://github.com/ammkrn/nanoda_lib)
- [Sokonanoda closure-based checker source](https://github.com/intgrah/sokonanoda)
- [MathGraph closure-based checker source](https://github.com/metalogiclabs/mathgraph-lean-kernel)
- [Lean Kernel Arena archived September 2026 round](https://arena.lean-lang.org/round/2026-09/)
- [C0 benchmark source and CI](https://github.com/dwijayuda/pskernel/blob/497df6a39947aa3532b2d1a6ffe84342125fd2fc/psc0/packages/pskernel-c0/test/C0CheckerComparison.lean)

**Interpretation rule:** source code inspection supports architecture comparisons; only executable qualified CI supports C0 benchmark numbers; an external theorem proves exactly its stated assumptions and no more.
