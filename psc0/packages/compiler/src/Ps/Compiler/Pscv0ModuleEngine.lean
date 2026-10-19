import Ps.Compiler.Pscv0Engine
import Ps.Syntax.ParseCommon

-- A project consists of named, in-memory v7.2 sources. The graph is
-- discovered before elaboration: imports are never ignored or converted into
-- concatenation. This portable layer performs no filesystem/host IO.
structure PsPscv0ModuleSource where
  name : String
  source : String
  sourceKind : PsCompilerSourceKind := .proofScript
  -- Optional real source path (normalized, project-relative). The native
  -- compiler never reads it; the host uses it for provenance and source maps.
  sourceName : String := ""

structure PsPscv0ParsedModule where
  name : String
  sourceKind : PsCompilerSourceKind
  source : String
  sourceName : String
  program : PsSyntaxProgram

-- Module identities use a canonical source spelling of structural components.
-- A dot inside an escaped component is never a module path separator.
def psPscv0ModuleKey (segments : List String) : String :=
  String.intercalate "." (segments.map fun part =>
    psLexIdentifierSpelling part (psLexReservedIdentifier part))

def psPscv0ImportKey (entry : PsSyntaxImport) : String :=
  psPscv0ModuleKey (psSyntaxNameRootSegments entry.moduleName.segments)

def psPscv0ValidModuleKey (name : String) : Bool :=
  match psLex name with
  | .error _ => false
  | .ok tokens =>
    match psParseSyntaxNameWith true { remaining := tokens } with
    | .error _ => false
    | .ok parsed =>
      let segments := psSyntaxNameRootSegments parsed.value.segments
      !segments.isEmpty && psTokenCursorDone parsed.cursor &&
        psPscv0ModuleKey segments == name

def psPscv0ProjectParse (sources : List PsPscv0ModuleSource) :
    Except String (List PsPscv0ParsedModule) := do
  if sources.length > 256 then throw "PSCV0-MODULE: project source count budget"
  if (sources.map (·.name)).eraseDups.length != sources.length then
    throw "PSCV0-MODULE: duplicate module identity"
  let names := sources.map (·.name)
  let fileNames := sources.map fun item =>
    if item.sourceName.isEmpty then item.name ++ psCompilerSourceKindExtension item.sourceKind else item.sourceName
  if fileNames.eraseDups.length != sources.length then
    throw "PSCV0-MODULE: duplicate source path identity"
  for entry in sources do
    if !psPscv0ValidModuleKey entry.name then
      throw ("PSCV0-MODULE: invalid module identity " ++ entry.name)
  let parsed : List PsPscv0ParsedModule ← sources.mapM fun input => do
    let program ← psCompilerParsePscv0Program input.sourceKind input.source
    let dependencies := program.imports.map psPscv0ImportKey
    if dependencies.length != dependencies.eraseDups.length then
      throw ("PSCV0-MODULE: duplicate import in " ++ input.name)
    for dep in dependencies do
      if !names.contains dep then
        throw ("PSCV0-MODULE: missing module " ++ dep ++ " imported by " ++ input.name)
    return {
      name := input.name, source := input.source, sourceKind := input.sourceKind
      sourceName := if input.sourceName.isEmpty then input.name ++ psCompilerSourceKindExtension input.sourceKind else input.sourceName
      program }
  -- Pinned Lean rejects module-mode imports of legacy non-module files.
  -- Validate the actual parsed graph, including import-only clients, before
  -- declaration elaboration; the source extension alone cannot supply this bit.
  for client in parsed do
    if client.program.isModule then
      for entry in client.program.imports do
        let dependency := psPscv0ImportKey entry
        let some provider := parsed.find? (fun item => item.name == dependency)
          | throw ("PSCV0-MODULE: missing module " ++ dependency ++ " imported by " ++ client.name)
        if !provider.program.isModule then
          throw ("PSCV0-MODULE-KIND: module " ++ client.name ++
            " cannot import non-module " ++ dependency)
  return parsed

-- Topological planning over the complete explicit graph. A cycle is an error,
-- not an opportunity to infer mutually recursive cross-file declarations.
def psPscv0ProjectOrder : Nat → List PsPscv0ParsedModule →
    List PsPscv0ParsedModule → Except String (List PsPscv0ParsedModule)
  | 0, [], doneRev => .ok doneRev.reverse
  | 0, _ :: _, _ => .error "PSCV0-MODULE: graph budget"
  | fuel + 1, pending, doneRev =>
    if pending.isEmpty then .ok doneRev.reverse
    else
      match pending.find? (fun candidate =>
        candidate.program.imports.all (fun imp =>
          doneRev.any (fun item => item.name == psPscv0ImportKey imp))) with
      | none => .error "PSCV0-MODULE: circular import dependency"
      | some ready =>
        psPscv0ProjectOrder fuel
          (pending.filter (fun item => item.name != ready.name))
          (ready :: doneRev)

-- Keep global manifest validation, but compile and link only the transitive
-- dependency closure of the chosen executable entry. Otherwise unrelated
-- source declarations could collide or enter a checked runtime graph.
def psPscv0ProjectReachable (fuel : Nat) (modules : List PsPscv0ParsedModule)
    (pending visited : List String) : Except String (List String) := do
  match fuel with
  | 0 => throw "PSCV0-MODULE: reachability budget"
  | fuel + 1 =>
    match pending with
    | [] => return visited
    | current :: rest =>
      if visited.contains current then
        psPscv0ProjectReachable fuel modules rest visited
      else
        let some selected := modules.find? (fun entry => entry.name == current)
          | throw ("PSCV0-MODULE: missing dependency " ++ current)
        let imports := selected.program.imports.map psPscv0ImportKey
        psPscv0ProjectReachable fuel modules (imports ++ rest) (current :: visited)

-- Import views carry declaration identities and elaboration metadata. Module
-- clients receive the public view, where ordinary definitions are opaque.
-- Legacy clients retain the original declaration kinds and implementation
-- closure; this does not export the provider's source-level private aliases.
structure PsPscv0ModuleInterface where
  declarations : List PsDeclaration := []
  classes : List PsName := []
  classParameters : List (PsName × PsClassParameters) := []
  instances : List PsInstanceEntry := []
  defaults : List PsInstanceEntry := []
  simpEntries : List PsSimpEntry := []
  reducibility : List (PsName × PsReducibility) := []
  noncomputableNames : List PsName := []
  sourceEquations : List PsSourceEquations := []
  extTheorems : List PsName := []

def psPscv0ImportedDeclaration (exposed : List PsName) : PsDeclaration → PsDeclaration
  | .definitionDecl name levels type value =>
    if exposed.any (psNameEq name) then .definitionDecl name levels type value
    else .opaqueDecl name levels type value
  | declaration => declaration

def psPscv0SameInstanceIdentity (left right : PsInstanceEntry) : Bool :=
  match left.value, right.value with
  | .constE a _, .constE b _ => psNameEq a b
  | _, _ => false

def psPscv0MergeInstanceEntries (left right : List PsInstanceEntry) : List PsInstanceEntry :=
  right.foldl (fun acc item =>
    if acc.any (psPscv0SameInstanceIdentity item) then acc else acc ++ [item]) left

def psPscv0InterfaceMerge (left right : PsPscv0ModuleInterface) :
    PsPscv0ModuleInterface :=
  let declarations := right.declarations.foldl (fun acc decl =>
    if acc.any (fun entry => psNameEq (psDeclarationName entry) (psDeclarationName decl))
    then acc else acc ++ [decl]) left.declarations
  let classes := right.classes.foldl (fun acc name =>
    if acc.any (psNameEq name) then acc else acc ++ [name]) left.classes
  let classParameters := right.classParameters.foldl (fun acc item =>
    if acc.any (fun entry => psNameEq entry.fst item.fst) then acc else acc ++ [item])
    left.classParameters
  let instances := psPscv0MergeInstanceEntries left.instances right.instances
  let defaults := psPscv0MergeInstanceEntries left.defaults right.defaults
  let simpEntries := psSimpEntriesMerge left.simpEntries right.simpEntries
  let sourceEquations := psSourceEquationsMerge left.sourceEquations right.sourceEquations
  let extTheorems := right.extTheorems.foldl (fun names name =>
    if names.any (psNameEq name) then names else names ++ [name]) left.extTheorems
  let reducibility := right.reducibility.foldl (fun acc item =>
    if acc.any (fun prior => psNameEq prior.fst item.fst) then acc else acc ++ [item])
    left.reducibility
  let noncomputableNames := right.noncomputableNames.foldl (fun names name =>
    if names.any (psNameEq name) then names else names ++ [name]) left.noncomputableNames
  { declarations, classes, classParameters, instances, defaults, simpEntries,
    reducibility, noncomputableNames, sourceEquations, extTheorems }

-- Metadata follows the selected original elaboration declarations, before
-- preparation or runtime lowering. This shared constructor preserves their
-- kinds; the module-style public owner applies opacity separately.
def psPscv0DeclarationInterface (environment : PsEnvironment)
    (declarations : List PsDeclaration) : PsPscv0ModuleInterface :=
  let names := declarations.map psDeclarationName
  let owned := fun name => names.any (psNameEq name)
  let classes := environment.classes.filter owned
  let classParameters := environment.classParameters.filter (fun item => owned item.fst)
  let visible := fun (item : PsInstanceEntry) =>
    match item.value with
    | .constE name _ => owned name
    | _ => false
  let instances := environment.instances.entries.filter visible
  let defaults := environment.instances.defaults.filter visible
  let simpEntries := environment.simpEntries.filter (fun entry => owned entry.name)
  let sourceEquations := environment.sourceEquations.filter fun entry =>
    owned entry.owner && entry.equations.all owned &&
      entry.unfolding?.all owned
  let extTheorems := environment.extTheorems.filter owned
  { declarations, classes, classParameters, instances, defaults, simpEntries,
    sourceEquations, extTheorems,
    reducibility := names.map (fun name => (name, psEnvironmentReducibility environment name))
    noncomputableNames := names.filter (psEnvironmentIsNoncomputable environment) }

-- Public identity is selected from source-command ownership, rather than from
-- the final runtime IR (which also contains private and generated workers).
def psPscv0OwnInterface (environment : PsEnvironment)
    (own : List PsDeclaration) (hidden exposed : List PsName) :
    PsPscv0ModuleInterface :=
  let publicDecls := own.filter (fun decl =>
    !hidden.any (psNameEq (psDeclarationName decl)))
  psPscv0DeclarationInterface environment
    (publicDecls.map (psPscv0ImportedDeclaration exposed))

-- The same instance may reach a client through two import paths.
-- Register it exactly once, without changing the relative instance priorities.
def psPscv0InstallInterface (environment : PsEnvironment)
    (view : PsPscv0ModuleInterface) : Except String PsEnvironment := do
  let environment ← view.declarations.foldlM (fun env decl => do
    -- A public-import diamond may present the same checked identity through
    -- two paths. Global project declaration uniqueness is checked separately.
    if psEnvironmentContains env (psDeclarationName decl) then
      return env
    let some next := psEnvironmentAdd env decl
      | throw "PSCV0-MODULE: failed to load imported declaration"
    pure next) environment
  let classes := view.classes.foldl (fun acc name =>
    if acc.any (psNameEq name) then acc else name :: acc) environment.classes
  let classParameters := view.classParameters.foldl (fun acc item =>
    if acc.any (fun existing => psNameEq existing.fst item.fst) then acc
    else item :: acc) environment.classParameters
  -- Exported lists are already newest-first at each priority. Reverse replay
  -- preserves their tie order, including public-import diamonds.
  let instances := view.instances.reverse.foldl (fun index entry =>
    if index.entries.any (psPscv0SameInstanceIdentity entry) then index
    else psInstanceIndexAdd index entry) environment.instances
  let instances := view.defaults.reverse.foldl (fun index entry =>
    if index.defaults.any (psPscv0SameInstanceIdentity entry) then index
    else psInstanceIndexAddDefault index entry) instances
  let environment := view.reducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  let environment := view.noncomputableNames.foldl psEnvironmentMarkNoncomputable environment
  let simpEntries := view.simpEntries.reverse.foldl (fun entries entry =>
    if entries.any (fun prior => psNameEq prior.name entry.name) then entries
    else psSimpEntriesAdd entries entry) environment.simpEntries
  let environment := { environment with classes, classParameters, instances, simpEntries }
  let environment ← psEnvironmentAddSourceEquations environment view.sourceEquations
  psEnvironmentAddExtTheorems environment view.extTheorems

def psPscv0ExprConstants : PsExpr → List PsName
  | .constE name _ => [name]
  | .app fn arg => psPscv0ExprConstants fn ++ psPscv0ExprConstants arg
  | .lam _ type body _ | .forallE _ type body _ =>
      psPscv0ExprConstants type ++ psPscv0ExprConstants body
  | .letE _ type value body =>
      psPscv0ExprConstants type ++ psPscv0ExprConstants value ++
        psPscv0ExprConstants body
  | .proj typeName _ value => typeName :: psPscv0ExprConstants value
  | _ => []

def psPscv0GeneratedPrivateNames (origins : List PsElabBatchOrigin) : List PsName :=
  origins.flatMap fun origin =>
    origin.members.filterMap fun member =>
      match member.role with
      | .normalizedWorker => some member.name
      | _ => none

structure PsPscv0BuiltModule where
  name : String
  interface : PsPscv0ModuleInterface
  legacyInterface : PsPscv0ModuleInterface
  ownNames : List PsName
  inspectionDeclarations : List PsInspectionDeclaration := []

structure PsPscv0ProjectOrigin where
  moduleName : String
  sourceName : String
  source : String
  batches : List PsElabBatchOrigin
  parents : List (PsName × PsName)
  commandDiagnostics : List PsDiagnostic := []

-- Retain the actual import/export decision at its owner. This receipt is
-- descriptive metadata; admission and runtime semantics remain separate.
structure PsPscv0ModuleProfile where
  name : String
  sourceName : String
  source : String
  imports : List (String × Bool)
  ownNames : List PsName
  privateNames : List PsName
  exposedNames : List PsName
  interface : PsPscv0ModuleInterface

structure PsPscv0ProjectOutput where
  prepared : PsCompilerAdmissionReadyModule
  admissions : String
  mainNames : List PsName
  libraryNames : List PsName
  origins : List PsPscv0ProjectOrigin
  moduleProfiles : List PsPscv0ModuleProfile
  -- No imported source is promoted to proof authority. The external official
  -- Lean kernel still checks the complete canonical dependency closure.

-- The generic project retains the original caller context after linking every
-- reachable source declaration. Module-local preparation uses its installed
-- import view; that view never replaces the final project's base environment.
-- This is an internally produced compiler result, not a checked-profile token.
structure PsCompilerEngineProjectOutput where
  prepared : PsCompilerEnginePrepared
  admissions : String
  mainNames : List PsName
  libraryNames : List PsName
  origins : List PsPscv0ProjectOrigin
  moduleProfiles : List PsPscv0ModuleProfile

-- Module clients see their declared imports through public interfaces. Legacy
-- clients load each declared dependency's complete transitive elaboration view.
-- Both routes retain the same explicit graph and final checked declaration set.
def psCompilerEnginePreparePscv0Project (profile : PsCompilerProfileContext)
    (entryName : String) (sources : List PsPscv0ModuleSource) :
    Except String PsCompilerEngineProjectOutput := do
  let parsed ← psPscv0ProjectParse sources
  if !parsed.any (fun item => item.name == entryName) then
    throw ("PSCV0-MODULE: unknown entry " ++ entryName)
  let budget := parsed.foldl (fun total item => total + item.program.imports.length + 1) 1
  let reachable ← psPscv0ProjectReachable budget parsed [entryName] []
  let active := parsed.filter (fun item => reachable.contains item.name)
  let order ← psPscv0ProjectOrder (active.length + 1) active []
  let mut built : List PsPscv0BuiltModule := []
  let mut declarations : List PsDeclaration := []
  let mut recursorWorkerGroups : List PsRecursorWorkerGroup := []
  let mut noncomputableNames : List PsName := []
  let mut globalNames : List PsName := []
  let mut origins : List PsPscv0ProjectOrigin := []
  let mut mainNames : List PsName := []
  let mut moduleProfiles : List PsPscv0ModuleProfile := []
  for item in order do
    let importEnvironment ← item.program.imports.foldlM (fun env imp => do
      let some linked := built.find? (fun module =>
        module.name == psPscv0ImportKey imp)
        | throw "PSCV0-MODULE: unresolved topological dependency"
      let installed ← psPscv0InstallInterface env
        (if item.program.isModule then linked.interface else linked.legacyInterface)
      psInspectionAttach installed linked.inspectionDeclarations)
      profile.baseEnvironment
    let program := { item.program with imports := [] }
    let elaborated ← (psElabProgramWithOrigins importEnvironment program item.name).mapError
      psCompilerPscv0ElabError
    let moduleProfile : PsCompilerProfileContext :=
      { profile with baseEnvironment := importEnvironment }
    let moduleElaborated : PsCompilerEngineElaborated := {
      environment := elaborated.result.environment
      declarations := elaborated.result.declarations
      profile := moduleProfile
      commandDiagnostics := elaborated.result.commandDiagnostics }
    let output ← (psCompilerEnginePrepareElaboratedWithOutput moduleElaborated).mapError
      psCompilerPscv0Error
    let own := output.prepared.declarations
    for decl in own do
      if globalNames.any (psNameEq (psDeclarationName decl)) then
        throw ("PSCV0-MODULE: duplicate project declaration " ++
          psNameToString (psDeclarationName decl))
      globalNames := psDeclarationName decl :: globalNames
    let ownNames := own.map psDeclarationName
    let hidden := elaborated.privateNames ++
      psPscv0GeneratedPrivateNames elaborated.origins
    let ownPublic := psPscv0OwnInterface elaborated.result.environment
      elaborated.result.declarations hidden elaborated.exposedNames
    let mut interface := ownPublic
    let mut legacyInterface := psPscv0DeclarationInterface
      elaborated.result.environment elaborated.result.declarations
    for imp in item.program.imports do
      let some linked := built.find? (fun module =>
        module.name == psPscv0ImportKey imp)
        | throw "PSCV0-MODULE: missing interface dependency"
      -- Private import edges and mangled implementation declarations belong to
      -- the legacy closure too. Local source aliases never enter this view.
      legacyInterface := psPscv0InterfaceMerge legacyInterface linked.legacyInterface
      if imp.isPublic then
        interface := psPscv0InterfaceMerge interface linked.interface
    -- The exported view is also the availability boundary for public types
    -- and exposed definitions. A public-import path can make a declaration
    -- available even when another direct import of its provider is private.
    let publicNames := interface.declarations.map psDeclarationName
    let publiclyAvailable := fun name =>
      psEnvironmentContains profile.baseEnvironment name ||
        publicNames.any (psNameEq name)
    for decl in ownPublic.declarations do
      let typeDependencies := psPscv0ExprConstants (psDeclarationType decl)
      if item.program.isModule && typeDependencies.any
          (fun dependency => hidden.any (psNameEq dependency)) then
        throw ("PSCV0-MODULE: public signature references private name in " ++
          psNameToString (psDeclarationName decl))
      -- Native legacy roots do not restrict their exported environment.
      if item.program.isModule &&
          typeDependencies.any (fun dependency => !publiclyAvailable dependency) then
        throw ("PSCV0-MODULE: public signature references private import in " ++
          psNameToString (psDeclarationName decl))
      -- Imported ordinary definitions are opaque in ownPublic; theorem proofs
      -- are likewise absent from psDeclarationValue. Their private implementation
      -- dependencies are retained for checking, without becoming exposed bodies.
      if let some body := psDeclarationValue decl then
        let bodyDependencies := psPscv0ExprConstants body
        if item.program.isModule && bodyDependencies.any
            (fun dependency => hidden.any (psNameEq dependency)) then
          throw ("PSCV0-MODULE: exposed body references private name in " ++
            psNameToString (psDeclarationName decl))
        if item.program.isModule &&
            bodyDependencies.any (fun dependency => !publiclyAvailable dependency) then
          throw ("PSCV0-MODULE: exposed body references private import in " ++
            psNameToString (psDeclarationName decl))
    moduleProfiles := moduleProfiles ++ [{
      name := item.name, sourceName := item.sourceName, source := item.source
      imports := item.program.imports.map (fun imp => (psPscv0ImportKey imp, imp.isPublic))
      ownNames, privateNames := hidden, exposedNames := elaborated.exposedNames, interface }]
    let inspectionDeclarations ← psInspectionCapture elaborated.result.environment
      elaborated.result.declarations
    built := built ++ [{
      name := item.name, interface, legacyInterface, ownNames, inspectionDeclarations }]
    declarations := declarations ++ own
    recursorWorkerGroups := recursorWorkerGroups ++ output.prepared.recursorWorkerGroups
    noncomputableNames := noncomputableNames ++ output.prepared.noncomputableNames
    origins := origins ++ [{
      moduleName := item.name, sourceName := item.sourceName, source := item.source,
      batches := elaborated.origins, parents := output.originParents
      commandDiagnostics := elaborated.result.commandDiagnostics }]
    if item.name == entryName then
      mainNames := ownPublic.declarations.map psDeclarationName
  let prepared : PsCompilerEnginePrepared := {
    declarations, recursorWorkerGroups, noncomputableNames, profile }
  -- Source-level 'public import' is a transitive API view for importing
  -- modules, not an instruction to export dependency functions from the
  -- executable entry artifact. Link every dependency, expose entry names only.
  let libraryNames := globalNames.reverse.filter (fun name =>
    !mainNames.any (psNameEq name))
  let admissions ← (psCompilerEngineAdmissionsFromPrepared prepared).mapError psCompilerPscv0Error
  return { prepared, admissions, mainNames, libraryNames, origins, moduleProfiles }

