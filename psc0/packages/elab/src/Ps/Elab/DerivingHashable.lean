/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/Hashable.lean.
Copyright (c) 2021 Microsoft Corporation. Author: Dany Fabian.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: ordinary Core eliminators for the selected nonrecursive,
nonindexed family profile; shared telescope and dictionary elaboration.
-/
import Ps.Elab.DerivingContext

def psElabDeriveHashable (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin
  let className := psRootName "Hashable"
  let plan := psElabDeriveRequirements plan className
  -- Validate the complete family before generating any branch.
  let _ ← plan.info.constructors.mapM (psElabDeriveFields plan)
  let type ← psElabDeriveClassType plan.context className plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let method ← psElabDeriveEliminate plan plan.context (fun _ => uint64)
    (fun context constructor fields _ => do
      let seed := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
        (.lit (.natural constructor.constructorIndex))
      fields.foldlM (fun acc field => do
        -- Proof fields also participate. Their Hashable dictionary yields zero;
        -- its proposition may mention earlier fields in this branch.
        let target ← psElabDeriveClassType context className field.type
        let dictionary ← psElabDeriveInstance context target
        let .app (.constE _ levels) _ := target | throw .typeMismatch
        let hashed := psExprApplyMany (.constE (psNameAppendStr className "hash") levels)
          [field.type, dictionary, .fvar field.id]
        pure (psExprApplyMany (.constE (psRootName "mixHash") []) [acc, hashed])) seed)
  let value := psExprApplyMany (.constE (psNameAppendStr className "mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instHashable" type value
