import Ps.Core.Abstract
import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Environment.Resolve
import Ps.Meta.Infer
import Ps.Meta.SynthInstance
import Ps.Meta.Unify
import Ps.Syntax.Ast
import Ps.Elab.Context
import Ps.Elab.Literal

inductive PsElabError where
  | fuelExhausted
  | emptyName
  | unknownName (name : PsName)
  | invalidNatural (text : String)
  | invalidString (text : String)
  | invalidCharacter (text : String)
  | infer (error : PsInferError)
  | typeMismatch
  | implicitApplicationUnsupported
  | emptyCallUnsupported
  | invalidArgument (message : String)
  | scope (message : String)
  | data (message : String)
  | proof (message : String)
  | refinement (message : String)
  | atDeclaration (name : PsName) (error : PsElabError)
  | atContext (label : String) (error : PsElabError)
  | unsupportedTerm
  | matchExpectedType
  | matchScrutineeUnsupported
  | matchInductiveUnsupported
  | matchParameterArity
  | matchPatternUnsupported
  | matchConstructorUnknown (name : PsName)
  | matchDuplicateConstructor (name : PsName)
  | matchNonExhaustive
  | matchRecursorUnsupported
  | matchRecursorLevels
  | matchConstructorArity (name : PsName)
  | matchRecursiveFieldUnsupported (name : PsName)
  | duplicateDeclaration (name : PsName)
  | unresolvedMetavariable
  | structuralRecursionArity
  | structuralRecursionNotDecreasing
  | structuralRecursionInvariantArgument
  | structuralRecursionInternal
  | structuralRecursionDependentParameter
  | structuralRecursionEscapingReference

-- Resource failures cannot become speculative mismatches or resumable work.
def psElabErrorIsResource : PsElabError → Bool
  | .fuelExhausted | .infer .fuelExhausted => true
  | .atDeclaration _ error | .atContext _ error => psElabErrorIsResource error
  | _ => false

structure PsElabTermResult where
  context : PsElabContext
  term : PsExpr
  type : PsExpr

-- Callers supply a weak-head-normalized type. A result family's explicit
-- scope arguments do not make its unsolved result structurally known.
def psElabExpectedTypeIsUnconstrained (context : PsElabContext) (type : PsExpr) : Bool :=
  match type with
  | .mvar _ => true
  | _ => (psUnifyResultFamilyView context.metaContext type).isSome

def psElabBoolNot (value : Bool) : Bool :=
  if value then false else true

def psElabBoolOr (left right : Bool) : Bool :=
  if left then true else right

def psElabBoolAnd (left right : Bool) : Bool :=
  if left then right else false

def psElabStructuralParameterAt
    (ids : List Nat) : Nat -> Option Nat :=
  match ids with
  | List.nil => fun (_index : Nat) => Option.none
  | List.cons id rest =>
      let smaller : Nat -> Option Nat := psElabStructuralParameterAt rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => Option.some id
        | Nat.succ next => smaller next

-- Abstraction changes exactly the selected free ID. Equality with the original
-- instantiated type therefore checks its absence without a printed-name test.
def psElabCheckStructuralType
    (context : PsElabContext) (majorId : Nat) (type : PsExpr) :
    Except PsElabError Unit :=
  let instantiated := psMetaInstantiate context.metaContext type;
  if psExprHasUnresolvedMeta instantiated then
    Except.error PsElabError.unresolvedMetavariable
  else if psExprAlphaEq instantiated (psExprAbstractFVar majorId instantiated) then
    Except.ok Unit.unit
  else Except.error PsElabError.structuralRecursionDependentParameter

def psElabCheckStructuralParameters
    (context : PsElabContext) (majorId : Nat) (parameterIds : List Nat) :
    Except PsElabError Unit :=
  match parameterIds with
  | List.nil => Except.ok Unit.unit
  | List.cons id rest =>
      match psLocalFindById context.localContext id with
      | Option.none => Except.error PsElabError.structuralRecursionInternal
      | Option.some declaration =>
          match psElabCheckStructuralType context majorId (psLocalDeclType declaration) with
          | Except.error error => Except.error error
          | Except.ok _ => psElabCheckStructuralParameters context majorId rest

-- Recursion may vary the major and its generalized indices. Every other
-- parameter must have a type independent of them; otherwise its recursive
-- replacement would require dependent context generalization.
def psElabCheckStructuralTelescope (context : PsElabContext)
    (recursion : PsElabStructuralRecursion) : Except PsElabError Nat := do
  let some majorId := psElabStructuralParameterAt recursion.explicitParameterIds
    recursion.recursiveParameterIndex | throw .structuralRecursionInternal
  let varying := majorId :: recursion.indices.map Prod.fst
  let fixed := recursion.parameterIds.filter (fun id => !varying.contains id)
  for id in varying do
    psElabCheckStructuralParameters context id fixed
  if !recursion.refined then
    psElabCheckStructuralType context majorId recursion.resultType
  return majorId

def psElabNatNe (left right : Nat) : Bool :=
  if Nat.beq left right then false else true

def psElabListLength {α : Type}
    (values : List α) : Nat :=
  match values with
  | [] => 0
  | _ :: rest => Nat.succ (psElabListLength rest)

def psSyntaxNameAppendSegments
    (segments : List String) :
    PsName -> PsName :=
  match segments with
  | [] =>
      fun (name : PsName) =>
        name
  | segment :: rest =>
      let smaller : PsName -> PsName :=
        psSyntaxNameAppendSegments rest;
      fun (name : PsName) =>
        smaller (psNameAppendStr name segment)

def psSyntaxNameRootSegments (segments : List String) : List String :=
  match segments with
  | "_root_" :: rest => rest
  | _ => segments

def psSyntaxNameToName (name : PsSyntaxName) : Option PsName :=
  match psSyntaxNameRootSegments name.segments with
  | [] => none
  | first :: rest => some (psSyntaxNameAppendSegments rest (psRootName first))

def psElabResultWithMeta
    (result : PsElabTermResult)
    (metaContext : PsMetaContext)
    (type : PsExpr) : PsElabTermResult :=
  {
    context := psElabContextWithMeta result.context metaContext
    term := psMetaInstantiate metaContext result.term
    type := psMetaInstantiate metaContext type
  }

-- Apply already elaborated Core arguments through the declared telescope.
-- This solves domain/universe constraints before handing a goal to instance
-- search; it never inserts source implicits or fabricates a binder type.
def psElabApplyCore (context : PsElabContext) (head : PsExpr)
    (arguments : List PsExpr) : Except PsElabError PsElabTermResult := do
  let type ← (psInferType context.environment context.metaContext context.localContext head).mapError
    PsElabError.infer
  arguments.foldlM (fun (current : PsElabTermResult) argument => do
    let pi ← (psInferEnsureForall current.context.environment current.context.metaContext
      current.context.localContext current.type).mapError PsElabError.infer
    let actual ← (psInferType current.context.environment current.context.metaContext
      current.context.localContext argument).mapError PsElabError.infer
    let unified := psUnify current.context.environment current.context.localContext
      current.context.metaContext pi.domain actual
    if unified.resourceExceeded then throw .fuelExhausted
    if !unified.success then throw .typeMismatch
    return psElabResultWithMeta {
      context := current.context, term := .app current.term argument
      type := psExprInstantiate1 pi.body argument } unified.context
        (psExprInstantiate1 pi.body argument))
    { context, term := head, type }

def psElabUnifyExpected
    (result : PsElabTermResult)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match expected with
  | none => Except.ok result
  | some expectedType =>
      let unified :=
        psUnify
          result.context.environment
          result.context.localContext
          result.context.metaContext
          result.type
          expectedType;
      if unified.resourceExceeded then
        Except.error PsElabError.fuelExhausted
      else if unified.success then
        Except.ok
          (psElabResultWithMeta
            result
            unified.context
            expectedType)
      else
        Except.error PsElabError.typeMismatch

-- A coercion is an ordinary checked class projection. The caller supplies
-- input/output arguments; this operation performs exactly one registry lookup.
def psElabCoerce (result : PsElabTermResult) (classText : String)
    (target : Option PsExpr) (dependent : Bool := false) :
    Except PsElabError PsElabTermResult := do
  let context := result.context
  let sourceSort ← (psInferType context.environment context.metaContext context.localContext
    result.type).mapError PsElabError.infer
  let u ← (psInferEnsureSort context.environment context.metaContext context.localContext
    sourceSort).mapError PsElabError.infer
  let v := psMetaFreshLevel context.metaContext
  let outputType := if dependent then
      PsExpr.forallE (psRootName "value") result.type (.sortE v.level) .explicit
    else .sortE v.level
  let (context, output) := match target with
    | some type => (psElabContextWithMeta context v.context, type)
    | none =>
      let fresh := psMetaFresh v.context context.localContext outputType .natural
      (psElabContextWithMeta context fresh.context, fresh.expr)
  let className := psRootName classText
  let goal ← psElabApplyCore context (.constE className [u, v.level]) [result.type, output]
  let search := psSynthInstanceWithLimits context.environment context.localContext
    context.instances goal.context.metaContext 64 {} goal.term
  if search.table.resourceExceeded then throw .fuelExhausted
  let some dictionary := search.result.value | throw .typeMismatch
  let context := psElabRecordInfo (psElabContextWithMeta context search.result.context)
    (.instanceSelection context.sourceSpan goal.term dictionary)
  psElabApplyCore context
    (.constE (psNameAppendStr className "coe") [u, v.level])
    [result.type, output, dictionary, result.term]

-- Applications and literal notation use the same scoped constraint owner.
def psElabSolveSynthetic (current : PsElabTermResult)
    (pending : List PsSyntheticConstraint) : Except PsElabError PsElabTermResult := do
  let solved := psSyntheticSolve current.context.environment current.context.instances
    current.context.metaContext pending (!current.context.postponing)
  if solved.resourceExceeded then throw .fuelExhausted
  if current.context.postponing then
    for constraint in solved.pending do
      if !psSyntheticMayRetry solved.context constraint then
        match constraint with
        | .instanceGoal _ => throw .implicitApplicationUnsupported
        | _ => throw .typeMismatch
    let result := psElabResultWithMeta current solved.context current.type
    let scope := psElabSaveScope result.context
    return { result with context := { result.context with
      pending := solved.pending.reverse.map (PsElabPendingWork.core scope) ++
        result.context.pending } }
  -- Preserve the reason for failure at the elaborator boundary; a blocked
  -- expected/default equality is a type mismatch, not a missing dictionary.
  match solved.pending.head? with
  | some (.expectedType _ _ _) | some (.defaultValue _ _) => throw .typeMismatch
  | some (.instanceGoal _) => throw .implicitApplicationUnsupported
  | none => pure ()
  return psElabResultWithMeta current solved.context current.type

-- All syntax-owned dictionaries share the same synthetic queue, including
-- proposition conditions and Prop-to-Bool conversions. Evidence remains an
-- ordinary checked term; unresolved decisions never become runtime guesses.
def psElabSynthesizeInstance (context : PsElabContext) (target : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let fresh := psMetaFresh context.metaContext context.localContext target .synthetic
  let .mvar id := fresh.expr | throw .unresolvedMetavariable
  psElabSolveSynthetic {
    context := psElabRecordInfo (psElabContextWithMeta context fresh.context)
      (.instanceSelection context.sourceSpan target fresh.expr),
    term := fresh.expr, type := target } [.instanceGoal id]

def psElabDecideProposition (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  let target := PsExpr.app (.constE psDecidableName []) result.term
  let dictionary ← psElabSynthesizeInstance result.context target
  psElabApplyCore dictionary.context
    (.constE (psNameAppendStr psDecidableName "decide") [])
    [result.term, dictionary.term]

def psElabFinalizeExpected (result : PsElabTermResult) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  match psElabUnifyExpected result expected with
  | .ok checked => return checked
  | .error error =>
    if psElabErrorIsResource error then throw error
    let some target := expected | throw error
    -- Keep a typed result hole while its actual/expected type is blocked.
    -- Mandatory defaults and later arguments may resolve it before a Coe
    -- dictionary can be selected. Retrying owns the original lexical scope.
    let context := result.context
    let constraint := PsSyntheticConstraint.expectedType context.localContext result.type target
    if context.postponing && psSyntheticMayRetry context.metaContext constraint then
      let fresh := psMetaFresh context.metaContext context.localContext target .syntheticOpaque
      let .mvar id := fresh.expr | throw .unresolvedMetavariable
      return { context := { context with
                 metaContext := fresh.context
                 pending := .expectedTerm (psElabSaveScope context) id result.term result.type ::
                   context.pending },
               term := fresh.expr, type := target }
    -- The failed conversion is speculative. Synthesis starts from the original
    -- context, and the final strict check cannot insert a second coercion.
    let isProp := psDefEqReadOnlyWithEnv context.environment context.metaContext
      context.localContext result.type (.sortE .zero)
    let isBool := psDefEqReadOnlyWithEnv context.environment context.metaContext
      context.localContext target (.constE psBoolName [])
    let converted ← (if isProp && isBool then psElabDecideProposition result
        else psElabCoerce result "Coe" (some target)).mapError fun failure =>
      if psElabErrorIsResource failure then failure else error
    psElabUnifyExpected converted expected

def psElabEnsureFunction (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  match psWhnf result.context.environment result.context.metaContext
      result.context.localContext result.type with
  | .forallE _ _ _ _ => return result
  | _ =>
    let converted ← (psElabCoerce result "CoeFun" none true).mapError fun error =>
      if psElabErrorIsResource error then error else .infer .expectedFunction
    match psWhnf converted.context.environment converted.context.metaContext
        converted.context.localContext converted.type with
    | .forallE _ _ _ _ => return converted
    | _ => throw (.infer .expectedFunction)

def psElabEnsureType (result : PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  match psWhnf result.context.environment result.context.metaContext
      result.context.localContext result.type with
  | .sortE _ => return result
  | _ =>
    let converted ← (psElabCoerce result "CoeSort" none).mapError fun error =>
      if psElabErrorIsResource error then error else .infer .expectedSort
    let _ ← (psInferEnsureSort converted.context.environment converted.context.metaContext
      converted.context.localContext converted.type).mapError PsElabError.infer
    return converted

def psElabResolvedTerm
    (context : PsElabContext)
    (term : PsExpr)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psInferType
      context.environment
      context.metaContext
      context.localContext
      term with
  | Except.error error =>
      Except.error (PsElabError.infer error)
  | Except.ok type =>
      let result :=
        PsElabTermResult.mk
          context
          term
          type;
      psElabFinalizeExpected
        result
        expected

def psElabProjectionApplyParameters
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
        psElabProjectionApplyParameters context rest;
      fun (cursor : PsExpr) =>
        match
            psInferEnsureForall
              context.environment
              context.metaContext
              context.localContext
              cursor with
        | Except.error error =>
            Except.error (PsElabError.infer error)
        | Except.ok forallView =>
            smaller
              (psExprInstantiate1 forallView.body parameter)

def psElabFindStructureField
    (context : PsElabContext)
    (typeName : PsName)
    (target : PsExpr)
    (fieldName : String)
    (remaining : Nat) :
    Nat ->
    PsExpr ->
    Except PsElabError Nat :=
  match remaining with
  | 0 =>
      fun (_index : Nat) =>
        fun (_cursor : PsExpr) =>
          Except.error PsElabError.unsupportedTerm
  | nextRemaining + 1 =>
      fun (index : Nat) =>
        fun (cursor : PsExpr) =>
          let smaller : Nat -> PsExpr -> Except PsElabError Nat :=
            psElabFindStructureField
              context
              typeName
              target
              fieldName
              nextRemaining;
          match
              psInferEnsureForall
                context.environment
                context.metaContext
                context.localContext
                cursor with
          | Except.error error =>
              Except.error (PsElabError.infer error)
          | Except.ok forallView =>
              if
                  psStringEq
                    (psNameLastComponent forallView.name)
                    fieldName then
                Except.ok index
              else
                smaller
                  (Nat.succ index)
                  (psExprInstantiate1
                    forallView.body
                    (PsExpr.proj typeName index target))

def psElabProjectionStep
    (context : PsElabContext)
    (current : PsElabTermResult)
    (fieldName : String) :
    Except PsElabError PsElabTermResult :=
  let reducedType :=
    psWhnf
      context.environment
      current.context.metaContext
      current.context.localContext
      current.type;
  let view := psInferAppView reducedType;
  match view.head with
  | .constE typeName levels =>
      match psEnvironmentFindInductive current.context.environment typeName with
      | none => Except.error PsElabError.unsupportedTerm
      | some info =>
          let projectionInvalid :=
            if info.isStructure then
              if Nat.beq info.numIndices 0 then
                if Nat.beq (psElabListLength view.args) info.numParams then
                  false
                else
                  true
              else
                true
            else
              true;
          if projectionInvalid then
            Except.error PsElabError.unsupportedTerm
          else
            match info.constructors with
            | List.nil =>
                Except.error PsElabError.unsupportedTerm
            | List.cons constructorName remainingConstructors =>
                match remainingConstructors with
                | List.nil =>
                    match
                        psEnvironmentFindConstructor
                          current.context.environment
                          constructorName with
                    | none => Except.error PsElabError.unsupportedTerm
                    | some constructorInfo =>
                        match
                            psElabProjectionApplyParameters
                              current.context
                              view.args
                              (psExprInstantiateLevelParams constructorInfo.levelParams levels constructorInfo.type) with
                        | Except.error error => Except.error error
                        | Except.ok fieldCursor =>
                            match
                                psElabFindStructureField
                                  current.context
                                  typeName
                                  current.term
                                  fieldName
                                  constructorInfo.numFields
                                  0
                                  fieldCursor with
                            | Except.error error => Except.error error
                            | Except.ok index =>
                                psElabResolvedTerm
                                  current.context
                                  (PsExpr.proj
                                    typeName
                                    index
                                    current.term)
                                  Option.none
                | List.cons _ _ =>
                    Except.error PsElabError.unsupportedTerm
  | _ => Except.error PsElabError.unsupportedTerm

def psElabProjectionChainWorker
    (fields : List String) :
    PsElabContext ->
    PsElabTermResult ->
    Except PsElabError PsElabTermResult :=
  match fields with
  | [] =>
      fun (_context : PsElabContext) =>
        fun (current : PsElabTermResult) =>
          Except.ok current
  | field :: rest =>
      let smaller :
          PsElabContext -> PsElabTermResult -> Except PsElabError PsElabTermResult :=
        psElabProjectionChainWorker rest;
      fun (context : PsElabContext) =>
        fun (current : PsElabTermResult) =>
          match psElabProjectionStep context current field with
          | Except.error error => Except.error error
          | Except.ok projected =>
              smaller projected.context projected

def psElabProjectionChain
    (context : PsElabContext)
    (current : PsElabTermResult)
    (fields : List String) :
    Except PsElabError PsElabTermResult :=
  psElabProjectionChainWorker fields context current

-- Resolve only the base of a projection. The recursive descent considers
-- longer proper local prefixes first; the final segment always remains a field.
def psElabLocalProjectionBaseWorker
    (localContext : PsLocalContext)
    (fields : List String) :
    PsName -> Option (Prod PsResolvedName (List String)) :=
  match fields with
  | List.nil =>
      fun (_base : PsName) => Option.none
  | List.cons field rest =>
      let smaller : PsName -> Option (Prod PsResolvedName (List String)) :=
        psElabLocalProjectionBaseWorker localContext rest;
      fun (base : PsName) =>
        match smaller (psNameAppendStr base field) with
        | Option.some selected => Option.some selected
        | Option.none =>
            match psLocalFindUser localContext base with
            | Option.none => Option.none
            | Option.some declaration =>
                Option.some (Prod.mk
                  (PsResolvedName.local (psLocalDeclId declaration))
                  (List.cons field rest))

-- Share name selection between elaboration and hygienic recursion rewriting.
-- Exact complete names precede the established first-segment projection base.
-- Only an absent first segment permits a longer LOCAL base; a selected base
-- never falls back to another name after a field or type error.
def psElabReferencePrefix (fuel : Nat) (localContext : PsLocalContext)
    (environment : PsEnvironment) (rooted : Bool) (namePrefix suffix : List String) :
    Option (Prod PsResolvedName (List String)) :=
  match fuel, namePrefix with
  | 0, _ => none
  | _, [] => none
  | fuel + 1, _ =>
    let name := psSyntaxNameAppendSegments namePrefix .anonymous
    let resolved := if rooted then
      (psEnvironmentFind environment name).map (fun _ => PsResolvedName.global name)
      else psResolveName localContext environment name
    match resolved with
    | some value => some (value, suffix)
    | none =>
      match namePrefix.getLast? with
      | none => none
      | some last => psElabReferencePrefix fuel localContext environment rooted
          namePrefix.dropLast (last :: suffix)

def psElabResolveReferenceBase (localContext : PsLocalContext)
    (environment : PsEnvironment) (sourceName : PsSyntaxName) :
    Option (Prod PsResolvedName (List String)) :=
  let rooted := sourceName.segments.head? == some "_root_"
  let segments := psSyntaxNameRootSegments sourceName.segments
  psElabReferencePrefix (segments.length + 1) localContext environment rooted segments []

-- Global constants instantiate declared universe parameters at every use.
-- Keep the fresh constraints in the ordinary elaboration context so arguments
-- and expected types solve them through the same unifier as expression holes.
def psElabResolvedReference (context : PsElabContext) (resolved : PsResolvedName) :
    Except PsElabError (PsElabContext × PsExpr) := do
  match resolved with
  | .local id => return (context, .fvar id)
  | .global name =>
    let some declaration := psEnvironmentFind context.environment name | throw (.unknownName name)
    let (constraints, levelsRev) := (psDeclarationLevelParams declaration).foldl
      (fun (state : PsMetaContext × List PsLevel) _ =>
        let fresh := psMetaFreshLevel state.fst
        (fresh.context, fresh.level :: state.snd)) (context.metaContext, [])
    return (psElabContextWithMeta context constraints, .constE name levelsRev.reverse)

def psElabProjectionReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabResolveReferenceBase
      context.localContext context.environment sourceName with
  | Option.none =>
      match sourceName.segments with
      | List.nil => Except.error PsElabError.emptyName
      | List.cons first _ =>
          Except.error
            (PsElabError.unknownName (psNameAppendStr PsName.anonymous first))
  | Option.some selected => do
      let (context, baseTerm) ← psElabResolvedReference context selected.fst
      let result ← if selected.snd.isEmpty then psElabResolvedTerm context baseTerm expected
        else do
          let base ← psElabResolvedTerm context baseTerm none
          let projected ← psElabProjectionChain context base selected.snd
          psElabFinalizeExpected projected expected
      return { result with
        context := psElabRecordInfo result.context
          (.reference sourceName selected.fst selected.snd result.term result.type) }

def psElabNamedReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabProjectionReference context sourceName expected

def psElabReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psSyntaxNameRootSegments sourceName.segments with
  | List.nil =>
      psElabNamedReference context sourceName expected
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          if psStringEq segment "Prop" then
            psElabResolvedTerm
              context
              (PsExpr.sortE PsLevel.zero)
              expected
          else if psStringEq segment "Type" then
            psElabResolvedTerm
              context
              (PsExpr.sortE (PsLevel.succ PsLevel.zero))
              expected
          else
            psElabNamedReference context sourceName expected
      | List.cons _ _ =>
          psElabNamedReference context sourceName expected

-- Pinned Lean BuiltinTerm.elabNumLit/elabScientificLit share a fresh Type,
-- expected-type unification and one synthetic class goal. Raw parameters must
-- never be elaborated as source numerals (a local OfNat may change them).
-- Apache-2.0, Microsoft Corporation, Leonardo de Moura.
def psElabNumericLiteral (context : PsElabContext) (family method : String)
    (indices arguments : List PsExpr) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let level := psMetaFreshLevel context.metaContext
  let target := psMetaFresh level.context context.localContext (.sortE (.succ level.level)) .natural
  let context := psElabContextWithMeta context target.context
  let context ← match expected with
    | none => pure context
    | some type =>
      let unified := psUnify context.environment context.localContext context.metaContext target.expr type
      if unified.resourceExceeded then throw .fuelExhausted
      if !unified.success then throw .typeMismatch
      pure (psElabContextWithMeta context unified.context)
  let goal ← psElabApplyCore context
    (.constE (psRootName family) [level.level]) (target.expr :: indices)
  let dictionary := psMetaFresh goal.context.metaContext goal.context.localContext goal.term .synthetic
  let .mvar id := dictionary.expr | throw .implicitApplicationUnsupported
  let result : PsElabTermResult := {
    context := psElabRecordInfo (psElabContextWithMeta goal.context dictionary.context)
      (.instanceSelection context.sourceSpan goal.term dictionary.expr)
    term := psExprApplyMany (.constE (psNameAppendStr (psRootName family) method) [level.level])
      (target.expr :: (indices ++ [dictionary.expr] ++ arguments))
    type := target.expr }
  let result ← psElabSolveSynthetic result [.instanceGoal id]
  psElabFinalizeExpected result expected

def psElabNatural (context : PsElabContext) (text : String) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let some value := psParseNaturalText text | throw (.invalidNatural text)
  psElabNumericLiteral context "OfNat" "ofNat" [.lit (.natural value)] [] expected

def psElabScientific (context : PsElabContext) (text : String) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let some (mantissa, negative, exponent) := psParseScientificText text
    | throw (.invalidArgument ("invalid scientific literal: " ++ text))
  let sign := PsExpr.constE (psNameAppendStr (psRootName "Bool")
    (if negative then "true" else "false")) []
  psElabNumericLiteral context "OfScientific" "ofScientific" []
    [.lit (.natural mantissa), sign, .lit (.natural exponent)] expected

def psElabString
    (context : PsElabContext)
    (text : String)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psDecodeStringLiteral text with
  | none => Except.error (PsElabError.invalidString text)
  | some value =>
      psElabResolvedTerm
        context
        (PsExpr.lit (PsLiteral.string value))
        expected

def psElabCharacter
    (context : PsElabContext)
    (text : String)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psDecodeCharacterLiteral text with
  | none => Except.error (PsElabError.invalidCharacter text)
  | some value =>
      let term :=
        PsExpr.app
          (PsExpr.constE psCharOfNatName [])
          (PsExpr.lit (PsLiteral.natural (Char.toNat value)));
      psElabResolvedTerm context term expected

def psElabUnit
    (context : PsElabContext)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabResolvedTerm
    context
    (PsExpr.constE psUnitUnitName [])
    expected

def psElabBool
    (context : PsElabContext)
    (value : Bool)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  if value then
    psElabResolvedTerm
      context
      (PsExpr.constE psBoolTrueName [])
      expected
  else
    psElabResolvedTerm
      context
      (PsExpr.constE psBoolFalseName [])
      expected

-- Shared bidirectional operations. Holes remain ordinary scoped metavariables;
-- declaration completion rejects every unresolved term or universe metavariable.
abbrev PsElaborator :=
  PsElabContext → PsSyntaxTerm → Option PsExpr → Except PsElabError PsElabTermResult

structure PsElabTypeResult where
  context : PsElabContext
  type : PsExpr

def psElabFreshType (context : PsElabContext) : PsElabTypeResult :=
  let level := psMetaFreshLevel context.metaContext
  let fresh := psMetaFresh level.context context.localContext (.sortE level.level) .natural
  { context := psElabContextWithMeta context fresh.context, type := fresh.expr }

def psElabHole (context : PsElabContext) (expected : Option PsExpr) : PsElabTermResult :=
  let target := match expected with
    | some type => PsElabTypeResult.mk context type
    | none => psElabFreshType context
  let fresh := psMetaFresh target.context.metaContext target.context.localContext target.type .natural
  { context := psElabContextWithMeta target.context fresh.context
    term := fresh.expr
    type := target.type }

def psElabOptionalType (elaborate : PsElaborator) (context : PsElabContext)
    (type value : PsSyntaxTerm) : Except PsElabError PsElabTypeResult := do
  let annotation ← elaborate context type none >>= psElabEnsureType
  let level ← (psInferEnsureSort annotation.context.environment annotation.context.metaContext
    annotation.context.localContext annotation.type).mapError PsElabError.infer
  let value ← elaborate annotation.context value (some annotation.term)
  return {
    context := value.context
    type := .app (.app (.constE psOptParamName [level]) annotation.term) value.term }

def psElabType (elaborate : PsElaborator) (context : PsElabContext)
    (source : PsSyntaxTerm) : Except PsElabError PsElabTypeResult := do
  match source with
  | .hole _ => return psElabFreshType context
  | .optionalType type value _ => psElabOptionalType elaborate context type value
  | _ =>
    let result ← elaborate context source none >>= psElabEnsureType
    let _ ← (psInferEnsureSort result.context.environment result.context.metaContext
      result.context.localContext result.type).mapError PsElabError.infer
    return { context := result.context, type := result.term }

def psElabAscription (elaborate : PsElaborator) (context : PsElabContext)
    (value type : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let annotation ← psElabType elaborate context type
  let result ← elaborate annotation.context value (some annotation.type)
  psElabFinalizeExpected result expected


def psElabExpressionSort (context : PsElabContext) (type : PsExpr) :
    Except PsElabError PsLevel := do
  let sort ← (psInferType context.environment context.metaContext context.localContext type).mapError PsElabError.infer
  (psInferEnsureSort context.environment context.metaContext context.localContext sort).mapError PsElabError.infer

