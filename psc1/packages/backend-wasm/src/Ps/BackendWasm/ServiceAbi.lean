import Ps.BackendWasm.RuntimeString
import Ps.BackendWasm.RuntimeInt
import Ps.BackendCommon.Plan

-- Explicit self-host transport only. No imports, native callbacks or compiler
-- semantics cross this boundary; opaque GC values stay owned by WebAssembly.
def psWasmServiceFunction (name : String) (parameters results locals : List PsWasmValueType)
    (body : List PsWasmInstruction) : PsWasmFunction :=
  PsWasmFunction.mk name Option.none parameters results locals body

def psWasmServiceStringFunctions : List PsWasmFunction :=
  [
    psWasmServiceFunction "__psc1_service_string_new" [PsWasmValueType.i32] [psWasmStringCharsRef] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.arrayNewDefault psWasmStringCharsName],
    psWasmServiceFunction "__psc1_service_string_set" [psWasmStringCharsRef,PsWasmValueType.i32,PsWasmValueType.i32] [] []
      [PsWasmInstruction.localGet 2,PsWasmInstruction.call psWasmCharUtf8WidthFn,PsWasmInstruction.drop,PsWasmInstruction.localGet 0,PsWasmInstruction.localGet 1,PsWasmInstruction.localGet 2,PsWasmInstruction.arraySet psWasmStringCharsName],
    psWasmServiceFunction "__psc1_service_string_finish" [psWasmStringCharsRef] [psWasmStringRef] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.call psWasmStringFromCharsFn],
    psWasmServiceFunction "__psc1_service_string_size" [psWasmStringRef] [PsWasmValueType.i32] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.structGet psWasmStringName 0,PsWasmInstruction.arrayLen],
    psWasmServiceFunction "__psc1_service_string_byte" [psWasmStringRef,PsWasmValueType.i32] [PsWasmValueType.i32] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.structGet psWasmStringName 0,PsWasmInstruction.localGet 1,PsWasmInstruction.arrayGetU psWasmStringBytesName]
  ]

def psWasmServiceNatFunctions : List PsWasmFunction :=
  [
    psWasmServiceFunction "__psc1_service_nat_is_zero" [psWasmNatRef] [PsWasmValueType.i32] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.refTest psWasmNatZeroName]
  ]

def psWasmServiceIntFunctions : List PsWasmFunction :=
  [
    psWasmServiceFunction "__psc1_service_int_sign" [psWasmIntRef] [PsWasmValueType.i32] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.structGet psWasmIntName 0],
    psWasmServiceFunction "__psc1_service_int_magnitude" [psWasmIntRef] [psWasmNatRef] []
      [PsWasmInstruction.localGet 0,PsWasmInstruction.structGet psWasmIntName 1]
  ]

def psWasmServiceHasType (name : String) (module : PsWasmModule) : Bool :=
  psListAny (fun (type : PsWasmStructType) => psStringEq type.name name) module.structures

def psWasmServiceSelectExports (publicNames : List String)
    (exports : List (Prod String String)) : List (Prod String String) :=
  match exports with
  | List.nil => []
  | List.cons entry rest =>
      if psBackendNameSeen entry.fst publicNames then
        List.cons entry (psWasmServiceSelectExports publicNames rest)
      else psWasmServiceSelectExports publicNames rest

def psWasmServiceTransport (module : PsWasmModule) (publicNames : List String) : PsWasmModule :=
  let nat := psWasmServiceHasType psWasmNatName module;
  let functions := psListAppend
    (if nat then psWasmServiceNatFunctions else [])
    (psListAppend
      (if psWasmServiceHasType psWasmStringName module then psWasmServiceStringFunctions else [])
      (if psWasmServiceHasType psWasmIntName module then psWasmServiceIntFunctions else []));
  let helperExports := psListMap
    (fun (function : PsWasmFunction) => Prod.mk function.name function.name) functions;
  let intExports := if psWasmServiceHasType psWasmIntName module then [
      Prod.mk "__psc1_service_int_of_nat" psWasmIntOfNatFn,
      Prod.mk "__psc1_service_int_neg" psWasmIntNegFn] else [];
  let natExports := if nat then [
      Prod.mk "__psc1_service_nat_half" psWasmNatHalfFn,
      Prod.mk "__psc1_service_nat_low" psWasmNatLowFn,
      Prod.mk "__psc1_service_nat_of_u32" psWasmNatOfU32Fn,
      Prod.mk "__psc1_service_nat_bit0" psWasmNatMkBit0Fn,
      Prod.mk "__psc1_service_nat_bit1" psWasmNatBit1Fn] else [];
  let exports := psWasmServiceSelectExports publicNames module.exports;
  { structures := module.structures, arrays := module.arrays, functionTypes := module.functionTypes,
    functions := psListAppend module.functions functions, functionRefs := module.functionRefs,
    exports := psListAppend exports (psListAppend helperExports (psListAppend natExports intExports)),
    abiMemory := module.abiMemory, abiMemoryImports := module.abiMemoryImports,
    abiGlobalsExport := module.abiGlobalsExport, functionImports := module.functionImports }
