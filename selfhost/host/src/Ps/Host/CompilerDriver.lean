import Ps.Compiler.Api
import Ps.Host.ProjectCompiler
import Ps.Host.TypeScriptCompiler

def psHostCompilerSourceKindFromPath
    (path : String) : Option PsCompilerSourceKind :=
  if path.endsWith ".lean" then
    some PsCompilerSourceKind.lean
  else if path.endsWith ".ps" then
    some PsCompilerSourceKind.proofScript
  else
    none

def psHostCompilerTargetKind
    (target : String) : Option PsCompilerSourceKind :=
  if target == "lean" || target == ".lean" then
    some PsCompilerSourceKind.lean
  else if target == "ps" || target == ".ps" then
    some PsCompilerSourceKind.proofScript
  else
    none

def psHostCompilerTranslatedSource
    (inputPath : String)
    (targetText : String) : IO String := do
  let sourceKind ←
    match psHostCompilerSourceKindFromPath inputPath with
    | none =>
        throw
          (IO.userError
            ("PSC1_CLI_SOURCE_KIND: expected .lean or .ps input, got " ++
              inputPath))
    | some kind => pure kind
  let targetKind ←
    match psHostCompilerTargetKind targetText with
    | none =>
        throw
          (IO.userError
            ("PSC1_CLI_TRANSLATION_TARGET: expected ps or lean, got " ++
              targetText))
    | some kind => pure kind
  let source ← IO.FS.readFile inputPath
  match psCompilerTranslateSource sourceKind targetKind source with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_TRANSLATION_FAILED: source is outside the supported bootstrap subset")
  | Except.ok output =>
      pure output

def psHostCompilerTranslate
    (inputPath : String)
    (targetText : String) : IO Unit := do
  IO.print (← psHostCompilerTranslatedSource inputPath targetText)

def psHostCompilerTranslateToFile
    (inputPath : String)
    (targetText : String)
    (outputPath : String) : IO Unit := do
  let output ← psHostCompilerTranslatedSource inputPath targetText
  IO.FS.writeFile outputPath output
  IO.println
    ("PSC1_TRANSLATE: " ++ inputPath ++ " -> " ++ outputPath)

def psHostCompilerElaborateProject
    (inputPath : String) : IO PsElabModuleResult :=
  psHostLoadProject
    psBootstrapPreludeEnvironment
    inputPath

def psHostCompilerCheck
    (inputPath : String) : IO Unit := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerCheckElaborated elaborated with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CHECK_FAILED: elaborated source is not persistable checked core")
  | Except.ok _ =>
      IO.println
        ("PSC1_CHECK: PASS (" ++
          toString elaborated.declarations.length ++
          " declarations)")

def psHostCompilerAdmissions
    (inputPath : String) : IO Unit := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerAdmissionsFromElaborated elaborated with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_ADMISSION_CODEC_FAILED: elaborated source is not persistable")
  | Except.ok encoded =>
      IO.print encoded

def psHostCompilerTypeScriptSource
    (inputPath : String) : IO String := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerTypeScriptFromElaborated elaborated with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_TS_EMIT_FAILED: source is outside the executable TypeScript backend subset")
  | Except.ok output =>
      pure output

def psHostCompilerTypeScript
    (inputPath : String) : IO Unit := do
  IO.print (← psHostCompilerTypeScriptSource inputPath)

def psHostCompilerBuild
    (inputPath outputPath : String) : IO Unit := do
  let typeScriptPath ←
    if outputPath.endsWith ".ts" then
      pure outputPath
    else if outputPath.endsWith ".js" then
      pure (outputPath.dropRight 3 ++ ".ts")
    else
      throw
        (IO.userError
          "PSC1_CLI_OUTPUT_KIND: build output must end in .js or .ts")
  let source ← psHostCompilerTypeScriptSource inputPath
  let result ← psWriteAndCompileTypeScript source typeScriptPath
  IO.println
    ("PSC1_COMPILE: " ++ result.typeScriptPath ++
      " -> " ++ result.javascriptPath)
  IO.println
    ("PSC1_DECLARATION: " ++ result.declarationPath)
  IO.println
    ("PSC1_SOURCE_MAP: " ++ result.sourceMapPath)
  IO.println
    ("PSC1_TYPESCRIPT: " ++ result.typescriptVersion)
