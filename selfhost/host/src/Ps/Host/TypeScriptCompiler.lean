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

def psTscExecutable : String :=
  if System.Platform.isWindows then
    "npx.cmd"
  else
    "npx"

def psTypeScriptVersion : IO String := do
  let output ← IO.Process.output {
    cmd := psTscExecutable
    args := #["--no-install", "tsc", "--version"]
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
    cmd := psTscExecutable
    args := #[
      "--no-install",
      "tsc",
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
  IO.FS.writeFile typeScriptPath source
  psCompileTypeScriptFile typeScriptPath
