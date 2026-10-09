import Ps.Core.Builtin
import Ps.Environment.Basic

def psPreludeAdd
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : PsEnvironment :=
  match psEnvironmentAdd environment declaration with
  | some next => next
  | none => environment

-- Small closed definitions avoid repeatedly elaborating a single large local
-- context. The resulting prelude declarations and their order are unchanged.
def psPreludeUName : PsName :=
  psRootName "u"

def psPreludeAlphaName : PsName :=
  psRootName "α"

def psPreludeBetaName : PsName :=
  psRootName "β"

def psPreludeFirstName : PsName :=
  psRootName "first"

def psPreludeSecondName : PsName :=
  psRootName "second"

def psPreludePairName : PsName :=
  psRootName "pair"

def psPreludeAName : PsName :=
  psRootName "a"

def psPreludeBName : PsName :=
  psRootName "b"

def psPreludePName : PsName :=
  psRootName "p"

def psPreludeCName : PsName :=
  psRootName "c"

def psPreludeHName : PsName :=
  psRootName "h"

def psPreludeTName : PsName :=
  psRootName "t"

def psPreludeEName : PsName :=
  psRootName "e"

def psPreludeNName : PsName :=
  psRootName "n"

def psPreludeTypeType : PsExpr :=
  PsExpr.sortE (PsLevel.succ PsLevel.zero)

def psPreludePropType : PsExpr :=
  PsExpr.sortE PsLevel.zero

def psPreludeNatType : PsExpr :=
  PsExpr.constE psNatName []

def psPreludeIntType : PsExpr :=
  PsExpr.constE psIntName []

def psPreludeUInt8Type : PsExpr :=
  PsExpr.constE psUInt8Name []

def psPreludeStringType : PsExpr :=
  PsExpr.constE psStringName []

def psPreludeBoolType : PsExpr :=
  PsExpr.constE psBoolName []

def psPreludeUnitType : PsExpr :=
  PsExpr.constE psUnitName []

def psPreludeCharType : PsExpr :=
  PsExpr.constE psCharName []

def psPreludeUnaryTypeConstructorType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    psPreludeTypeType
    PsBinderInfo.explicit

def psPreludeProdType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeBName
      psPreludeTypeType
      psPreludeTypeType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeProdOf : PsExpr -> PsExpr -> PsExpr :=
  fun (alpha : PsExpr) (beta : PsExpr) =>
    PsExpr.app
      (PsExpr.app (PsExpr.constE psProdName []) alpha)
      beta

def psPreludeProdFstType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeBetaName
      psPreludeTypeType
      (PsExpr.forallE
        psPreludePairName
        (psPreludeProdOf (PsExpr.bvar 1) (PsExpr.bvar 0))
        (PsExpr.bvar 2)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit)
    PsBinderInfo.implicit

def psPreludeProdSndType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeBetaName
      psPreludeTypeType
      (PsExpr.forallE
        psPreludePairName
        (psPreludeProdOf (PsExpr.bvar 1) (PsExpr.bvar 0))
        (PsExpr.bvar 1)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit)
    PsBinderInfo.implicit

def psPreludeArrayOf : PsExpr -> PsExpr :=
  fun (alpha : PsExpr) => PsExpr.app (PsExpr.constE psArrayName []) alpha

def psPreludeArrayType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    psPreludeTypeType
    PsBinderInfo.explicit

def psPreludeArrayEmptyType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeNName
      psPreludeNatType
      (psPreludeArrayOf (PsExpr.bvar 1))
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeArraySizeType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeAName
      (psPreludeArrayOf (PsExpr.bvar 0))
      psPreludeNatType
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeArrayPushType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeAName
      (psPreludeArrayOf (PsExpr.bvar 0))
      (PsExpr.forallE
        psPreludeBName
        (PsExpr.bvar 1)
        (psPreludeArrayOf (PsExpr.bvar 2))
        PsBinderInfo.explicit)
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeArrayGetDType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeAName
      (psPreludeArrayOf (PsExpr.bvar 0))
      (PsExpr.forallE
        psPreludeNName
        psPreludeNatType
        (PsExpr.forallE
          psPreludeBName
          (PsExpr.bvar 2)
          (PsExpr.bvar 3)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeArraySetIfInBoundsType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeAName
      (psPreludeArrayOf (PsExpr.bvar 0))
      (PsExpr.forallE
        psPreludeNName
        psPreludeNatType
        (PsExpr.forallE
          psPreludeBName
          (PsExpr.bvar 2)
          (psPreludeArrayOf (PsExpr.bvar 3))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeAlphaToBeta : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    (PsExpr.bvar 1)
    (PsExpr.bvar 1)
    PsBinderInfo.explicit

def psPreludeArrayMapType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeBName
      psPreludeTypeType
      (PsExpr.forallE
        (psRootName "f")
        psPreludeAlphaToBeta
        (PsExpr.forallE
          psPreludeAName
          (psPreludeArrayOf (PsExpr.bvar 2))
          (psPreludeArrayOf (PsExpr.bvar 2))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit)
    PsBinderInfo.implicit

def psPreludeFoldFunctionType : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    (PsExpr.bvar 0)
    (PsExpr.forallE
      psPreludeBName
      (PsExpr.bvar 2)
      (PsExpr.bvar 2)
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeArrayFoldlType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    psPreludeTypeType
    (PsExpr.forallE
      psPreludeBName
      psPreludeTypeType
      (PsExpr.forallE
        (psRootName "f")
        psPreludeFoldFunctionType
        (PsExpr.forallE
          (psRootName "init")
          (PsExpr.bvar 1)
          (PsExpr.forallE
            psPreludeAName
            (psPreludeArrayOf (PsExpr.bvar 3))
            (PsExpr.forallE
              (psRootName "start")
              psPreludeNatType
              (PsExpr.forallE
                (psRootName "stop")
                psPreludeNatType
                (PsExpr.bvar 5)
                PsBinderInfo.explicit)
              PsBinderInfo.explicit)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.implicit)
    PsBinderInfo.implicit

def psPreludeEqType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    (PsExpr.sortE (PsLevel.param psPreludeUName))
    (PsExpr.forallE
      psPreludeAName
      (PsExpr.bvar 0)
      (PsExpr.forallE
        psPreludeBName
        (PsExpr.bvar 1)
        psPreludePropType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeDecidableType : PsExpr :=
  PsExpr.forallE
    psPreludePName
    psPreludePropType
    psPreludeTypeType
    PsBinderInfo.explicit

def psPreludeEqAB : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.constE
          psEqName
          [PsLevel.succ PsLevel.zero])
        psPreludeBoolType)
      (PsExpr.bvar 1))
    (PsExpr.bvar 0)

def psPreludeBoolDecEqType : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    psPreludeBoolType
    (PsExpr.forallE
      psPreludeBName
      psPreludeBoolType
      (PsExpr.app
        (PsExpr.constE psDecidableName [])
        psPreludeEqAB)
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeIteType : PsExpr :=
  PsExpr.forallE
    psPreludeAlphaName
    (PsExpr.sortE (PsLevel.param psPreludeUName))
    (PsExpr.forallE
      psPreludeCName
      psPreludePropType
      (PsExpr.forallE
        psPreludeHName
        (PsExpr.app
          (PsExpr.constE psDecidableName [])
          (PsExpr.bvar 0))
        (PsExpr.forallE
          psPreludeTName
          (PsExpr.bvar 2)
          (PsExpr.forallE
            psPreludeEName
            (PsExpr.bvar 3)
            (PsExpr.bvar 4)
            PsBinderInfo.explicit)
          PsBinderInfo.explicit)
        PsBinderInfo.instanceImplicit)
      PsBinderInfo.explicit)
    PsBinderInfo.implicit

def psPreludeNatUnaryType : PsExpr :=
  PsExpr.forallE
    psPreludeNName
    psPreludeNatType
    psPreludeNatType
    PsBinderInfo.explicit

def psPreludeNatBinaryType : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    psPreludeNatType
    (PsExpr.forallE
      psPreludeBName
      psPreludeNatType
      psPreludeNatType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeNatBeqType : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    psPreludeNatType
    (PsExpr.forallE
      psPreludeBName
      psPreludeNatType
      psPreludeBoolType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeIntOfNatType : PsExpr :=
  PsExpr.forallE
    psPreludeNName
    psPreludeNatType
    psPreludeIntType
    PsBinderInfo.explicit

def psPreludeUInt8OfNatType : PsExpr :=
  PsExpr.forallE
    psPreludeNName
    psPreludeNatType
    psPreludeUInt8Type
    PsBinderInfo.explicit

def psPreludeIntUnaryType : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    psPreludeIntType
    psPreludeIntType
    PsBinderInfo.explicit

def psPreludeIntBinaryType : PsExpr :=
  PsExpr.forallE
    psPreludeAName
    psPreludeIntType
    (PsExpr.forallE
      psPreludeBName
      psPreludeIntType
      psPreludeIntType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeCharToNatType : PsExpr :=
  PsExpr.forallE
    psPreludeCName
    psPreludeCharType
    psPreludeNatType
    PsBinderInfo.explicit

def psPreludeStringPushType : PsExpr :=
  PsExpr.forallE
    (psRootName "s")
    psPreludeStringType
    (PsExpr.forallE
      psPreludeCName
      psPreludeCharType
      psPreludeStringType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeStringSingletonType : PsExpr :=
  PsExpr.forallE
    psPreludeCName
    psPreludeCharType
    psPreludeStringType
    PsBinderInfo.explicit

def psPreludeStringUnaryNatType : PsExpr :=
  PsExpr.forallE
    (psRootName "s")
    psPreludeStringType
    psPreludeNatType
    PsBinderInfo.explicit

def psPreludeStringBinaryType : PsExpr :=
  PsExpr.forallE
    (psRootName "a")
    psPreludeStringType
    (PsExpr.forallE
      (psRootName "b")
      psPreludeStringType
      psPreludeStringType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeStringPositionType : PsExpr :=
  PsExpr.forallE
    (psRootName "s")
    psPreludeStringType
    (PsExpr.forallE
      psPreludeNName
      psPreludeNatType
      psPreludeNatType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeStringGetType : PsExpr :=
  PsExpr.forallE
    (psRootName "s")
    psPreludeStringType
    (PsExpr.forallE
      psPreludeNName
      psPreludeNatType
      psPreludeCharType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeStringAtEndType : PsExpr :=
  PsExpr.forallE
    (psRootName "s")
    psPreludeStringType
    (PsExpr.forallE
      psPreludeNName
      psPreludeNatType
      psPreludeBoolType
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeStringExtractType : PsExpr :=
  PsExpr.forallE
    (psRootName "s")
    psPreludeStringType
    (PsExpr.forallE
      (psRootName "start")
      psPreludeNatType
      (PsExpr.forallE
        (psRootName "stop")
        psPreludeNatType
        psPreludeStringType
        PsBinderInfo.explicit)
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeCharOfNatType : PsExpr :=
  PsExpr.forallE
    psPreludeNName
    psPreludeNatType
    psPreludeCharType
    PsBinderInfo.explicit

def psPreludeNatMotiveName : PsName :=
  psRootName "_motive"

def psPreludeNatMajorName : PsName :=
  psRootName "_major"

def psPreludeNatZeroMinorName : PsName :=
  psRootName "_zero"

def psPreludeNatSuccMinorName : PsName :=
  psRootName "_succ"

def psPreludeNatHypothesisName : PsName :=
  psRootName "_ih"

def psPreludeNatMotiveType : PsExpr :=
  PsExpr.forallE
    psPreludeNatMajorName
    psPreludeNatType
    (PsExpr.sortE (PsLevel.param psPreludeUName))
    PsBinderInfo.explicit

def psPreludeNatZeroMinorType : PsExpr :=
  PsExpr.app
    (PsExpr.bvar 0)
    (PsExpr.constE psNatZeroName List.nil)

def psPreludeNatSuccMinorType : PsExpr :=
  PsExpr.forallE
    psPreludeNName
    psPreludeNatType
    (PsExpr.forallE
      psPreludeNatHypothesisName
      (PsExpr.app
        (PsExpr.bvar 2)
        (PsExpr.bvar 0))
      (PsExpr.app
        (PsExpr.bvar 3)
        (PsExpr.app
          (PsExpr.constE psNatSuccName List.nil)
          (PsExpr.bvar 1)))
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeNatRecType : PsExpr :=
  PsExpr.forallE
    psPreludeNatMotiveName
    psPreludeNatMotiveType
    (PsExpr.forallE
      psPreludeNatZeroMinorName
      psPreludeNatZeroMinorType
      (PsExpr.forallE
        psPreludeNatSuccMinorName
        psPreludeNatSuccMinorType
        (PsExpr.forallE
          psPreludeNatMajorName
          psPreludeNatType
          (PsExpr.app
            (PsExpr.bvar 3)
            (PsExpr.bvar 0))
          PsBinderInfo.explicit)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit)
    PsBinderInfo.explicit

def psPreludeEnv0 : PsEnvironment :=
  psEnvironmentEmpty

def psPreludeEnv1 : PsEnvironment :=
  psPreludeAdd psPreludeEnv0
    (PsDeclaration.inductiveDecl
      (PsInductiveInfo.mk
        psNatName
        List.nil
        psPreludeTypeType
        0
        0
        (List.cons
          psNatZeroName
          (List.cons psNatSuccName List.nil))
        false))

def psPreludeEnvNatZero : PsEnvironment :=
  psPreludeAdd psPreludeEnv1
    (PsDeclaration.constructorDecl
      (PsConstructorInfo.mk
        psNatZeroName
        List.nil
        psPreludeNatType
        psNatName
        0
        0
        0
        List.nil))

def psPreludeEnvNatSucc : PsEnvironment :=
  psPreludeAdd psPreludeEnvNatZero
    (PsDeclaration.constructorDecl
      (PsConstructorInfo.mk
        psNatSuccName
        List.nil
        psPreludeNatUnaryType
        psNatName
        1
        0
        1
        (List.cons 0 List.nil)))

def psPreludeEnvNatRec : PsEnvironment :=
  psPreludeAdd psPreludeEnvNatSucc
    (PsDeclaration.recursorDecl
      (PsRecursorInfo.mk
        psNatRecName
        (List.cons psPreludeUName List.nil)
        psPreludeNatRecType
        (List.cons psNatName List.nil)
        0
        0
        1
        2))

def psPreludeEnvNat1 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNatRec
    (PsDeclaration.axiomDecl psNatAddName [] psPreludeNatBinaryType)

def psPreludeEnvNat2 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat1
    (PsDeclaration.axiomDecl psNatSubName [] psPreludeNatBinaryType)

def psPreludeEnvNat3 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat2
    (PsDeclaration.axiomDecl psNatMulName [] psPreludeNatBinaryType)

def psPreludeEnvNat4 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat3
    (PsDeclaration.axiomDecl psNatDivName [] psPreludeNatBinaryType)

def psPreludeEnvNat5 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat4
    (PsDeclaration.axiomDecl psNatModName [] psPreludeNatBinaryType)

def psPreludeEnvNat6 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat5
    (PsDeclaration.axiomDecl psNatBeqName [] psPreludeNatBeqType)

def psPreludeEnvNat7 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat6
    (PsDeclaration.axiomDecl psNatBleName [] psPreludeNatBeqType)

def psPreludeEnvNat8 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat7
    (PsDeclaration.axiomDecl psNatBltName [] psPreludeNatBeqType)

def psPreludeEnv2 : PsEnvironment :=
  psPreludeAdd psPreludeEnvNat8
    (PsDeclaration.axiomDecl psIntName [] psPreludeTypeType)

def psPreludeEnv3 : PsEnvironment :=
  psPreludeAdd psPreludeEnv2
    (PsDeclaration.axiomDecl psIntOfNatName [] psPreludeIntOfNatType)

def psPreludeEnv4 : PsEnvironment :=
  psPreludeAdd psPreludeEnv3
    (PsDeclaration.axiomDecl psIntNegSuccName [] psPreludeIntOfNatType)

def psPreludeEnv5 : PsEnvironment :=
  psPreludeAdd psPreludeEnv4
    (PsDeclaration.axiomDecl psIntNegName [] psPreludeIntUnaryType)

def psPreludeEnv6 : PsEnvironment :=
  psPreludeAdd psPreludeEnv5
    (PsDeclaration.axiomDecl psIntAddName [] psPreludeIntBinaryType)

def psPreludeEnv7 : PsEnvironment :=
  psPreludeAdd psPreludeEnv6
    (PsDeclaration.axiomDecl psIntSubName [] psPreludeIntBinaryType)

def psPreludeEnv8 : PsEnvironment :=
  psPreludeAdd psPreludeEnv7
    (PsDeclaration.axiomDecl psIntMulName [] psPreludeIntBinaryType)

def psPreludeEnvScalarUInt8 : PsEnvironment :=
  psPreludeAdd
    (psPreludeAdd
      (psPreludeAdd psPreludeEnv8
        (PsDeclaration.axiomDecl psIntReprName []
          (PsExpr.forallE psPreludeNName psPreludeIntType psPreludeStringType PsBinderInfo.explicit)))
      (PsDeclaration.axiomDecl psUInt8Name [] psPreludeTypeType))
    (PsDeclaration.axiomDecl
      psUInt8OfNatName
      []
      psPreludeUInt8OfNatType)

def psPreludeEnvScalarUInt16 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarUInt8
    (PsDeclaration.axiomDecl psUInt16Name [] psPreludeTypeType)

def psPreludeEnvScalarUInt32 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarUInt16
    (PsDeclaration.axiomDecl psUInt32Name [] psPreludeTypeType)

def psPreludeEnvScalarUInt64 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarUInt32
    (PsDeclaration.axiomDecl psUInt64Name [] psPreludeTypeType)

def psPreludeEnvScalarUSize : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarUInt64
    (PsDeclaration.axiomDecl psUSizeName [] psPreludeTypeType)

def psPreludeEnvScalarInt8 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarUSize
    (PsDeclaration.axiomDecl psInt8Name [] psPreludeTypeType)

def psPreludeEnvScalarInt16 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarInt8
    (PsDeclaration.axiomDecl psInt16Name [] psPreludeTypeType)

def psPreludeEnvScalarInt32 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarInt16
    (PsDeclaration.axiomDecl psInt32Name [] psPreludeTypeType)

def psPreludeEnvScalarInt64 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarInt32
    (PsDeclaration.axiomDecl psInt64Name [] psPreludeTypeType)

def psPreludeEnvScalarISize : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarInt64
    (PsDeclaration.axiomDecl psISizeName [] psPreludeTypeType)

def psPreludeEnvScalarFloat : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarISize
    (PsDeclaration.axiomDecl psFloatName [] psPreludeTypeType)

def psPreludeEnvScalarFloat32 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarFloat
    (PsDeclaration.axiomDecl psFloat32Name [] psPreludeTypeType)

def psPreludeEnv9 : PsEnvironment :=
  psPreludeAdd psPreludeEnvScalarFloat32
    (PsDeclaration.axiomDecl psStringName [] psPreludeTypeType)

def psPreludeEnv10 : PsEnvironment :=
  psPreludeAdd psPreludeEnv9
    (PsDeclaration.axiomDecl psBoolName [] psPreludeTypeType)

def psPreludeEnv11 : PsEnvironment :=
  psPreludeAdd psPreludeEnv10
    (PsDeclaration.axiomDecl psBoolTrueName [] psPreludeBoolType)

def psPreludeEnv12 : PsEnvironment :=
  psPreludeAdd psPreludeEnv11
    (PsDeclaration.axiomDecl psBoolFalseName [] psPreludeBoolType)

def psPreludeEnv13 : PsEnvironment :=
  psPreludeAdd psPreludeEnv12
    (PsDeclaration.axiomDecl psUnitName [] psPreludeTypeType)

def psPreludeEnv14 : PsEnvironment :=
  psPreludeAdd psPreludeEnv13
    (PsDeclaration.axiomDecl psUnitUnitName [] psPreludeUnitType)

def psPreludeEnv15 : PsEnvironment :=
  psPreludeAdd psPreludeEnv14
    (PsDeclaration.axiomDecl psCharName [] psPreludeTypeType)

def psPreludeEnv16 : PsEnvironment :=
  psPreludeAdd psPreludeEnv15
    (PsDeclaration.axiomDecl psCharOfNatName [] psPreludeCharOfNatType)

def psPreludeEnvText0 : PsEnvironment :=
  psPreludeAdd psPreludeEnv16
    (PsDeclaration.axiomDecl psCharToNatName [] psPreludeCharToNatType)

def psPreludeEnvText1 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText0
    (PsDeclaration.axiomDecl psStringPushName [] psPreludeStringPushType)

def psPreludeEnvText2 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText1
    (PsDeclaration.axiomDecl psStringSingletonName [] psPreludeStringSingletonType)

def psPreludeEnvText3 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText2
    (PsDeclaration.axiomDecl psStringLengthName [] psPreludeStringUnaryNatType)

def psPreludeEnvText4 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText3
    (PsDeclaration.axiomDecl psStringAppendName [] psPreludeStringBinaryType)

def psPreludeEnvText5 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText4
    (PsDeclaration.axiomDecl psStringUtf8ByteSizeName [] psPreludeStringUnaryNatType)

def psPreludeEnvText6 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText5
    (PsDeclaration.axiomDecl psStringNextName [] psPreludeStringPositionType)

def psPreludeEnvText7 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText6
    (PsDeclaration.axiomDecl psStringGetName [] psPreludeStringGetType)

def psPreludeEnvText8 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText7
    (PsDeclaration.axiomDecl psStringAtEndName [] psPreludeStringAtEndType)

def psPreludeEnvText9 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText8
    (PsDeclaration.axiomDecl psStringExtractName [] psPreludeStringExtractType)

def psPreludeEnvText10 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText9
    (PsDeclaration.axiomDecl
      psStringPosRawMkName [] psPreludeNatUnaryType)

def psPreludeEnvText11 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText10
    (PsDeclaration.axiomDecl
      psStringPosRawByteIdxName [] psPreludeNatUnaryType)

-- Portable source aliases preserve the existing primitive ABI without adding axioms.
def psPreludeEnvText12 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText11
    (PsDeclaration.definitionDecl psStringSpecifiedAppendName [] psPreludeStringBinaryType
      (PsExpr.const psStringAppendName []))

def psPreludeEnvText13 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText12
    (PsDeclaration.definitionDecl psStringPosRawNextName [] psPreludeStringPositionType
      (PsExpr.const psStringNextName []))

def psPreludeEnvText14 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText13
    (PsDeclaration.definitionDecl psStringPosRawAtEndName [] psPreludeStringAtEndType
      (PsExpr.const psStringAtEndName []))

def psPreludeEnvList0 : PsEnvironment :=
  psPreludeAdd psPreludeEnvText14
    (PsDeclaration.axiomDecl
      psListName [] psPreludeUnaryTypeConstructorType)

def psPreludeEnvOption0 : PsEnvironment :=
  psPreludeAdd psPreludeEnvList0
    (PsDeclaration.axiomDecl
      psOptionName [] psPreludeUnaryTypeConstructorType)

def psPreludeEnvProd0 : PsEnvironment :=
  psPreludeAdd psPreludeEnvOption0
    (PsDeclaration.axiomDecl psProdName [] psPreludeProdType)

def psPreludeEnvProd1 : PsEnvironment :=
  psPreludeAdd psPreludeEnvProd0
    (PsDeclaration.axiomDecl psProdFstName [] psPreludeProdFstType)

def psPreludeEnvProd2 : PsEnvironment :=
  psPreludeAdd psPreludeEnvProd1
    (PsDeclaration.axiomDecl psProdSndName [] psPreludeProdSndType)

def psPreludeEnvArray0 : PsEnvironment :=
  psPreludeAdd psPreludeEnvProd2
    (PsDeclaration.axiomDecl psArrayName [] psPreludeArrayType)

def psPreludeEnvArray1 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray0
    (PsDeclaration.axiomDecl
      psArrayEmptyWithCapacityName [] psPreludeArrayEmptyType)

def psPreludeEnvArray2 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray1
    (PsDeclaration.axiomDecl psArraySizeName [] psPreludeArraySizeType)

def psPreludeEnvArray3 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray2
    (PsDeclaration.axiomDecl psArrayPushName [] psPreludeArrayPushType)

def psPreludeEnvArray4 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray3
    (PsDeclaration.axiomDecl psArrayGetDName [] psPreludeArrayGetDType)

def psPreludeEnvArray5 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray4
    (PsDeclaration.axiomDecl
      psArraySetIfInBoundsName [] psPreludeArraySetIfInBoundsType)

def psPreludeEnvArray6 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray5
    (PsDeclaration.axiomDecl psArrayMapName [] psPreludeArrayMapType)

def psPreludeEnvArray7 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray6
    (PsDeclaration.axiomDecl psArrayFoldlName [] psPreludeArrayFoldlType)

def psPreludeEnv17 : PsEnvironment :=
  psPreludeAdd psPreludeEnvArray7
    (PsDeclaration.axiomDecl psEqName [psPreludeUName] psPreludeEqType)

def psPreludeEnv18 : PsEnvironment :=
  psPreludeAdd psPreludeEnv17
    (PsDeclaration.axiomDecl psDecidableName [] psPreludeDecidableType)

def psPreludeEnv19 : PsEnvironment :=
  psPreludeAdd psPreludeEnv18
    (PsDeclaration.axiomDecl psBoolDecEqName [] psPreludeBoolDecEqType)

def psBootstrapPreludeEnvironment : PsEnvironment :=
  psPreludeAdd psPreludeEnv19
      (PsDeclaration.axiomDecl psIteName [psPreludeUName] psPreludeIteType)
