import Ps.CompilerIr.Specialize

def psIrSpecU32 : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32

def psIrSpecA : PsVerifiedIrType :=
  PsVerifiedIrType.typeParameter "A"

def psIrSpecListA : PsVerifiedIrType :=
  PsVerifiedIrType.named "List" [psIrSpecA]

def psIrSpecListU32 : PsVerifiedIrType :=
  PsVerifiedIrType.named "List" [psIrSpecU32]

def psIrSpecModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := [
      {
        name := "Box"
        typeParameters := [{ name := "A" }]
        fields := [
          {
            name := "value"
            type := psIrSpecA
          }
        ]
      }
    ]
    inductives := [
      {
        name := "List"
        typeParameters := [{ name := "A" }]
        constructors := [
          {
            name := "nil"
            fields := []
          },
          {
            name := "cons"
            fields := [
              {
                name := "head"
                type := psIrSpecA
              },
              {
                name := "tail"
                type := psIrSpecListA
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      {
        name := "id"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "value"
            type := psIrSpecA
          }
        ]
        resultType := psIrSpecA
        body := PsVerifiedIrExpr.var "value"
      },
      {
        name := "length"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "xs"
            type := psIrSpecListA
          }
        ]
        resultType := psIrSpecU32
        body :=
          PsVerifiedIrExpr.matchE
            "List"
            [psIrSpecA]
            (PsVerifiedIrExpr.var "xs")
            [
              (
                "nil",
                [],
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    0)
              ),
              (
                "cons",
                [
                  {
                    field := "head"
                    name := "head"
                    type := psIrSpecA
                  },
                  {
                    field := "tail"
                    name := "tail"
                    type := psIrSpecListA
                  }
                ],
                PsVerifiedIrExpr.intrinsic
                  (PsVerifiedIrIntrinsic.machineIntBinary
                    PsVerifiedIrMachineIntegerType.uint32
                    PsVerifiedIrIntegerBinaryOp.add)
                  []
                  [
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.machineInteger
                        PsVerifiedIrMachineIntegerType.uint32
                        1),
                    PsVerifiedIrExpr.call
                      (PsVerifiedIrExpr.var "length")
                      [psIrSpecA]
                      [PsVerifiedIrExpr.var "tail"]
                  ]
              )
            ]
      },
      {
        name := "boxRoundTrip"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psIrSpecU32
          }
        ]
        resultType := psIrSpecU32
        body :=
          PsVerifiedIrExpr.projection
            "Box"
            [psIrSpecU32]
            (PsVerifiedIrExpr.record
              "Box"
              [psIrSpecU32]
              [("value", PsVerifiedIrExpr.var "value")])
            "value"
      },
      {
        name := "idU32"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psIrSpecU32
          }
        ]
        resultType := psIrSpecU32
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "id")
            [psIrSpecU32]
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "lengthTwo"
        typeParameters := []
        parameters := []
        resultType := psIrSpecU32
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "length")
            [psIrSpecU32]
            [
              PsVerifiedIrExpr.constructor
                "List"
                "cons"
                [psIrSpecU32]
                [
                  (
                    "head",
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.machineInteger
                        PsVerifiedIrMachineIntegerType.uint32
                        10)
                  ),
                  (
                    "tail",
                    PsVerifiedIrExpr.constructor
                      "List"
                      "cons"
                      [psIrSpecU32]
                      [
                        (
                          "head",
                          PsVerifiedIrExpr.literal
                            (PsVerifiedIrLiteral.machineInteger
                              PsVerifiedIrMachineIntegerType.uint32
                              20)
                        ),
                        (
                          "tail",
                          PsVerifiedIrExpr.constructor
                            "List"
                            "nil"
                            [psIrSpecU32]
                            []
                        )
                      ]
                  )
                ]
            ]
      }
    ]
  }

def psIrSpecBoxName : String :=
  "Box$spec$U32"

def psIrSpecListName : String :=
  "List$spec$U32"

def psIrSpecIdName : String :=
  "id$spec$U32"

def psIrSpecLengthName : String :=
  "length$spec$U32"

def psIrSpecIsBox : PsVerifiedIrStructure -> Bool
  | {
      name := name,
      typeParameters := [],
      fields := [{ name := "value", type := .primitive .uint32 }]
    } => name == psIrSpecBoxName
  | _ => false

def psIrSpecIsList : PsVerifiedIrInductive -> Bool
  | {
      name := name,
      typeParameters := [],
      constructors := [
        { name := "nil", fields := [] },
        {
          name := "cons",
          fields := [
            { name := "head", type := .primitive .uint32 },
            { name := "tail", type := .named tailName [] }
          ]
        }
      ]
    } =>
      name == psIrSpecListName
        && tailName == psIrSpecListName
  | _ => false

def psIrSpecIsId : PsVerifiedIrDeclaration -> Bool
  | {
      name := name,
      typeParameters := [],
      parameters := [{ name := "value", type := .primitive .uint32 }],
      resultType := .primitive .uint32,
      body := .var "value"
    } => name == psIrSpecIdName
  | _ => false

def psIrSpecIsLength : PsVerifiedIrDeclaration -> Bool
  | {
      name := name,
      typeParameters := [],
      parameters := [
        {
          name := "xs",
          type := .named listName []
        }
      ],
      resultType := .primitive .uint32,
      body := .matchE matchName [] (.var "xs") _
    } =>
      name == psIrSpecLengthName
        && listName == psIrSpecListName
        && matchName == psIrSpecListName
  | _ => false

def psIrSpecNoGenericStructure :
    List PsVerifiedIrStructure -> Bool
  | [] => true
  | structureInfo :: rest =>
      structureInfo.name != "Box"
        && psIrSpecNoGenericStructure rest

def psIrSpecNoGenericInductive :
    List PsVerifiedIrInductive -> Bool
  | [] => true
  | inductiveInfo :: rest =>
      inductiveInfo.name != "List"
        && psIrSpecNoGenericInductive rest

def psIrSpecNoGenericDeclaration :
    List PsVerifiedIrDeclaration -> Bool
  | [] => true
  | declaration :: rest =>
      declaration.name != "id"
        && declaration.name != "length"
        && psIrSpecNoGenericDeclaration rest

def psTestGenericSpecialization : Bool :=
  match psIrSpecializeModule psIrSpecModule with
  | Except.error _ => false
  | Except.ok module =>
      match
          psIrSpecializeFindStructure
            module.structures
            psIrSpecBoxName,
          psIrSpecializeFindInductive
            module.inductives
            psIrSpecListName,
          psIrSpecializeFindDeclaration
            module.declarations
            psIrSpecIdName,
          psIrSpecializeFindDeclaration
            module.declarations
            psIrSpecLengthName with
      | some boxInfo, some listInfo, some idInfo, some lengthInfo =>
          psIrSpecIsBox boxInfo
            && psIrSpecIsList listInfo
            && psIrSpecIsId idInfo
            && psIrSpecIsLength lengthInfo
            && psIrSpecNoGenericStructure module.structures
            && psIrSpecNoGenericInductive module.inductives
            && psIrSpecNoGenericDeclaration module.declarations
      | _, _, _, _ => false

def main : IO Unit := do
  if psTestGenericSpecialization then
    IO.println "PSC1_IR_SPECIALIZE_TESTS: PASS"
  else
    throw (IO.userError "PSC1_IR_SPECIALIZE_TESTS: FAIL")
