import Ps.Elab.Scope
import Ps.Elab.Class
import Ps.Environment.StandardInhabited

structure PsCommandState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration := []
  scope : PsCommandScope := {}
  frames : List PsScopeFrame := []
  namespaces : List (List String) := []
  originsRev : List PsElabBatchOrigin := []
  privateNames : List PsName := []
  exposedNames : List PsName := []
  moduleIdentity : String := ""
  privateAliases : List (List String × List String) := []

def psScopeDeclaration (resolver : PsScopeResolver) (source : PsSyntaxDeclaration) :
    Except PsElabError PsSyntaxDeclaration := do
  let sourceName := (psElabOriginSource source).fst
  let sourceQualified := psScopeQualified resolver.scope sourceName
  let resolved := (psScopePrivateRewrite resolver sourceQualified.segments).getD sourceQualified.segments
  let name := { sourceQualified with segments := resolved }
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
  | .structureDecl _ params result fields span =>
    let params ← psScopeBinders visit [] params
    let result ← result.mapM (visit params.bound)
    let fields ← psScopeBinders visit params.bound fields
    let used := psScopeUnion (result.map (·.used) |>.getD []) (psScopeUnion params.used fields.used)
    let captured := psScopeSelect resolver.scope used
    return .structureDecl name (captured ++ params.binders) (result.map (·.term)) fields.binders span
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
  let checked ← psElabTypedBinders psElabTerm (psElabContextEmpty state.environment (scope.levelNames.map psRootName))
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
    (registration : Option PsSyntaxRegistration) (isPrivate : Bool := false) :
    Except PsElabError PsCommandState := do
  let qualified := psScopeQualified state.scope (psElabOriginSource source).fst
  -- Only explicit project modules mangle private identities. Single-file
  -- elaboration retains its existing standalone naming contract.
  let aliases := if isPrivate && !state.moduleIdentity.isEmpty then
    (qualified.segments,
      ["$psc0Private"] ++ state.moduleIdentity.splitOn "." ++ qualified.segments)
      :: state.privateAliases
    else state.privateAliases
  let source ← psScopeDeclaration {
    environment := state.environment, scope := state.scope,
    privateAliases := aliases } source
  let some name := psSyntaxNameToName (psElabOriginSource source).fst | throw .emptyName
  let originBatch ← (psElabDeclarationBatchWithOrigins state.environment
    state.originsRev.length source (state.scope.levelNames.map psRootName)).mapError
      (fun error => PsElabError.atDeclaration name error.error)
  let batch ← match registration with
    | some .opaqueDecl =>
      -- Preserve actual kernel opacity, rather than a display-only declaration tag.
      match originBatch.result.declarations with
      | [.definitionDecl declarationName levels type value] =>
        pure { originBatch.result with
          declarations := [.opaqueDecl declarationName levels type value] }
      | _ => throw (.data "opaque requires one checked definition; normalized workers pending")
    | _ => pure originBatch.result
  let isClass := match registration with | some .classDecl => true | _ => false
  let isAbbrev := match registration with | some .abbrevDecl => true | _ => false
  let batch ← (psElabAddStructureProjections state.environment isClass batch).mapError
    (.atDeclaration name)
  let environment ← (psAddDeclarationList state.environment batch.declarations).mapError
    (.atDeclaration name)
  let environment ← (match registration with
    | none => pure environment
    | some .abbrevDecl | some .opaqueDecl => pure environment
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
    originsRev := { originBatch.origin with
      members := originBatch.origin.members ++
        psElabStableMemberOrigins (batch.declarations.drop originBatch.result.declarations.length)
          originBatch.result.declarations.length } :: state.originsRev
    declarationsRev := psPrependBatchReverse batch.declarations state.declarationsRev
    privateNames := if isPrivate then
      batch.declarations.map psDeclarationName ++ state.privateNames
    else state.privateNames
    exposedNames := if isAbbrev then
      batch.declarations.map psDeclarationName ++ state.exposedNames
    else state.exposedNames
    privateAliases := aliases }

-- The first bounded deriving handler generates an ordinary checked
-- instance from a non-dependent fieldless constructor. It never admits
-- arbitrary elaborator extensions or fabricated typeclass inhabitants.
-- Compute a default for each constructor field from the registered,
-- checked Inhabited dictionaries. Instantiating the remaining telescope
-- after every field also supports field types dependent on earlier defaults.
-- Source params/indices are handled separately, so this worker has neither.
def psElabDeriveInhabitedConstructor (environment : PsEnvironment)
    (family : PsExpr) (constructor : PsConstructorInfo) :
    Except PsElabError PsExpr := do
  if constructor.numParams != 0 || !constructor.levelParams.isEmpty then
    throw (.data "deriving constructor has unsupported family parameters")
  let mut cursor := constructor.type
  let mut value := PsExpr.constE constructor.name []
  for _ in [:constructor.numFields] do
    let .forallE _ domain body _ :=
      psWhnf environment psMetaEmpty psLocalEmpty cursor
      | throw (.data "deriving constructor field telescope is incomplete")
    let inferred ← (psInferType environment psMetaEmpty psLocalEmpty domain).mapError
      PsElabError.infer
    let .sortE level := psWhnf environment psMetaEmpty psLocalEmpty inferred
      | throw (.data "deriving field must be a type")
    let target := .app (.constE (psRootName "Inhabited") [level]) domain
    let candidate := psSynthInstance environment psLocalEmpty environment.instances
      psMetaEmpty target
    let some dictionary := candidate.value
      | throw (.data "deriving constructor field has no Inhabited instance")
    let dictionary := psMetaInstantiate candidate.context dictionary
    if psExprHasUnresolvedMeta dictionary then
      throw (.data "deriving constructor field leaves unresolved typeclass parameters")
    let defaultValue := psStandardInhabitedDefault level domain dictionary
    cursor := psExprInstantiate1 body defaultValue
    value := .app value defaultValue
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty cursor family then
    throw (.data "derived constructor does not produce the expected family")
  return value

def psElabDeriveInhabited (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "deriving requires an inductive/structure declaration")
  let some (.inductiveDecl info) := psEnvironmentFind environment member.name
    | throw (.data "derived family is not an inductive")
  if info.numParams != 0 || info.numIndices != 0 || !info.levelParams.isEmpty then
    throw (.data "bounded Inhabited deriving requires a closed non-indexed family")
  let .sortE level := info.type
    | throw (.data "bounded Inhabited deriving requires a Type 0 family")
  if !psLevelEquivalent level (.succ .zero) then
    throw (.data "bounded Inhabited deriving requires a Type 0 family")
  let family := PsExpr.constE info.name []
  let name := psNameAppendStr info.name "instInhabited"
  for constructorName in info.constructors do
    let some constructor := psEnvironmentFindConstructor environment constructorName
      | throw (.data "deriving constructor is missing")
    match psElabDeriveInhabitedConstructor environment family constructor with
    | .ok defaultValue =>
      return .definitionDecl name [] (psStandardInhabitedType family)
        (psStandardInhabitedValue family defaultValue)
    | .error _ => pure ()
  throw (.data "Inhabited deriving requires a constructor with inhabitable fields")

-- Checked finite-enumeration Boolean equality, lowered through the
-- generated inductive recursor without new runtime primitives.
-- This initial selected handler refuses parameterized or payload cases.
def psElabDeriveEnumBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "deriving BEq requires a data declaration")
  let some (.inductiveDecl info) := psEnvironmentFind environment member.name
    | throw (.data "deriving BEq family missing")
  if info.numParams != 0 || info.numIndices != 0 ||
      !info.levelParams.isEmpty || info.constructors.isEmpty then
    throw (.data "bounded BEq deriving requires a closed finite enumeration")
  let .sortE level := info.type
    | throw (.data "BEq deriving requires a Type 0 enumeration")
  if !psLevelEquivalent level (.succ .zero) then
    throw (.data "BEq deriving requires a Type 0 enumeration")
  for constructorName in info.constructors do
    let some constructor := psEnvironmentFindConstructor environment constructorName
      | throw (.data "BEq deriving constructor missing")
    if constructor.numParams != 0 || constructor.numFields != 0 ||
        !constructor.levelParams.isEmpty then
      throw (.data "bounded BEq deriving requires fieldless constructors")
  let family := PsExpr.constE info.name []
  let bool := PsExpr.constE psBoolName []
  let recursor := PsExpr.constE (psNameAppendStr info.name "rec") [.succ .zero]
  let rightMotive := psLogicLam 6 "_" family bool
  let outerMotive := psLogicLam 7 "_" family
    (psLogicPi 8 "right" family bool)
  let outerBranches := (info.constructors.zipIdx).map fun (_, leftIndex) =>
    let compareRight := (info.constructors.zipIdx).map fun (_, rightIndex) =>
      if leftIndex == rightIndex then PsExpr.constE psBoolTrueName []
      else PsExpr.constE psBoolFalseName []
    psLogicLam 5 "right" family
      (psLogicApply recursor ([rightMotive] ++ compareRight ++ [.fvar 5]))
  let outer := psLogicApply recursor
    ([outerMotive] ++ outerBranches ++ [.fvar 0])
  let method := psLogicLam 0 "left" family
    (psLogicLam 1 "right" family (.app outer (.fvar 1)))
  let className := psRootName "BEq"
  let dictionaryType := PsExpr.app (.constE className [.zero]) family
  let value := psLogicApply (.constE (psNameAppendStr className "mk") [.zero])
    [family, method]
  return .definitionDecl (psNameAppendStr info.name "instBEq") []
    dictionaryType value

def psElabDeriveHandler (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) (handler : PsSyntaxName) :
    Except PsElabError PsDeclaration :=
  match handler.segments with
  | ["Inhabited"] => psElabDeriveInhabited environment origin
  | ["BEq"] => psElabDeriveEnumBEq environment origin
  | _ => .error (.data "deriving handler is selected but not yet implemented")

def psElabCommandDeriving (state : PsCommandState) (source : PsSyntaxDeclaration)
    (handlers : List PsSyntaxName) (isPrivate : Bool) :
    Except PsElabError PsCommandState := do
  let next ← psElabCommandDeclaration state source none isPrivate
  let origin :: previous := next.originsRev
    | throw (.data "deriving lost source provenance")
  -- Preserve handler source order. Generated definitions are inserted through
  -- the same checked environment and registered like explicit instances.
  let (environment, declarationsRev, members, privateNames) ← handlers.foldlM
    (fun (acc : PsEnvironment × List PsDeclaration ×
        List PsElabMemberOrigin × List PsName) handler => do
      let (env, declarations, derivedMembers, privateNames) := acc
      let generated ← psElabDeriveHandler env origin handler
      let name := psDeclarationName generated
      let some added := psEnvironmentAdd env generated
        | throw (.duplicateDeclaration name)
      let updated ← psElabRegisterInstance added name 1000
      let member : PsElabMemberOrigin := {
        index := origin.members.length + derivedMembers.length
        name
        role := .derivedInstance }
      return (updated, generated :: declarations,
        derivedMembers ++ [member],
        if isPrivate then name :: privateNames else privateNames))
    (next.environment, next.declarationsRev,
      ([] : List PsElabMemberOrigin), next.privateNames)
  return { next with
    environment
    declarationsRev
    originsRev := { origin with members := origin.members ++ members } :: previous
    privateNames }


def psElabCommand (state : PsCommandState) (command : PsSyntaxCommand) :
    Except PsElabError PsCommandState := do
  match command with
  | .universeCmd names _ =>
    let levelNames ← names.foldlM (fun levels name => do
      let [key] := name.segments | throw (.scope "universe requires an unqualified name")
      if key == "_" || levels.contains key then
        throw (.scope ("duplicate or invalid universe " ++ key))
      return levels ++ [key]) state.scope.levelNames
    return { state with scope := { state.scope with levelNames } }
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
  | .privateDeclaration source => psElabCommandDeclaration state source none true
  | .privateRegisteredDeclaration source registration =>
    psElabCommandDeclaration state source (some registration) true
  | .derivingDeclaration source handlers isPrivate =>
    psElabCommandDeriving state source handlers isPrivate

def psElabProgramWithOrigins (environment : PsEnvironment) (program : PsSyntaxProgram)
    (moduleIdentity : String := "") :
    Except PsElabError PsElabModuleWithOriginsResult := do
  if !program.imports.isEmpty then throw (.scope "module imports are not available in this entry point")
  let namespaces := environment.declarations.foldl (fun acc decl =>
    ((psScopeNamePrefixes (psDeclarationName decl)).drop 1).foldl psScopeRemember acc) []
  let state ← program.commands.foldlM psElabCommand {
    environment, namespaces, moduleIdentity }
  if !state.frames.isEmpty then throw (.scope "unclosed namespace or section")
  return {
    result := { environment := state.environment, declarations := state.declarationsRev.reverse }
    origins := state.originsRev.reverse
    privateNames := state.privateNames
    exposedNames := state.exposedNames }

def psElabProgram (environment : PsEnvironment) (program : PsSyntaxProgram) :
    Except PsElabError PsElabModuleResult :=
  (psElabProgramWithOrigins environment program).map (·.result)
