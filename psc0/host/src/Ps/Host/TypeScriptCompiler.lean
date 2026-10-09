import Ps.BackendTs.Module
import Ps.Bridge.Json

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

-- Current compilation and historical recovery have separate, exact profiles.
def psTypeScriptExpectedVersion : IO String := do
  let version := (← IO.getEnv "PSC0_TYPESCRIPT_VERSION").getD "7.0.2"
  if version == "7.0.2" || version == "5.8.3" then
    pure version
  else
    throw (IO.userError
      ("PSC0_TYPESCRIPT_VERSION: expected 7.0.2 or historical 5.8.3, received " ++ version))

-- FilePath.isAbsolute also accepts drive-relative Windows paths such as C:tsc.
def psTypeScriptAbsolutePath (value : String) : Bool :=
  if System.Platform.isWindows then
    let normalized := value.replace "\\" "/"
    if normalized.startsWith "/" then
      true
    else
      match (normalized.chars.take 3).toList with
      | [drive, ':', '/'] => drive.isAlpha
      | _ => false
  else
    value.startsWith "/"

def psTypeScriptPathKey (value : System.FilePath) : String :=
  if System.Platform.isWindows then
    (value.toString.replace "\\" "/").toLower
  else
    value.toString

def psTypeScriptInstalledPackageCli
    (packageJson : System.FilePath) : IO System.FilePath := do
  let realPackageJson ← IO.FS.realPath packageJson
  let directory ←
    match realPackageJson.parent with
    | some parent => pure parent
    | none => throw (IO.userError "package.json has no parent directory")
  let source ← IO.FS.readFile realPackageJson
  let metadata ←
    match psJsonParse source with
    | Except.ok value => pure value
    | Except.error _ => throw (IO.userError "invalid TypeScript package.json")
  let packageName := (psJsonGetField metadata "name").bind psJsonAsString
  let command := (psJsonGetField metadata "bin").bind
    (fun bins => (psJsonGetField bins "tsc").bind psJsonAsString)
  if packageName != some "typescript" then
    throw (IO.userError "package.json must declare the typescript package")
  let bin ←
    match command with
    | some value => pure value
    | none => throw (IO.userError "package.json must declare string bin.tsc")
  if bin.isEmpty || (System.FilePath.mk bin).isAbsolute then
    throw (IO.userError "package.json bin.tsc must be a nonempty relative path")
  let launcher ← IO.FS.realPath (directory / bin)
  let directoryKey := psTypeScriptPathKey directory
  let directoryPrefix := if directoryKey.endsWith "/" then directoryKey else directoryKey ++ "/"
  if !(psTypeScriptPathKey launcher).startsWith directoryPrefix ||
      (← launcher.metadata).type != IO.FS.FileType.file then
    throw (IO.userError "bin.tsc must be a regular file inside the installed typescript package")
  IO.FS.withFile launcher .read (fun _ => pure ())
  pure launcher

-- The nearest package boundary must own this exact declared launcher.
def psTypeScriptLauncherOwner
    (fuel : Nat)
    (launcher directory : System.FilePath) : IO System.FilePath :=
  match fuel with
  | 0 => throw (IO.userError "launcher has no owning typescript package")
  | Nat.succ remaining => do
      let packageJson := directory / "package.json"
      if ← packageJson.pathExists then
        let declared ← psTypeScriptInstalledPackageCli packageJson
        if psTypeScriptPathKey declared != psTypeScriptPathKey launcher then
          throw (IO.userError "launcher is not the installed package bin.tsc")
        return launcher
      match directory.parent with
      | some parent => psTypeScriptLauncherOwner remaining launcher parent
      | none => throw (IO.userError "launcher has no owning typescript package")

def psTypeScriptInstalledLauncher
    (candidate : System.FilePath) : IO System.FilePath := do
  let launcher ← IO.FS.realPath candidate
  if (← launcher.metadata).type != IO.FS.FileType.file then
    throw (IO.userError "TypeScript launcher must be a regular file")
  match launcher.parent with
  | some directory =>
      psTypeScriptLauncherOwner (launcher.components.length + 1) launcher directory
  | none => throw (IO.userError "launcher has no parent directory")

-- An explicit override is authoritative, including an empty or invalid value.
-- Invoke the package's JavaScript bin.tsc through Node, without shell shims.
def psTypeScriptCli : IO String := do
  let expected ← psTypeScriptExpectedVersion
  match ← IO.getEnv "PSC0_TSC" with
  | some override => do
      if !psTypeScriptAbsolutePath override then
        throw (IO.userError
          "PSC0_TYPESCRIPT_CLI_OVERRIDE: PSC0_TSC must be an absolute installed JavaScript launcher")
      try
        return (← psTypeScriptInstalledLauncher (System.FilePath.mk override)).toString
      catch error =>
        throw (IO.userError
          ("PSC0_TYPESCRIPT_CLI_OVERRIDE: " ++ override ++ ": " ++ toString error))
  | none => do
      let current ← IO.currentDir
      let packageJson := current / "node_modules/typescript/package.json"
      if ← packageJson.pathExists then
        return (← psTypeScriptInstalledPackageCli packageJson).toString
      let separator := if System.Platform.isWindows then ";" else ":"
      let directories := ((← IO.getEnv "PATH").getD "").splitOn separator
      for directory in directories do
        let base := System.FilePath.mk (if directory.isEmpty then "." else directory)
        let candidates := [base / "tsc", base / "node_modules/typescript/bin/tsc"] ++
          (if base.fileName == some ".bin" then [base / "../typescript/bin/tsc"] else [])
        for candidate in candidates do
          if ← candidate.pathExists then
            try
              return (← psTypeScriptInstalledLauncher candidate).toString
            catch _ => pure ()
      throw (IO.userError
        ("PSC1_TYPESCRIPT_CLI_MISSING: install TypeScript " ++ expected ++
          " locally or on PATH, or set PSC0_TSC to its absolute installed JavaScript launcher"))

def psTypeScriptVerifyVersion (cli expected : String) : IO String := do
  let output ← IO.Process.output {
    cmd := "node"
    args := #[cli, "--version"]
  }
  if output.exitCode != 0 then
    throw (IO.userError
      ("PSC1_TSC_VERSION_FAILED:\n" ++ output.stdout ++ output.stderr))
  let raw := output.stdout.trimAscii.toString
  if raw != "Version " ++ expected then
    throw (IO.userError
      ("PSC1_TSC_VERSION_MISMATCH: expected Version " ++ expected ++ ", received " ++ raw))
  pure expected

def psTypeScriptVersion : IO String := do
  let expected ← psTypeScriptExpectedVersion
  let cli ← psTypeScriptCli
  psTypeScriptVerifyVersion cli expected

def psTypeScriptProfileArgs (version : String) (args : Array String) : Array String :=
  if version == "7.0.2" then #["--ignoreConfig"] ++ args else args

def psCompileTypeScriptFile
    (typeScriptPath : String) :
    IO PsTypeScriptCompileResult := do
  let expected ← psTypeScriptExpectedVersion
  let cli ← psTypeScriptCli
  let version ← psTypeScriptVerifyVersion cli expected
  let arguments := psTypeScriptProfileArgs version #[
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
  let output ← IO.Process.output {
    cmd := "node"
    args := #[cli] ++ arguments
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
