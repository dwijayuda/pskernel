import Ps.Environment.Prelude

def psSelfHostListNilName : PsName :=
  psNameAppendStr psListName "nil"

def psSelfHostListConsName : PsName :=
  psNameAppendStr psListName "cons"

def psSelfHostListRecName : PsName :=
  psNameAppendStr psListName "rec"

def psSelfHostOptionNoneName : PsName :=
  psNameAppendStr psOptionName "none"

def psSelfHostOptionSomeName : PsName :=
  psNameAppendStr psOptionName "some"

def psSelfHostOptionRecName : PsName :=
  psNameAppendStr psOptionName "rec"

def psSelfHostExceptName : PsName :=
  psRootName "Except"

def psSelfHostExceptErrorName : PsName :=
  psNameAppendStr psSelfHostExceptName "error"

def psSelfHostExceptOkName : PsName :=
  psNameAppendStr psSelfHostExceptName "ok"

def psSelfHostExceptRecName : PsName :=
  psNameAppendStr psSelfHostExceptName "rec"

def psSelfHostListOf (alpha : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psListName [])
    alpha

def psSelfHostListNilOf (alpha : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psSelfHostListNilName [])
    alpha

def psSelfHostListConsOf
    (alpha head tail : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.constE psSelfHostListConsName [])
        alpha)
      head)
    tail

def psSelfHostOptionOf (alpha : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psOptionName [])
    alpha

def psSelfHostOptionNoneOf (alpha : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psSelfHostOptionNoneName [])
    alpha

def psSelfHostOptionSomeOf
    (alpha value : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.constE psSelfHostOptionSomeName [])
      alpha)
    value

def psSelfHostExceptOf
    (errorType valueType : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.constE psSelfHostExceptName [])
      errorType)
    valueType

def psSelfHostExceptErrorOf
    (errorType valueType error : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.constE psSelfHostExceptErrorName [])
        errorType)
      valueType)
    error

def psSelfHostExceptOkOf
    (errorType valueType value : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.constE psSelfHostExceptOkName [])
        errorType)
      valueType)
    value

def psSelfHostReplacePreludeAxiom
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : PsEnvironment :=
  match psEnvironmentAddReplacingAxiom environment declaration with
  | Option.none => environment
  | Option.some next => next

def psSelfHostPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u";
  let alphaName := psRootName "α";
  let errorTypeName := psRootName "ε";
  let valueTypeName := psRootName "α";
  let motiveName := psRootName "_motive";
  let nilMinorName := psRootName "_nil";
  let consMinorName := psRootName "_cons";
  let noneMinorName := psRootName "_none";
  let someMinorName := psRootName "_some";
  let errorMinorName := psRootName "_error";
  let okMinorName := psRootName "_ok";
  let headName := psRootName "head";
  let tailName := psRootName "tail";
  let valueName := psRootName "value";
  let errorName := psRootName "error";
  let hypothesisName := psRootName "_ih";
  let majorName := psRootName "_major";
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let listType :=
    PsExpr.forallE
      alphaName
      typeType
      typeType
      PsBinderInfo.explicit;
  let nilType :=
    PsExpr.forallE
      alphaName
      typeType
      (psSelfHostListOf (PsExpr.bvar 0))
      PsBinderInfo.implicit;
  let consType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        headName
        (PsExpr.bvar 0)
        (PsExpr.forallE
          tailName
          (psSelfHostListOf (PsExpr.bvar 1))
          (psSelfHostListOf (PsExpr.bvar 2))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let listMotiveType :=
    PsExpr.forallE
      majorName
      (psSelfHostListOf (PsExpr.bvar 0))
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit;
  let nilMinorType :=
    PsExpr.app
      (PsExpr.bvar 0)
      (psSelfHostListNilOf (PsExpr.bvar 1));
  let consMinorType :=
    PsExpr.forallE
      headName
      (PsExpr.bvar 2)
      (PsExpr.forallE
        tailName
        (psSelfHostListOf (PsExpr.bvar 3))
        (PsExpr.forallE
          hypothesisName
          (PsExpr.app
            (PsExpr.bvar 3)
            (PsExpr.bvar 0))
          (PsExpr.app
            (PsExpr.bvar 4)
            (psSelfHostListConsOf
              (PsExpr.bvar 5)
              (PsExpr.bvar 2)
              (PsExpr.bvar 1)))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let listRecType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        motiveName
        listMotiveType
        (PsExpr.forallE
          nilMinorName
          nilMinorType
          (PsExpr.forallE
            consMinorName
            consMinorType
            (PsExpr.forallE
              majorName
              (psSelfHostListOf (PsExpr.bvar 3))
              (PsExpr.app
                (PsExpr.bvar 3)
                (PsExpr.bvar 0))
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let optionType :=
    PsExpr.forallE
      alphaName
      typeType
      typeType
      PsBinderInfo.explicit;
  let noneType :=
    PsExpr.forallE
      alphaName
      typeType
      (psSelfHostOptionOf (PsExpr.bvar 0))
      PsBinderInfo.implicit;
  let someType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        valueName
        (PsExpr.bvar 0)
        (psSelfHostOptionOf (PsExpr.bvar 1))
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let optionMotiveType :=
    PsExpr.forallE
      majorName
      (psSelfHostOptionOf (PsExpr.bvar 0))
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit;
  let noneMinorType :=
    PsExpr.app
      (PsExpr.bvar 0)
      (psSelfHostOptionNoneOf (PsExpr.bvar 1));
  let someMinorType :=
    PsExpr.forallE
      valueName
      (PsExpr.bvar 2)
      (PsExpr.app
        (PsExpr.bvar 2)
        (psSelfHostOptionSomeOf
          (PsExpr.bvar 3)
          (PsExpr.bvar 0)))
      PsBinderInfo.explicit;
  let optionRecType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        motiveName
        optionMotiveType
        (PsExpr.forallE
          noneMinorName
          noneMinorType
          (PsExpr.forallE
            someMinorName
            someMinorType
            (PsExpr.forallE
              majorName
              (psSelfHostOptionOf (PsExpr.bvar 3))
              (PsExpr.app
                (PsExpr.bvar 3)
                (PsExpr.bvar 0))
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let exceptType :=
    PsExpr.forallE
      errorTypeName
      typeType
      (PsExpr.forallE
        valueTypeName
        typeType
        typeType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let exceptErrorType :=
    PsExpr.forallE
      errorTypeName
      typeType
      (PsExpr.forallE
        valueTypeName
        typeType
        (PsExpr.forallE
          errorName
          (PsExpr.bvar 1)
          (psSelfHostExceptOf
            (PsExpr.bvar 2)
            (PsExpr.bvar 1))
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let exceptOkType :=
    PsExpr.forallE
      errorTypeName
      typeType
      (PsExpr.forallE
        valueTypeName
        typeType
        (PsExpr.forallE
          valueName
          (PsExpr.bvar 0)
          (psSelfHostExceptOf
            (PsExpr.bvar 2)
            (PsExpr.bvar 1))
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let exceptMotiveType :=
    PsExpr.forallE
      majorName
      (psSelfHostExceptOf
        (PsExpr.bvar 1)
        (PsExpr.bvar 0))
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit;
  let exceptErrorMinorType :=
    PsExpr.forallE
      errorName
      (PsExpr.bvar 2)
      (PsExpr.app
        (PsExpr.bvar 1)
        (psSelfHostExceptErrorOf
          (PsExpr.bvar 3)
          (PsExpr.bvar 2)
          (PsExpr.bvar 0)))
      PsBinderInfo.explicit;
  let exceptOkMinorType :=
    PsExpr.forallE
      valueName
      (PsExpr.bvar 2)
      (PsExpr.app
        (PsExpr.bvar 2)
        (psSelfHostExceptOkOf
          (PsExpr.bvar 4)
          (PsExpr.bvar 3)
          (PsExpr.bvar 0)))
      PsBinderInfo.explicit;
  let exceptRecType :=
    PsExpr.forallE
      errorTypeName
      typeType
      (PsExpr.forallE
        valueTypeName
        typeType
        (PsExpr.forallE
          motiveName
          exceptMotiveType
          (PsExpr.forallE
            errorMinorName
            exceptErrorMinorType
            (PsExpr.forallE
              okMinorName
              exceptOkMinorType
              (PsExpr.forallE
                majorName
                (psSelfHostExceptOf
                  (PsExpr.bvar 4)
                  (PsExpr.bvar 3))
                (PsExpr.app
                  (PsExpr.bvar 3)
                  (PsExpr.bvar 0))
                PsBinderInfo.explicit)
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let withList :=
    psSelfHostReplacePreludeAxiom
      psBootstrapPreludeEnvironment
      (PsDeclaration.inductiveDecl
        (PsInductiveInfo.mk
          psListName
          []
          listType
          1
          0
          [psSelfHostListNilName, psSelfHostListConsName]
          false));
  let withNil :=
    psPreludeAdd withList
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psSelfHostListNilName
          []
          nilType
          psListName
          0
          1
          0
          []));
  let withCons :=
    psPreludeAdd withNil
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psSelfHostListConsName
          []
          consType
          psListName
          1
          1
          2
          [1]));
  let withListRec :=
    psPreludeAdd withCons
      (PsDeclaration.recursorDecl
        (PsRecursorInfo.mk
          psSelfHostListRecName
          [uName]
          listRecType
          [psListName]
          1
          0
          1
          2));
  let withOption :=
    psSelfHostReplacePreludeAxiom
      withListRec
      (PsDeclaration.inductiveDecl
        (PsInductiveInfo.mk
          psOptionName
          []
          optionType
          1
          0
          [psSelfHostOptionNoneName, psSelfHostOptionSomeName]
          false));
  let withNone :=
    psPreludeAdd withOption
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psSelfHostOptionNoneName
          []
          noneType
          psOptionName
          0
          1
          0
          []));
  let withSome :=
    psPreludeAdd withNone
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psSelfHostOptionSomeName
          []
          someType
          psOptionName
          1
          1
          1
          []));
  let withOptionRec :=
    psPreludeAdd withSome
      (PsDeclaration.recursorDecl
        (PsRecursorInfo.mk
          psSelfHostOptionRecName
          [uName]
          optionRecType
          [psOptionName]
          1
          0
          1
          2));
  let withExcept :=
    psSelfHostReplacePreludeAxiom
      withOptionRec
      (PsDeclaration.inductiveDecl
        (PsInductiveInfo.mk
          psSelfHostExceptName
          []
          exceptType
          2
          0
          [psSelfHostExceptErrorName, psSelfHostExceptOkName]
          false));
  let withExceptError :=
    psPreludeAdd withExcept
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psSelfHostExceptErrorName
          []
          exceptErrorType
          psSelfHostExceptName
          0
          2
          1
          []));
  let withExceptOk :=
    psPreludeAdd withExceptError
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psSelfHostExceptOkName
          []
          exceptOkType
          psSelfHostExceptName
          1
          2
          1
          []));
  psPreludeAdd withExceptOk
    (PsDeclaration.recursorDecl
      (PsRecursorInfo.mk
        psSelfHostExceptRecName
        [uName]
        exceptRecType
        [psSelfHostExceptName]
        2
        0
        1
        2))

def psSelfHostRuntimePreludeDeclarations : List PsDeclaration :=
  match
      psEnvironmentFind
        psSelfHostPreludeEnvironment
        psListName with
  | Option.none => List.nil
  | Option.some listDeclaration =>
      match
          psEnvironmentFind
            psSelfHostPreludeEnvironment
            psSelfHostListNilName with
      | Option.none => List.nil
      | Option.some nilDeclaration =>
          match
              psEnvironmentFind
                psSelfHostPreludeEnvironment
                psSelfHostListConsName with
          | Option.none => List.nil
          | Option.some consDeclaration =>
              match
                  psEnvironmentFind
                    psSelfHostPreludeEnvironment
                    psSelfHostListRecName with
              | Option.none => List.nil
              | Option.some listRecDeclaration =>
                  match
                      psEnvironmentFind
                        psSelfHostPreludeEnvironment
                        psOptionName with
                  | Option.none => List.nil
                  | Option.some optionDeclaration =>
                      match
                          psEnvironmentFind
                            psSelfHostPreludeEnvironment
                            psSelfHostOptionNoneName with
                      | Option.none => List.nil
                      | Option.some noneDeclaration =>
                          match
                              psEnvironmentFind
                                psSelfHostPreludeEnvironment
                                psSelfHostOptionSomeName with
                          | Option.none => List.nil
                          | Option.some someDeclaration =>
                              match
                                  psEnvironmentFind
                                    psSelfHostPreludeEnvironment
                                    psSelfHostOptionRecName with
                              | Option.none => List.nil
                              | Option.some optionRecDeclaration =>
                                  match
                                      psEnvironmentFind
                                        psSelfHostPreludeEnvironment
                                        psSelfHostExceptName with
                                  | Option.none => List.nil
                                  | Option.some exceptDeclaration =>
                                      match
                                          psEnvironmentFind
                                            psSelfHostPreludeEnvironment
                                            psSelfHostExceptErrorName with
                                      | Option.none => List.nil
                                      | Option.some exceptErrorDeclaration =>
                                          match
                                              psEnvironmentFind
                                                psSelfHostPreludeEnvironment
                                                psSelfHostExceptOkName with
                                          | Option.none => List.nil
                                          | Option.some exceptOkDeclaration =>
                                              match
                                                  psEnvironmentFind
                                                    psSelfHostPreludeEnvironment
                                                    psSelfHostExceptRecName with
                                              | Option.none => List.nil
                                              | Option.some exceptRecDeclaration =>
                                                  [
                                                    listDeclaration,
                                                    nilDeclaration,
                                                    consDeclaration,
                                                    listRecDeclaration,
                                                    optionDeclaration,
                                                    noneDeclaration,
                                                    someDeclaration,
                                                    optionRecDeclaration,
                                                    exceptDeclaration,
                                                    exceptErrorDeclaration,
                                                    exceptOkDeclaration,
                                                    exceptRecDeclaration
                                                  ]
