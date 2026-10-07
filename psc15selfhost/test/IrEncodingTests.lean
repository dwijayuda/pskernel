import Ps.DriverTs.Stages
import Ps.DriverJs.Stages
import Ps.DriverWasm.Stages
import Ps.CompilerIr.InterfaceArtifact

def psIrEncodingFixture : PsVerifiedIrModule :=
  PsVerifiedIrModule.mk [] [] [] [
    PsVerifiedIrDeclaration.mk "huge" [] [] (.primitive .nat)
      (.literal (.natural 123456789012345678901234567890)),
    PsVerifiedIrDeclaration.mk "negative" [] [] (.primitive .int) (.literal (.integer (-123))),
    PsVerifiedIrDeclaration.mk "unicode" [] [] (.primitive .string) (.literal (.string "a\n\"😀")),
    PsVerifiedIrDeclaration.mk "unknown" [] [] .unknown (.var "unresolved")]

def main (args : List String) : IO Unit := do
  if args == ["--raw"] then
    match psIrEncodeModule psIrEncodingFixture with
    | .error _ => throw (IO.userError "IR_ENCODE_FAILED")
    | .ok encoded => IO.println encoded
  else if args == ["--interface"] then
    let .ok prepared := psCompilerPrepareSource .lean "def answer : Nat := 42\n"
      | throw (IO.userError "PREPARE_FAILED")
    let .ok validated := psCompilerVerifiedIrFromPrepared prepared
      | throw (IO.userError "VALIDATION_FAILED")
    let .ok interface := psIrEncodeRuntimeInterface validated
      | throw (IO.userError "INTERFACE_FAILED")
    IO.println interface
  else if args == ["--js-stages"] then
    let source := "def forward (A : Type) (value : A) : A := value\ndef answer : Nat := forward Nat 42\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "PREPARE_FAILED")
    let .ok staged := psCompilerJavaScriptStagesFromPrepared prepared
      | throw (IO.userError "JS_STAGES_FAILED")
    let .ok legacy := psCompilerJavaScriptFromPrepared prepared
      | throw (IO.userError "JS_LEGACY_FAILED")
    if legacy != staged.javaScript || staged.runtimeIr != staged.verifiedIr then
      throw (IO.userError "JS_STAGES_CHANGED_OUTPUT")
    IO.println (psJsonObject [
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("javaScript", psJsonQuote staged.javaScript),
      ("verifiedIr", psJsonQuote staged.verifiedIr),
      ("specializedIr", psJsonQuote staged.specializedIr)])
  else if args == ["--wasm-stages"] then
    let source := "def forward (A : Type) (value : A) : A := value\ndef answer (value : UInt32) : UInt32 := forward UInt32 value\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "PREPARE_FAILED")
    let .ok staged := psCompilerWasmStagesFromPrepared psCompilerWasm32Target prepared
      | throw (IO.userError "WASM_STAGES_FAILED")
    let .ok legacy := psCompilerWasmFromPrepared psCompilerWasm32Target prepared
      | throw (IO.userError "WASM_LEGACY_FAILED")
    if legacy != staged.wasm || staged.runtimeIr != staged.verifiedIr then
      throw (IO.userError "WASM_STAGES_CHANGED_OUTPUT")
    IO.println (psJsonObject [
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("wasm", psJsonArray (staged.wasm.map (fun byte => toString byte.toNat))),
      ("verifiedIr", psJsonQuote staged.verifiedIr),
      ("specializedIr", psJsonQuote staged.specializedIr)])
  else if args == ["--stages"] then
    let .ok prepared := psCompilerPrepareSource .lean "def answer : Nat := 42\n"
      | throw (IO.userError "PREPARE_FAILED")
    let .ok staged := psCompilerTypeScriptStagesFromPrepared prepared
      | throw (IO.userError "STAGES_FAILED")
    let .ok legacy := psCompilerTypeScriptFromPrepared prepared
      | throw (IO.userError "LEGACY_FAILED")
    if legacy != staged.typeScript || staged.runtimeIr != staged.verifiedIr then
      throw (IO.userError "STAGES_CHANGED_OUTPUT")
    IO.println (psJsonObject [
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("typeScript", psJsonQuote staged.typeScript),
      ("verifiedIr", psJsonQuote staged.verifiedIr)])
  else
    match psIrJsonExprWithFuel 0 (.literal .unit), psIrJsonTypeWithFuel 0 .unknown with
    | .error .depthExhausted, .error .depthExhausted => IO.println "PSCV_IR_ENCODING_DEPTH: PASS"
    | _, _ => throw (IO.userError "IR_DEPTH_NOT_ENFORCED")
