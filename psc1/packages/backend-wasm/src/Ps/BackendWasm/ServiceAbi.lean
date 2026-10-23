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
    psWasmServiceFunction "__psc1_service_string_new" [.i32] [psWasmStringCharsRef] []
      [.localGet 0,.arrayNewDefault psWasmStringCharsName],
    psWasmServiceFunction "__psc1_service_string_set" [psWasmStringCharsRef,.i32,.i32] [] []
      [.localGet 2,.call psWasmCharUtf8WidthFn,.drop,.localGet 0,.localGet 1,.localGet 2,.arraySet psWasmStringCharsName],
    psWasmServiceFunction "__psc1_service_string_finish" [psWasmStringCharsRef] [psWasmStringRef] []
      [.localGet 0,.call psWasmStringFromCharsFn],
    psWasmServiceFunction "__psc1_service_string_size" [psWasmStringRef] [.i32] []
      [.localGet 0,.structGet psWasmStringName 0,.arrayLen],
    psWasmServiceFunction "__psc1_service_string_byte" [psWasmStringRef,.i32] [.i32] []
      [.localGet 0,.structGet psWasmStringName 0,.localGet 1,.arrayGetU psWasmStringBytesName]
  ]

def psWasmServiceNatFunctions : List PsWasmFunction :=
  [
    psWasmServiceFunction "__psc1_service_nat_is_zero" [psWasmNatRef] [.i32] []
      [.localGet 0,.refTest psWasmNatZeroName]
  ]

def psWasmServiceIntFunctions : List PsWasmFunction :=
  [
    psWasmServiceFunction "__psc1_service_int_sign" [psWasmIntRef] [.i32] []
      [.localGet 0,.structGet psWasmIntName 0],
    psWasmServiceFunction "__psc1_service_int_magnitude" [psWasmIntRef] [psWasmNatRef] []
      [.localGet 0,.structGet psWasmIntName 1]
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
