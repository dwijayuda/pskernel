import Ps.Elab.Equality
import Ps.Elab.Application
import Ps.Elab.GroupElimination
import Ps.Elab.CoreBoundary

-- A source equation keeps its original expression and its real checked proof.
-- Source binders expose homogeneous Eq exactly when the actual types align.
structure PsElabSourceMatchEquation where
  original : PsExpr
  proof : PsExpr
  type : PsExpr

def psElabSourceMatchEquationConvert (context : PsElabContext)
    (type proof expected : PsExpr) : Except PsElabError PsElabTermResult := do
  let checked ← psElabResolvedTerm context proof (some type)
  let context := checked.context
  if psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
      checked.type expected then
    return ← psElabResolvedTerm context checked.term (some expected)
  let actual := psExprAppView (psWhnf context.environment context.metaContext context.localContext checked.type)
  let wanted := psExprAppView (psWhnf context.environment context.metaContext context.localContext expected)
  match actual.head, wanted.head with
  | .constE name _, .constE target _ =>
    if psNameEq name psEqName && psNameEq target (psRootName "HEq") then
      let equation ← psElabEquationView context checked.type checked.term
      let result := fun right => psExprApplyMany (.constE (psRootName "HEq") [equation.level])
        [equation.type, equation.left, equation.type, right]
      let base := psExprApplyMany (.constE (psNameAppendStr (psRootName "HEq") "refl") [equation.level])
        [equation.type, equation.left]
      let proof ← psElabEquationRec context equation result base
      return ← psElabResolvedTerm context proof (some expected)
    if psNameEq name (psRootName "HEq") && psNameEq target psEqName then
      let equation ← psElabEquationView context checked.type checked.term
      return ← psElabResolvedTerm context equation.proof (some expected)
    psElabResolvedTerm context checked.term (some expected)
  | _, _ => psElabResolvedTerm context checked.term (some expected)

def psElabSourceMatchEquationNormalize (context : PsElabContext)
    (source : PsElabSourceMatchEquation) :
    Except PsElabError (PsElabContext × PsElabSourceMatchEquation) := do
  let checked ← psElabResolvedTerm context source.proof (some source.type)
  let context := checked.context
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext checked.type)
  match view.head, view.args with
  | .constE name [level], [leftType, left, rightType, right] =>
    if psNameEq name (psRootName "HEq") &&
        psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext leftType rightType then
      let target := psLogicEq level leftType left right
      let result ← psElabSourceMatchEquationConvert context checked.type checked.term target
      return (result.context, { source with proof := result.term, type := result.type })
    return (context, { source with proof := checked.term, type := checked.type })
  | _, _ => return (context, { source with proof := checked.term, type := checked.type })

def psElabSourceMatchEquationType (context : PsElabContext)
    (original current : PsExpr) (retainHEq : Bool) : Except PsElabError PsExpr := do
  let (type, _) ← psElabIndexEquation context original current
  let view := psExprAppView type
  match view.head, view.args with
  | .constE name [level], [domain, left, right] =>
    if retainHEq && psNameEq name psEqName then
      return psExprApplyMany (.constE (psRootName "HEq") [level]) [domain, left, domain, right]
    return type
  | _, _ => return type

def psElabSourceMatchProofIds (source : Option PsElabSourceMatchEquation) : List Nat :=
  match source with
  | some { proof := .fvar id, .. } => [id]
  | _ => []

-- Branch consumers receive typed elimination metadata; patterns and tactics
-- share refinement without reconstructing fields or induction hypotheses.
structure PsElabMatchBranch where
  context : PsElabContext
  target : PsExpr
  fields : List PsElabTypedBinder
  hypotheses : List PsElabTypedBinder
  clearedIds : List Nat
  refinements : PsElabRefinements := []
  sourceEquation? : Option PsElabSourceMatchEquation := none

structure PsElabMatchAlternative where
  constructorName : PsName
  fieldNames : List PsSyntaxName
  elaborate : PsElabMatchBranch -> Except PsElabError PsElabTermResult
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
  sourceEquation? : Option PsElabSourceMatchEquation := none
  indexArguments : List PsExpr := []
  sourceIndices : List PsExpr := []
  argumentMetaContext? : Option PsMetaContext := none

def psElabMatchIndexMap (parameters indices : List PsExpr) : List (Nat × Nat) :=
  (indices.zipIdx).filterMap fun entry =>
    match entry.fst with
    | .fvar id =>
      if (indices.filter (fun value => psExprAlphaEq value (.fvar id))).length == 1 &&
          !(parameters.any (psElabExprContainsLocal id)) then some (id, entry.snd)
      else none
    | _ => none

-- Retained Matrix values need their earlier type/value dependencies as well.
-- This backwards closure does not inspect source RHS names.
def psElabMatchRequiredDependencies (context : PsElabContext) (ids : List Nat) : List Nat :=
  context.localContext.declarations.foldl (fun required declaration =>
    if required.contains (psLocalDeclId declaration) then
      let type := psMetaInstantiate context.metaContext (psLocalDeclType declaration)
      let valueIds := match declaration with
        | .binding .. => []
        | .letDecl _ _ _ value => psExprFVarIds (psMetaInstantiate context.metaContext value)
      (required ++ psExprFVarIds type ++ valueIds).eraseDups
    else required) ids

def psElabMatchMotive (context : PsElabContext) (info : PsInductiveInfo)
    (levels : List PsLevel) (parameters indices : List PsExpr)
    (major expected : PsExpr)
    (generalizedIds? : Option (List Nat) := none) (requiredIds : List Nat := [])
    (sourceEquation? : Option PsElabSourceMatchEquation := none)
    (protectedIds : List Nat := []) (sourceIndices : List PsExpr := []) :
    Except PsElabError PsElabMatchPlan := do
  if !sourceIndices.isEmpty && sourceIndices.length != indices.length then
    throw (.refinement "source match index metadata arity mismatch")
  let type := psExprInstantiateLevelParams info.levelParams levels info.type
  let cursor ← psElabMatchApplyParameters context parameters type
  let opened ← psElabOpenCoreTelescope 4096 context cursor (some info.numIndices)
  let freshIndices := psElabBinderArguments opened.bindersRev
  let indexMap := (psElabMatchIndexMap parameters indices).filter
    (fun entry => !protectedIds.contains entry.fst)
  let constrained := indexMap.length != indices.length
  let indexMap := if constrained then [] else indexMap
  let substitutions := indexMap.filterMap fun entry =>
    (freshIndices[entry.snd]?).map (fun value => (entry.fst, value))
  let majorType := psExprApplyMany (.constE info.name levels) (parameters ++ freshIndices)
  let pushed := psLocalPushBinding opened.context.localContext (psRootName "_match") majorType .explicit
  let majorId := match major with
    | .fvar id => if protectedIds.contains id || parameters.any (psElabExprContainsLocal id) ||
        indices.any (psElabExprContainsLocal id) then none else some id
    | _ => none
  -- Outer source indices remain rigid. A source-only typed retry may add a
  -- checked private index telescope; automatic constraints cannot rename them.
  let constraintVariables := if !constrained then [] else
    context.localContext.declarations.filterMap fun declaration =>
      let id := psLocalDeclId declaration
      if !protectedIds.contains id && indices.any (psElabExprContainsLocal id) &&
          !(parameters.any (psElabExprContainsLocal id)) then some id else none
  let roots := indexMap.map Prod.fst ++ majorId.toList
  let dependents := psElabDependentLocals context roots
    (protectedIds ++ psElabSourceMatchProofIds sourceEquation?)
  let required := psElabMatchRequiredDependencies context
    (requiredIds ++ generalizedIds?.getD [])
  let generalized := if constrained then [] else
    dependents.filter fun entry => generalizedIds?.isNone || required.contains entry.binder.id
  let body := psElabCloseDependentType generalized expected
  let body := if constrained then body else
    psElabSubstituteLocals (substitutions ++ majorId.toList.map (fun id => (id, .fvar pushed.id))) body
  let equalityContext := psElabContextWithLocal opened.context pushed.context
  let equations ← if !constrained then pure [] else do
    let indexEquations ← (freshIndices.zip indices).mapM fun (fresh, original) =>
      psElabIndexEquation equalityContext fresh original
    let majorEquation ← psElabIndexEquation equalityContext (.fvar pushed.id) major
    pure (indexEquations ++ [majorEquation])
  -- This source slot is separate from the automatic constraint queue. Build
  -- its ORIGINAL side after ordinary abstraction so no current-index/major
  -- substitution can sweep through the preserved source expression or type.
  let (body, sourceArguments, argumentMetaContext?) ← match sourceEquation? with
    | none => pure (body, [], none)
    | some source => do
      let sourceView := psExprAppView
        (psWhnf context.environment context.metaContext context.localContext source.type)
      let retainHEq := match sourceView.head with
        | .constE name _ => psNameEq name (psRootName "HEq")
        | _ => false
      let equationType ← psElabSourceMatchEquationType equalityContext source.original
        (.fvar pushed.id) retainHEq
      let atActual := (freshIndices.zip indices).filterMap fun (fresh, actual) =>
        match fresh with | .fvar id => some (id, actual) | _ => none
      let actualType := psElabSubstituteLocals (atActual ++ [(pushed.id, major)]) equationType
      let argument ← psElabSourceMatchEquationConvert context source.type source.proof actualType
      pure (.forallE (psRootName "_sourceEq") equationType body .explicit,
        [argument.term], some argument.context.metaContext)
  let body := (equations.zipIdx).foldr (fun entry body =>
    psLogicPi (pushed.id + 1 + entry.snd) "_indexEq" entry.fst.fst body) body
  let motive := psCloseElabLambdaBinders context.metaContext opened.bindersRev
    (.lam (psRootName "_match") majorType (psExprAbstractFVar pushed.id body) .explicit)
  return {
    motive, indices := indexMap, majorId, constraintVariables, generalized
    constraints := equations.map Prod.fst
    arguments := equations.map Prod.snd ++ sourceArguments ++ psElabDependentArguments generalized
    sourceEquation?, indexArguments := indices, sourceIndices, argumentMetaContext? }

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
    (visibleFields : List Nat)
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
    let next := { context with
      localContext := pushed.context
      auxiliaryLocalIds := pushed.id :: context.auxiliaryLocalIds }
    let next := match context.structuralRecursion with
      | some recursion => if recursion.collectCalls && visibleFields.contains index then
          psElabContextWithStructuralRecursion next
            (some { recursion with calls := (field.id, pushed.id) :: recursion.calls })
        else next
      | none => next
    psElabMatchHypotheses fields rest visibleFields next
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

abbrev PsElabMatchMinorResult := PsElabRecursorArgument

def psElabMatchMinorWithHypotheses (context : PsElabContext)
    (info : PsInductiveInfo) (levels : List PsLevel) (parameters : List PsExpr)
    (plan : PsElabMatchPlan) (ctorName : PsName) (alternative : Option PsElabMatchAlternative)
    (minorType : PsExpr) (visibleFields : List Nat) :
    Except PsElabError PsElabMatchMinorResult := do
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
    visibleFields aliases.context fields.body
  let visibleHypotheses := (ctor.recursiveFields.zip hypotheses.bindersRev.reverse).filterMap
    (fun (index, binder) => if visibleFields.contains index then some binder else none)
  let finish := fun (refinements : PsElabRefinements) (context : PsElabContext) (target : PsExpr) => do
    let some alternative := alternative | throw PsElabError.matchNonExhaustive
    let (equationContext, branchTarget, equationBinder?, sourceEquation?) ← match plan.sourceEquation? with
      | none => pure (context, target, none, none)
      | some source => do
        let pi ← (psInferEnsureForall context.environment context.metaContext
          context.localContext target).mapError PsElabError.infer
        if !psBinderInfoEq pi.binder .explicit then throw .matchRecursorUnsupported
        let name := psNameAppendNum (psRootName "$psc0MatchEquation") context.localContext.nextId
        let pushed := psLocalPushBinding context.localContext name pi.domain pi.binder
        let inner := psElabContextWithLocal context pushed.context
        let (inner, equation) ← psElabSourceMatchEquationNormalize inner {
          original := source.original, proof := .fvar pushed.id, type := pi.domain }
        pure (inner, psExprInstantiate1 pi.body (.fvar pushed.id),
          some (PsElabTypedBinder.mk pushed.id name pi.domain pi.binder), some equation)
    let generalized ← psElabOpenDependents plan.generalized {
      context := equationContext, body := branchTarget, bindersRev := [], aliasesRev := []
      replacements := substitutions ++ refinements }
    let majorIds := plan.majorId.toList
    let clearedIds := majorIds ++ plan.generalized.map (·.binder.id) ++
      aliases.sourcesRev.filterMap (fun (original, alias) =>
        if majorIds.contains original then some alias else none)
    -- Retain real recursor binders while keeping dummy companion hypotheses
    -- outside source name resolution and new proof-goal contexts.
    let visibleIds := visibleHypotheses.map (·.id)
    let hidden := hypotheses.bindersRev.filterMap
      (fun binder => if visibleIds.contains binder.id then none else some binder.id)
    let branchContext := psElabContextWithLocal generalized.context {
      generalized.context.localContext with
      declarations := generalized.context.localContext.declarations.filter
        (fun declaration => !hidden.contains (psLocalDeclId declaration)) }
    let body ← alternative.elaborate {
      context := psElabContextAfterStructuralFields branchContext
      target := generalized.body
      fields := fields.bindersRev.reverse
      hypotheses := visibleHypotheses
      clearedIds
      refinements := generalized.replacements
      sourceEquation? }
    let body ← psElabCloseDependents equationContext generalized body branchTarget
    match equationBinder? with
    | none => pure body
    | some binder =>
      psElabAbstract context body.context
        [.lambdaE binder.id binder.name binder.type binder.binder] body.term target
  let flexible := fields.bindersRev.map (fun binder => binder.id) ++
    plan.constraintVariables ++ (if plan.constraints.isEmpty then [] else plan.majorId.toList)
  let requests := ((plan.sourceIndices.zip indices).zip plan.indexArguments).map
    fun ((original, left), right) =>
      ({ original, left, right, named := plan.sourceEquation?.isSome } : PsElabIndexRefinementCandidate)
  let body ← psElabSolveIndexConstraintsWithRefinements 256 plan.constraints.length flexible
    (hypotheses.bindersRev.map (fun binder => binder.id) ++ psElabSourceMatchProofIds plan.sourceEquation?)
    finish [] hypotheses.context hypotheses.body requests
  let closed ← psElabAbstract context body.context
    (psElabAliasAbstractions aliases.valuesRev ++
      psElabLambdaAbstractions hypotheses.bindersRev ++ psElabLambdaAbstractions fields.bindersRev)
    body.term minorType
  return { context := closed.context, term := closed.term }

-- Direct-family callers retain this interface. The full elimination-slot
-- consumer below chooses visibility per actual recursive field instead.
def psElabMatchMinor (context : PsElabContext)
    (info : PsInductiveInfo) (levels : List PsLevel) (parameters : List PsExpr)
    (plan : PsElabMatchPlan) (ctorName : PsName) (alternative : Option PsElabMatchAlternative)
    (minorType : PsExpr) (retainHypotheses : Bool := true) :
    Except PsElabError PsElabMatchMinorResult := do
  let some ctor := psEnvironmentFindConstructor context.environment ctorName
    | throw (.matchConstructorUnknown ctorName)
  psElabMatchMinorWithHypotheses context info levels parameters plan ctorName alternative
    minorType (if retainHypotheses then ctor.recursiveFields else [])

-- Pinned Lean's cases_on.cpp specializes unused motives to PUnit at exactly
-- the eliminator's universe. Both constants come from the ordinary checked
-- Standard; an absent or incompatible signature is an elaboration failure.
def psElabMatchUnit (context : PsElabContext) (level : PsLevel) :
    Except PsElabError (PsExpr × PsExpr) := do
  let name := psRootName "PUnit"
  let unit := PsExpr.constE name [level]
  let value := PsExpr.constE (psNameAppendStr name "unit") [level]
  let unitType ← (psInferType context.environment context.metaContext
    context.localContext unit).mapError PsElabError.infer
  let valueType ← (psInferType context.environment context.metaContext
    context.localContext value).mapError PsElabError.infer
  if !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
      unitType (.sortE level) ||
      !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
        valueType unit then
    throw .matchRecursorUnsupported
  return (unit, value)

def psElabMatchConstantArgument (context : PsElabContext)
    (type : PsExpr) (count : Nat) (value : PsExpr) :
    Except PsElabError PsElabRecursorArgument := do
  let opened ← psElabOpenCoreTelescope 4096 context type (some count)
  let term := psCloseElabLambdaBinders opened.context.metaContext opened.bindersRev value
  return { context := psElabLeaveScope context opened.context, term }

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

-- Typed consumers retain their actual discriminant and type across refinement.
-- Recheck that pair in its current context; no source name is resolved again.
def psElabMatchTypedWith
    (prepare : PsElabContext -> PsInductiveInfo -> Except PsElabError (List PsElabMatchAlternative))
    (scrutinee : PsElabTermResult) (expected : Option PsExpr)
    (equationName? : Option PsSyntaxName := none)
    (generalizing? : Option Bool := none)
    (generalizedIds? : Option (List Nat) := none)
    (requiredIds : List Nat := [])
    (sourceEquation? : Option PsElabSourceMatchEquation := none)
    (protectedIds : List Nat := []) (sourceIndices : List PsExpr := [])
    (sourceCompiler : Bool := false) :
    Except PsElabError PsElabTermResult := do
  let some expectedType := expected | throw .matchExpectedType
  let scrutinee ← psElabResolvedTerm scrutinee.context scrutinee.term (some scrutinee.type)
  let context ← match sourceEquation? with
    | none => pure scrutinee.context
    | some source => do
      let (type, _) ← psElabIndexEquation scrutinee.context source.original scrutinee.term
      let checked ← psElabSourceMatchEquationConvert scrutinee.context source.type source.proof type
      pure checked.context
  if equationName?.isSome != sourceEquation?.isSome then
    throw (.refinement "source match equation metadata/proof ownership mismatch")
  let typeView := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext scrutinee.type)
  let .constE name levels := typeView.head | throw .matchScrutineeUnsupported
  let some info := psEnvironmentFindInductive context.environment name
    | throw .matchScrutineeUnsupported
  if typeView.args.length != info.numParams + info.numIndices then throw .matchParameterArity
  let parameters := typeView.args.take info.numParams
  let indices := typeView.args.drop info.numParams
  let expectedType := psWhnfCore context.metaContext context.localContext expectedType
  let generalizedIds? := if generalizedIds?.isSome then generalizedIds? else
    if generalizing? == some false then some [] else none
  let plan ← psElabMatchMotive context info levels parameters indices scrutinee.term expectedType
    generalizedIds? requiredIds sourceEquation? protectedIds sourceIndices
  let context := match plan.argumentMetaContext? with
    | some metaContext => psElabContextWithMeta context metaContext
    | none => context
  -- Reverted dependent parameters can raise the motive's universe above that
  -- of the original expected result. Infer the completed motive, not a proxy.
  let level ← psElabMatchMotiveLevel context plan.motive
  let recursor ← psElabEliminationRecursorPlanFor context info levels parameters level
  let alternatives ← prepare recursor.context info
  let constructors ← psElabEliminationConstructors recursor.context recursor.plan
  let singleton := recursor.plan.group.members.length == 1
  let unit ← if recursor.plan.slots.length == 1 then pure none else
    pure (some (← psElabMatchUnit recursor.context level))
  let motives ← psElabRecursorArguments recursor.plan.slots.zipIdx
    (fun current (slot, index) type => do
      if index == recursor.slotIndex then return { context := current, term := plan.motive }
      let some unit := unit | throw .matchRecursorUnsupported
      psElabMatchConstantArgument current type (slot.family.numIndices + 1) unit.fst)
    recursor.context recursor.cursor
  -- Ordinary group matching is a cases specialization. It supplies no map
  -- from fields to recursive source calls: such calls need a complete motive
  -- family, while an unrelated enclosing singleton recursion retains its map.
  let minorContext := if singleton then
      psElabStructuralMatchContext motives.context scrutinee.term expectedType plan info.numIndices
    else psElabContextAfterStructuralFields motives.context
  let minors ← psElabRecursorArguments constructors
    (fun current (index, _, constructor) type => do
      if index == recursor.slotIndex then
        let visible := if singleton then
            constructor.recursiveFields.filterMap
              (fun (field, target) => if target == recursor.slotIndex then some field else none)
          else []
        psElabMatchMinorWithHypotheses current info levels parameters plan constructor.info.name
          (psElabMatchAlternativeFind constructor.info.name alternatives) type visible
      else
        let some unit := unit | throw .matchRecursorUnsupported
        psElabMatchConstantArgument current type
          (constructor.info.numFields + constructor.recursiveFields.length) unit.snd)
    minorContext motives.cursor
  let arguments := parameters ++ motives.arguments ++ minors.arguments ++ indices ++ [scrutinee.term]
  let context := psElabLeaveScope context minors.context
  if sourceCompiler then
    let value ← psElabResolvedTerm context
      (psExprApplyMany (.constE recursor.recursor.name recursor.levels) arguments) none
    let boundary ← psElabCoreBoundaryOpen value.context
      (.primitive recursor.slotIndex plan.arguments.length) value.term value.type
    let applied ← psElabApplyCore boundary.context (.fvar boundary.id) plan.arguments
    psElabCoreBoundaryClose boundary applied (some expectedType)
  else
    let term := psExprApplyMany (.constE recursor.recursor.name recursor.levels)
      (arguments ++ plan.arguments)
    psElabResolvedTerm context term (some expectedType)



-- Syntax and tactic callers keep their existing default behavior. Source
-- matrices enter through the typed interface after their one input elaboration.
def psElabMatchWith (elaborate : PsElaborator)
    (prepare : PsElabContext -> PsInductiveInfo -> Except PsElabError (List PsElabMatchAlternative))
    (context : PsElabContext) (scrutineeSyntax : PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let some _ := expected | throw .matchExpectedType
  let scrutinee ← elaborate context scrutineeSyntax none
  psElabMatchTypedWith prepare scrutinee expected
