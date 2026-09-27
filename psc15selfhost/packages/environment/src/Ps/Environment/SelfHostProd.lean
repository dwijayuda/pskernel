import Ps.Environment.SelfHostPrelude

def psSelfHostProdRecName : PsName :=
  psNameAppendStr psProdName "rec"

def psSelfHostIntReprName : PsName :=
  psNameAppendStr psIntName "repr"

def psSelfHostProdOf
    (alpha beta : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.constE psProdName [])
      alpha)
    beta

def psSelfHostProdMkOf
    (alpha beta fst snd : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.app
          (PsExpr.constE psProdMkName [])
          alpha)
        beta)
      fst)
    snd

def psSelfHostProdPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u";
  let alphaName := psRootName "α";
  let betaName := psRootName "β";
  let motiveName := psRootName "_motive";
  let minorName := psRootName "_mk";
  let majorName := psRootName "_major";
  let fstName := psRootName "fst";
  let sndName := psRootName "snd";
  let valueName := psRootName "value";
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let intType := PsExpr.constE psIntName [];
  let stringType := PsExpr.constE psStringName [];
  let intReprType :=
    PsExpr.forallE
      valueName
      intType
      stringType
      PsBinderInfo.explicit;
  let prodType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        betaName
        typeType
        typeType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let prodMkType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        betaName
        typeType
        (PsExpr.forallE
          fstName
          (PsExpr.bvar 1)
          (PsExpr.forallE
            sndName
            (PsExpr.bvar 1)
            (psSelfHostProdOf
              (PsExpr.bvar 3)
              (PsExpr.bvar 2))
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let motiveType :=
    PsExpr.forallE
      majorName
      (psSelfHostProdOf
        (PsExpr.bvar 1)
        (PsExpr.bvar 0))
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit;
  let minorType :=
    PsExpr.forallE
      fstName
      (PsExpr.bvar 2)
      (PsExpr.forallE
        sndName
        (PsExpr.bvar 2)
        (PsExpr.app
          (PsExpr.bvar 2)
          (psSelfHostProdMkOf
            (PsExpr.bvar 4)
            (PsExpr.bvar 3)
            (PsExpr.bvar 1)
            (PsExpr.bvar 0)))
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let recType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        betaName
        typeType
        (PsExpr.forallE
          motiveName
          motiveType
          (PsExpr.forallE
            minorName
            minorType
            (PsExpr.forallE
              majorName
              (psSelfHostProdOf
                (PsExpr.bvar 3)
                (PsExpr.bvar 2))
              (PsExpr.app
                (PsExpr.bvar 2)
                (PsExpr.bvar 0))
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let withProd :=
    psSelfHostReplacePreludeAxiom
      psSelfHostPreludeEnvironment
      (PsDeclaration.inductiveDecl
        (PsInductiveInfo.mk
          psProdName
          []
          prodType
          2
          0
          [psProdMkName]
          true));
  let withProdMk :=
    psPreludeAdd withProd
      (PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          psProdMkName
          []
          prodMkType
          psProdName
          0
          2
          2
          []));
  let withProdRec :=
    psPreludeAdd withProdMk
      (PsDeclaration.recursorDecl
        (PsRecursorInfo.mk
          psSelfHostProdRecName
          [uName]
          recType
          [psProdName]
          2
          0
          1
          1));
  psPreludeAdd withProdRec
    (PsDeclaration.axiomDecl psSelfHostIntReprName [] intReprType)

def psSelfHostRuntimePreludeDeclarationsWithProd :
    List PsDeclaration :=
  match
      psEnvironmentFind
        psSelfHostProdPreludeEnvironment
        psProdName with
  | none => List.nil
  | some prodDeclaration =>
      match
          psEnvironmentFind
            psSelfHostProdPreludeEnvironment
            psProdMkName with
      | none => List.nil
      | some prodMkDeclaration =>
          match
              psEnvironmentFind
                psSelfHostProdPreludeEnvironment
                psSelfHostProdRecName with
          | none => List.nil
          | some prodRecDeclaration =>
              List.cons
                prodDeclaration
                (List.cons
                  prodMkDeclaration
                  (List.cons
                    prodRecDeclaration
                    psSelfHostRuntimePreludeDeclarations))
