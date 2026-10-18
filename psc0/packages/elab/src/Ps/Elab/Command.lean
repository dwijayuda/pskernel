import Ps.Elab.Scope
import Ps.Elab.Deriving
import Ps.Elab.Mutual
import Ps.Elab.MutualStructural
import Ps.Elab.WhereMutualWellFounded
import Ps.Elab.PreDefinition

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
  | .noncomputableDefinition .. =>
    throw (.data "PSCV0-NONCOMPUTABLE-BATCH: noncomputable policy requires typed command-batch elaboration")
  | .whereDeclaration .. =>
    throw (.scope "PSCV0-WHERE-BATCH: local definitions require typed command-batch scope")
  | .definition _ binders type value span
  | .partialDefinition _ binders type value span
  | .fixedpointDefinition _ binders type value span
  | .wellFoundedDefinition _ binders type value _ span
  | .theoremDecl _ binders type value span =>
    let isTheorem := match source with | .theoremDecl _ _ _ _ _ => true | _ => false
    let isPartial := match source with | .partialDefinition _ _ _ _ _ => true | _ => false
    let isFixedpoint := match source with | .fixedpointDefinition _ _ _ _ _ => true | _ => false
    let binders ← psScopeBinders visit [] binders
    let type ← visit binders.bound type
    let value ← visit binders.bound value
    let termination ← match source with
      | .wellFoundedDefinition _ _ _ _ suffix _ => do
        let measure ← visit binders.bound suffix.measure
        let proof ← suffix.decreasing.mapM (visit binders.bound)
        let retained := { suffix with measure := measure.term, decreasing := proof.map (·.term) }
        let used := psScopeUnion measure.used (proof.map (·.used) |>.getD [])
        pure (some (retained, used))
      | _ => pure none
    let header := psScopeUnion binders.used type.used
    let used := if isTheorem then psScopeUnion header resolver.scope.included
      else psScopeUnion header (psScopeUnion value.used (termination.map Prod.snd |>.getD []))
    let captured := psScopeSelect resolver.scope used
    if isTheorem && !value.used.all (fun key => captured.any (fun b => (psScopeBinderKeys b.fst).contains key)) then
      throw (.scope "theorem proof uses a section variable absent from its header; use include")
    if isTheorem then
      return .theoremDecl name (captured ++ binders.binders) type.term value.term span
    -- Recursive section parameters are fixed in the source scope. Add them at
    -- the syntax boundary before either recursion strategy is elaborated.
    let selfArguments := (captured.filter fun binder =>
      match binder.fst.kind with | .explicit => true | _ => false).flatMap
        (fun binder => (psSyntaxBinderNames binder.fst).map PsSyntaxTerm.reference)
    let value ←
      if selfArguments.isEmpty then pure value
      else psScopeTerm 4096 { resolver with selfArguments } binders.bound value.term
    if isPartial then
      return .partialDefinition name (captured ++ binders.binders) type.term value.term span
    if isFixedpoint then
      return .fixedpointDefinition name (captured ++ binders.binders) type.term value.term span
    if let some (suffix, _) := termination then
      return .wellFoundedDefinition name (captured ++ binders.binders) type.term value.term suffix span
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
    let names := psSyntaxBinderNames entry.fst
    (names.zipIdx).foldlM (fun scope (name, index) => do
      let key := psScopeKey name
      if name.segments.length != 1 || key == "_" then
        throw (.scope "section variable requires a name")
      if psScopeHasVariable scope key then
        throw (.scope ("duplicate active section variable " ++ key))
      -- Resolve and register each annotation in the preceding names' scope.
      -- Delaying publication until the whole group hides native shadowing.
      let resolved ← psScopeTerm 4096 { environment := state.environment, scope } [] entry.snd
      let head := { entry.fst with name, moreNames := [], origin := some { names, index } }
      let scopedEntry := PsScopeVariable.mk (head, resolved.term) resolved.used
      pure { scope with variables := scope.variables ++ [scopedEntry] }) scope) state.scope
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


-- Scope one original source block, elaborate its typed local captures, then
-- let the checked dependency owner partition it. Helpers retain their own
-- source information while their declarations belong to the parent's origin.
def psElabCommandPreDefinitionRegistration
    (members : List PsSyntaxMutualMember) (isMutual : Bool) :
    Option PsSyntaxRegistration :=
  if isMutual then none else
    match members with
    | [member] =>
      match member.declaration, member.registration with
      | .definition _ _ (.omittedType _) _ _, _ => none
      | .definition .., some .abbrevDecl => some .abbrevDecl
      | .definition .., some .opaqueDecl => some .opaqueDecl
      | .definition .., some (.instanceDecl priority) => some (.instanceDecl priority)
      | .definition .., some (.defaultInstanceDecl priority ordinaryPriority) =>
        some (.defaultInstanceDecl priority ordinaryPriority)
      | _, _ => none
    | _ => none

def psElabCommandPreDefinitions (state : PsCommandState)
    (members : List PsSyntaxMutualMember) (span : PsSourceSpan) (isMutual : Bool)
    (nonrecursiveEquations : Bool := true) : Except PsElabError PsCommandState := do
  if members.isEmpty then throw (.data "PSCV0-MUTUAL-EMPTY: mutual requires def/function members")
  let registration := psElabCommandPreDefinitionRegistration members isMutual
  let qualified := members.map fun member =>
    psScopeQualified state.scope (psElabOriginSource member.declaration).fst
  let names := qualified.map (·.segments)
  for sourceName in qualified do
    if (names.filter (· == sourceName.segments)).length != 1 then
      let some name := psSyntaxNameToName sourceName | throw .emptyName
      throw (.duplicateDeclaration name)
  let aliases := (members.zip qualified).foldl (fun aliases entry =>
    if entry.fst.isPrivate && !state.moduleIdentity.isEmpty then
      (entry.snd.segments,
        ["$psc0Private"] ++ state.moduleIdentity.splitOn "." ++ entry.snd.segments) :: aliases
    else aliases) state.privateAliases
  let resolver : PsScopeResolver := {
    environment := state.environment
    scope := state.scope
    privateAliases := aliases }
  let names := qualified.map fun name =>
    (psScopePrivateRewrite resolver name.segments).getD name.segments
  let peerAliases := names.zipIdx.map fun (name, index) =>
    (name, ["$psc0Mutual", psNatToString index])
  let resolver := { resolver with mutualNames := names, mutualAliases := peerAliases }
  -- Validate every original main before inherited local intent can affect
  -- scope. Pinned Main ignores local hints in an all-partial block without
  -- elaborating their names; body/header names still use the normal resolver.
  let mainSources := members.map (fun member => PsElabPreDefinitionSource.declaration member.declaration)
  psElabPreDefinitionCheckMainModifiers mainSources
  let inheritedPartial := psElabPreDefinitionHasPartialMain mainSources
  let scopedMembers ← (members.zip peerAliases).mapM fun (member, alias) =>
    psScopePreDefinition resolver member
      (PsSyntaxName.mk alias.snd (psElabOriginSource member.declaration).snd)
      inheritedPartial
  -- Pinned definition bodies see the complete checked section telescope.
  -- Hints cannot enable a local dictionary by contributing source-name keys.
  -- Where's typed capture closure retains only actual type/body dependencies.
  let sectionContext := state.scope.variables.map (·.binder)
  let prepared ← psElabPreparePreDefinitionsWithSource state.environment
    (state.scope.levelNames.map psRootName) sectionContext scopedMembers span
  let block := prepared.block
  if registration.isSome && block.members.length != 1 then
    throw (.data "PSCV0-PREDEFINITION-REGISTRATION: registered source must retain one checked owner")
  let checkedBlock := if registration.isSome then
    { block with members := block.members.map fun member => { member with registration := none } }
    else block
  let result ← psElabPreDefinitionBatch state.environment checkedBlock
    (some (psElabWhereWellFoundedComponent prepared))
    (if registration.isSome then false else nonrecursiveEquations)
    registration.isNone
  if result.members.length != block.members.length then
    throw (.data "PSCV0-PREDEFINITION-OWNERSHIP: checked member provenance mismatch")
  let result ← match registration with
    | some .opaqueDecl =>
      match block.members, result.members, result.batch.declarations with
      | [member], [owned], [.definitionDecl name levels type value] => do
        if !psNameEq name member.name || owned.declarations.length != 1 then
          throw (.data "PSCV0-PREDEFINITION-REGISTRATION: opaque source lost its checked declaration owner")
        let declaration := PsDeclaration.opaqueDecl name levels type value
        pure { result with
          batch := { result.batch with declarations := [declaration] }
          members := [{ owned with declarations := [declaration] }] }
      | _, _, _ =>
        throw (.data "opaque requires one checked definition; normalized workers pending")
    | _ => pure result
  let environment ← psAddDeclarationList state.environment result.batch.declarations
  let environment := if members.any (fun member =>
      psElabPreDefinitionDeclarationNoncomputable member.declaration) then
    result.batch.declarations.foldl (fun env declaration =>
      psEnvironmentMarkNoncomputable env (psDeclarationName declaration)) environment
  else environment
  let environment ← match registration, block.members with
    | none, _ => pure environment
    | some registration, [member] =>
      (match registration with
        | .abbrevDecl => pure (psEnvironmentSetReducibility environment member.name .reducible)
        | .opaqueDecl => pure environment
        | .classDecl => psElabRegisterClass environment member.name
        | .instanceDecl priority => psElabRegisterInstance environment member.name priority
        | .defaultInstanceDecl priority ordinaryPriority => do
          let environment ← match ordinaryPriority with
            | some ordinary => psElabRegisterInstance environment member.name ordinary
            | none => pure environment
          psElabRegisterDefaultInstance environment member.name priority).mapError
            (.atDeclaration member.name)
    | _, _ =>
      throw (.data "PSCV0-PREDEFINITION-REGISTRATION: registration lost its single source owner")
  let outputs := block.members.zip result.members
  let origins := scopedMembers.zipIdx.map fun (member, index) =>
    let owned := outputs.filter (fun output => output.fst.sourceIndex == index)
    let declarations := owned.flatMap (·.snd.declarations)
    let origin := psElabBatchOriginAt (state.originsRev.length + index) member.source
      (psElabStableMemberOrigins declarations 0) none
    { origin with
      sourceInfo := owned.flatMap (·.snd.sourceInfo)
      diagnostics := owned.flatMap (·.snd.diagnostics)
      localDefinitions := owned.filterMap fun (input, result) =>
        match input.source with
        | .localDefinition _ source => some {
            name := input.name
            span := source.span
            declarations := result.declarations.map psDeclarationName }
        | .declaration _ => none
      mutualGroup := if isMutual then some {
        firstSourceIndex := state.originsRev.length
        memberIndex := index
        memberCount := scopedMembers.length
        span } else none }
  -- The outer source owner applies registration only after the checked batch
  -- is complete. Unregistered generated members retain their owned private
  -- visibility, as in pinned mkEqLikeNameFor.
  -- Use ownership rather than declaration kind or a generated-name suffix:
  -- an internal whole-function equation can also mention private callees.
  -- Explicit source theorem members keep their own source visibility.
  let privateNames := outputs.flatMap fun (member, result) =>
    result.declarations.filterMap fun declaration =>
      let name := psDeclarationName declaration
      if member.isPrivate || !psNameEq name member.name then some name else none
  let namespaces := result.batch.declarations.foldl (fun acc declaration =>
    ((psScopeNamePrefixes (psDeclarationName declaration)).drop 1).foldl psScopeRemember acc)
    state.namespaces
  return { state with
    environment, namespaces
    originsRev := origins.reverse ++ state.originsRev
    declarationsRev := psPrependBatchReverse result.batch.declarations state.declarationsRev
    exposedNames := match registration with
      | some .abbrevDecl => result.batch.declarations.map psDeclarationName ++ state.exposedNames
      | _ => state.exposedNames
    privateNames := privateNames ++ state.privateNames
    privateAliases := aliases }

def psElabCommandDeclaration (state : PsCommandState) (source : PsSyntaxDeclaration)
    (registration : Option PsSyntaxRegistration) (isPrivate : Bool := false) :
    Except PsElabError PsCommandState := do
  -- The typed dependency owner decides whether a retained recursion hint is
  -- used. A genuine nonrecursive definition never invokes WF or P1 admission.
  let usePreDefinitions := match source with
    | .whereDeclaration .. | .noncomputableDefinition .. => true
    | .definition _ _ (.omittedType _) _ _
    | .partialDefinition _ _ (.omittedType _) _ _
    | .wellFoundedDefinition _ _ (.omittedType _) _ _ _
    | .fixedpointDefinition _ _ (.omittedType _) _ _ => true
    -- Ordinary explicit definitions share the typed dependency/strategy owner.
    -- Section closure still retains only actual type and body dependencies.
    -- The outer singleton owner retains supported explicit registrations.
    -- Theorem include/omit keeps its existing source owner.
    | .definition .. => registration.isNone ||
      (psElabCommandPreDefinitionRegistration
        [PsSyntaxMutualMember.mk source isPrivate registration] false).isSome
    | .wellFoundedDefinition .. | .fixedpointDefinition .. => registration.isNone
    | _ => false
  if usePreDefinitions then
    let nonrecursiveEquations := match source with
      | .definition _ _ (.omittedType _) _ _ => true
      | .definition .. => !state.scope.variables.isEmpty
      | _ => true
    return ← psElabCommandPreDefinitions state
      [PsSyntaxMutualMember.mk source isPrivate registration] (psElabOriginSource source).snd false
      nonrecursiveEquations
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
  let originBatch ← match source with
    | .partialDefinition sourceName binders type value _ => do
      if registration.isSome then
        throw (.data "PSCV0-TERM-02-HEAD: partial cannot register a total declaration")
      let result ← (psElabPartialCommandBatch state.environment sourceName binders type value
        (state.scope.levelNames.map psRootName)).mapError (.atDeclaration name)
      let origin := psElabBatchOriginAt state.originsRev.length source
        (psElabStableMemberOrigins result.declarations 0) none
      pure ({ result, origin := { origin with sourceInfo := result.sourceInfo } } :
        PsElabDeclarationBatchWithOriginsResult)
    | _ =>
      (psElabDeclarationBatchWithOrigins state.environment
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
    | some .abbrevDecl => pure (psEnvironmentSetReducibility environment name .reducible)
    | some .opaqueDecl => pure environment
    | some .classDecl => psElabRegisterClass environment name
    | some (.instanceDecl priority) => psElabRegisterInstance environment name priority
    | some (.defaultInstanceDecl priority ordinaryPriority) => do
      let environment ← match ordinaryPriority with
        | some ordinary => psElabRegisterInstance environment name ordinary
        | none => pure environment
      psElabRegisterDefaultInstance environment name priority).mapError
      (.atDeclaration name)
  let namespaces := batch.declarations.foldl (fun acc decl =>
    -- A declaration registers its parent namespaces. Constructors and
    -- projections also register their inductive/structure namespace.
    ((psScopeNamePrefixes (psDeclarationName decl)).drop 1).foldl psScopeRemember acc) state.namespaces
  let implementationNames := batch.declarations.filterMap fun declaration =>
    match declaration with | .partialDecl name .. => some name | _ => none
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
    else implementationNames ++ state.privateNames
    exposedNames := if isAbbrev then
      batch.declarations.map psDeclarationName ++ state.exposedNames
    else state.exposedNames
    privateAliases := aliases }

-- A joint batch has one checked strategy. Ordinary members use the selected
-- direct structural construction; independently inhabited P0 members retain
-- their logical opaque/actual-body owner. Other strategies keep their refusal.
def psElabMutualStrategy (members : List PsSyntaxMutualMember) : Except PsElabError Unit := do
  if members.isEmpty then throw (.data "PSCV0-MUTUAL-EMPTY: mutual requires def/function members")
  if members.any (fun member => match member.declaration with
      | .fixedpointDefinition .. => true | _ => false) then
    throw (.data "PSCV0-FIXPOINT-BATCH: fixedpoint components require the typed predefinition owner")
  if members.any (fun member => match member.declaration with
      | .wellFoundedDefinition .. => true | _ => false) then
    throw (.data "PSCV0-MUTUAL-WF: mutual well-founded recursion requires a checked group construction; admission is unavailable")
  if members.all (fun member => match member.declaration with
      | .definition .. => true | _ => false) then
    if members.any (fun member => member.registration.isSome) then
      throw (.data "PSCV0-MUTUAL-TOTAL: REGISTRATION: selected structural mutual members cannot register additional declaration kinds")
    return ()
  if !members.all (fun member => match member.declaration with
      | .partialDefinition .. => true | _ => false) then
    throw (.data "PSCV0-MUTUAL-STRATEGY: selected mutual batch requires partial def/function members")
  if members.any (fun member => member.registration.isSome) then
    throw (.data "PSCV0-TERM-02-HEAD: partial cannot register a total declaration")

def psElabCommandPartialMutual (state : PsCommandState) (members : List PsSyntaxMutualMember)
    (span : PsSourceSpan) : Except PsElabError PsCommandState := do
  psElabMutualStrategy members
  let qualified := members.map fun member =>
    psScopeQualified state.scope (psElabOriginSource member.declaration).fst
  let names := qualified.map (·.segments)
  for sourceName in qualified do
    if (names.filter (· == sourceName.segments)).length != 1 then
      let some name := psSyntaxNameToName sourceName | throw .emptyName
      throw (.duplicateDeclaration name)
  let aliases := (members.zip qualified).foldl (fun aliases entry =>
    if entry.fst.isPrivate && !state.moduleIdentity.isEmpty then
      (entry.snd.segments,
        ["$psc0Private"] ++ state.moduleIdentity.splitOn "." ++ entry.snd.segments) :: aliases
    else aliases) state.privateAliases
  let resolver : PsScopeResolver := {
    environment := state.environment, scope := state.scope, privateAliases := aliases }
  let names := qualified.map fun sourceName =>
    (psScopePrivateRewrite resolver sourceName.segments).getD sourceName.segments
  let localAliases := (names.zipIdx).map fun entry =>
    (entry.fst, ["$psc0Mutual", psNatToString entry.snd])
  let resolver := { resolver with mutualNames := names, mutualAliases := localAliases }
  let scopedMembers ← (members.zip localAliases).mapM fun entry =>
    psScopeMutualMember resolver entry.fst
      (PsSyntaxName.mk entry.snd.snd (psElabOriginSource entry.fst.declaration).snd)
  -- Pinned MutualDef.collectUsed/removeUnusedVars closes section variables
  -- over every main header/body before SCC partition, including disconnected
  -- members. Keep this explicit result instead of guessing from AST arities.
  let used := scopedMembers.foldl (fun used member => psScopeUnion used member.used) []
  let captured := psScopeSelect state.scope used
  let result ← if members.all (fun member => match member.declaration with
      | .definition .. => true | _ => false) then
    psElabStructuralMutualBatch state.environment
      (state.scope.levelNames.map psRootName) captured scopedMembers
  else
    psElabPartialMutualBatch state.environment
      (state.scope.levelNames.map psRootName) captured scopedMembers
  if result.members.length != scopedMembers.length then
    throw (.data "PSCV0-MUTUAL-INTERNAL: checked member provenance mismatch")
  let environment ← psAddDeclarationList state.environment result.batch.declarations
  let origins := (scopedMembers.zip result.members).zipIdx.map fun entry =>
    let origin := psElabBatchOriginAt (state.originsRev.length + entry.snd)
      entry.fst.fst.source (psElabStableMemberOrigins entry.fst.snd.declarations 0) none
    { origin with
      sourceInfo := entry.fst.snd.sourceInfo
      mutualGroup := some {
        firstSourceIndex := state.originsRev.length
        memberIndex := entry.snd
        memberCount := scopedMembers.length
        span } }
  let privateNames := (scopedMembers.zip result.members).flatMap fun entry =>
    if entry.fst.isPrivate then entry.snd.declarations.map psDeclarationName
    else entry.snd.declarations.filterMap fun declaration =>
      match declaration with | .partialDecl name .. => some name | _ => none
  let namespaces := result.batch.declarations.foldl (fun acc declaration =>
    ((psScopeNamePrefixes (psDeclarationName declaration)).drop 1).foldl psScopeRemember acc)
    state.namespaces
  return { state with
    environment, namespaces
    originsRev := origins.reverse ++ state.originsRev
    declarationsRev := psPrependBatchReverse result.batch.declarations state.declarationsRev
    privateNames := privateNames ++ state.privateNames
    privateAliases := aliases }

def psElabCommandMutual (state : PsCommandState) (members : List PsSyntaxMutualMember)
    (span : PsSourceSpan) : Except PsElabError PsCommandState := do
  -- Preserve the established explicit-partial top-level route. The shared
  -- local preparation owns where blocks and total/mixed source components.
  if !members.isEmpty && members.all (fun member => match member.declaration with
      | .partialDefinition _ _ (.omittedType _) _ _ => false
      | .partialDefinition .. => true | _ => false) then
    psElabCommandPartialMutual state members span
  else psElabCommandPreDefinitions state members span true

-- Deriving owns Core generation in a shared parameter/universe telescope.
-- This command owns source order, registration and provenance for all handlers.
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
      let sourceName := (psSyntaxNameToName origin.sourceName).getD .anonymous
      let generated ← (psElabDeriveHandler env origin handler).mapError
        (.atDeclaration (psNameAppendStr sourceName ("deriving " ++ String.intercalate "." handler.segments)))
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
  | .mutualDeclarations members span => psElabCommandMutual state members span

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

