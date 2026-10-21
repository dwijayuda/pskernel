import Ps.Host.DirectBackend
import Ps.BackendWasm.StringComponent

def psHostDirectEmitWasmString (session : PsHostDirectPrepared)
    (outputPath : String) (component : Bool) : IO Unit := do
  if !outputPath.endsWith ".wasm" || !session.wasmStringAbi then
    throw (IO.userError "PSC1_WASM_STRING_PROFILE_REQUIRED")
  let schema <- match psWasmStringAbiMakePlan session.validated session.publicNames session.ioDispatcherAbi with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let plan <- match psBackendClosedPlan session.validated session.publicNames with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let lowered <- match psWasmLowerSpecializedModule { wordSize := .wasm32 } plan.raw with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_WASM_STRING_LOWER_FAILED: " ++ psHostWasmLowerErrorText error))
  let adapted <- match psWasmStringAbiAdapt schema plan lowered with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let selected := psWasmSelectRuntime adapted
  match psWasmIrValidateModule selected with
  | .error _ => throw (IO.userError "PSC1_WASM_STRING_SELECTED_IR_INVALID")
  | .ok _ => pure ()
  let binary <- match psWasmEncodeModule selected with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_WASM_STRING_BINARY_FAILED")
  let lifted <- if component then
      match psWasmStringAbiComponent plan schema selected with
      | .ok value => pure (some value)
      | .error reason => throw (IO.userError reason)
    else pure none
  let name := psHostArtifactFileName outputPath "module.wasm"
  let stem := (name.dropEnd 5).toString
  let target := if component then "wasm-component" else "wasm-core"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    match lifted with
    | none =>
        IO.FS.writeBinFile (stage / name) (ByteArray.mk binary.toArray)
    | some value =>
        IO.FS.writeBinFile (stage / name) (ByteArray.mk value.componentBytes.toArray)
        IO.FS.writeBinFile (stage / (stem ++ ".core.wasm")) (ByteArray.mk value.coreBytes.toArray)
        let _ <- psHostWasmTool #["validate", (stage / (stem ++ ".core.wasm")).toString] "STRING_CORE_VALIDATE"
        psHostWriteWat (stage / (stem ++ ".core.wasm")) (stage / (stem ++ ".core.wat"))
        IO.FS.writeFile (stage / (stem ++ ".wit")) value.wit
    let _ <- psHostWasmTool #["validate", (stage / name).toString] "STRING_VALIDATE"
    psHostWriteWat (stage / name) (stage / (stem ++ ".wat"))
    let runtime <- match psWasmRuntimeCanonicalSource selected with
      | .ok value => pure value
      | .error reason => throw (IO.userError reason)
    psHostWriteArtifactTargetPlans stage [
      psHostArtifactTargetPlanJson target name "psc1-wasm-runtime/1" runtime
        (psWasmRuntimeRequirements selected) [] "psc-wasm-ir-json/1:functions"]
    psHostPublishArtifactStage stage outputPath target
  IO.println ("PSC1_DIRECT_WASM_STRING: " ++ outputPath)
