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

def psHostParentDirectory (path : String) : String :=
  let parent := psHostDirectoryOfPath path
  if parent == path then "." else parent

partial def psHostFindWorkspaceRootWithFuel
    (fuel : Nat)
    (path : String) : IO (Option String) := do
  match fuel with
  | 0 => pure none
  | remaining + 1 =>
      let packageDir := psHostJoinPath path "packages"
      let stdlibDir := psHostJoinPath path "stdlib"
      let hasPackages ← System.FilePath.pathExists packageDir
      let hasStdlib ← System.FilePath.pathExists stdlibDir
      if hasPackages && hasStdlib then
        pure (some path)
      else
        let parent := psHostParentDirectory path
        if parent == path || (path == "." && parent == ".") then
          pure none
        else
          psHostFindWorkspaceRootWithFuel remaining parent

def psHostFindWorkspaceRoot (root : String) : IO (Option String) :=
  psHostFindWorkspaceRootWithFuel 64 root

def psHostPackageDirectory : List String -> Option String
  | "Ps" :: "Foundation" :: _ => some "foundation"
  | "Ps" :: "Syntax" :: _ => some "syntax"
  | "Ps" :: "Core" :: _ => some "core"
  | "Ps" :: "Environment" :: _ => some "environment"
  | "Ps" :: "Project" :: _ => some "project"
  | "Ps" :: "Meta" :: _ => some "meta"
  | "Ps" :: "Elab" :: _ => some "elab"
  | "Ps" :: "Bridge" :: _ => some "bridge"
  | "Ps" :: "CompilerIr" :: _ => some "compiler-ir"
  | "Ps" :: "Erasure" :: _ => some "erasure"
  | "Ps" :: "BackendTs" :: _ => some "backend-ts"
  | _ => none

def psHostImportSearchBases
    (root : String)
    (workspace : Option String)
    (sourceName : PsSyntaxName) : List String :=
  match workspace with
  | none => [root]
  | some workspaceRoot =>
      let stdlibRoot := psHostJoinPath workspaceRoot "stdlib"
      match sourceName.segments with
      | "ProofScript" :: _ =>
          [root, stdlibRoot]
      | segments =>
          match psHostPackageDirectory segments with
          | none => [root, stdlibRoot]
          | some packageName =>
              let packageRoot :=
                psHostJoinPath
                  (psHostJoinPath
                    (psHostJoinPath workspaceRoot "packages")
                    packageName)
                  "src"
              [root, packageRoot, stdlibRoot]

def psHostResolveImportAtBase
    (preferLean : Bool)
    (baseRoot relative : String) : IO (Option String) := do
  let base := psHostJoinPath baseRoot relative
  let leanPath := base ++ ".lean"
  let proofScriptPath := base ++ ".ps"
  let hasLean ← System.FilePath.pathExists leanPath
  let hasProofScript ← System.FilePath.pathExists proofScriptPath
  if hasLean && hasProofScript then
    if preferLean then
      pure (some leanPath)
    else
      throw
        (IO.userError
          ("PSC1_PROJECT_SOURCE_AMBIGUITY: " ++ relative))
  else if hasLean then
    pure (some leanPath)
  else if hasProofScript then
    pure (some proofScriptPath)
  else
    pure none

partial def psHostResolveImportFromBases
    (preferLean : Bool)
    (relative : String) :
    List String -> IO (Option String)
  | [] => pure none
  | base :: rest => do
      let resolved ←
        psHostResolveImportAtBase
          preferLean
          base
          relative
      match resolved with
      | some path => pure (some path)
      | none =>
          psHostResolveImportFromBases
            preferLean
            relative
            rest

def psHostPreferAuthoritativeLean
    (sourceName : PsSyntaxName) : Bool :=
  match sourceName.segments with
  | "Ps" :: _ => true
  | "ProofScript" :: _ => true
  | _ => false

def psHostResolveImport
    (root : String)
    (sourceName : PsSyntaxName) : IO String := do
  let relative := psHostModuleRelativePath sourceName
  if relative.isEmpty then
    throw (IO.userError "PSC1_PROJECT_IMPORT_NAME")
  let workspace ← psHostFindWorkspaceRoot root
  let bases := psHostImportSearchBases root workspace sourceName
  let resolved ←
    psHostResolveImportFromBases
      (psHostPreferAuthoritativeLean sourceName)
      relative
      bases
  match resolved with
  | some path => pure path
  | none =>
      throw
        (IO.userError
          ("PSC1_PROJECT_SOURCE_MISSING: " ++ relative))

def psHostTokenKindText : PsTokenKind -> String
  | .identifier => "identifier"
  | .natural => "natural"
  | .string => "string"
  | .character => "character"
  | .symbol => "symbol"
  | .endOfInput => "end-of-input"

def psHostSourcePosText (position : PsSourcePos) : String :=
  toString position.line ++ ":" ++ toString position.column

def psHostParseErrorText : PsParseError -> String
  | .fuelExhausted => "parser fuel exhausted"
  | .unexpectedEnd expected =>
      "unexpected end; expected " ++ expected
  | .expectedText expected actual span =>
      psHostSourcePosText span.start ++
        ": expected '" ++ expected ++
        "', got '" ++ actual ++ "'"
  | .expectedKind expected actual span =>
      psHostSourcePosText span.start ++
        ": expected " ++ psHostTokenKindText expected ++
        ", got " ++ psHostTokenKindText actual

def psHostLexErrorText : PsLexError -> String
  | .unterminatedBlockComment span =>
      psHostSourcePosText span.start ++ ": unterminated block comment"
  | .unterminatedString span =>
      psHostSourcePosText span.start ++ ": unterminated string"
  | .newlineInString span =>
      psHostSourcePosText span.start ++ ": newline in string"
  | .unterminatedCharacter span =>
      psHostSourcePosText span.start ++ ": unterminated character"
  | .fuelExhausted => "lexer fuel exhausted"

def psHostInferErrorText : PsInferError -> String
  | .fuelExhausted => "infer:fuelExhausted"
  | .looseBoundVariable index =>
      "infer:looseBoundVariable:" ++ toString index
  | .unknownFreeVariable id =>
      "infer:unknownFreeVariable:" ++ toString id
  | .unknownMetavariable id =>
      "infer:unknownMetavariable:" ++ toString id
  | .unknownConstant name =>
      "infer:unknownConstant:" ++ psNameToString name
  | .incorrectUniverseArity name =>
      "infer:incorrectUniverseArity:" ++ psNameToString name
  | .expectedSort => "infer:expectedSort"
  | .expectedFunction => "infer:expectedFunction"
  | .applicationTypeMismatch => "infer:applicationTypeMismatch"
  | .letTypeMismatch => "infer:letTypeMismatch"
  | .projectionUnsupported => "infer:projectionUnsupported"

def psHostElabErrorText : PsElabError -> String
  | .fuelExhausted => "fuelExhausted"
  | .emptyName => "emptyName"
  | .unknownName name =>
      "unknownName:" ++ psNameToString name
  | .invalidNatural text => "invalidNatural:" ++ text
  | .invalidString text => "invalidString:" ++ text
  | .invalidCharacter text => "invalidCharacter:" ++ text
  | .infer error => psHostInferErrorText error
  | .typeMismatch => "typeMismatch"
  | .implicitApplicationUnsupported =>
      "implicitApplicationUnsupported"
  | .unsupportedTerm => "unsupportedTerm"
  | .matchExpectedType => "matchExpectedType"
  | .matchScrutineeUnsupported => "matchScrutineeUnsupported"
  | .matchInductiveUnsupported => "matchInductiveUnsupported"
  | .matchParameterArity => "matchParameterArity"
  | .matchPatternUnsupported => "matchPatternUnsupported"
  | .matchConstructorUnknown name =>
      "matchConstructorUnknown:" ++ psNameToString name
  | .matchDuplicateConstructor name =>
      "matchDuplicateConstructor:" ++ psNameToString name
  | .matchNonExhaustive => "matchNonExhaustive"
  | .matchRecursorUnsupported => "matchRecursorUnsupported"
  | .matchRecursorLevels => "matchRecursorLevels"
  | .matchConstructorArity name =>
      "matchConstructorArity:" ++ psNameToString name
  | .matchRecursiveFieldUnsupported name =>
      "matchRecursiveFieldUnsupported:" ++ psNameToString name
  | .duplicateDeclaration name =>
      "duplicateDeclaration:" ++ psNameToString name
  | .unresolvedMetavariable => "unresolvedMetavariable"
  | .structuralRecursionArity => "structuralRecursionArity"
  | .structuralRecursionNotDecreasing =>
      "structuralRecursionNotDecreasing"
  | .structuralRecursionInvariantArgument =>
      "structuralRecursionInvariantArgument"
  | .structuralRecursionInternal => "structuralRecursionInternal"

def psHostParseSource
    (path source : String) : IO PsSyntaxModule := do
  if path.endsWith ".lean" then
    match psParseLeanSource source with
    | Except.ok sourceModule => pure sourceModule
    | Except.error error =>
        let detail :=
          match error with
          | .lex lexError => psHostLexErrorText lexError
          | .parse parseError => psHostParseErrorText parseError
        throw
          (IO.userError
            ("PSC1_PROJECT_PARSE_FAILED: " ++ path ++ ": " ++ detail))
  else if path.endsWith ".ps" then
    match psParseProofScriptSource source with
    | Except.ok sourceModule => pure sourceModule
    | Except.error error =>
        let detail :=
          match error with
          | .lex lexError => psHostLexErrorText lexError
          | .parse parseError => psHostParseErrorText parseError
        throw
          (IO.userError
            ("PSC1_PROJECT_PARSE_FAILED: " ++ path ++ ": " ++ detail))
  else
    throw
      (IO.userError
        ("PSC1_PROJECT_SOURCE_KIND: " ++ path))

def psHostSyntaxDeclarationName : PsSyntaxDeclaration -> String
  | .definition name _ _ _ _ =>
      match psSyntaxNameToName name with
      | some value => psNameToString value
      | none => "<definition>"
  | .partialDefinition name _ _ _ _ =>
      match psSyntaxNameToName name with
      | some value => psNameToString value
      | none => "<partial>"
  | .theoremDecl name _ _ _ _ =>
      match psSyntaxNameToName name with
      | some value => psNameToString value
      | none => "<theorem>"
  | .inductiveDecl name _ _ _ _ =>
      match psSyntaxNameToName name with
      | some value => psNameToString value
      | none => "<inductive>"
  | .structureDecl name _ _ _ =>
      match psSyntaxNameToName name with
      | some value => psNameToString value
      | none => "<structure>"

def psHostElabDeclarationsDetailed
    (path : String)
    (environment : PsEnvironment) :
    List PsSyntaxDeclaration ->
    List PsDeclaration ->
    IO PsElabModuleResult
  | [], declarationsRev =>
      pure {
        environment := environment
        declarations := declarationsRev.reverse
      }
  | source :: rest, declarationsRev =>
      match psElabDeclarationBatch environment source with
      | Except.error error =>
          throw
            (IO.userError
              ("PSC1_PROJECT_ELAB_FAILED: " ++ path ++
                ": declaration=" ++ psHostSyntaxDeclarationName source ++
                ": " ++ psHostElabErrorText error))
      | Except.ok result =>
          match psAddDeclarationList environment result.declarations with
          | Except.error error =>
              throw
                (IO.userError
                  ("PSC1_PROJECT_ELAB_FAILED: " ++ path ++
                    ": declaration=" ++ psHostSyntaxDeclarationName source ++
                    ": " ++ psHostElabErrorText error))
          | Except.ok nextEnvironment =>
              psHostElabDeclarationsDetailed
                path
                nextEnvironment
                rest
                (psPrependBatchReverse
                  result.declarations
                  declarationsRev)

mutual
  partial def psHostLoadModuleWithFuel
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
          let elaborated ←
            psHostElabDeclarationsDetailed
              path
              withImports.environment
              sourceModule.declarations
              []
          pure {
            environment := elaborated.environment
            declarations :=
              withImports.declarations ++ elaborated.declarations
            loadedPaths := path :: withImports.loadedPaths
          }

  partial def psHostLoadImportsWithFuel
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
end

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
