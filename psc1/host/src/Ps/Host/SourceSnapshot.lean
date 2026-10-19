import Ps.Host.ProjectCompiler

/-- Exact input bytes and their parsed syntax, captured once by the project loader. -/
structure PsHostCapturedSource where
  path : String
  text : String
  parsed : PsSyntaxModule

structure PsHostCapturedProject where
  entryPath : String
  environment : PsEnvironment
  declarations : List PsDeclaration
  sources : List PsHostCapturedSource

private structure PsHostCaptureState where
  environment : PsEnvironment
  declarations : List PsDeclaration := []
  sources : List PsHostCapturedSource := []
  loaded : List String := []

mutual
  private partial def captureModule
      (fuel : Nat) (root inputPath : String)
      (stack : List String) (state : PsHostCaptureState) : IO PsHostCaptureState := do
    let path := (← IO.FS.realPath inputPath).toString
    if state.loaded.contains path then return state
    if stack.contains path then
      throw (IO.userError ("PSC1_PROJECT_DEPENDENCY_CYCLE: " ++ path))
    match fuel with
    | 0 => throw (IO.userError "PSC1_PROJECT_FUEL_EXHAUSTED")
    | remaining + 1 =>
      let text ← IO.FS.readFile path
      let parsed ← psHostParseSource path text
      let imported ← captureImports remaining root (path :: stack) parsed.imports state
      let elaborated ← psHostElabDeclarationsDetailed path imported.environment parsed.declarations []
      return {
        environment := elaborated.environment
        declarations := imported.declarations ++ elaborated.declarations
        sources := imported.sources ++ [{ path := path, text := text, parsed := parsed }]
        loaded := path :: imported.loaded }

  private partial def captureImports
      (fuel : Nat) (root : String) (stack : List String)
      (imports : List PsSyntaxImport) (state : PsHostCaptureState) : IO PsHostCaptureState := do
    match imports with
    | [] => return state
    | sourceImport :: rest =>
      let dependency ← psHostResolveImport root sourceImport.moduleName
      let next ← captureModule fuel root dependency stack state
      captureImports fuel root stack rest next
end

/-- A dependency-ordered immutable input snapshot. All target builders share this
value; none of them reads source files again. This is a captured byte snapshot,
not a claim that the filesystem itself is locked against concurrent writers. -/
def psHostCaptureProject
    (baseEnvironment : PsEnvironment) (inputPath : String) : IO PsHostCapturedProject := do
  let entryPath := (← IO.FS.realPath inputPath).toString
  let state ← captureModule 4096 (psHostDirectoryOfPath entryPath) entryPath []
    { environment := baseEnvironment }
  return { entryPath := entryPath, environment := state.environment,
    declarations := state.declarations, sources := state.sources }
