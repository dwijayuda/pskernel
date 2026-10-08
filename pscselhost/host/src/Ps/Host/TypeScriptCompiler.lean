import Ps.BackendTs.Module

structure PsTypeScriptCompileResult where
  typeScriptPath : String
  javascriptPath : String
  declarationPath : String
  sourceMapPath : String
  diagnostics : String
  typescriptVersion : String

def psReplaceSuffix
    (value suffix replacement : String) : String :=
  if value.endsWith suffix then
    value.dropRight suffix.length ++ replacement
  else
    value ++ replacement

def psTypeScriptOutputPaths
    (typeScriptPath : String) : String × String × String :=
  (
    psReplaceSuffix typeScriptPath ".ts" ".js",
    psReplaceSuffix typeScriptPath ".ts" ".d.ts",
    psReplaceSuffix typeScriptPath ".ts" ".js.map"
  )

-- Resolve the installed JavaScript entry point. npm exec does not reliably use
-- a pinned tsc supplied on PATH, and Windows .cmd shims require a shell.
def psTypeScriptCli : IO String := do
  let current ← IO.currentDir
  let separator := if System.Platform.isWindows then ";" else ":"
  let directories := current.toString :: ((← IO.getEnv "PATH").getD "").splitOn separator
  for directory in directories do
    let base := System.FilePath.mk directory
    for candidate in [base / "node_modules/typescript/bin/tsc",
        base / "../typescript/bin/tsc", base / "tsc"] do
      if ← candidate.pathExists then
        let resolved ← IO.FS.realPath candidate
        if (resolved.toString.replace "\\" "/").endsWith "/typescript/bin/tsc" then
          return resolved.toString
  throw (IO.userError "PSC1_TYPESCRIPT_CLI_MISSING: install TypeScript 5.8.3 locally or on PATH")

def psTypeScriptVersion : IO String := do
  let output ← IO.Process.output {
    cmd := "node"
    args := #[← psTypeScriptCli, "--version"]
  }
  if output.exitCode != 0 then
    throw
      (IO.userError
        ("PSC1_TSC_VERSION_FAILED:\n" ++ output.stderr))
  let raw := output.stdout.trimAscii.toString
  if raw.startsWith "Version " then
    pure (raw.drop 8).toString
  else
    pure raw

def psCompileTypeScriptFile
    (typeScriptPath : String) :
    IO PsTypeScriptCompileResult := do
  let output ← IO.Process.output {
    cmd := "node"
    args := #[
      ← psTypeScriptCli,
      typeScriptPath,
      "--target", "ES2022",
      "--module", "ES2022",
      "--moduleResolution", "bundler",
      "--strict",
      "--declaration",
      "--sourceMap",
      "--noEmitOnError",
      "--skipLibCheck",
      "--pretty", "false"
    ]
  }
  let diagnostics :=
    if output.stderr.isEmpty then
      output.stdout
    else if output.stdout.isEmpty then
      output.stderr
    else
      output.stdout ++ "\n" ++ output.stderr
  if output.exitCode != 0 then
    throw
      (IO.userError
        ("PSC1_TS_COMPILE_FAILED:\n" ++ diagnostics))
  let paths := psTypeScriptOutputPaths typeScriptPath
  let javascriptPath := paths.1
  let declarationPath := paths.2.1
  let sourceMapPath := paths.2.2
  if !(← System.FilePath.pathExists javascriptPath) then
    throw (IO.userError "PSC1_TS_COMPILE_MISSING_JS")
  if !(← System.FilePath.pathExists declarationPath) then
    throw (IO.userError "PSC1_TS_COMPILE_MISSING_DECLARATION")
  if !(← System.FilePath.pathExists sourceMapPath) then
    throw (IO.userError "PSC1_TS_COMPILE_MISSING_SOURCE_MAP")
  let version ← psTypeScriptVersion
  pure {
    typeScriptPath := typeScriptPath
    javascriptPath := javascriptPath
    declarationPath := declarationPath
    sourceMapPath := sourceMapPath
    diagnostics := diagnostics
    typescriptVersion := version
  }

def psWriteAndCompileTypeScript
    (source : String)
    (typeScriptPath : String) :
    IO PsTypeScriptCompileResult := do
  if let some parent := (System.FilePath.mk typeScriptPath).parent then
    IO.FS.createDirAll parent
  IO.FS.writeFile typeScriptPath source
  psCompileTypeScriptFile typeScriptPath
