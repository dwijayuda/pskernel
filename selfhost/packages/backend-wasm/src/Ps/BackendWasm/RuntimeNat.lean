import Ps.CompilerIr.Model

def psWasmNatRuntimeTypeName : String :=
  "ProofScript.Nat"

def psWasmNatRuntimeZeroName : String :=
  "zero"

def psWasmNatRuntimeSuccName : String :=
  "succ"

def psWasmNatRuntimeAddName : String :=
  "__ps_nat_add"

def psWasmNatRuntimeSubName : String :=
  "__ps_nat_sub"

def psWasmNatRuntimeMulName : String :=
  "__ps_nat_mul"

def psWasmNatRuntimeDivName : String :=
  "__ps_nat_div"

def psWasmNatRuntimeModName : String :=
  "__ps_nat_mod"

def psWasmNatRuntimeEqName : String :=
  "__ps_nat_eq"

def psWasmNatRuntimeNeName : String :=
  "__ps_nat_ne"

def psWasmNatRuntimeLeName : String :=
  "__ps_nat_le"

def psWasmNatRuntimeLtName : String :=
  "__ps_nat_lt"

def psWasmNatRuntimeFromU32Name : String :=
  "__ps_nat_from_u32"

def psWasmNatRuntimeToU32BoundedName : String :=
  "__ps_nat_to_u32_bounded"

def psWasmNatRuntimeType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psWasmNatRuntimeBoolType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool

def psWasmNatRuntimeU32Type : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32

def psWasmNatRuntimeU32
    (value : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.machineInteger
      PsVerifiedIrMachineIntegerType.uint32
      value)

def psWasmNatRuntimeZero : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.constructor
    psWasmNatRuntimeTypeName
    psWasmNatRuntimeZeroName
    []
    []

def psWasmNatRuntimeSucc
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.constructor
    psWasmNatRuntimeTypeName
    psWasmNatRuntimeSuccName
    []
    [("pred", value)]

def psWasmNatRuntimeCall
    (name : String)
    (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.call
    (PsVerifiedIrExpr.var name)
    []
    arguments

def psWasmNatRuntimeBool
    (value : Bool) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool value)

def psWasmNatRuntimePredBinding
    (name : String) : PsVerifiedIrMatchBinding :=
  {
    field := "pred"
    name := name
    type := psWasmNatRuntimeType
  }

def psWasmNatRuntimeMatch
    (scrutinee : PsVerifiedIrExpr)
    (zeroBody : PsVerifiedIrExpr)
    (predName : String)
    (succBody : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.matchE
    psWasmNatRuntimeTypeName
    []
    scrutinee
    [
      (
        psWasmNatRuntimeZeroName,
        [],
        zeroBody
      ),
      (
        psWasmNatRuntimeSuccName,
        [psWasmNatRuntimePredBinding predName],
        succBody
      )
    ]

def psWasmNatRuntimeInductive : PsVerifiedIrInductive :=
  {
    name := psWasmNatRuntimeTypeName
    typeParameters := []
    constructors := [
      {
        name := psWasmNatRuntimeZeroName
        fields := []
      },
      {
        name := psWasmNatRuntimeSuccName
        fields := [
          {
            name := "pred"
            type := psWasmNatRuntimeType
          }
        ]
      }
    ]
  }

def psWasmNatRuntimeBinaryParameters :
    List PsVerifiedIrParameter :=
  [
    {
      name := "a"
      type := psWasmNatRuntimeType
    },
    {
      name := "b"
      type := psWasmNatRuntimeType
    }
  ]

def psWasmNatRuntimeAddDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeAddName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeType
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        (PsVerifiedIrExpr.var "b")
        "aPred"
        (psWasmNatRuntimeSucc
          (psWasmNatRuntimeCall
            psWasmNatRuntimeAddName
            [
              PsVerifiedIrExpr.var "aPred",
              PsVerifiedIrExpr.var "b"
            ]))
  }

def psWasmNatRuntimeSubDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeSubName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeType
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "b")
        (PsVerifiedIrExpr.var "a")
        "bPred"
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "a")
          psWasmNatRuntimeZero
          "aPred"
          (psWasmNatRuntimeCall
            psWasmNatRuntimeSubName
            [
              PsVerifiedIrExpr.var "aPred",
              PsVerifiedIrExpr.var "bPred"
            ]))
  }

def psWasmNatRuntimeMulDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeMulName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeType
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        psWasmNatRuntimeZero
        "aPred"
        (psWasmNatRuntimeCall
          psWasmNatRuntimeAddName
          [
            PsVerifiedIrExpr.var "b",
            psWasmNatRuntimeCall
              psWasmNatRuntimeMulName
              [
                PsVerifiedIrExpr.var "aPred",
                PsVerifiedIrExpr.var "b"
              ]
          ])
  }

def psWasmNatRuntimeEqDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeEqName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeBoolType
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          (psWasmNatRuntimeBool true)
          "bPred"
          (psWasmNatRuntimeBool false))
        "aPred"
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          (psWasmNatRuntimeBool false)
          "bPred"
          (psWasmNatRuntimeCall
            psWasmNatRuntimeEqName
            [
              PsVerifiedIrExpr.var "aPred",
              PsVerifiedIrExpr.var "bPred"
            ]))
  }

def psWasmNatRuntimeNeDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeNeName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeBoolType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmNatRuntimeCall
          psWasmNatRuntimeEqName
          [
            PsVerifiedIrExpr.var "a",
            PsVerifiedIrExpr.var "b"
          ])
        (psWasmNatRuntimeBool false)
        (psWasmNatRuntimeBool true)
  }

def psWasmNatRuntimeLeDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeLeName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeBoolType
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        (psWasmNatRuntimeBool true)
        "aPred"
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          (psWasmNatRuntimeBool false)
          "bPred"
          (psWasmNatRuntimeCall
            psWasmNatRuntimeLeName
            [
              PsVerifiedIrExpr.var "aPred",
              PsVerifiedIrExpr.var "bPred"
            ]))
  }

def psWasmNatRuntimeLtDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeLtName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeBoolType
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          (psWasmNatRuntimeBool false)
          "bPred"
          (psWasmNatRuntimeBool true))
        "aPred"
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          (psWasmNatRuntimeBool false)
          "bPred"
          (psWasmNatRuntimeCall
            psWasmNatRuntimeLtName
            [
              PsVerifiedIrExpr.var "aPred",
              PsVerifiedIrExpr.var "bPred"
            ]))
  }

def psWasmNatRuntimeDivDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeDivName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmNatRuntimeCall
          psWasmNatRuntimeEqName
          [
            PsVerifiedIrExpr.var "b",
            psWasmNatRuntimeZero
          ])
        psWasmNatRuntimeZero
        (PsVerifiedIrExpr.ifE
          (psWasmNatRuntimeCall
            psWasmNatRuntimeLtName
            [
              PsVerifiedIrExpr.var "a",
              PsVerifiedIrExpr.var "b"
            ])
          psWasmNatRuntimeZero
          (psWasmNatRuntimeSucc
            (psWasmNatRuntimeCall
              psWasmNatRuntimeDivName
              [
                psWasmNatRuntimeCall
                  psWasmNatRuntimeSubName
                  [
                    PsVerifiedIrExpr.var "a",
                    PsVerifiedIrExpr.var "b"
                  ],
                PsVerifiedIrExpr.var "b"
              ])))
  }

def psWasmNatRuntimeModDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeModName
    typeParameters := []
    parameters := psWasmNatRuntimeBinaryParameters
    resultType := psWasmNatRuntimeType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmNatRuntimeCall
          psWasmNatRuntimeEqName
          [
            PsVerifiedIrExpr.var "b",
            psWasmNatRuntimeZero
          ])
        (PsVerifiedIrExpr.var "a")
        (PsVerifiedIrExpr.ifE
          (psWasmNatRuntimeCall
            psWasmNatRuntimeLtName
            [
              PsVerifiedIrExpr.var "a",
              PsVerifiedIrExpr.var "b"
            ])
          (PsVerifiedIrExpr.var "a")
          (psWasmNatRuntimeCall
            psWasmNatRuntimeModName
            [
              psWasmNatRuntimeCall
                psWasmNatRuntimeSubName
                [
                  PsVerifiedIrExpr.var "a",
                  PsVerifiedIrExpr.var "b"
                ],
              PsVerifiedIrExpr.var "b"
            ]))
  }

def psWasmNatRuntimeFromU32Declaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeFromU32Name
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmNatRuntimeU32Type
      }
    ]
    resultType := psWasmNatRuntimeType
    body :=
      PsVerifiedIrExpr.ifE
        (PsVerifiedIrExpr.intrinsic
          (PsVerifiedIrIntrinsic.machineIntCompare
            PsVerifiedIrMachineIntegerType.uint32
            PsVerifiedIrIntegerCompareOp.eq)
          [
            PsVerifiedIrExpr.var "value",
            psWasmNatRuntimeU32 0
          ])
        psWasmNatRuntimeZero
        (psWasmNatRuntimeSucc
          (psWasmNatRuntimeCall
            psWasmNatRuntimeFromU32Name
            [
              PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.machineIntBinary
                  PsVerifiedIrMachineIntegerType.uint32
                  PsVerifiedIrIntegerBinaryOp.sub)
                [
                  PsVerifiedIrExpr.var "value",
                  psWasmNatRuntimeU32 1
                ]
            ]))
  }

def psWasmNatRuntimeToU32BoundedDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmNatRuntimeToU32BoundedName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmNatRuntimeType
      }
    ]
    resultType := psWasmNatRuntimeU32Type
    body :=
      psWasmNatRuntimeMatch
        (PsVerifiedIrExpr.var "value")
        (psWasmNatRuntimeU32 0)
        "pred"
        (PsVerifiedIrExpr.intrinsic
          (PsVerifiedIrIntrinsic.machineIntBinary
            PsVerifiedIrMachineIntegerType.uint32
            PsVerifiedIrIntegerBinaryOp.add)
          [
            psWasmNatRuntimeU32 1,
            psWasmNatRuntimeCall
              psWasmNatRuntimeToU32BoundedName
              [PsVerifiedIrExpr.var "pred"]
          ])
  }

def psWasmNatRuntimeDeclarations :
    List PsVerifiedIrDeclaration :=
  [
    psWasmNatRuntimeAddDeclaration,
    psWasmNatRuntimeSubDeclaration,
    psWasmNatRuntimeMulDeclaration,
    psWasmNatRuntimeEqDeclaration,
    psWasmNatRuntimeNeDeclaration,
    psWasmNatRuntimeLeDeclaration,
    psWasmNatRuntimeLtDeclaration,
    psWasmNatRuntimeDivDeclaration,
    psWasmNatRuntimeModDeclaration,
    psWasmNatRuntimeFromU32Declaration,
    psWasmNatRuntimeToU32BoundedDeclaration
  ]

def psWasmNatLiteralExpr : Nat -> PsVerifiedIrExpr
  | 0 => psWasmNatRuntimeZero
  | value + 1 =>
      psWasmNatRuntimeSucc (psWasmNatLiteralExpr value)

def psWasmNatIntrinsicName :
    PsVerifiedIrIntrinsic -> Option String
  | .natAdd => some psWasmNatRuntimeAddName
  | .natSub => some psWasmNatRuntimeSubName
  | .natMul => some psWasmNatRuntimeMulName
  | .natDiv => some psWasmNatRuntimeDivName
  | .natMod => some psWasmNatRuntimeModName
  | .natEq => some psWasmNatRuntimeEqName
  | .natNe => some psWasmNatRuntimeNeName
  | .natLe => some psWasmNatRuntimeLeName
  | .natLt => some psWasmNatRuntimeLtName
  | _ => none

def psWasmRewriteNatExprWithFuel :
    Nat -> PsVerifiedIrExpr -> PsVerifiedIrExpr
  | 0, expression => expression
  | fuel + 1, expression =>
      let rewrite :=
        psWasmRewriteNatExprWithFuel fuel
      match expression with
      | .literal (.natural value) =>
          psWasmNatLiteralExpr value
      | .literal literal =>
          PsVerifiedIrExpr.literal literal
      | .var name =>
          PsVerifiedIrExpr.var name
      | .intrinsic operation arguments =>
          let rewritten := arguments.map rewrite
          match psWasmNatIntrinsicName operation with
          | some name =>
              psWasmNatRuntimeCall name rewritten
          | none =>
              PsVerifiedIrExpr.intrinsic operation rewritten
      | .lambda parameters resultType body =>
          PsVerifiedIrExpr.lambda
            parameters
            resultType
            (rewrite body)
      | .call fn typeArguments arguments =>
          PsVerifiedIrExpr.call
            (rewrite fn)
            typeArguments
            (arguments.map rewrite)
      | .letE name type value body =>
          PsVerifiedIrExpr.letE
            name
            type
            (rewrite value)
            (rewrite body)
      | .ifE condition thenBranch elseBranch =>
          PsVerifiedIrExpr.ifE
            (rewrite condition)
            (rewrite thenBranch)
            (rewrite elseBranch)
      | .record structureName typeArguments fields =>
          PsVerifiedIrExpr.record
            structureName
            typeArguments
            (fields.map
              (fun field => (field.1, rewrite field.2)))
      | .projection structureName typeArguments target field =>
          PsVerifiedIrExpr.projection
            structureName
            typeArguments
            (rewrite target)
            field
      | .constructor inductiveName constructorName typeArguments fields =>
          PsVerifiedIrExpr.constructor
            inductiveName
            constructorName
            typeArguments
            (fields.map
              (fun field => (field.1, rewrite field.2)))
      | .matchE inductiveName typeArguments scrutinee alternatives =>
          PsVerifiedIrExpr.matchE
            inductiveName
            typeArguments
            (rewrite scrutinee)
            (alternatives.map
              (fun alternative =>
                (
                  alternative.1,
                  alternative.2.1,
                  rewrite alternative.2.2
                )))

def psWasmRewriteNatExpr
    (expression : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmRewriteNatExprWithFuel 4096 expression

def psWasmRewriteNatDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    PsVerifiedIrDeclaration :=
  {
    name := declaration.name
    typeParameters := declaration.typeParameters
    parameters := declaration.parameters
    resultType := declaration.resultType
    body := psWasmRewriteNatExpr declaration.body
  }

def psWasmRewriteNatDeclarations :
    List PsVerifiedIrDeclaration ->
    List PsVerifiedIrDeclaration
  | [] => []
  | declaration :: rest =>
      psWasmRewriteNatDeclaration declaration ::
        psWasmRewriteNatDeclarations rest

def psWasmAugmentNatRuntime
    (module : PsVerifiedIrModule) : PsVerifiedIrModule :=
  {
    imports := module.imports
    structures := module.structures
    inductives :=
      module.inductives ++ [psWasmNatRuntimeInductive]
    declarations :=
      psWasmRewriteNatDeclarations module.declarations
        ++ psWasmNatRuntimeDeclarations
  }
