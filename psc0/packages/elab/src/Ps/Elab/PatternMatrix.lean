import Ps.Elab.PatternRow
import Ps.Elab.MatchGeneralization

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
  | .wildcard _ | .variable _ | .natural _ _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .ctor syntaxName _ _ =>
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


-- Source terms are elaborated once. All matrix state retains checked Core
-- identities; source syntax remains only as name/span metadata.
structure PsElabPatternColumn where
  source : PsSyntaxMatchDiscriminant PsSyntaxTerm
  original : PsExpr
  major : PsExpr
  value : PsExpr
  type : PsExpr
  retainOriginal : Bool := false
  sourceEquation? : Option PsElabSourceMatchEquation := none
  sourceIndices : List PsExpr := []
  generalizedNames : List PsName := []
  onlyLocal : Bool := false
  path : List Nat := []

structure PsElabPatternBinding where
  name : PsName
  value : PsExpr
  type : PsExpr
  onlyLocal : Bool := false

structure PsElabPatternEquationBinding where
  name : PsName
  equation : PsElabSourceMatchEquation

structure PsElabPatternRow where
  patterns : List PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan
  generalized : List PsElabPatternBinding := []
  bindings : List PsElabPatternBinding := []
  equations : List PsElabPatternEquationBinding := []
  checked? : Option PsElabCheckedPatternRow := none
  arguments : List (Nat × PsExpr) := []

def psElabPatternIrrefutable : PsSyntaxPattern -> Bool
  | .variable _ | .wildcard _ => true
  | _ => false

def psElabPatternBind (column : PsElabPatternColumn)
    (_pattern : PsSyntaxPattern) (row : PsElabPatternRow) :
    Except PsElabError PsElabPatternRow := do
  let some checked := row.checked?
    | throw (.refinement "pattern row was not checked before compilation")
  let arguments := checked.slots.foldl (fun arguments (id, path) =>
    if path == column.path then arguments ++ [(id, column.value)] else arguments) row.arguments
  return { row with arguments }

def psElabPatternRefineEquation (refinements : PsElabRefinements)
    (equation : PsElabSourceMatchEquation) : PsElabSourceMatchEquation :=
  { equation with
    proof := psElabSubstituteLocals refinements equation.proof
    type := psElabSubstituteLocals refinements equation.type }

def psElabPatternRefineColumn (refinements : PsElabRefinements)
    (column : PsElabPatternColumn) : PsElabPatternColumn :=
  { column with
    original := if column.retainOriginal then column.original
      else psElabSubstituteLocals refinements column.original
    major := psElabSubstituteLocals refinements column.major
    value := psElabSubstituteLocals refinements column.value
    type := psElabSubstituteLocals refinements column.type
    sourceEquation? := column.sourceEquation?.map (psElabPatternRefineEquation refinements) }

def psElabPatternRefineBinding (refinements : PsElabRefinements)
    (binding : PsElabPatternBinding) : PsElabPatternBinding :=
  { binding with
    value := psElabSubstituteLocals refinements binding.value
    type := psElabSubstituteLocals refinements binding.type }

def psElabPatternRefineRow (refinements : PsElabRefinements)
    (row : PsElabPatternRow) : PsElabPatternRow :=
  { row with
    generalized := row.generalized.map (psElabPatternRefineBinding refinements)
    bindings := row.bindings.map (psElabPatternRefineBinding refinements)
    equations := row.equations.map (fun binding =>
      { binding with equation := psElabPatternRefineEquation refinements binding.equation })
    arguments := row.arguments.map (fun (id, value) =>
      (id, psElabSubstituteLocals refinements value))
    checked? := row.checked?.map fun checked =>
      { checked with
        term := psElabSubstituteLocals refinements checked.term
        type := psElabSubstituteLocals refinements checked.type } }

-- A hidden index hint names only a surviving pattern local. A solved index
-- never becomes an unconditional source let binding.
def psElabPatternBindingVisible (context : PsElabContext)
    (protectedIds : List Nat) (binding : PsElabPatternBinding) : Bool :=
  if !binding.onlyLocal then true
  else match psMetaInstantiate context.metaContext binding.value with
    | .fvar id => !protectedIds.contains id &&
        (psLocalFindById context.localContext id).isSome
    | _ => false

-- Source names and RHS syntax were resolved in the checked row telescope.
-- This terminal compiler step applies only its actual retained Core arguments.
def psElabPatternBody (_branch : PsElaborator) (context : PsElabContext)
    (row : PsElabPatternRow) (expected : PsExpr) (_protectedIds : List Nat) :
    Except PsElabError PsElabTermResult := do
  let some checked := row.checked?
    | throw (.refinement "pattern row was not checked before compilation")
  psElabApplyPatternRow context checked row.arguments
    (row.equations.map (·.equation)) expected

def psElabPatternEquation (context : PsElabContext)
    (name? : Option PsSyntaxName) (equation? : Option PsElabSourceMatchEquation) :
    Except PsElabError (PsElabContext × Option PsElabPatternEquationBinding) := do
  match name? with
  | none => return (context, none)
  | some sourceName =>
    let some equation := equation?
      | throw (.refinement "named match branch equation unavailable")
    let (context, equation) ← psElabSourceMatchEquationNormalize context equation
    let checked ← psElabResolvedTerm context equation.proof (some equation.type)
    let some name := psSyntaxNameToName sourceName | throw .emptyName
    return (checked.context, some {
      name, equation := { equation with proof := checked.term, type := checked.type } })

def psElabPatternAddEquation (equation : Option PsElabPatternEquationBinding)
    (row : PsElabPatternRow) : PsElabPatternRow :=
  match equation with
  | none => row
  | some binding => { row with equations := row.equations ++ [binding] }

-- Required transport comes from retained typed state, including proof slots.
-- The motive owner computes its backwards dependency closure separately from
-- optional source generalization.
def psElabPatternRequiredIds (context : PsElabContext)
    (columns : List PsElabPatternColumn) (rows : List PsElabPatternRow) : List Nat :=
  let values := columns.flatMap fun column =>
    [column.original, column.major, column.value, column.type] ++
      column.sourceEquation?.toList.flatMap (fun equation => [equation.proof, equation.type])
  let values := values ++ rows.flatMap fun row =>
    (row.generalized ++ row.bindings).flatMap (fun binding => [binding.value, binding.type]) ++
      row.equations.flatMap (fun binding => [binding.equation.proof, binding.equation.type]) ++
      row.arguments.map Prod.snd ++
      row.checked?.toList.flatMap (fun checked => [checked.term, checked.type])
  let values := values.map (psMetaInstantiate context.metaContext)
  context.localContext.declarations.reverse.filterMap fun declaration =>
    let id := psLocalDeclId declaration
    if values.any (psElabExprContainsLocal id) then some id else none

-- Every split consumes the shared typed Match owner. Optional ys already
-- occur in the checked complete telescope, so a split never reselects them.
def psElabPatternMatrix (fuel : Nat) (branch : PsElaborator)
    (context : PsElabContext) (columns : List PsElabPatternColumn)
    (rows : List PsElabPatternRow) (expected : PsExpr)
    (generalizing? : Option Bool) (protectedIds : List Nat) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match columns with
    | [] =>
      let some row := rows.head? | throw .matchNonExhaustive
      psElabPatternBody branch context row expected protectedIds
    | column :: rest =>
      if rows.isEmpty then
        let rec eliminate (remaining : List PsElabPatternColumn) :
            Except PsElabError PsElabTermResult := do
          match remaining with
          | [] => throw .matchNonExhaustive
          | column :: remaining =>
            match psElabMatchTypedWith (fun _ _ => pure [])
                { context, term := column.major, type := column.type } (some expected)
                column.source.equationName? generalizing? (some []) []
                column.sourceEquation? protectedIds column.sourceIndices with
            | .ok result => return result
            | .error .matchNonExhaustive => eliminate remaining
            | .error error => throw error
        return ← eliminate columns
      if rows.all (fun row => (row.patterns.head?.map psElabPatternIrrefutable).getD false) then
        let (context, equation) ← psElabPatternEquation context
          column.source.equationName? column.sourceEquation?
        let rows ← rows.mapM fun row => do
          let pattern :: patterns := row.patterns | throw .matchPatternUnsupported
          let row ← psElabPatternBind column pattern row
          return psElabPatternAddEquation equation { row with patterns }
        return ← psElabPatternMatrix fuel branch context rest rows expected generalizing? protectedIds
      let requiredIds := psElabPatternRequiredIds context rest rows
      psElabMatchTypedWith (fun current info => do
        let rows ← rows.mapM fun row => do
          let pattern :: _ := row.patterns | throw .matchPatternUnsupported
          if psElabPatternIrrefutable pattern then return (none, row)
          let pattern := match pattern with
            | .natural value span =>
              if value == 0 then
                PsSyntaxPattern.ctor (PsSyntaxName.mk ["Nat", "zero"] span) [] span
              else .ctor (PsSyntaxName.mk ["Nat", "succ"] span) [.natural (value - 1) span] span
            | _ => pattern
          let row := { row with patterns := pattern :: row.patterns.drop 1 }
          let name ← psElabMatchPatternConstructorName info.name pattern
          if !(info.constructors.any (psNameEq name)) then throw (.matchConstructorUnknown name)
          let some ctor := psEnvironmentFindConstructor current.environment name
            | throw (.matchConstructorUnknown name)
          let count := match pattern with | .ctor _ fields _ => fields.length | _ => 0
          if count != ctor.numFields then throw (.matchConstructorArity name)
          return (some name, row)
        info.constructors.mapM fun name => do
          let some ctor := psEnvironmentFindConstructor current.environment name
            | throw (.matchConstructorUnknown name)
          let span := psSyntaxTermSpan column.source.term
          let fields := (List.range ctor.numFields).map fun index =>
            PsSyntaxName.mk ["$psc0Pattern", psNatToString current.localContext.nextId,
              psNatToString index] span
          let selected ← rows.foldlM (fun selected (head, row) => do
            let pattern :: patterns := row.patterns | throw .matchPatternUnsupported
            if head.isNone then
              let row ← psElabPatternBind column pattern row
              return selected ++ [{ row with patterns :=
                (fields.map fun _ => PsSyntaxPattern.wildcard span) ++ patterns }]
            else if (head.map (psNameEq name)).getD false then
              let children := match pattern with | .ctor _ fields _ => fields | _ => []
              return selected ++ [{ row with patterns := children ++ patterns }]
            else return selected) []
          return {
            constructorName := name
            fieldNames := fields
            elaborate := fun child => do
              if child.fields.length != fields.length then throw .matchRecursorUnsupported
              let fieldColumns := (fields.zip child.fields).zipIdx.map fun ((name, binder), index) =>
                psElabPatternRefineColumn child.refinements {
                  source := { term := .reference name }
                  original := .fvar binder.id
                  major := .fvar binder.id
                  value := .fvar binder.id
                  type := binder.type
                  path := column.path ++ [index] }
              let rest := rest.map (psElabPatternRefineColumn child.refinements)
              let selected := selected.map (psElabPatternRefineRow child.refinements)
              -- This proof is already in the final child context. Only retained
              -- equations above consume the current branch's refinement log.
              let (context, equation) ← psElabPatternEquation child.context
                column.source.equationName? child.sourceEquation?
              let selected := selected.map (psElabPatternAddEquation equation)
              psElabPatternMatrix fuel branch context (fieldColumns ++ rest) selected
                child.target generalizing? protectedIds
            span })
        { context, term := column.major, type := column.type } (some expected)
        column.source.equationName? generalizing? (some []) requiredIds
        column.sourceEquation? protectedIds column.sourceIndices

structure PsElabPatternInputs where
  context : PsElabContext
  columns : List PsElabPatternColumn
  locals : List (PsElabTypedBinder × PsExpr)
  generalizationMajors : List PsExpr

-- Provenance is captured in the caller's scope. Constructor field columns
-- intentionally have no source indices from which to request a retry.
def psElabPatternSourceIndices (context : PsElabContext) (type : PsExpr) : List PsExpr :=
  let view := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext type)
  match view.head with
  | .constE name _ =>
    match psEnvironmentFindInductive context.environment name with
    | some info =>
      if view.args.length == info.numParams + info.numIndices then
        view.args.drop info.numParams
      else []
    | none => []
  | _ => []

-- Only caller-scoped computed inputs use lets. The runtime discriminants
-- opened below are independent ordinary binders.
def psElabPatternFreeze (context : PsElabContext)
    (source : PsSyntaxMatchDiscriminant PsSyntaxTerm) (value type : PsExpr)
    (generalizedNames : List PsName := []) (onlyLocal : Bool := false) :
    Except PsElabError
      (PsElabContext × PsElabPatternColumn × List (PsElabTypedBinder × PsExpr)) := do
  let checked ← psElabResolvedTerm context value (some type)
  let column : PsElabPatternColumn := {
    source, original := checked.term, major := checked.term, value := checked.term
    type := checked.type, retainOriginal := true
    sourceIndices := psElabPatternSourceIndices checked.context checked.type
    generalizedNames, onlyLocal }
  match checked.term with
  | .fvar _ => return (checked.context, column, [])
  | _ =>
    let name := psNameAppendNum (psRootName "$psc0Discriminant")
      checked.context.localContext.nextId
    let pushed := psLocalPushLet checked.context.localContext name checked.type checked.term
    let context := psElabContextWithLocal checked.context pushed.context
    let value := PsExpr.fvar pushed.id
    return (context, { column with original := value, major := value, value },
      [(PsElabTypedBinder.mk pushed.id name checked.type .explicit, checked.term)])

def psElabPatternInputs (elaborate : PsElaborator) (context : PsElabContext)
    (sources : List (PsSyntaxMatchDiscriminant PsSyntaxTerm)) :
    Except PsElabError PsElabPatternInputs := do
  match sources with
  | [] => return { context, columns := [], locals := [], generalizationMajors := [] }
  | source :: rest =>
    let value ← elaborate context source.term none
    let (context, column, locals) ← psElabPatternFreeze value.context source value.term value.type
    let tail ← psElabPatternInputs elaborate context rest
    return {
      context := tail.context
      columns := column :: tail.columns
      locals := locals ++ tail.locals
      generalizationMajors := value.term :: tail.generalizationMajors }

-- A named discriminator supplies a genuine whole-match proof argument.
-- Independent ds may need HEq here; no reflexivity proof is assumed in scope.
def psElabPatternOpenEquations (context : PsElabContext)
    (columns : List PsElabPatternColumn) (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError (PsElabContext × List PsElabPatternColumn × List PsElabTypedBinder) := do
  match columns with
  | [] => return (context, [], bindersRev)
  | column :: rest =>
    let (context, column, bindersRev) ← match column.source.equationName? with
      | none => pure (context, column, bindersRev)
      | some _ => do
        let (type, _) ← psElabIndexEquation context column.original column.major
        let _ ← psElabExpressionSort context type
        let name := psNameAppendNum (psRootName "$psc0SourceEquation") context.localContext.nextId
        let pushed := psLocalPushBinding context.localContext name type .explicit
        let context := psElabContextWithLocal context pushed.context
        pure (context, { column with sourceEquation? := some {
            original := column.original, proof := .fvar pushed.id, type } },
          PsElabTypedBinder.mk pushed.id name type .explicit :: bindersRev)
    let (context, rest, bindersRev) ← psElabPatternOpenEquations context rest bindersRev
    return (context, column :: rest, bindersRev)

-- The legacy structural collector follows actual fresh header identities.
-- A nested match retains established field-to-IH observations unchanged.
def psElabPatternStructuralContext (context : PsElabContext)
    (replacements : List (Nat × PsExpr)) : PsElabContext :=
  match context.structuralRecursion with
  | none => context
  | some recursion =>
    if !recursion.collectCalls then context
    else
      let remap := fun id =>
        match psElabSubstituteLocals replacements (.fvar id) with
        | .fvar current => current
        | _ => id
      psElabContextWithStructuralRecursion context (some { recursion with
        parameterIds := recursion.parameterIds.map remap
        explicitParameterIds := recursion.explicitParameterIds.map remap
        resultType := psElabSubstituteLocals replacements recursion.resultType })

-- Instantiate each actual proof-slot domain before constructing reflexivity.
-- A heterogeneous slot remains HEq even when applying ds makes its types equal.
def psElabPatternApplyReflexivity (count : Nat) (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  match count with
  | 0 => return result
  | count + 1 =>
    let context := result.context
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext result.type).mapError PsElabError.infer
    let view := psExprAppView
      (psWhnf context.environment context.metaContext context.localContext pi.domain)
    let proof ← match view.head, view.args with
      | .constE name [level], [type, _, right] =>
        if !psNameEq name psEqName then
          throw (.refinement "source match reflexivity expected Eq or HEq")
        pure (psLogicRefl level type right)
      | .constE name [level], [_, _, rightType, right] =>
        if !psNameEq name (psRootName "HEq") then
          throw (.refinement "source match reflexivity expected Eq or HEq")
        pure (psExprApplyMany
          (.constE (psNameAppendStr (psRootName "HEq") "refl") [level]) [rightType, right])
      | _, _ => throw (.refinement "source match reflexivity expected Eq or HEq")
    let checked ← psElabResolvedTerm context proof (some pi.domain)
    let applied ← psElabApplyCore checked.context result.term [checked.term]
    psElabPatternApplyReflexivity count applied

-- Reify the complete chosen ds/ys telescope, then close and apply it. This
-- abstracts computed majors through later domains as well as the result type.
def psElabPatternRunPlan (branch : PsElaborator) (inputs : PsElabPatternInputs)
    (rows : List PsElabPatternRow) (plan : PsElabSourceMatchPlan)
    (generalizing? : Option Bool) (expected : PsExpr) :
    Except PsElabError PsElabTermResult := do
  if inputs.columns.length != plan.rawMajors.length then
    throw (.refinement "source match telescope arity mismatch")
  let selected ← plan.selectedIds.mapM fun id => do
    let some _ := psLocalFindById plan.context.localContext id
      | throw (.refinement "source match generalized local unavailable")
    return (id, psLocalVisibleNames plan.context.localContext id)
  let generalizedSources ← selected.mapM fun (id, names) => do
    let some declaration := psLocalFindById plan.context.localContext id
      | throw (.refinement "source match generalized local unavailable")
    return ({
      original := PsExpr.fvar id
      type := psLocalDeclType declaration
      names := names } : PsElabPatternRowSource)
  let sources := inputs.columns.map (fun column =>
    { original := column.original, type := column.type
      equationName? := column.source.equationName?
      names := column.generalizedNames, onlyLocal := column.onlyLocal : PsElabPatternRowSource }) ++
      generalizedSources
  let rows := rows.map fun row => {
    row with
    patterns := row.patterns ++ selected.map (fun _ => PsSyntaxPattern.wildcard row.span) }
  let (context, rows) ← rows.foldlM
    (fun (state : PsElabContext × List PsElabPatternRow) row => do
      let (context, checked) ← psElabCheckPatternRow branch state.fst sources
        row.patterns row.body plan.matchType
      return (context, state.snd ++ [{ row with checked? := some checked }]))
    (plan.context, [])
  let plan := { plan with context }
  let arguments := inputs.columns.map (·.value) ++ selected.map (fun entry => PsExpr.fvar entry.fst)
  let (opened, replacements) ← psElabSourceMatchOpenMajors
    (plan.rawMajors ++ selected.map (fun entry => PsExpr.fvar entry.fst))
    plan.context plan.matchType
  let binders := opened.bindersRev.reverse
  if binders.length != inputs.columns.length + selected.length then
    throw (.refinement "source match telescope arity mismatch")
  let columns := (inputs.columns.zip (binders.take inputs.columns.length)).zipIdx.map
    fun ((column, binder), index) =>
      { column with major := .fvar binder.id, value := .fvar binder.id,
        type := binder.type, path := [index] }
  let some first := columns.head? | throw .matchScrutineeUnsupported
  let span := psSyntaxTermSpan first.source.term
  let generalized := (selected.zip (binders.drop inputs.columns.length)).zipIdx.map fun (((id, names), binder), index) =>
    { source := { term := PsSyntaxTerm.hole span }
      original := PsExpr.fvar id
      major := PsExpr.fvar binder.id
      value := PsExpr.fvar binder.id
      type := binder.type
      retainOriginal := true
      generalizedNames := names
      path := [inputs.columns.length + index] : PsElabPatternColumn }
  let (context, columns, equationBindersRev) ←
    psElabPatternOpenEquations opened.context (columns ++ generalized)
  let context := psElabPatternStructuralContext context replacements
  let protectedIds := plan.context.localContext.declarations.map psLocalDeclId
  let result ← psElabPatternMatrix 4096 branch context columns rows opened.body
    generalizing? protectedIds
  let bindersRev := equationBindersRev ++ opened.bindersRev
  let typeAbstractions := bindersRev.map fun binder =>
    PsMetaAbstraction.forallE binder.id binder.name binder.type binder.binder
  let closedType ← psElabAbstractType plan.context result.context typeAbstractions opened.body
  let inner := psElabContextWithMeta result.context closedType.context.metaContext
  let closed ← psElabAbstract plan.context inner
    (psElabLambdaAbstractions bindersRev) result.term closedType.term
  let applied ← psElabApplyCore closed.context closed.term arguments
  let applied ← psElabPatternApplyReflexivity equationBindersRev.length applied
  psElabResolvedTerm applied.context applied.term (some expected)

-- Retry indices are checked Core expressions from the saved caller scope.
-- No source term is elaborated again while extending the base telescope.
def psElabPatternIndexInputs (context : PsElabContext)
    (indices : List PsExpr) (named : Bool) (span : PsSourceSpan) :
    Except PsElabError PsElabPatternInputs := do
  match indices with
  | [] => return { context, columns := [], locals := [], generalizationMajors := [] }
  | index :: rest =>
    let type ← (psInferType context.environment context.metaContext
      context.localContext index).mapError PsElabError.infer
    let hint := match index with
      | .fvar id => psLocalVisibleNames context.localContext id
      | _ => []
    let source : PsSyntaxMatchDiscriminant PsSyntaxTerm := {
      term := .hole span
      equationName? := if named then some (PsSyntaxName.mk ["_"] span) else none }
    let (context, column, locals) ←
      psElabPatternFreeze context source index type hint true
    let tail ← psElabPatternIndexInputs context rest named span
    return {
      context := tail.context
      columns := column :: tail.columns
      locals := locals ++ tail.locals
      generalizationMajors := index :: tail.generalizationMajors }

-- Keep the raw base apart from the chosen optional extension. Native index
-- refinement prefixes that base, restores the pre-attempt state, and selects
-- optional ys again. Only the dedicated index-alignment request enters here.
def psElabPatternSourceLoop (fuel : Nat) (branch : PsElaborator)
    (inputs : PsElabPatternInputs) (rows : List PsElabPatternRow)
    (baseMatchType expected : PsExpr) (generalizing? : Option Bool)
    (first? : Option PsElabError := none) :
    Except PsElabError (PsElabPatternInputs × PsElabTermResult) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let plan ← psElabSourceMatchGeneralizationFromType inputs.context
      inputs.generalizationMajors (inputs.columns.map (·.type)) baseMatchType generalizing?
    match psElabPatternRunPlan branch inputs rows plan generalizing? expected with
    | .ok result => return (inputs, result)
    | .error (.sourceMatchIndexRefinement requested named cause) =>
      let cause := first?.getD cause
      let context := inputs.context
      let requested := requested.map (psMetaInstantiate context.metaContext)
      if requested.isEmpty then throw cause
      for index in requested do
        if !psMetaExprScopeSafe context.metaContext context.localContext index then throw cause
        let type ← match psInferType context.environment context.metaContext
            context.localContext index with
          | .ok type => pure type
          | .error error =>
            let error := PsElabError.infer error
            if psElabErrorIsResource error then throw error else throw cause
        if !psMetaExprScopeSafe context.metaContext context.localContext type then throw cause
        match psElabExpressionSort context type with
        | .ok _ => pure ()
        | .error error =>
          if psElabErrorIsResource error then throw error else throw cause
        if inputs.generalizationMajors.any (fun major =>
            psDefEqReadOnlyWithEnv context.environment context.metaContext
              context.localContext major index) then throw cause
      let indices ← psElabSourceMatchIndexDependencies context requested inputs.generalizationMajors
      if indices.isEmpty then throw cause
      let (context, baseMatchType) ←
        match psElabSourceMatchPrefixIndices context indices baseMatchType with
        | .ok result => pure result
        | .error error =>
          if psElabErrorIsResource error then throw error else throw cause
      let some first := inputs.columns.head? | throw .matchScrutineeUnsupported
      let added ← psElabPatternIndexInputs context indices named (psSyntaxTermSpan first.source.term)
      let inputs : PsElabPatternInputs := {
        context := added.context
        columns := added.columns ++ inputs.columns
        locals := inputs.locals ++ added.locals
        generalizationMajors := added.generalizationMajors ++ inputs.generalizationMajors }
      let rows := rows.map fun row => {
        row with
        patterns := indices.map (fun _ => PsSyntaxPattern.wildcard row.span) ++ row.patterns }
      psElabPatternSourceLoop fuel branch inputs rows baseMatchType expected generalizing? (some cause)
    | .error error => throw error

def psElabMatchMatrixSourceWith (elaborate branch : PsElaborator) (context : PsElabContext)
    (sources : List (PsSyntaxMatchDiscriminant PsSyntaxTerm))
    (alternatives : List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
    (generalizing? : Option Bool) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  -- The result constraint belongs to the caller, before pattern fields exist.
  let target := match expected with
    | some type => PsElabTypeResult.mk context type
    | none => psElabFreshType context
  let expected := target.type
  if sources.isEmpty then throw .matchScrutineeUnsupported
  let rows ← alternatives.mapM fun (patterns, body, span) => do
    if patterns.length != sources.length then
      throw (.refinement "pattern row/discriminant arity mismatch")
    let names := patterns.flatMap (psSyntaxPatternNames 4096)
    if psSyntaxNameListHasDuplicate names then throw (.refinement "duplicate pattern variable")
    return { patterns, body, span : PsElabPatternRow }
  let inputs ← psElabPatternInputs elaborate target.context sources
  -- Optional ys can repair an initially ill-typed raw base. Validate the
  -- actual chosen complete telescope in FromType, not a premature false plan.
  let (prepared, baseMatchType) ← psElabSourceMatchBaseType inputs.context
    (inputs.generalizationMajors.zip (inputs.columns.map (·.type))) expected
  let inputs := { inputs with context := prepared }
  let (inputs, result) ← psElabPatternSourceLoop 4096 branch inputs rows
    baseMatchType expected generalizing?
  let abstractions := inputs.locals.reverse.map fun (binder, value) =>
    PsMetaAbstraction.letE binder.id binder.name binder.type value
  psElabAbstract context result.context abstractions result.term expected

def psElabMatchMatrixSource (elaborate : PsElaborator) : PsElabContext →
    List (PsSyntaxMatchDiscriminant PsSyntaxTerm) →
    List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan) →
    Option Bool → Option PsExpr → Except PsElabError PsElabTermResult :=
  psElabMatchMatrixSourceWith elaborate elaborate

-- Generated pattern lets and existing internal callers retain their syntax API.
def psElabMatchMatrixWith (elaborate branch : PsElaborator) (context : PsElabContext)
    (sources : List PsSyntaxTerm)
    (alternatives : List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  psElabMatchMatrixSourceWith elaborate branch context
    (sources.map fun term => { term }) alternatives none expected

def psElabMatchMatrix (elaborate : PsElaborator) : PsElabContext →
    List PsSyntaxTerm → List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan) →
    Option PsExpr → Except PsElabError PsElabTermResult :=
  psElabMatchMatrixWith elaborate elaborate
