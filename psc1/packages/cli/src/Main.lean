import Ps.Host.WasmComponent
import Ps.Host.WasmString
import Ps.Host.ScriptBackend

-- Native and npm launchers use this one command model. There is no implicit
-- fallback to the archived generated PSC0 compiler or its stale kernel artifact.
def psCliUsage : String :=
  "ProofScript PSC1 checked native compiler (Lean 4.35.0)\n" ++
  "usage:\n" ++
  "  Add --abi io-dispatcher for the explicit String dispatcher input ABI.\n" ++
  "  Add --assurance ordinary for checked partial execution; --assurance verified is unavailable and rejects.\n" ++
  "  psc1 check <input.lean|input.ps>\n" ++
  "  wasm-component: --export <name> or --exports <comma-separated-names>\n" ++
  "  psc1 build <input.lean|input.ps> --out <output.js|output.ts>\n" ++
  "  psc1 build <input.lean|input.ps> --target <js|ts|rust|wasm-core|python|php> --out <output>\n" ++
  "  psc1 build <input.lean|input.ps> --targets ts,js --out-dir <directory>\n" ++
  "  psc1 build <input.lean|input.ps> --target wasm-component --export <name> --out <component.wasm>\n" ++
  "  psc1 translate <input.lean|input.ps> --to <lean|ps> [--out <output>]\n" ++
  "  psc1 emit-lean <input.lean|input.ps> [--out <output.lean>]\n" ++
  "  psc1 emit-ps <input.lean|input.ps> [--out <output.ps>]\n" ++
  "  psc1 admissions <input.lean|input.ps>\n" ++
  "  psc1 typescript <input.lean|input.ps>\n" ++
  "  psc1 wat <input.wasm> --out <output.wat>\n" ++
  "Python/PHP require separately installed @proofscript/backend-python or @proofscript/backend-php. Direct builds require installed PSC1 host-tools; Rust also requires cargo/rustfmt, Wasm requires wasm-tools, Python requires Python >=3.14, PHP requires PHP >=8.5 with ext-gmp only for exact integers."

private def buildDefault (inputPath outputPath : String) : IO Unit := do
  if outputPath.endsWith ".js" then psHostDirectJavaScript inputPath outputPath
  else if outputPath.endsWith ".ts" then psHostDirectTypeScript inputPath outputPath
  else throw (IO.userError "PSC1_OUTPUT_EXTENSION: use --target for Rust, Wasm, Python or PHP")

/-- Parse the one explicit assurance option without changing command ordering.
Duplicate, incomplete and unknown requests fail before any output is staged. -/
private def psCliAssuranceArgs :
    List String → Option PsHostAssurance → List String →
    Except String (PsHostAssurance × List String)
  | [], assurance, reversed => .ok (assurance.getD .checked, reversed.reverse)
  | "--assurance" :: value :: rest, none, reversed =>
      if value == "ordinary" then psCliAssuranceArgs rest (some .ordinary) reversed
      else if value == "checked" then psCliAssuranceArgs rest (some .checked) reversed
      else if value == "verified" then psCliAssuranceArgs rest (some .verified) reversed
      else .error ("PSC1_ASSURANCE_UNKNOWN: " ++ value)
  | "--assurance" :: _, some _, _ => .error "PSC1_ASSURANCE_DUPLICATE"
  | ["--assurance"], none, _ => .error "PSC1_ASSURANCE_VALUE_REQUIRED"
  | argument :: rest, assurance, reversed =>
      psCliAssuranceArgs rest assurance (argument :: reversed)

private def buildFor
    (inputPath outputPath target : String) (assurance : PsHostAssurance) : IO Unit := do
  let some kind := psBackendTargetFromName target
    | throw (IO.userError ("PSC1_TARGET_UNKNOWN: " ++ target))
  if kind == .wasmComponent then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_REQUIRED: add --export <name>")
  let session ← psHostDirectPrepareFor inputPath assurance
  match kind with
  | .js => psHostDirectEmitJavaScript session outputPath
  | .ts => psHostDirectEmitTypeScript session outputPath
  | .rust => psHostDirectEmitRust session outputPath
  | .wasmCore => psHostDirectEmitWasmCore session outputPath
  | .python => psHostDirectEmitPython session outputPath
  | .php => psHostDirectEmitPhp session outputPath
  | .wasmComponent => throw (IO.userError "PSC1_COMPONENT_EXPORT_REQUIRED")

private def buildTargetsFor (inputPath outputDir targets : String)
    (assurance : PsHostAssurance) : IO Unit := do
  if targets != "ts,js" && targets != "js,ts" then
    throw (IO.userError "PSC1_TARGET_SET_UNSUPPORTED: combined target set must be ts,js")
  psHostDirectEmitEcmaPair (← psHostDirectPrepareFor inputPath assurance) outputDir

private def buildDefaultFor
    (inputPath outputPath : String) (assurance : PsHostAssurance) : IO Unit := do
  if outputPath.endsWith ".js" then buildFor inputPath outputPath "js" assurance
  else if outputPath.endsWith ".ts" then buildFor inputPath outputPath "ts" assurance
  else throw (IO.userError "PSC1_OUTPUT_EXTENSION: use --target for Rust, Wasm, Python or PHP")

private def psCliExecution
    (assurance : PsHostAssurance) (args : List String) : IO Unit := do
  if assurance == .verified then
    throw (IO.userError "PSC1_VERIFIED_EXECUTION_UNAVAILABLE: no behavioral certificate; no ordinary fallback")
  match args with
  | ["check", inputPath] => psHostDirectCheckFor inputPath assurance
  | ["admissions", inputPath] => psHostDirectAdmissionsFor inputPath assurance
  | ["typescript", inputPath] => IO.print (← psHostDirectTypeScriptSourceFor inputPath assurance)
  | ["build", inputPath, "--targets", targets, "--out-dir", outputDir] =>
      buildTargetsFor inputPath outputDir targets assurance
  | ["build", inputPath, "--target", "wasm-component", "--exports", exportsText, "--out", outputPath]
  | ["build", inputPath, "--target", "wasm-component", "--out", outputPath, "--exports", exportsText] =>
      psHostDirectEmitWasmComponents (← psHostDirectPrepareFor inputPath assurance)
        (exportsText.splitOn ",") outputPath
  | ["build", inputPath, "--target", "wasm-component", "--export", exportName, "--out", outputPath]
  | ["build", inputPath, "--target", "wasm-component", "--out", outputPath, "--export", exportName] =>
      psHostDirectEmitWasmComponent (← psHostDirectPrepareFor inputPath assurance) exportName outputPath
  | ["build", inputPath, "--target", target, "--out", outputPath] =>
      buildFor inputPath outputPath target assurance
  | ["build", inputPath, "--out", outputPath] | ["compile", inputPath, "--out", outputPath] =>
      buildDefaultFor inputPath outputPath assurance
  | _ => throw (IO.userError "PSC1_ASSURANCE_REQUIRES_EXECUTION_COMMAND: check, admissions, typescript, build or compile")


private def psCliCheckedExecution (args : List String) : IO Unit := do
  match args with
  | [] | ["--help"] | ["-h"] => IO.println psCliUsage
  | ["--version"] => IO.println ("PSC1 0.1.0-psc1.2 (checked native; Lean " ++ Lean.versionString ++ ")")
  | ["--identity"] =>
      IO.println ("{\"protocol\":\"psc1-native/1\",\"profile\":\"psc1-checked-direct/1\",\"lean\":\"" ++ Lean.versionString ++ "\",\"leanCommit\":\"" ++ Lean.githash ++ "\",\"targets\":" ++ psJsonArray (([PsBackendTarget.js, .ts, .rust, .wasmCore, .wasmComponent]).map (fun target => psJsonQuote (psBackendTargetName target))) ++ "}")
  | ["check", inputPath] => psHostDirectCheck inputPath
  | ["admissions", inputPath] => psHostDirectAdmissions inputPath
  | ["typescript", inputPath] => IO.print (← psHostDirectTypeScriptSource inputPath)
  | ["translate", inputPath, "--to", target] => psHostCompilerTranslate inputPath target
  | ["translate", inputPath, "--to", target, "--out", outputPath] =>
      psHostCompilerTranslateToFile inputPath target outputPath
  | ["emit-lean", inputPath] => psHostCompilerTranslate inputPath "lean"
  | ["emit-lean", inputPath, "--out", outputPath] => psHostCompilerTranslateToFile inputPath "lean" outputPath
  | ["emit-ps", inputPath] => psHostCompilerTranslate inputPath "ps"
  | ["emit-ps", inputPath, "--out", outputPath] => psHostCompilerTranslateToFile inputPath "ps" outputPath
  | ["build", inputPath, "--target", target, "--out", outputPath] =>
      buildFor inputPath outputPath target .checked
  | ["build", inputPath, "--targets", targets, "--out-dir", outputDir] =>
      buildTargetsFor inputPath outputDir targets .checked
  | ["build", inputPath, "--target", "wasm-component", "--exports", exportsText, "--out", outputPath]
  | ["build", inputPath, "--target", "wasm-component", "--out", outputPath, "--exports", exportsText] =>
      psHostDirectEmitWasmComponents (← psHostDirectPrepareFor inputPath .checked)
        (exportsText.splitOn ",") outputPath
  | ["build", inputPath, "--target", "wasm-component", "--export", exportName, "--out", outputPath]
  | ["build", inputPath, "--target", "wasm-component", "--out", outputPath, "--export", exportName] =>
      psHostDirectWasmComponent inputPath exportName outputPath
  | ["build", inputPath, "--out", outputPath] | ["compile", inputPath, "--out", outputPath] =>
      buildDefault inputPath outputPath
  | ["wat", binaryPath, "--out", watPath] => psHostWasmBinaryToWat binaryPath watPath
  | _ => throw (IO.userError psCliUsage)


private def psCliAbiArgs : List String → Option String → List String →
    Except String (String × List String)
  | [], abi, reversed => .ok (abi.getD "scalar", reversed.reverse)
  | "--abi" :: value :: rest, none, reversed =>
      if value == "scalar" || value == "io-dispatcher" || value == "wasm-string" then
        psCliAbiArgs rest (some value) reversed
      else .error ("PSC1_ABI_UNKNOWN: " ++ value)
  | "--abi" :: _, some _, _ => .error "PSC1_ABI_DUPLICATE"
  | ["--abi"], none, _ => .error "PSC1_ABI_VALUE_REQUIRED"
  | argument :: rest, abi, reversed => psCliAbiArgs rest abi (argument :: reversed)

private def psCliIoExecution (args : List String) (assurance : PsHostAssurance) : IO Unit := do
  if assurance == .verified then throw (IO.userError "PSC1_VERIFIED_EXECUTION_UNAVAILABLE")
  match args with
  | ["build", inputPath, "--target", target, "--out", outputPath] =>
      let some kind := psBackendTargetFromName target
        | throw (IO.userError "PSC1_TARGET_UNKNOWN")
      if kind == .wasmCore || kind == .wasmComponent then
        return (← psHostDirectEmitWasmString (← psHostDirectPrepareWasmFor inputPath assurance true)
          outputPath (kind == .wasmComponent))
      let session ← psHostDirectPrepareIoFor inputPath assurance
      match psHostDirectCheckPublicApi kind session with
      | .error reason => throw (IO.userError reason)
      | .ok _ => pure ()
      match kind with
      | .js => psHostDirectEmitJavaScript session outputPath
      | .ts => psHostDirectEmitTypeScript session outputPath
      | .rust => psHostDirectEmitRust session outputPath
      | .python => psHostDirectEmitPython session outputPath
      | .php => psHostDirectEmitPhp session outputPath
      | _ => throw (IO.userError "PSC1_IO_DISPATCHER_ABI_TARGET_UNSUPPORTED")
  | _ => throw (IO.userError "PSC1_IO_ABI_REQUIRES_EXPLICIT_BUILD_TARGET")

private def psCliWasmStringExecution (args : List String) (assurance : PsHostAssurance) : IO Unit := do
  if assurance == .verified then throw (IO.userError "PSC1_VERIFIED_EXECUTION_UNAVAILABLE")
  match args with
  | ["build", inputPath, "--target", target, "--out", outputPath] =>
      if target != "wasm-core" && target != "wasm-component" then
        throw (IO.userError "PSC1_WASM_STRING_ABI_TARGET_UNSUPPORTED")
      psHostDirectEmitWasmString (← psHostDirectPrepareWasmFor inputPath assurance false)
        outputPath (target == "wasm-component")
  | _ => throw (IO.userError "PSC1_WASM_STRING_REQUIRES_EXPLICIT_BUILD_TARGET")

def main (args : List String) : IO Unit := do
  if Lean.versionString != PsKernelLean.providerVersion || Lean.githash != PsKernelLean.providerCommit then
    throw (IO.userError "PSC1_NATIVE_LEAN_PIN_MISMATCH: compiler runtime does not match the native source pin")
  let (assurance, command) ← match psCliAssuranceArgs args none [] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let (abi, command) ← match psCliAbiArgs command none [] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  if abi == "wasm-string" then psCliWasmStringExecution command assurance
  else if abi == "io-dispatcher" then psCliIoExecution command assurance
  else if assurance == .checked then psCliCheckedExecution command
  else psCliExecution assurance command
