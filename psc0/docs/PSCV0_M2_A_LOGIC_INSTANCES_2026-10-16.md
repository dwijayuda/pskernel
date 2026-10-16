# M2+A: explicit basic order and constructive decisions

## Design and pinned reference

Lean 4.35.0, eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
- [Init/Prelude.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Prelude.lean): Nat LT/LE, reversed GT/GE, Decidable's Boolean payload, constructive And/Or/Not.
- [Init/Core.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Core.lean): constructive True/False, implication and Iff decisions.
- [Init/Data/Int/Basic.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Int/Basic.lean): Int order dictionaries and decLe/decLt.
Upstream attribution: Microsoft Corporation / Lean FRO, LLC, Apache-2.0; see THIRD_PARTY_NOTICES.md.

Native38804150832 compiled the previous slice and passed its strict registry and checked asset gates, then refused comparisonNotation: the checked native LT/LE declarations were logical dependencies, but were never selected as instances. Source notation exposed that missing selection layer. This is not evidence of an invalid checked declaration or a need to special-case conditionals.

## Architecture

StandardLogicInstances explicitly selects thirteen existing checked definitions: Nat/Int LT/LE, Int.decLt/decLe and seven constructive proposition decisions. Dependency inclusion never means implicit instance registration. The strict audit verifies every name, definition kind, class and registration. The frozen exporter boundaries remain unchanged, with no new declarations or assumptions.

The ordinary synthetic-constraint scheduler and structural table keys resolve these dictionaries. Runtime selection includes the native instBEqOfDecidableEq and instDecidableEqBool dependencies for Iff, and the selected constructive definitions. Int decisions lower to the existing typed Int comparison operations, and Bool.beq to boolEq, using the same arity/partial-application boundary as other primitives. PrimitiveAudit verifies their exact pinned native signatures; differential execution and kernel checking remain separate evidence.

## Qualification

Six compact native Lean observations are mirrored in the existing shared JS/TS/Rust runtime ledger: three compound Nat propositions (And, Or, Not, implication, Iff, True, False) and three negative/equal/positive Int order cases. The existing three comparison-alias observations remain. No new test runner, new backend IR operation, resource relaxation or trusted axiom.

Implementation is pending cloud qualification. Keep the previous registry digests until strict independent entry points report agreeing new values. Full source/kernel/IR/module, all backend, GC/ABI, and existing solver/performance gates are required before calling this slice qualified.

Native38806446169 compiled the logic layer and all six pinned decision observations, then its strict audit refused a mistaken runtime dependency name. Direct inspection of the frozen native Core DAG confirms that instDecidableIff uses instBEqOfDecidableEq applied to instDecidableEqBool, not a ground instBEqBool. The runtime catalogue and strict dependency audit now select those exact checked dependencies; no logical body, acceptance criterion or registration changed. Digest selection and complete source/runtime qualification remain pending.


## Conditional proposition classification

Cloud run 38808961871 at a08346dc isolated the compound source failure to `logicImplies`. The conditional owner matched only literal `Sort 0`, while the forall elaborator correctly retained `Sort (imax 0 0)`. Lean 4.35.0 `src/Lean/Meta/InferType.lean` (`isAlwaysZero`, `isProp`) recognizes all levels equivalent to zero. PSC0 now uses its existing read-only definitional equality against Prop, which handles instantiated equivalent levels without assigning an unknown type to Prop. No new unifier or logical definition is introduced. The existing seven named logical forms and six shared runtime vectors remain unchanged; the implication vector is the regression. Upstream conditional coverage reviewed: `tests/elab/ifThenElseIssue.lean`, `ifThenElseIssue2.lean`. Validation pending.

## Shared decision scheduling

Native run 38809845902 at 7fde856b passed implication and reached `FilterCases.high`, where a polymorphic callback precedes the array that determines its domain. The conditional owner still used immediate instance search, unlike normal implicit arguments. Conditions and Prop-to-Bool conversion now create a scoped synthetic Decidable metavariable and use the existing transactional queue. The resulting evidence remains checked Core; ordinary rigid missing-instance diagnostics remain unchanged. This follows pinned Lean `Elab/App.lean` and `Elab/SyntheticMVars.lean`: defer stuck instance inputs, synthesize after expected/argument constraints, apply defaults only at quiescence. Existing high-universe filter and logical vectors validate the mechanism; no special filter/type case is added. Full validation pending.

Int equality: exact checked Int.decEq/Int.instDecidableEq dependencies and signature audits passed at0165db79. Int.decEq is lowered through intEq with partial-application completion, like Int.decLt/decLe; it must not also enter the runtime declaration catalogue as a native proof/match implementation. Native38814381644 exposed that catalogue ownership error before platform refusal qualification; corrected without changing logical declarations. Backend parity remains pending.
