import Ps.CompilerIr.JsAbi
import Ps.CompilerIr.Encode
import Ps.BackendJs.Print

def psJsAbiTestPrimitives : List PsVerifiedIrPrimitiveType :=
  [.nat, .int, .uint8, .uint16, .uint32, .uint64, .usize, .int8, .int16, .int32,
   .int64, .isize, .float, .float32, .bool, .char, .string, .unit]

def psJsAbiTestImport (primitive : PsVerifiedIrPrimitiveType) : PsVerifiedIrExternalImport :=
  let name := psJsAbiPrimitiveName primitive;
  let type := PsVerifiedIrType.primitive primitive;
  PsVerifiedIrExternalImport.mk name "host" name (.function [type] type)

def psJsAbiTestExport (primitive : PsVerifiedIrPrimitiveType) : PsInterfaceIrExport :=
  let type := PsVerifiedIrType.primitive primitive;
  PsInterfaceIrExport.mk (psJsAbiPrimitiveName primitive) (.function [type] type)

def psJsAbiTestHost : PsInterfaceIrContract :=
  PsInterfaceIrContract.mk "host" "psc-runtime-semantics/1" "psc-runtime-values/1"
    ["javascript"] ["host-call"] (.host "fixture-host-functions") [] []
    (psListMap psJsAbiTestExport psJsAbiTestPrimitives)

def psJsAbiTestPolicy : PsInterfaceIrPolicy := .mk "javascript" ["host-call"]

def psJsAbiTestModule : PsErasedIrModule :=
  let type := PsVerifiedIrType.primitive .uint32;
  .mk (.mk (psListMap psJsAbiTestImport psJsAbiTestPrimitives) [] []
    [.mk "roundTrip" [] [.mk "value" type] type (.call (.var "uint32") [] [.var "value"])])

def psJsAbiTestPlan (bits : Nat) : Except PsJsAbiError String :=
  psJsAbiPlan psJsAbiTestPolicy bits [psJsAbiTestHost] psJsAbiTestModule

def psJsAbiTestReject (value : Except PsJsAbiError String) : Bool :=
  match value with
  | .error _ => true
  | .ok _ => false

def psJsAbiTestUnsupported : Bool :=
  let type := PsVerifiedIrType.named "Array" [.primitive .nat];
  let provider := { psJsAbiTestHost with exports := [.mk "array" (.function [type] type)] };
  let module := PsErasedIrModule.mk (.mk [.mk "array" "host" "array" (.function [type] type)] [] [] []);
  psJsAbiTestReject (psJsAbiPlan psJsAbiTestPolicy 64 [provider] module)

def psJsAbiTestInvalidBody : Bool :=
  let bad := PsVerifiedIrDeclaration.mk "bad" [] [] (.primitive .bool) (.literal (.natural 0));
  let erased := PsErasedIrModule.mk (PsVerifiedIrModule.mk [] [] [] [bad]);
  psJsAbiTestReject (psJsAbiPlan psJsAbiTestPolicy 64 [psJsAbiTestHost] erased)

def psJsAbiTestCases : List (String × Bool) :=
  [("scalar plan", match psJsAbiTestPlan 64 with | .ok _ => true | _ => false),
   ("32 bit profile", match psJsAbiTestPlan 32 with | .ok _ => true | _ => false),
   ("invalid word profile", psJsAbiTestReject (psJsAbiTestPlan 16)),
   ("wrong target", psJsAbiTestReject (psJsAbiPlan (.mk "rust" ["host-call"]) 64 [psJsAbiTestHost] psJsAbiTestModule)),
   ("capability denied", psJsAbiTestReject (psJsAbiPlan (.mk "javascript" []) 64 [psJsAbiTestHost] psJsAbiTestModule)),
   ("missing interface", psJsAbiTestReject (psJsAbiPlan psJsAbiTestPolicy 64 [] psJsAbiTestModule)),
   ("aggregate unsupported", psJsAbiTestUnsupported),
   ("body freshly checked", psJsAbiTestInvalidBody)]

def main (args : List String) : IO Unit := do
  if args == ["--plan"] || args == ["--plan32"] then
    match psJsAbiTestPlan (if args == ["--plan32"] then 32 else 64) with
    | .error _ => throw (IO.userError "ABI_PLAN_FAILED")
    | .ok plan => IO.println plan
  else if args == ["--ir"] then
    match psIrEncodeModule psJsAbiTestModule.raw with
    | .error _ => throw (IO.userError "ABI_IR_FAILED")
    | .ok encoded => IO.println encoded
  else if args == ["--js"] then
    -- Actual compiled scalar client for runtime adapter integration. The
    -- broader all-scalar plan is tested separately, including target words.
    let raw := psJsAbiTestModule.raw;
    let module := PsErasedIrModule.mk { raw with imports := [psJsAbiTestImport .uint32] };
    match psValidateErasedIrModuleWithInterfaces psJsAbiTestPolicy [psJsAbiTestHost] module with
    | .error _ => throw (IO.userError "ABI_MODULE_INVALID")
    | .ok validated =>
        match psJsLowerValidatedModule validated with
        | .error _ => throw (IO.userError "ABI_JS_LOWER_FAILED")
        | .ok lowered =>
            match psJsPrintModule lowered with
            | .error _ => throw (IO.userError "ABI_JS_PRINT_FAILED")
            | .ok source => IO.println source
  else
    for (name, passed) in psJsAbiTestCases do
      if passed then IO.println ("PSCV_JS_ABI_PASS: " ++ name)
      else throw (IO.userError ("PSCV_JS_ABI_FAIL: " ++ name))
    IO.println "PSCV_JS_ABI_TESTS: PASS"
