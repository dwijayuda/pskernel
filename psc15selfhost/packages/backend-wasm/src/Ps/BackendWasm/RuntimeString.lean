import Ps.BackendWasm.RuntimeNat
import Ps.Foundation.List

def psWasmStringName : String := "ProofScript.String"
def psWasmStringCharsName : String := "ProofScript.String.Chars"

def psWasmStringSingletonFn : String := "__ps_wasm_string_singleton"
def psWasmStringPushFn : String := "__ps_wasm_string_push"
def psWasmStringLengthFn : String := "__ps_wasm_string_length"
def psWasmStringAppendFn : String := "__ps_wasm_string_append"
def psWasmCharUtf8WidthFn : String := "__ps_wasm_char_utf8_width"
def psWasmStringUtf8ByteSizeFromFn : String :=
  "__ps_wasm_string_utf8_byte_size_from"
def psWasmStringUtf8ByteSizeFn : String := "__ps_wasm_string_utf8_byte_size"
def psWasmStringNextFromFn : String := "__ps_wasm_string_next_from"
def psWasmStringNextFn : String := "__ps_wasm_string_next"
def psWasmStringGetFromFn : String := "__ps_wasm_string_get_from"
def psWasmStringGetFn : String := "__ps_wasm_string_get"
def psWasmStringAtEndFn : String := "__ps_wasm_string_at_end"
def psWasmStringExtractFillFn : String := "__ps_wasm_string_extract_fill"
def psWasmStringExtractFn : String := "__ps_wasm_string_extract"
def psWasmStringEqFromFn : String := "__ps_wasm_string_eq_from"
def psWasmStringEqFn : String := "__ps_wasm_string_eq"

def psWasmStringRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmStringName

def psWasmStringCharsRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmStringCharsName

def psWasmStringRuntimeArrays : List PsWasmArrayType :=
  [
    {
      name := psWasmStringCharsName
      elementType :=
        PsWasmStorageType.value PsWasmValueType.i32
      mutable := true
    }
  ]

def psWasmStringRuntimeStructures : List PsWasmStructType :=
  [
    {
      name := psWasmStringName
      superType := Option.none
      isFinal := true
      fields := [
        {
          name := "chars"
          storageType :=
            PsWasmStorageType.value psWasmStringCharsRef
        },
        {
          name := "length"
          storageType :=
            PsWasmStorageType.value PsWasmValueType.i32
        }
      ]
    }
  ]

def psWasmStringNatOneInstructions : List PsWasmInstruction :=
  [
    PsWasmInstruction.call psWasmNatZeroFn,
    PsWasmInstruction.call psWasmNatBit1Fn
  ]

def psWasmStringLiteralCharsWithFuel
    (fuel : Nat) :
    String -> Nat -> List PsWasmInstruction :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) (_position : Nat) =>
        List.nil
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> List PsWasmInstruction :=
        psWasmStringLiteralCharsWithFuel remaining;
      fun (value : String) (position : Nat) =>
        if
            String.Internal.atEnd
              value
              (String.Pos.Raw.mk position) then
          List.nil
        else
          let char : Char :=
            String.Internal.get
              value
              (String.Pos.Raw.mk position);
          let nextPosition : Nat :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                value
                (String.Pos.Raw.mk position));
          List.cons
            (PsWasmInstruction.i32Const
              (Int.ofNat (Char.toNat char)))
            (smaller value nextPosition)

def psWasmStringLiteralChars
    (value : String) : List PsWasmInstruction :=
  psWasmStringLiteralCharsWithFuel
    (Nat.succ (String.utf8ByteSize value))
    value
    0

def psWasmStringLiteralFinishChunk
    (count : Nat)
    (hasPrevious : Bool)
    (instructionsRev : List PsWasmInstruction) : List PsWasmInstruction :=
  let finished : List PsWasmInstruction :=
    List.cons (PsWasmInstruction.structNew psWasmStringName)
      (List.cons (PsWasmInstruction.i32Const (Int.ofNat count))
        (List.cons
          (PsWasmInstruction.arrayNewFixed psWasmStringCharsName count)
          instructionsRev));
  if hasPrevious then
    List.cons (PsWasmInstruction.call psWasmStringAppendFn) finished
  else
    finished

def psWasmStringLiteralChunksWithFuel
    (fuel : Nat) :
    String -> Nat -> Nat -> Bool -> List PsWasmInstruction -> List PsWasmInstruction :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) (_position : Nat) (count : Nat)
          (hasPrevious : Bool) (instructionsRev : List PsWasmInstruction) =>
        psListReverse (psWasmStringLiteralFinishChunk count hasPrevious instructionsRev)
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> Nat -> Bool -> List PsWasmInstruction -> List PsWasmInstruction :=
        psWasmStringLiteralChunksWithFuel remaining;
      fun (value : String) (position : Nat) (count : Nat)
          (hasPrevious : Bool) (instructionsRev : List PsWasmInstruction) =>
        if String.Internal.atEnd value (String.Pos.Raw.mk position) then
          psListReverse (psWasmStringLiteralFinishChunk count hasPrevious instructionsRev)
        else
          let char : Char := String.Internal.get value (String.Pos.Raw.mk position);
          let nextPosition : Nat := String.Pos.Raw.byteIdx
            (String.Internal.next value (String.Pos.Raw.mk position));
          let instruction : PsWasmInstruction :=
            PsWasmInstruction.i32Const (Int.ofNat (Char.toNat char));
          if Nat.beq count 4096 then
            smaller value nextPosition 1 true
              (List.cons instruction
                (psWasmStringLiteralFinishChunk count hasPrevious instructionsRev))
          else
            smaller value nextPosition (Nat.succ count) hasPrevious
              (List.cons instruction instructionsRev)

def psWasmStringLiteralInstructions
    (value : String) : List PsWasmInstruction :=
  psWasmStringLiteralChunksWithFuel (Nat.succ (String.utf8ByteSize value))
    value 0 0 false List.nil

def psWasmStringRuntimeFunctions : List PsWasmFunction :=
  [
    {
      name := psWasmStringSingletonFn
      typeName := Option.none
      parameters := [PsWasmValueType.i32]
      results := [psWasmStringRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayNewFixed psWasmStringCharsName 1,
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
      name := psWasmCharUtf8WidthFn
      typeName := Option.none
      parameters := [PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 128,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart
          (Option.some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 2048,
          PsWasmInstruction.i32LtU,
          PsWasmInstruction.ifStart
            (Option.some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 2,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.i32Const 65536,
            PsWasmInstruction.i32LtU,
            PsWasmInstruction.ifStart
              (Option.some PsWasmValueType.i32),
              PsWasmInstruction.i32Const 3,
            PsWasmInstruction.else_,
              PsWasmInstruction.i32Const 4,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringUtf8ByteSizeFromFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        PsWasmValueType.i32,
        psWasmNatRef
      ]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart
          (Option.some psWasmNatRef),
          PsWasmInstruction.localGet 2,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32Add,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structGet psWasmStringName 0,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.arrayGet psWasmStringCharsName,
          PsWasmInstruction.call psWasmCharUtf8WidthFn,
          PsWasmInstruction.call psWasmNatOfU32Fn,
          PsWasmInstruction.call psWasmNatAddFn,
          PsWasmInstruction.call psWasmStringUtf8ByteSizeFromFn,
        PsWasmInstruction.end_
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
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.call psWasmStringUtf8ByteSizeFromFn
      ]
    },
    {
      name := psWasmStringAppendFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        psWasmStringRef
      ]
      results := [psWasmStringRef]
      locals := [
        psWasmStringCharsRef,
        psWasmStringCharsRef,
        PsWasmValueType.i32,
        PsWasmValueType.i32,
        psWasmStringCharsRef
      ]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.localSet 4,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.localSet 5,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 5,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayNew psWasmStringCharsName,
        PsWasmInstruction.localSet 6,
        PsWasmInstruction.localGet 6,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.arrayCopy
          psWasmStringCharsName
          psWasmStringCharsName,
        PsWasmInstruction.localGet 6,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 5,
        PsWasmInstruction.arrayCopy
          psWasmStringCharsName
          psWasmStringCharsName,
        PsWasmInstruction.localGet 6,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 5,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.structNew psWasmStringName
      ]
    },
    {
      name := psWasmStringPushFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        PsWasmValueType.i32
      ]
      results := [psWasmStringRef]
      locals := [
        psWasmStringCharsRef,
        PsWasmValueType.i32,
        psWasmStringCharsRef
      ]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.arrayNew psWasmStringCharsName,
        PsWasmInstruction.localSet 4,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.arrayCopy
          psWasmStringCharsName
          psWasmStringCharsName,
        PsWasmInstruction.localGet 4,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.i32Add,
        PsWasmInstruction.structNew psWasmStringName
      ]
    },
    {
      name := psWasmStringEqFromFn
      typeName := Option.none
      parameters := [
        psWasmStringCharsRef,
        psWasmStringCharsRef,
        PsWasmValueType.i32,
        PsWasmValueType.i32
      ]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart
          (Option.some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.arrayGet psWasmStringCharsName,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.arrayGet psWasmStringCharsName,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart
            (Option.some PsWasmValueType.i32),
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
      parameters := [
        psWasmStringRef,
        psWasmStringRef
      ]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart
          (Option.some PsWasmValueType.i32),
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structGet psWasmStringName 0,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.structGet psWasmStringName 0,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structGet psWasmStringName 1,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.call psWasmStringEqFromFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringNextFromFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        PsWasmValueType.i32,
        psWasmNatRef,
        psWasmNatRef
      ]
      results := [psWasmNatRef]
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart
          (Option.some psWasmNatRef),
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.call psWasmNatBit1Fn,
          PsWasmInstruction.call psWasmNatAddFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.call psWasmNatCmpFn,
          PsWasmInstruction.localSet 4,
          PsWasmInstruction.localGet 4,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart
            (Option.some psWasmNatRef),
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.structGet psWasmStringName 0,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.arrayGet psWasmStringCharsName,
            PsWasmInstruction.call psWasmCharUtf8WidthFn,
            PsWasmInstruction.call psWasmNatOfU32Fn,
            PsWasmInstruction.call psWasmNatAddFn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 4,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32GtS,
            PsWasmInstruction.ifStart
              (Option.some psWasmNatRef),
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.call psWasmNatZeroFn,
              PsWasmInstruction.call psWasmNatBit1Fn,
              PsWasmInstruction.call psWasmNatAddFn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.call psWasmCharUtf8WidthFn,
              PsWasmInstruction.call psWasmNatOfU32Fn,
              PsWasmInstruction.call psWasmNatAddFn,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.call psWasmStringNextFromFn,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringNextFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        psWasmNatRef
      ]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmStringNextFromFn
      ]
    },
    {
      name := psWasmStringGetFromFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        PsWasmValueType.i32,
        psWasmNatRef,
        psWasmNatRef
      ]
      results := [PsWasmValueType.i32]
      locals := [PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart
          (Option.some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 65,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.call psWasmNatCmpFn,
          PsWasmInstruction.localSet 4,
          PsWasmInstruction.localGet 4,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart
            (Option.some PsWasmValueType.i32),
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.structGet psWasmStringName 0,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.arrayGet psWasmStringCharsName,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 4,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32GtS,
            PsWasmInstruction.ifStart
              (Option.some PsWasmValueType.i32),
              PsWasmInstruction.i32Const 65,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.call psWasmCharUtf8WidthFn,
              PsWasmInstruction.call psWasmNatOfU32Fn,
              PsWasmInstruction.call psWasmNatAddFn,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.call psWasmStringGetFromFn,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringGetFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        psWasmNatRef
      ]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmStringGetFromFn
      ]
    },
    {
      name := psWasmStringAtEndFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        psWasmNatRef
      ]
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
      name := psWasmStringExtractFillFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        psWasmStringCharsRef,
        PsWasmValueType.i32,
        psWasmNatRef,
        psWasmNatRef,
        psWasmNatRef,
        PsWasmValueType.i32,
        PsWasmValueType.i32
      ]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 1,
        PsWasmInstruction.i32GeU,
        PsWasmInstruction.ifStart
          (Option.some PsWasmValueType.i32),
          PsWasmInstruction.localGet 7,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 6,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Ne,
          PsWasmInstruction.ifStart
            (Option.some PsWasmValueType.i32),
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.localGet 5,
            PsWasmInstruction.call psWasmNatCmpFn,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32Eq,
            PsWasmInstruction.ifStart
              (Option.some PsWasmValueType.i32),
              PsWasmInstruction.localGet 7,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.localGet 7,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.arraySet psWasmStringCharsName,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.call psWasmCharUtf8WidthFn,
              PsWasmInstruction.call psWasmNatOfU32Fn,
              PsWasmInstruction.call psWasmNatAddFn,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.localGet 7,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.call psWasmStringExtractFillFn,
            PsWasmInstruction.end_,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.localGet 4,
            PsWasmInstruction.call psWasmNatCmpFn,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32Eq,
            PsWasmInstruction.ifStart
              (Option.some PsWasmValueType.i32),
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.localGet 7,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.arraySet psWasmStringCharsName,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.call psWasmCharUtf8WidthFn,
              PsWasmInstruction.call psWasmNatOfU32Fn,
              PsWasmInstruction.call psWasmNatAddFn,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.localGet 7,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.call psWasmStringExtractFillFn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.i32Const 1,
              PsWasmInstruction.i32Add,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmStringName 0,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.arrayGet psWasmStringCharsName,
              PsWasmInstruction.call psWasmCharUtf8WidthFn,
              PsWasmInstruction.call psWasmNatOfU32Fn,
              PsWasmInstruction.call psWasmNatAddFn,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.i32Const 0,
              PsWasmInstruction.localGet 7,
              PsWasmInstruction.call psWasmStringExtractFillFn,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmStringExtractFn
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        psWasmNatRef,
        psWasmNatRef
      ]
      results := [psWasmStringRef]
      locals := [
        psWasmStringCharsRef,
        PsWasmValueType.i32
      ]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.call psWasmNatCmpFn,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32GeS,
        PsWasmInstruction.ifStart
          (Option.some psWasmStringRef),
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.arrayNewDefault psWasmStringCharsName,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.structNew psWasmStringName,
        PsWasmInstruction.else_,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structGet psWasmStringName 1,
          PsWasmInstruction.arrayNew psWasmStringCharsName,
          PsWasmInstruction.localSet 3,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.call psWasmStringExtractFillFn,
          PsWasmInstruction.localSet 4,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.localGet 4,
          PsWasmInstruction.structNew psWasmStringName,
        PsWasmInstruction.end_
      ]
    }
  ]
