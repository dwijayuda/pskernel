import Ps.BackendWasm.Model

def psWasmNatName : String := "ProofScript.Nat"
def psWasmNatZeroName : String := "ProofScript.Nat.Zero"
def psWasmNatBit0Name : String := "ProofScript.Nat.Bit0"
def psWasmNatBit1Name : String := "ProofScript.Nat.Bit1"
def psWasmNatDivModName : String := "ProofScript.NatDivMod"

def psWasmNatZeroFn : String := "__ps_wasm_nat_zero"
def psWasmNatHalfFn : String := "__ps_wasm_nat_half"
def psWasmNatLowFn : String := "__ps_wasm_nat_low"
def psWasmNatMkBit0Fn : String := "__ps_wasm_nat_mk_bit0"
def psWasmNatBit1Fn : String := "__ps_wasm_nat_bit1"
def psWasmNatSuccFn : String := "__ps_wasm_nat_succ"
def psWasmNatCmpFn : String := "__ps_wasm_nat_cmp"
def psWasmNatAddFn : String := "__ps_wasm_nat_add"
def psWasmNatSubGeFn : String := "__ps_wasm_nat_sub_ge"
def psWasmNatSubFn : String := "__ps_wasm_nat_sub"
def psWasmNatMulFn : String := "__ps_wasm_nat_mul"
def psWasmNatDivModFn : String := "__ps_wasm_nat_divmod"
def psWasmNatDivFn : String := "__ps_wasm_nat_div"
def psWasmNatModFn : String := "__ps_wasm_nat_mod"
def psWasmNatFitsBitsFn : String := "__ps_wasm_nat_fits_bits"
def psWasmNatFitsU32Fn : String := "__ps_wasm_nat_fits_u32"
def psWasmNatToU32Fn : String := "__ps_wasm_nat_to_u32"
def psWasmNatOfU32Fn : String := "__ps_wasm_nat_of_u32"

def psWasmNatRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmNatName

def psWasmNatDivModRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmNatDivModName

def psWasmNatRuntimeStructures : List PsWasmStructType :=
  [
    {
      name := psWasmNatName
      superType := none
      isFinal := false
      fields := []
    },
    {
      name := psWasmNatZeroName
      superType := some psWasmNatName
      isFinal := true
      fields := []
    },
    {
      name := psWasmNatBit0Name
      superType := some psWasmNatName
      isFinal := true
      fields := [
        {
          name := "half"
          storageType := PsWasmStorageType.value psWasmNatRef
        }
      ]
    },
    -- Wasm GC canonicalization is structural rather than nominal.
    -- Keep Bit1 structurally distinct from Bit0 so ref.test/ref.cast
    -- preserve Nat constructor identity after canonicalization.
    {
      name := psWasmNatBit1Name
      superType := some psWasmNatName
      isFinal := true
      fields := [
        {
          name := "half"
          storageType := PsWasmStorageType.value psWasmNatRef
        },
        {
          name := "constructorTag"
          storageType := PsWasmStorageType.packedI8
        }
      ]
    },
        {
      name := psWasmNatDivModName
      superType := none
      isFinal := true
      fields := [
        {
          name := "quotient"
          storageType := PsWasmStorageType.value psWasmNatRef
        },
        {
          name := "remainder"
          storageType := PsWasmStorageType.value psWasmNatRef
        }
      ]
    }
  ]

def psWasmNatRuntimeFunctions : List PsWasmFunction :=
  [
    {
      name := psWasmNatZeroFn
      typeName := none
      parameters := []
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.structNew psWasmNatZeroName
      ]
    },
    {
      name := psWasmNatHalfFn
      typeName := none
      parameters := [psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.localGet 0,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.refTest psWasmNatBit0Name,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.refCast psWasmNatBit0Name,
            PsWasmInstruction.structGet psWasmNatBit0Name 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.refCast psWasmNatBit1Name,
            PsWasmInstruction.structGet psWasmNatBit1Name 0,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatLowFn
      typeName := none
      parameters := [psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatBit1Name
      ]
    },
    {
      name := psWasmNatMkBit0Fn
      typeName := none
      parameters := [psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.localGet 0,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structNew psWasmNatBit0Name,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatBit1Fn
      typeName := none
      parameters := [psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 1,
        PsWasmInstruction.structNew psWasmNatBit1Name
      ]
    },
    {
      name := psWasmNatSuccFn
      typeName := none
      parameters := [psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.call psWasmNatBit1Fn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.refTest psWasmNatBit0Name,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.refCast psWasmNatBit0Name,
            PsWasmInstruction.structGet psWasmNatBit0Name 0,
            PsWasmInstruction.call psWasmNatBit1Fn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.refCast psWasmNatBit1Name,
            PsWasmInstruction.structGet psWasmNatBit1Name 0,
            PsWasmInstruction.call psWasmNatSuccFn,
            PsWasmInstruction.call psWasmNatMkBit0Fn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatCmpFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := [psWasmNatRef, psWasmNatRef, PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.i32Const (-1),
          PsWasmInstruction.end_,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 1,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localSet 2,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localSet 3,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.call psWasmNatCmpFn,
            PsWasmInstruction.localSet 4,
            PsWasmInstruction.localGet 4,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32Ne,
            PsWasmInstruction.ifStart (some PsWasmValueType.i32),
              PsWasmInstruction.localGet 4,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.call psWasmNatLowFn,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.call psWasmNatLowFn,
              PsWasmInstruction.i32Sub,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatAddFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := [psWasmNatRef, PsWasmValueType.i32, PsWasmValueType.i32]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.localGet 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.localGet 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.call psWasmNatAddFn,
            PsWasmInstruction.localSet 2,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.localSet 3,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.localSet 4,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.localGet 4,
            PsWasmInstruction.i32And,
            PsWasmInstruction.ifStart (some psWasmNatRef),
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.call psWasmNatSuccFn,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.i32Xor,
              PsWasmInstruction.ifStart (some psWasmNatRef),
                PsWasmInstruction.localGet 2,
                PsWasmInstruction.call psWasmNatBit1Fn,
              PsWasmInstruction.else_,
                PsWasmInstruction.localGet 2,
                PsWasmInstruction.call psWasmNatMkBit0Fn,
              PsWasmInstruction.end_,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatSubGeFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := [
        psWasmNatRef,
        psWasmNatRef,
        PsWasmValueType.i32,
        PsWasmValueType.i32,
        psWasmNatRef
      ]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.localGet 0,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localSet 2,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localSet 3,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.localSet 4,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.localSet 5,
            PsWasmInstruction.localGet 4,
            PsWasmInstruction.localGet 5,
            PsWasmInstruction.i32LtU,
            PsWasmInstruction.ifStart (some psWasmNatRef),
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.call psWasmNatSuccFn,
              PsWasmInstruction.call psWasmNatSubGeFn,
              PsWasmInstruction.call psWasmNatBit1Fn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.localGet 3,
              PsWasmInstruction.call psWasmNatSubGeFn,
              PsWasmInstruction.localSet 6,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.i32Ne,
              PsWasmInstruction.ifStart (some psWasmNatRef),
                PsWasmInstruction.localGet 6,
                PsWasmInstruction.call psWasmNatBit1Fn,
              PsWasmInstruction.else_,
                PsWasmInstruction.localGet 6,
                PsWasmInstruction.call psWasmNatMkBit0Fn,
              PsWasmInstruction.end_,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatSubFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatCmpFn,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32LtS,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.call psWasmNatSubGeFn,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatMulFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := [psWasmNatRef]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatMulFn,
            PsWasmInstruction.localSet 2,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.ifStart (some psWasmNatRef),
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.call psWasmNatAddFn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatDivModFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatDivModRef]
      locals := [
        psWasmNatRef,
        psWasmNatDivModRef,
        psWasmNatRef,
        psWasmNatRef,
        psWasmNatRef
      ]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some psWasmNatDivModRef),
          PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structNew psWasmNatDivModName,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (some psWasmNatDivModRef),
            PsWasmInstruction.call psWasmNatZeroFn,
            PsWasmInstruction.call psWasmNatZeroFn,
            PsWasmInstruction.structNew psWasmNatDivModName,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localSet 2,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatDivModFn,
            PsWasmInstruction.localSet 3,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.structGet psWasmNatDivModName 0,
            PsWasmInstruction.localSet 4,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.structGet psWasmNatDivModName 1,
            PsWasmInstruction.localSet 5,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.ifStart (some psWasmNatRef),
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatBit1Fn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
            PsWasmInstruction.end_,
            PsWasmInstruction.localSet 6,
            PsWasmInstruction.localGet 6,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatCmpFn,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32GeS,
            PsWasmInstruction.ifStart (some psWasmNatDivModRef),
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.call psWasmNatBit1Fn,
              PsWasmInstruction.localGet 6,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.call psWasmNatSubGeFn,
              PsWasmInstruction.structNew psWasmNatDivModName,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
              PsWasmInstruction.localGet 6,
              PsWasmInstruction.structNew psWasmNatDivModName,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatDivFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatDivModFn,
        PsWasmInstruction.structGet psWasmNatDivModName 0
      ]
    },
    {
      name := psWasmNatModFn
      typeName := none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmNatDivModFn,
        PsWasmInstruction.structGet psWasmNatDivModName 1
      ]
    }
,
    {
      name := psWasmNatFitsBitsFn
      typeName := none
      parameters := [psWasmNatRef, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart (some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.i32Const 1,
            PsWasmInstruction.i32Sub,
            PsWasmInstruction.call psWasmNatFitsBitsFn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatFitsU32Fn
      typeName := none
      parameters := [psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 32,
        PsWasmInstruction.call psWasmNatFitsBitsFn
      ]
    },
    {
      name := psWasmNatToU32Fn
      typeName := none
      parameters := [psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 0,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.call psWasmNatHalfFn,
          PsWasmInstruction.call psWasmNatToU32Fn,
          PsWasmInstruction.i32Const 2,
          PsWasmInstruction.i32Mul,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.call psWasmNatLowFn,
          PsWasmInstruction.i32Add,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatOfU32Fn
      typeName := none
      parameters := [PsWasmValueType.i32]
      results := [psWasmNatRef]
      locals := [psWasmNatRef]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32ShrU,
          PsWasmInstruction.call psWasmNatOfU32Fn,
          PsWasmInstruction.localSet 1,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32And,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatBit1Fn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatMkBit0Fn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    }
  ]

def psWasmNatLiteralInstructionsWithFuel :
    Nat -> Nat -> List PsWasmInstruction
  | 0, _ =>
      [PsWasmInstruction.structNew psWasmNatZeroName]
  | _ + 1, 0 =>
      [PsWasmInstruction.structNew psWasmNatZeroName]
  | fuel + 1, value =>
      let half := value / 2
      let low := value % 2
      psWasmNatLiteralInstructionsWithFuel fuel half ++
      (if low == 0 then
        [PsWasmInstruction.structNew psWasmNatBit0Name]
      else
        [PsWasmInstruction.call psWasmNatBit1Fn])

def psWasmNatLiteralInstructions
    (value : Nat) : List PsWasmInstruction :=
  psWasmNatLiteralInstructionsWithFuel (value + 1) value
