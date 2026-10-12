import Ps.Environment.StandardProduct

-- Selected Lean 4.35 RC4 Except library operations for Type-0
-- exceptions/results. Every branch is a checked eliminator; no host-level
-- JavaScript exception, source-only macro, or trusted runtime hook is added.
def psStandardExceptEliminate (epsilon alpha resultType major : PsExpr)
    (errorMinor successMinor : PsExpr) : PsExpr :=
  let source := psSelfHostExceptOf epsilon alpha
  let motive := psLogicLam 12 "_" source resultType
  psLogicApply (.constE psSelfHostExceptRecName [.succ .zero])
    [epsilon, alpha, motive, errorMinor, successMinor, major]

def psStandardExceptBindDeclaration : PsDeclaration :=
  let epsilon := PsExpr.fvar 0
  let alpha := PsExpr.fvar 1
  let beta := PsExpr.fvar 2
  let source := psSelfHostExceptOf epsilon alpha
  let result := psSelfHostExceptOf epsilon beta
  let callback := psLogicPi 5 "value" alpha result
  let errorMinor := psLogicLam 6 "err" epsilon
    (psSelfHostExceptErrorOf epsilon beta (.fvar 6))
  let successMinor := psLogicLam 7 "value" alpha
    (.app (.fvar 4) (.fvar 7))
  let body := psStandardExceptEliminate epsilon alpha result (.fvar 3)
    errorMinor successMinor
  let type := psLogicPi 0 "ε" psPreludeTypeType
    (psLogicPi 1 "α" psPreludeTypeType
      (psLogicPi 2 "β" psPreludeTypeType
        (psLogicPi 3 "action" source
          (psLogicPi 4 "f" callback result)) .implicit) .implicit) .implicit
  let value := psLogicLam 0 "ε" psPreludeTypeType
    (psLogicLam 1 "α" psPreludeTypeType
      (psLogicLam 2 "β" psPreludeTypeType
        (psLogicLam 3 "action" source
          (psLogicLam 4 "f" callback body)) .implicit) .implicit) .implicit
  .definitionDecl (psNameAppendStr psSelfHostExceptName "bind") [] type value

-- Map is expressed in terms of the checked bind operation. This deliberately
-- shares one error-propagation mechanism rather than copying a recursor.
def psStandardExceptMapDeclaration : PsDeclaration :=
  let epsilon := PsExpr.fvar 0
  let alpha := PsExpr.fvar 1
  let beta := PsExpr.fvar 2
  let source := psSelfHostExceptOf epsilon alpha
  let result := psSelfHostExceptOf epsilon beta
  let callback := psLogicPi 5 "value" alpha beta
  let wrapped := psLogicLam 6 "value" alpha
    (psSelfHostExceptOkOf epsilon beta (.app (.fvar 3) (.fvar 6)))
  let body := psLogicApply (.constE
    (psNameAppendStr psSelfHostExceptName "bind") [])
      [epsilon, alpha, beta, .fvar 4, wrapped]
  let type := psLogicPi 0 "ε" psPreludeTypeType
    (psLogicPi 1 "α" psPreludeTypeType
      (psLogicPi 2 "β" psPreludeTypeType
        (psLogicPi 3 "f" callback
          (psLogicPi 4 "action" source result)) .implicit) .implicit) .implicit
  let value := psLogicLam 0 "ε" psPreludeTypeType
    (psLogicLam 1 "α" psPreludeTypeType
      (psLogicLam 2 "β" psPreludeTypeType
        (psLogicLam 3 "f" callback
          (psLogicLam 4 "action" source body)) .implicit) .implicit) .implicit
  .definitionDecl (psNameAppendStr psSelfHostExceptName "map") [] type value

def psStandardExceptMapErrorDeclaration : PsDeclaration :=
  let epsilon := PsExpr.fvar 0
  let delta := PsExpr.fvar 1
  let alpha := PsExpr.fvar 2
  let source := psSelfHostExceptOf epsilon alpha
  let result := psSelfHostExceptOf delta alpha
  let callback := psLogicPi 5 "error" epsilon delta
  let errorMinor := psLogicLam 6 "error" epsilon
    (psSelfHostExceptErrorOf delta alpha (.app (.fvar 3) (.fvar 6)))
  let successMinor := psLogicLam 7 "value" alpha
    (psSelfHostExceptOkOf delta alpha (.fvar 7))
  let body := psStandardExceptEliminate epsilon alpha result (.fvar 4)
    errorMinor successMinor
  let type := psLogicPi 0 "ε" psPreludeTypeType
    (psLogicPi 1 "δ" psPreludeTypeType
      (psLogicPi 2 "α" psPreludeTypeType
        (psLogicPi 3 "f" callback
          (psLogicPi 4 "action" source result)) .implicit) .implicit) .implicit
  let value := psLogicLam 0 "ε" psPreludeTypeType
    (psLogicLam 1 "δ" psPreludeTypeType
      (psLogicLam 2 "α" psPreludeTypeType
        (psLogicLam 3 "f" callback
          (psLogicLam 4 "action" source body)) .implicit) .implicit) .implicit
  .definitionDecl (psNameAppendStr psSelfHostExceptName "mapError") [] type value

-- The handler is only invoked for error; a successful value is unchanged.
def psStandardExceptTryCatchDeclaration : PsDeclaration :=
  let epsilon := PsExpr.fvar 0
  let alpha := PsExpr.fvar 1
  let family := psSelfHostExceptOf epsilon alpha
  let callback := psLogicPi 4 "error" epsilon family
  let errorMinor := psLogicLam 5 "error" epsilon
    (.app (.fvar 3) (.fvar 5))
  let successMinor := psLogicLam 6 "value" alpha
    (psSelfHostExceptOkOf epsilon alpha (.fvar 6))
  let body := psStandardExceptEliminate epsilon alpha family (.fvar 2)
    errorMinor successMinor
  let type := psLogicPi 0 "ε" psPreludeTypeType
    (psLogicPi 1 "α" psPreludeTypeType
      (psLogicPi 2 "action" family
        (psLogicPi 3 "handle" callback family)) .implicit) .implicit
  let value := psLogicLam 0 "ε" psPreludeTypeType
    (psLogicLam 1 "α" psPreludeTypeType
      (psLogicLam 2 "action" family
        (psLogicLam 3 "handle" callback body)) .implicit) .implicit
  .definitionDecl (psNameAppendStr psSelfHostExceptName "tryCatch") [] type value

def psStandardExceptIsOkDeclaration : PsDeclaration :=
  let epsilon := PsExpr.fvar 0
  let alpha := PsExpr.fvar 1
  let family := psSelfHostExceptOf epsilon alpha
  let bool := PsExpr.constE psBoolName []
  let errorMinor := psLogicLam 3 "_" epsilon
    (.constE psBoolFalseName [])
  let successMinor := psLogicLam 4 "_" alpha
    (.constE psBoolTrueName [])
  let body := psStandardExceptEliminate epsilon alpha bool (.fvar 2)
    errorMinor successMinor
  let type := psLogicPi 0 "ε" psPreludeTypeType
    (psLogicPi 1 "α" psPreludeTypeType
      (psLogicPi 2 "action" family bool) .implicit) .implicit
  let value := psLogicLam 0 "ε" psPreludeTypeType
    (psLogicLam 1 "α" psPreludeTypeType
      (psLogicLam 2 "action" family body) .implicit) .implicit
  .definitionDecl (psNameAppendStr psSelfHostExceptName "isOk") [] type value

def psStandardExceptToOptionDeclaration : PsDeclaration :=
  let epsilon := PsExpr.fvar 0
  let alpha := PsExpr.fvar 1
  let family := psSelfHostExceptOf epsilon alpha
  let output := psSelfHostOptionOf alpha
  let errorMinor := psLogicLam 3 "_" epsilon
    (psSelfHostOptionNoneOf alpha)
  let successMinor := psLogicLam 4 "value" alpha
    (psSelfHostOptionSomeOf alpha (.fvar 4))
  let body := psStandardExceptEliminate epsilon alpha output (.fvar 2)
    errorMinor successMinor
  let type := psLogicPi 0 "ε" psPreludeTypeType
    (psLogicPi 1 "α" psPreludeTypeType
      (psLogicPi 2 "action" family output) .implicit) .implicit
  let value := psLogicLam 0 "ε" psPreludeTypeType
    (psLogicLam 1 "α" psPreludeTypeType
      (psLogicLam 2 "action" family body) .implicit) .implicit
  .definitionDecl (psNameAppendStr psSelfHostExceptName "toOption") [] type value

def psStandardExceptDeclarations : List PsDeclaration :=
  [psStandardExceptBindDeclaration, psStandardExceptMapDeclaration,
   psStandardExceptMapErrorDeclaration, psStandardExceptTryCatchDeclaration,
   psStandardExceptIsOkDeclaration, psStandardExceptToOptionDeclaration]

-- Called only after the existing Except type, constructors and recursor have
-- already been installed and checked, together with the Standard dictionaries.
def psStandardExceptExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardExceptDeclarations.foldl (fun current declaration =>
    (psEnvironmentAdd current declaration).getD current) environment

def psStandardExceptAudit (environment : PsEnvironment) : Except String Unit := do
  psStandardProductAudit environment
  for declaration in psStandardExceptDeclarations do
    psStandardAuditDeclaration environment declaration
