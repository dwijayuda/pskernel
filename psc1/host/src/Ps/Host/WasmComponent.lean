import Ps.Host.DirectBackend

-- A physical WIT representation is not permission to export a capability. First
-- enforce the same active scalar contract as the independent typed-IR checker.
-- Today only Bool intersects that contract and the bounded scalar WIT ABI.
-- Integer/float representations are retained for explicit future qualification,
-- not advertised as usable current source-language features.
def psHostWitScalarType (type : PsVerifiedIrType) : Except String String := do
  let .primitive primitive := type
    | throw "PSC1_COMPONENT_WIT_TYPE_UNSUPPORTED"
  match psIrCheckPrimitive primitive with
  | .error issue =>
      throw ("PSC1_COMPONENT_SCALAR_PROFILE_UNQUALIFIED: " ++ issue.detail)
  | .ok _ => pure ()
  match primitive with
  | .bool => return "bool"
  | .uint8 => return "u8"
  | .uint16 => return "u16"
  | .uint32 => return "u32"
  | .uint64 => return "u64"
  | .int8 => return "s8"
  | .int16 => return "s16"
  | .int32 => return "s32"
  | .int64 => return "s64"
  | .float => return "f64"
  | .float32 => return "f32"
  | _ => throw "PSC1_COMPONENT_WIT_TYPE_UNSUPPORTED"

def psHostWitIdent (name : String) : Bool :=
  let lower := fun (c : Char) => Nat.ble 97 c.toNat && Nat.ble c.toNat 122
  let digit := fun (c : Char) => Nat.ble 48 c.toNat && Nat.ble c.toNat 57
  let validPart := fun (part : String) => match part.toList with
    | [] => false
    | first :: rest => lower first && rest.all (fun c => lower c || digit c)
  let reserved := ["world", "interface", "package", "export", "import", "use", "type",
    "func", "record", "variant", "resource", "constructor", "static", "bool", "string",
    "char", "u8", "u16", "u32", "u64", "s8", "s16", "s32", "s64", "f32", "f64"]
  !reserved.contains name && (name.splitOn "-").all validPart

def psHostWitArgument (parameter : PsVerifiedIrParameter) : Except String String := do
  if !psHostWitIdent parameter.name then throw "PSC1_COMPONENT_WIT_ARGUMENT_NAME_UNSUPPORTED"
  let type ← psHostWitScalarType parameter.type
  return parameter.name ++ ": " ++ type

def psHostWitSelectedExport (ir : PsValidatedIrModule) (name : String) : Except String String := do
  if !psHostWitIdent name then throw "PSC1_COMPONENT_WIT_EXPORT_NAME_UNSUPPORTED"
  let some declaration := ir.raw.declarations.find? (fun d => d.name == name)
    | throw "PSC1_COMPONENT_WIT_EXPORT_UNKNOWN"
  if !declaration.typeParameters.isEmpty then throw "PSC1_COMPONENT_WIT_GENERIC_EXPORT_UNSUPPORTED"
  let parameters ← declaration.parameters.mapM psHostWitArgument
  let result ← psHostWitScalarType declaration.resultType
  return "package proofscript:psc1;\n\nworld app {\n  export " ++ name ++
    ": func(" ++ String.intercalate ", " parameters ++ ") -> " ++ result ++ ";\n}\n"

def psHostDirectEmitWasmComponent
    (session : PsHostDirectPrepared) (exportName outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".wasm" then throw (IO.userError "PSC1_COMPONENT_OUTPUT_EXTENSION")
  if !session.publicNames.contains exportName then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_NOT_IN_ENTRY_SOURCE")
  let wit ← match psHostWitSelectedExport session.validated exportName with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let lowered ← match psWasmLowerValidatedModule { wordSize := PsWasmWordSize.wasm32 } session.validated with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_COMPONENT_LOWER_UNSUPPORTED: " ++ psHostWasmLowerErrorText error))
  if !lowered.exports.any (fun item => item.1 == exportName) then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_NOT_LOWERED")
  let selected := { lowered with exports := lowered.exports.filter (fun item => item.1 == exportName) }
  let bytes ← match psWasmEncodeModule selected with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_COMPONENT_BINARY_UNSUPPORTED")
  let name := psHostArtifactFileName outputPath "module.wasm"
  let stem := (name.dropEnd 5).toString
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteSelectedProvenance session stage [exportName]
    let core := stage / (stem ++ ".core.wasm")
    let witPath := stage / (stem ++ ".wit")
    let embedded := stage / "temporary.embedded.wasm"
    let component := stage / name
    let observed := stage / "temporary.observed.wit"
    IO.FS.writeBinFile core (ByteArray.mk bytes.toArray)
    IO.FS.writeFile witPath wit
    let _ ← psHostWasmTool #["validate", core.toString] "CORE_VALIDATE"
    psHostWriteWat core (stage / (stem ++ ".core.wat"))
    let _ ← psHostWasmTool #["component", "embed", witPath.toString, "--world", "app",
      core.toString, "-o", embedded.toString] "WIT_EMBED"
    let _ ← psHostWasmTool #["component", "new", embedded.toString, "-o", component.toString] "COMPONENT_NEW"
    let _ ← psHostWasmTool #["validate", component.toString] "COMPONENT_VALIDATE"
    psHostWriteWat component (stage / (stem ++ ".wat"))
    let observedWit ← psHostWasmTool #["component", "wit", component.toString] "WIT_OBSERVE"
    IO.FS.writeFile observed observedWit
    let _ ← psHostArtifactTool #["wit-check", witPath.toString, observed.toString]
    IO.FS.removeFile embedded
    IO.FS.removeFile observed
    psHostPublishArtifactStage stage outputPath "wasm-component"
  IO.println ("PSC1_COMPONENT_WASM: " ++ outputPath)

def psHostDirectWasmComponent
    (inputPath exportName outputPath : String) : IO Unit := do
  psHostDirectEmitWasmComponent (← psHostDirectPrepare inputPath) exportName outputPath
