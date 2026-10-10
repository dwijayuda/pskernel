import Ps.KernelCore.API.Reference

private def require (ok : Bool) (message : String) : IO Unit :=
  unless ok do throw (IO.userError message)

private def mapEmpty (m : PsKernelExprMap) : Bool :=
  m.small.isEmpty && m.index.isNone

private def pairEmpty (s : PsKernelExprPairSet) : Bool :=
  s.small.isEmpty && s.index.isNone

private def cachesEmpty (s : PsKernelCheckerState) : Bool :=
  mapEmpty s.inferOnly && mapEmpty s.checkedInfer && mapEmpty s.whnfCore &&
  mapEmpty s.whnf && mapEmpty s.unfold && pairEmpty s.success && pairEmpty s.failure

/-- Inference may retain beta redexes in a lambda's result type. Public
declaration checking must compare that type with the user's stated type by
ordinary conversion, under either semantic-cache policy. -/
private def checkLambdaTypeTransport (policy : PsKernelSemanticCachePolicy)
    (level : PsKernelLevel) (tag : String) : IO Unit := do
  let c := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let p := PsKernelExpr.sort level
  let P := PsKernelName.str .anonymous "P"
  let Q := PsKernelName.str .anonymous "Q"
  let h := PsKernelName.str .anonymous "h"
  let idType := PsKernelExpr.lam Q p (.bvar 0) .default
  let domain := PsKernelExpr.app idType (.bvar 0)
  let term := PsKernelExpr.lam P p (.lam h domain (.bvar 0) .default) .default
  let unreduced := PsKernelExpr.forallE P p
    (.forallE h domain (.app idType (.bvar 1)) .default) .default
  let reduced := PsKernelExpr.forallE P p
    (.forallE h (.bvar 0) (.bvar 1) .default) .default
  match @psKernelCheckerCheck policy 4096 c psKernelCheckerStateEmpty term with
  | .error e => throw (IO.userError (tag ++ ": checked inference failed: " ++ e))
  | .ok (actual, _) =>
      require (psKernelExprEq actual unreduced)
        (tag ++ ": lambda inference changed its recursively inferred body type")
      match @psKernelIsDefEq policy 4096 c psKernelCheckerStateEmpty actual reduced with
      | .ok (true, _) => pure ()
      | _ => throw (IO.userError (tag ++ ": retained type did not convert to declared type"))
  match @psKernelCheckerInfer policy 4096 c psKernelCheckerStateEmpty term with
  | .ok (actual, _) =>
      require (psKernelExprEq actual unreduced) (tag ++ ": infer-only result drift")
  | .error e => throw (IO.userError (tag ++ ": infer-only failed: " ++ e))
  let session := PsKernelKernelSession.mk psKernelEnvironmentEmpty
    { psKernelResourcePolicyDefault with fuel := 4096 } psKernelProviderDefault
  let definition : PsKernelDefinitionInfo :=
    { base := { name := .str .anonymous tag, levelParams := [], type := reduced },
      value := term, hints := .regular 0, safety := .safe }
  match @psKernelV1AdmitDeclaration policy session (.definitionDecl definition) with
  | .ok _ => pure ()
  | .error _ => throw (IO.userError (tag ++ ": valid converted declaration rejected"))
  let impossible := PsKernelExpr.forallE P p (.bvar 0) .default
  match @psKernelV1AdmitDeclaration policy session
      (.definitionDecl { definition with base := { definition.base with type := impossible } }) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError (tag ++ ": invalid all-types inhabitant was not rejected"))

def main : IO Unit := do
  let c := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let p := PsKernelExpr.sort .zero
  let ty := PsKernelExpr.sort (.succ .zero)
  let wrong := PsKernelExpr.sort (.succ (.succ .zero))
  let forged := psKernelExprMapInsert psKernelExprMapEmpty p wrong
  let poisoned := { psKernelCheckerStateEmpty with
    inferOnly := forged, checkedInfer := forged,
    whnf := forged, whnfCore := forged, unfold := forged,
    success := psKernelExprPairSetInsert psKernelExprPairSetEmpty p wrong }
  -- These are deliberately invalid LOW-LEVEL states, never admitted API sessions.
  -- Prove the fixture reaches a cache hit, then require the reference to ignore it.
  match psKernelCheckerInfer 64 c poisoned p with
  | .error e => throw (IO.userError e)
  | .ok (A, _) => require (psKernelExprEq A wrong) "poison fixture did not hit cached inference"
  match @psKernelCheckerInfer psKernelReferenceCachePolicy 64 c poisoned p with
  | .error e => throw (IO.userError e)
  | .ok (A, _) => require (psKernelExprEq A ty) "reference used poisoned inference"
  match @psKernelCheckerWhnf psKernelReferenceCachePolicy 64 c poisoned p with
  | .error e => throw (IO.userError e)
  | .ok (e, _) => require (psKernelExprEq e p) "reference used poisoned reduction"
  match @psKernelIsDefEq psKernelReferenceCachePolicy 64 c poisoned p wrong with
  | .error e => throw (IO.userError e)
  | .ok (equal, _) => require (!equal) "reference used poisoned equality"

  let A := PsKernelName.str .anonymous "A"
  let x := PsKernelName.str .anonymous "x"
  let identity := PsKernelExpr.lam A ty (.lam x (.bvar 0) (.bvar 0) .default) .default
  let identityType := PsKernelExpr.forallE A ty
    (.forallE x (.bvar 0) (.bvar 1) .default) .default
  match @psKernelCheckerCheck psKernelReferenceCachePolicy
      512 c psKernelCheckerStateEmpty identity with
  | .error e => throw (IO.userError e)
  | .ok (A, s) =>
      require (psKernelExprEq A identityType) "reference inferred wrong dependent identity type"
      require (cachesEmpty s) "reference published semantic cache entries under binders"

  let session := PsKernelKernelSession.mk psKernelEnvironmentEmpty
    { psKernelResourcePolicyDefault with fuel := 512 } psKernelProviderDefault
  let name := PsKernelName.str .anonymous "referenceIdentity"
  let definition : PsKernelDefinitionInfo :=
    { base := { name := name, levelParams := [], type := identityType },
      value := identity, hints := .regular 0, safety := .safe }
  match psKernelReferenceAdmitDeclaration session (.definitionDecl definition) with
  | .error _ => throw (IO.userError "reference rejected a valid definition")
  | .ok admitted =>
      require (psKernelEnvironmentContains admitted.session.environment name)
        "reference did not commit the valid declaration"
      match psKernelReferenceCheckExpression admitted.session [] .safe (.const name []) with
      | .error _ => throw (IO.userError "reference failed after environment extension")
      | .ok _ => pure ()
  match psKernelReferenceAdmitDeclaration session
      (.definitionDecl { definition with value := p }) with
  | .ok _ => throw (IO.userError "reference accepted an invalid definition")
  | .error (.rejectedInvalid _) => pure ()
  | .error _ => throw (IO.userError "invalid definition was not classified as invalid")

  let emptyType : PsKernelSimpleInductiveDecl :=
    { name := .str .anonymous "ReferenceEmpty", levelParams := [], type := p,
      ctors := [], isUnsafe := false, numParams := 0 }
  match psKernelReferenceAdmitDeclaration session (.ordinaryInductive emptyType) with
  | .error _ => throw (IO.userError "reference rejected empty inductive admission")
  | .ok _ => pure ()
  let stopped := { session with resources := { session.resources with fuel := 0 } }
  match psKernelReferenceCheckExpression stopped [] .safe identity with
  | .error (.resourceExhausted .fuel _) => pure ()
  | _ => throw (IO.userError "reference lost the resource-exhaustion boundary")
  checkLambdaTypeTransport psKernelCachedCachePolicy .zero "lambdaPropCached"
  checkLambdaTypeTransport psKernelReferenceCachePolicy .zero "lambdaPropReference"
  checkLambdaTypeTransport psKernelCachedCachePolicy (.succ .zero) "lambdaTypeCached"
  checkLambdaTypeTransport psKernelReferenceCachePolicy (.succ .zero) "lambdaTypeReference"
  IO.println "PSKERNEL_LAMBDA_TYPE_TRANSPORT: PASS modes=2 regimes=2 checked=4 inferOnly=4 conversion=4 validAdmission=4 invalidAdmission=4"
  IO.println "PSKERNEL_REFERENCE_TESTS: PASS poison=3 dependent-binders=1 admission=3 resource=1"
