import Ps.Environment.StandardToString

-- Checked universe-polymorphic RC4 Option programming APIs.
-- Input and result universes are independent; there is no Type-0 fallback.
def psStandardOptionRecursor (result element : PsLevel) : PsExpr :=
  .constE psSelfHostOptionRecName [result, element]

def psStandardOptionGetDDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let option := psSelfHostOptionOf alpha (.param u)
  let motive := psLogicLam 3 "_" option alpha
  let someBranch := psLogicLam 4 "value" alpha (.fvar 4)
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "opt" option
      (psLogicPi 2 "default" alpha alpha)) .implicit
  let body := psLogicApply (psStandardOptionRecursor (.succ (.param u)) (.param u))
    [alpha, motive, .fvar 2, someBranch, .fvar 1]
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "opt" option
      (psLogicLam 2 "default" alpha body)) .implicit
  .definitionDecl (psNameAppendStr psOptionName "getD") [u] type value

def psStandardOptionMapDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let optionAlpha := psSelfHostOptionOf alpha (.param u)
  let optionBeta := psSelfHostOptionOf beta (.param v)
  let arrow := psLogicPi 4 "value" alpha beta
  let motive := psLogicLam 5 "_" optionAlpha optionBeta
  let someBranch := psLogicLam 6 "value" alpha
    (psSelfHostOptionSomeOf beta (.app (.fvar 2) (.fvar 6)) (.param v))
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "β" (.sortE (.succ (.param v)))
      (psLogicPi 2 "f" arrow
        (psLogicPi 3 "opt" optionAlpha optionBeta)) .implicit) .implicit
  let body := psLogicApply (psStandardOptionRecursor (.succ (.param v)) (.param u))
    [alpha, motive, psSelfHostOptionNoneOf beta (.param v), someBranch, .fvar 3]
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "β" (.sortE (.succ (.param v)))
      (psLogicLam 2 "f" arrow
        (psLogicLam 3 "opt" optionAlpha body)) .implicit) .implicit
  .definitionDecl (psNameAppendStr psOptionName "map") [u, v] type value

def psStandardOptionBindDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let optionAlpha := psSelfHostOptionOf alpha (.param u)
  let optionBeta := psSelfHostOptionOf beta (.param v)
  let arrow := psLogicPi 4 "value" alpha optionBeta
  let motive := psLogicLam 5 "_" optionAlpha optionBeta
  let someBranch := psLogicLam 6 "value" alpha (.app (.fvar 3) (.fvar 6))
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "β" (.sortE (.succ (.param v)))
      (psLogicPi 2 "opt" optionAlpha
        (psLogicPi 3 "f" arrow optionBeta)) .implicit) .implicit
  let body := psLogicApply (psStandardOptionRecursor (.succ (.param v)) (.param u))
    [alpha, motive, psSelfHostOptionNoneOf beta (.param v), someBranch, .fvar 2]
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "β" (.sortE (.succ (.param v)))
      (psLogicLam 2 "opt" optionAlpha
        (psLogicLam 3 "f" arrow body)) .implicit) .implicit
  .definitionDecl (psNameAppendStr psOptionName "bind") [u, v] type value

def psStandardOptionIsSomeDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let optionAlpha := psSelfHostOptionOf alpha (.param u)
  let bool := PsExpr.constE psBoolName []
  let motive := psLogicLam 3 "_" optionAlpha bool
  let someBranch := psLogicLam 4 "value" alpha (.constE psBoolTrueName [])
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "opt" optionAlpha bool) .implicit
  let body := psLogicApply (psStandardOptionRecursor (.succ .zero) (.param u))
    [alpha, motive, .constE psBoolFalseName [], someBranch, .fvar 1]
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "opt" optionAlpha body) .implicit
  .definitionDecl (psNameAppendStr psOptionName "isSome") [u] type value

def psStandardOptionIsNoneDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let optionAlpha := psSelfHostOptionOf alpha (.param u)
  let bool := PsExpr.constE psBoolName []
  let motive := psLogicLam 3 "_" optionAlpha bool
  let someBranch := psLogicLam 4 "value" alpha (.constE psBoolFalseName [])
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "opt" optionAlpha bool) .implicit
  let body := psLogicApply (psStandardOptionRecursor (.succ .zero) (.param u))
    [alpha, motive, .constE psBoolTrueName [], someBranch, .fvar 1]
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "opt" optionAlpha body) .implicit
  .definitionDecl (psNameAppendStr psOptionName "isNone") [u] type value

def psStandardOptionFilterDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let optionAlpha := psSelfHostOptionOf alpha (.param u)
  let bool := PsExpr.constE psBoolName []
  let predicate := psLogicPi 5 "value" alpha bool
  let motive := psLogicLam 3 "_" optionAlpha optionAlpha
  let boolMotive := psLogicLam 6 "_" bool optionAlpha
  let someBranch := psLogicLam 4 "value" alpha
    (psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ (.param u)])
      [boolMotive, psSelfHostOptionNoneOf alpha (.param u),
       psSelfHostOptionSomeOf alpha (.fvar 4) (.param u),
       .app (.fvar 1) (.fvar 4)])
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "predicate" predicate
      (psLogicPi 2 "opt" optionAlpha optionAlpha)) .implicit
  let body := psLogicApply (psStandardOptionRecursor (.succ (.param u)) (.param u))
    [alpha, motive, psSelfHostOptionNoneOf alpha (.param u), someBranch, .fvar 2]
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "predicate" predicate
      (psLogicLam 2 "opt" optionAlpha body)) .implicit
  .definitionDecl (psNameAppendStr psOptionName "filter") [u] type value

def psStandardOptionDeclarations : List PsDeclaration :=
  [psStandardOptionGetDDeclaration,
   psStandardOptionMapDeclaration,
   psStandardOptionBindDeclaration,
   psStandardOptionIsSomeDeclaration,
   psStandardOptionIsNoneDeclaration,
   psStandardOptionFilterDeclaration]

def psStandardPreludeDeclarationsWithOption : List PsDeclaration :=
  psStandardPreludeDeclarationsWithToString ++ psStandardOptionDeclarations

def psStandardOptionExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardPreludeExtendWithToString environment
  psStandardOptionDeclarations.foldl (fun env decl =>
    (psEnvironmentAdd env decl).getD env) environment
