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

## P1 qualification correction — 18 October 2026

Candidate `f7c34243e017bf672893f1a624f9d0a1126fc750` failed [preparation run 39074107811](https://github.com/dwijayuda/pskernel/actions/runs/39074107811). The Order registry/audits, nine checked monotonicity proofs, P0, WF and indexed BEq checks passed. P1 source construction failed with a type mismatch; three historical policy-only negatives also remained after policy activation.

Pinned Lean `src/Init/Prelude.lean` declares congrArg arguments as type, range, left, right, function, proof. P1 supplied the function before the endpoints. The existing WF congruence constructor was already correct. This candidate corrects P1 application order and adds owned application/equation diagnostic context; it changes no proof requirement or kernel boundary. Pinned PartialFixpoint/Eqns.lean applies congrArg to the projection and fix_eq proof through native implicit inference; PSC0 supplies the actual full Core argument order.

All five exact formerly policy-refused programs are now retained together as kernel-checked logical-only positives, including omitted result inference and a private namespace definition. Native Lean controls accompany them. None is emitted or executed. Genuine nonmonotone and assurance refusals remain required.

Qualification of this correction is pending. Main remains `f271f2a35789b120dbe1a6dcd5a555db44e72134`; no main Native run was superseded. M3+B remains open. After P1 preparation passes, promote with preserved history and require the five main workflows at one exact SHA before claiming integration. Then close remaining source strategies, generic/section P1, generalized measured recursion and six-exit matrix gaps.


## P1 logical-construction milestone — 18 October 2026

At `762e2ba6e835734351ad94b37cbb39ab5581318d`, [preparation run 39075270327](https://github.com/dwijayuda/pskernel/actions/runs/39075270327) independently checked all four P1 source members in three actual fixpoint components, their whole/source equations, common mutual PProd projections and exact runtime-body identities under the unchanged official-kernel 2m/20k limits. The kernel-valid adversarial self-equation/body mismatch was rejected by the runtime adapter. Missing/opaque auxiliaries and incomplete packed components also retained their refusals. All five byte-identical historical policy-only programs passed logical checking and none was executed.

All other preparation steps passed. The P1 emission request stopped at a fixture grammar error: `Option.some(value)` is an expression call, not a native constructor pattern. This candidate corrects it to `Option.some value`, preserving the selected grammar and compiler acceptance rules. Emission, module controls, 30 runtime comparisons and five-workflow integration remain pending. The previous fixture-only IO diagnostic compile error at e66588f9 was fixed in762e2ba6.

Main remains `f271f2a35789b120dbe1a6dcd5a555db44e72134`, with its five successful workflows; no healthy main Native run was superseded. M3+B is incomplete. Continue P1 emission/integration, then source-policy/noncomputable ownership, selected generic/section fixedpoints and generalized measured recursion according to the six exits. A noncomputable implementation/design is being prepared independently from pinned NoncomputableAttr, MutualDef, PreDefinition/Basic and Compiler/LCNF/ToLCNF; it is not yet committed or qualified.


## Qualified P1 preparation; main integration pending

Preparation `e8cb72b8c2bb5b08433b455b66e887f6bf79fcbe` passed [run39075748079](https://github.com/dwijayuda/pskernel/actions/runs/39075748079), job117522420411, in full. Observed: Order asset replay/audits; four portable order dictionaries; nine monotonicity proofs and nonmonotone refusal; retained source/P0/WF/indexed/recursive-deriving checks; four P1 source members in three actual fixedpoint components; exact whole/source equations; official-kernel checks under unchanged2m/20k limits; complete packed runtime ownership; kernel-valid adversarial mismatch and missing-layout refusals; all five exact historical policy-only programs checked logically and never executed; module private-callee/support hiding and explicit public equations; ordinary five-target emission and both verified-assurance refusals.

This checkpoint promotes the same qualified compiler/test content to main for Native/M3/F1/F2/F3 integration. No backend runtime parity or complete M3 claim follows from preparation. The P1 observer adds30 required comparisons. Run all retained cases and report actual totals.

Root causes resolved: correct Lean4.35.0 congrArg Core argument order, retained old policy cases now logical-only positives, native constructor-pattern spelling in the fixture, and fixture-only IO diagnostic syntax. No compiler grammar, proof criterion, negative criterion or budget was weakened. See [P1 design and evidence](PSCV0_M3_PARTIAL_FIXPOINT_ACTIVATION_2026-10-18.md).
