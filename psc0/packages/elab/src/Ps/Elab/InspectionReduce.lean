import Ps.Elab.Basic
import Ps.Meta.TypeView
import Ps.Environment.Inspection
import Ps.Elab.InspectionScalar

/-!
Inspection reduction reports exhaustion instead of a truncated residual.
Registered Core recursor/quotient metadata owns IOTA. The default #reduce policy
follows Lean 4.35.0 Meta/Reduce.lean, Elab/BuiltinCommand.lean and Init/MetaTypes
(Apache-2.0, Microsoft Corporation and Leonardo de Moura). Execution rules and
opening of opaque bodies are local to #eval; conversion is unchanged.
-/

def psInspectionError (message : String) : PsElabError :=
  .data ("PSCV0-INSPECTION: " ++ message)

def psInspectionBody (execution : Bool) : PsDeclaration → Option PsExpr
  | .definitionDecl _ _ _ value => some value
  | .opaqueDecl _ _ _ value | .theoremDecl _ _ _ value =>
    if execution then some value else none
  | _ => none

def psInspectionWhnf (fuel : Nat) (context : PsElabContext)
    (execution : Bool) (expression : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let step := psInspectionWhnf fuel context execution
    let view := psReduceAppView (psMetaInstantiate context.metaContext expression)
    let applied := psExprApplyMany view.head view.args
    match view.head with
    | .fvar id =>
      match psLocalFindById context.localContext id with
      | some (.letDecl _ _ _ value) => step (psExprApplyMany value view.args)
      | _ => return applied
    | .letE _ _ value body =>
      step (psExprApplyMany (psExprInstantiate1 body value) view.args)
    | .lam _ _ body _ =>
      match view.args with
      | [] => return view.head
      | first :: rest => step (psExprApplyMany (psExprInstantiate1 body first) rest)
    | .proj owner index major =>
      let major ← step major
      if execution then
        if let some value := psInspectionPlatformProjection owner index major then
          return ← step (psExprApplyMany value view.args)
      match psReduceProjectionIota (fun value => value) context.environment owner index major with
      | some value => step (psExprApplyMany value view.args)
      | none => return psExprApplyMany (.proj owner index major) view.args
    | .constE name levels =>
      if execution then
        if let some arity := psInspectionScalarArity name then
          if view.args.length < arity then return applied
          let arguments ← (view.args.take arity).mapM (fun argument =>
            step (psInspectionScalarInput name argument))
          let tail := view.args.drop arity
          match psInspectionScalarEval name arguments with
          | some value => return ← step (psExprApplyMany value tail)
          | none =>
            let originalArguments ← (view.args.take arity).mapM step
            return psExprApplyMany view.head (originalArguments ++ tail)
      if psNameEq name psNatZeroName then
        return ← step (psExprApplyMany (.lit (.natural 0)) view.args)
      let scalarArgs ←
        if (psNameEq name psNatSuccName && view.args.length == 1) ||
            ((psReduceNatBinary name).isSome && view.args.length == 2) then
          view.args.mapM step
        else pure view.args
      let scalar := psExprApplyMany view.head scalarArgs
      if let some value := psReduceNatPrimitive (fun value => value) scalar then
        return ← step value
      -- The actual major is forced by this error-reporting owner. The ordinary
      -- metadata callback is used only to inspect registered telescope shape.
      let candidate ← match psEnvironmentFindRecursor context.environment name with
        | some info => do
          let position := info.numParams + info.numMotives + info.numMinors + info.numIndices
          match scalarArgs[position]? with
          | none => pure none
          | some major => do
            let major ← step major
            let args := scalarArgs.take position ++ [major] ++ scalarArgs.drop (position + 1)
            let value := psExprApplyMany view.head args
            let metadataReduce := psWhnf context.environment context.metaContext context.localContext
            match psReduceIota metadataReduce context.environment value with
            | some reduced => pure (some reduced)
            | none =>
              let majorHead := (psReduceAppView major).head
              let constructor? := match majorHead with
                | .constE constructorName _ => psEnvironmentFindConstructor context.environment constructorName
                | _ => none
              if constructor?.isSome || (psInspectionNatural major).isSome then
                throw (psInspectionError ("registered recursor did not reduce: " ++ psNameToString name))
              pure none
        | none =>
          match psEnvironmentFind context.environment name with
          | some (.quotientDecl _ _ _ kind) => do
            let position? := match kind with | .lift => some 5 | .ind => some 4 | _ => none
            match position? with
            | none => pure none
            | some position =>
              match scalarArgs[position]? with
              | none => pure none
              | some major => do
                let major ← step major
                let args := scalarArgs.take position ++ [major] ++ scalarArgs.drop (position + 1)
                pure (psReduceQuotientIota (fun value => value) context.environment
                  (psExprApplyMany view.head args))
          | _ => pure none
      if let some value := candidate then return ← step value
      match psEnvironmentFind context.environment name with
      | none => throw (psInspectionError ("unknown constant " ++ psNameToString name))
      | some declaration =>
        match psInspectionBody execution declaration with
        | none => return scalar
        | some value =>
          let parameters := psDeclarationLevelParams declaration
          if parameters.length != levels.length then throw .typeMismatch
          step (psExprApplyMany (psExprInstantiateLevelParams parameters levels value) scalarArgs)
    | _ => return applied

def psInspectionIsErased (context : PsElabContext) (expression : PsExpr)
    (execution : Bool := false) : Except PsElabError Bool := do
  let type ← (if execution then psExprTypeView context.environment context.localContext expression
    else psInferType context.environment context.metaContext context.localContext expression).mapError PsElabError.infer
  let type := psMetaInstantiate context.metaContext type
  match psWhnf context.environment context.metaContext context.localContext type with
  | .sortE _ => return true
  | _ =>
    let sort ← (if execution then psExprTypeView context.environment context.localContext type
      else psInferType context.environment context.metaContext context.localContext type).mapError PsElabError.infer
    match psWhnf context.environment context.metaContext context.localContext sort with
    | .sortE level => return psLevelNormalizesToZero level
    | .mvar _ => return false
    | _ => throw .typeMismatch

-- Static source checking precedes execution. The execution branch uses the
-- ordinary annotation view so evaluated opaque scalar values never demand a
-- fabricated dependent proof or enter conversion checks.
def psInspectionNormalize (fuel : Nat) (context : PsElabContext)
    (execution : Bool) (expression : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if ← psInspectionIsErased context expression execution then
      return psMetaInstantiate context.metaContext expression
    let normalized ← psInspectionWhnf (fuel + 1) context execution expression
    let visit := psInspectionNormalize fuel context execution
    let finish := fun value => do
      let reduced ← psInspectionWhnf (fuel + 1) context execution value
      if psExprAlphaEq reduced value then pure value else visit reduced
    match normalized with
    | .app .. =>
      let view := psReduceAppView normalized
      let type ← (psInferType context.environment context.metaContext
        context.localContext view.head).mapError PsElabError.infer
      let (_, arguments) ← view.args.foldlM
        (fun (state : PsExpr × List PsExpr) argument => do
          let pi ← (psInferEnsureForall context.environment context.metaContext
            context.localContext state.1).mapError PsElabError.infer
          let selected := execution || psBinderInfoEq pi.binder .explicit
          let argument ← if selected then visit argument else pure argument
          return (psExprInstantiate1 pi.body argument, state.2 ++ [argument])) (type, [])
      finish (psExprApplyMany view.head arguments)
    | .lam name domain body binder =>
      let pushed := psLocalPushBinding context.localContext name domain binder
      let inner := psElabContextWithLocal context pushed.context
      let body ← psInspectionNormalize fuel inner execution
        (psExprInstantiate1 body (.fvar pushed.id))
      return .lam name domain (psExprAbstractFVar pushed.id body) binder
    | .proj owner index major =>
      finish (.proj owner index (← visit major))
    | _ => return normalized

def psInspectionReduce (context : PsElabContext) (expression : PsExpr) :
    Except PsElabError PsExpr :=
  psInspectionNormalize 4096 context false expression
