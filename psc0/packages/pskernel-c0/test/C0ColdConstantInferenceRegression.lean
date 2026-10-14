import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedInferenceDispatch

/-!
E.4O: independently source-equivalent COMPLETE cold constant inference.

The entire source constant typing decision is executed outside the recursive
source inference worker: source environment lookup, arity, safety/partial
admission, universe-argument discipline, type instantiation and exact
infer-only versus fully checked cache publication.

Each successful new result carries the exact original checker result AND
complete source state equation. Every failed or unsupported operation must
retain the original source error and resource semantics. A raw import or
cache hit is never a verified-provider proof certificate.
-/

def main : IO Unit := do
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let safeName : PsKernelName := .str .anonymous "ColdQualifiedDefinition"
  let safeInfo : PsKernelDefinitionInfo := {
    base := {
      name := safeName
      levelParams := []
      type := sort1
    }
    value := sort0
    hints := .abbrevHint
    safety := .safe
  }
  let env ← match psKernelAddDefinition 4096 psKernelEnvironmentEmpty
      safeInfo 4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e => throw (IO.userError ("cold safe definition source rejected: " ++ e))
  let session := psKernelMkCheckerSession env []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let constant : PsKernelExpr := .const safeName []
  let cold := psKernelC0ConstantCompleteInferWithFuel
    4096 session.context session.state safeName [] false
  match cold with
  | some (ty, nextState) =>
      if !psKernelExprEqual ty sort1 ||
          (psKernelExprMapGet nextState.checkedInfer constant).isNone then
        throw (IO.userError "cold independent full constant typing lost cache")
  | none => throw (IO.userError "direct cold constant rule unexpectedly declined")
  let coldInfer := psKernelC0ConstantCompleteInferWithFuel
    4096 session.context session.state safeName [] true
  match coldInfer with
  | some (ty, nextState) =>
      if !psKernelExprEqual ty sort1 ||
          (psKernelExprMapGet nextState.inferOnly constant).isNone ||
          (psKernelExprMapGet nextState.checkedInfer constant).isSome then
        throw (IO.userError "cold infer-only source cache mixed checked modes")
  | none => throw (IO.userError "cold infer-only constant declined")

  let some raw := psKernelC0ArchitectureBegin session
    | throw (IO.userError "cold constant original work failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "cold constant work certification failed")
  let full ← match psKernelC0CertifiedWorkCheckDirectOwned 4096 work constant with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("cold checked receipt failed: " ++ e))
  let _fullSource :
      psKernelC0CertifiedWorkCheck 4096 work constant = .ok full.val :=
    full.property
  if !psKernelExprEqual full.val.fst sort1 then
    throw (IO.userError "cold qualified checked result differs from source")
  let inferred ← match psKernelC0CertifiedWorkInferDirectOwned 4096 work constant with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("cold inferred receipt failed: " ++ e))
  let _inferSource :
      psKernelC0CertifiedWorkInfer 4096 work constant = .ok inferred.val :=
    inferred.property
  if !psKernelExprEqual inferred.val.fst sort1 then
    throw (IO.userError "cold qualified infer-only type differs from source")

  -- Both successful cold checks and subsequently warmed cache hits are
  -- independent from recursive source inference. No new checker session
  -- may acquire authority by a caller-provided forged raw cache.
  let (originalType, warm) ← match psKernelSessionCheck
      4096 session constant with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source warmup failed: " ++ e))
  if !psKernelExprEqual originalType sort1 ||
      (psKernelC0QualifiedInferHeadWithFuel 4096
        warm.context warm.state constant false).isNone then
    throw (IO.userError "source warm cache regression failed")
  let unknown : PsKernelExpr :=
    .const (.str .anonymous "NeverAdmittedConstant") []
  if (psKernelC0QualifiedInferHeadWithFuel 4096
      session.context session.state unknown false).isSome then
    throw (IO.userError "unknown cold constant acquired source type")
  match psKernelC0CertifiedWorkCheckDirectOwned 4096 work unknown with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unknown constant bypassed source error")
  if (psKernelC0ConstantCompleteInferWithFuel
      0 session.context session.state safeName [] false).isSome then
    throw (IO.userError "cold constant bypassed zero fuel")
  match psKernelC0CertifiedWorkCheckDirectOwned 0 work constant with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "cold checked constant bypassed zero fuel")
  let blocked : PsKernelCheckerContext := {
    session.context with
    maxRecDepth := 1
    recDepth := 1000000
  }
  if (psKernelC0ConstantCompleteInferWithFuel
      4096 blocked session.state safeName [] false).isSome then
    throw (IO.userError "cold constant bypassed recursion guard")

  -- Polymorphic source checking: infer-only permits an undeclared
  -- instantiation name, whereas full checking requires it in the
  -- current declared-level parameter list. Arity is checked first.
  let u : PsKernelName := .str .anonymous "sourceUniverse"
  let v : PsKernelName := .str .anonymous "foreignUniverse"
  let axiomName : PsKernelName := .str .anonymous "ColdUniverseAxiom"
  let axiomInfo : PsKernelAxiomInfo := {
    base := {
      name := axiomName
      levelParams := [u]
      type := .sort (.param u)
    }
    isUnsafe := false
  }
  let polymorphicEnv ← match psKernelAddAxiom 4096 env axiomInfo
      4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e => throw (IO.userError ("poly axiom source admission failed: " ++ e))
  let closed := psKernelMkCheckerSession polymorphicEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let good : PsKernelExpr := .const axiomName [.zero]
  let foreign : PsKernelExpr := .const axiomName [.param v]
  let missing : PsKernelExpr := .const axiomName []
  match psKernelC0QualifiedInferHeadWithFuel 4096
      closed.context closed.state good false with
  | some (ty, _) =>
      if !psKernelExprEqual ty sort0 then
        throw (IO.userError "cold independent level instantiation changed")
  | none => throw (IO.userError "valid cold polymorphic constant declined")
  match psKernelC0QualifiedInferHeadWithFuel 4096
      closed.context closed.state foreign true with
  | some (ty, _) =>
      if !psKernelExprEqual ty (.sort (.param v)) then
        throw (IO.userError "cold infer-only level substitution failed")
  | none => throw (IO.userError "cold infer-only universe was rejected")
  if (psKernelC0QualifiedInferHeadWithFuel 4096
      closed.context closed.state foreign false).isSome ||
      (psKernelC0QualifiedInferHeadWithFuel 4096
        closed.context closed.state missing false).isSome then
    throw (IO.userError "foreign universe or wrong arity obtained checked type")
  match psKernelCheckerCheck 4096 closed.context closed.state foreign with
  | .error "invalid reference to undefined universe level parameter" => pure ()
  | _ => throw (IO.userError "source undeclared universe error changed")
  match psKernelCheckerCheck 4096 closed.context closed.state missing with
  | .error "incorrect number of universe levels" => pure ()
  | _ => throw (IO.userError "source universe arity precedence changed")
  let authorized := psKernelMkCheckerSession polymorphicEnv [v]
    .safe 4096 psKernelLeanNatMaxSizeDefault
  match psKernelC0QualifiedInferHeadWithFuel
      4096 authorized.context authorized.state foreign false with
  | some (ty, _) =>
      if !psKernelExprEqual ty (.sort (.param v)) then
        throw (IO.userError "authorized universe cold instantiation differed")
  | none => throw (IO.userError "authorized cold checked constant declined")

  -- Original source safety policy is a prior obligation. Independent cold
  -- inference must decline unsafe/partial use in a safe context, and never
  -- reclassify a denied input as an accepted checked term.
  let unsafeName : PsKernelName := .str .anonymous "ColdUnsafeDefinition"
  let unsafeInfo : PsKernelDefinitionInfo := {
    base := {
      name := unsafeName
      levelParams := []
      type := sort1
    }
    value := sort0
    hints := .abbrevHint
    safety := .unsafeDef
  }
  let envUnsafe ← match psKernelAddDefinition 4096 polymorphicEnv
      unsafeInfo 4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e => throw (IO.userError ("unsafe source admission failed: " ++ e))
  let unsafeExpr : PsKernelExpr := .const unsafeName []
  let sourceSafe := psKernelMkCheckerSession envUnsafe []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  if (psKernelC0QualifiedInferHeadWithFuel 4096
      sourceSafe.context sourceSafe.state unsafeExpr false).isSome then
    throw (IO.userError "safe cold checker accepted unsafe dependency")
  match psKernelCheckerCheck 4096
      sourceSafe.context sourceSafe.state unsafeExpr with
  | .error "safe declaration uses unsafe constant" => pure ()
  | _ => throw (IO.userError "source unsafe rejection changed")
  let sourceUnsafe := psKernelMkCheckerSession envUnsafe []
    .unsafeDef 4096 psKernelLeanNatMaxSizeDefault
  if (psKernelC0QualifiedInferHeadWithFuel
      4096 sourceUnsafe.context sourceUnsafe.state unsafeExpr false).isNone then
    throw (IO.userError "authorized unsafe cold source typing declined")

  -- The verified public provider starts at the literal audited checked
  -- genesis; it never imports the manually constructed source checker.
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified cold constant genesis failed")
  match psKernelC0VerifiedProviderCheck genesis unknown with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider imported fabricated constant")
  let checkedSession ← match psKernelC0VerifiedProviderAdmit
      genesis (.definitionDecl safeInfo) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified safe constant admission failed")
  let (checkedTy, afterCheck) ← match psKernelC0VerifiedProviderCheck
      checkedSession constant with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified cold checked constant declined")
  if !psKernelExprEqual checkedTy sort1 ||
      !(psKernelC0HistoryAxiomSignatures
        afterCheck.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "source checked constant altered foundation history")

  IO.println "C0_COLD_CONST original_constant_rule_source_exact=pass"
  IO.println "C0_COLD_CONST arity_universes_safety_and_fuel=pass"
  IO.println "C0_COLD_CONST verified_provider_forged_import_isolation=pass"
