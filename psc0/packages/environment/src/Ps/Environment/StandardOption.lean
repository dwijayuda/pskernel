import Ps.Environment.StandardToString

-- Selected RC4 Option programming APIs for the current Type-0 closure.
-- Each body is an ordinary kernel-checkable recursor expression, with no
-- environment-specific evaluator fallback and no new trusted primitive.
def psStandardOptionRecursor : PsExpr :=
  .constE psSelfHostOptionRecName [.succ .zero]

def psStandardOptionGetDDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let option := psSelfHostOptionOf alpha
  let motive := psLogicLam 3 "_" option alpha
  let someBranch := psLogicLam 4 "value" alpha (.fvar 4)
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "opt" option
      (psLogicPi 2 "default" alpha alpha)) .implicit
  let body := psLogicApply psStandardOptionRecursor
    [alpha, motive, .fvar 2, someBranch, .fvar 1]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "opt" option
      (psLogicLam 2 "default" alpha body)) .implicit
  .definitionDecl (psNameAppendStr psOptionName "getD") [] type value

def psStandardOptionMapDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let optionAlpha := psSelfHostOptionOf alpha
  let optionBeta := psSelfHostOptionOf beta
  let arrow := psLogicPi 4 "value" alpha beta
  let motive := psLogicLam 5 "_" optionAlpha optionBeta
  let someBranch := psLogicLam 6 "value" alpha
    (psSelfHostOptionSomeOf beta (.app (.fvar 2) (.fvar 6)))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "β" psPreludeTypeType
      (psLogicPi 2 "f" arrow
        (psLogicPi 3 "opt" optionAlpha optionBeta)) .implicit) .implicit
  let body := psLogicApply psStandardOptionRecursor
    [alpha, motive, psSelfHostOptionNoneOf beta, someBranch, .fvar 3]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "β" psPreludeTypeType
      (psLogicLam 2 "f" arrow
        (psLogicLam 3 "opt" optionAlpha body)) .implicit) .implicit
  .definitionDecl (psNameAppendStr psOptionName "map") [] type value

def psStandardOptionBindDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let optionAlpha := psSelfHostOptionOf alpha
  let optionBeta := psSelfHostOptionOf beta
  let arrow := psLogicPi 4 "value" alpha optionBeta
  let motive := psLogicLam 5 "_" optionAlpha optionBeta
  let someBranch := psLogicLam 6 "value" alpha (.app (.fvar 3) (.fvar 6))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "β" psPreludeTypeType
      (psLogicPi 2 "opt" optionAlpha
        (psLogicPi 3 "f" arrow optionBeta)) .implicit) .implicit
  let body := psLogicApply psStandardOptionRecursor
    [alpha, motive, psSelfHostOptionNoneOf beta, someBranch, .fvar 2]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "β" psPreludeTypeType
      (psLogicLam 2 "opt" optionAlpha
        (psLogicLam 3 "f" arrow body)) .implicit) .implicit
  .definitionDecl (psNameAppendStr psOptionName "bind") [] type value

def psStandardOptionDeclarations : List PsDeclaration :=
  [psStandardOptionGetDDeclaration,
   psStandardOptionMapDeclaration,
   psStandardOptionBindDeclaration]

def psStandardPreludeDeclarationsWithOption : List PsDeclaration :=
  psStandardPreludeDeclarationsWithToString ++ psStandardOptionDeclarations

def psStandardOptionExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardPreludeExtendWithToString environment
  psStandardOptionDeclarations.foldl (fun env decl =>
    (psEnvironmentAdd env decl).getD env) environment
