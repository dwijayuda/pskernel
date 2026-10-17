# M3 selected partial fixedpoints — activation design and evidence boundary

Status: activation candidate only. Completion requires actual source/kernel/IR/runtime gates at one exact commit.

## Pinned design basis

Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:
- `src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean`: independent result CCPO search, inhabited flat-order fallback, pointwise Pi orders, packed PProd components, recursive-call substitution, ordinary compiled bodies.
- `src/Lean/Elab/PreDefinition/PartialFixpoint/Eqns.lean`: `Order.fix_eq`, `congrArg` for projections and dependent `congrFun` for source arguments.
- `src/Lean/Elab/Tactic/Monotonicity.lean`: constant/identity/lambda/call/projection rules, checked compositional lemmas and independent discriminant splitting.
- `tests/elab/partial_fixpoint.lean`, `partial_fixpoint_mutual.lean`, and `partial_fixpoint_monotonicity.lean`: tail recursion, Option results, mutual components, dependent results, absence of inhabitation, recursive-result inspection, and selected monadic extensions.

PSC0 keeps its smaller selected surface. It packs complete function telescopes directly rather than introducing Lean's fixed-parameter permutation optimization. This preserves source binders, captures, universes and member order with fewer intermediate representations. Every accepted component is still checked against the actual closed functional and its independently constructed order/monotonicity proof. No provisional public axiom, native elaboration escape or source-specific runtime rewrite is introduced. Monadic order extensions require separately retained checked lemmas and remain distinct from the currently selected independent-branch/call proof rules.

## Selected library identity

The immutable 117-declaration asset has complete type/value/proof dependencies and six recursor rules independently replayed by official Lean. Preparation run 39069995046 at 0093a0ae3aca4a80d67a439c43822a18918d56f8 observed:
- 3752 declarations, 44 classes, 370 ordinary instances; default registry unchanged.
- FNV `fnv1a64:18189421774150997966`.
- declaration SHA-256 `19acd30faa99f70362aac15e2e2a65f8fffe69a560e8fc0c329b4d3cc3635312`.
- surface SHA-256 `f364e3d926e0c7c198e6807a79d26e389afeb8d2ad1a7fe8761944fa3282a5a3`.
- Four actual portable order dictionaries (including dependent Pi), nine separately kernel-checked monotonicity proofs, and a nonmonotone refusal.

The pre-Order authoring/replay boundary stays frozen. Only inspected class/dictionary metadata enters instance search. Classical.propDecidable is not registered as an ordinary runtime decision procedure. The foundation remains exactly propext, Quot.sound, Classical.choice.

## Admission and runtime invariants

A recursive P1 component must contain compatible fixedpoint members. Each member's actual checked body is closed over its source telescope. Peers become projections from the common packed recursive parameter. The compiler constructs Order.fix using an actual CCPO and checked monotonicity proof. Source equations follow from fix_eq and checked congruence; no equation is assumed.

The official kernel sees the original logical graph. The ordinary runtime adapter requires unique public members, exact universes/types, complete ordered projections, a unique checked auxiliary, exact whole-function equations, and reconstruction of the same functional from all retained bodies. Only auxiliary-owned recursor helpers may be restored, with bounded beta/zeta normalization. An unrelated but kernel-valid self-equation cannot authorize a different runtime body.

P1 equations do not establish executable adequacy, termination or target correspondence. Closed-verified and boundary-qualified requests with missing obligations still fail at assurance; no ordinary fallback is permitted.

## Qualification

The existing P1 fixture checks four members in three components, exact source equations, complete ordinary runtime ownership, a kernel-valid adversarial equation/body mismatch, missing/opaque auxiliaries and missing projections. The exact formerly policy-refused recursive programs become checked logical-only positives and are never run. Nonmonotone source remains an exact-phase negative.

Five existing runtime lanes consume the same terminating native oracle: JavaScript, strict compiled TypeScript, Rust, V8 GC and Wasmtime components. Three exports and two inputs require 30 new observations; report actual results only after execution. Preserve every prior selected case, all budgets and the five-workflow exact-SHA integration requirement.

Broader selected generic/section/mutual-WF matrix closure and all six M3+B exits must be audited before claiming M3+B complete.

## Generated visibility

Only the actual identity of each public typed predefinition enters its module interface. All support declarations owned by that member stay private, regardless of declaration kind or suffix. This includes the whole-function equality used by the P1 runtime ownership check, whose type contains the real source body and can reference a private callee. The source-defined interface theorem is independently public. The P1 module control requires an imported public unfolding theorem to work while the generated eq_def remains inaccessible. This applies the pinned mkEqLikeNameFor invariant through the existing typed ownership records.
