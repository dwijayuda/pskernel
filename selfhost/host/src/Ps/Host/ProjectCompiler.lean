import Ps.Environment.Prelude
import Ps.Syntax.ParseLean
import Ps.Syntax.ParseProofScript
import Ps.Elab.Declaration

structure PsHostProjectState where
  environment : PsEnvironment
  declarations : List PsDeclaration
  loadedPaths : List String

def psHostPathSeparator : Char :=
  if System.Platform.isWindows then '\\' else '/'

def psHostDirectoryChars :
    List Char -> List Char -> String
  | [], _ => "."
  | char :: rest, reversed =>
      if char == '/' || char == '\\' then
        String.ofList rest.reverse
      else
        psHostDirectoryChars rest (char :: reversed)

def psHostDirectoryOfPath (path : String) : String :=
  let chars := path.toList
  let rec loop : List Char -> List Char -> String
    | [], _ => "."
    | char :: rest, consumedRev =>
        if char == '/' || char == '\\' then
          String.ofList rest.reverse
        else
          loop rest (char :: consumedRev)
  loop chars.reverse []

def psHostModuleRelativePathChars : List Char -> List Char
  | [] => []
  | '.' :: rest =>
      psHostPathSeparator :: psHostModuleRelativePathChars rest
  | char :: rest =>
      char :: psHostModuleRelativePathChars rest

def psHostModuleRelativePath (name : PsSyntaxName) : String :=
  String.ofList
    (psHostModuleRelativePathChars
      (psNameToString
        (match psSyntaxNameToName name with
         | some value => value
         | none => PsName.anonymous)).toList)

def psHostJoinPath (left right : String) : String :=
  if left.isEmpty || left == "." then
    right
  else
    left ++ String.ofList [psHostPathSeparator] ++ right

def psHostListContainsString :
    List String -> String -> Bool
  | [], _ => false
  | value :: rest, target =>
      value == target || psHostListContainsString rest target

def psHostResolveImport
    (root : String)
    (sourceName : PsSyntaxName) : IO String := do
  let relative := psHostModuleRelativePath sourceName
  if relative.isEmpty then
    throw (IO.userError "PSC1_PROJECT_IMPORT_NAME")
  let base := psHostJoinPath root relative
  let leanPath := base ++ ".lean"
  let proofScriptPath := base ++ ".ps"
  let hasLean ← System.FilePath.pathExists leanPath
  let hasProofScript ← System.FilePath.pathExists proofScriptPath
  if hasLean && hasProofScript then
    throw
      (IO.userError
        ("PSC1_PROJECT_SOURCE_AMBIGUITY: " ++ relative))
  else if hasLean then
    pure leanPath
  else if hasProofScript then
    pure proofScriptPath
  else
    throw
      (IO.userError
        ("PSC1_PROJECT_SOURCE_MISSING: " ++ relative))

def psHostParseSource
    (path source : String) : IO PsSyntaxModule := do
  if path.endsWith ".lean" then
    match psParseLeanSource source with
    | Except.ok sourceModule => pure sourceModule
    | Except.error _ =>
        throw
          (IO.userError
            ("PSC1_PROJECT_PARSE_FAILED: " ++ path))
  else if path.endsWith ".ps" then
    match psParseProofScriptSource source with
    | Except.ok sourceModule => pure sourceModule
    | Except.error _ =>
        throw
          (IO.userError
            ("PSC1_PROJECT_PARSE_FAILED: " ++ path))
  else
    throw
      (IO.userError
        ("PSC1_PROJECT_SOURCE_KIND: " ++ path))

def psHostLoadImportsWithFuel
    (fuel : Nat)
    (root : String)
    (stack : List String) :
    List PsSyntaxImport ->
    PsHostProjectState ->
    IO PsHostProjectState
  | [], state => pure state
  | sourceImport :: rest, state => do
      let dependency ←
        psHostResolveImport root sourceImport.moduleName
      let next ←
        psHostLoadModuleWithFuel
          fuel
          root
          dependency
          stack
          state
      psHostLoadImportsWithFuel
        fuel
        root
        stack
        rest
        next

def psHostLoadModuleWithFuel
    (fuel : Nat)
    (root path : String)
    (stack : List String)
    (state : PsHostProjectState) :
    IO PsHostProjectState := do
  match fuel with
  | 0 =>
      throw (IO.userError "PSC1_PROJECT_FUEL_EXHAUSTED")
  | remaining + 1 =>
      if psHostListContainsString state.loadedPaths path then
        pure state
      else if psHostListContainsString stack path then
        throw
          (IO.userError
            ("PSC1_PROJECT_DEPENDENCY_CYCLE: " ++ path))
      else
        let source ← IO.FS.readFile path
        let sourceModule ← psHostParseSource path source
        let withImports ←
          psHostLoadImportsWithFuel
            remaining
            root
            (path :: stack)
            sourceModule.imports
            state
        match
            psElabModule
              withImports.environment
              sourceModule with
        | Except.error _ =>
            throw
              (IO.userError
                ("PSC1_PROJECT_ELAB_FAILED: " ++ path))
        | Except.ok elaborated =>
            pure {
              environment := elaborated.environment
              declarations :=
                withImports.declarations ++ elaborated.declarations
              loadedPaths := path :: withImports.loadedPaths
            }

def psHostLoadProject
    (baseEnvironment : PsEnvironment)
    (entryPath : String) :
    IO PsElabModuleResult := do
  let root := psHostDirectoryOfPath entryPath
  let state ←
    psHostLoadModuleWithFuel
      4096
      root
      entryPath
      []
      {
        environment := baseEnvironment
        declarations := []
        loadedPaths := []
      }
  pure {
    environment := state.environment
    declarations := state.declarations
  }
