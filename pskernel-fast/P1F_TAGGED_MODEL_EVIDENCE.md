# PSKernel-Fast P1f — Tagged Proof Point, Derived Pair Closure and Honest Quotient Boundaries

**Status:** independent proof-first, machine-checked **model representation** (not a complete set model, proof irrelevance, Type-valued Pi semantics, valid declaration kernel or consistency proof). P1f does NOT change executable G4.3b checking or existing P1d/P1e source-level model interpretation. Old model candidates are preserved as explicit **negative research evidence**, not silently promoted.

## Exact qualification

- Branch: `research/pskernel-fast-clean-v3-20261011`.
- **Qualified source + assumption gate:** [`367ddf25d3d97e7fb0b88c86dbeed7410d51dc10`](https://github.com/dwijayuda/pskernel/commit/367ddf25d3d97e7fb0b88c86dbeed7410d51dc10).
- [**Completed GitHub Actions run 38129546961**](https://github.com/dwijayuda/pskernel/actions/runs/38129546961), job `114440827120`: **SUCCESS**. Pinned Lean `4.35.0-rc4` upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, **94** Lake build jobs, **42** independently audited Lean V3 source files, **110 exact** machine-checked theorem-assumption receipts, previous G1–G4.3b focused smoke suites and all older P1 theorem modules green.
- The narrow assumption audit only permits `propext`, `Classical.choice`, `Quot.sound` and fails closed on extra/missing receipts or `sorryAx`. Every theorem in this stage is **conditional on an explicitly SUPPLIED `SetTheoryBasis V`**; no global SetTheory instance was constructed, no new project model/soundness axiom was declared. Lean's `#print axioms` does not list the quantified set-model typeclass as an ambient global axiom; the mathematical premise still matters.

## Research-driven architectural decision

Deep study of [con-leche's proof-point construction](https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Pt.lean), [Kuratowski graph model](https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Graphs.lean), [finite ordinal model](https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Omega.lean), and [quotient counterexample](https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Quot.lean) establishes that **proof-point design cannot be driven by test-fix hunting**. It requires an explicit *data encoding* boundary with structural no-collision theorems.

Earlier PSKernel-Fast findings:

1. **P1d canonical candidate fails:** `True={empty}`; its only inhabitant is itself a `Prop` truth value, so no separate proof point can be carried. Already machine-proved as `old_true_forces_truth_value`.
2. **P1e V2 candidate fails:** `proofPointV2` is *exactly* a writable Kuratowski pair of `(empty,empty)`, machine-proved by `proofPointV2_is_kuratowski_empty_pair`.
3. **Bad proposed stronger goal:** "A proof point is distinct from every possible quotient set." Con-leche proves `quotSet_eq_pt_countermodel` for unconstrained quotient data; that global theorem is false. PSKernel-Fast now independently proves `taggedPoint_is_arbitrary_image`, showing unrestricted image representations may equal the proof point. The correct boundary is **writable *well-typed* representations**, with justified restrictions on quotient terms/slots. Do not postulate a universal `quotSet_ne_pt` model law or introduce a guessed rejection policy as proof.

## New independent model math

### 1. Common set-encoding layer, not coupled to the bad V2 candidate

[`Spec/SetEncoding.lean`](src/PSKernelFast/Spec/SetEncoding.lean) depends only on the existing `SetTheoryBasis V` model assumptions. It defines and proves exact membership laws for:

- `modelSingleton x := pair x x`;
- `modelOrderedPair a b := pair (singleton a) (pair a b)` (Kuratowski);
- `modelGraph F A := image (fun x => modelOrderedPair x (F x)) A`;
- `modelNat 0 := empty`, `modelNat (n+1) := modelNat n ∪ {modelNat n}` (von Neumann);
- `member_orderedPair_nonempty`: **every member of an ordered pair itself has a member**;
- `empty_member_modelNat_succ`: every positive finite ordinal has empty among its elements;
- `universe_modelSingleton_closed`: singleton universe closure, derived from powerset plus downward-subset closure, not made into an extra axiom.

These definitions characterize the *actual model-level data objects* against which a proof point can be meaningfully distinguished. They are not the runtime compiler's storage-layout assertions.

### 2. One principled tagged proof-point representation

[`Spec/TaggedProofPoint.lean`](src/PSKernelFast/Spec/TaggedProofPoint.lean) defines the candidate:

- `tag = {empty, {{empty}}}`,
- `pt = {tag}`,
- `True = {pt}`,
- `Prop = powerset(True)`.

It independently proves from `SetTheoryBasis V`:

- `taggedPointTag_ne_singleton`: the tag cannot collapse to a singleton;
- `taggedPointTag_ne_orderedPair`: the tag contains empty, whereas every Kuratowski-pair member is nonempty;
- `taggedPoint_ne_orderedPair`: the proof point itself cannot be a writable Kuratowski ordered pair;
- `taggedPoint_ne_graph`: a function graph's elements are ordered pairs, so no such graph is the point;
- `taggedPoint_ne_nat`: point differs from **every** finite von Neumann natural number;
- `taggedPoint_not_prop` while `taggedPoint_member_true`: the proof point inhabits True but is **not itself a proposition truth-value**;
- `taggedProp_exactly_two`: Prop contains exactly two truth values, false and true;
- `taggedPoint_is_arbitrary_image`: arbitrary image freshness fails, explicitly guarding against the impossible quotient/no-image assumption.

This matches the **structural anti-data design** of con-leche without copying its checker implementation, claiming its independent proof applies to our checker, or adding a new runtime trust path. The remaining **typed quotient representation** gap is explicit.

### 3. General finite-pair universe closure from the existing Tarski matrix

[`Spec/FiniteUniverseClosure.lean`](src/PSKernelFast/Spec/FiniteUniverseClosure.lean) proves `universe_modelPair_closed` using a bounded finite argument rather than adding a new model assumption:

1. Given any inhabited Grothendieck universe, derive three distinct members: empty, singleton empty, double-singleton empty. Their membership follows from the existing universe subset/powerset/singleton theorems.
2. A pair of two members is a subset of the universe by the existing pair-membership law.
3. The size alternative in the Tarski universe definition says that such a subset is either equinumerous with the universe or itself a universe member.
4. Equirepresentability is impossible: at most **two** preimages cannot surject onto the **three proven distinct universe members**.
5. Therefore the pair is a member. The theorem is generic over an arbitrary inhabited stage and any two of its members, with **no new axiom**.

This closes a real mathematical prerequisite for tagged-point placement, and supports future finite/set data constructions without contaminating the checker implementation.

### 4. The shifted tagged universe tower is qualified

[`Spec/TaggedPointUniverse.lean`](src/PSKernelFast/Spec/TaggedPointUniverse.lean) now proves:

- `taggedPointTag_mem_typeOne`,
- `taggedPoint_mem_typeOne`,
- `taggedTrue_mem_typeOne`,
- `taggedProp_mem_typeOne`,
- `taggedSort_member_succ`: exact `Sort u : Sort (succ u)` **set membership** under every symbolic universe valuation in a proposed tagged `Sort 0=Prop`/positive Grothendieck tower.

These follow from the old model assumptions and the **derived** pair/singleton/powerset closure, not from a new trusted "universe contains tag" assertion.

## What is NOT proved and why migration is blocked

**No global `SetTheoryBasis V` instance** or model-existence theorem; the new set construction is conditional. The V3 tagged point is **qualified against the precise implemented pair, graph, finite-numeral and Prop encodings**, not every conceivable data set or type-theoretic quotient object.

The proof-only tagged tower is intentionally **NOT** substituted into P1d/P1e's current `sortSet`, `propPi` or `interpProp`. Those modules still use the older provisional candidate, so their two checked-source true/false denotation theorems must be **reproved under the tagged model** before being advertised as results for that model. The runtime G4.3b checker remains unchanged.

**Explicit remaining mathematical/model gates**:

- a complete typed `Quot` class/lift model with necessary *typed/syntactic* proof-point freshness guards, no false unconditional `QuotFreshness`;
- proof-irrelevant `lamR`, `piR`, application, proof-point constancy and Type-valued graph products, with model membership/eta/beta;
- hereditary semantic `WellDenoted` and source-to-denotation soundness of ALL relevant actually executable G4.3b typing/conversion rules, not just two closed examples;
- exact Lean 4.35 universe, quotient, inductive and primitive semantics; protected checked declaration environment, model extension, relative no-False theorem;
- independent native/JS/Wasm representation-refinement proofs and **real kernel-only** throughput, RSS and allocation benchmarks.

The **next correct work is an explicitly versioned, proof-only parameterized Prop-model interface** that lets the old partial model be replaced in one coherent semantic migration, followed by the two actual checked-source examples requalified under the tagged carrier. No new semantic-runtime authority or proof admission until the model obligations really hold.

## Provenance of proof elaboration issues

- Initial integrated [run 38128974156](https://github.com/dwijayuda/pskernel/actions/runs/38128974156) compiled the data-encoding layer but failed one dependent equality rewrite in the tag's non-singleton proof. The fix at `ea958d6e39557aad0924a9401821b23f9dc2172f` transports equality **only in the containing set**; the mathematical tag, statement and representation were NOT changed. [Run 38129096108](https://github.com/dwijayuda/pskernel/actions/runs/38129096108) passed **90 Lake build jobs, 40 independent source files, 101 exact theorem receipts**.
- The separate generic finite-pair closure and tagged universe placement compiled as a mathematical slice, but the first integrated [run 38129457984](https://github.com/dwijayuda/pskernel/actions/runs/38129457984) failed one `SetTheoryBasis.Mem` wrapper-versus-raw-membership elaboration in `taggedSort_member_succ`. Replaced the restatement with the **actual raw field** `SetTheoryBasis.univ_step`, not a new premise.
- **Final green code/assumption checkpoint**: `367ddf25d3d97e7fb0b88c86dbeed7410d51dc10`, [run 38129546961](https://github.com/dwijayuda/pskernel/actions/runs/38129546961), job `114440827120` — **SUCCESS, 94 build jobs, 42 audited V3 Lean source files, 110 exact theorem receipts**, all historical focused regressions passed. No additional model assumption, `sorryAx`, checker acceptance rule or old proof branch changes.
