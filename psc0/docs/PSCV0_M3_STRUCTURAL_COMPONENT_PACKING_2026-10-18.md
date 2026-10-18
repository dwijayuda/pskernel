# M3+B actual-universe structural component packing

Status: design and coherent implementation prepared; qualification pending.
Primary reference: Lean 4.35.0, eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

## Native study and comparison

- src/Lean/Elab/PreDefinition/Basic.lean, checkCodomainsLevel: mutual source
  results must have equivalent actual universes; it does not require a successor.
- src/Lean/Meta/PProdN.lean: right-associated And for known propositions,
  PProd otherwise; True/PUnit for zero components and identity for one.
  Projection follows the actual checked product owner and source position.
- Structural/IndPred.lean, andProj / replaceIndPredRecApp: positive predicate
  fields apply their real argument spine before function-component projection.
- Structural/BRecOn.lean, mkBRecOnConst / withBelowDict: pack the actual motives,
  retaining common result universes and source-function positions.
- src/Lean/Elab/Structure.lean, structureSyntaxToView, and
  MutualInductive.lean, inferResultingUniverse/checkResultingUniversePolymorphism:
  inferred non-Prop structures have a positive result universe. In particular,
  do not assume PProd preserves an unconstrained Sort u without checking.
- tests/elab/indPredRecursion.lean: Prop-valued mutual and positive function-field
  recursion; tests/elab/structuralMutual.lean: common-universe restrictions.

PSC0 previously rejected every non-successor result before constructing its
packed motive, used Type-only Prod, and projected by that assumed owner. This
incorrectly excludes proof-valued definitions allowed by the selected grammar.
Use the native policy over PSC0's existing typed Core owner. PProd is already
in the audited selected P1 closure; no new declaration, export or axiom.

## Invariants and implementation

The existing MutualStructural owner now records the actual component level.
PackType/PackValue choose And/PProd from that level, check each actual component,
infer the packed product and compare its result sort to the real motive domain.
No guessed predecessor, implicit lift or relaxed universe equality. Empty
proposition slots use checked True/True.intro; other empty slots use existing
checked PUnit. Singleton packing remains identity. Projection checks source
bounds, infers the actual And/PProd owner, and validates each Core projection.
All existing strict-child, fixed-parameter, indexed-family, ownership, equation,
predicate-elimination and runtime-view checks stay in place.

This is an original implementation following upstream algorithms, not copied
implementation bodies. Keep upstream Apache-2.0 notices and references.

## Coherent validation scope

Extend existing fixtures only:
- Paired actual .lean/.ps inputs: three mutually recursive dependent equality
  proofs over Nat, checking every component position; two proof-valued functions
  over a positive function-valued inductive predicate; native Lean oracle and
  official kernel admission of generated definitions/equations.
- Existing internal mutual-data fixture: one proof-valued function whose companion
  family owns zero functions, exercising singleton and empty Prop packing.
- Existing Type-valued source and multi-family runtime observations exercise
  PProd through all five backends. No additional executable or CI lane.
- Preserve incompatible-universe, Acc Type-valued automatic recursion,
  nondecreasing calls, metadata/ownership and assurance negative controls.

A successful Prop slice does not claim arbitrary Sort-u packing, nested source
structural recursion or all M3+B exits complete. Those require native-positive
scope evidence and their own checked construction, not inferred acceptance.
