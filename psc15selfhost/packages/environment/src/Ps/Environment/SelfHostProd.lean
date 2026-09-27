import Ps.Environment.SelfHostPrelude

def psSelfHostProdOf
    (alpha beta : PsExpr) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.constE psProdName [])
      alpha)
    beta

def psSelfHostProdPreludeEnvironment : PsEnvironment :=
  let alphaName := psRootName "α"
  let betaName := psRootName "β"
  let fstName := psRootName "fst"
  let sndName := psRootName "snd"
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let prodType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        betaName
        typeType
        typeType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit
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
      PsBinderInfo.implicit
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
          true))
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
        []))

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
          List.cons
            prodDeclaration
            (List.cons
              prodMkDeclaration
              psSelfHostRuntimePreludeDeclarations)
