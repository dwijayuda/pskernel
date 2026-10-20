import Ps.Host.DirectBackend
import Ps.BackendWasm.Component

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
  psWasmComponentWitIdent name

def psHostWitArgument (parameter : PsVerifiedIrParameter) : Except String String := do
  if !psHostWitIdent parameter.name then throw "PSC1_COMPONENT_WIT_ARGUMENT_NAME_UNSUPPORTED"
  let type <- psHostWitScalarType parameter.type
  return parameter.name ++ ": " ++ type

def psHostWitSelectedExport (ir : PsValidatedIrModule) (name : String) : Except String String := do
  psWasmComponentWit (<- psWasmComponentMakePlan ir [name])

def psHostDirectEmitWasmComponent
    (session : PsHostDirectPrepared) (exportName outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".wasm" then throw (IO.userError "PSC1_COMPONENT_OUTPUT_EXTENSION")
  if !session.publicNames.contains exportName then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_NOT_IN_ENTRY_SOURCE")
  let componentPlan <- match psWasmComponentMakePlan session.validated [exportName] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let plan <- match psBackendClosedPlan session.validated [exportName] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let lowered <- match psWasmLowerSpecializedModule { wordSize := PsWasmWordSize.wasm32 } plan.raw with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_COMPONENT_LOWER_UNSUPPORTED: " ++ psHostWasmLowerErrorText error))
  if !lowered.exports.any (fun item => item.1 == exportName) then
    throw (IO.userError "PSC1_COMPONENT_EXPORT_NOT_LOWERED")
  let selected := psWasmSelectRuntime { lowered with exports := lowered.exports.filter (fun item => item.1 == exportName) }
  let emitted <- match psWasmComponentEmit componentPlan selected with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let name := psHostArtifactFileName outputPath "module.wasm"
  let stem := (name.dropEnd 5).toString
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteSelectedProvenance session stage [exportName]
    let core := stage / (stem ++ ".core.wasm")
    let witPath := stage / (stem ++ ".wit")
    let component := stage / name
    let observed := stage / "temporary.observed.wit"
    IO.FS.writeBinFile core (ByteArray.mk emitted.coreBytes.toArray)
    IO.FS.writeFile witPath emitted.wit
    IO.FS.writeBinFile component (ByteArray.mk emitted.componentBytes.toArray)
    let _ <- psHostWasmTool #["validate", core.toString] "CORE_VALIDATE"
    psHostWriteWat core (stage / (stem ++ ".core.wat"))
    let _ <- psHostWasmTool #["validate", component.toString] "COMPONENT_VALIDATE"
    psHostWriteWat component (stage / (stem ++ ".wat"))
    let observedWit <- psHostWasmTool #["component", "wit", component.toString] "WIT_OBSERVE"
    IO.FS.writeFile observed observedWit
    let _ <- psHostArtifactTool #["wit-check", witPath.toString, observed.toString]
    IO.FS.removeFile observed
    let runtime <- match psWasmRuntimeCanonicalSource selected with
      | .ok value => pure value
      | .error reason => throw (IO.userError reason)
    psHostWriteArtifactTargetPlans stage [
      psHostArtifactTargetPlanJson "wasm-component" name "psc1-wasm-runtime/1"
        runtime (psWasmRuntimeRequirements selected) [] "psc-wasm-ir-json/1:functions"]
    psHostPublishArtifactStage stage outputPath "wasm-component"
  IO.println ("PSC1_COMPONENT_WASM: " ++ outputPath)

def psHostDirectWasmComponent
    (inputPath exportName outputPath : String) : IO Unit := do
  psHostDirectEmitWasmComponent (<- psHostDirectPrepare inputPath) exportName outputPath

