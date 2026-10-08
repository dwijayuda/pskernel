import Ps.BackendWasm.Validate
import Ps.BackendWasm.LiteralEvidence
import Ps.BackendWasm.Lower
import Ps.BackendWasm.Binary

def literalDeclaration (name : String) (kind : PsVerifiedIrPrimitiveType)
    (integer : PsVerifiedIrMachineIntegerType) (value : Int) : PsVerifiedIrDeclaration :=
  PsVerifiedIrDeclaration.mk name [] [] (PsVerifiedIrType.primitive kind)
    (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.machineInteger integer value))

def literalSource : PsSpecializedIrModule :=
  PsSpecializedIrModule.mk (PsVerifiedIrModule.mk [] [] [] [
    literalDeclaration "unsignedMax" .uint32 .uint32 4294967295,
    literalDeclaration "signedMin" .int32 .int32 (-2147483648),
    PsVerifiedIrDeclaration.mk "truth" [] [] (.primitive .bool) (.literal (.bool true))])

def literalAccepts (source : PsSpecializedIrModule) (target : PsWasmModule) : Bool :=
  match psWasmValidateSpecializedLiteralModule source target with
  | Except.ok _ => true
  | Except.error _ => false

def main (args : List String) : IO Unit := do
  if args == ["--expectation"] then
    match psWasmEncodeLiteralExpectation literalSource with
    | Except.error _ => throw (IO.userError "WASM_LITERAL_EXPECTATION_FAILED")
    | Except.ok text => IO.println text;
    return;
  let target ← match psWasmLowerSpecializedValidatedModule (PsWasmTargetProfile.mk .wasm32) literalSource with
    | Except.ok module => pure module
    | Except.error _ => throw (IO.userError "WASM_LITERAL_LOWER_FAILED");
  if args == ["--bytes"] then
    let bytes ← match psWasmEncodeModule target with
      | Except.ok value => pure value
      | Except.error _ => throw (IO.userError "WASM_LITERAL_ENCODE_FAILED");
    IO.println (String.intercalate "," (bytes.map fun byte => toString byte.toNat));
    return;
  let extra := PsWasmFunction.mk "extra" none [] [.i32] [] [.i32Const 9];
  let malformed := PsSpecializedIrModule.mk (PsVerifiedIrModule.mk [] [] [] [literalDeclaration "bad" .uint32 .uint32 (-1)]);
  let fake := PsWasmModule.mk [] [] [] [PsWasmFunction.mk "bad" none [] [.i32] [] [.i32Const (-1)]] [] [("bad", "bad")];
  let duplicateSource := PsSpecializedIrModule.mk { literalSource.raw with declarations := literalSource.raw.declarations ++ literalSource.raw.declarations };
  let duplicateTarget := { target with functions := target.functions ++ target.functions, exports := target.exports ++ target.exports };
  let cases : List (String × Bool) := [
    ("actual literal lowering", literalAccepts literalSource target),
    ("extra function", !literalAccepts literalSource { target with functions := extra :: target.functions }),
    ("extra export", !literalAccepts literalSource { target with exports := ("extra", "truth") :: target.exports }),
    ("duplicate source and target", !literalAccepts duplicateSource duplicateTarget),
    ("out of range forged source", !literalAccepts malformed fake),
    ("function reference", !literalAccepts literalSource { target with functionRefs := ["truth"] }),
    ("extra runtime type", !literalAccepts literalSource { target with functionTypes := [PsWasmFunctionType.mk "hidden" [] []] }),
    ("duplicate export names", !literalAccepts literalSource { target with exports := [("truth", "truth"), ("truth", "truth"), ("truth", "truth")] }),
    ("missing declaration", !literalAccepts literalSource { target with functions := [] }),
    ("redirected export", !literalAccepts literalSource { target with exports := [("unsignedMax", "truth"), ("signedMin", "signedMin"), ("truth", "truth")] })
  ];
  for entry in cases do
    if !entry.2 then throw (IO.userError ("PSC_WASM_LITERAL_SHAPE: FAIL " ++ entry.1));
  IO.println ("PSC_WASM_LITERAL_SHAPE: PASS (" ++ toString cases.length ++ " cases)")
