# Typed mutual fixedpoint construction

Candidate, not source mutual-WF acceptance. Reference: Lean4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
ArgsPacker.Mutual.{uncurryType,uncurryTypeND,uncurryWithType},
PreDefinition/WF/{PackMutual,Rel,Fix}. Important upstream controls include
funind_mutual_dep, fixedParamsReorder and mutual_termination_by_errors.
Attribution remains in THIRD_PARTY_NOTICES.md.

Ps.Meta.MutualPacking now distinguishes a dependent combined result type from
a common nondependent codomain. The latter checks every original measure's
codomain in its actual scope, rejects varying dependencies, and retains one
ordinary codomain rather than a stuck type-level sum eliminator.
Projection types use the same arity-owned injections as value projections.

Ps.Meta.MutualWellFounded combines already checked unary member types and
measure functions in one fixed-parameter context. Per-member domains are
compared before packing. A real common dictionary supplies the inverse-image
relation through Ps.Meta.WellFounded. The required functional and callback
types are inferred from the selected actual fixpoint declaration, avoiding a
second hand-maintained signature. Each branch is checked against the injected
member type before combining; the full functional and fixedpoint are checked.

The existing packing executable adds three heterogeneous dependent result
members, a common Nat measure, all typed callee projections and three exact
fix_eq-derived equations independently admitted by the official kernel.
It refuses missing member measures and a measure codomain depending on a
varying parameter. These are checked construction tests; the branches have no
recursive source calls and do not claim source strategy, decrease-goal, or
backend execution coverage.

Next consumers must specialize complete owned headers through the shared
fixed-parameter permutations, preserve genuine capture provenance, re-elaborate
source under typed branch callbacks, and independently compare the retained
source equations. Runtime adaptation must recover each member from the entire
actual checked functional before erasure. No unknown strict-IR type, assumed
equation, Boolean component shortcut, or temporary axiom is authorized.
