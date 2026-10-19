import Ps.BackendWasm.RuntimeNat
import Ps.Foundation.List

/- Runtime strings own valid UTF-8 bytes and a scalar count. Byte-offset lookup
   never scans a prefix. Only private builders mutate character arrays; finishing
   allocates fresh bytes, so host builder aliases cannot mutate an input string. -/

def psWasmStringName : String := "ProofScript.String"
def psWasmStringBytesName : String := "ProofScript.String.Bytes"
def psWasmStringCharsName : String := "ProofScript.String.Chars"

def psWasmStringSizeAddFn : String := "__ps_wasm_string_size_add"
def psWasmCharUtf8WidthFn : String := "__ps_wasm_char_utf8_width"
def psWasmStringByteWidthFn : String := "__ps_wasm_string_byte_width"
def psWasmStringWriteScalarFn : String := "__ps_wasm_string_write_scalar"
def psWasmStringCharsSizeFn : String := "__ps_wasm_string_chars_size"
def psWasmStringCharsFillFn : String := "__ps_wasm_string_chars_fill"
def psWasmStringFromCharsFn : String := "__ps_wasm_string_from_chars"
def psWasmStringSingletonFn : String := "__ps_wasm_string_singleton"
def psWasmStringLengthFn : String := "__ps_wasm_string_length"
def psWasmStringUtf8ByteSizeFn : String := "__ps_wasm_string_utf8_byte_size"
def psWasmStringAppendFn : String := "__ps_wasm_string_append"
def psWasmStringPushFn : String := "__ps_wasm_string_push"
def psWasmStringEqFromFn : String := "__ps_wasm_string_eq_from"
def psWasmStringEqFn : String := "__ps_wasm_string_eq"
def psWasmStringHasPositionFn : String := "__ps_wasm_string_has_position"
def psWasmStringReadScalarFn : String := "__ps_wasm_string_read_scalar"
def psWasmStringGetFn : String := "__ps_wasm_string_get"
def psWasmStringNextFn : String := "__ps_wasm_string_next"
def psWasmStringAtEndFn : String := "__ps_wasm_string_at_end"
def psWasmStringCountFromFn : String := "__ps_wasm_string_count_from"
def psWasmStringExtractFn : String := "__ps_wasm_string_extract"

def psWasmStringRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmStringName

def psWasmStringBytesRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmStringBytesName

def psWasmStringCharsRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmStringCharsName

def psWasmStringRuntimeArrays : List PsWasmArrayType :=
  [
    { name := psWasmStringBytesName
      elementType := PsWasmStorageType.packedI8
      mutable := true },
    { name := psWasmStringCharsName
      elementType := PsWasmStorageType.value PsWasmValueType.i32
      mutable := true }
  ]

def psWasmStringRuntimeStructures : List PsWasmStructType :=
  [
    {
      name := psWasmStringName
      superType := Option.none
      isFinal := true
      fields := [
        { name := "bytes"
          storageType := PsWasmStorageType.value psWasmStringBytesRef },
        { name := "length"
          storageType := PsWasmStorageType.value PsWasmValueType.i32 }
      ]
    }
  ]

def psWasmStringLiteralScalarBytes (char : Char) : List Nat :=
  let value : Nat := Char.toNat char;
  if Nat.ble value 127 then [value]
  else if Nat.ble value 2047 then
    [Nat.add 192 (Nat.div value 64), Nat.add 128 (Nat.mod value 64)]
  else if Nat.ble value 65535 then
    [Nat.add 224 (Nat.div value 4096),
     Nat.add 128 (Nat.mod (Nat.div value 64) 64),
     Nat.add 128 (Nat.mod value 64)]
  else
    [Nat.add 240 (Nat.div value 262144),
     Nat.add 128 (Nat.mod (Nat.div value 4096) 64),
     Nat.add 128 (Nat.mod (Nat.div value 64) 64),
     Nat.add 128 (Nat.mod value 64)]

def psWasmStringLiteralByte (value : Nat) : PsWasmInstruction :=
  PsWasmInstruction.i32Const (Int.ofNat value)

def psWasmStringLiteralFinishChunk
    (byteCount charCount : Nat)
    (hasPrevious : Bool)
    (instructionsRev : List PsWasmInstruction) : List PsWasmInstruction :=
  let finished : List PsWasmInstruction :=
    List.cons (PsWasmInstruction.structNew psWasmStringName)
      (List.cons (PsWasmInstruction.i32Const (Int.ofNat charCount))
        (List.cons
          (PsWasmInstruction.arrayNewFixed psWasmStringBytesName byteCount)
          instructionsRev));
  if hasPrevious then
    List.cons (PsWasmInstruction.call psWasmStringAppendFn) finished
  else finished

def psWasmStringLiteralChunksWithFuel
    (fuel : Nat) :
    String -> Nat -> Nat -> Nat -> Bool ->
    List PsWasmInstruction -> List PsWasmInstruction :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) (_position : Nat) (byteCount : Nat) (charCount : Nat)
          (hasPrevious : Bool) (instructionsRev : List PsWasmInstruction) =>
        psListReverse
          (psWasmStringLiteralFinishChunk byteCount charCount hasPrevious instructionsRev)
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> Nat -> Nat -> Bool ->
          List PsWasmInstruction -> List PsWasmInstruction :=
        psWasmStringLiteralChunksWithFuel remaining;
      fun (value : String) (position : Nat) (byteCount : Nat) (charCount : Nat)
          (hasPrevious : Bool) (instructionsRev : List PsWasmInstruction) =>
        if String.Internal.atEnd value (String.Pos.Raw.mk position) then
          psListReverse
            (psWasmStringLiteralFinishChunk byteCount charCount hasPrevious instructionsRev)
        else
          let char : Char := String.Internal.get value (String.Pos.Raw.mk position);
          let nextPosition : Nat := String.Pos.Raw.byteIdx
            (String.Internal.next value (String.Pos.Raw.mk position));
          let bytes : List Nat := psWasmStringLiteralScalarBytes char;
          let added : List PsWasmInstruction :=
            psListReverse (psListMap psWasmStringLiteralByte bytes);
          let width : Nat := psListLength bytes;
          if Nat.ble 4092 byteCount then
            smaller value nextPosition width 1 true
              (psListAppend added
                (psWasmStringLiteralFinishChunk byteCount charCount hasPrevious instructionsRev))
          else
            smaller value nextPosition (Nat.add byteCount width) (Nat.succ charCount)
              hasPrevious (psListAppend added instructionsRev)

def psWasmStringLiteralInstructions
    (value : String) : List PsWasmInstruction :=
  psWasmStringLiteralChunksWithFuel (Nat.succ (String.utf8ByteSize value))
    value 0 0 0 false List.nil

/- All indices are checked before truncating a Nat. SizeAdd traps on allocation
   length overflow. Byte helpers below operate only on valid, privately owned
   UTF-8 arrays; no mutable byte array escapes the string construction boundary. -/
def psWasmStringRuntimeFunctions : List PsWasmFunction :=
  [
    {
      name := psWasmStringSizeAddFn
      typeName := Option.none
      parameters := [PsWasmValueType.i32, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.unreachable,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmCharUtf8WidthFn
      typeName := Option.none
      parameters := [PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 1114112,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 55296,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 57343,
        PsWasmInstruction.i32LeU,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.unreachable,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 2048,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 65536,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 3,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 4,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringByteWidthFn
      typeName := Option.none
      parameters := [PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 224,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 240,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 3,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 4,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringWriteScalarFn
      typeName := Option.none
      parameters := [psWasmStringBytesRef, PsWasmValueType.i32, PsWasmValueType.i32]
      results := []
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.call psWasmCharUtf8WidthFn,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart Option.none,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart Option.none,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 6,
        PsWasmInstruction.i32ShrU,
        PsWasmInstruction.i32Const 31,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 192,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 3,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart Option.none,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 12,
        PsWasmInstruction.i32ShrU,
        PsWasmInstruction.i32Const 15,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 224,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 6,
        PsWasmInstruction.i32ShrU,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 18,
        PsWasmInstruction.i32ShrU,
        PsWasmInstruction.i32Const 7,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 240,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 12,
        PsWasmInstruction.i32ShrU,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 6,
        PsWasmInstruction.i32ShrU,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 3,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Or,
        PsWasmInstruction.arraySet psWasmStringBytesName,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringCharsSizeFn
      typeName := Option.none
      parameters := [psWasmStringCharsRef, PsWasmValueType.i32, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.arrayGet psWasmStringCharsName,
        PsWasmInstruction.call psWasmCharUtf8WidthFn,
        PsWasmInstruction.call psWasmStringSizeAddFn,
        PsWasmInstruction.call psWasmStringCharsSizeFn,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringCharsFillFn
      typeName := Option.none
      parameters := [psWasmStringCharsRef, psWasmStringBytesRef, PsWasmValueType.i32, PsWasmValueType.i32]
      results := []
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart Option.none,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.arrayGet psWasmStringCharsName,
        PsWasmInstruction.localSet 4,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.call psWasmStringWriteScalarFn,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.call psWasmCharUtf8WidthFn,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.call psWasmStringCharsFillFn,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringFromCharsFn
      typeName := Option.none
      parameters := [psWasmStringCharsRef]
      results := [psWasmStringRef]
      locals := [psWasmStringBytesRef]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmStringCharsSizeFn,
        PsWasmInstruction.arrayNewDefault psWasmStringBytesName,
        PsWasmInstruction.localSet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmStringCharsFillFn,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.structNew psWasmStringName
      ]
    },
    {
      name := psWasmStringSingletonFn
      typeName := Option.none
      parameters := [PsWasmValueType.i32]
      results := [psWasmStringRef]
      locals := [psWasmStringBytesRef]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmCharUtf8WidthFn,
        PsWasmInstruction.arrayNewDefault psWasmStringBytesName,
        PsWasmInstruction.localSet 1,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmStringWriteScalarFn,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.structNew psWasmStringName
      ]
    },
    {
      name := psWasmStringLengthFn
      typeName := Option.none
      parameters := [psWasmStringRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.call psWasmNatOfU32Fn
      ]
    },
    {
      name := psWasmStringUtf8ByteSizeFn
      typeName := Option.none
      parameters := [psWasmStringRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.call psWasmNatOfU32Fn
      ]
    },
    {
      name := psWasmStringAppendFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmStringRef]
      results := [psWasmStringRef]
      locals := [PsWasmValueType.i32, PsWasmValueType.i32, psWasmStringBytesRef]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.call psWasmStringSizeAddFn,
        PsWasmInstruction.arrayNewDefault psWasmStringBytesName,
        PsWasmInstruction.localSet 4,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.arrayCopy psWasmStringBytesName psWasmStringBytesName,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.arrayCopy psWasmStringBytesName psWasmStringBytesName,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.call psWasmStringSizeAddFn,
        PsWasmInstruction.structNew psWasmStringName
      ]
    },
    {
      name := psWasmStringPushFn
      typeName := Option.none
      parameters := [psWasmStringRef, PsWasmValueType.i32]
      results := [psWasmStringRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmStringSingletonFn,
        PsWasmInstruction.call psWasmStringAppendFn
      ]
    },
    {
      name := psWasmStringEqFromFn
      typeName := Option.none
      parameters := [psWasmStringBytesRef, psWasmStringBytesRef, PsWasmValueType.i32, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.call psWasmStringEqFromFn,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringEqFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmStringRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmStringEqFromFn,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringHasPositionFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatFitsU32Fn,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatToU32Fn,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 192,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32Ne,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringReadScalarFn
      typeName := Option.none
      parameters := [psWasmStringBytesRef, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 224,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 31,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 64,
        PsWasmInstruction.i32Mul,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 240,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 15,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 64,
        PsWasmInstruction.i32Mul,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.i32Const 64,
        PsWasmInstruction.i32Mul,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 7,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Const 64,
        PsWasmInstruction.i32Mul,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.i32Const 64,
        PsWasmInstruction.i32Mul,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 2,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.i32Const 64,
        PsWasmInstruction.i32Mul,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 3,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.i32Const 63,
        PsWasmInstruction.i32And,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringGetFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmStringHasPositionFn,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatToU32Fn,
        PsWasmInstruction.call psWasmStringReadScalarFn,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 65,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringNextFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmStringHasPositionFn,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatToU32Fn,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.call psWasmStringByteWidthFn,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.end_,
        PsWasmInstruction.call psWasmNatOfU32Fn,
        PsWasmInstruction.call psWasmNatAddFn
      ]
    },
    {
      name := psWasmStringAtEndFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmStringUtf8ByteSizeFn,
        PsWasmInstruction.call psWasmNatCmpFn,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32GeS
      ]
    },
    {
      name := psWasmStringCountFromFn
      typeName := Option.none
      parameters := [psWasmStringBytesRef, PsWasmValueType.i32, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.arrayGetU psWasmStringBytesName,
        PsWasmInstruction.call psWasmStringByteWidthFn,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.call psWasmStringCountFromFn,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringExtractFn
      typeName := Option.none
      parameters := [psWasmStringRef, psWasmNatRef, psWasmNatRef]
      results := [psWasmStringRef]
      locals := [PsWasmValueType.i32, PsWasmValueType.i32, psWasmStringBytesRef]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.call psWasmNatCmpFn,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32GeS,
        PsWasmInstruction.ifStart (Option.some psWasmStringRef),
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.arrayNewDefault psWasmStringBytesName,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.structNew psWasmStringName,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmStringHasPositionFn,
        PsWasmInstruction.ifStart (Option.some psWasmStringRef),
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatToU32Fn,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.call psWasmStringHasPositionFn,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.call psWasmNatToU32Fn,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.arrayLen,
        PsWasmInstruction.end_,
        PsWasmInstruction.localSet 4,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Sub,
        PsWasmInstruction.arrayNewDefault psWasmStringBytesName,
        PsWasmInstruction.localSet 5,
        PsWasmInstruction.localGet 5,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Sub,
        PsWasmInstruction.arrayCopy psWasmStringBytesName psWasmStringBytesName,
        PsWasmInstruction.localGet 5,
        PsWasmInstruction.localGet 5,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmStringCountFromFn,
        PsWasmInstruction.structNew psWasmStringName,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.arrayNewDefault psWasmStringBytesName,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.structNew psWasmStringName,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    }
  ]
