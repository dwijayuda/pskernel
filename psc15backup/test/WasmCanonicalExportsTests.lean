import Ps.DriverWasm.Compiler
import Ps.CompilerIr.Encode
import Ps.BackendWasm.Encode

def canonicalEcho (name : String) (type : PsVerifiedIrPrimitiveType) : PsVerifiedIrDeclaration :=
  PsVerifiedIrDeclaration.mk name [] [PsVerifiedIrParameter.mk "internal_parameter" (.primitive type)]
    (.primitive type) (.var "internal_parameter")

def canonicalLess (name : String) (type : PsVerifiedIrPrimitiveType)
    (integer : PsVerifiedIrMachineIntegerType) : PsVerifiedIrDeclaration :=
  PsVerifiedIrDeclaration.mk name [] [PsVerifiedIrParameter.mk "x" (.primitive type)]
    (.primitive .bool) (.intrinsic (.machineIntCompare integer .lt) []
      [.var "x", .literal (.machineInteger integer 0)])

def canonicalDeclarations : List PsVerifiedIrDeclaration := [
  canonicalEcho "Source.u8" .uint8, canonicalEcho "Source.u16" .uint16,
  canonicalEcho "Source.u32" .uint32, canonicalEcho "Source.u64" .uint64,
  canonicalEcho "Source.s8" .int8, canonicalEcho "Source.s16" .int16,
  canonicalEcho "Source.s32" .int32, canonicalEcho "Source.s64" .int64,
  canonicalEcho "Source.word" .usize, canonicalEcho "Source.sword" .isize,
  canonicalEcho "Source.f32" .float32, canonicalEcho "Source.f64" .float,
  canonicalEcho "Source.boolean" .bool, canonicalEcho "Source.letter" .char,
  canonicalLess "Source.negative8" .int8 .int8,
  canonicalLess "Source.negative16" .int16 .int16,
  PsVerifiedIrDeclaration.mk "Source.done" [] [] (.primitive .unit) (.literal .unit),
  PsVerifiedIrDeclaration.mk "Source.hidden" [] [] (.primitive .string) (.literal (.string "private"))]

def canonicalSource : PsSpecializedIrModule :=
  PsSpecializedIrModule.mk (PsVerifiedIrModule.mk [] [] [] canonicalDeclarations)

def canonicalSelection : PsWasmCanonicalSelection :=
  PsWasmCanonicalSelection.mk "psc" "scalar" "world" "api" [
    PsWasmCanonicalExport.mk "Source.u8" "echo-u8", PsWasmCanonicalExport.mk "Source.u16" "echo-u16",
    PsWasmCanonicalExport.mk "Source.u32" "echo-u32", PsWasmCanonicalExport.mk "Source.u64" "echo-u64",
    PsWasmCanonicalExport.mk "Source.s8" "echo-s8", PsWasmCanonicalExport.mk "Source.s16" "echo-s16",
    PsWasmCanonicalExport.mk "Source.s32" "echo-s32", PsWasmCanonicalExport.mk "Source.s64" "echo-s64",
    PsWasmCanonicalExport.mk "Source.word" "echo-word", PsWasmCanonicalExport.mk "Source.sword" "echo-sword",
    PsWasmCanonicalExport.mk "Source.f32" "echo-f32", PsWasmCanonicalExport.mk "Source.f64" "echo-f64",
    PsWasmCanonicalExport.mk "Source.boolean" "echo-bool", PsWasmCanonicalExport.mk "Source.letter" "echo-char",
    PsWasmCanonicalExport.mk "Source.negative8" "negative-eight",
    PsWasmCanonicalExport.mk "Source.negative16" "negative-sixteen",
    PsWasmCanonicalExport.mk "Source.done" "done"]

def canonicalAccepts (source : PsSpecializedIrModule) (selection : PsWasmCanonicalSelection) : Bool :=
  match psWasmCompileCanonicalExports (PsWasmTargetProfile.mk .wasm32) selection source with
  | Except.ok _ => true
  | Except.error _ => false

def canonicalSingle (declaration : PsVerifiedIrDeclaration) : PsSpecializedIrModule :=
  PsSpecializedIrModule.mk (PsVerifiedIrModule.mk [] [] [] [declaration])

def canonicalOnly (source : String) (foreign : String := "selected") : PsWasmCanonicalSelection :=
  { canonicalSelection with exports := [PsWasmCanonicalExport.mk source foreign] }

def canonicalMany (count : Nat) : PsVerifiedIrDeclaration :=
  let parameters := (List.range count).map fun i => PsVerifiedIrParameter.mk ("x" ++ toString i) (.primitive .uint8);
  PsVerifiedIrDeclaration.mk "many" [] parameters (.primitive .uint8) (.var "x0")

def canonicalRequestAccepts (wire : String) : Bool :=
  match psWasmCanonicalDecodeRequest wire with
  | Except.ok _ => true
  | Except.error _ => false

def canonicalRequestChecks : IO Unit := do
  let request := PsWasmCanonicalRequest.mk (PsWasmTargetProfile.mk .wasm64) canonicalSelection
  let wire := psWasmCanonicalEncodeRequest request
  let .ok decoded := psWasmCanonicalDecodeRequest wire
    | throw (IO.userError "PSC_WASM_CANONICAL_REQUEST_ROUNDTRIP")
  if psWasmCanonicalEncodeRequest decoded != wire then
    throw (IO.userError "PSC_WASM_CANONICAL_REQUEST_BYTES")
  for bad in [wire ++ " ", "[[[[]]]]", "{}", wire.replace "\"64\"" "64",
      wire.replace "\"64\"" "\"064\"", wire.replace "psc-wasm-canonical-request/1" "unknown/1",
      psWasmCanonicalEncodeRequest { request with selection := { canonicalSelection with exports := [] } },
      psWasmCanonicalEncodeRequest { request with selection := { canonicalSelection with
        exports := List.replicate 1025 (PsWasmCanonicalExport.mk "Source.u8" "echo") } },
      psWasmCanonicalEncodeRequest { request with selection := { canonicalSelection with
        exports := [PsWasmCanonicalExport.mk (String.ofList (List.replicate 4097 'a')) "echo"] } }] do
    if canonicalRequestAccepts bad then throw (IO.userError "PSC_WASM_CANONICAL_REQUEST_ACCEPTED_INVALID")
  if !psJsonArrayRequestWithinLimits 80 3 3 "[\"[{}]\\\"\",[[]]]" ||
      psJsonArrayRequestWithinLimits 80 2 3 "[[[]]]" ||
      psJsonArrayRequestWithinLimits 80 3 2 "[[],[]]" then
    throw (IO.userError "PSC_JSON_ARRAY_REQUEST_PREFLIGHT")
  IO.println "PSC_WASM_CANONICAL_REQUEST: PASS"

def main (args : List String) : IO Unit := do
  if args == ["--prepared32"] || args == ["--prepared64"] then
    let width := if args == ["--prepared64"] then PsWasmWordSize.wasm64 else PsWasmWordSize.wasm32
    let source := "def echoWord (value : USize) : USize := value\ndef hidden (value : UInt32) : UInt32 := value\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "PSC_WASM_CANONICAL_PREPARE")
    let request := PsWasmCanonicalRequest.mk (PsWasmTargetProfile.mk width)
      (PsWasmCanonicalSelection.mk "psc" "prepared" "world" "api"
        [PsWasmCanonicalExport.mk "echoWord" "echo-word"])
    let wire := psWasmCanonicalEncodeRequest request
    let .ok staged := psCompilerWasmCanonicalStagesFromPrepared wire prepared
      | throw (IO.userError "PSC_WASM_CANONICAL_PREPARED_STAGES")
    if staged.runtimeIr != staged.verifiedIr then throw (IO.userError "PSC_WASM_CANONICAL_CHANGED_IR")
    IO.println (psJsonObject [
      ("wire", psJsonQuote wire), ("source", psJsonQuote source),
      ("binary", psJsonArray (staged.wasm.map fun byte => toString byte.toNat)),
      ("runtimeIr", psJsonQuote staged.runtimeIr), ("verifiedIr", psJsonQuote staged.verifiedIr),
      ("specializedIr", psJsonQuote staged.specializedIr), ("wasmIr", psJsonQuote staged.wasmIr),
      ("erasureCorrespondence", psJsonQuote staged.erasureCorrespondence),
      ("interfaceJson", psJsonQuote staged.interfaceJson), ("bindingJson", psJsonQuote staged.bindingJson)])
    return
  if args == ["--fixture32"] || args == ["--fixture64"] then
    let width := if args == ["--fixture64"] then PsWasmWordSize.wasm64 else PsWasmWordSize.wasm32;
    match psWasmCompileCanonicalExports (PsWasmTargetProfile.mk width) canonicalSelection canonicalSource with
    | Except.error _ => throw (IO.userError "PSC_WASM_CANONICAL_FIXTURE_FAILED")
    | Except.ok artifacts =>
        let sourceJson ← match psIrEncodeModule canonicalSource.raw with
          | Except.ok value => pure value
          | Except.error _ => throw (IO.userError "PSC_WASM_CANONICAL_SOURCE_ENCODING");
        let targetJson ← match psWasmIrEncodeModule artifacts.target with
          | Except.ok value => pure value
          | Except.error _ => throw (IO.userError "PSC_WASM_CANONICAL_TARGET_ENCODING");
        IO.println (psJsonObject [
          Prod.mk "binary" (psJsonArray (artifacts.binary.map fun byte => toString byte.toNat)),
          Prod.mk "bindingJson" (psJsonQuote artifacts.bindingJson),
          Prod.mk "interfaceJson" (psJsonQuote artifacts.interfaceJson),
          Prod.mk "sourceJson" (psJsonQuote sourceJson),
          Prod.mk "targetJson" (psJsonQuote targetJson)]);
    return;
  canonicalRequestChecks
  let forged := canonicalSingle (PsVerifiedIrDeclaration.mk "forged" [] [] (.primitive .uint32) (.literal (.bool true)));
  let imported := PsSpecializedIrModule.mk { canonicalSource.raw with
    imports := [PsVerifiedIrExternalImport.mk "external" "provider" "external" (.function [] (.primitive .uint32))] };
  let polymorphic := canonicalSingle (PsVerifiedIrDeclaration.mk "poly" [PsVerifiedIrTypeParameter.mk "T"]
    [PsVerifiedIrParameter.mk "x" (.typeParameter "T")] (.typeParameter "T") (.var "x"));
  let cases : List (String × Bool) := [
    ("selected numeric surface with private GC helper", canonicalAccepts canonicalSource canonicalSelection),
    ("unit result", canonicalAccepts canonicalSource (canonicalOnly "Source.done")),
    ("missing declaration", !canonicalAccepts canonicalSource (canonicalOnly "missing")),
    ("internal string representation", !canonicalAccepts canonicalSource (canonicalOnly "Source.hidden")),
    ("unit parameter", !canonicalAccepts (canonicalSingle (canonicalEcho "unit" .unit)) (canonicalOnly "unit")),
    ("natural representation", !canonicalAccepts (canonicalSingle (canonicalEcho "natural" .nat)) (canonicalOnly "natural")),
    ("integer representation", !canonicalAccepts (canonicalSingle (canonicalEcho "integer" .int)) (canonicalOnly "integer")),
    ("sixteen direct parameters", canonicalAccepts (canonicalSingle (canonicalMany 16)) (canonicalOnly "many")),
    ("seventeen need a wrapper", !canonicalAccepts (canonicalSingle (canonicalMany 17)) (canonicalOnly "many")),
    ("source revalidation", !canonicalAccepts forged (canonicalOnly "forged")),
    ("external import", !canonicalAccepts imported canonicalSelection),
    ("unspecialized polymorphism", !canonicalAccepts polymorphic (canonicalOnly "poly")),
    ("invalid foreign name", !canonicalAccepts canonicalSource (canonicalOnly "Source.u8" "Invalid")),
    ("empty selection", !canonicalAccepts canonicalSource { canonicalSelection with exports := [] }),
    ("duplicate alias", !canonicalAccepts canonicalSource { canonicalSelection with exports :=
      [PsWasmCanonicalExport.mk "Source.u8" "same", PsWasmCanonicalExport.mk "Source.u16" "same"] })
  ];
  for entry in cases do
    if !entry.2 then throw (IO.userError ("PSC_WASM_CANONICAL_EXPORTS: FAIL " ++ entry.1));
  IO.println ("PSC_WASM_CANONICAL_EXPORTS: PASS (" ++ toString cases.length ++ " cases)")
