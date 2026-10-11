import Ps.Elab.Equality
import Ps.Elab.Application

def psMatchNameEqTarget
    (target : PsName)
    (name : PsName) : Bool :=
  psNameEq name target

def psMatchNameListContains
    (names : List PsName)
    (target : PsName) : Bool :=
  match names with
  | [] =>
      false
  | name :: rest =>
      if psMatchNameEqTarget target name then
        true
      else
        psMatchNameListContains rest target

structure PsElabMatchAlternative where
  constructorName : PsName
  pattern : PsSyntaxPattern
  body : PsSyntaxTerm
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

def psElabMatchAlternativeCovered
    (alternatives : List PsElabMatchAlternative)
    (ctorName : PsName) : Bool :=
  match psElabMatchAlternativeFind ctorName alternatives with
  | some _ => true
  | none => false

def psElabFillWildcardAlternatives
    (pattern : PsSyntaxPattern)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan)
    (constructors : List PsName) :
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative :=
  match constructors with
  | [] =>
      fun (alternativesRev : List PsElabMatchAlternative) =>
        alternativesRev
  | ctorName :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          List PsElabMatchAlternative :=
        psElabFillWildcardAlternatives
          pattern
          body
          span
          rest;
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let next : List PsElabMatchAlternative :=
          match psElabMatchAlternativeFind ctorName alternativesRev with
          | some _ => alternativesRev
          | none =>
              let alternative : PsElabMatchAlternative := {
                constructorName := ctorName
                pattern := pattern
                body := body
                span := span
              };
              List.cons alternative alternativesRev;
        smaller next

def psElabMatchAlternativeListReverseAux
    (values : List PsElabMatchAlternative) :
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative :=
  match values with
  | [] =>
      fun (acc : List PsElabMatchAlternative) => acc
  | value :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          List PsElabMatchAlternative :=
        psElabMatchAlternativeListReverseAux rest;
      fun (acc : List PsElabMatchAlternative) =>
        smaller (List.cons value acc)

def psElabMatchAlternativeListReverse
    (values : List PsElabMatchAlternative) :
    List PsElabMatchAlternative :=
  psElabMatchAlternativeListReverseAux values []

def psElabMatchAlternativesCoverConstructors
    (alternatives : List PsElabMatchAlternative)
    (constructors : List PsName) : Bool :=
  match constructors with
  | [] => true
  | constructorName :: rest =>
      if
          psElabMatchAlternativeCovered
            alternatives
            constructorName then
        psElabMatchAlternativesCoverConstructors alternatives rest
      else
        false

def psElabMatchPatternConstructorName
    (inductiveInfo : PsName)
    (pattern : PsSyntaxPattern) :
    Except PsElabError PsName :=
  match pattern with
  | .bool value _ =>
      if psNameEq inductiveInfo psBoolName then
        if value then
          Except.ok psBoolTrueName
        else
          Except.ok psBoolFalseName
      else
        Except.error PsElabError.matchPatternUnsupported
  | .wildcard _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .constructor syntaxName _ _ =>
      match syntaxName.segments with
      | [] => Except.error PsElabError.matchPatternUnsupported
      | segment :: rest =>
          match rest with
          | [] =>
              Except.ok (psNameAppendStr inductiveInfo segment)
          | _ :: _ =>
              match psSyntaxNameToName syntaxName with
              | none => Except.error PsElabError.matchPatternUnsupported
              | some name => Except.ok name

def psElabPrepareMatchAlternativesWorker
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) :
    List PsElabMatchAlternative ->
    Except PsElabError (List PsElabMatchAlternative) :=
  match entries with
  | [] =>
      fun (alternativesRev : List PsElabMatchAlternative) =>
        Except.ok (psElabMatchAlternativeListReverse alternativesRev)
  | entry :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          Except PsElabError (List PsElabMatchAlternative) :=
        psElabPrepareMatchAlternativesWorker
          inductiveInfo
          rest;
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let pattern := Prod.fst entry;
        let payload := Prod.snd entry;
        let body := Prod.fst payload;
        let span := Prod.snd payload;
        match pattern with
        | .wildcard _ =>
            match rest with
            | [] =>
                Except.ok
                  (psElabMatchAlternativeListReverse
                    (psElabFillWildcardAlternatives
                      pattern
                      body
                      span
                      inductiveInfo.constructors
                      alternativesRev))
            | _ :: _ =>
                Except.error PsElabError.matchPatternUnsupported
        | _ =>
            match psElabMatchPatternConstructorName
                inductiveInfo.name
                pattern with
            | Except.error error => Except.error error
            | Except.ok ctorName =>
                if psElabBoolNot
                    (psMatchNameListContains
                      inductiveInfo.constructors
                      ctorName) then
                  Except.error
                    (PsElabError.matchConstructorUnknown ctorName)
                else
                  match
                      psElabMatchAlternativeFind
                        ctorName
                        alternativesRev with
                  | some _ =>
                      Except.error
                        (PsElabError.matchDuplicateConstructor ctorName)
                  | none =>
                      let alternative : PsElabMatchAlternative := {
                        constructorName := ctorName
                        pattern := pattern
                        body := body
                        span := span
                      };
                      smaller
                        (List.cons alternative alternativesRev)

def psElabPrepareMatchAlternatives
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
    (alternativesRev : List PsElabMatchAlternative) :
    Except PsElabError (List PsElabMatchAlternative) :=
  psElabPrepareMatchAlternativesWorker
    inductiveInfo
    entries
    alternativesRev

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
  auxiliary : List PsElabDependentLocal
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
  let auxiliary := if !constrained then [] else
    context.localContext.declarations.reverse.filterMap fun declaration =>
      let id := psLocalDeclId declaration
      if indices.any (psElabExprContainsLocal id) && !(parameters.any (psElabExprContainsLocal id)) then
        some (PsElabDependentLocal.mk
          (PsElabTypedBinder.mk id (psLocalDeclUserName declaration) (psLocalDeclType declaration) .explicit) none)
      else none
  let roots := (if constrained then auxiliary.map (fun entry => entry.binder.id) else indexMap.map Prod.fst) ++ majorId.toList
  let generalized := psElabDependentLocals context roots []
  if constrained then
    match majorId with
    | some id =>
      if psElabExprContainsLocal id expected ||
          generalized.any (fun entry => psElabExprContainsLocal id entry.binder.type) then
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
  let body := psElabCloseDependentType auxiliary body
  let motive := psCloseElabLambdaBinders context.metaContext opened.bindersRev
    (.lam (psRootName "_match") majorType (psExprAbstractFVar pushed.id body) .explicit)
  return {
    motive, indices := indexMap, majorId, auxiliary, generalized
    constraints := equations.map Prod.fst
    arguments := psElabDependentArguments auxiliary ++ equations.map Prod.snd ++
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

def psElabMatchMinor (elaborate : PsElaborator) (context : PsElabContext)
    (info : PsInductiveInfo) (levels : List PsLevel) (parameters : List PsExpr)
    (plan : PsElabMatchPlan) (ctorName : PsName) (alternative : Option PsElabMatchAlternative)
    (minorType : PsExpr) : Except PsElabError PsElabMatchMinorResult := do
  let some ctor := psEnvironmentFindConstructor context.environment ctorName
    | throw (.matchConstructorUnknown ctorName)
  let names := alternative.bind fun alternative =>
    match alternative.pattern with
    | .constructor _ names _ => some names
    | _ => none
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
  let auxiliary ← psElabOpenDependents plan.auxiliary {
    context := hypotheses.context, body := hypotheses.body, bindersRev := []
    aliasesRev := [], replacements := substitutions }
  let finish := fun context target => do
    let some alternative := alternative | throw PsElabError.matchNonExhaustive
    let generalized ← psElabOpenDependents plan.generalized {
      context, body := target, bindersRev := [], aliasesRev := []
      replacements := auxiliary.replacements }
    let body ← elaborate (psElabContextAfterStructuralFields generalized.context)
      alternative.body (some generalized.body)
    return PsElabTermResult.mk (psElabLeaveScope context body.context)
      (psElabCloseDependents generalized body.context.metaContext body.term) target
  let flexible := auxiliary.bindersRev.map (fun binder => binder.id) ++ fields.bindersRev.map (fun binder => binder.id)
  let body ← psElabSolveIndexConstraints 256 plan.constraints.length flexible (hypotheses.bindersRev.map (fun binder => binder.id))
    finish auxiliary.context auxiliary.body
  let value := psElabSubstituteLocals aliases.valuesRev
    (psElabCloseDependents auxiliary body.context.metaContext body.term)
  let closed := psCloseElabLambdaBinders body.context.metaContext fields.bindersRev
    (psCloseElabLambdaBinders body.context.metaContext hypotheses.bindersRev value)
  return { context := psElabLeaveScope context body.context, term := closed }

structure PsElabMatchMinorsResult where
  context : PsElabContext
  minors : List PsExpr

def psElabMatchMinors (elaborate : PsElaborator) (info : PsInductiveInfo)
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
    let minor ← psElabMatchMinor elaborate context info levels parameters plan name alternative pi.domain
    let tail ← psElabMatchMinors elaborate info levels parameters plan alternatives rest
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

def psElabMatch (elaborate : PsElaborator) (context : PsElabContext)
    (scrutineeSyntax : PsSyntaxTerm)
    (alternativesSyntax : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
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
  let alternatives ← psElabPrepareMatchAlternatives info alternativesSyntax []
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
  let motiveType ← (psInferType context.environment context.metaContext
    context.localContext plan.motive).mapError PsElabError.infer
  let motiveTelescope ← psElabOpenCoreTelescope 4096 context motiveType none
  let level ← (psInferEnsureSort context.environment context.metaContext
    motiveTelescope.context.localContext motiveTelescope.body).mapError PsElabError.infer
  if recursor.levelParams.length > 1 then throw .matchRecursorLevels
  let recursorLevels := if recursor.levelParams.isEmpty then [] else [level]
  let minorContext := psElabStructuralMatchContext context scrutinee.term expectedType plan info.numIndices
  let recursorType := psExprInstantiateLevelParams recursor.levelParams recursorLevels recursor.type
  let cursor ← psElabMatchApplyParameters context (parameters ++ [plan.motive]) recursorType
  let minors ← psElabMatchMinors elaborate info levels parameters plan alternatives info.constructors
    minorContext cursor
  let term := psExprApplyMany (.constE recursorName recursorLevels)
    (parameters ++ [plan.motive] ++ minors.minors ++ indices ++ [scrutinee.term] ++ plan.arguments)
  psElabResolvedTerm (psElabLeaveScope context minors.context) term (some expectedType)
