import Ps.Elab.Equality
import Ps.Elab.Application

structure PsElabMatchAlternative where
  constructorName : PsName
  fieldNames : List PsSyntaxName
  elaborate : PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult
  span : PsSourceSpan

def psElabMatchAlternativeFind
    (name : PsName)
    (alternatives : List PsElabMatchAlternative) :
    Option PsElabMatchAlternative :=
  match alternatives with
  | [] => Option.none
  | alternative :: rest =>
      if psNameEq alternative.constructorName name then
        Option.some alternative
      else
        psElabMatchAlternativeFind name rest

def psElabMatchApplyParametersWorker
    (context : PsElabContext)
    (parameters : List PsExpr) :
    PsExpr ->
    Except PsElabError PsExpr :=
  match parameters with
  | [] =>
      fun (cursor : PsExpr) =>
        Except.ok cursor
  | parameter :: rest =>
      let smaller : PsExpr -> Except PsElabError PsExpr :=
        psElabMatchApplyParametersWorker
          context
          rest;
      fun (cursor : PsExpr) =>
        match psInferEnsureForall
            context.environment
            context.metaContext
            context.localContext
            cursor with
        | Except.error error =>
            Except.error (PsElabError.infer error)
        | Except.ok forallView =>
            smaller
              (psExprInstantiate1
                forallView.body
                parameter)

def psElabMatchApplyParameters
    (context : PsElabContext)
    (parameters : List PsExpr)
    (cursor : PsExpr) :
    Except PsElabError PsExpr :=
  psElabMatchApplyParametersWorker
    context
    parameters
    cursor

def psSyntaxNameIsWildcardBinder
    (name : PsSyntaxName) : Bool :=
  match name.segments with
  | List.nil =>
      false
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          psStringEq segment "_"
      | List.cons _ _ =>
          false

def psSyntaxNameMatchesCore
    (coreName : Option PsName)
    (candidate : PsSyntaxName) : Bool :=
  if psSyntaxNameIsWildcardBinder candidate then
    false
  else
    match coreName with
    | none =>
        false
    | some left =>
        match psSyntaxNameToName candidate with
        | none =>
            false
        | some right =>
            psNameEq left right

def psSyntaxNameListContainsCore
    (coreName : Option PsName)
    (candidates : List PsSyntaxName) : Bool :=
  match candidates with
  | List.nil =>
      false
  | List.cons candidate rest =>
      if psSyntaxNameMatchesCore coreName candidate then
        true
      else
        psSyntaxNameListContainsCore coreName rest

def psSyntaxNameListHasDuplicate
    (names : List PsSyntaxName) : Bool :=
  match names with
  | List.nil =>
      false
  | List.cons name rest =>
      if psSyntaxNameIsWildcardBinder name then
        psSyntaxNameListHasDuplicate rest
      else
        let coreName := psSyntaxNameToName name;
        if psSyntaxNameListContainsCore coreName rest then
          true
        else
          psSyntaxNameListHasDuplicate rest

-- One motive plan owns direct index abstraction, dependent context reversion,
-- and equality constraints for fixed, compound or repeated parent indices.
structure PsElabMatchPlan where
  motive : PsExpr
  indices : List (Nat × Nat)
  majorId : Option Nat
  constraintVariables : List Nat
  generalized : List PsElabDependentLocal
  constraints : List PsExpr
  arguments : List PsExpr

def psElabMatchIndexMap (parameters indices : List PsExpr) : List (Nat × Nat) :=
  (indices.zipIdx).filterMap fun entry =>
    match entry.fst with
    | .fvar id =>
      if (indices.filter (fun value => psExprAlphaEq value (.fvar id))).length == 1 &&
          !(parameters.any (psElabExprContainsLocal id)) then some (id, entry.snd)
      else none
    | _ => none

def psElabMatchMotive (context : PsElabContext) (info : PsInductiveInfo)
    (levels : List PsLevel) (parameters indices : List PsExpr)
    (major expected : PsExpr) : Except PsElabError PsElabMatchPlan := do
  let type := psExprInstantiateLevelParams info.levelParams levels info.type
  let cursor ← psElabMatchApplyParameters context parameters type
  let opened ← psElabOpenCoreTelescope 4096 context cursor (some info.numIndices)
  let freshIndices := psElabBinderArguments opened.bindersRev
  let indexMap := psElabMatchIndexMap parameters indices
  let constrained := indexMap.length != indices.length
  let indexMap := if constrained then [] else indexMap
  let substitutions := indexMap.filterMap fun entry =>
    (freshIndices[entry.snd]?).map (fun value => (entry.fst, value))
  let majorType := psExprApplyMany (.constE info.name levels) (parameters ++ freshIndices)
  let pushed := psLocalPushBinding opened.context.localContext (psRootName "_match") majorType .explicit
  let majorId := match major with
    | .fvar id => if parameters.any (psElabExprContainsLocal id) ||
        indices.any (psElabExprContainsLocal id) then none else some id
    | _ => none
  -- A constrained motive keeps outer indices in their original scope. Only
  -- equality elimination may generalize them and their dependent values.
  let constraintVariables := if !constrained then [] else
    context.localContext.declarations.filterMap fun declaration =>
      let id := psLocalDeclId declaration
      if indices.any (psElabExprContainsLocal id) &&
          !(parameters.any (psElabExprContainsLocal id)) then some id else none
  let roots := indexMap.map Prod.fst ++ majorId.toList
  let dependents := psElabDependentLocals context roots []
  let generalized := if constrained then [] else dependents
  if constrained then
    match majorId with
    | some id =>
      if psElabExprContainsLocal id expected ||
          dependents.any (fun entry => psElabExprContainsLocal id entry.binder.type) then
        throw (.refinement "fixed-index matching with major-dependent result/context requires heterogeneous transport")
    | none => pure ()
  let body := psElabCloseDependentType generalized expected
  let body := if constrained then body else
    psElabSubstituteLocals (substitutions ++ majorId.toList.map (fun id => (id, .fvar pushed.id))) body
  let equations ← if !constrained then pure [] else
    (indices.zip freshIndices).mapM fun entry => do
      let type ← (psInferType context.environment context.metaContext context.localContext entry.fst).mapError PsElabError.infer
      let level ← psElabExpressionSort context type
      return (psLogicEq level type entry.snd entry.fst, psLogicRefl level type entry.fst)
  let body := (equations.zipIdx).foldr (fun entry body =>
    psLogicPi (pushed.id + 1 + entry.snd) "_indexEq" entry.fst.fst body) body
  let motive := psCloseElabLambdaBinders context.metaContext opened.bindersRev
    (.lam (psRootName "_match") majorType (psExprAbstractFVar pushed.id body) .explicit)
  return {
    motive, indices := indexMap, majorId, constraintVariables, generalized
    constraints := equations.map Prod.fst
    arguments := equations.map Prod.snd ++
      psElabDependentArguments generalized }

def psElabMatchFields (names : List PsSyntaxName) (context : PsElabContext)
    (cursor : PsExpr) (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError PsElabOpenTelescope := do
  match names with
  | [] => return { context, bindersRev, body := cursor }
  | source :: rest =>
    let some name := psSyntaxNameToName source | throw .emptyName
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let pushed := psLocalPushBinding context.localContext name pi.domain pi.binder
    psElabMatchFields rest (psElabContextWithLocal context pushed.context)
      (psExprInstantiate1 pi.body (.fvar pushed.id))
      (PsElabTypedBinder.mk pushed.id name pi.domain pi.binder :: bindersRev)

def psElabMatchHypotheses (fields : List PsElabTypedBinder) (recursiveFields : List Nat)
    (context : PsElabContext) (cursor : PsExpr)
    (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError PsElabOpenTelescope := do
  match recursiveFields with
  | [] => return { context, bindersRev, body := cursor }
  | index :: rest =>
    let some field := fields[index]? | throw .structuralRecursionInternal
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let name := psNameAppendNum (psRootName "_ih") index
    let pushed := psLocalPushBinding context.localContext name pi.domain pi.binder
    let next := psElabContextWithLocal context pushed.context
    let next := match context.structuralRecursion with
      | some recursion => if recursion.collectCalls then
          psElabContextWithStructuralRecursion next
            (some { recursion with calls := (field.id, pushed.id) :: recursion.calls })
        else next
      | none => next
    psElabMatchHypotheses fields rest next
      (psExprInstantiate1 pi.body (.fvar pushed.id))
      (PsElabTypedBinder.mk pushed.id name pi.domain pi.binder :: bindersRev)

def psElabMatchAnonymousFields (context : PsElabContext) (type : PsExpr) (count : Nat) :
    Except PsElabError PsElabOpenTelescope := do
  let opened ← psElabOpenCoreTelescope 4096 context type (some count)
  let ids := opened.bindersRev.map (fun binder => binder.id)
  let name := fun id => psNameAppendNum (psRootName "_matchField") id
  let declarations := opened.context.localContext.declarations.map fun declaration =>
    match declaration with
    | .binding id original type binder =>
      .binding id (if ids.contains id then name id else original) type binder
    | _ => declaration
  return { opened with
    context := psElabContextWithLocal opened.context { opened.context.localContext with declarations }
    bindersRev := opened.bindersRev.map (fun binder => { binder with name := name binder.id }) }

structure PsElabMatchMinorResult where
  context : PsElabContext
  term : PsExpr

def psElabMatchMinor (context : PsElabContext)
    (info : PsInductiveInfo) (levels : List PsLevel) (parameters : List PsExpr)
    (plan : PsElabMatchPlan) (ctorName : PsName) (alternative : Option PsElabMatchAlternative)
    (minorType : PsExpr) : Except PsElabError PsElabMatchMinorResult := do
  let some ctor := psEnvironmentFindConstructor context.environment ctorName
    | throw (.matchConstructorUnknown ctorName)
  let names := alternative.map (·.fieldNames)
  let fields ← match names with
    | none => psElabMatchAnonymousFields context minorType ctor.numFields
    | some names =>
      if names.length != ctor.numFields || psSyntaxNameListHasDuplicate names then
        throw (.matchConstructorArity ctor.name)
      psElabMatchFields names context minorType
  let values := psElabBinderArguments fields.bindersRev
  let constructor := psExprApplyMany (.constE ctor.name levels) (parameters ++ values)
  let constructorType ← (psInferType fields.context.environment fields.context.metaContext
    fields.context.localContext constructor).mapError PsElabError.infer
  let result := psExprAppView (psWhnf fields.context.environment fields.context.metaContext
    fields.context.localContext constructorType)
  let indices := result.args.drop info.numParams
  let substitutions := plan.indices.filterMap fun entry =>
    (indices[entry.snd]?).map (fun value => (entry.fst, value))
  let substitutions := match plan.majorId with
    | none => substitutions
    | some id => substitutions ++ [(id, constructor)]
  let aliases ← substitutions.foldlM psElabMatchAlias { context := fields.context, valuesRev := [] }
  let hypotheses ← psElabMatchHypotheses fields.bindersRev.reverse ctor.recursiveFields
    aliases.context fields.body
  let finish := fun context target => do
    let some alternative := alternative | throw PsElabError.matchNonExhaustive
    let generalized ← psElabOpenDependents plan.generalized {
      context, body := target, bindersRev := [], aliasesRev := []
      replacements := substitutions }
    let body ← alternative.elaborate (psElabContextAfterStructuralFields generalized.context)
      generalized.body
    return PsElabTermResult.mk (psElabLeaveScope context body.context)
      (psElabCloseDependents generalized body.context.metaContext body.term) target
  let flexible := fields.bindersRev.map (fun binder => binder.id) ++ plan.constraintVariables
  let body ← psElabSolveIndexConstraints 256 plan.constraints.length flexible (hypotheses.bindersRev.map (fun binder => binder.id))
    finish hypotheses.context hypotheses.body
  let value := psElabSubstituteLocals aliases.valuesRev
    (psMetaInstantiate body.context.metaContext body.term)
  let closed := psCloseElabLambdaBinders body.context.metaContext fields.bindersRev
    (psCloseElabLambdaBinders body.context.metaContext hypotheses.bindersRev value)
  return { context := psElabLeaveScope context body.context, term := closed }

structure PsElabMatchMinorsResult where
  context : PsElabContext
  minors : List PsExpr

def psElabMatchMinors (info : PsInductiveInfo)
    (levels : List PsLevel) (parameters : List PsExpr) (plan : PsElabMatchPlan)
    (alternatives : List PsElabMatchAlternative) (constructors : List PsName)
    (context : PsElabContext) (cursor : PsExpr) :
    Except PsElabError PsElabMatchMinorsResult := do
  match constructors with
  | [] => return { context, minors := [] }
  | name :: rest =>
    let alternative := psElabMatchAlternativeFind name alternatives
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let minor ← psElabMatchMinor context info levels parameters plan name alternative pi.domain
    let tail ← psElabMatchMinors info levels parameters plan alternatives rest
      minor.context (psExprInstantiate1 pi.body minor.term)
    return { context := tail.context, minors := minor.term :: tail.minors }

def psElabStructuralMatchContext (context : PsElabContext)
    (scrutinee expected : PsExpr) (plan : PsElabMatchPlan) (numIndices : Nat) : PsElabContext :=
  match context.structuralRecursion with
  | none => context
  | some recursion =>
    let permitted := recursion.collectCalls &&
      psExprAlphaEq (psMetaInstantiate context.metaContext expected)
        (psMetaInstantiate context.metaContext recursion.resultType) &&
      (match scrutinee, psElabStructuralParameterAt recursion.explicitParameterIds
          recursion.recursiveParameterIndex with
        | .fvar id, some majorId => id == majorId
        | _, _ => false) &&
      plan.indices.length == numIndices &&
      plan.indices.all (fun entry => recursion.explicitParameterIds.contains entry.fst)
    psElabContextWithStructuralRecursion context (some { recursion with
      collectCalls := permitted
      indices := if permitted then plan.indices else recursion.indices
      refined := if permitted then plan.majorId.isSome else recursion.refined })

def psElabMatchMotiveLevel (context : PsElabContext) (motive : PsExpr) :
    Except PsElabError PsLevel := do
  let type ← (psInferType context.environment context.metaContext
    context.localContext (psMetaInstantiate context.metaContext motive)).mapError PsElabError.infer
  let telescope ← psElabOpenCoreTelescope 4096 context type none
  (psInferEnsureSort context.environment context.metaContext
    telescope.context.localContext telescope.body).mapError PsElabError.infer

def psElabMatchWith (elaborate : PsElaborator)
    (prepare : PsElabContext -> PsInductiveInfo -> Except PsElabError (List PsElabMatchAlternative))
    (context : PsElabContext) (scrutineeSyntax : PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let some expectedType := expected | throw .matchExpectedType
  let scrutinee ← elaborate context scrutineeSyntax none
  let context := scrutinee.context
  let typeView := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext scrutinee.type)
  let .constE name levels := typeView.head | throw .matchScrutineeUnsupported
  let some info := psEnvironmentFindInductive context.environment name
    | throw .matchScrutineeUnsupported
  if typeView.args.length != info.numParams + info.numIndices then throw .matchParameterArity
  let parameters := typeView.args.take info.numParams
  let indices := typeView.args.drop info.numParams
  let alternatives ← prepare context info
  let recursorName := psNameAppendStr name "rec"
  let some recursor := psEnvironmentFindRecursor context.environment recursorName
    | throw .matchRecursorUnsupported
  if recursor.numParams != info.numParams || recursor.numIndices != info.numIndices ||
      recursor.numMotives != 1 || recursor.numMinors != info.constructors.length then
    throw .matchRecursorUnsupported
  let expectedType := psMetaInstantiate context.metaContext expectedType
  let plan ← psElabMatchMotive context info levels parameters indices scrutinee.term expectedType
  -- Reverted dependent parameters can raise the motive's universe above that
  -- of the original expected result. Infer the completed motive, not a proxy.
  let level ← psElabMatchMotiveLevel context plan.motive
  let recursorLevels ← psElabRecursorLevels info recursor levels level
  let minorContext := psElabStructuralMatchContext context scrutinee.term expectedType plan info.numIndices
  let recursorType := psExprInstantiateLevelParams recursor.levelParams recursorLevels recursor.type
  let cursor ← psElabMatchApplyParameters context (parameters ++ [plan.motive]) recursorType
  let minors ← psElabMatchMinors info levels parameters plan alternatives info.constructors
    minorContext cursor
  let term := psExprApplyMany (.constE recursorName recursorLevels)
    (parameters ++ [plan.motive] ++ minors.minors ++ indices ++ [scrutinee.term] ++ plan.arguments)
  psElabResolvedTerm (psElabLeaveScope context minors.context) term (some expectedType)

