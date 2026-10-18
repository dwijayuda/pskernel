import Ps.Elab.Match
import Ps.Elab.PatternSyntax

-- A source row is checked before the decision tree selects any constructor
-- that the row did not itself specify. Paths identify actual source columns
-- and constructor fields; source names never identify compiler arguments.
structure PsElabPatternRowSource where
  original : PsExpr
  type : PsExpr
  equationName? : Option PsSyntaxName := none
  names : List PsName := []
  onlyLocal : Bool := false

structure PsElabPatternRowOccurrence where
  value : PsExpr
  path : List Nat

structure PsElabCheckedPatternRow where
  term : PsExpr
  type : PsExpr
  binders : List Nat
  slots : List (Nat × List Nat)
  numEquations : Nat
  equationBinders : List Nat
  aliases : List (PsName × Nat)
  metadata : PsElabCoreRow
  compilerPatterns : List PsSyntaxPattern

structure PsElabPatternLhs where
  context : PsElabContext
  values : List PsExpr
  occurrences : List PsElabPatternRowOccurrence
  compilerPatterns : List PsSyntaxPattern
  target : PsExpr

structure PsElabPatternRowChecked where
  context : PsElabContext
  value : PsExpr
  occurrences : List PsElabPatternRowOccurrence
  compilerPattern : PsSyntaxPattern

def psElabPatternRowReplace (replacements : List (PsExpr × PsExpr))
    (expression : PsExpr) : PsExpr :=
  match replacements.find? (fun entry => psExprAlphaEq entry.fst expression) with
  | some entry => entry.snd
  | none =>
    match expression with
    | .app fn arg =>
      .app (psElabPatternRowReplace replacements fn) (psElabPatternRowReplace replacements arg)
    | .lam name type body binder =>
      .lam name (psElabPatternRowReplace replacements type)
        (psElabPatternRowReplace replacements body) binder
    | .forallE name type body binder =>
      .forallE name (psElabPatternRowReplace replacements type)
        (psElabPatternRowReplace replacements body) binder
    | .letE name type value body =>
      .letE name (psElabPatternRowReplace replacements type)
        (psElabPatternRowReplace replacements value) (psElabPatternRowReplace replacements body)
    | .proj name index value => .proj name index (psElabPatternRowReplace replacements value)
    | expression => expression

def psElabPatternRowContains (value expression : PsExpr) : Bool :=
  if psExprAlphaEq value expression then true else
  match expression with
  | .app fn arg | .lam _ fn arg _ | .forallE _ fn arg _ =>
    psElabPatternRowContains value fn || psElabPatternRowContains value arg
  | .letE _ type term body =>
    psElabPatternRowContains value type || psElabPatternRowContains value term ||
      psElabPatternRowContains value body
  | .proj _ _ expression => psElabPatternRowContains value expression
  | _ => false

def psElabPatternRowUnify (context : PsElabContext) (left right : PsExpr) :
    Except PsElabError (PsElabContext × Bool) := do
  let unified := psUnify context.environment context.localContext context.metaContext left right
  if unified.resourceExceeded then throw .fuelExhausted
  if unified.success then return (psElabContextWithMeta context unified.context, true)
  return (context, false)

def psElabPatternRowVariables (context : PsElabContext) (names : List PsSyntaxName) :
    Except PsElabError (PsElabContext × List PsElabTypedBinder) := do
  match names with
  | [] => return (context, [])
  | source :: names =>
    if psSyntaxNameIsWildcardBinder source then
      return ← psElabPatternRowVariables context names
    let some name := psSyntaxNameToName source | throw .emptyName
    let type := psElabFreshType context
    let pushed := psLocalPushBinding type.context.localContext name type.type .explicit
    let (context, binders) ← psElabPatternRowVariables
      (psElabContextWithLocal type.context pushed.context) names
    return (context, PsElabTypedBinder.mk pushed.id name type.type .explicit :: binders)

def psElabPatternRowConstructorName (family : PsName) (pattern : PsSyntaxPattern) :
    Except PsElabError (PsName × List PsSyntaxPattern) := do
  match pattern with
  | .bool value _ =>
    if !psNameEq family psBoolName then throw .matchPatternUnsupported
    return (if value then psBoolTrueName else psBoolFalseName, [])
  | .natural value span =>
    if !psNameEq family psNatName then throw .matchPatternUnsupported
    if value == 0 then return (psNameAppendStr psNatName "zero", [])
    return (psNameAppendStr psNatName "succ", [.natural (value - 1) span])
  | .ctor source fields _ | .dotCtor source fields _ =>
    let name ← match source.segments with
      | [] => throw .matchPatternUnsupported
      | [segment] => pure (psNameAppendStr family segment)
      | _ =>
        match psSyntaxNameToName source with
        | none => throw .matchPatternUnsupported
        | some name => pure name
    return (name, fields)
  | _ => throw .matchPatternUnsupported

-- Explicit constructor parameters are ordinary terms; implicit parameters
-- are supplied by the selected family application. All comparisons retain the
-- checked argument's actual context and resource failures.
def psElabPatternRowParameters (branch : PsElaborator) (fuel : Nat)
    (context : PsElabContext) (name : PsName) (parameters : List PsExpr)
    (cursor : PsExpr) (patterns : List PsSyntaxPattern) :
    Except PsElabError (PsElabContext × PsExpr × List PsSyntaxPattern) := do
  match parameters with
  | [] => return (context, cursor, patterns)
  | parameter :: parameters =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let (context, patterns) ← if psBinderAcceptsExplicitArgument pi.binder then do
        let pattern :: patterns := patterns | throw (.matchConstructorArity name)
        let checked ← psElabPatternParameter branch fuel context pattern (some pi.domain)
        let (context, same) ← psElabPatternRowUnify checked.context parameter checked.term
        unless same do throw .typeMismatch
        pure (context, patterns)
      else pure (context, patterns)
    psElabPatternRowParameters branch fuel context name parameters
      (psExprInstantiate1 pi.body parameter) patterns

-- Explicit variables are rigid locals. Wildcards are private pattern
-- metavariables until every constructor field and index has been checked.
-- Resolve nested short constructors only after their preceding fields have
-- constrained the real dependent domain.
def psElabPatternRowElaborate (branch : PsElaborator) (fuel : Nat)
    (context : PsElabContext) (variables : List PsElabTypedBinder)
    (pattern : PsSyntaxPattern) (expected : PsExpr) (path : List Nat) :
    Except PsElabError PsElabPatternRowChecked := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .variable source =>
      if psSyntaxNameIsWildcardBinder source then
        let value := psElabHole context (some expected)
        return { context := value.context, value := value.term
          occurrences := [{ value := value.term, path }], compilerPattern := pattern }
      let some name := psSyntaxNameToName source | throw .emptyName
      let some patternVar := variables.find? (fun patternVar => psNameEq patternVar.name name)
        | throw (.refinement "pattern variable declaration unavailable")
      let (context, success) ← psElabPatternRowUnify context patternVar.type expected
      if !success then throw .typeMismatch
      return { context, value := .fvar patternVar.id
        occurrences := [{ value := .fvar patternVar.id, path }], compilerPattern := pattern }
    | .wildcard _ =>
      let value := psElabHole context (some expected)
      return { context := value.context, value := value.term
        occurrences := [{ value := value.term, path }], compilerPattern := pattern }
    | .inaccessible _ => throw .matchPatternUnsupported
    | _ =>
      let view := psExprAppView
        (psWhnf context.environment context.metaContext context.localContext expected)
      let .constE family levels := view.head | throw .matchScrutineeUnsupported
      let some info := psEnvironmentFindInductive context.environment family
        | throw .matchScrutineeUnsupported
      if view.args.length != info.numParams + info.numIndices then throw .matchParameterArity
      let (name, patterns) ← psElabPatternRowConstructorName family pattern
      if !(info.constructors.any (psNameEq name)) then throw (.matchConstructorUnknown name)
      let some ctor := psEnvironmentFindConstructor context.environment name
        | throw (.matchConstructorUnknown name)
      unless ctor.numParams == info.numParams do throw .matchParameterArity
      let parameters := view.args.take info.numParams
      let type ← (psInferType context.environment context.metaContext context.localContext
        (.constE name levels)).mapError PsElabError.infer
      let (context, cursor, patterns) ←
        psElabPatternRowParameters branch fuel context name parameters type patterns
      let (context, cursor, remaining, values, occurrences, fields) ←
        (List.range ctor.numFields).foldlM
          (fun (state : PsElabContext × PsExpr × List PsSyntaxPattern ×
              List PsExpr × List PsElabPatternRowOccurrence × List PsSyntaxPattern) index => do
            let (context, cursor, remaining, values, occurrences, fields) := state
            let pi ← (psInferEnsureForall context.environment context.metaContext
              context.localContext cursor).mapError PsElabError.infer
            let (field, remaining) ← if psBinderAcceptsExplicitArgument pi.binder then do
                let field :: remaining := remaining | throw (.matchConstructorArity name)
                pure (field, remaining)
              else pure (.wildcard (psSyntaxPatternSpan pattern), remaining)
            let checked ← psElabPatternRowElaborate branch fuel context variables field
              pi.domain (path ++ [index])
            return (checked.context, psExprInstantiate1 pi.body checked.value, remaining,
              values ++ [checked.value], occurrences ++ checked.occurrences,
              fields ++ [checked.compilerPattern]))
          (context, cursor, patterns, [], [], [])
      unless remaining.isEmpty do throw (.matchConstructorArity name)
      let (context, success) ← psElabPatternRowUnify context cursor expected
      if !success then throw .typeMismatch
      let value := psExprApplyMany (.constE name levels) (parameters ++ values)
      let checked ← psElabResolvedTerm context value (some expected)
      let compilerPattern := match pattern with
        | .ctor source _ span | .dotCtor source _ span => PsSyntaxPattern.ctor source fields span
        | _ => pattern
      return { context := checked.context, value := checked.term, occurrences, compilerPattern }

-- Pinned Lean retries only a constructor pattern that checks after recursively
-- erasing inductive indices. The later visitor must find the first mismatch
-- along inductive parameters or matching constructor fields, ending at a fvar.
def psElabPatternRowEraseIndices (fuel : Nat) (context : PsElabContext) (type : PsExpr) :
    Except PsElabError (PsElabContext × PsExpr) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let view := psExprAppView
      (psWhnf context.environment context.metaContext context.localContext type)
    let .constE name levels := view.head | return (context, type)
    let some info := psEnvironmentFindInductive context.environment name | return (context, type)
    if view.args.length != info.numParams + info.numIndices then return (context, type)
    let (context, parameters) ← (view.args.take info.numParams).foldlM
      (fun (state : PsElabContext × List PsExpr) parameter => do
        let (context, parameter) ← psElabPatternRowEraseIndices fuel state.fst parameter
        return (context, state.snd ++ [parameter])) (context, [])
    let cursor ← psElabMatchApplyParameters context parameters
      (psExprInstantiateLevelParams info.levelParams levels info.type)
    let (context, _, indices) ← (List.range info.numIndices).foldlM
      (fun (state : PsElabContext × PsExpr × List PsExpr) _ => do
        let (context, cursor, indices) := state
        let pi ← (psInferEnsureForall context.environment context.metaContext
          context.localContext cursor).mapError PsElabError.infer
        let fresh := psElabHole context (some pi.domain)
        return (fresh.context, psExprInstantiate1 pi.body fresh.term, indices ++ [fresh.term]))
      (context, cursor, [])
    return (context, psExprApplyMany view.head (parameters ++ indices))

def psElabPatternRowRefinementPath (fuel : Nat) (context : PsElabContext)
    (left right : PsExpr) (indexMode : Bool := false) :
    Except PsElabError (Option (List Nat)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let left := psWhnf context.environment context.metaContext context.localContext left
    let right := psWhnf context.environment context.metaContext context.localContext right
    if indexMode then
      match left, right with
      | .fvar _, _ | _, .fvar _ => return some []
      | _, _ => pure ()
    let a := psExprAppView left
    let b := psExprAppView right
    let .constE name _ := a.head | return none
    let .constE _ _ := b.head | return none
    if a.args.isEmpty || a.args.length != b.args.length then return none
    let (context, same) ← psElabPatternRowUnify context a.head b.head
    if !same then return none
    let numParams? := if indexMode then
        (psEnvironmentFindConstructor context.environment name).map (·.numParams)
      else
        (psEnvironmentFindInductive context.environment name).map (·.numParams)
    let some numParams := numParams? | return none
    let rec find (context : PsElabContext) (arguments : List (PsExpr × PsExpr)) (index : Nat) :
        Except PsElabError (Option (List Nat)) := do
      match arguments with
      | [] => return none
      | (left, right) :: rest =>
        let (context, same) ← psElabPatternRowUnify context left right
        if same then return ← find context rest (index + 1)
        if indexMode && index < numParams then return none
        let path ← psElabPatternRowRefinementPath fuel context left right
          (indexMode || index >= numParams)
        return path.map (index :: ·)
    find context (a.args.zip b.args) 0

def psElabPatternRowIndexAt (context : PsElabContext) (type : PsExpr) :
    List Nat → Option PsExpr
  | [] => some type
  | index :: path => do
    let view := psExprAppView
      (psWhnf context.environment context.metaContext context.localContext type)
    let argument ← view.args[index]?
    psElabPatternRowIndexAt context argument path

def psElabPatternRowAtSource (branch : PsElaborator)
    (context : PsElabContext) (variables : List PsElabTypedBinder)
    (source : PsElabPatternRowSource) (pattern : PsSyntaxPattern)
    (expected : PsExpr) (path : List Nat) :
    Except PsElabError PsElabPatternRowChecked := do
  match psElabPatternRowElaborate branch 4096 context variables pattern expected path with
  | .ok result => return result
  | .error cause =>
    if psElabErrorIsResource cause then throw cause
    let erased ← match psElabPatternRowEraseIndices 4096 context expected with
      | .ok erased => pure erased
      | .error error => if psElabErrorIsResource error then throw error else throw cause
    let alternative ← match
        psElabPatternRowElaborate branch 4096 erased.fst variables pattern erased.snd path with
      | .ok alternative => pure alternative
      | .error error => if psElabErrorIsResource error then throw error else throw cause
    let type ← (psInferType alternative.context.environment alternative.context.metaContext
      alternative.context.localContext alternative.value).mapError PsElabError.infer
    let some path ← psElabPatternRowRefinementPath 4096 alternative.context type expected
      | throw cause
    let some index := psElabPatternRowIndexAt context source.type path | throw cause
    throw (.sourceMatchIndexRefinement [index] source.equationName?.isSome cause)

def psElabPatternRowLhs (branch : PsElaborator)
    (context : PsElabContext) (variables : List PsElabTypedBinder)
    (sources : List PsElabPatternRowSource) (patterns : List PsSyntaxPattern)
    (matchType : PsExpr) (index : Nat := 0) :
    Except PsElabError PsElabPatternLhs := do
  match sources, patterns with
  | [], [] => return {
      context, values := [], occurrences := [], compilerPatterns := [], target := matchType }
  | source :: sources, pattern :: patterns =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext matchType).mapError PsElabError.infer
    let checked ← psElabPatternRowAtSource branch context variables source pattern pi.domain [index]
    let tail ← psElabPatternRowLhs branch checked.context variables sources patterns
      (psExprInstantiate1 pi.body checked.value) (index + 1)
    return { tail with
      values := checked.value :: tail.values
      occurrences := checked.occurrences ++ tail.occurrences
      compilerPatterns := checked.compilerPattern :: tail.compilerPatterns }
  | _, _ => throw (.refinement "pattern row/discriminant arity mismatch")

-- An assigned wildcard is inaccessible. An unresolved wildcard is a genuine
-- row parameter; a repeated occurrence contributes no second parameter.
def psElabPatternRowOccurrences (context : PsElabContext)
    (explicitIds : List Nat) (occurrences : List PsElabPatternRowOccurrence) :
    List PsElabPatternRowOccurrence :=
  occurrences.foldl (fun result occurrence =>
    let value := psMetaInstantiate context.metaContext occurrence.value
    let accessible := match value with
      | .fvar id => explicitIds.contains id
      | .mvar _ => true
      | _ => false
    if accessible && !(result.any (fun prior => psExprAlphaEq prior.value value)) then
      result ++ [{ occurrence with value }]
    else result) []

def psElabPatternRowOrder (fuel : Nat) (context : PsElabContext)
    (candidates : List PsElabPatternRowOccurrence)
    (pending visiting ordered : List PsExpr) : Except PsElabError (List PsExpr) := do
  match pending with
  | [] => return ordered
  | value :: pending =>
    match fuel with
    | 0 => throw .fuelExhausted
    | fuel + 1 =>
      if ordered.any (psExprAlphaEq value) then
        return ← psElabPatternRowOrder fuel context candidates pending visiting ordered
      if visiting.any (psExprAlphaEq value) then
        throw (.refinement "cyclic pattern variable telescope")
      let type ← (psInferType context.environment context.metaContext
        context.localContext value).mapError PsElabError.infer
      let type := psMetaInstantiate context.metaContext type
      let dependencies := candidates.filterMap fun candidate =>
        if psElabPatternRowContains candidate.value type then some candidate.value else none
      let ordered ← psElabPatternRowOrder fuel context candidates dependencies (value :: visiting) ordered
      psElabPatternRowOrder fuel context candidates pending visiting (ordered ++ [value])

structure PsElabPatternRowOpened where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  replacements : List (PsExpr × PsExpr)

def psElabPatternRowOpen (original : PsElabContext) (ordered : List PsExpr)
    (state : PsElabPatternRowOpened) : Except PsElabError PsElabPatternRowOpened := do
  match ordered with
  | [] => return state
  | value :: rest =>
    let type ← (psInferType original.environment original.metaContext
      original.localContext value).mapError PsElabError.infer
    let type := psElabPatternRowReplace state.replacements
      (psMetaInstantiate original.metaContext type)
    let some metaContext := psMetaRestrictScope (state.context.metaContext.nextId + 1)
        state.context.metaContext state.context.localContext type
      | throw (.refinement "pattern variable type escaped its telescope")
    let context := psElabContextWithMeta state.context metaContext
    let _ ← psElabExpressionSort context type
    let name := psNameAppendNum (psRootName "$psc0PatternVariable") context.localContext.nextId
    let pushed := psLocalPushBinding context.localContext name type .explicit
    psElabPatternRowOpen original rest {
      context := psElabContextWithLocal context pushed.context
      bindersRev := PsElabTypedBinder.mk pushed.id name type .explicit :: state.bindersRev
      replacements := state.replacements ++ [(value, .fvar pushed.id)] }

def psElabPatternRowAlias (context : PsElabContext) (name : PsName) (value : PsExpr) :
    Except PsElabError PsElabContext := do
  let .fvar id := value | throw (.refinement "pattern alias requires an actual row variable")
  let some localContext := psLocalAddNameAlias context.localContext name id
    | throw (.refinement "pattern local identity unavailable")
  return psElabContextWithLocal context localContext

def psElabPatternRowAliases (context : PsElabContext) (sources : List PsElabPatternRowSource)
    (values : List PsExpr) (explicitVariables : List PsElabTypedBinder)
    (replacements : List (PsExpr × PsExpr)) :
    Except PsElabError PsElabContext := do
  let context ← (sources.zip values).foldlM (fun context (source, value) => do
    if source.names.isEmpty then return context
    let .fvar id := value | return context
    let actualPatternLocal := replacements.any fun entry => psExprAlphaEq entry.snd (.fvar id)
    if !actualPatternLocal then return context
    source.names.foldlM (fun context name => psElabPatternRowAlias context name value) context)
    context
  explicitVariables.foldlM (fun context patternVar => do
    let some entry := replacements.find?
        (fun entry => psExprAlphaEq entry.fst (.fvar patternVar.id))
      | throw (.refinement "explicit pattern variable occurs only in inaccessible positions")
    psElabPatternRowAlias context patternVar.name entry.snd) context

def psElabPatternRowEquations (context : PsElabContext)
    (sources : List PsElabPatternRowSource) (values : List PsExpr)
    (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError (PsElabContext × List PsElabTypedBinder) := do
  match sources, values with
  | [], [] => return (context, bindersRev)
  | source :: sources, value :: values =>
    let (context, bindersRev) ← match source.equationName? with
      | none => pure (context, bindersRev)
      | some sourceName => do
        let (type, _) ← psElabIndexEquation context source.original value
        let _ ← psElabExpressionSort context type
        let name := psNameAppendNum (psRootName "$psc0RowEquation") context.localContext.nextId
        let pushed := psLocalPushBinding context.localContext name type .explicit
        let context := psElabContextWithLocal context pushed.context
        let context ← if psSyntaxNameIsWildcardBinder sourceName then pure context else do
          let some name := psSyntaxNameToName sourceName | throw .emptyName
          psElabPatternRowAlias context name (.fvar pushed.id)
        pure (context, PsElabTypedBinder.mk pushed.id name type .explicit :: bindersRev)
    psElabPatternRowEquations context sources values bindersRev
  | _, _ => throw (.refinement "pattern equation/discriminant arity mismatch")

def psElabPatternRowCoreAliases (context : PsElabContext) (ids : List Nat) :
    List (PsName × Nat) :=
  context.localContext.nameAliases.foldl (fun (result : List (PsName × Nat)) alias =>
    let visible := match psLocalFindUser context.localContext alias.userName with
      | some declaration => psLocalDeclId declaration == alias.id
      | none => false
    if ids.contains alias.id && visible &&
        !(result.any (fun entry => psNameEq entry.fst alias.userName)) then
      (alias.userName, alias.id) :: result
    else result) []

def psElabCheckPatternRow (branch : PsElaborator) (outer : PsElabContext)
    (sources : List PsElabPatternRowSource) (patterns : List PsSyntaxPattern)
    (body : PsSyntaxTerm) (matchType : PsExpr) :
    Except PsElabError (PsElabContext × PsElabCheckedPatternRow) := do
  let patterns ← patterns.mapM (psElabPatternPrepare 4096 outer.environment)
  let names := patterns.flatMap (psSyntaxPatternNames 4096)
  if psSyntaxNameListHasDuplicate names then throw (.refinement "duplicate pattern variable")
  let (context, variables) ← psElabPatternRowVariables outer names
  let lhs ← psElabPatternRowLhs branch context variables sources patterns matchType
  let occurrences := psElabPatternRowOccurrences lhs.context (variables.map (·.id)) lhs.occurrences
  for patternVar in variables do
    if !(occurrences.any (fun occurrence => psExprAlphaEq occurrence.value (.fvar patternVar.id))) then
      throw (.refinement "explicit pattern variable occurs only in inaccessible positions")
  let ordered ← psElabPatternRowOrder 4096 lhs.context occurrences
    (occurrences.map (·.value)) [] []
  let opened ← psElabPatternRowOpen lhs.context ordered {
    context := psElabLeaveScope outer lhs.context, bindersRev := [], replacements := [] }
  let replace := fun value => psElabPatternRowReplace opened.replacements
    (psMetaInstantiate lhs.context.metaContext value)
  let values := lhs.values.map replace
  let target := replace lhs.target
  let _ ← psElabExpressionSort opened.context target
  let context ← psElabPatternRowAliases opened.context sources values variables opened.replacements
  let (context, equationsRev) ← psElabPatternRowEquations context sources values
  let aliases := psElabPatternRowCoreAliases context
    ((opened.bindersRev ++ equationsRev).map (·.id))
  let result ← branch context body (some target)
  let bindersRev := equationsRev ++ opened.bindersRev
  let closedType ← psElabAbstractType outer result.context
    (bindersRev.map fun binder => .forallE binder.id binder.name binder.type binder.binder) target
  let inner := psElabContextWithMeta result.context closedType.context.metaContext
  let closed ← psElabAbstract outer inner (psElabLambdaAbstractions bindersRev)
    result.term closedType.term
  let slots ← occurrences.mapM fun occurrence => do
    let some entry := opened.replacements.find?
        (fun entry => psExprAlphaEq entry.fst occurrence.value)
      | throw (.refinement "pattern argument identity unavailable")
    let .fvar id := entry.snd | throw (.refinement "pattern argument identity unavailable")
    return (id, occurrence.path)
  let rowIds := bindersRev.reverse.map (·.id)
  let sourceAliases ← aliases.mapM fun (name, id) => do
    let some (_, position) := rowIds.zipIdx.find? (fun entry => entry.fst == id)
      | throw (.refinement "checked row source alias identity unavailable")
    return (name, position)
  let metadata : PsElabCoreRow := {
    binderCount := rowIds.length
    patterns := values.map (psCloseElabLambdaBinders closed.context.metaContext bindersRev)
    aliases := sourceAliases
    callerValues := outer.localContext.declarations.reverse.filterMap fun declaration =>
      let id := psLocalDeclId declaration
      if outer.auxiliaryLocalIds.contains id then none else some (.fvar id) }
  psElabCoreRowValidate closed.context closed.type metadata
  return (closed.context, {
    term := closed.term, type := closed.type
    binders := opened.bindersRev.reverse.map (·.id)
    slots, numEquations := equationsRev.length
    equationBinders := equationsRev.reverse.map (·.id)
    aliases, metadata, compilerPatterns := lhs.compilerPatterns })

-- Compiler application checks the real field values and then the exact named
-- proof domains. It neither reopens source syntax nor assumes a branch proof.
-- Source aliases are reified only after the generic row has been checked.
-- Later Core owners can open these checked lets when producing branch-local
-- obligations; ordinary RHS checking never sees a new alias declaration.
def psElabPatternRowReifyAliases (context : PsElabContext)
    (aliases : List (PsName × Nat)) (values : List (Nat × PsExpr))
    (term expected : PsExpr) : Except PsElabError PsElabTermResult := do
  match aliases with
  | [] => psElabResolvedTerm context term (some expected)
  | (name, id) :: rest =>
    let some (_, value) := values.find? (fun entry => entry.fst == id)
      | throw (.refinement "checked pattern row alias argument unavailable")
    let value ← psElabResolvedTerm context value none
    let pushed := psLocalPushLet value.context.localContext name value.type value.term
    let inner := psElabContextWithLocal value.context pushed.context
    let result ← psElabPatternRowReifyAliases inner rest values term expected
    psElabCloseLetScope value.context result pushed.id name value.type value.term (some expected)

def psElabApplyPatternRow (context : PsElabContext) (row : PsElabCheckedPatternRow)
    (arguments : List (Nat × PsExpr)) (equations : List PsElabSourceMatchEquation)
    (expected : PsExpr) : Except PsElabError PsElabTermResult := do
  let argumentValues ← row.binders.mapM fun id =>
    match arguments.find? (fun entry => entry.fst == id) with
    | none => throw (.refinement "checked pattern row argument unavailable")
    | some entry => pure entry.snd
  let checked ← psElabResolvedTerm context row.term (some row.type)
  let boundary ← psElabCoreBoundaryOpen checked.context .row checked.term checked.type
    (some row.metadata)
  let applied ← psElabApplyCore boundary.context (.fvar boundary.id) argumentValues
  if equations.length != row.numEquations || row.equationBinders.length != row.numEquations then
    throw (.refinement "checked pattern row equation arity mismatch")
  let (applied, values) ← (row.equationBinders.zip equations).foldlM
    (fun (state : PsElabTermResult × List (Nat × PsExpr)) (id, equation) => do
      let applied := state.fst
      let pi ← (psInferEnsureForall applied.context.environment applied.context.metaContext
        applied.context.localContext applied.type).mapError PsElabError.infer
      let proof ← psElabSourceMatchEquationConvert applied.context equation.type equation.proof pi.domain
      let applied ← psElabApplyCore proof.context applied.term [proof.term]
      return (applied, state.snd ++ [(id, proof.term)]))
    (applied, row.binders.zip argumentValues)
  let checked ← psElabResolvedTerm applied.context applied.term (some expected)
  let closed ← psElabCoreBoundaryClose boundary checked (some expected)
  psElabPatternRowReifyAliases closed.context row.aliases values closed.term expected
