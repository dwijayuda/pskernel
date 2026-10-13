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

def psSelfHostListOf (alpha : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psListName [level])
    alpha

def psSelfHostListNilOf (alpha : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psSelfHostListNilName [level])
    alpha

def psSelfHostListConsOf
    (alpha head tail : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.constE psSelfHostListConsName [level])
        alpha)
      head)
    tail

def psSelfHostOptionOf (alpha : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psOptionName [level])
    alpha

def psSelfHostOptionNoneOf (alpha : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psSelfHostOptionNoneName [level])
    alpha

def psSelfHostOptionSomeOf
    (alpha value : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.constE psSelfHostOptionSomeName [level])
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
  | none => environment
  | some next => next

-- Universe-polymorphic Option. The recursor's result sort and element
-- universe are independent, in the kernel-generated order [v, u].
def psSelfHostOptionDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let level := PsLevel.param u
  let type := PsExpr.sortE (.succ level)
  let alpha := PsExpr.fvar 0
  let option := psSelfHostOptionOf alpha level
  let motive := PsExpr.fvar 1
  let noneValue := psSelfHostOptionNoneOf alpha level
  let value := PsExpr.fvar 4
  let someValue := psSelfHostOptionSomeOf alpha value level
  let parameters := fun body => psLogicPi 0 "α" type body .implicit
  let recType := parameters
    (psLogicPi 1 "motive"
      (psLogicPi 5 "value" option (.sortE (.param v)))
      (psLogicPi 2 "none" (.app motive noneValue)
        (psLogicPi 3 "some"
          (psLogicPi 4 "value" alpha (.app motive someValue))
          (psLogicPi 5 "value" option (.app motive (.fvar 5)))))
      .implicit)
  [ .inductiveDecl (.mk psOptionName [u]
      (psLogicPi 0 "α" type type) 1 0
      [psSelfHostOptionNoneName, psSelfHostOptionSomeName] false),
    .constructorDecl (.mk psSelfHostOptionNoneName [u]
      (parameters option) psOptionName 0 1 0 []),
    .constructorDecl (.mk psSelfHostOptionSomeName [u]
      (parameters (psLogicPi 4 "value" alpha option)) psOptionName 1 1 1 []),
    .recursorDecl (.mk psSelfHostOptionRecName [v, u] recType
      [psOptionName] 1 0 1 2) ]

-- Lean 4.35.0 Init.Prelude: the element universe and recursor result
-- sort are independent. Ground authoring helpers explicitly instantiate u=0.
def psSelfHostListDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let level := PsLevel.param u
  let type := PsExpr.sortE (.succ level)
  let alpha := PsExpr.fvar 0
  let list := psSelfHostListOf alpha level
  let motive := PsExpr.fvar 1
  let parameters := fun body => psLogicPi 0 "α" type body .implicit
  let cons := psSelfHostListConsOf alpha (.fvar 4) (.fvar 5) level
  let minor := psLogicPi 4 "head" alpha
    (psLogicPi 5 "tail" list
      (psLogicPi 6 "ih" (.app motive (.fvar 5)) (.app motive cons)))
  let recType := parameters
    (psLogicPi 1 "motive" (psLogicPi 7 "value" list (.sortE (.param v)))
      (psLogicPi 2 "nil" (.app motive (psSelfHostListNilOf alpha level))
        (psLogicPi 3 "cons" minor
          (psLogicPi 7 "value" list (.app motive (.fvar 7))))) .implicit)
  [ .inductiveDecl (.mk psListName [u]
      (psLogicPi 0 "α" type type) 1 0
      [psSelfHostListNilName, psSelfHostListConsName] false),
    .constructorDecl (.mk psSelfHostListNilName [u]
      (parameters list) psListName 0 1 0 []),
    .constructorDecl (.mk psSelfHostListConsName [u]
      (parameters (psLogicPi 4 "head" alpha (psLogicPi 5 "tail" list list)))
      psListName 1 1 2 [1]),
    .recursorDecl (.mk psSelfHostListRecName [v, u] recType [psListName] 1 0 1 2) ]

def psSelfHostPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u";
  let errorTypeName := psRootName "ε";
  let valueTypeName := psRootName "α";
  let motiveName := psRootName "_motive";
  let errorMinorName := psRootName "_error";
  let okMinorName := psRootName "_ok";
  let valueName := psRootName "value";
  let errorName := psRootName "error";
  let majorName := psRootName "_major";
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
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
  let withListRec :=
    psSelfHostListDeclarations.foldl psSelfHostReplacePreludeAxiom psBootstrapPreludeEnvironment;
  let withOptionRec :=
    psSelfHostOptionDeclarations.foldl psSelfHostReplacePreludeAxiom withListRec;
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
                                  match
                                      psEnvironmentFind
                                        psSelfHostPreludeEnvironment
                                        psSelfHostExceptName with
                                  | none => List.nil
                                  | some exceptDeclaration =>
                                      match
                                          psEnvironmentFind
                                            psSelfHostPreludeEnvironment
                                            psSelfHostExceptErrorName with
                                      | none => List.nil
                                      | some exceptErrorDeclaration =>
                                          match
                                              psEnvironmentFind
                                                psSelfHostPreludeEnvironment
                                                psSelfHostExceptOkName with
                                          | none => List.nil
                                          | some exceptOkDeclaration =>
                                              match
                                                  psEnvironmentFind
                                                    psSelfHostPreludeEnvironment
                                                    psSelfHostExceptRecName with
                                              | none => List.nil
                                              | some exceptRecDeclaration =>
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
