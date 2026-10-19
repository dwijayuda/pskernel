import Ps.Elab.ExposedProofs
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
  isModule : Bool := false
  privateAliases : List (List String × List String) := []

def psScopeDeclaration (resolver : PsScopeResolver) (source : PsSyntaxDeclaration)
    (exposedBody : Bool := false) :
    Except PsElabError PsSyntaxDeclaration := do
  let sourceName := (psElabOriginSource source).fst
  let sourceQualified := psScopeQualified resolver.scope sourceName
  let resolved := (psScopePrivateRewrite resolver sourceQualified.segments).getD sourceQualified.segments
  let name := psScopeCanonicalNameSyntax { sourceQualified with segments := resolved }
  let resolver := { resolver with selfName := some resolved }
  let visit := psScopeTerm 4096 resolver
  let bodyResolver := { resolver with
    abstractProofs := resolver.abstractProofs && exposedBody }
  let bodyVisit := psScopeTerm 4096 bodyResolver
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
    let value ← bodyVisit binders.bound value
    let termination ← match source with
      | .wellFoundedDefinition _ _ _ _ suffix _ => do
        let measure ← bodyVisit binders.bound suffix.measure
        let proof ← suffix.decreasing.mapM (bodyVisit binders.bound)
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
      else psScopeTerm 4096 { bodyResolver with selfArguments } binders.bound value.term
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


-- Registration is applied to the complete checked declaration batch. The
-- inferred and explicit-header routes use this same metadata owner.
def psElabCommandMayExposeProofs : Option PsSyntaxRegistration → Bool
  | some .abbrevDecl | some (.instanceDecl _)
  | some (.defaultInstanceDecl _ (some _)) => true
  | _ => false

def psElabCommandRegisterDeclaration (environment : PsEnvironment)
    (name : PsName) (registration : Option PsSyntaxRegistration) :
    Except PsElabError PsEnvironment :=
  match registration with
  | none | some .opaqueDecl => pure environment
  | some .abbrevDecl => pure (psEnvironmentSetReducibility environment name .reducible)
  | some .classDecl => psElabRegisterClass environment name
  | some (.instanceDecl priority) => psElabRegisterInstance environment name priority
  | some (.defaultInstanceDecl priority ordinaryPriority) => do
    let environment ← match ordinaryPriority with
      | some ordinary => psElabRegisterInstance environment name ordinary
      | none => pure environment
    psElabRegisterDefaultInstance environment name priority

-- Pinned MutualDef.finishElab exposes abbreviation and data-instance bodies.
-- A default attribute on an ordinary def does not change its declaration kind;
-- proof-valued instances also keep the ordinary non-exposed body boundary.
def psElabCommandExposesDefinition (environment : PsEnvironment)
    (name : PsName) (registration : Option PsSyntaxRegistration) :
    Except PsElabError Bool := do
  if let some .abbrevDecl := registration then return true
  let instanceDeclaration := match registration with
    | some (.instanceDecl _) => true
    | some (.defaultInstanceDecl _ (some _)) => true
    | _ => false
  if !instanceDeclaration then return false
  let some declaration := psEnvironmentFind environment name
    | throw (.data "registered declaration missing at body-exposure boundary")
  let context := psElabContextEmpty environment (psDeclarationLevelParams declaration)
  let level ← psElabExpressionSort context (psDeclarationType declaration)
  return !psLevelEquivalent level .zero

-- Scope one original source block, elaborate its typed local captures, then
-- let the checked dependency owner partition it. Helpers retain their own
-- source information while their declarations belong to the parent's origin.
def psElabCommandPreDefinitions (state : PsCommandState)
    (members : List PsSyntaxMutualMember) (span : PsSourceSpan) (isMutual : Bool) :
    Except PsElabError PsCommandState := do
  if members.isEmpty then throw (.data "PSCV0-MUTUAL-EMPTY: mutual requires def/function members")
  let qualified := members.map fun member =>
    psScopeQualified state.scope (psElabOriginSource member.declaration).fst
  let names := qualified.map (·.segments)
  for sourceName in qualified do
    if (names.filter (· == sourceName.segments)).length != 1 then
      let some name := psSyntaxNameToName (psScopeCanonicalNameSyntax sourceName) | throw .emptyName
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
  let privateAuxiliaryPrefix :=
    if state.isModule && !state.moduleIdentity.isEmpty then
      ["$psc0Private"] ++ state.moduleIdentity.splitOn "."
    else []
  let scopedMembers ← (members.zip peerAliases).mapM fun (member, alias) =>
    psScopePreDefinition
      { resolver with abstractProofs := state.isModule && !member.isPrivate } member
      (PsSyntaxName.mk alias.snd (psElabOriginSource member.declaration).snd)
      inheritedPartial privateAuxiliaryPrefix
  -- Pinned definition bodies see the complete checked section telescope.
  -- Hints cannot enable a local dictionary by contributing source-name keys.
  -- Where's typed capture closure retains only actual type/body dependencies.
  let sectionContext := state.scope.variables.map (·.binder)
  let prepared ← psElabPreparePreDefinitionsWithSource state.environment
    (state.scope.levelNames.map psRootName) sectionContext scopedMembers span
  let block := prepared.block
  let result ← psElabPreDefinitionBatch state.environment block
    (some (psElabWhereWellFoundedComponent prepared))
  if result.members.length != block.members.length then
    throw (.data "PSCV0-PREDEFINITION-OWNERSHIP: checked member provenance mismatch")
  let environment ← psAddDeclarationList state.environment result.batch.declarations
  let environment := if members.any (fun member =>
      psElabPreDefinitionDeclarationNoncomputable member.declaration) then
    result.batch.declarations.foldl (fun env declaration =>
      psEnvironmentMarkNoncomputable env (psDeclarationName declaration)) environment
  else environment
  let outputs := block.members.zip result.members
  let (environment, exposedOwners) ← outputs.foldlM
    (fun (acc : PsEnvironment × List Nat) (member, _) => do
      let registered ← (psElabCommandRegisterDeclaration acc.fst member.name
        member.registration).mapError (.atDeclaration member.name)
      let exposed ← (psElabCommandExposesDefinition registered member.name
        member.registration).mapError (.atDeclaration member.name)
      return (registered, if exposed then member.sourceIndex :: acc.snd else acc.snd))
    (environment, [])
  let exposedNames := outputs.flatMap fun (member, result) =>
    if exposedOwners.contains member.sourceIndex then
      result.declarations.filterMap fun declaration =>
        match declaration with
        | .definitionDecl name .. => some name
        | _ => none
    else []
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
  -- Exposed value owners retain their checked computational dependencies.
  -- Source-private members remain private; generated equations and operational
  -- markers retain their existing local ownership.
  let privateNames := outputs.flatMap fun (member, result) =>
    result.declarations.filterMap fun declaration =>
      let name := psDeclarationName declaration
      let exposed := exposedNames.any (psNameEq name)
      if member.isPrivate || (!psNameEq name member.name && !exposed) then some name else none
  let namespaces := result.batch.declarations.foldl (fun acc declaration =>
    ((psScopeNamePrefixes (psDeclarationName declaration)).drop 1).foldl psScopeRemember acc)
    state.namespaces
  -- Helpers of an ordinary module definition have private checked identities.
  -- Their source aliases remain usable by later commands in this provider only.
  let privateAliases := (qualified.zip scopedMembers).foldl
    (fun (aliases : List (List String × List String)) (sourceName, member) =>
      member.locals.foldl (fun aliases localDefinition =>
        if localDefinition.isPrivate then
          (sourceName.segments ++ localDefinition.source.name.segments,
            (psNameToString localDefinition.name).splitOn ".") :: aliases
        else aliases) aliases) aliases
  return { state with
    environment, namespaces
    originsRev := origins.reverse ++ state.originsRev
    declarationsRev := psPrependBatchReverse result.batch.declarations state.declarationsRev
    privateNames := privateNames ++ state.privateNames
    exposedNames := exposedNames ++ state.exposedNames
    privateAliases }

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
    -- Ordinary bodies must also see section instances whose dependency keys
    -- occur only in a candidate dictionary type. Typed closure prunes captures.
    -- Explicit registrations and theorem include/omit keep their existing owner.
    | .definition .. => registration.isNone && !state.scope.variables.isEmpty
    | .wellFoundedDefinition .. | .fixedpointDefinition .. => registration.isNone
    | _ => false
  if usePreDefinitions then
    return ← psElabCommandPreDefinitions state
      [PsSyntaxMutualMember.mk source isPrivate registration] (psElabOriginSource source).snd false
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
    privateAliases := aliases
    abstractProofs := state.isModule && !isPrivate } source
      (psElabCommandMayExposeProofs registration)
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
  -- The source instance kind follows the actual checked result sort. A
  -- default attribute on an ordinary definition does not make it a theorem.
  let instanceDeclaration := match registration with
    | some (.instanceDecl _) => true
    | some (.defaultInstanceDecl _ (some _)) => true
    | _ => false
  let batch ← if instanceDeclaration then do
    match batch.declarations with
    | [.definitionDecl declarationName levels type value] =>
      let level ← (psElabExpressionSort
        (psElabContextEmpty state.environment levels) type).mapError
          (.atDeclaration name)
      if psLevelEquivalent level .zero then
        pure { batch with declarations :=
          [.theoremDecl declarationName levels type value] }
      else pure batch
    | _ => throw (.data "instance requires one checked value declaration")
  else pure batch
  let isClass := match registration with | some .classDecl => true | _ => false
  let batch ← (psElabAddStructureProjections state.environment isClass batch).mapError
    (.atDeclaration name)
  let environment ← (psAddDeclarationList state.environment batch.declarations).mapError
    (.atDeclaration name)
  let environment ← (psElabCommandRegisterDeclaration environment name registration).mapError
    (.atDeclaration name)
  let exposesValue ← (psElabCommandExposesDefinition environment name registration).mapError
    (.atDeclaration name)
  let projectionNames := (batch.declarations.drop originBatch.result.declarations.length).map
    psDeclarationName
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
    exposedNames := projectionNames ++
      (if exposesValue then batch.declarations.map psDeclarationName else []) ++
      state.exposedNames
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
      let some name := psSyntaxNameToName (psScopeCanonicalNameSyntax sourceName) | throw .emptyName
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
    psScopeMutualMember
      { resolver with abstractProofs := state.isModule && !entry.fst.isPrivate } entry.fst
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
    if name.segments.isEmpty then throw .emptyName
    return name.segments.foldl (fun (state : PsCommandState) component =>
      let namePrefix := state.scope.namePrefix ++ [component]
      { state with
        frames := { label := some [component], saved := state.scope } :: state.frames
        scope := { state.scope with namePrefix }
        namespaces := psScopeRemember state.namespaces namePrefix }) state
  | .sectionCmd name _ =>
    match name with
    | none =>
      return { state with
        frames := { label := none, saved := state.scope } :: state.frames }
    | some name =>
      if name.segments.isEmpty then throw .emptyName
      return name.segments.foldl (fun (state : PsCommandState) component =>
        { state with
          frames := { label := some [component], saved := state.scope } :: state.frames }) state
  | .endCmd name _ =>
    let frame :: rest := state.frames | throw (.scope "end without an open scope")
    match name with
    | none =>
      if frame.label.isSome then
        throw (.scope "end requires the innermost scope name")
      return { state with scope := frame.saved, frames := rest }
    | some name =>
      if name.segments.isEmpty then throw .emptyName
      if name.segments.length > state.frames.length then
        throw (.scope "end name contains too many components")
      name.segments.reverse.foldlM (fun (state : PsCommandState) component => do
        let frame :: rest := state.frames | throw (.scope "end without an open scope")
        if frame.label != some [component] then
          throw (.scope "end name does not match the innermost scope")
        return { state with scope := frame.saved, frames := rest }) state
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
    environment, namespaces, moduleIdentity, isModule := program.isModule }
  -- Pinned Lean closes remaining namespace/section scopes at end of file.
  -- Only declarations and their metadata leave this program owner; scope frames
  -- and local resolution settings cannot escape into the next module.
  let result : PsElabModuleWithOriginsResult := {
    result := { environment := state.environment, declarations := state.declarationsRev.reverse }
    origins := state.originsRev.reverse
    privateNames := state.privateNames
    exposedNames := state.exposedNames }
  if program.isModule then psElabAbstractExposedProofs environment result
  else pure result

def psElabProgram (environment : PsEnvironment) (program : PsSyntaxProgram) :
    Except PsElabError PsElabModuleResult :=
  (psElabProgramWithOrigins environment program).map (·.result)

