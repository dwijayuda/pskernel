import Init.Data.UInt.Lemmas
import WasmBinaryReference
import Ps.BackendWasm.CompilerService

-- All-input byte boundary equality, checked by official Lean.
theorem wasm_portable_byte_compat (value : Nat) :
    UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmByte value) = UInt8.ofNat value := by
  change UInt8.ofNat (value % 256) = UInt8.ofNat value
  exact UInt8.ofNat_mod_size

theorem wasm_portable_byte_bound (value : Nat) :
    Ps.Internal.WasmBinaryBytes.psWasmByte value < 256 := by
  exact Nat.mod_lt value (by decide)

#print axioms wasm_portable_byte_compat
#print axioms wasm_portable_byte_bound

private def errorKey : PsWasmEncodeError -> String
  | .unsupportedValueType => "unsupportedValueType"
  | .unsupportedInstruction => "unsupportedInstruction"
  | .negativeIntegerConstant => "negativeIntegerConstant"
  | .unknownFunction n => "unknownFunction:" ++ n
  | .unknownFunctionType n => "unknownFunctionType:" ++ n
  | .unknownStructure n => "unknownStructure:" ++ n

private def compare (expected actual : Except PsWasmEncodeError (List UInt8)) : IO Unit := do
  match expected, actual with
  | .ok a, .ok b =>
      if a != b then throw (IO.userError "owned encoder byte-carrier output changed")
  | .error a, .error b =>
      if errorKey a != errorKey b then throw (IO.userError "owned encoder refusal changed")
  | _, _ => throw (IO.userError "owned encoder success/refusal boundary changed")

private def checkModule (module : PsWasmModule) : IO Unit := do
  compare (PsWasmBinaryReference.psWasmEncodeModule module) (psWasmEncodeModule module)
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeModule module with
  | .error _ => pure ()
  | .ok bytes =>
      if bytes.any (fun value => Nat.ble 256 value) then
        throw (IO.userError "portable encoded byte exceeded 255")

private def checkFloatBitMetadata (type : PsWasmValueType)
    (instruction : PsWasmInstruction) (expected : Bool) : IO Unit := do
  let function := PsWasmFunction.mk "bits" Option.none [] [type] [] [instruction]
  let module := { psWasmModuleEmpty with functions := [function] }
  let accepted := match psWasmIrValidateModule module with
    | .ok _ => true
    | .error _ => false
  if accepted != expected then
    throw (IO.userError "raw bit metadata width validation changed")
  match psWasmEncodeModule module with
  | .error .unsupportedInstruction => pure ()
  | _ => throw (IO.userError "unqualified floating encoding was enabled")

def testWasmBinaryCarrier (module : PsWasmModule) : IO Unit := do
  -- Representation metadata must not qualify machine/float source capabilities.
  for type in [PsVerifiedIrPrimitiveType.uint8, .uint32, .uint64, .float, .float32] do
    match psIrCheckPrimitive type with
    | .error issue =>
        if issue.code != "scalar-capability-unqualified" then
          throw (IO.userError "machine/float refusal code changed")
    | .ok _ => throw (IO.userError "unqualified scalar capability was enabled")
  checkFloatBitMetadata .f32 (.f32ConstBits 0) true
  checkFloatBitMetadata .f32 (.f32ConstBits 4294967295) true
  checkFloatBitMetadata .f32 (.f32ConstBits 4294967296) false
  checkFloatBitMetadata .f64 (.f64ConstBits 0) true
  checkFloatBitMetadata .f64 (.f64ConstBits 18446744073709551615) true
  checkFloatBitMetadata .f64 (.f64ConstBits 18446744073709551616) false
  for value in [0,1,127,128,255,256,257,65535,65536,2^63,2^64,2^2000] do
    if PsWasmBinaryReference.psWasmByte value != psWasmByte value then
      throw (IO.userError "byte modulus changed")
    if PsWasmBinaryReference.psWasmEncodeUleb value != psWasmEncodeUleb value then
      throw (IO.userError "ULEB encoding changed")
    for signed in [Int.ofNat value, -(Int.ofNat value)] do
      if PsWasmBinaryReference.psWasmEncodeSleb signed != psWasmEncodeSleb signed then
        throw (IO.userError "SLEB encoding changed")
      if PsWasmBinaryReference.psWasmEncodeI32Constant signed != psWasmEncodeI32Constant signed then
        throw (IO.userError "i32 immediate encoding changed")
      if PsWasmBinaryReference.psWasmEncodeI64Constant signed != psWasmEncodeI64Constant signed then
        throw (IO.userError "i64 immediate encoding changed")
  for name in ["","ASCII","λ雪🙂","\u0000","module.memory"] do
    if PsWasmBinaryReference.psWasmEncodeName name != psWasmEncodeName name then
      throw (IO.userError "UTF8 name encoding changed")
  let instructions : List PsWasmInstruction := [
    PsWasmInstruction.i32Load 1,
    PsWasmInstruction.i32Store 1,
    PsWasmInstruction.i32Load8U,
    PsWasmInstruction.i32Store8,
    PsWasmInstruction.abiHeapGet,
    PsWasmInstruction.abiHeapSet,
    PsWasmInstruction.abiBusyGet,
    PsWasmInstruction.abiBusySet,
    PsWasmInstruction.localGet 1,
    PsWasmInstruction.localSet 1,
    PsWasmInstruction.drop,
    PsWasmInstruction.unreachable,
    PsWasmInstruction.call "missing-function",
    PsWasmInstruction.returnCall "missing-function",
    PsWasmInstruction.return_,
    PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
    PsWasmInstruction.else_,
    PsWasmInstruction.end_,
    PsWasmInstruction.i32Const (-129),
    PsWasmInstruction.i64Const (-129),
    PsWasmInstruction.f32ConstBits 17,
    PsWasmInstruction.f64ConstBits 17,
    PsWasmInstruction.i32Add,
    PsWasmInstruction.i32Sub,
    PsWasmInstruction.i32Mul,
    PsWasmInstruction.i32And,
    PsWasmInstruction.i32Or,
    PsWasmInstruction.i32Xor,
    PsWasmInstruction.i32ShrU,
    PsWasmInstruction.i32Extend8S,
    PsWasmInstruction.i32Extend16S,
    PsWasmInstruction.i32Eq,
    PsWasmInstruction.i32Ne,
    PsWasmInstruction.i32LtS,
    PsWasmInstruction.i32LtU,
    PsWasmInstruction.i32LeS,
    PsWasmInstruction.i32LeU,
    PsWasmInstruction.i32GtS,
    PsWasmInstruction.i32GtU,
    PsWasmInstruction.i32GeS,
    PsWasmInstruction.i32GeU,
    PsWasmInstruction.i64Add,
    PsWasmInstruction.i64Sub,
    PsWasmInstruction.i64Mul,
    PsWasmInstruction.i64And,
    PsWasmInstruction.i64Or,
    PsWasmInstruction.i64Xor,
    PsWasmInstruction.i64Eq,
    PsWasmInstruction.i64Ne,
    PsWasmInstruction.i64LtS,
    PsWasmInstruction.i64LtU,
    PsWasmInstruction.i64LeS,
    PsWasmInstruction.i64LeU,
    PsWasmInstruction.i64GtS,
    PsWasmInstruction.i64GtU,
    PsWasmInstruction.i64GeS,
    PsWasmInstruction.i64GeU,
    PsWasmInstruction.f32Add,
    PsWasmInstruction.f32Sub,
    PsWasmInstruction.f32Mul,
    PsWasmInstruction.f32Div,
    PsWasmInstruction.f32Eq,
    PsWasmInstruction.f32Ne,
    PsWasmInstruction.f32Lt,
    PsWasmInstruction.f32Le,
    PsWasmInstruction.f32Gt,
    PsWasmInstruction.f32Ge,
    PsWasmInstruction.f64Add,
    PsWasmInstruction.f64Sub,
    PsWasmInstruction.f64Mul,
    PsWasmInstruction.f64Div,
    PsWasmInstruction.f64Eq,
    PsWasmInstruction.f64Ne,
    PsWasmInstruction.f64Lt,
    PsWasmInstruction.f64Le,
    PsWasmInstruction.f64Gt,
    PsWasmInstruction.f64Ge,
    PsWasmInstruction.structNew "missing-type",
    PsWasmInstruction.structGet "missing-type" 1,
    PsWasmInstruction.structGetS "missing-type" 1,
    PsWasmInstruction.structGetU "missing-type" 1,
    PsWasmInstruction.arrayNew "missing-type",
    PsWasmInstruction.arrayNewDefault "missing-type",
    PsWasmInstruction.arrayNewFixed "missing-type" 1,
    PsWasmInstruction.arrayGet "missing-type",
    PsWasmInstruction.arrayGetS "missing-type",
    PsWasmInstruction.arrayGetU "missing-type",
    PsWasmInstruction.arraySet "missing-type",
    PsWasmInstruction.arrayLen,
    PsWasmInstruction.arrayCopy "missing-function" "missing-function",
    PsWasmInstruction.refTest "missing-type",
    PsWasmInstruction.refCast "missing-type",
    PsWasmInstruction.refFunc "missing-function",
    PsWasmInstruction.refCastFunction "missing-type",
    PsWasmInstruction.callRef "missing-type",
    PsWasmInstruction.returnCallRef "missing-type"
  ]
  for instruction in instructions do
    compare
      (PsWasmBinaryReference.psWasmEncodeInstruction module.structures module.arrays
        module.functionTypes (psWasmAllFunctions module) instruction)
      (psWasmEncodeInstruction module.structures module.arrays
        module.functionTypes (psWasmAllFunctions module) instruction)
  checkModule module
  for memory in [false,true] do
    for globals in [false,true] do
      for imported in [false,true] do
        checkModule { module with abiMemory := memory, abiGlobalsExport := globals, abiMemoryImports := imported }
  let importedFunction := PsWasmFunction.mk "imported" Option.none [] [PsWasmValueType.i32]
    [] [PsWasmInstruction.i32Const 42]
  checkModule { module with functionImports := [
    PsWasmFunctionImport.mk "first" "a" importedFunction,
    PsWasmFunctionImport.mk "second" "b" { importedFunction with name := "imported2" }] }
  IO.println "PSC1_WASM_BYTE_CARRIER: all-input modulus/range proofs; retained encoder equality for all 96 opcodes, LEB/UTF8 boundaries, module flags and ordered imports"
