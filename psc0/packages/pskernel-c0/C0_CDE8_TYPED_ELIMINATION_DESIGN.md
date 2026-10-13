# PSKernel-C0 CDE-8 — Typed elimination and resource-refinement design

**Status:** architecture study / next implementation contract, not completed code or soundness proof.  
**Kernel pin:** Lean 4.35.0.  
**Branch:** `perf/pskernel-c0-v7-rust-20261012`.  
**Scope:** native Lean under `psc0/packages/pskernel-c0/`; no original `pskernel-core`, compiler, Rust/Wasm or bootstrap edits.

**CDE-8 executable qualification update (2026-10-14):** The latest bounded implementation [`d5a179dc`](https://github.com/dwijayuda/pskernel/commit/d5a179dc08cd361f70a5d34001d1eea4cc99e736) has **full native [CI 38448498595](https://github.com/dwijayuda/pskernel/actions/runs/38448498595) SUCCESS**, including Lean 4.35 compilation, official source/reject fixtures, the mandatory bounded-resource and K/eta observation regressions, negative/resource/migration checks, microbenchmarks and independently rebuilt original checker comparison. The scope is **candidate work-budget foundation and source-typed observation only**; globally complete allocation metering, positive real-checked K/eta coverage, Phase C/D/E exits, full Phase B acceptance and formal soundness remain outstanding. Documentation commits after `d5a179dc` do not represent new executable qualification.

**CDE-8A.2 resource-scope clarification (2026-10-14):** `Budget.lean` now includes captured binder environments, saved continuation frames, UTF-8 string-storage work and a conservative pre-expansion reservation before String-of-list demand rewrites, under the operation-level candidate quota. The current unit is conservative syntax/work, **not a proved memory-allocation byte bound**. It still does not meter all source-rule internal allocations and substitutions; implementing/proving a complete resource contract remains an open CDE-8A exit criterion. Source commit `57cbdd4e`; CI run [38452517448](https://github.com/dwijayuda/pskernel/actions/runs/38452517448).

**CDE-8A.3 update (2026-10-14):** `Budget.lean` precharges source definition body and application-spine traversal before contextual delta, and the selected recursor rule RHS before ordinary iota reconstruction. Unknown/nonmatching recursor constructors remain neutral. The quota is shared with captured environments, saved frames, UTF-8 expansion, and final readback. This remains a conservative candidate work estimate, not a complete cost semantics for internal substitution/heap allocation. Corrected source `d76e2cc4`; [native CI 38453561566](https://github.com/dwijayuda/pskernel/actions/runs/38453561566) under qualification.

**CDE-8A.3 qualification update (2026-10-14):** Executable commit [`d76e2cc4`](https://github.com/dwijayuda/pskernel/commit/d76e2cc4d5d2a0b5f107f37847c75e280c15c060) received **full native [CI 38453561566](https://github.com/dwijayuda/pskernel/actions/runs/38453561566) SUCCESS**. The run qualified native Lean 4.35 compilation, official positive/negative replay fixtures, CDE-0–8 candidate/source regressions (including delta-body/recursor-RHS preflight and neutral missing-rule cases), negative/resource/semantics and scratch-store checks, performance microbenchmarks and independent original-C0 checker comparison. The latest code is therefore qualified for this **bounded candidate-work-preflight slice**, not the full CDE-8A resource exit, a soundness/refinement proof, or trusted kernel replacement. Full C/D/E, B, F and G exits remain open; the original source checker remains the only accepting authority.

**CDE-8A.4 qualification (2026-10-14):** [`bf95088c`](https://github.com/dwijayuda/pskernel/commit/bf95088c338c8e9b8dda7686ce8f26e4f323dac6) passed the full [native CI 38459330291](https://github.com/dwijayuda/pskernel/actions/runs/38459330291). Intermediate quotation, new demand states, primitive numerical work, metadata/name/universe traversal, δ/iota reconstruction, String expansion and saved blocked/normal recursor/Quot frame readbacks are now charged by one opt-in candidate syntactic-work allowance. The corresponding [resource audit](C0_INTERMEDIATE_REWRITE_RESOURCE_AUDIT.md) names all families. This is **not** complete runtime heap or CPU allocation accounting and does not authorize K/eta or a trusted kernel rewrite; the source checker remains authoritative. Complete CDE-8A formal runtime resource assurance and CDE-8B/8C full trusted integration are still open.

## Current implementation checkpoint (2026-10-14)

* `Architecture/Budget.lean` and mandatory `C0ArchitectureBudgetRegression.lean` implement an **opt-in readback/syntax-traversal work quota**. Exact expression-node walks, captured closure/environment readback, conservative pre-instantiation reserve, final spine precharge and demand-step active syntax consumption share one operation-scoped quota. Source WHNF is still computed independently first in preview and is unaffected by candidate declines.
* `Architecture/Typed.lean` adds **source-typed observation**, not an optimized accepting K/eta evaluator. It resolves recursor metadata from the source environment and invokes existing source K/structure-eta helpers with source infer/WHNF/DefEq callbacks. Missing, unsafe or ill-scoped inputs cannot fabricate a constructor. Validation and checked-work authority remain in `Architecture/Work.lean`.
* Known remaining gap: internal callbacks and temporary allocations within δ/Nat/Quot/recursor/projection reductions are not fully metered; K/eta positive real checked families and formal resource/refinement equivalence are still incomplete. This implementation is an architecture foundation, not the full CDE-8A/B completion or Phase C/D/E exit.

## 1. Why the present WHNF candidate cannot yet become accepting

CDE-0–7 implement a non-accepting closure/spine machine, source-bounded arithmetic,
context-dependent delta and local lets, constructor projections, quotient
computation, ordinary non-K recursor iota, and bounded String-literal
major-premise expansion. A separate source WHNF always runs first in preview;
only the original checker can infer/check types and admit declarations.

The candidate's step fuel bounds transitions, **not total allocation or time**:
`psKernelC0QuoteClosure` uses a per-call recursive depth bound, and multiple
separate reifications can allocate independently. The CDE-7 UTF-8 byte guard
bounds the input to String constructor expansion but does not make its
intermediate syntax allocation globally accounted. These are observable
resource-policy gaps. Neither CI differentials nor synthetic metadata
fixtures prove correspondence on all well-typed Lean terms.

In particular, treating any of the following as a purely syntactic rewrite
would violate the planned kernel acceptance contract:

* **K recursors.** The source `psKernelToConstructorWhenK` infers the major's
  type, WHNFs that type, checks inductive family and metavariable/index
  restrictions, constructs the canonical constructor from actual parameters,
  infers that constructor's type and checks definitional equality before
  allowing the constructor substitution. Merely observing one constructor or
  a matching name is not sufficient.
* **Structure eta in recursor reduction.** The source
  `psKernelToConstructorWhenStructure` checks that the inductive is a
  nonrecursive structure, infers/WHNFs the scrutinee type, excludes Prop
  structures, requires exactly one constructor, and derives its parameter and
  field projections from checked constructor metadata. The source may be
  non-constructor syntax; blindly manufacturing a constructor is unsafe.
* **String literals.** The source uses `psKernelStringLitToConstructor`,
  followed by source WHNF of `String.ofList`; it does not directly
  equate an arbitrary string with a guessed constructor. CDE-7 models that
  intermediate demand for a bounded, candidate-only subset.

## 2. Proposed single architecture

Retain one source-semantic evaluator interface and one authoritative checker,
not parallel accepting source/arena/closure pathways. Structure the next
implementation as three distinct data domains:

1. **Immutable terms and closures:** a closure carries source syntax and delayed
   environment, never a proof or checked status. Persistent/scratch indexed
   syntax retains explicit store provenance and exact structural readback.
2. **Candidate operation budget:** a single state carries transition fuel,
   remaining quotation/work budget, allocation accounting, current environment
   scope and reduction policy. Each `quote`, substitution, String expansion,
   and constructor/recursor reconstruction consumes budget before it returns
   a candidate term. Exhaustion returns a distinct resource outcome, not
   `false`, an ill-typed judgment, or a silent neutral success.
3. **Checked obligation interface:** when K/eta requires inference or DefEq,
   route through the existing checked-session source operation and attach
   explicit scope/fuel/error provenance. A candidate may *observe* such an
   obligation but may not turn it into a reusable trusted cache entry or an
   accepting judgment. Only after an independent source-equivalence/refinement
   gate may the selected unified checker directly consume such evidence.

The typed obligation API must not cache data across environment extension,
local-context change, universe instantiation, safety/transparency policy, or
fuel contract. Rebuild the checked session on every successful atomic
environment admission as currently done. No fallback acceptance on candidate
success or on an unknown/error category.

## 3. Coherent implementation milestones

**CDE-8A — exact common resource contract.** Introduce an operation-scoped
budget for all quotation and reconstructed syntax; replace depth-only
quotation checks at demand boundaries with consumption visible to the caller.
Use checked overflow/size guards on String/constructor expansion; keep the
transition counter separate and monotone. Add positive and negative cost
regressions (nested, repeated, wide, UTF-8 multibyte and intentionally exhausted
operations) without changing the trusted source verdict.

**CDE-8B — scoped typed K and eta observation.** Implement the full
inference/WHNF/DefEq-dependent premises as an isolated source-checked
observation first. Demonstrate equality to the existing official source
behavior on appropriately checked inductive examples, including failure,
Prop/data, index, universe, safety, partial and finite-resource cases. Reject
or explicitly decline unsupported situations. Do not synthesize a K witness
from names or constructor counts alone.

**CDE-8C — one checked reduction contract.** Unify WHNF, DefEq and inference
calls with context/owner/error provenance and remove duplicate historical
fast paths only after broad differential acceptance. Source-owned positive
and negative NDJSON exports and whole-checked-workload stress tests are
mandatory before replacing a trusted implementation.

Then qualify complete C/D/E exits separately, return to full Phase B real
Init/Std/Mathlib conformance, perform full-workload performance comparisons
(Phase F), and carry out formal soundness/refinement assurance (Phase G).

## 4. Acceptance and negative gates

* Candidate success **never** implies typing, declaration admission or an
  executable artifact. Failed checks leave the prior environment unchanged.
* Same bytes and pinned Lean 4.35 semantics must have the same source
  accept/reject/unsupported/resource classification at the authoritative
  boundary. Insufficient fuel is a resource failure, never a logical refutation.
* Reification preserves free/bound-variable scope, binder metadata where
  source-exactness demands it, universe levels, arguments and declaration
  ownership. Foreign store handles cannot be proof evidence.
* Include syntax-valid but ill-typed terms, proof-irrelevant K counterexamples,
  K metavariable/indices constraints, Prop structures, opaque/unsafe/partial
  definitions, incorrect projection names, malformed recursor metadata,
  nested String/Quot inputs and excessive allocations.
* Qualify native compilation, focused source-differential tests, official
  negative/positive fixtures, original checker comparison and comparable
  checked workloads. Do not equate short synthetic WHNF tests with complete
  kernel equivalence or competitive performance.

## 5. Source audit map

* `src/Ps/KernelCore/Checker/Recursor/Analysis.lean`:
  `psKernelToConstructorWhenK`,
  `psKernelToConstructorWhenStructure`.
* `src/Ps/KernelCore/Checker/Recursor/Reduction.lean`:
  `psKernelReduceInductiveRecWith`, full RHS universe/field instantiation.
* `src/Ps/KernelCore/Checker/Reduction/PrimitiveData.lean`:
  `psKernelStringLitToConstructor`.
* `src/Ps/KernelCore/Architecture/Demand.lean`:
  operation-local transitions and continuation frames.
* `src/Ps/KernelCore/Architecture/Work.lean`:
  checked-session authority and atomic admission seam.
* `C0_ARCHITECTURE_FIRST_CDE_PLAN.md`:
  binding master dependency order and phase exit criteria.

This is a design gate for subsequent implementation, **not** an assertion
that K/eta, globally metered quotation, full Phase D/E or formal consistency
have been implemented.
