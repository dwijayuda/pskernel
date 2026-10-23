import Ps.BackendWasm.BinaryBytes

-- Compatibility API: a single shared encoding algorithm owns section ordering,
-- indices, validation refusals and byte normalization. These adapters only change
-- the byte carrier at the existing native UInt8 boundary.

abbrev psListFlatMapExcept := @Ps.Internal.WasmBinaryBytes.psListFlatMapExcept

def psWasmEncodeByteChunks (chunks : List (List UInt8)) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeByteChunks (psListMap (fun chunk => psListMap UInt8.toNat chunk) chunks))

def psWasmByte (value : Nat) : UInt8 :=
  UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmByte value)

def psWasmEncodeUlebWithFuel
    (remainingFuel : Nat) : Nat -> List UInt8 :=
  fun (argument0 : Nat) =>
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeUlebWithFuel remainingFuel argument0)

def psWasmEncodeUleb (value : Nat) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeUleb value)

def psWasmEncodeSlebWithFuel
    (remainingFuel : Nat) : Int -> List UInt8 :=
  fun (argument0 : Int) =>
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeSlebWithFuel remainingFuel argument0)

def psWasmEncodeSleb (value : Int) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeSleb value)

abbrev psWasmNormalizeI32Immediate := @Ps.Internal.WasmBinaryBytes.psWasmNormalizeI32Immediate

abbrev psWasmNormalizeI64Immediate := @Ps.Internal.WasmBinaryBytes.psWasmNormalizeI64Immediate

def psWasmEncodeI32Constant (value : Int) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeI32Constant value)

def psWasmEncodeI64Constant (value : Int) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeI64Constant value)

abbrev psWasmStringToListFromWithFuel := @Ps.Internal.WasmBinaryBytes.psWasmStringToListFromWithFuel

abbrev psWasmStringToListFrom := @Ps.Internal.WasmBinaryBytes.psWasmStringToListFrom

abbrev psWasmStringToList := @Ps.Internal.WasmBinaryBytes.psWasmStringToList

def psWasmEncodeUtf8Char (char : Char) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeUtf8Char char)

def psWasmEncodeUtf8Chars
    (chars : List Char) :
    List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeUtf8Chars chars)

def psWasmEncodeName (name : String) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeName name)

abbrev psWasmFindStructureIndexWorker := @Ps.Internal.WasmBinaryBytes.psWasmFindStructureIndexWorker

abbrev psWasmFindStructureIndexLoop := @Ps.Internal.WasmBinaryBytes.psWasmFindStructureIndexLoop

abbrev psWasmFindStructureIndex := @Ps.Internal.WasmBinaryBytes.psWasmFindStructureIndex

abbrev psWasmFindArrayIndexWorker := @Ps.Internal.WasmBinaryBytes.psWasmFindArrayIndexWorker

abbrev psWasmFindArrayIndexLoop := @Ps.Internal.WasmBinaryBytes.psWasmFindArrayIndexLoop

abbrev psWasmFindArrayIndex := @Ps.Internal.WasmBinaryBytes.psWasmFindArrayIndex

abbrev psWasmFindHeapTypeIndex := @Ps.Internal.WasmBinaryBytes.psWasmFindHeapTypeIndex

def psWasmEncodeValueType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (type : PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeValueType structures arrays type with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeValueTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (types : List PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeValueTypes structures arrays types with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeVector
    (bytes : List UInt8)
    (count : Nat) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeVector (psListMap UInt8.toNat bytes) count)

abbrev psWasmFindFunctionTypeIndexWorker := @Ps.Internal.WasmBinaryBytes.psWasmFindFunctionTypeIndexWorker

abbrev psWasmFindFunctionTypeIndexLoop := @Ps.Internal.WasmBinaryBytes.psWasmFindFunctionTypeIndexLoop

abbrev psWasmFindFunctionTypeIndex := @Ps.Internal.WasmBinaryBytes.psWasmFindFunctionTypeIndex

def psWasmEncodeNamedFunctionType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionType : PsWasmFunctionType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeNamedFunctionType structures arrays functionType with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeNamedFunctionTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypesToEncode : List PsWasmFunctionType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeNamedFunctionTypes structures arrays functionTypesToEncode with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionType structures arrays function with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionsToEncode : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionTypes structures arrays functionsToEncode with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

abbrev psWasmFindFunctionIndexWorker := @Ps.Internal.WasmBinaryBytes.psWasmFindFunctionIndexWorker

abbrev psWasmFindFunctionIndexLoop := @Ps.Internal.WasmBinaryBytes.psWasmFindFunctionIndexLoop

abbrev psWasmFindFunctionIndex := @Ps.Internal.WasmBinaryBytes.psWasmFindFunctionIndex

def psWasmEncodeInstruction
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (instruction : PsWasmInstruction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeInstruction structures arrays functionTypes functions instruction with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeInstructions
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (instructions : List PsWasmInstruction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeInstructions structures arrays functionTypes functions instructions with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeLocalDeclaration
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (type : PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeLocalDeclaration structures arrays type with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeLocalDeclarations
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (types : List PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeLocalDeclarations structures arrays types with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionBody
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionBody structures arrays functionTypes functions function with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionBodies
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (functionsToEncode : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionBodies structures arrays functionTypes functions functionsToEncode with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeStorageType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (type : PsWasmStorageType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeStorageType structures arrays type with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeStructField
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (field : PsWasmStructField) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeStructField structures arrays field with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeStructFields
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (fields : List PsWasmStructField) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeStructFields structures arrays fields with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeStructCompositeType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeStructCompositeType structures arrays structType with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeStructType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeStructType structures arrays structType with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeStructTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structTypes : List PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeStructTypes structures arrays structTypes with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeArrayType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (arrayType : PsWasmArrayType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeArrayType structures arrays arrayType with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeArrayTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (arrayTypes : List PsWasmArrayType) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeArrayTypes structures arrays arrayTypes with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

abbrev psWasmFunctionTypeIndex := @Ps.Internal.WasmBinaryBytes.psWasmFunctionTypeIndex

def psWasmEncodeFunctionTypeIndicesAcc
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Nat -> List UInt8 -> Except PsWasmEncodeError (List UInt8) :=
  fun (argument0 : Nat) =>
  fun (argument1 : List UInt8) =>
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionTypeIndicesAcc structures arrays functionTypes functions argument0 (psListMap UInt8.toNat argument1) with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionTypeIndicesWorker
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Nat -> Except PsWasmEncodeError (List UInt8) :=
  fun (argument0 : Nat) =>
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionTypeIndicesWorker structures arrays functionTypes functions argument0 with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionTypeIndicesLoop
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functionIndex : Nat)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionTypeIndicesLoop structures arrays functionTypes functionIndex functions with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionTypeIndices
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionTypeIndices structures arrays functionTypes functions with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionRefIndex
    (functions : List PsWasmFunction) (name : String) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionRefIndex functions name with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeFunctionRefIndices
    (functions : List PsWasmFunction)
    (names : List String) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeFunctionRefIndices functions names with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeDeclarativeFunctionRefs
    (functions : List PsWasmFunction)
    (functionRefs : List String) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeDeclarativeFunctionRefs functions functionRefs with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeExport
    (functions : List PsWasmFunction) (exportItem : Prod String String) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeExport functions exportItem with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeExports
    (functions : List PsWasmFunction)
    (exports : List (String × String)) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeExports functions exports with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeSection
    (sectionId : Nat)
    (payload : List UInt8) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeSection sectionId (psListMap UInt8.toNat payload))

def psWasmEncodeTypeSectionPayload
    (encodedTypes : List UInt8)
    (typeCount : Nat) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeTypeSectionPayload (psListMap UInt8.toNat encodedTypes) typeCount)

def psWasmEncodeGroupedTypeSectionPayload
    (encodedHeapTypes : List UInt8)
    (heapTypeCount : Nat)
    (encodedFunctionTypes : List UInt8)
    (functionTypeCount : Nat) : List UInt8 :=
  psListMap UInt8.ofNat (Ps.Internal.WasmBinaryBytes.psWasmEncodeGroupedTypeSectionPayload (psListMap UInt8.toNat encodedHeapTypes) heapTypeCount (psListMap UInt8.toNat encodedFunctionTypes) functionTypeCount)

def psWasmEncodeAbiImport (module : PsWasmModule) (index : Nat)
    (value : PsWasmFunctionImport) : Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeAbiImport module index value with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeAbiImportsWorker (module : PsWasmModule) (index : Nat)
    (imports : List PsWasmFunctionImport) : Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeAbiImportsWorker module index imports with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeAbiImports (module : PsWasmModule) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeAbiImports module with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)

def psWasmEncodeModule
    (module : PsWasmModule) :
    Except PsWasmEncodeError (List UInt8) :=
  match Ps.Internal.WasmBinaryBytes.psWasmEncodeModule module with
  | Except.error error => Except.error error
  | Except.ok bytes => Except.ok (psListMap UInt8.ofNat bytes)
