# PSKernel-Fast P1h: Hereditary Tagged Denotation and Semantic Proof-Point Uniqueness

**Green and conditional, proof-only.** This milestone does not change the executing G4.3b checker, trusted runtime or admission authority.

## Live-source qualification

- **Qualified code/proofs commit:** [`2b4e79bddce283c3bd7fb04fd0387a8e81d3ca3f`](https://github.com/dwijayuda/pskernel/commit/2b4e79bddce283c3bd7fb04fd0387a8e81d3ca3f), branch `research/pskernel-fast-clean-v3-20261011`.
- [Completed **SUCCESS** CI run **38134093069**](https://github.com/dwijayuda/pskernel/actions/runs/38134093069), job **`114454289188`**, Lean **4.35.0-rc4**, official upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- Cloud log independently records **97 Lake build jobs**, **45 independently audited Lean source files**, **139 exact #print-axioms theorem assumption receipts** with allowed assumptions `propext`, `Classical.choice`, `Quot.sound`, NO `sorryAx`. Prior G1–G4.3b focused runtime and beta-regression suites passed.
- Prior green hereditary-only checkpoint: [`af1a547fc4ae779c15eb3e31aa31cc425b82205b`](https://github.com/dwijayuda/pskernel/commit/af1a547fc4ae779c15eb3e31aa31cc425b82205b), [CI #38133936309](https://github.com/dwijayuda/pskernel/actions/runs/38133936309), job `114453808100` passed **97 jobs / 45 source modules / 136 exact receipts**. P1h's final three theorems increased receipts to 139 without increasing source count.

## Proven mathematical contracts

[`Proof/TaggedWellDenoted.lean`](src/PSKernelFast/Proof/TaggedWellDenoted.lean) constructs a HEREDITARY semantic typing judgment over the existing `PropInterpTerm` syntax:
- `sort u` is interpreted at `taggedSortSet V (u+1)`, derived from the tagged Grothendieck tower;
- `bvar i` requires a concrete model-environment membership witness at its declared semantic rank;
- proposition-valued `Pi A B` requires a recursively well-denoted domain and recursively well-denoted body **for every actual element in the interpreted domain**. No unchecked binder annotation is allowed to silently discharge this model obligation.

It proves `taggedWellDenoted_sound` (every witness denotes a member of the declared semantic sort) and `taggedWellDenoted_pi_fibres` (the hereditary Pi witness entails actual model-fibre validity). Constructs precise witnesses for BOTH executing G4.3b checked source programs `∀(P:Prop),P` and `∀(P:Prop),P→P`; reuses source-backed proof annotation to derive the guarded Pi model membership for each. This is NOT a proof that **all** executing G4.3b successes produce `TaggedWellDenoted` witnesses.

[`Spec/TaggedPropSemantics.lean`](src/PSKernelFast/Spec/TaggedPropSemantics.lean) additionally proves **for an arbitrary interpreted proposition `P ∈ taggedProp V`**:
- If `x ∈ P`, then `x = taggedPoint V`.
- If `x, y ∈ P`, then `x = y`: PURE MODEL-VALUE uniqueness / semantic proof irrelevance.
- `P` has an inhabitant iff `P = taggedTrue V`.

These extend P1f's exact two-truth-values theorem without assuming universal quotient freshness, any new set-theory axiom, a checked term interpreter or model existence. Proof-point uniqueness here is mathematical SET-MODEL uniqueness, **not** full source checked proof-term irrelevance or Lean's proof-irrelevance definitional equality rule.

## Explicitly unresolved obligations and next path

All set-theoretic results remain conditional on a caller-supplied **`[SetTheoryBasis V]`**, whose existence is not constructed. This is not an internal Lean model-existence proof.

Still false: a global source-to-`TaggedWellDenoted` derivation from every six-rule checker success; fully typed semantic context and substitution, lambda/let/app beta preservation, Type-valued dependent Pi graphs, typed quotient writable guards, complete proof-term irrelevance, protected declarations/model extension, relative no-False/consistency, full Lean 4.35 WHNF/DefEq/conformance, admission API, and real kernel-only throughput/RSS/allocation comparisons.

Next work should define **source context/environment validity linked to checked terms** and derive hereditary witnesses on a genuinely guarded nontrivial subset before tackling general executable checker soundness. Never use simple model proposition inhabitation as proof-term checker authorization. P1d/P1e provisional carriers remain historical; new P1g/P1h model proofs use only the tagged carrier.
