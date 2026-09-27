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

def psSelfHostReplacePreludeAxiom
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : PsEnvironment :=
  match psEnvironmentAddReplacingAxiom environment declaration with
  | none => environment
  | some next => next

def psSelfHostPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u"
  let alphaName := psRootName "α"
  let motiveName := psRootName "_motive"
  let nilMinorName := psRootName "_nil"
  let consMinorName := psRootName "_cons"
  let noneMinorName := psRootName "_none"
  let someMinorName := psRootName "_some"
  let headName := psRootName "head"
  let tailName := psRootName "tail"
  let valueName := psRootName "value"
  let hypothesisName := psRootName "_ih"
  let majorName := psRootName "_major"
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let listType :=
    PsExpr.forallE
      alphaName
      typeType
      typeType
      PsBinderInfo.explicit
  let nilType :=
    PsExpr.forallE
      alphaName
      typeType
      (psSelfHostListOf (PsExpr.bvar 0))
      PsBinderInfo.implicit
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
      PsBinderInfo.implicit
  let listMotiveType :=
    PsExpr.forallE
      majorName
      (psSelfHostListOf (PsExpr.bvar 0))
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit
  let nilMinorType :=
    PsExpr.app
      (PsExpr.bvar 0)
      (psSelfHostListNilOf (PsExpr.bvar 1))
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
      PsBinderInfo.explicit
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
      PsBinderInfo.implicit
  let optionType :=
    PsExpr.forallE
      alphaName
      typeType
      typeType
      PsBinderInfo.explicit
  let noneType :=
    PsExpr.forallE
      alphaName
      typeType
      (psSelfHostOptionOf (PsExpr.bvar 0))
      PsBinderInfo.implicit
  let someType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        valueName
        (PsExpr.bvar 0)
        (psSelfHostOptionOf (PsExpr.bvar 1))
        PsBinderInfo.explicit)
      PsBinderInfo.implicit
  let optionMotiveType :=
    PsExpr.forallE
      majorName
      (psSelfHostOptionOf (PsExpr.bvar 0))
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit
  let noneMinorType :=
    PsExpr.app
      (PsExpr.bvar 0)
      (psSelfHostOptionNoneOf (PsExpr.bvar 1))
  let someMinorType :=
    PsExpr.forallE
      valueName
      (PsExpr.bvar 2)
      (PsExpr.app
        (PsExpr.bvar 2)
        (psSelfHostOptionSomeOf
          (PsExpr.bvar 3)
          (PsExpr.bvar 0)))
      PsBinderInfo.explicit
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
      PsBinderInfo.implicit
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
          false))
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
          []))
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
          [1]))
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
          2))
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
          false))
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
          []))
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
          []))
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
        2))

def psSelfHostRuntimePreludeDeclarations : List PsDeclaration :=
  match
      psEnvironmentFind
        psSelfHostPreludeEnvironment
        psListName with
  | none => List.nil
  | some listDeclaration =>
      match
          psEnvironmentFind
            psSelfHostPreludeEnvironment
            psSelfHostListNilName with
      | none => List.nil
      | some nilDeclaration =>
          match
              psEnvironmentFind
                psSelfHostPreludeEnvironment
                psSelfHostListConsName with
          | none => List.nil
          | some consDeclaration =>
              match
                  psEnvironmentFind
                    psSelfHostPreludeEnvironment
                    psSelfHostListRecName with
              | none => List.nil
              | some listRecDeclaration =>
                  match
                      psEnvironmentFind
                        psSelfHostPreludeEnvironment
                        psOptionName with
                  | none => List.nil
                  | some optionDeclaration =>
                      match
                          psEnvironmentFind
                            psSelfHostPreludeEnvironment
                            psSelfHostOptionNoneName with
                      | none => List.nil
                      | some noneDeclaration =>
                          match
                              psEnvironmentFind
                                psSelfHostPreludeEnvironment
                                psSelfHostOptionSomeName with
                          | none => List.nil
                          | some someDeclaration =>
                              match
                                  psEnvironmentFind
                                    psSelfHostPreludeEnvironment
                                    psSelfHostOptionRecName with
                              | none => List.nil
                              | some optionRecDeclaration =>
                                  [
                                    listDeclaration,
                                    nilDeclaration,
                                    consDeclaration,
                                    listRecDeclaration,
                                    optionDeclaration,
                                    noneDeclaration,
                                    someDeclaration,
                                    optionRecDeclaration
                                  ]
