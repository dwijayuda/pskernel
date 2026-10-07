import Ps.BackendWasm.CanonicalExports

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

def main (args : List String) : IO Unit := do
  if args == ["--fixture32"] || args == ["--fixture64"] then
    let width := if args == ["--fixture64"] then PsWasmWordSize.wasm64 else PsWasmWordSize.wasm32;
    match psWasmCompileCanonicalExports (PsWasmTargetProfile.mk width) canonicalSelection canonicalSource with
    | Except.error _ => throw (IO.userError "PSC_WASM_CANONICAL_FIXTURE_FAILED")
    | Except.ok artifacts =>
        IO.println (psJsonObject [
          Prod.mk "binary" (psJsonArray (artifacts.binary.map fun byte => toString byte.toNat)),
          Prod.mk "bindingJson" (psJsonQuote artifacts.bindingJson),
          Prod.mk "interfaceJson" (psJsonQuote artifacts.interfaceJson)]);
    return;
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
