import Ps.Host.DirectBackend

-- Initial checked public WIT profile: fixed-width scalars and Booleans only.
-- Nat, Int, String, generic/recursive/functional values have no implicit
-- canonical component ABI. They remain unsupported until adapters are qualified.
def psHostWitScalarType : PsVerifiedIrType → Except String String
  | .primitive .bool => .ok "bool"
  | .primitive .uint8 => .ok "u8"
  | .primitive .uint16 => .ok "u16"
  | .primitive .uint32 => .ok "u32"
  | .primitive .uint64 => .ok "u64"
  | .primitive .int8 => .ok "s8"
  | .primitive .int16 => .ok "s16"
  | .primitive .int32 => .ok "s32"
  | .primitive .int64 => .ok "s64"
  | .primitive .float => .ok "f64"
  | .primitive .float32 => .ok "f32"
  | _ => .error "PSC1_COMPONENT_WIT_TYPE_UNSUPPORTED"

def psHostWitIdent (name : String) : Bool :=
  match name.toList with
  | [] => false
  | first :: rest =>
      let lower := fun c => Nat.ble 97 c.toNat && Nat.ble c.toNat 122
      let digit := fun c => Nat.ble 48 c.toNat && Nat.ble c.toNat 57
      lower first && rest.all (fun c => lower c || digit c || c == '-')

def psHostWitArgument (parameter : PsVerifiedIrParameter) : Except String String := do
  if !psHostWitIdent parameter.name then
    throw "PSC1_COMPONENT_WIT_ARGUMENT_NAME_UNSUPPORTED"
  let ty ← psHostWitScalarType parameter.type
  return parameter.name ++ ": " ++ ty

-- Canonicalize only trivia; signature identity and scalar types remain exact.
def psHostWitWithoutWhitespace (value : String) : String :=
  String.ofList (value.toList.filter (fun c =>
    c != ' ' && c != '\n' && c != '\r' && c != '\t'))

def psHostWitSelectedExport (ir : PsValidatedIrModule) (name : String) :
    Except String String := do
  if !psHostWitIdent name then
    throw "PSC1_COMPONENT_WIT_EXPORT_NAME_UNSUPPORTED"
  let some declaration := ir.raw.declarations.find? (fun d => d.name == name)
    | throw "PSC1_COMPONENT_WIT_EXPORT_UNKNOWN"
  if !declaration.typeParameters.isEmpty then
    throw "PSC1_COMPONENT_WIT_GENERIC_EXPORT_UNSUPPORTED"
  let parameters ← declaration.parameters.mapM psHostWitArgument
  let result ← psHostWitScalarType declaration.resultType
  return "package proofscript:psc1;\n\nworld app {\n  export " ++ name ++
    ": func(" ++ String.intercalate ", " parameters ++ ") -> " ++ result ++ ";\n}\n"

def psHostWasmTool (arguments : Array String) (phase : String) : IO String := do
  let output ← IO.Process.output { cmd := "wasm-tools", args := arguments }
  if output.exitCode != 0 then
    throw (IO.userError ("PSC1_COMPONENT_" ++ phase ++ "_FAILED: " ++ output.stderr))
  return output.stdout

-- Construct and validate the entire component output in a private staging
-- directory before exposing any official output. The core binary is built from
-- the same checked/validated module used to plan the public interface.
def psHostDirectWasmComponent
    (inputPath exportName outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".wasm" then
    throw (IO.userError "PSC1_COMPONENT_OUTPUT_EXTENSION: expected .wasm")
  let prepared ← psHostDirectPrepare inputPath
  let validated := prepared.validated
  -- The selected export is explicitly authored in this entry source.
  if !prepared.sourceModule.declarations.any
      (fun d => psHostSyntaxDeclarationName d == exportName) then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_NOT_IN_ENTRY_SOURCE")
  let wit ← match psHostWitSelectedExport validated exportName with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let lowered ← match psWasmLowerValidatedModule
      { wordSize := PsWasmWordSize.wasm32 } validated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_COMPONENT_LOWER_UNSUPPORTED")
  if !lowered.exports.any (fun e => e.1 == exportName) then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_NOT_LOWERED")
  let bytes ← match psWasmEncodeModule lowered with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_COMPONENT_BINARY_UNSUPPORTED")
  psHostDirectEnsureParent outputPath
  let stageDir : System.FilePath := System.FilePath.mk (outputPath ++ ".psc1-stage")
  if ← stageDir.pathExists then
    throw (IO.userError "PSC1_COMPONENT_STAGE_EXISTS")
  IO.FS.createDirAll stageDir
  let stagedCore := stageDir / "module.core.wasm"
  let stagedCoreWat := stageDir / "module.core.wat"
  let stagedWit := stageDir / "module.wit"
  let stagedEmbedded := stageDir / "module.embedded.wasm"
  let stagedComponent := stageDir / "module.wasm"
  let stagedComponentWat := stageDir / "module.wat"
  try
    IO.FS.writeBinFile stagedCore (ByteArray.mk bytes.toArray)
    IO.FS.writeFile stagedWit wit
    let _ ← psHostWasmTool #["validate", stagedCore.toString] "CORE_VALIDATE"
    psHostWasmBinaryToWat stagedCore.toString stagedCoreWat.toString
    let _ ← psHostWasmTool #[
      "component", "embed", stagedWit.toString, "--world", "app",
      stagedCore.toString, "-o", stagedEmbedded.toString] "WIT_EMBED"
    let _ ← psHostWasmTool #[
      "component", "new", stagedEmbedded.toString,
      "-o", stagedComponent.toString] "GENERATE"
    let _ ← psHostWasmTool #["validate", stagedComponent.toString] "VALIDATE"
    psHostWasmBinaryToWat stagedComponent.toString stagedComponentWat.toString
    let observedWit ← psHostWasmTool #["component", "wit", stagedComponent.toString] "WIT_CHECK"
    let some exportRest := (wit.splitOn "export ")[1]? |
      throw (IO.userError "PSC1_COMPONENT_WIT_EXPECTED_EXPORT_MISSING")
    let some signature := (exportRest.splitOn ";")[0]? |
      throw (IO.userError "PSC1_COMPONENT_WIT_EXPECTED_SIGNATURE_MISSING")
    let exactExport := psHostWitWithoutWhitespace ("export " ++ signature ++ ";")
    let canonicalObserved := psHostWitWithoutWhitespace observedWit
    if (canonicalObserved.splitOn exactExport).length <= 1 then
      throw (IO.userError "PSC1_COMPONENT_WIT_SIGNATURE_MISMATCH")
    let stem := outputPath.dropRight 5
    IO.FS.rename stagedCore (System.FilePath.mk (stem ++ ".core.wasm"))
    IO.FS.rename stagedCoreWat (System.FilePath.mk (stem ++ ".core.wat"))
    IO.FS.rename stagedWit (System.FilePath.mk (stem ++ ".wit"))
    IO.FS.rename stagedComponentWat (System.FilePath.mk (stem ++ ".wat"))
    IO.FS.rename stagedComponent (System.FilePath.mk outputPath)
    IO.println ("PSC1_COMPONENT_WASM: " ++ outputPath)
    IO.println ("PSC1_COMPONENT_WIT: " ++ stem ++ ".wit")
    IO.println ("PSC1_COMPONENT_WAT: " ++ stem ++ ".wat")
  finally
    IO.FS.removeDirAll stageDir
