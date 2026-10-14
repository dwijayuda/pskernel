import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Checker.Inference.App

/-!
Phase E.4S: preserve complete Lean 4.35-compatible source application
semantics after moving C0 checked/infer-only application rules into a
dedicated source helper.

Official type checker reference: infer_app, ensure_pi, full argument
checking and DefEq, eager reduction, dependent type instantiation and the
separate infer-only argument-spine exposure. Long application spines retain
the existing C0 checked-app callback and all source resource limits.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "ApplicationBinder"
  let sort0 : PsKernelExpr := .sort .zero
  let depProp : PsKernelExpr := .forallE name sort0 (.bvar 0) .default
  let identity : PsKernelExpr := .lam name sort0 (.bvar 0) .default
  let valid : PsKernelExpr := .app identity depProp
  let invalid : PsKernelExpr := .app identity sort0
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let (checkedType, _) ← match psKernelSessionCheck 4096 source valid with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source checked app declined: " ++ e))
  if !psKernelExprEqual checkedType sort0 then
    throw (IO.userError "source checked application instantiation changed")
  let (inferredType, _) ← match psKernelSessionInfer 4096 source valid with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source infer-only app declined: " ++ e))
  if !psKernelExprEqual inferredType sort0 then
    throw (IO.userError "source infer-only spine result changed")
  match psKernelSessionCheck 4096 source invalid with
  | .error "application type mismatch" => pure ()
  | _ => throw (IO.userError "source wrong argument domain was not rejected")

  -- Repeated application enters the source's separately optimized
  -- checked-application callback at >=16 arguments. Every argument has
  -- type Sort0; the body is a closed proposition of type Sort0.
  let mut manyLambda := depProp
  for _ in [:16] do
    manyLambda := .lam name sort0 manyLambda .default
  let mut manyApp := manyLambda
  for _ in [:16] do
    manyApp := .app manyApp depProp
  let (largeType, _) ← match psKernelSessionCheck 4096 source manyApp with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source long application failed: " ++ e))
  if !psKernelExprEqual largeType sort0 then
    throw (IO.userError "source long checked-app callback changed result")

  let unknown : PsKernelExpr := .app
    (.const (.str .anonymous "UnadmittedFunction") []) depProp
  match psKernelSessionCheck 4096 source unknown with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unknown application function accepted")
  match psKernelSessionCheck 0 source valid with
  | .error "kernel inference budget exhausted" => pure ()
  | _ => throw (IO.userError "source application bypassed zero fuel")
  let exhausted : PsKernelCheckerSession := {
    source with
    context := {
      source.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  match psKernelSessionCheck 4096 exhausted valid with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "source checked app bypassed depth policy")

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
    | .error _ => throw (IO.userError "source app provider genesis failed")
  let (providerType, _) ← match psKernelC0VerifiedProviderCheck genesis valid with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified source app rejected")
  if !psKernelExprEqual providerType sort0 then
    throw (IO.userError "verified source app type changed")
  let publication ← match psKernelC0VerifiedProviderPublishRoots
      genesis [valid, manyApp] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "checked app publication declined")
  let _sourceProof := psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 2 then
    throw (IO.userError "checked apps lost atomic publication")
  match psKernelC0VerifiedProviderPublishRoots genesis [valid, invalid] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "ill-typed application partially published")
  IO.println "C0_APP_SOURCE checked_vs_infer_only_type_instantiation=pass"
  IO.println "C0_APP_SOURCE long_checked_spine_and_resource_semantics=pass"
  IO.println "C0_APP_SOURCE verified_source_publication_fail_closed=pass"
