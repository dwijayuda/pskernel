import Ps.BackendTs.Module

structure PsTypeScriptCompileResult where
  typeScriptPath : String
  javascriptPath : String
  declarationPath : String
  sourceMapPath : String
  diagnostics : String
  typescriptVersion : String

structure PsTypeScriptCommand where
  command : String
  prefixArgs : Array String

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

-- Resolve the installed JavaScript entry point. PSC_TYPESCRIPT_CLI is the
-- authoritative override shared with the Node-side self-host tooling. Falling
-- back to local/PATH discovery is retained for interactive use, but every
-- fixed-point workflow supplies the override explicitly.
def psTypeScriptCli : IO String := do
  match ← IO.getEnv "PSC_TYPESCRIPT_CLI" with
  | some override =>
      let candidate := System.FilePath.mk override
      if !(← candidate.pathExists) then
        throw
          (IO.userError
            ("PSC1_TYPESCRIPT_CLI_OVERRIDE_MISSING: " ++ override))
      let resolved ← IO.FS.realPath candidate
      let normalized := resolved.toString.replace "\\" "/"
      if normalized.endsWith "/typescript/bin/tsc" then
        return resolved.toString
      throw
        (IO.userError
          ("PSC1_TYPESCRIPT_CLI_OVERRIDE_INVALID: " ++ resolved.toString))
  | none =>
      let current ← IO.currentDir
      let separator := if System.Platform.isWindows then ";" else ":"
      let directories :=
        current.toString :: ((← IO.getEnv "PATH").getD "").splitOn separator
      for directory in directories do
        let base := System.FilePath.mk directory
        for candidate in [base / "node_modules/typescript/bin/tsc",
            base / "../typescript/bin/tsc", base / "tsc"] do
          if ← candidate.pathExists then
            let resolved ← IO.FS.realPath candidate
            if (resolved.toString.replace "\\" "/").endsWith "/typescript/bin/tsc" then
              return resolved.toString
      throw
        (IO.userError
          "PSC1_TYPESCRIPT_CLI_MISSING: install TypeScript 7.0.2 locally or on PATH")

def psTypeScriptNativeExecutableName : String :=
  if System.Platform.isWindows then "tsc.exe" else "tsc"

def psTypeScriptCommand : IO PsTypeScriptCommand := do
  if let some override ← IO.getEnv "PSC_TYPESCRIPT_NATIVE_TSC" then
    let candidate := System.FilePath.mk override
    if ← candidate.pathExists then
      return { command := override, prefixArgs := #[] }
    throw (IO.userError ("PSC1_TYPESCRIPT_NATIVE_TSC_MISSING: " ++ override))
  let appPath ← IO.appPath
  if let some binDir := appPath.parent then
    if let some bundleRoot := binDir.parent then
      let bundled := bundleRoot / "typescript" / "lib" / psTypeScriptNativeExecutableName
      if ← bundled.pathExists then
        return { command := bundled.toString, prefixArgs := #[] }
  pure { command := "node", prefixArgs := #[← psTypeScriptCli] }

def psTypeScriptVersion : IO String := do
  let tool ← psTypeScriptCommand
  let output ← IO.Process.output {
    cmd := tool.command
    args := tool.prefixArgs ++ #["--version"]
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
  let version ← psTypeScriptVersion
  if version != "7.0.2" then
    throw
      (IO.userError
        ("PSC1_TYPESCRIPT_PIN: require TypeScript 7.0.2, got " ++ version))
  let tool ← psTypeScriptCommand
  let output ← IO.Process.output {
    cmd := tool.command
    args := tool.prefixArgs ++ #[
      typeScriptPath,
      "--ignoreConfig",
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
