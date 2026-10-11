import Ps.Elab.Scope
import Ps.Elab.Class

structure PsCommandState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration := []
  scope : PsCommandScope := {}
  frames : List PsScopeFrame := []
  namespaces : List (List String) := []

def psScopeDeclaration (resolver : PsScopeResolver) (source : PsSyntaxDeclaration) :
    Except PsElabError PsSyntaxDeclaration := do
  let sourceName := (psElabOriginSource source).fst
  let name := psScopeQualified resolver.scope sourceName
  let resolver := { resolver with selfName := some name.segments }
  let visit := psScopeTerm 4096 resolver
  match source with
  | .definition _ binders type value span
  | .theoremDecl _ binders type value span =>
    let isTheorem := match source with | .theoremDecl _ _ _ _ _ => true | _ => false
    let binders ← psScopeBinders visit [] binders
    let type ← visit binders.bound type
    let value ← visit binders.bound value
    let header := psScopeUnion binders.used type.used
    let used := if isTheorem then psScopeUnion header resolver.scope.included
      else psScopeUnion header value.used
    let captured := psScopeSelect resolver.scope used
    if isTheorem && !value.used.all (fun key => captured.any (fun b => (psScopeBinderKeys b.fst).contains key)) then
      throw (.scope "theorem proof uses a section variable absent from its header; use include")
    if isTheorem then
      return .theoremDecl name (captured ++ binders.binders) type.term value.term span
    -- Recursive section parameters are fixed in the source scope. Add them at
    -- the syntax boundary before the existing structural-recursion algorithm.
    let selfArguments := (captured.filter fun binder =>
      match binder.fst.kind with | .explicit => true | _ => false).flatMap
        (fun binder => (psSyntaxBinderNames binder.fst).map PsSyntaxTerm.reference)
    let value ←
      if selfArguments.isEmpty then pure value
      else psScopeTerm 4096 { resolver with selfArguments } binders.bound value.term
    return .definition name (captured ++ binders.binders) type.term value.term span
  | .structureDecl _ params fields span =>
    let params ← psScopeBinders visit [] params
    let fields ← psScopeBinders visit params.bound fields
    let captured := psScopeSelect resolver.scope (psScopeUnion params.used fields.used)
    return .structureDecl name (captured ++ params.binders) fields.binders span
  | .inductiveDecl _ params result constructors span =>
    let params ← psScopeBinders visit [] params
    let result ← result.mapM (visit params.bound)
    let constructors ← constructors.mapM fun constructor => do
      let fields ← psScopeBinders visit params.bound constructor.fields
      let result ← constructor.resultType.mapM (visit fields.bound)
      return ({ constructor with fields := fields.binders, resultType := result.map (·.term) },
        psScopeUnion fields.used (result.map (·.used) |>.getD []))
    let used := constructors.foldl (fun acc c => psScopeUnion acc c.snd)
      (psScopeUnion params.used (result.map (·.used) |>.getD []))
    let captured := psScopeSelect resolver.scope used
    return .inductiveDecl name (captured ++ params.binders) (result.map (·.term))
      (constructors.map Prod.fst) span
  | .partialDefinition _ _ _ _ _ => throw .unsupportedTerm

def psScopeNamePrefixes (name : PsName) : List (List String) :=
  match name with
  | .anonymous => []
  | .str parent part =>
    let prefixes := psScopeNamePrefixes parent
    (match prefixes with | [] => [part] | first :: _ => first ++ [part]) :: prefixes
  | .num parent _ => psScopeNamePrefixes parent

def psScopeRemember (namespaces : List (List String)) (namePrefix : List String) :
    List (List String) :=
  (psScopePrefixes namePrefix).foldl (fun acc item =>
    if item.isEmpty || acc.contains item then acc else item :: acc) namespaces

def psScopeOpen (state : PsCommandState) (name : PsSyntaxName) :
    Except PsElabError (List String) := do
  let segments := psSyntaxNameRootSegments name.segments
  let candidates := if name.segments.head? == some "_root_" then [segments]
    else (psScopePrefixes state.scope.namePrefix).map (· ++ segments)
  let some found := candidates.find? state.namespaces.contains
    | throw (.scope ("unknown namespace " ++ psScopeKey name))
  return found

-- New variable groups are checked immediately against an ephemeral local
-- telescope. Store qualified syntax/dependencies, never a live local identity
-- that could escape a section or be reused by a later declaration.
def psScopeVariables (state : PsCommandState) (entries : List PsScopeBinder) :
    Except PsElabError PsCommandState := do
  let scope ← entries.foldlM (fun scope entry => do
    let _ ← (psSyntaxBinderNames entry.fst).foldlM (fun seen name => do
      let key := psScopeKey name
      if name.segments.length != 1 || key == "_" then
        throw (.scope "section variable requires a name")
      if psScopeHasVariable scope key || seen.contains key then
        throw (.scope ("duplicate active section variable " ++ key))
      pure (key :: seen)) ([] : List String)
    let resolved ← psScopeTerm 4096 { environment := state.environment, scope } [] entry.snd
    let entry := PsScopeVariable.mk (entry.fst, resolved.term) resolved.used
    return { scope with variables := scope.variables ++ [entry] }) state.scope
  let checked ← psElabTypedBinders psElabTerm (psElabContextEmpty state.environment)
    (scope.variables.map (·.binder))
  if checked.bindersRev.any (fun b =>
      psExprHasUnresolvedMeta (psMetaInstantiate checked.context.metaContext b.type)) then
    throw .unresolvedMetavariable
  return { state with scope }

def psScopeInclusion (state : PsCommandState) (names : List PsSyntaxName) (add : Bool) :
    Except PsElabError PsCommandState := do
  let included ← names.foldlM (fun included name => do
    let key := psScopeKey name
    if !psScopeHasVariable state.scope key then
      throw (.scope ("unknown section variable " ++ key))
    return if add then psScopeUnion included [key] else included.filter (· != key))
    state.scope.included
  return { state with scope := { state.scope with included } }

def psElabCommandDeclaration (state : PsCommandState) (source : PsSyntaxDeclaration)
    (registration : Option PsSyntaxRegistration) : Except PsElabError PsCommandState := do
  let source ← psScopeDeclaration { environment := state.environment, scope := state.scope } source
  let some name := psSyntaxNameToName (psElabOriginSource source).fst | throw .emptyName
  let batch ← (psElabDeclarationBatch state.environment source).mapError (.atDeclaration name)
  let isClass := match registration with | some .classDecl => true | _ => false
  let batch ← (psElabAddStructureProjections state.environment isClass batch).mapError
    (.atDeclaration name)
  let environment ← (psAddDeclarationList state.environment batch.declarations).mapError
    (.atDeclaration name)
  let environment ← (match registration with
    | none => pure environment
    | some .classDecl => psElabRegisterClass environment name
    | some (.instanceDecl priority) => psElabRegisterInstance environment name priority).mapError
      (.atDeclaration name)
  let namespaces := batch.declarations.foldl (fun acc decl =>
    -- A declaration registers its parent namespaces. Constructors and
    -- projections also register their inductive/structure namespace.
    ((psScopeNamePrefixes (psDeclarationName decl)).drop 1).foldl psScopeRemember acc) state.namespaces
  return { state with
    environment := environment
    namespaces := namespaces
    declarationsRev := psPrependBatchReverse batch.declarations state.declarationsRev }

def psElabCommand (state : PsCommandState) (command : PsSyntaxCommand) :
    Except PsElabError PsCommandState := do
  match command with
  | .namespaceCmd name _ =>
    let qualified := psScopeQualified state.scope name
    if qualified.segments.isEmpty then throw .emptyName
    return { state with
      frames := { label := some name.segments, saved := state.scope } :: state.frames
      scope := { state.scope with namePrefix := qualified.segments }
      namespaces := psScopeRemember state.namespaces qualified.segments }
  | .sectionCmd name _ =>
    return { state with
      frames := { label := name.map (·.segments), saved := state.scope } :: state.frames }
  | .endCmd name _ =>
    let frame :: rest := state.frames | throw (.scope "end without an open scope")
    if name.isSome && name.map (·.segments) != frame.label then
      throw (.scope "end name does not match the innermost scope")
    return { state with scope := frame.saved, frames := rest }
  | .openCmd names _ =>
    let opened ← names.mapM (psScopeOpen state)
    return { state with scope := { state.scope with opened := opened ++ state.scope.opened } }
  | .variableCmd binders _ => psScopeVariables state binders
  | .includeCmd names _ => psScopeInclusion state names true
  | .omitCmd names _ => psScopeInclusion state names false
  | .declaration source => psElabCommandDeclaration state source none
  | .registeredDeclaration source registration =>
    psElabCommandDeclaration state source (some registration)

def psElabProgram (environment : PsEnvironment) (program : PsSyntaxProgram) :
    Except PsElabError PsElabModuleResult := do
  if !program.imports.isEmpty then throw (.scope "module imports are not available in this entry point")
  let namespaces := environment.declarations.foldl (fun acc decl =>
    ((psScopeNamePrefixes (psDeclarationName decl)).drop 1).foldl psScopeRemember acc) []
  let state ← program.commands.foldlM psElabCommand { environment, namespaces }
  if !state.frames.isEmpty then throw (.scope "unclosed namespace or section")
  return { environment := state.environment, declarations := state.declarationsRev.reverse }
