import Ps.Elab.MutualStructural

-- Raw typed header ownership shared by source validation and runtime recovery.
structure PsElabPreDefinitionOpened where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  type : PsExpr
  value : PsExpr

-- Consume only the retained raw header lambdas. Normalizing the value here
-- would conflate source parameters with a returned function's own lambdas.
def psElabPreDefinitionOpen (count : Nat) (context : PsElabContext)
    (type value : PsExpr) (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError PsElabPreDefinitionOpened := do
  match count with
  | 0 => return { context, bindersRev, type, value }
  | count + 1 =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext type).mapError PsElabError.infer
    let .lam _ domain body binder := value
      | throw (.data "PSCV0-PREDEFINITION-HEADER: retained source header exceeds the actual raw lambda prefix")
    if !psBinderInfoEq binder pi.binder ||
        !psExprFVarsInContext context.localContext domain ||
        !psElabMutualStructuralEqual context domain pi.domain then
      throw (.data "PSCV0-PREDEFINITION-HEADER: raw lambda binder differs from its checked header domain or kind")
    let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
    psElabPreDefinitionOpen count (psElabContextWithLocal context pushed.context)
      (psExprInstantiate1 pi.body (.fvar pushed.id))
      (psExprInstantiate1 body (.fvar pushed.id))
      (PsElabTypedBinder.mk pushed.id pi.name pi.domain pi.binder :: bindersRev)

