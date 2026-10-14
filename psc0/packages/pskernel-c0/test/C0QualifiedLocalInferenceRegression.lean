import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedLocalInference

/-!
Native Phase E.4L: source-exact FVar inference and full checking.

A local free variable must be present in the authoritative local context;
ordinary context lookup, shadowing, typed cache updates, fuel and recursion
are source-equivalent. This regression uses manually constructed local
contexts ONLY as low-level source semantic fixtures, never as verified
public-provider inputs.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let name : PsKernelName := .str .anonymous "LocalCheckedVariable"
  let expression : PsKernelExpr := .fvar name
  let expected : PsKernelExpr := .sort .zero
  let locals := psKernelLocalContextAddLocal source.context.localContext
    name name expected .default
  let contextual : PsKernelCheckerSession := {
    source with context :=
      psKernelCheckerContextWithLocalContext source.context locals
  }
  let some initial := psKernelC0ArchitectureBegin contextual
    | throw (IO.userError "qualified local work genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork initial
    | throw (IO.userError "qualified local source store certification failed")

  -- The local entry is genuinely independent of source InferCore; the
  -- theorem binds all its source checker state and typed-cache behavior.
  let directInfer := psKernelC0FVarInferWithFuel 4096
    contextual.context contextual.state name true
  let directCheck := psKernelC0FVarInferWithFuel 4096
    contextual.context contextual.state name false
  match directInfer, directCheck with
  | some (tyInfer, inferState), some (tyCheck, checkState) =>
      if !psKernelExprEqual tyInfer expected ||
          !psKernelExprEqual tyCheck expected then
        throw (IO.userError "independent local lookup returned wrong type")
      if (psKernelExprMapGet inferState.inferOnly expression).isNone ||
          (psKernelExprMapGet inferState.checkedInfer expression).isSome ||
          (psKernelExprMapGet checkState.checkedInfer expression).isNone ||
          (psKernelExprMapGet checkState.inferOnly expression).isSome then
        throw (IO.userError "local inference mixed source checked/infer caches")
  | _, _ =>
      throw (IO.userError "qualified local path declined a bound variable")

  let inferred ← match psKernelC0CertifiedWorkInferWithLocalsOwned
      4096 work expression with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("source local inference failed: " ++ e))
  let _inferEquation :
      psKernelC0CertifiedWorkInfer 4096 work expression = .ok inferred.val :=
    inferred.property
  let checked ← match psKernelC0CertifiedWorkCheckWithLocalsOwned
      4096 work expression with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("source local full checking failed: " ++ e))
  let _checkedEquation :
      psKernelC0CertifiedWorkCheck 4096 work expression = .ok checked.val :=
    checked.property
  if !psKernelExprEqual inferred.val.fst expected ||
      !psKernelExprEqual checked.val.fst expected then
    throw (IO.userError "qualified local receipts changed checked source type")

  -- A different local with the same unique name shadows the prior one
  -- in the source's authoritative ordered local-context representation.
  let newer : PsKernelExpr := .sort (.succ .zero)
  let shadow := psKernelLocalContextAddLocal locals
    name name newer .default
  let shadowContext := psKernelCheckerContextWithLocalContext
    contextual.context shadow
  match psKernelC0FVarInferWithFuel 4096 shadowContext source.state name false with
  | some (ty, _) =>
      if !psKernelExprEqual ty newer then
        throw (IO.userError "local source shadowing precedence changed")
  | none =>
      throw (IO.userError "local shadowing direct inference declined")

  -- Deep indexed-local lookup retains exactly the same value as the
  -- source list and its immutable pending-index overlay.
  let mut large := psKernelLocalContextEmpty
  for i in [:520] do
    let localName : PsKernelName := .num (.str .anonymous "deepLocal") i
    large := psKernelLocalContextAddLocal large localName localName
      expected .default
  let deepName : PsKernelName := .num (.str .anonymous "deepLocal") 3
  let deepContext := psKernelCheckerContextWithLocalContext
    contextual.context large
  match psKernelC0FVarInferWithFuel
      4096 deepContext source.state deepName false with
  | some (ty, _) =>
      if !psKernelExprEqual ty expected then
        throw (IO.userError "deep local source index lookup changed type")
  | none =>
      throw (IO.userError "deep source local index lookup declined")

  -- Unknown locals and exhausted source budget never gain an accepted
  -- type from the direct family.
  let unknown : PsKernelName := .str .anonymous "UnknownLocalName"
  if (psKernelC0FVarInferWithFuel 4096 source.context
      source.state unknown false).isSome then
    throw (IO.userError "unknown local was independently accepted")
  match psKernelCheckerCheck 4096 source.context source.state (.fvar unknown) with
  | .error "unknown free variable" => pure ()
  | _ => throw (IO.userError "unknown local source error classification changed")
  if (psKernelC0FVarInferWithFuel 0 contextual.context
      contextual.state name false).isSome then
    throw (IO.userError "local direct inference ignored zero source fuel")
  match psKernelC0CertifiedWorkCheckWithLocalsOwned 0 work expression with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "zero source fuel checked a local")
  let blockedContext : PsKernelCheckerContext := {
    contextual.context with
    maxRecDepth := 1
    recDepth := 1000000
  }
  if (psKernelC0FVarInferWithFuel 4096 blockedContext
      contextual.state name false).isSome then
    throw (IO.userError "local inference ignored source recursion budget")

  -- Constructible raw caches are deliberately NOT public proof authority.
  -- Source equivalence records them, but the verified provider starts
  -- only from independently qualified empty checked genesis.
  let forged : PsKernelExpr := .sort (.succ (.succ .zero))
  let poisoned := psKernelCheckerStateWithCheckedInfer source.state
    (psKernelExprMapInsert source.state.checkedInfer expression forged)
  match psKernelC0FVarInferWithFuel 4096
      source.context poisoned name false with
  | some (cached, _) =>
      if !psKernelExprEqual cached forged then
        throw (IO.userError "raw cache source behavior was not matched")
  | none => throw (IO.userError "raw cache compatibility path was not reached")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let provider ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok work => pure work
    | .error _ => throw (IO.userError "verified local provider genesis failed")
  match psKernelC0VerifiedProviderCheck provider expression with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified public provider admitted raw local context")
  match psKernelC0VerifiedProviderInfer provider expression with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified inference accepted unqualified FVar")

  IO.println "C0_LOCAL_INFER source_exact_fvar_infer_and_check=pass"
  IO.println "C0_LOCAL_INFER shadowing_deep_context_and_resource_boundaries=pass"
  IO.println "C0_LOCAL_INFER raw_cache_isolation_and_verified_provider=pass"
