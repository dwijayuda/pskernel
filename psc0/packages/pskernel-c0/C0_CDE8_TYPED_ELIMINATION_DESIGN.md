# PSKernel-C0 CDE-8 — Typed elimination and resource-refinement design

**Status:** architecture study / next implementation contract, not completed code or soundness proof.  
**Kernel pin:** Lean 4.35.0.  
**Branch:** `perf/pskernel-c0-v7-rust-20261012`.  
**Scope:** native Lean under `psc0/packages/pskernel-c0/`; no original `pskernel-core`, compiler, Rust/Wasm or bootstrap edits.

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
