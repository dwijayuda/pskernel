import Ps.BackendWasm.RuntimeNat
import Ps.BackendWasm.IntUtil
import Ps.Foundation.List

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
      superType := Option.none
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
      typeName := Option.none
      parameters := [psWasmNatRef]
      results := [psWasmIntRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
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
      typeName := Option.none
      parameters := [psWasmNatRef]
      results := [psWasmIntRef]
      locals := []
      body := [
        PsWasmInstruction.i32Const (Int.negSucc 0),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmNatSuccFn,
        PsWasmInstruction.structNew psWasmIntName
      ]
    },
    {
      name := psWasmIntNegFn
      typeName := Option.none
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
      typeName := Option.none
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
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
          PsWasmInstruction.i32Const (Int.negSucc 0),
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32GtS,
          PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 1,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32Eq,
            PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
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
              PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
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
      typeName := Option.none
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
        PsWasmInstruction.ifStart (Option.some psWasmIntRef),
          PsWasmInstruction.localGet 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart (Option.some psWasmIntRef),
            PsWasmInstruction.localGet 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.i32Eq,
            PsWasmInstruction.ifStart (Option.some psWasmIntRef),
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
              PsWasmInstruction.ifStart (Option.some psWasmIntRef),
                PsWasmInstruction.call psWasmNatZeroFn,
                PsWasmInstruction.call psWasmIntOfNatFn,
              PsWasmInstruction.else_,
                PsWasmInstruction.localGet 6,
                PsWasmInstruction.i32Const 0,
                PsWasmInstruction.i32GtS,
                PsWasmInstruction.ifStart (Option.some psWasmIntRef),
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
      typeName := Option.none
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
      typeName := Option.none
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
        PsWasmInstruction.ifStart (Option.some psWasmIntRef),
          PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.call psWasmIntOfNatFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 3,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart (Option.some psWasmIntRef),
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
  let signMagnitude := psWasmIntSignMagnitude value;
  psListAppend
    [PsWasmInstruction.i32Const (Prod.fst signMagnitude)]
    (psListAppend
      (psWasmNatLiteralInstructions (Prod.snd signMagnitude))
      [PsWasmInstruction.structNew psWasmIntName])