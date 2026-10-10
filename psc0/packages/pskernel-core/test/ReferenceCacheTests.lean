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
  IO.println "PSKERNEL_REFERENCE_TESTS: PASS poison=3 dependent-binders=1 admission=3 resource=1"
