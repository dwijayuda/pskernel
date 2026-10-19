import Ps.Elab.InspectionDependencies
import Ps.Elab.DerivingRepr
import Ps.Elab.Term

def psInspectionFormatUsing (result : PsElabTermResult) (repr : Bool) :
    Except PsElabError PsElabTermResult := do
  let className := psRootName (if repr then "Repr" else "ToString")
  let (context, head) ← psElabResolvedReference result.context (.global className)
  let target ← psElabApplyCore context head [result.type]
  let dictionary ← psElabSynthesizeInstance target.context target.term
  let dictionary ← psElabDrainPending (psElabTermWithFuel 4096) dictionary
  let functionName := if repr then psRootName "reprStr"
    else psNameAppendStr (psRootName "ToString") "toString"
  let (context, head) ← psElabResolvedReference dictionary.context (.global functionName)
  psElabApplyCore context head [result.type, dictionary.term, result.term]

def psInspectionFreshReprName (fuel : Nat) (environment : PsEnvironment) (index : Nat) :
    Except PsElabError PsName := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let name := psNameAppendNum (psRootName "$psc0InspectionRepr") index
    if psEnvironmentContains environment name then psInspectionFreshReprName fuel environment (index + 1)
    else return name

-- Native #eval may derive Repr for the actual top-level inductive family when
-- neither Repr nor ToString is available. The ordinary checked handler owns
-- all field requirements. Its temporary result is never published.
def psInspectionDeriveRepr (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  let view := psReduceAppView (psWhnf result.context.environment result.context.metaContext
    result.context.localContext result.type)
  let .constE family _ := view.head
    | throw (psInspectionError "#eval has no Repr or ToString instance")
  let declaration ← psElabDeriveReprForFamily result.context.environment family
  let .definitionDecl _ levels type body := declaration | throw .typeMismatch
  let context := psElabContextEmpty result.context.environment levels
  let _ ← psElabExpressionSort context type
  let checked ← psElabResolvedTerm context body (some type)
  if psExprHasUnresolvedMeta checked.term || psExprHasUnresolvedMeta checked.type ||
      !(psExprFVarIds checked.term).isEmpty || !(psExprFVarIds checked.type).isEmpty then
    throw .unresolvedMetavariable
  let name ← psInspectionFreshReprName (result.context.environment.declarations.length + 1)
    result.context.environment 0
  let some environment := psEnvironmentAdd result.context.environment
      (.definitionDecl name levels checked.type checked.term)
    | throw (.duplicateDeclaration name)
  let environment ← psElabRegisterInstance environment name 1000
  psInspectionFormatUsing { result with
    context := { result.context with environment, instances := environment.instances } } true

def psInspectionFormatter (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  match psInspectionFormatUsing result true with
  | .ok rendered => return rendered
  | .error error => if psElabErrorIsResource error then throw error
  match psInspectionFormatUsing result false with
  | .ok rendered => return rendered
  | .error error => if psElabErrorIsResource error then throw error
  psInspectionDeriveRepr result

-- Resolve aliases one head step at a time so an effect boundary cannot vanish
-- inside unrestricted unfolding of its representation.
def psInspectionIsEffectType (fuel : Nat) (context : PsElabContext) (type : PsExpr) :
    Except PsElabError Bool := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let view := psReduceAppView (psMetaInstantiate context.metaContext type)
    match view.head with
    | .constE name levels =>
      if ["IO", "EIO", "BaseIO", "ST", "EST"].any (fun text => psNameEq name (psRootName text)) then
        return true
      match psEnvironmentFind context.environment name with
      | some (.definitionDecl _ parameters _ body) =>
        if parameters.length != levels.length then throw .typeMismatch
        psInspectionIsEffectType fuel context
          (psExprApplyMany (psExprInstantiateLevelParams parameters levels body) view.args)
      | _ => return false
    | .lam _ _ body _ =>
      match view.args with
      | first :: rest =>
        psInspectionIsEffectType fuel context (psExprApplyMany (psExprInstantiate1 body first) rest)
      | [] => return false
    | .letE _ _ value body =>
      psInspectionIsEffectType fuel context (psExprApplyMany (psExprInstantiate1 body value) view.args)
    | _ => return false

def psInspectionEval (result : PsElabTermResult) : Except PsElabError String := do
  let context := result.context
  let result := { result with
    term := psMetaInstantiate context.metaContext result.term
    type := psMetaInstantiate context.metaContext result.type }
  if psExprHasUnresolvedMeta result.term || psExprHasUnresolvedMeta result.type then
    throw .unresolvedMetavariable
  if !(psExprFVarIds result.term).isEmpty then
    throw (psInspectionError "#eval requires a closed value")
  if ← psInspectionIsEffectType 4096 context result.type then
    throw (psInspectionError "#eval requires a pure total value; effects are outside the selected command")
  let result ← match psWhnf context.environment context.metaContext context.localContext result.type with
    | .sortE level =>
      if psLevelEquivalent level .zero then psElabDecideProposition result
      else throw (psInspectionError "#eval cannot evaluate a type")
    | _ =>
      if ← psInspectionIsErased context result.term then
        throw (psInspectionError "#eval cannot evaluate a proof")
      pure result
  let formatted ← psInspectionFormatter result
  let formatted ← psElabDrainPending (psElabTermWithFuel 4096) formatted
  let environment ← (psInspectionExecutionEnvironment formatted.context.environment).mapError
    psInspectionError
  let context := { formatted.context with environment }
  let term := psMetaInstantiate context.metaContext formatted.term
  if psExprHasUnresolvedMeta term || !(psExprFVarIds term).isEmpty then throw .unresolvedMetavariable
  let visited ← psInspectionExecutable 4096 context [] result.term
  let _ ← psInspectionExecutable 4096 context visited term
  let value ← psInspectionNormalize 4096 context true term
  match value with
  | .lit (.string message) => return message
  | _ => throw (psInspectionError "#eval did not produce a fully evaluated checked formatter result")
