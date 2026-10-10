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

/-- Deliberately malformed LOW-LEVEL contexts exercise the new certification
boundary. They are not admitted public environments or checker exploits. -/
private def checkLambdaCodomainGate (policy : PsKernelSemanticCachePolicy) : IO Unit := do
  let x := PsKernelName.str .anonymous "x"
  let y := PsKernelName.str .anonymous "uncertifiedLocal"
  let base := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let withType := fun ty =>
    psKernelCheckerContextWithLocalContext base
      (psKernelLocalContextAddLocal base.localContext y y ty .default)
  let term := PsKernelExpr.lam x (.sort .zero) (.fvar y) .default
  -- Re-inference of this body's supplied type encounters a loose variable.
  match @psKernelCheckerCheck policy 64 (withType (.bvar 0))
      psKernelCheckerStateEmpty term with
  | .ok _ => throw (IO.userError "checked lambda skipped codomain certification")
  | .error msg =>
      match psKernelErrorFromMessage msg with
      | .declinedUnsupported _ => pure ()
      | _ => throw (IO.userError "uncertified codomain was not a decline")
  -- Infer-only is intentionally a separate grade with validity preconditions.
  match @psKernelCheckerInfer policy 64 (withType (.bvar 0))
      psKernelCheckerStateEmpty term with
  | .ok _ => pure ()
  | .error _ => throw (IO.userError "infer-only grade acquired the checked-only gate")
  let mut deepType := PsKernelExpr.sort .zero
  for _ in [:32] do
    deepType := .forallE x (.sort .zero) deepType .default
  match @psKernelCheckerCheck policy 8 (withType deepType)
      psKernelCheckerStateEmpty term with
  | .ok _ => throw (IO.userError "codomain fixture did not exhaust its inference budget")
  | .error msg =>
      match psKernelErrorFromMessage msg with
      | .resourceExhausted .fuel _ => pure ()
      | _ => throw (IO.userError "codomain certification lost resource classification")


private abbrev SortVisitOperation :=
  PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr ->
    Except String (Prod PsKernelExpr PsKernelCheckerState)

private def expectLambdaVisitFailure (infer whnf : SortVisitOperation)
    (expected : String) (resource : Bool) : IO Unit := do
  let c := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  match psKernelLambdaCodomainVisitWith infer whnf c psKernelCheckerStateEmpty
      (.sort .zero) false with
  | .ok _ => throw (IO.userError "failing codomain visit unexpectedly succeeded")
  | .error message =>
      require (psKernelStringEq message expected) "codomain visit changed its error message"
      match psKernelErrorFromMessage message with
      | .resourceExhausted .fuel _ =>
          require resource "non-resource codomain failure became resource exhaustion"
      | .declinedUnsupported _ =>
          require (!resource) "resource codomain failure became an unsupported decline"
      | _ => throw (IO.userError "codomain visit changed its public error classification")

/-- Exercise the actual shared visit boundary: skipped callbacks, exact
symbolic observations, state sequencing, and both failure stages. -/
private def checkSortVisitCarriers : IO Unit := do
  let c := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let start := { psKernelCheckerStateEmpty with nextFresh := 17 }
  let bodyType := PsKernelExpr.fvar (.str .anonymous "visitSubject")
  let reject : SortVisitOperation := fun _ _ _ =>
    .error "a skipped visit callback ran"
  match psKernelLambdaCodomainVisitWith reject reject c start bodyType true with
  | .ok (.unchecked, after) =>
      require (Nat.beq after.nextFresh 17) "unchecked visit changed state"
      require (psKernelLambdaCodomainVisitLevel .unchecked).isNone
        "unchecked visit manufactured a level"
  | _ => throw (IO.userError "infer-only codomain visit called a rejecting callback")

  let inferredType := PsKernelExpr.const (.str .anonymous "visitNeedsWhnf") []
  let symbolicLevel := PsKernelLevel.imax
    (.param (.str .anonymous "u"))
    (.max (.param (.str .anonymous "v")) (.mvar (.str .anonymous "w")))
  let infer : SortVisitOperation := fun _ state expr =>
    if psKernelExprEq expr bodyType && Nat.beq state.nextFresh 17 then
      .ok (inferredType, { state with nextFresh := 29 })
    else
      .error "codomain inference received the wrong expression or state"
  let expose : SortVisitOperation := fun _ state expr =>
    if psKernelExprEq expr inferredType && Nat.beq state.nextFresh 29 then
      .ok (.sort symbolicLevel, { state with nextFresh := 41 })
    else
      .error "codomain sort exposure received the wrong expression or state"
  match psKernelLambdaCodomainVisitWith infer expose c start bodyType false with
  | .ok (.observed visit, after) =>
      require (psKernelExprEq visit.inferredType inferredType)
        "codomain visit replaced the actual inferred type by its normal form"
      require (psKernelExprEq (.sort visit.level) (.sort symbolicLevel))
        "codomain visit lost the actual symbolic sort level"
      match psKernelLambdaCodomainVisitLevel (.observed visit) with
      | .none => throw (IO.userError "observed visit lost its selected level")
      | .some level =>
          require (psKernelExprEq (.sort level) (.sort symbolicLevel))
            "observed level accessor changed the selected level"
      require (Nat.beq after.nextFresh 41) "codomain visit lost the sort-exposure state"
  | .ok (.unchecked, _) => throw (IO.userError "checked visit returned unchecked evidence")
  | .error message => throw (IO.userError ("symbolic codomain visit failed: " ++ message))

  let directType := PsKernelExpr.sort symbolicLevel
  let direct : SortVisitOperation := fun _ state _ => .ok (directType, state)
  match psKernelLambdaCodomainVisitWith direct reject c start bodyType false with
  | .ok (.observed visit, after) =>
      require (psKernelExprEq visit.inferredType directType &&
        psKernelExprEq (.sort visit.level) (.sort symbolicLevel) &&
        Nat.beq after.nextFresh 17)
        "direct-sort visit changed its observation or state"
  | _ => throw (IO.userError "direct-sort visit called a rejecting WHNF callback")

  let unresolved : SortVisitOperation := fun _ state _ => .ok (inferredType, state)
  expectLambdaVisitFailure
    (fun _ _ _ => .error "kernel inference budget exhausted")
    reject "kernel inference budget exhausted" true
  expectLambdaVisitFailure
    (fun _ _ _ => .error "invalid inferred codomain")
    reject "lambda codomain sort could not be certified" false
  expectLambdaVisitFailure unresolved
    (fun _ _ _ => .error "kernel reduction budget exhausted")
    "kernel reduction budget exhausted" true
  expectLambdaVisitFailure unresolved
    (fun _ _ _ => .error "invalid codomain exposure")
    "lambda codomain sort could not be certified" false
  expectLambdaVisitFailure unresolved
    (fun _ state expr => .ok (expr, state))
    "lambda codomain sort could not be certified" false

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
  checkLambdaCodomainGate psKernelCachedCachePolicy
  checkLambdaCodomainGate psKernelReferenceCachePolicy
  checkSortVisitCarriers
  IO.println "PSKERNEL_SORT_VISIT_CARRIERS: PASS unchecked=1 observed=2 failures=5"
  IO.println "PSKERNEL_LAMBDA_CODOMAIN_GATE: PASS modes=2 declined=2 inferOnly=2 resource=2"
  IO.println "PSKERNEL_LAMBDA_TYPE_TRANSPORT: PASS modes=2 regimes=2 checked=4 inferOnly=4 conversion=4 validAdmission=4 invalidAdmission=4"
  IO.println "PSKERNEL_REFERENCE_TESTS: PASS poison=3 dependent-binders=1 admission=3 resource=1"
