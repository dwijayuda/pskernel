# PSKernel-Fast — soundness/model architecture contract v1

**Status:** normative *target architecture*, 2026-10-11. This document does NOT assert a kernel-soundness or consistency theorem. It specifies the next P0/P1 proof interfaces while retaining full performance-architecture freedom.

**Pinned compatibility authority:** Lean `4.35.0-rc4` (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). **Implementation line:** `research/pskernel-fast-clean-v3-20261011`. **Previous green:** restricted G4.3b six-rule checker at `253afb42b477aacab22def288a2dd42d7ca9633b`, [run 38116916150](https://github.com/dwijayuda/pskernel/actions/runs/38116916150). G4.4 WHNF/DefEq, admission, relative consistency and full conformance are NOT implemented. Keep old proof branches untouched.

## Decision: proofs before unchecked acceptance, experiments before storage commitments

Adopt the *direct model-backed successful-acceptance theorem* pattern from [con-leche](https://github.com/leanprover/con-leche), and the *optimized representation simulation* pattern from [con-ron](https://github.com/leanprover/con-ron). Neither project's theorem automatically applies to this independent checker, and importing a proof model does not certify our implementation.

Define the following three **logical** layers; they need not be three full maintained checkers.

1. **Independent semantics.** Grammar and universe valuation; context/binder scope; eventually semantic judgments for terms, proof irrelevance and exact Lean 4.35 primitives; independent set-theoretic interpretation `SetTheory V` (or a proved compatible interface), explicit interpretations of the *pinned allowed axioms*. The semantic theorem must not refer to representation handles or caches.
2. **Executable authority.** Exactly one production accepting kernel; honest `InferOnly` versus `FullyChecked`; positive WHNF/DefEq semantic premises; atomic checked-environment extension. The only thing allowed to return `Accepted` must have actually checked all proof, declaration and axiom obligations.
3. **Optimized representation.** Interned DAG, closures, scratch/persistent tiers and memoization as measured. Every affirmative result that could reach Layer 2 must be proven to refine Layer 1/2 semantics, or must be independently rechecked by a proven checker. Errors/resource declines need not be complete but may never be promoted into acceptance.

This is *not* proof-first in the sense of implementing all of a second type theory before the checker. It is **contract-first and proof-per-accepting-rule**, plus non-authoritative performance experiments. Do not preserve old Checker/Knot/source-profile constraints or existing proof ASTs when they hurt correctness/performance.

## Expected P0/P1 proof graph and current status

| Obligation | Required theorem/property | Current |
| --- | --- | --- |
| Context well-formedness | Every stored binder domain is scoped at *its introduction depth* and was actually certified as a type; lookup lifts it without capture | G4.3 structural proof only; new P1 independent spec/proof in progress |
| Executing typed rules | A successful `inferGeneralPi` gives the independent `GeneralPiRule` and a structurally valid source and inferred type for every checked context | Rule certificate proved; general input/output structural scope beyond wrapper preflight is next P1 theorem |
| **Typed substitution** | Actual beta and let result-type substitution preserves typing under exact G4.3b premises | **BOUNDED CASES PROVED**: checked dependent identity beta and variable-body let/zeta; generic nested substitution **OPEN**. [P1 evidence](P1_TYPED_SUBSTITUTION_EVIDENCE.md) |
| Conversion | Every positive typed WHNF/DefEq result preserves model denotation at the EXACT level context, opacity and checker environment generation | **OPEN** (G4.4) |
| Inductives/quotient/primitives | Every generated recursor and exceptional rule has an independent, sound model interpretation and exact pinned version policy | **OPEN** |
| Declaration fold | Each accepted fresh name extends a model of the prior immutable environment; no temporary handle or unchecked candidate can survive as a checked constant | **OPEN** |
| Public capstone | `checkDecls .verified ds = .ok env -> Nonempty (Model V env)` under explicit `SetTheory V` and axiom pins; derived `False` rejection | **OPEN**; requires previous rows |
| Backend/runtime bridge | Actual native/JS/Wasm results refine one semantic authority; decoder preserves terms, versions and axiom-policy provenance | **OPEN** |

P0 includes a separate **independent scope model** `ContextScoped` defined without importing the executing G4.3b checker. This model is intentionally **structural, not set-theoretic**. Its first substantive P1 results prove the accepted fragment respects binder scopes under all six rules, including `Pi`, lambda, application and let result substitution. These are prerequisites, **not** a proof of denotational typing, relative consistency or true kernel admission.

A full set model must eventually account for `Prop` as proof-irrelevant, cumulativity, infinite Lean universe levels, `imax`, function-space domains and codomains, extensional equality, `Quot`, inductives, recursor computations, arithmetic and proofs. It cannot be obtained by relabelling the six constructors of `GeneralPiRule` as a model. Avoid falsely claiming `GeneralPiRule` alone is a mathematical soundness result.

## Verified mode and arbitrary-axiom Lean mode

- **Ordinary compatibility mode:** Lean-compatible declarations, including arbitrary user axioms, can be admitted after rule checks; every theorem's assumption closure must be disclosed. No unconditional consistency theorem is possible if `axiom bad : False` is permitted.
- **Consistency-assured mode:** only explicitly pinned axioms for which a concrete set-model interpretation is proved. Start from con-leche's `propext`, `Classical.choice`, `Quot.sound` model route only after verifying our Lean 4.35 semantics and quoted primitive rules. Unmodelled axioms, compiler-backed trust features and unsupported rules **decline**, not silently accept.
- Gödel's limitation: `SetTheory V` or its universe existence is a genuine *relative consistency assumption*, not proof that Lean itself establishes its own consistency with no extra assumptions.

## Proof design with low performance tax

- **Authoritative API contract:** `Result = Accepted | Invalid | Unsupported | ResourceExhausted | InternalError`. No uncertified hint, hash hit, output of an infer-only cache or fast normalization state can synthesize `Accepted`.
- **Cache law:** scope + binder levels, level instantiation, immutable checked-env epoch, reduction transparency and verified/ordinary policy are part of every relevant memo key, or the memo is provably context independent. Discard shortcut results on unproved equality; exact interning uses content verification, never hash equality alone.
- **Storage freedom:** no mandatory compact DAG until measurements of *real typed conversion* show advantages. A con-ron-style packed store can later refine a pure/pinned checker relation. Native Rust/Aeneas is optional and has a nontrivial separate trust/reproof cost.
- **Runtime costs:** preserve an efficient executable checker with proof terms erased; proof modules must not be imported by deployment code. Optional extra checks/annotations are allowed only if generated by actual checking, sound, and measured (the con-leche certification-tax lesson).
- **Resource law:** out-of-fuel, malformed handles or overflow fail closed; liveness/complete acceptance/termination are separate from **partial** positive correctness.

## Concrete immediate P1 acceptance

1. Compile an **independent context-scoping specification** and proofs for arbitrary nested binder contexts and all six `GeneralPiRule` constructors, including the nontrivial capture-avoiding application/let cases, on exact executable source. **Do not replace these with a theorem just echoing a rule constructor.**
2. Prove `GeneralPiContextWF` implies the independent scoped-context predicate, and `inferClosedGeneralPi` successful output is *already* structurally valid even before a second executable output validator is consulted.
3. Keep the extra fail-closed output check until both a semantic proof and the input-validation reflection are qualified; do not remove checks just for benchmark appearance.
4. Assert independent theorem assumptions in CI, preserve counterexample/negative tests and precise source/CI SHAs, then develop a separate **type-preservation** and later set-theory model layer.
5. Track real runtime checker costs, official Lean 4.35 typed differential agreement and all model/axiom/driver trust assumptions. No current performance claim about real Lean kernel checking.

## Research references

- [con-leche README](https://github.com/leanprover/con-leche/blob/master/README.md), [proof overview](https://github.com/leanprover/con-leche/blob/master/OVERVIEW.md), [MainTheorem.lean](https://github.com/leanprover/con-leche/blob/master/ConLeche/MainTheorem.lean). Direct model of successful checker decisions, explicit stronger set-theoretic assumptions, pinned axioms, annotations and verified runtime costs.
- [con-ron README](https://github.com/leanprover/con-ron/blob/master/README.md), [OVERVIEW.md](https://github.com/leanprover/con-ron/blob/master/OVERVIEW.md) and [AENEAS_FINDINGS.md](https://github.com/leanprover/con-ron/blob/master/AENEAS_FINDINGS.md). Two-step Lean-twin/Rust refinement; Rust translated by Charon/Aeneas with declared holes; proof cost and compact persistent/scratch representation are informative, but not mandatory here.
- [Official Lean 4.35 kernel](https://github.com/leanprover/lean4/tree/v4.35.0-rc4/src/kernel): `type_checker.cpp`, `level.cpp`, `inductive.cpp`, `quot.cpp`, `declaration.cpp`. Official source is a compatibility oracle, not an imported soundness theorem.

**No release/merge as a complete checker until the end-to-end model and accepting path really exist.**

## New typed-substitution checkpoint and economy decision (P1)

[Cloud-verified P1 typed substitution evidence](P1_TYPED_SUBSTITUTION_EVIDENCE.md), [run 38120030487](https://github.com/dwijayuda/pskernel/actions/runs/38120030487), establishes **bounded genuine typing preservation** (dependent identity beta, variable-body let/zeta), exact binder lifting laws, and one checked-binder variable-weakening theorem against the unchanged executable source. The 15-theorem assumption receipt gate passed without a new axiom. These theorems refine local portions of the mathematical proof obligations, not the whole calculus.

**Cost choice:** do not make a proof of a global *syntactic* substitution/regularity theorem an unconditional prerequisite for exploring con-leche's direct model-based `WellDenoted` proof. The consistency capstone ultimately needs every **executing positive** beta/let/WHNF/DefEq and admission rule to preserve its model's meaning. A direct semantic preservation theorem can sometimes be cheaper than fully developing syntactic subject reduction and normalization; neither option is proved for PSKernel-Fast today. Evaluate both on a small, independently denoted calculus, measure proof complexity, and choose the smallest valid assurance path. Do not weaken the actual checker, fabricate model assumptions, or treat type-level structural proofs as set-model consistency.

## P1c semantic syntax proof bridge — GREEN, not denotational soundness

[GitHub Actions #38121976529](https://github.com/dwijayuda/pskernel/actions/runs/38121976529) independently qualifies the [P1c erased syntax and source-to-spec proof](P1C_SEMANTIC_ERASURE_EVIDENCE.md): 68 Lake jobs, 29 source files audited and 24 theorem assumption receipts. The new *independent erased syntax* grounds Lean universe levels under an arbitrary valuation and erases names/styles; the actual source lift/substitution is proven to agree with independently defined erased lift/substitution. All six G4.3b typing constructors preserve source/type erasure **existence** under a validated context. The actual beta and qualified let reductions map to exactly the corresponding erased contractions.

**Important boundary:** an erased term is NOT its interpretation in a set-theoretic universe; an arbitrary valuation `ρ : KName → Nat` is not `SetTheory V`. The current erased syntax also lacks con-leche-style **certified binder codomain proposition-regime annotations** needed by a syntax-directed model of Lean's impredicative `Prop`; such annotations must be computed and validated by the actual checker before semantic claims. No run-time checker, accepting rule, or performance implementation was changed by these proof-only modules.

**Current proof-economy decision:** prioritize a *direct checker-to-denotational-model route* for eventual full Lean-like consistency, with selective syntactic weakening/substitution lemmas used as correctness prerequisites and tests. P1c supplies the lexical/level/substitution translation bridge; next define the smallest credible set-model interface and `WellDenoted` invariant, prove beta/let semantic preservation and one Sort/dependent-Pi membership theorem **without** pretending con-leche's capstone automatically applies to this checker. Evaluate the actual annotation tax and proof cost before making a full-kernel architectural commitment.
