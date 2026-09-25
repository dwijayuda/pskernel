import Ps.Core.Builtin
import Ps.Environment.Basic

def psPreludeAdd
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : PsEnvironment :=
  match psEnvironmentAdd environment declaration with
  | some next => next
  | none => environment

def psBootstrapPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u";
  let alphaName := psRootName "α";
  let betaName := psRootName "β";
  let firstName := psRootName "first";
  let secondName := psRootName "second";
  let pairName := psRootName "pair";
  let aName := psRootName "a";
  let bName := psRootName "b";
  let pName := psRootName "p";
  let cName := psRootName "c";
  let hName := psRootName "h";
  let tName := psRootName "t";
  let eName := psRootName "e";
  let nName := psRootName "n";
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let propType := PsExpr.sortE PsLevel.zero;
  let natType := PsExpr.constE psNatName [];
  let intType := PsExpr.constE psIntName [];
  let stringType := PsExpr.constE psStringName [];
  let boolType := PsExpr.constE psBoolName [];
  let unitType := PsExpr.constE psUnitName [];
  let charType := PsExpr.constE psCharName [];
  let unaryTypeConstructorType :=
    PsExpr.forallE
      alphaName
      typeType
      typeType
      PsBinderInfo.explicit;
  let prodType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        bName
        typeType
        typeType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let prodOf :=
    fun alpha beta =>
      PsExpr.app
        (PsExpr.app (PsExpr.constE psProdName []) alpha)
        beta;
  let prodFstType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        betaName
        typeType
        (PsExpr.forallE
          pairName
          (prodOf (PsExpr.bvar 1) (PsExpr.bvar 0))
          (PsExpr.bvar 2)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let prodSndType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        betaName
        typeType
        (PsExpr.forallE
          pairName
          (prodOf (PsExpr.bvar 1) (PsExpr.bvar 0))
          (PsExpr.bvar 1)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let arrayOf :=
    fun alpha => PsExpr.app (PsExpr.constE psArrayName []) alpha;
  let arrayType :=
    PsExpr.forallE
      alphaName
      typeType
      typeType
      PsBinderInfo.explicit;
  let arrayEmptyType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        nName
        natType
        (arrayOf (PsExpr.bvar 1))
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let arraySizeType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        aName
        (arrayOf (PsExpr.bvar 0))
        natType
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let arrayPushType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        aName
        (arrayOf (PsExpr.bvar 0))
        (PsExpr.forallE
          bName
          (PsExpr.bvar 1)
          (arrayOf (PsExpr.bvar 2))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let arrayGetDType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        aName
        (arrayOf (PsExpr.bvar 0))
        (PsExpr.forallE
          nName
          natType
          (PsExpr.forallE
            bName
            (PsExpr.bvar 2)
            (PsExpr.bvar 3)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let arraySetIfInBoundsType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        aName
        (arrayOf (PsExpr.bvar 0))
        (PsExpr.forallE
          nName
          natType
          (PsExpr.forallE
            bName
            (PsExpr.bvar 2)
            (arrayOf (PsExpr.bvar 3))
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let alphaToBeta :=
    PsExpr.forallE
      aName
      (PsExpr.bvar 1)
      (PsExpr.bvar 1)
      PsBinderInfo.explicit;
  let arrayMapType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        bName
        typeType
        (PsExpr.forallE
          (psRootName "f")
          alphaToBeta
          (PsExpr.forallE
            aName
            (arrayOf (PsExpr.bvar 2))
            (arrayOf (PsExpr.bvar 2))
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let foldFunctionType :=
    PsExpr.forallE
      aName
      (PsExpr.bvar 0)
      (PsExpr.forallE
        bName
        (PsExpr.bvar 2)
        (PsExpr.bvar 2)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let arrayFoldlType :=
    PsExpr.forallE
      alphaName
      typeType
      (PsExpr.forallE
        bName
        typeType
        (PsExpr.forallE
          (psRootName "f")
          foldFunctionType
          (PsExpr.forallE
            (psRootName "init")
            (PsExpr.bvar 1)
            (PsExpr.forallE
              aName
              (arrayOf (PsExpr.bvar 3))
              (PsExpr.forallE
                (psRootName "start")
                natType
                (PsExpr.forallE
                  (psRootName "stop")
                  natType
                  (PsExpr.bvar 5)
                  PsBinderInfo.explicit)
                PsBinderInfo.explicit)
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.implicit)
      PsBinderInfo.implicit;
  let eqType :=
    PsExpr.forallE
      alphaName
      (PsExpr.sortE (PsLevel.param uName))
      (PsExpr.forallE
        aName
        (PsExpr.bvar 0)
        (PsExpr.forallE
          bName
          (PsExpr.bvar 1)
          propType
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let decidableType :=
    PsExpr.forallE
      pName
      propType
      typeType
      PsBinderInfo.explicit;
  let eqAB :=
    PsExpr.app
      (PsExpr.app
        (PsExpr.app
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          boolType)
        (PsExpr.bvar 1))
      (PsExpr.bvar 0);
  let boolDecEqType :=
    PsExpr.forallE
      aName
      boolType
      (PsExpr.forallE
        bName
        boolType
        (PsExpr.app
          (PsExpr.constE psDecidableName [])
          eqAB)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let iteType :=
    PsExpr.forallE
      alphaName
      (PsExpr.sortE (PsLevel.param uName))
      (PsExpr.forallE
        cName
        propType
        (PsExpr.forallE
          hName
          (PsExpr.app
            (PsExpr.constE psDecidableName [])
            (PsExpr.bvar 0))
          (PsExpr.forallE
            tName
            (PsExpr.bvar 2)
            (PsExpr.forallE
              eName
              (PsExpr.bvar 3)
              (PsExpr.bvar 4)
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.instanceImplicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit;
  let natUnaryType :=
    PsExpr.forallE
      nName
      natType
      natType
      PsBinderInfo.explicit;
  let natBinaryType :=
    PsExpr.forallE
      aName
      natType
      (PsExpr.forallE
        bName
        natType
        natType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let natBeqType :=
    PsExpr.forallE
      aName
      natType
      (PsExpr.forallE
        bName
        natType
        boolType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let intOfNatType :=
    PsExpr.forallE
      nName
      natType
      intType
      PsBinderInfo.explicit;
  let intUnaryType :=
    PsExpr.forallE
      aName
      intType
      intType
      PsBinderInfo.explicit;
  let intBinaryType :=
    PsExpr.forallE
      aName
      intType
      (PsExpr.forallE
        bName
        intType
        intType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let charToNatType :=
    PsExpr.forallE
      cName
      charType
      natType
      PsBinderInfo.explicit;
  let stringPushType :=
    PsExpr.forallE
      (psRootName "s")
      stringType
      (PsExpr.forallE
        cName
        charType
        stringType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let stringSingletonType :=
    PsExpr.forallE
      cName
      charType
      stringType
      PsBinderInfo.explicit;
  let stringUnaryNatType :=
    PsExpr.forallE
      (psRootName "s")
      stringType
      natType
      PsBinderInfo.explicit;
  let stringBinaryType :=
    PsExpr.forallE
      (psRootName "a")
      stringType
      (PsExpr.forallE
        (psRootName "b")
        stringType
        stringType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let stringPositionType :=
    PsExpr.forallE
      (psRootName "s")
      stringType
      (PsExpr.forallE
        nName
        natType
        natType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let stringGetType :=
    PsExpr.forallE
      (psRootName "s")
      stringType
      (PsExpr.forallE
        nName
        natType
        charType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let stringAtEndType :=
    PsExpr.forallE
      (psRootName "s")
      stringType
      (PsExpr.forallE
        nName
        natType
        boolType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let stringExtractType :=
    PsExpr.forallE
      (psRootName "s")
      stringType
      (PsExpr.forallE
        (psRootName "start")
        natType
        (PsExpr.forallE
          (psRootName "stop")
          natType
          stringType
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let charOfNatType :=
    PsExpr.forallE
      nName
      natType
      charType
      PsBinderInfo.explicit;
  let natMotiveName := psRootName "_motive";
  let natMajorName := psRootName "_major";
  let natZeroMinorName := psRootName "_zero";
  let natSuccMinorName := psRootName "_succ";
  let natHypothesisName := psRootName "_ih";
  let natMotiveType :=
    PsExpr.forallE
      natMajorName
      natType
      (PsExpr.sortE (PsLevel.param uName))
      PsBinderInfo.explicit;
  let natZeroMinorType :=
    PsExpr.app
      (PsExpr.bvar 0)
      (PsExpr.constE psNatZeroName List.nil);
  let natSuccMinorType :=
    PsExpr.forallE
      nName
      natType
      (PsExpr.forallE
        natHypothesisName
        (PsExpr.app
          (PsExpr.bvar 2)
          (PsExpr.bvar 0))
        (PsExpr.app
          (PsExpr.bvar 3)
          (PsExpr.app
            (PsExpr.constE psNatSuccName List.nil)
            (PsExpr.bvar 1)))
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let natRecType :=
    PsExpr.forallE
      natMotiveName
      natMotiveType
      (PsExpr.forallE
        natZeroMinorName
        natZeroMinorType
        (PsExpr.forallE
          natSuccMinorName
          natSuccMinorType
          (PsExpr.forallE
            natMajorName
            natType
            (PsExpr.app
              (PsExpr.bvar 3)
              (PsExpr.bvar 0))
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let env0 := psEnvironmentEmpty;
  let env1 :=
    psPreludeAdd env0
      (PsDeclaration.inductiveDecl {
        name := psNatName
        levelParams := List.nil
        type := typeType
        numParams := 0
        numIndices := 0
        constructors :=
          List.cons
            psNatZeroName
            (List.cons psNatSuccName List.nil)
        isStructure := false
      });
  let envNatZero :=
    psPreludeAdd env1
      (PsDeclaration.constructorDecl {
        name := psNatZeroName
        levelParams := List.nil
        type := natType
        inductiveName := psNatName
        constructorIndex := 0
        numParams := 0
        numFields := 0
        recursiveFields := List.nil
      });
  let envNatSucc :=
    psPreludeAdd envNatZero
      (PsDeclaration.constructorDecl {
        name := psNatSuccName
        levelParams := List.nil
        type := natUnaryType
        inductiveName := psNatName
        constructorIndex := 1
        numParams := 0
        numFields := 1
        recursiveFields := List.cons 0 List.nil
      });
  let envNatRec :=
    psPreludeAdd envNatSucc
      (PsDeclaration.recursorDecl {
        name := psNatRecName
        levelParams := List.cons uName List.nil
        type := natRecType
        inductiveNames := List.cons psNatName List.nil
        numParams := 0
        numIndices := 0
        numMotives := 1
        numMinors := 2
      });
  let envNat1 :=
    psPreludeAdd envNatRec
      (PsDeclaration.axiomDecl psNatAddName [] natBinaryType);
  let envNat2 :=
    psPreludeAdd envNat1
      (PsDeclaration.axiomDecl psNatSubName [] natBinaryType);
  let envNat3 :=
    psPreludeAdd envNat2
      (PsDeclaration.axiomDecl psNatMulName [] natBinaryType);
  let envNat4 :=
    psPreludeAdd envNat3
      (PsDeclaration.axiomDecl psNatDivName [] natBinaryType);
  let envNat5 :=
    psPreludeAdd envNat4
      (PsDeclaration.axiomDecl psNatModName [] natBinaryType);
  let envNat6 :=
    psPreludeAdd envNat5
      (PsDeclaration.axiomDecl psNatBeqName [] natBeqType);
  let envNat7 :=
    psPreludeAdd envNat6
      (PsDeclaration.axiomDecl psNatBleName [] natBeqType);
  let envNat8 :=
    psPreludeAdd envNat7
      (PsDeclaration.axiomDecl psNatBltName [] natBeqType);
  let env2 :=
    psPreludeAdd envNat8
      (PsDeclaration.axiomDecl psIntName [] typeType);
  let env3 :=
    psPreludeAdd env2
      (PsDeclaration.axiomDecl psIntOfNatName [] intOfNatType);
  let env4 :=
    psPreludeAdd env3
      (PsDeclaration.axiomDecl psIntNegSuccName [] intOfNatType);
  let env5 :=
    psPreludeAdd env4
      (PsDeclaration.axiomDecl psIntNegName [] intUnaryType);
  let env6 :=
    psPreludeAdd env5
      (PsDeclaration.axiomDecl psIntAddName [] intBinaryType);
  let env7 :=
    psPreludeAdd env6
      (PsDeclaration.axiomDecl psIntSubName [] intBinaryType);
  let env8 :=
    psPreludeAdd env7
      (PsDeclaration.axiomDecl psIntMulName [] intBinaryType);
  let env9 :=
    psPreludeAdd env8
      (PsDeclaration.axiomDecl psStringName [] typeType);
  let env10 :=
    psPreludeAdd env9
      (PsDeclaration.axiomDecl psBoolName [] typeType);
  let env11 :=
    psPreludeAdd env10
      (PsDeclaration.axiomDecl psBoolTrueName [] boolType);
  let env12 :=
    psPreludeAdd env11
      (PsDeclaration.axiomDecl psBoolFalseName [] boolType);
  let env13 :=
    psPreludeAdd env12
      (PsDeclaration.axiomDecl psUnitName [] typeType);
  let env14 :=
    psPreludeAdd env13
      (PsDeclaration.axiomDecl psUnitUnitName [] unitType);
  let env15 :=
    psPreludeAdd env14
      (PsDeclaration.axiomDecl psCharName [] typeType);
  let env16 :=
    psPreludeAdd env15
      (PsDeclaration.axiomDecl psCharOfNatName [] charOfNatType);
  let envText0 :=
    psPreludeAdd env16
      (PsDeclaration.axiomDecl psCharToNatName [] charToNatType);
  let envText1 :=
    psPreludeAdd envText0
      (PsDeclaration.axiomDecl psStringPushName [] stringPushType);
  let envText2 :=
    psPreludeAdd envText1
      (PsDeclaration.axiomDecl psStringSingletonName [] stringSingletonType);
  let envText3 :=
    psPreludeAdd envText2
      (PsDeclaration.axiomDecl psStringLengthName [] stringUnaryNatType);
  let envText4 :=
    psPreludeAdd envText3
      (PsDeclaration.axiomDecl psStringAppendName [] stringBinaryType);
  let envText5 :=
    psPreludeAdd envText4
      (PsDeclaration.axiomDecl psStringUtf8ByteSizeName [] stringUnaryNatType);
  let envText6 :=
    psPreludeAdd envText5
      (PsDeclaration.axiomDecl psStringNextName [] stringPositionType);
  let envText7 :=
    psPreludeAdd envText6
      (PsDeclaration.axiomDecl psStringGetName [] stringGetType);
  let envText8 :=
    psPreludeAdd envText7
      (PsDeclaration.axiomDecl psStringAtEndName [] stringAtEndType);
  let envText9 :=
    psPreludeAdd envText8
      (PsDeclaration.axiomDecl psStringExtractName [] stringExtractType);
  let envText10 :=
    psPreludeAdd envText9
      (PsDeclaration.axiomDecl
        psStringPosRawMkName [] natUnaryType);
  let envText11 :=
    psPreludeAdd envText10
      (PsDeclaration.axiomDecl
        psStringPosRawByteIdxName [] natUnaryType);
  let envList0 :=
    psPreludeAdd envText11
      (PsDeclaration.axiomDecl
        psListName [] unaryTypeConstructorType);
  let envOption0 :=
    psPreludeAdd envList0
      (PsDeclaration.axiomDecl
        psOptionName [] unaryTypeConstructorType);
  let envProd0 :=
    psPreludeAdd envOption0
      (PsDeclaration.axiomDecl psProdName [] prodType);
  let envProd1 :=
    psPreludeAdd envProd0
      (PsDeclaration.axiomDecl psProdFstName [] prodFstType);
  let envProd2 :=
    psPreludeAdd envProd1
      (PsDeclaration.axiomDecl psProdSndName [] prodSndType);
  let envArray0 :=
    psPreludeAdd envProd2
      (PsDeclaration.axiomDecl psArrayName [] arrayType);
  let envArray1 :=
    psPreludeAdd envArray0
      (PsDeclaration.axiomDecl
        psArrayEmptyWithCapacityName [] arrayEmptyType);
  let envArray2 :=
    psPreludeAdd envArray1
      (PsDeclaration.axiomDecl psArraySizeName [] arraySizeType);
  let envArray3 :=
    psPreludeAdd envArray2
      (PsDeclaration.axiomDecl psArrayPushName [] arrayPushType);
  let envArray4 :=
    psPreludeAdd envArray3
      (PsDeclaration.axiomDecl psArrayGetDName [] arrayGetDType);
  let envArray5 :=
    psPreludeAdd envArray4
      (PsDeclaration.axiomDecl
        psArraySetIfInBoundsName [] arraySetIfInBoundsType);
  let envArray6 :=
    psPreludeAdd envArray5
      (PsDeclaration.axiomDecl psArrayMapName [] arrayMapType);
  let envArray7 :=
    psPreludeAdd envArray6
      (PsDeclaration.axiomDecl psArrayFoldlName [] arrayFoldlType);
  let env17 :=
    psPreludeAdd envArray7
      (PsDeclaration.axiomDecl psEqName [uName] eqType);
  let env18 :=
    psPreludeAdd env17
      (PsDeclaration.axiomDecl psDecidableName [] decidableType);
  let env19 :=
    psPreludeAdd env18
      (PsDeclaration.axiomDecl psBoolDecEqName [] boolDecEqType);
  psPreludeAdd env19
    (PsDeclaration.axiomDecl psIteName [uName] iteType)
