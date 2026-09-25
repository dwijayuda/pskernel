import Ps.BackendWasm.Model

def psWasmNatName : String :=
  "ProofScript.Nat"

def psWasmNatZeroName : String :=
  "ProofScript.Nat.zero"

def psWasmNatSuccName : String :=
  "ProofScript.Nat.succ"

def psWasmNatAddName : String :=
  "ProofScript.Nat.add"

def psWasmNatSubName : String :=
  "ProofScript.Nat.sub"

def psWasmNatMulName : String :=
  "ProofScript.Nat.mul"

def psWasmNatDivName : String :=
  "ProofScript.Nat.div"

def psWasmNatModName : String :=
  "ProofScript.Nat.mod"

def psWasmNatEqName : String :=
  "ProofScript.Nat.eq"

def psWasmNatNeName : String :=
  "ProofScript.Nat.ne"

def psWasmNatLeName : String :=
  "ProofScript.Nat.le"

def psWasmNatLtName : String :=
  "ProofScript.Nat.lt"

def psWasmNatToU32Name : String :=
  "ProofScript.Nat.toU32"

def psWasmNatRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmNatName

def psWasmNatStructures : List PsWasmStructType :=
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
      name := psWasmNatSuccName
      superType := some psWasmNatName
      isFinal := true
      fields := [
        {
          name := "pred"
          storageType :=
            PsWasmStorageType.value psWasmNatRef
        }
      ]
    }
  ]

def psWasmNatBinaryFunction
    (name : String)
    (body : List PsWasmInstruction) :
    PsWasmFunction :=
  {
    name := name
    typeName := none
    parameters := [psWasmNatRef, psWasmNatRef]
    results := [psWasmNatRef]
    locals := []
    body := body
  }

def psWasmNatCompareFunction
    (name : String)
    (body : List PsWasmInstruction) :
    PsWasmFunction :=
  {
    name := name
    typeName := none
    parameters := [psWasmNatRef, psWasmNatRef]
    results := [PsWasmValueType.i32]
    locals := []
    body := body
  }

def psWasmNatAddFunction : PsWasmFunction :=
  psWasmNatBinaryFunction
    psWasmNatAddName
    [
      .localGet 0,
      .refTest psWasmNatSuccName,
      .ifStart (some psWasmNatRef),
        .localGet 0,
        .refCast psWasmNatSuccName,
        .structGet psWasmNatSuccName 0,
        .localGet 1,
        .call psWasmNatAddName,
        .structNew psWasmNatSuccName,
      .else_,
        .localGet 1,
      .end_
    ]

def psWasmNatSubFunction : PsWasmFunction :=
  psWasmNatBinaryFunction
    psWasmNatSubName
    [
      .localGet 1,
      .refTest psWasmNatSuccName,
      .ifStart (some psWasmNatRef),
        .localGet 0,
        .refTest psWasmNatSuccName,
        .ifStart (some psWasmNatRef),
          .localGet 0,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .localGet 1,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .call psWasmNatSubName,
        .else_,
          .structNew psWasmNatZeroName,
        .end_,
      .else_,
        .localGet 0,
      .end_
    ]

def psWasmNatMulFunction : PsWasmFunction :=
  psWasmNatBinaryFunction
    psWasmNatMulName
    [
      .localGet 0,
      .refTest psWasmNatSuccName,
      .ifStart (some psWasmNatRef),
        .localGet 1,
        .localGet 0,
        .refCast psWasmNatSuccName,
        .structGet psWasmNatSuccName 0,
        .localGet 1,
        .call psWasmNatMulName,
        .call psWasmNatAddName,
      .else_,
        .structNew psWasmNatZeroName,
      .end_
    ]

def psWasmNatEqFunction : PsWasmFunction :=
  psWasmNatCompareFunction
    psWasmNatEqName
    [
      .localGet 0,
      .refTest psWasmNatSuccName,
      .ifStart (some PsWasmValueType.i32),
        .localGet 1,
        .refTest psWasmNatSuccName,
        .ifStart (some PsWasmValueType.i32),
          .localGet 0,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .localGet 1,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .call psWasmNatEqName,
        .else_,
          .i32Const 0,
        .end_,
      .else_,
        .localGet 1,
        .refTest psWasmNatSuccName,
        .ifStart (some PsWasmValueType.i32),
          .i32Const 0,
        .else_,
          .i32Const 1,
        .end_,
      .end_
    ]

def psWasmNatNeFunction : PsWasmFunction :=
  psWasmNatCompareFunction
    psWasmNatNeName
    [
      .localGet 0,
      .localGet 1,
      .call psWasmNatEqName,
      .i32Const 0,
      .i32Eq
    ]

def psWasmNatLeFunction : PsWasmFunction :=
  psWasmNatCompareFunction
    psWasmNatLeName
    [
      .localGet 0,
      .refTest psWasmNatSuccName,
      .ifStart (some PsWasmValueType.i32),
        .localGet 1,
        .refTest psWasmNatSuccName,
        .ifStart (some PsWasmValueType.i32),
          .localGet 0,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .localGet 1,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .call psWasmNatLeName,
        .else_,
          .i32Const 0,
        .end_,
      .else_,
        .i32Const 1,
      .end_
    ]

def psWasmNatLtFunction : PsWasmFunction :=
  psWasmNatCompareFunction
    psWasmNatLtName
    [
      .localGet 1,
      .refTest psWasmNatSuccName,
      .ifStart (some PsWasmValueType.i32),
        .localGet 0,
        .refTest psWasmNatSuccName,
        .ifStart (some PsWasmValueType.i32),
          .localGet 0,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .localGet 1,
          .refCast psWasmNatSuccName,
          .structGet psWasmNatSuccName 0,
          .call psWasmNatLtName,
        .else_,
          .i32Const 1,
        .end_,
      .else_,
        .i32Const 0,
      .end_
    ]

def psWasmNatDivFunction : PsWasmFunction :=
  psWasmNatBinaryFunction
    psWasmNatDivName
    [
      .localGet 1,
      .refTest psWasmNatSuccName,
      .ifStart (some psWasmNatRef),
        .localGet 0,
        .localGet 1,
        .call psWasmNatLtName,
        .ifStart (some psWasmNatRef),
          .structNew psWasmNatZeroName,
        .else_,
          .localGet 0,
          .localGet 1,
          .call psWasmNatSubName,
          .localGet 1,
          .call psWasmNatDivName,
          .structNew psWasmNatSuccName,
        .end_,
      .else_,
        .structNew psWasmNatZeroName,
      .end_
    ]

def psWasmNatModFunction : PsWasmFunction :=
  psWasmNatBinaryFunction
    psWasmNatModName
    [
      .localGet 1,
      .refTest psWasmNatSuccName,
      .ifStart (some psWasmNatRef),
        .localGet 0,
        .localGet 1,
        .call psWasmNatLtName,
        .ifStart (some psWasmNatRef),
          .localGet 0,
        .else_,
          .localGet 0,
          .localGet 1,
          .call psWasmNatSubName,
          .localGet 1,
          .call psWasmNatModName,
        .end_,
      .else_,
        .localGet 0,
      .end_
    ]

def psWasmNatToU32Function : PsWasmFunction :=
  {
    name := psWasmNatToU32Name
    typeName := none
    parameters := [psWasmNatRef]
    results := [PsWasmValueType.i32]
    locals := []
    body := [
      .localGet 0,
      .refTest psWasmNatSuccName,
      .ifStart (some PsWasmValueType.i32),
        .localGet 0,
        .refCast psWasmNatSuccName,
        .structGet psWasmNatSuccName 0,
        .call psWasmNatToU32Name,
        .i32Const 1,
        .i32Add,
      .else_,
        .i32Const 0,
      .end_
    ]
  }

def psWasmNatFunctions : List PsWasmFunction :=
  [
    psWasmNatAddFunction,
    psWasmNatSubFunction,
    psWasmNatMulFunction,
    psWasmNatDivFunction,
    psWasmNatModFunction,
    psWasmNatEqFunction,
    psWasmNatNeFunction,
    psWasmNatLeFunction,
    psWasmNatLtFunction,
    psWasmNatToU32Function
  ]

def psWasmNatLiteralInstructions :
    Nat -> List PsWasmInstruction
  | 0 => [PsWasmInstruction.structNew psWasmNatZeroName]
  | value + 1 =>
      psWasmNatLiteralInstructions value
        ++ [PsWasmInstruction.structNew psWasmNatSuccName]
