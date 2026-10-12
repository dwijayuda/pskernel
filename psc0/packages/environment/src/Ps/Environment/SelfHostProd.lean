import Ps.Environment.StandardGetElem

def psSelfHostProdRecName : PsName :=
  psNameAppendStr psProdName "rec"

def psSelfHostProdPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u";
  let alphaName := psRootName "α";
  let betaName := psRootName "β";
  let motiveName := psRootName "_motive";
  let minorName := psRootName "_mk";
  let majorName := psRootName "_major";
  let fstName := psRootName "fst";
  let sndName := psRootName "snd";
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
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
            (psStandardProductOf
              (PsExpr.bvar 3)
              (PsExpr.bvar 2))
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let motiveType :=
    PsExpr.forallE
      majorName
      (psStandardProductOf
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
          (psStandardProductMkOf
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
              (psStandardProductOf
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
  (fun env => [psStandardOutOfBoundsDeclaration,
      psStandardGetElemBangDefaultDeclaration].foldl psPreludeAdd env)
    <| psStandardLawfulGetElemExtend <| psStandardExceptExtend <| psStandardProductExtend <|
    psStandardInhabitedExtend <|
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
          1))

def psSelfHostRuntimePreludeDeclarationsWithProd :
    List PsDeclaration :=
  let prodDeclarations :=
    match psEnvironmentFind psSelfHostProdPreludeEnvironment psProdName with
    | none => []
    | some prod =>
      match psEnvironmentFind psSelfHostProdPreludeEnvironment psProdMkName with
      | none => []
      | some constructor =>
        match psEnvironmentFind psSelfHostProdPreludeEnvironment
            psSelfHostProdRecName with
        | none => []
        | some recursor => [prod, constructor, recursor]
  psEmptyDeclarations ++ psStandardPreludeDeclarationsWithInhabited ++
    prodDeclarations ++ psSelfHostRuntimePreludeDeclarations ++
    psStandardProductDeclarations ++ psStandardExceptDeclarations ++
    -- Class evidence and method projections must enter typed runtime erasure
    -- through the same pinned, officially checked Standard declarations.
    psStandardGetElemClass ++ psStandardGetElemOptionalDeclarations ++
    psStandardLawfulGetElemClass ++
    [psStandardOutOfBoundsDeclaration, psStandardGetElemBangDefaultDeclaration]
