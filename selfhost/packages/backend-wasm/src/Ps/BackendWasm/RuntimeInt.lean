import Ps.BackendWasm.RuntimeNat
import Ps.CompilerIr.Model

def psWasmIntRuntimeTypeName : String :=
  "ProofScript.Int"

def psWasmIntRuntimeOfNatName : String :=
  "ofNat"

def psWasmIntRuntimeNegSuccName : String :=
  "negSucc"

def psWasmIntRuntimeNegName : String :=
  "__ps_int_neg"

def psWasmIntRuntimeAddName : String :=
  "__ps_int_add"

def psWasmIntRuntimeSubName : String :=
  "__ps_int_sub"

def psWasmIntRuntimeMulName : String :=
  "__ps_int_mul"

def psWasmIntRuntimeEqName : String :=
  "__ps_int_eq"

def psWasmIntRuntimeLeName : String :=
  "__ps_int_le"

def psWasmIntRuntimeLtName : String :=
  "__ps_int_lt"

def psWasmIntRuntimeToI32BoundedName : String :=
  "__ps_int_to_i32_bounded"

def psWasmIntRuntimeType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int

def psWasmIntRuntimeBoolType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool

def psWasmIntRuntimeI32Type : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int32

def psWasmIntRuntimeOfNat
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.constructor
    psWasmIntRuntimeTypeName
    psWasmIntRuntimeOfNatName
    []
    [("value", value)]

def psWasmIntRuntimeNegSucc
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.constructor
    psWasmIntRuntimeTypeName
    psWasmIntRuntimeNegSuccName
    []
    [("value", value)]

def psWasmIntRuntimeCall
    (name : String)
    (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.call
    (PsVerifiedIrExpr.var name)
    []
    arguments

def psWasmIntRuntimeNatCall
    (name : String)
    (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.call
    (PsVerifiedIrExpr.var name)
    []
    arguments

def psWasmIntRuntimeBool
    (value : Bool) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool value)

def psWasmIntRuntimeNatBinding
    (name : String) : PsVerifiedIrMatchBinding :=
  {
    field := "value"
    name := name
    type := psWasmNatRuntimeType
  }

def psWasmIntRuntimeMatch
    (scrutinee : PsVerifiedIrExpr)
    (ofNatName : String)
    (ofNatBody : PsVerifiedIrExpr)
    (negSuccName : String)
    (negSuccBody : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.matchE
    psWasmIntRuntimeTypeName
    []
    scrutinee
    [
      (
        psWasmIntRuntimeOfNatName,
        [psWasmIntRuntimeNatBinding ofNatName],
        ofNatBody
      ),
      (
        psWasmIntRuntimeNegSuccName,
        [psWasmIntRuntimeNatBinding negSuccName],
        negSuccBody
      )
    ]

def psWasmIntRuntimeInductive : PsVerifiedIrInductive :=
  {
    name := psWasmIntRuntimeTypeName
    typeParameters := []
    constructors := [
      {
        name := psWasmIntRuntimeOfNatName
        fields := [
          {
            name := "value"
            type := psWasmNatRuntimeType
          }
        ]
      },
      {
        name := psWasmIntRuntimeNegSuccName
        fields := [
          {
            name := "value"
            type := psWasmNatRuntimeType
          }
        ]
      }
    ]
  }

def psWasmIntRuntimeUnaryParameter :
    List PsVerifiedIrParameter :=
  [
    {
      name := "value"
      type := psWasmIntRuntimeType
    }
  ]

def psWasmIntRuntimeBinaryParameters :
    List PsVerifiedIrParameter :=
  [
    {
      name := "a"
      type := psWasmIntRuntimeType
    },
    {
      name := "b"
      type := psWasmIntRuntimeType
    }
  ]

def psWasmIntRuntimeNegDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeNegName
    typeParameters := []
    parameters := psWasmIntRuntimeUnaryParameter
    resultType := psWasmIntRuntimeType
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "value")
        "n"
        (psWasmNatRuntimeMatch
          (PsVerifiedIrExpr.var "n")
          (psWasmIntRuntimeOfNat psWasmNatRuntimeZero)
          "pred"
          (psWasmIntRuntimeNegSucc
            (PsVerifiedIrExpr.var "pred")))
        "n"
        (psWasmIntRuntimeOfNat
          (psWasmNatRuntimeSucc
            (PsVerifiedIrExpr.var "n")))
  }

def psWasmIntRuntimeAddDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeAddName
    typeParameters := []
    parameters := psWasmIntRuntimeBinaryParameters
    resultType := psWasmIntRuntimeType
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        "aNat"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeOfNat
            (psWasmIntRuntimeNatCall
              psWasmNatRuntimeAddName
              [
                PsVerifiedIrExpr.var "aNat",
                PsVerifiedIrExpr.var "bNat"
              ]))
          "bNeg"
          (PsVerifiedIrExpr.ifE
            (psWasmIntRuntimeNatCall
              psWasmNatRuntimeLeName
              [
                PsVerifiedIrExpr.var "aNat",
                PsVerifiedIrExpr.var "bNeg"
              ])
            (psWasmIntRuntimeNegSucc
              (psWasmIntRuntimeNatCall
                psWasmNatRuntimeSubName
                [
                  PsVerifiedIrExpr.var "bNeg",
                  PsVerifiedIrExpr.var "aNat"
                ]))
            (psWasmIntRuntimeOfNat
              (psWasmIntRuntimeNatCall
                psWasmNatRuntimeSubName
                [
                  PsVerifiedIrExpr.var "aNat",
                  psWasmNatRuntimeSucc
                    (PsVerifiedIrExpr.var "bNeg")
                ]))))
        "aNeg"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (PsVerifiedIrExpr.ifE
            (psWasmIntRuntimeNatCall
              psWasmNatRuntimeLeName
              [
                PsVerifiedIrExpr.var "bNat",
                PsVerifiedIrExpr.var "aNeg"
              ])
            (psWasmIntRuntimeNegSucc
              (psWasmIntRuntimeNatCall
                psWasmNatRuntimeSubName
                [
                  PsVerifiedIrExpr.var "aNeg",
                  PsVerifiedIrExpr.var "bNat"
                ]))
            (psWasmIntRuntimeOfNat
              (psWasmIntRuntimeNatCall
                psWasmNatRuntimeSubName
                [
                  PsVerifiedIrExpr.var "bNat",
                  psWasmNatRuntimeSucc
                    (PsVerifiedIrExpr.var "aNeg")
                ])))
          "bNeg"
          (psWasmIntRuntimeNegSucc
            (psWasmNatRuntimeSucc
              (psWasmIntRuntimeNatCall
                psWasmNatRuntimeAddName
                [
                  PsVerifiedIrExpr.var "aNeg",
                  PsVerifiedIrExpr.var "bNeg"
                ]))))
  }

def psWasmIntRuntimeSubDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeSubName
    typeParameters := []
    parameters := psWasmIntRuntimeBinaryParameters
    resultType := psWasmIntRuntimeType
    body :=
      psWasmIntRuntimeCall
        psWasmIntRuntimeAddName
        [
          PsVerifiedIrExpr.var "a",
          psWasmIntRuntimeCall
            psWasmIntRuntimeNegName
            [PsVerifiedIrExpr.var "b"]
        ]
  }

def psWasmIntRuntimeMulDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeMulName
    typeParameters := []
    parameters := psWasmIntRuntimeBinaryParameters
    resultType := psWasmIntRuntimeType
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        "aNat"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeOfNat
            (psWasmIntRuntimeNatCall
              psWasmNatRuntimeMulName
              [
                PsVerifiedIrExpr.var "aNat",
                PsVerifiedIrExpr.var "bNat"
              ]))
          "bNeg"
          (psWasmIntRuntimeCall
            psWasmIntRuntimeNegName
            [
              psWasmIntRuntimeOfNat
                (psWasmIntRuntimeNatCall
                  psWasmNatRuntimeMulName
                  [
                    PsVerifiedIrExpr.var "aNat",
                    psWasmNatRuntimeSucc
                      (PsVerifiedIrExpr.var "bNeg")
                  ])
            ]))
        "aNeg"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeCall
            psWasmIntRuntimeNegName
            [
              psWasmIntRuntimeOfNat
                (psWasmIntRuntimeNatCall
                  psWasmNatRuntimeMulName
                  [
                    psWasmNatRuntimeSucc
                      (PsVerifiedIrExpr.var "aNeg"),
                    PsVerifiedIrExpr.var "bNat"
                  ])
            ])
          "bNeg"
          (psWasmIntRuntimeOfNat
            (psWasmIntRuntimeNatCall
              psWasmNatRuntimeMulName
              [
                psWasmNatRuntimeSucc
                  (PsVerifiedIrExpr.var "aNeg"),
                psWasmNatRuntimeSucc
                  (PsVerifiedIrExpr.var "bNeg")
              ])))
  }

def psWasmIntRuntimeEqDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeEqName
    typeParameters := []
    parameters := psWasmIntRuntimeBinaryParameters
    resultType := psWasmIntRuntimeBoolType
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        "aNat"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeNatCall
            psWasmNatRuntimeEqName
            [
              PsVerifiedIrExpr.var "aNat",
              PsVerifiedIrExpr.var "bNat"
            ])
          "bNeg"
          (psWasmIntRuntimeBool false))
        "aNeg"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeBool false)
          "bNeg"
          (psWasmIntRuntimeNatCall
            psWasmNatRuntimeEqName
            [
              PsVerifiedIrExpr.var "aNeg",
              PsVerifiedIrExpr.var "bNeg"
            ]))
  }

def psWasmIntRuntimeLeDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeLeName
    typeParameters := []
    parameters := psWasmIntRuntimeBinaryParameters
    resultType := psWasmIntRuntimeBoolType
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        "aNat"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeNatCall
            psWasmNatRuntimeLeName
            [
              PsVerifiedIrExpr.var "aNat",
              PsVerifiedIrExpr.var "bNat"
            ])
          "bNeg"
          (psWasmIntRuntimeBool false))
        "aNeg"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeBool true)
          "bNeg"
          (psWasmIntRuntimeNatCall
            psWasmNatRuntimeLeName
            [
              PsVerifiedIrExpr.var "bNeg",
              PsVerifiedIrExpr.var "aNeg"
            ]))
  }

def psWasmIntRuntimeLtDeclaration : PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeLtName
    typeParameters := []
    parameters := psWasmIntRuntimeBinaryParameters
    resultType := psWasmIntRuntimeBoolType
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "a")
        "aNat"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeNatCall
            psWasmNatRuntimeLtName
            [
              PsVerifiedIrExpr.var "aNat",
              PsVerifiedIrExpr.var "bNat"
            ])
          "bNeg"
          (psWasmIntRuntimeBool false))
        "aNeg"
        (psWasmIntRuntimeMatch
          (PsVerifiedIrExpr.var "b")
          "bNat"
          (psWasmIntRuntimeBool true)
          "bNeg"
          (psWasmIntRuntimeNatCall
            psWasmNatRuntimeLtName
            [
              PsVerifiedIrExpr.var "bNeg",
              PsVerifiedIrExpr.var "aNeg"
            ]))
  }

def psWasmIntRuntimeToI32BoundedDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmIntRuntimeToI32BoundedName
    typeParameters := []
    parameters := psWasmIntRuntimeUnaryParameter
    resultType := psWasmIntRuntimeI32Type
    body :=
      psWasmIntRuntimeMatch
        (PsVerifiedIrExpr.var "value")
        "n"
        (psWasmIntRuntimeNatCall
          psWasmNatRuntimeToU32BoundedName
          [PsVerifiedIrExpr.var "n"])
        "n"
        (PsVerifiedIrExpr.intrinsic
          (PsVerifiedIrIntrinsic.machineIntBinary
            PsVerifiedIrMachineIntegerType.int32
            PsVerifiedIrIntegerBinaryOp.sub)
          [
            PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.machineInteger
                PsVerifiedIrMachineIntegerType.int32
                0),
            psWasmIntRuntimeNatCall
              psWasmNatRuntimeToU32BoundedName
              [
                psWasmNatRuntimeSucc
                  (PsVerifiedIrExpr.var "n")
              ]
          ])
  }

def psWasmIntRuntimeDeclarations :
    List PsVerifiedIrDeclaration :=
  [
    psWasmIntRuntimeNegDeclaration,
    psWasmIntRuntimeAddDeclaration,
    psWasmIntRuntimeSubDeclaration,
    psWasmIntRuntimeMulDeclaration,
    psWasmIntRuntimeEqDeclaration,
    psWasmIntRuntimeLeDeclaration,
    psWasmIntRuntimeLtDeclaration,
    psWasmIntRuntimeToI32BoundedDeclaration
  ]

def psWasmIntLiteralExpr : Int -> PsVerifiedIrExpr
  | Int.ofNat value =>
      psWasmIntRuntimeOfNat
        (psWasmNatLiteralExpr value)
  | Int.negSucc value =>
      psWasmIntRuntimeNegSucc
        (psWasmNatLiteralExpr value)

def psWasmIntIntrinsicName :
    PsVerifiedIrIntrinsic -> Option String
  | .intNeg => some psWasmIntRuntimeNegName
  | .intAdd => some psWasmIntRuntimeAddName
  | .intSub => some psWasmIntRuntimeSubName
  | .intMul => some psWasmIntRuntimeMulName
  | .intEq => some psWasmIntRuntimeEqName
  | .intLe => some psWasmIntRuntimeLeName
  | .intLt => some psWasmIntRuntimeLtName
  | _ => none

def psWasmRewriteIntExprWithFuel :
    Nat -> PsVerifiedIrExpr -> PsVerifiedIrExpr
  | 0, expression => expression
  | fuel + 1, expression =>
      let rewrite := psWasmRewriteIntExprWithFuel fuel
      match expression with
      | .literal (.integer value) =>
          psWasmIntLiteralExpr value
      | .literal literal =>
          PsVerifiedIrExpr.literal literal
      | .var name =>
          PsVerifiedIrExpr.var name
      | .intrinsic operation arguments =>
          let rewritten := arguments.map rewrite
          match operation with
          | .intOfNat =>
              match rewritten with
              | [value] => psWasmIntRuntimeOfNat value
              | _ =>
                  PsVerifiedIrExpr.intrinsic operation rewritten
          | .intNegSucc =>
              match rewritten with
              | [value] => psWasmIntRuntimeNegSucc value
              | _ =>
                  PsVerifiedIrExpr.intrinsic operation rewritten
          | _ =>
              match psWasmIntIntrinsicName operation with
              | some name =>
                  psWasmIntRuntimeCall name rewritten
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

def psWasmRewriteIntExpr
    (expression : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmRewriteIntExprWithFuel 4096 expression

def psWasmRewriteIntDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    PsVerifiedIrDeclaration :=
  {
    name := declaration.name
    typeParameters := declaration.typeParameters
    parameters := declaration.parameters
    resultType := declaration.resultType
    body := psWasmRewriteIntExpr declaration.body
  }

def psWasmRewriteIntDeclarations :
    List PsVerifiedIrDeclaration ->
    List PsVerifiedIrDeclaration
  | [] => []
  | declaration :: rest =>
      psWasmRewriteIntDeclaration declaration ::
        psWasmRewriteIntDeclarations rest

def psWasmAugmentIntRuntime
    (module : PsVerifiedIrModule) : PsVerifiedIrModule :=
  {
    imports := module.imports
    structures := module.structures
    inductives :=
      module.inductives ++ [psWasmIntRuntimeInductive]
    declarations :=
      psWasmRewriteIntDeclarations module.declarations
        ++ psWasmIntRuntimeDeclarations
  }
