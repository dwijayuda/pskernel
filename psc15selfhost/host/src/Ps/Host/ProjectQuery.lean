import Ps.Host.ProjectCompiler
import Ps.Project.QueryGraph
import Ps.Bridge.CheckedAdmissions

structure PsHostModuleArtifact where
  path : String
  declarations : List PsDeclaration

structure PsHostProjectSnapshot where
  query : PsQuerySnapshot
  artifacts : List PsHostModuleArtifact

structure PsHostIncrementalState where
  environment : PsEnvironment
  declarations : List PsDeclaration
  loadedPaths : List String
  snapshot : PsHostProjectSnapshot
  rebuiltPaths : List String
  reusedPaths : List String

structure PsHostIncrementalProjectResult where
  elaborated : PsElabModuleResult
  snapshot : PsHostProjectSnapshot
  rebuiltPaths : List String
  reusedPaths : List String

def psHostProjectSnapshotEmpty : PsHostProjectSnapshot :=
  {
    query := psQuerySnapshotEmpty
    artifacts := List.nil
  }

def psHostQueryModuleName
    (path : String) : PsName :=
  PsName.str PsName.anonymous path

def psHostFindModuleArtifact
    (path : String)
    (artifacts : List PsHostModuleArtifact) :
    Option PsHostModuleArtifact :=
  match artifacts with
  | List.nil =>
      Option.none
  | List.cons artifact rest =>
      if psStringEq artifact.path path then
        Option.some artifact
      else
        psHostFindModuleArtifact path rest

def psHostSnapshotFindArtifact
    (snapshot : PsHostProjectSnapshot)
    (path : String) :
    Option PsHostModuleArtifact :=
  psHostFindModuleArtifact path snapshot.artifacts

def psHostSnapshotInsertArtifact
    (snapshot : PsHostProjectSnapshot)
    (artifact : PsHostModuleArtifact) :
    PsHostProjectSnapshot :=
  {
    query := snapshot.query
    artifacts :=
      List.cons artifact snapshot.artifacts
  }

def psHostSnapshotWithQuery
    (snapshot : PsHostProjectSnapshot)
    (query : PsQuerySnapshot) :
    PsHostProjectSnapshot :=
  {
    query := query
    artifacts := snapshot.artifacts
  }

def psHostApplyModuleDeclarations
    (path : String)
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    IO PsEnvironment := do
  match
      psAddDeclarationList
        environment
        declarations with
  | Except.error error =>
      throw
        (IO.userError
          ("PSC1_PROJECT_REUSE_ELAB_FAILED: " ++
            path ++
            ": " ++
            psHostElabErrorText error))
  | Except.ok nextEnvironment =>
      pure nextEnvironment

def psHostModuleInterfaceFingerprint
    (path : String)
    (declarations : List PsDeclaration) :
    IO PsModuleInterfaceFingerprint := do
  match
      psEncodeCheckedAdmissionsCanonical
        declarations with
  | Except.error _ =>
      throw
        (IO.userError
          ("PSC1_PROJECT_INTERFACE_ENCODING_FAILED: " ++
            path))
  | Except.ok encoded =>
      pure (psModuleInterfaceFingerprintV1 encoded)

def psHostIncrementalStateCommitArtifact
    (state : PsHostIncrementalState)
    (artifact : PsHostModuleArtifact)
    (query : PsQuerySnapshot)
    (environment : PsEnvironment)
    (rebuilt : Bool) :
    PsHostIncrementalState :=
  {
    environment := environment
    declarations :=
      psListAppend
        state.declarations
        artifact.declarations
    loadedPaths :=
      List.cons artifact.path state.loadedPaths
    snapshot :=
      psHostSnapshotInsertArtifact
        (psHostSnapshotWithQuery
          state.snapshot
          query)
        artifact
    rebuiltPaths :=
      if rebuilt then
        List.cons artifact.path state.rebuiltPaths
      else
        state.rebuiltPaths
    reusedPaths :=
      if rebuilt then
        state.reusedPaths
      else
        List.cons artifact.path state.reusedPaths
  }

def psHostIncrementalRebuild
    (path : String)
    (input : PsModuleQueryInput)
    (sourceModule : PsSyntaxModule)
    (state : PsHostIncrementalState) :
    IO PsHostIncrementalState := do
  let elaborated ←
    psHostElabDeclarationsDetailed
      path
      state.environment
      sourceModule.declarations
      List.nil
  let interfaceFingerprint ←
    psHostModuleInterfaceFingerprint
      path
      elaborated.declarations
  match
      psQueryCommitRebuilt
        state.snapshot.query
        input
        interfaceFingerprint with
  | Except.error _ =>
      throw
        (IO.userError
          ("PSC1_PROJECT_QUERY_COMMIT_FAILED: " ++
            path))
  | Except.ok query =>
      match
          psQuerySnapshotFind
            query
            input.name with
      | Option.none =>
          throw
            (IO.userError
              ("PSC1_PROJECT_QUERY_RECORD_MISSING: " ++
                path))
      | Option.some record =>
          let artifact : PsHostModuleArtifact :=
            {
              path := path
              declarations := elaborated.declarations
            }
          pure
            (psHostIncrementalStateCommitArtifact
              state
              artifact
              query
              elaborated.environment
              true)

def psHostIncrementalReuse
    (path : String)
    (record : PsModuleQueryRecord)
    (artifact : PsHostModuleArtifact)
    (state : PsHostIncrementalState) :
    IO PsHostIncrementalState := do
  let environment ←
    psHostApplyModuleDeclarations
      path
      state.environment
      artifact.declarations
  match
      psQueryCommitReused
        state.snapshot.query
        record with
  | Except.error _ =>
      throw
        (IO.userError
          ("PSC1_PROJECT_QUERY_REUSE_COMMIT_FAILED: " ++
            path))
  | Except.ok query =>
      let currentArtifact : PsHostModuleArtifact :=
        {
          path := path
          declarations := artifact.declarations
        }
      pure
        (psHostIncrementalStateCommitArtifact
          state
          currentArtifact
          query
          environment
          false)

mutual
  partial def psHostLoadModuleIncrementalWithFuel
      (fuel : Nat)
      (root path : String)
      (stack : List String)
      (previous : PsHostProjectSnapshot)
      (state : PsHostIncrementalState) :
      IO PsHostIncrementalState := do
    match fuel with
    | 0 =>
        throw
          (IO.userError
            "PSC1_PROJECT_FUEL_EXHAUSTED")
    | remaining + 1 =>
        if psHostListContainsString state.loadedPaths path then
          pure state
        else if psHostListContainsString stack path then
          throw
            (IO.userError
              ("PSC1_PROJECT_DEPENDENCY_CYCLE: " ++ path))
        else
          let source ← IO.FS.readFile path
          let sourceModule ←
            psHostParseSource path source
          let loaded ←
            psHostLoadImportsIncrementalWithFuel
              remaining
              root
              (List.cons path stack)
              previous
              sourceModule.imports
              state
          let withImports :=
            Prod.fst loaded
          let importNames :=
            Prod.snd loaded
          let input : PsModuleQueryInput :=
            {
              name := psHostQueryModuleName path
              imports := importNames
              sourceKey := source
            }
          match
              psQueryEvaluateModule
                previous.query
                withImports.snapshot.query
                input with
          | PsQueryDecision.red _ =>
              psHostIncrementalRebuild
                path
                input
                sourceModule
                withImports
          | PsQueryDecision.green record =>
              match
                  psHostSnapshotFindArtifact
                    previous
                    path with
              | Option.none =>
                  psHostIncrementalRebuild
                    path
                    input
                    sourceModule
                    withImports
              | Option.some artifact =>
                  psHostIncrementalReuse
                    path
                    record
                    artifact
                    withImports

  partial def psHostLoadImportsIncrementalWithFuel
      (fuel : Nat)
      (root : String)
      (stack : List String)
      (previous : PsHostProjectSnapshot)
      (imports : List PsSyntaxImport)
      (state : PsHostIncrementalState) :
      IO (Prod PsHostIncrementalState (List PsName)) := do
    match imports with
    | List.nil =>
        pure (Prod.mk state List.nil)
    | List.cons sourceImport rest =>
        let dependency ←
          psHostResolveImport
            root
            sourceImport.moduleName
        let next ←
          psHostLoadModuleIncrementalWithFuel
            fuel
            root
            dependency
            stack
            previous
            state
        let tail ←
          psHostLoadImportsIncrementalWithFuel
            fuel
            root
            stack
            previous
            rest
            next
        pure
          (Prod.mk
            (Prod.fst tail)
            (List.cons
              (psHostQueryModuleName dependency)
              (Prod.snd tail)))
end

def psHostLoadProjectIncremental
    (baseEnvironment : PsEnvironment)
    (entryPath : String)
    (previous : PsHostProjectSnapshot) :
    IO PsHostIncrementalProjectResult := do
  let root :=
    psHostDirectoryOfPath entryPath
  let state ←
    psHostLoadModuleIncrementalWithFuel
      4096
      root
      entryPath
      List.nil
      previous
      {
        environment := baseEnvironment
        declarations := List.nil
        loadedPaths := List.nil
        snapshot := psHostProjectSnapshotEmpty
        rebuiltPaths := List.nil
        reusedPaths := List.nil
      }
  pure {
    elaborated :=
      {
        environment := state.environment
        declarations := state.declarations
      }
    snapshot := state.snapshot
    rebuiltPaths := state.rebuiltPaths
    reusedPaths := state.reusedPaths
  }
