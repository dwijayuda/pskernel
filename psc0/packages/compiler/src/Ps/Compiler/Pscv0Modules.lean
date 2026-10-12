import Ps.Compiler.Pscv0

-- A project consists of named, in-memory .ps sources. The graph is
-- discovered before elaboration: imports are never ignored or converted into
-- concatenation. This portable layer performs no filesystem/host IO.
structure PsPscv0ModuleSource where
  name : String
  source : String
  -- Optional real source path (normalized, project-relative). The native
  -- compiler never reads it; the host uses it for provenance and source maps.
  sourceName : String := ""

structure PsPscv0ParsedModule where
  name : String
  source : String
  sourceName : String
  program : PsSyntaxProgram

def psPscv0ImportKey (entry : PsSyntaxImport) : String :=
  String.intercalate "." (psSyntaxNameRootSegments entry.moduleName.segments)

def psPscv0ValidModuleKey (name : String) : Bool :=
  !name.isEmpty && (name.splitOn ".").all (fun segment => !segment.isEmpty)

def psPscv0ProjectParse (sources : List PsPscv0ModuleSource) :
    Except String (List PsPscv0ParsedModule) := do
  if sources.length > 256 then throw "PSCV0-MODULE: project source count budget"
  if (sources.map (·.name)).eraseDups.length != sources.length then
    throw "PSCV0-MODULE: duplicate module identity"
  let names := sources.map (·.name)
  let fileNames := sources.map fun item =>
    if item.sourceName.isEmpty then item.name ++ ".ps" else item.sourceName
  if fileNames.eraseDups.length != sources.length then
    throw "PSCV0-MODULE: duplicate source path identity"
  for entry in sources do
    if !psPscv0ValidModuleKey entry.name then
      throw ("PSCV0-MODULE: invalid module identity " ++ entry.name)
  sources.mapM fun input => do
    let program ← psPscv0ParseProgram input.source
    let dependencies := program.imports.map psPscv0ImportKey
    if dependencies.length != dependencies.eraseDups.length then
      throw ("PSCV0-MODULE: duplicate import in " ++ input.name)
    for dep in dependencies do
      if !names.contains dep then
        throw ("PSCV0-MODULE: missing module " ++ dep ++ " imported by " ++ input.name)
    return {
      name := input.name, source := input.source
      sourceName := if input.sourceName.isEmpty then input.name ++ ".ps" else input.sourceName
      program }

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

-- The imported view carries checked declaration identities and typeclass
-- registrations, but not definitional bodies. Ordinary public names are
-- externally opaque in Lean RC4 module-style semantics by default.
structure PsPscv0ModuleInterface where
  declarations : List PsDeclaration := []
  classes : List PsName := []
  classParameters : List (PsName × PsClassParameters) := []
  instances : List PsInstanceEntry := []

def psPscv0ImportedDeclaration (exposed : List PsName) : PsDeclaration → PsDeclaration
  | .definitionDecl name levels type value =>
    if exposed.any (psNameEq name) then .definitionDecl name levels type value
    else .opaqueDecl name levels type value
  | declaration => declaration

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
  let instances := right.instances.foldl (fun acc item =>
    if acc.any (fun entry => match entry.value, item.value with
      | .constE left _, .constE right _ => psNameEq left right
      | _, _ => false) then acc else acc ++ [item])
    left.instances
  { declarations, classes, classParameters, instances }

-- Public identity is selected from source-command ownership, rather than from
-- the final runtime IR (which also contains private and generated workers).
def psPscv0OwnInterface (environment : PsEnvironment)
    (own : List PsDeclaration) (hidden exposed : List PsName) :
    PsPscv0ModuleInterface :=
  let publicDecls := own.filter (fun decl =>
    !hidden.any (psNameEq (psDeclarationName decl)))
  let names := publicDecls.map psDeclarationName
  let owned := fun name => names.any (psNameEq name)
  let classes := environment.classes.filter owned
  let classParameters := environment.classParameters.filter (fun item => owned item.fst)
  let instances := environment.instances.entries.filter fun item =>
    match item.value with
    | .constE name _ => owned name
    | _ => false
  { declarations := publicDecls.map (psPscv0ImportedDeclaration exposed),
    classes, classParameters, instances }

def psPscv0SameInstanceIdentity (left right : PsInstanceEntry) : Bool :=
  match left.value, right.value with
  | .constE a _, .constE b _ => psNameEq a b
  | _, _ => false

-- The same instance may reach a client through two public-import paths.
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
  let instances := view.instances.foldl (fun index entry =>
    if index.entries.any (psPscv0SameInstanceIdentity entry) then index
    else psInstanceIndexAdd index entry) environment.instances
  return { environment with classes, classParameters, instances }

def psPscv0ExprConstants : PsExpr → List PsName
  | .constE name _ => [name]
  | .app fn arg => psPscv0ExprConstants fn ++ psPscv0ExprConstants arg
  | .lam _ type body _ | .forallE _ type body _ =>
      psPscv0ExprConstants type ++ psPscv0ExprConstants body
  | .letE _ type value body =>
      psPscv0ExprConstants type ++ psPscv0ExprConstants value ++
        psPscv0ExprConstants body
  | .proj _ _ value => psPscv0ExprConstants value
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
  ownNames : List PsName

structure PsPscv0ProjectOrigin where
  moduleName : String
  sourceName : String
  source : String
  batches : List PsElabBatchOrigin
  parents : List (PsName × PsName)

structure PsPscv0ProjectOutput where
  prepared : PsCompilerAdmissionReadyModule
  admissions : String
  mainNames : List PsName
  libraryNames : List PsName
  origins : List PsPscv0ProjectOrigin
  -- No imported source is promoted to proof authority. The external official
  -- Lean kernel still checks the complete canonical dependency closure.

-- The entry module sees only its declared imports. Public imports are added to
-- its exported interface, ordinary imports are deliberately not re-exported.
def psCompilerPreparePscv0Project (entryName : String)
    (sources : List PsPscv0ModuleSource) : Except String PsPscv0ProjectOutput := do
  let parsed ← psPscv0ProjectParse sources
  if !parsed.any (fun item => item.name == entryName) then
    throw ("PSCV0-MODULE: unknown entry " ++ entryName)
  let budget := parsed.foldl (fun total item => total + item.program.imports.length + 1) 1
  let reachable ← psPscv0ProjectReachable budget parsed [entryName] []
  let active := parsed.filter (fun item => reachable.contains item.name)
  let order ← psPscv0ProjectOrder (active.length + 1) active []
  let mut built : List PsPscv0BuiltModule := []
  let mut declarations : List PsDeclaration := []
  let mut globalNames : List PsName := []
  let mut origins : List PsPscv0ProjectOrigin := []
  let mut mainNames : List PsName := []
  for item in order do
    let importEnvironment ← item.program.imports.foldlM (fun env imp => do
      let some linked := built.find? (fun module =>
        module.name == psPscv0ImportKey imp)
        | throw "PSCV0-MODULE: unresolved topological dependency"
      psPscv0InstallInterface env linked.interface) psSelfHostProdPreludeEnvironment
    let program := { item.program with imports := [] }
    let elaborated ← (psElabProgramWithOrigins importEnvironment program item.name).mapError
      psCompilerPscv0ElabError
    let output ← (psCompilerPrepareElaboratedWithOutput elaborated.result).mapError
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
    -- A public type must never refer to this module's private constants, even
    -- though public executable bodies may call those constants internally.
    for decl in ownPublic.declarations do
      if (psPscv0ExprConstants (psDeclarationType decl)).any
          (fun dependency => hidden.any (psNameEq dependency)) then
        throw ("PSCV0-MODULE: public signature references private name in " ++
          psNameToString (psDeclarationName decl))
      if let some body := psDeclarationValue decl then
        if (psPscv0ExprConstants body).any
            (fun dependency => hidden.any (psNameEq dependency)) then
          throw ("PSCV0-MODULE: exposed body references private name in " ++
            psNameToString (psDeclarationName decl))
    let mut interface := ownPublic
    for imp in item.program.imports do
      if imp.isPublic then
        let some linked := built.find? (fun module =>
          module.name == psPscv0ImportKey imp)
          | throw "PSCV0-MODULE: missing public dependency"
        interface := psPscv0InterfaceMerge interface linked.interface
    built := built ++ [{ name := item.name, interface, ownNames }]
    declarations := declarations ++ own
    origins := origins ++ [{
      moduleName := item.name, sourceName := item.sourceName, source := item.source,
      batches := elaborated.origins, parents := output.originParents }]
    if item.name == entryName then
      mainNames := ownPublic.declarations.map psDeclarationName
  let prepared : PsCompilerAdmissionReadyModule := { declarations }
  -- Source-level 'public import' is a transitive API view for importing
  -- modules, not an instruction to export dependency functions from the
  -- executable entry artifact. Link every dependency, expose entry names only.
  let libraryNames := globalNames.reverse.filter (fun name =>
    !mainNames.any (psNameEq name))
  let admissions ← (psCompilerAdmissionsFromPrepared prepared).mapError psCompilerPscv0Error
  return { prepared, admissions, mainNames, libraryNames, origins }
