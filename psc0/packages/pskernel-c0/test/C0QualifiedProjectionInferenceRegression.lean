import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedProjectionInference

/-!
Phase E.4V native projection conformance against a REAL source-admitted
nonrecursive structure, not fabricated inductive metadata.

The source-proved projection head uses the exact Lean 4.35-compatible
projection validator, recursive infer/WHNF workers, checked/infer-only
cache policy and fuel/depth guards. Invalid indices/families/major terms
must be rejected, including atomic checked-root publication failures.
-/

def c0ProjectionName (s : String) : PsKernelName :=
  .str .anonymous s

def c0ProjectionBox : PsKernelName :=
  c0ProjectionName "C0VerifiedProjectionBox"

def c0ProjectionCtor : PsKernelName :=
  .str c0ProjectionBox "mk"

def c0ProjectionDecl : PsKernelSimpleInductiveDecl := {
  levelParams := []
  name := c0ProjectionBox
  type := .sort (.succ (.succ .zero))
  ctors := [
    {
      name := c0ProjectionCtor
      type := .forallE (c0ProjectionName "fieldA")
          (.sort (.succ .zero))
        (.forallE (c0ProjectionName "fieldB")
          (.sort (.succ .zero))
          (.const c0ProjectionBox []) .default) .default
    }
  ]
  isUnsafe := false
  numParams := 0
}

def main : IO Unit := do
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let constructor : PsKernelExpr :=
    .app (.app (.const c0ProjectionCtor []) sort0) sort0
  let left : PsKernelExpr := .proj c0ProjectionBox 0 constructor
  let right : PsKernelExpr := .proj c0ProjectionBox 1 constructor
  let badIndex : PsKernelExpr := .proj c0ProjectionBox 2 constructor
  let badFamily : PsKernelExpr :=
    .proj (c0ProjectionName "AnotherBox") 0 constructor
  let badMajor : PsKernelExpr := .proj c0ProjectionBox 0 sort0
  let unknownMajor : PsKernelExpr :=
    .proj c0ProjectionBox 0
      (.mvar (c0ProjectionName "untrustedProjection"))

  let original := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 8192 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin original
    | throw (IO.userError "source projection work genesis failed")
  let admitted ← match psKernelC0ArchitectureAdmit 8192 raw
      (.ordinaryInductive c0ProjectionDecl) with
    | .error e => throw (IO.userError ("real checked Box admission failed: " ++ e))
    | .ok next => pure next
  let some certified := psKernelC0ArchitectureCertifyWork admitted
    | throw (IO.userError "admitted projection store was not certified")

  if !psKernelEnvironmentIsNonRecStructure
      admitted.checker.context.environment c0ProjectionBox then
    throw (IO.userError "source projection structure not recognized")

  for expr in [left, right] do
    let sourceType ← match psKernelSessionCheck 8192
        admitted.checker expr with
      | .ok (type, _) => pure type
      | .error e => throw (IO.userError ("source projection failed: " ++ e))
    if !psKernelExprEqual sourceType sort1 then
      throw (IO.userError "source projection returned wrong field type")
    let checked ← match psKernelC0CertifiedWorkCheckProjectionOwned
        8192 certified expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("qualified projection failed: " ++ e))
    let _exactChecked :
        psKernelC0CertifiedWorkCheck 8192 certified expr =
          .ok checked.val :=
      checked.property
    if !psKernelExprEqual checked.val.fst sourceType then
      throw (IO.userError "projection full-check source type diverged")
    let inferred ← match psKernelC0CertifiedWorkInferProjectionOwned
        8192 certified expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("infer-only projection failed: " ++ e))
    let _exactInfer :
        psKernelC0CertifiedWorkInfer 8192 certified expr =
          .ok inferred.val :=
      inferred.property
    if !psKernelExprEqual inferred.val.fst sourceType then
      throw (IO.userError "projection infer-only source type diverged")

  -- All rejected forms must preserve the exact source error and can
  -- NEVER become root certificates by a syntax-only projection guess.
  for invalid in [badIndex, badFamily, badMajor, unknownMajor] do
    match psKernelC0CertifiedWorkCheckProjectionOwned
        8192 certified invalid,
        psKernelC0CertifiedWorkCheck 8192 certified invalid with
    | .error actual, .error sourceError =>
        if actual != sourceError then
          throw (IO.userError "projection source failure classification changed")
    | _, _ =>
        throw (IO.userError "invalid projection was accepted")
  for expr in [left, right] do
    match psKernelC0CertifiedWorkCheckProjectionOwned 0 certified expr,
          psKernelC0CertifiedWorkCheck 0 certified expr with
    | .error actual, .error sourceError =>
        if actual != sourceError then
          throw (IO.userError "projection source zero-fuel error changed")
    | _, _ =>
        throw (IO.userError "projection bypassed zero source fuel")
  let blocked : PsKernelCheckerSession := {
    admitted.checker with
    context := {
      admitted.checker.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked projection work failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked projection certification failed")
  match psKernelC0CertifiedWorkCheckProjectionOwned
      8192 blockedWork left,
      psKernelC0CertifiedWorkCheck 8192 blockedWork left with
  | .error actual, .error sourceError =>
      if actual != sourceError then
        throw (IO.userError "projection source recursion error changed")
  | _, _ =>
      throw (IO.userError "projection bypassed source depth guard")

  -- Verified public checking starts with the exact audited empty genesis
  -- and source-admits this structure. It never imports a hand-built
  -- raw checker cache or assumes a positive projection without typing.
  let resources : PsKernelResourcePolicy := {
    fuel := 8192
    maxRecDepth := 8192
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 32
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok session => pure session
    | .error _ => throw (IO.userError "projection verified genesis failed")
  let verified ← match psKernelC0VerifiedProviderAdmit genesis
      (.ordinaryInductive c0ProjectionDecl) with
    | .ok session => pure session
    | .error _ => throw (IO.userError "verified structure admission failed")
  let (fieldTy, _) ← match psKernelC0VerifiedProviderCheck verified left with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified checked projection rejected")
  if !psKernelExprEqual fieldTy sort1 then
    throw (IO.userError "verified projection source field type changed")
  let publication ← match psKernelC0VerifiedProviderPublishRoots
      verified [left, right] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "source-checked projection publication failed")
  let _exactStage :=
    psKernelC0VerifiedProviderPublicationStagingExact publication
  let _exactCheck :=
    psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 2 then
    throw (IO.userError "verified projection publication lost roots")
  match psKernelC0VerifiedProviderPublishRoots verified [left, badIndex] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "mixed valid/invalid projections published")
  if !(psKernelC0HistoryAxiomSignatures
      publication.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "checked projection created a trusted axiom")

  IO.println "C0_QUALIFIED_PROJECTION real_admitted_structure_fields=pass"
  IO.println "C0_QUALIFIED_PROJECTION full_source_type_and_error_equations=pass"
  IO.println "C0_QUALIFIED_PROJECTION verified_atomic_source_publication=pass"
