import Ps.Core.Builtin
import Ps.Environment.Basic

def psPreludeAdd
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : PsEnvironment :=
  match psEnvironmentAdd environment declaration with
  | some next => next
  | none => environment

def psBootstrapPreludeEnvironment : PsEnvironment :=
  let uName := psRootName "u"
  let alphaName := psRootName "α"
  let aName := psRootName "a"
  let bName := psRootName "b"
  let pName := psRootName "p"
  let cName := psRootName "c"
  let hName := psRootName "h"
  let tName := psRootName "t"
  let eName := psRootName "e"
  let nName := psRootName "n"
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let propType := PsExpr.sortE PsLevel.zero
  let natType := PsExpr.constE psNatName []
  let stringType := PsExpr.constE psStringName []
  let boolType := PsExpr.constE psBoolName []
  let unitType := PsExpr.constE psUnitName []
  let charType := PsExpr.constE psCharName []
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
      PsBinderInfo.implicit
  let decidableType :=
    PsExpr.forallE
      pName
      propType
      typeType
      PsBinderInfo.explicit
  let eqAB :=
    PsExpr.app
      (PsExpr.app
        (PsExpr.app
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          boolType)
        (PsExpr.bvar 1))
      (PsExpr.bvar 0)
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
      PsBinderInfo.explicit
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
      PsBinderInfo.implicit
  let charOfNatType :=
    PsExpr.forallE
      nName
      natType
      charType
      PsBinderInfo.explicit
  let env0 := psEnvironmentEmpty
  let env1 :=
    psPreludeAdd env0
      (PsDeclaration.axiomDecl psNatName [] typeType)
  let env2 :=
    psPreludeAdd env1
      (PsDeclaration.axiomDecl psStringName [] typeType)
  let env3 :=
    psPreludeAdd env2
      (PsDeclaration.axiomDecl psBoolName [] typeType)
  let env4 :=
    psPreludeAdd env3
      (PsDeclaration.axiomDecl psBoolTrueName [] boolType)
  let env5 :=
    psPreludeAdd env4
      (PsDeclaration.axiomDecl psBoolFalseName [] boolType)
  let env6 :=
    psPreludeAdd env5
      (PsDeclaration.axiomDecl psUnitName [] typeType)
  let env7 :=
    psPreludeAdd env6
      (PsDeclaration.axiomDecl psUnitUnitName [] unitType)
  let env8 :=
    psPreludeAdd env7
      (PsDeclaration.axiomDecl psCharName [] typeType)
  let env9 :=
    psPreludeAdd env8
      (PsDeclaration.axiomDecl psCharOfNatName [] charOfNatType)
  let env10 :=
    psPreludeAdd env9
      (PsDeclaration.axiomDecl psEqName [uName] eqType)
  let env11 :=
    psPreludeAdd env10
      (PsDeclaration.axiomDecl psDecidableName [] decidableType)
  let env12 :=
    psPreludeAdd env11
      (PsDeclaration.axiomDecl psBoolDecEqName [] boolDecEqType)
  psPreludeAdd env12
    (PsDeclaration.axiomDecl psIteName [uName] iteType)
