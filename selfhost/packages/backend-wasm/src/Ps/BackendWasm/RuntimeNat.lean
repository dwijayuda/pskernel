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

def psWasmNatRuntimeType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psWasmNatRuntimeBoolType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool

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
    psWasmNatRuntimeModDeclaration
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

structure PsWasmNatRewriteFieldsResult where
  fields : List (String × PsVerifiedIrExpr)

structure PsWasmNatRewriteAlternativesResult where
  alternatives :
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr)

def psWasmRewriteNatExprList :
    List PsVerifiedIrExpr -> List PsVerifiedIrExpr
  | [] => []
  | expression :: rest =>
      psWasmRewriteNatExpr expression ::
        psWasmRewriteNatExprList rest

termination_by expressions => expressions.length
where
  psWasmRewriteNatExpr :
      PsVerifiedIrExpr -> PsVerifiedIrExpr
    | .literal (.natural value) =>
        psWasmNatLiteralExpr value
    | .literal literal =>
        PsVerifiedIrExpr.literal literal
    | .var name =>
        PsVerifiedIrExpr.var name
    | .intrinsic operation arguments =>
        let rewritten :=
          psWasmRewriteNatExprList arguments
        match psWasmNatIntrinsicName operation with
        | some name =>
            psWasmNatRuntimeCall name rewritten
        | none =>
            PsVerifiedIrExpr.intrinsic operation rewritten
    | .lambda parameters resultType body =>
        PsVerifiedIrExpr.lambda
          parameters
          resultType
          (psWasmRewriteNatExpr body)
    | .call fn typeArguments arguments =>
        PsVerifiedIrExpr.call
          (psWasmRewriteNatExpr fn)
          typeArguments
          (psWasmRewriteNatExprList arguments)
    | .letE name type value body =>
        PsVerifiedIrExpr.letE
          name
          type
          (psWasmRewriteNatExpr value)
          (psWasmRewriteNatExpr body)
    | .ifE condition thenBranch elseBranch =>
        PsVerifiedIrExpr.ifE
          (psWasmRewriteNatExpr condition)
          (psWasmRewriteNatExpr thenBranch)
          (psWasmRewriteNatExpr elseBranch)
    | .record structureName typeArguments fields =>
        PsVerifiedIrExpr.record
          structureName
          typeArguments
          (fields.map
            (fun field =>
              (field.1, psWasmRewriteNatExpr field.2)))
    | .projection structureName typeArguments target field =>
        PsVerifiedIrExpr.projection
          structureName
          typeArguments
          (psWasmRewriteNatExpr target)
          field
    | .constructor inductiveName constructorName typeArguments fields =>
        PsVerifiedIrExpr.constructor
          inductiveName
          constructorName
          typeArguments
          (fields.map
            (fun field =>
              (field.1, psWasmRewriteNatExpr field.2)))
    | .matchE inductiveName typeArguments scrutinee alternatives =>
        PsVerifiedIrExpr.matchE
          inductiveName
          typeArguments
          (psWasmRewriteNatExpr scrutinee)
          (alternatives.map
            (fun alternative =>
              (
                alternative.1,
                alternative.2.1,
                psWasmRewriteNatExpr alternative.2.2
              )))

def psWasmRewriteNatExpr
    (expression : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmRewriteNatExprList [expression]
    |>.headD expression

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
