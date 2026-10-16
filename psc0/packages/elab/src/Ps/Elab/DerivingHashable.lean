/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/Hashable.lean.
Copyright (c) 2021 Microsoft Corporation. Author: Dany Fabian.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: ordinary Core recursors for complete uniform direct groups,
including indexed children. Recursive field hashes come from their actual
member's checked induction hypotheses; nested recursion and partial fallback
are outside the selected field boundary.
-/
import Ps.Elab.DerivingContext

def psElabDeriveHashable (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin { groups := true, indices := true }
  let className := psRootName "Hashable"
  let plan := psElabDeriveRequirements plan className
  -- Validate the complete family before generating any branch.
  let _ ← (psElabDeriveConstructorNames plan).mapM fun name =>
    psElabDeriveFieldsWithRecursion plan name true
  let type ← psElabDeriveClassType plan.context className plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let method ← psElabDeriveEliminateGroup plan plan.context true (fun _ _ _ => uint64)
    (fun context _ constructor fields hypotheses _ => do
      let seed := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
        (.lit (.natural constructor.constructorIndex))
      fields.foldlM (fun acc field => do
        let hashed ← match hypotheses.find? (fun entry => entry.fst == field.id) with
          | some (_, value) => pure value
          | none => do
            -- Nonrecursive fields, including proofs, retain the selected
            -- dictionary behavior. Recursive fields need no self instance.
            let target ← psElabDeriveClassType context className field.type
            let dictionary ← psElabDeriveInstance context target
            let .app (.constE _ levels) _ := target | throw .typeMismatch
            pure (psExprApplyMany (.constE (psNameAppendStr className "hash") levels)
              [field.type, dictionary, .fvar field.id])
        pure (psExprApplyMany (.constE (psRootName "mixHash") []) [acc, hashed])) seed)
  let value := psExprApplyMany (.constE (psNameAppendStr className "mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instHashable" type value

