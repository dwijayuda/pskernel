import Ps.BackendWasm.RuntimeNat

def psWasmIntName : String := "ProofScript.Int"

def psWasmIntOfNatFn : String := "__ps_wasm_int_of_nat"
def psWasmIntNegSuccFn : String := "__ps_wasm_int_neg_succ"
def psWasmIntNegFn : String := "__ps_wasm_int_neg"
def psWasmIntCmpFn : String := "__ps_wasm_int_cmp"
def psWasmIntAddFn : String := "__ps_wasm_int_add"
def psWasmIntSubFn : String := "__ps_wasm_int_sub"
def psWasmIntMulFn : String := "__ps_wasm_int_mul"

def psWasmIntRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmIntName

def psWasmIntRuntimeStructures : List PsWasmStructType :=
  [
    {
      name := psWasmIntName
      superType := none
      isFinal := true
      fields := [
        {
          name := "sign"
          storageType := PsWasmStorageType.value PsWasmValueType.i32
        },
        {
          name := "magnitude"
          storageType := PsWasmStorageType.value psWasmNatRef
        }
      ]
    }
  ]

def psWasmIntRuntimeFunctions : List PsWasmFunction :=
  [
    {
      name := psWasmIntOfNatFn
      typeName := none
      parameters := [psWasmNatRef]
      results := [psWasmIntRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 0,
        PsWasmInstruction.else_,
          PsWasmInstruction.i32Const 1,
        PsWasmInstruction.end_,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structNew psWasmIntName
      ]
    },
    {
      name := psWasmIntNegSuccFn
      typeName := none
      parameters := [psWasmNatRef]
      results := [psWasmIntRef]
      locals := []
      body := [
        PsWasmInstruction.i32Const (-1),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmNatSuccFn,
        PsWasmInstruction.structNew psWasmIntName
      ]
    },
    {
      name := psWasmIntNegFn
      typeName := none
      parameters := [psWasmIntRef]
      results := [psWasmIntRef]
      locals := []
      body := [
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.i32Sub,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 1,
        PsWasmInstruction.structNew psWasmIntName
      ]
    },
    {
      name := psWasmIntCmpFn
      typeName := none
      parameters := [psWasmIntRef, psWasmIntRef]
      results := [PsWasmValueType.i32]
      locals := [
        PsWasmValueType.i32,
        PsWasmValueType.i32,
        psWasmNatRef,
        psWasmNatRef,
        PsWasmValueType.i32
      ]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.localGet 3,
        PsWasmInstruction.i32LtS,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.i32Const (-1),
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32GtS,
          PsWasmInstruction.ifStart (some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 1,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32Eq,
            PsWasmInstruction.ifStart (some PsWasmValueType.i32),
              PsWasmInstruction.i32Const 0,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 0,
              PsWasmInstruction.structGet psWasmIntName 1,
              PsWasmInstruction.localSet 4,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.structGet psWasmIntName 1,
              PsWasmInstruction.localSet 5,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatCmpFn,
              PsWasmInstruction.localSet 6,
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.i32Const 0,
              PsWasmInstruction.i32GtS,
              PsWasmInstruction.ifStart (some PsWasmValueType.i32),
                PsWasmInstruction.localGet 6,
              PsWasmInstruction.else_,
                PsWasmInstruction.i32Const 0,
                PsWasmInstruction.localGet 6,
                PsWasmInstruction.i32Sub,
              PsWasmInstruction.end_,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmIntAddFn
      typeName := none
      parameters := [psWasmIntRef, psWasmIntRef]
      results := [psWasmIntRef]
      locals := [
        PsWasmValueType.i32,
        PsWasmValueType.i32,
        psWasmNatRef,
        psWasmNatRef,
        PsWasmValueType.i32
      ]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 1,
        PsWasmInstruction.localSet 4,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmIntName 1,
        PsWasmInstruction.localSet 5,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (some psWasmIntRef),
          PsWasmInstruction.localGet 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart (some psWasmIntRef),
            PsWasmInstruction.localGet 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.i32Eq,
            PsWasmInstruction.ifStart (some psWasmIntRef),
              PsWasmInstruction.localGet 2,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatAddFn,
              PsWasmInstruction.structNew psWasmIntName,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatCmpFn,
              PsWasmInstruction.localSet 6,
              PsWasmInstruction.localGet 6,
              PsWasmInstruction.i32Const 0,
              PsWasmInstruction.i32Eq,
              PsWasmInstruction.ifStart (some psWasmIntRef),
                PsWasmInstruction.call psWasmNatZeroFn,
                PsWasmInstruction.call psWasmIntOfNatFn,
              PsWasmInstruction.else_,
                PsWasmInstruction.localGet 6,
                PsWasmInstruction.i32Const 0,
                PsWasmInstruction.i32GtS,
                PsWasmInstruction.ifStart (some psWasmIntRef),
                  PsWasmInstruction.localGet 2,
                  PsWasmInstruction.localGet 4,
                  PsWasmInstruction.localGet 5,
                  PsWasmInstruction.call psWasmNatSubGeFn,
                  PsWasmInstruction.structNew psWasmIntName,
                PsWasmInstruction.else_,
                  PsWasmInstruction.localGet 3,
                  PsWasmInstruction.localGet 5,
                  PsWasmInstruction.localGet 4,
                  PsWasmInstruction.call psWasmNatSubGeFn,
                  PsWasmInstruction.structNew psWasmIntName,
                PsWasmInstruction.end_,
              PsWasmInstruction.end_,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmIntSubFn
      typeName := none
      parameters := [psWasmIntRef, psWasmIntRef]
      results := [psWasmIntRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.call psWasmIntNegFn,
        PsWasmInstruction.call psWasmIntAddFn
      ]
    },
    {
      name := psWasmIntMulFn
      typeName := none
      parameters := [psWasmIntRef, psWasmIntRef]
      results := [psWasmIntRef]
      locals := [
        PsWasmValueType.i32,
        PsWasmValueType.i32
      ]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.localSet 3,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (some psWasmIntRef),
          PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.call psWasmIntOfNatFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart (some psWasmIntRef),
            PsWasmInstruction.call psWasmNatZeroFn,
            PsWasmInstruction.call psWasmIntOfNatFn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.i32Mul,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.structGet psWasmIntName 1,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.structGet psWasmIntName 1,
            PsWasmInstruction.call psWasmNatMulFn,
            PsWasmInstruction.structNew psWasmIntName,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    }
  ]

def psWasmIntLiteralInstructions
    (value : Int) : List PsWasmInstruction :=
  match value with
  | .ofNat magnitude =>
      [PsWasmInstruction.i32Const
        (if magnitude == 0 then 0 else 1)]
        ++ psWasmNatLiteralInstructions magnitude
        ++ [PsWasmInstruction.structNew psWasmIntName]
  | .negSucc magnitude =>
      [PsWasmInstruction.i32Const (-1)]
        ++ psWasmNatLiteralInstructions (magnitude + 1)
        ++ [PsWasmInstruction.structNew psWasmIntName]
