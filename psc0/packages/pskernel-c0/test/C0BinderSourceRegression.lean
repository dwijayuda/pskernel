import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Checker.Inference.Binder

/-!
Native Lean 4.35 binder fidelity after mechanical source rule extraction.

Checks dependent Pi type formation, lambda abstraction and binding reopening,
nested source-binder range summaries, infer-only vs fully checked separation,
and the closed-root verified provider. This tests the exact source rules:
dependent child type checking still goes through the source recursive worker.
No proof or checking authority is supplied by merely constructing a Pi/lam.
-/

def main : IO Unit := do
  let binder : PsKernelName := .str .anonymous "binderParam"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let piExpr : PsKernelExpr :=
    .forallE binder sort0 sort0 .default
  let depPi : PsKernelExpr :=
    .forallE binder sort0 (.bvar 0) .default
  let identity : PsKernelExpr :=
    .lam binder sort0 (.bvar 0) .default
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault

  let (piType, _) ← match psKernelSessionCheck 4096 source piExpr with
    | .ok x => pure x
    | .error e => throw (IO.userError ("source ordinary Pi failed: " ++ e))
  let expectedPi : PsKernelExpr :=
    .sort (psKernelLevelMkIMax (.succ .zero) (.succ .zero))
  if !psKernelExprEqual piType expectedPi then
    throw (IO.userError "source Pi imax level changed")
  let (depType, _) ← match psKernelSessionCheck 4096 source depPi with
    | .ok x => pure x
    | .error e => throw (IO.userError ("dependent Pi source failed: " ++ e))
  let expectedDep : PsKernelExpr :=
    .sort (psKernelLevelMkIMax (.succ .zero) .zero)
  if !psKernelExprEqual depType expectedDep then
    throw (IO.userError "dependent Pi source type changed")
  let (idType, _) ← match psKernelSessionCheck 4096 source identity with
    | .ok x => pure x
    | .error e => throw (IO.userError ("identity lambda source failed: " ++ e))
  if !psKernelExprEqual idType piExpr then
    throw (IO.userError "lambda binder abstraction changed source type")

  -- The source checked application must still enforce argument types.
  let application : PsKernelExpr := .app identity depPi
  let (appType, _) ← match psKernelSessionCheck 4096 source application with
    | .ok x => pure x
    | .error e => throw (IO.userError ("checked identity application failed: " ++ e))
  if !psKernelExprEqual appType sort0 then
    throw (IO.userError "dependent application instantiation changed")

  -- Enter the range-summary acceleration used by deeply nested binder
  -- prefixes, preserving native Lean independent checker outcomes.
  let mut deep : PsKernelExpr := sort0
  for _ in [:18] do
    deep := .forallE binder sort0 deep .default
  let (_, _) ← match psKernelSessionCheck 4096 source deep with
    | .ok x => pure x
    | .error e => throw (IO.userError ("deep Pi binder range failed: " ++ e))
  let mut nestedLambda : PsKernelExpr := .bvar 0
  for _ in [:18] do
    nestedLambda := .lam binder sort0 nestedLambda .default
  let (_, _) ← match psKernelSessionCheck 4096 source nestedLambda with
    | .ok x => pure x
    | .error e => throw (IO.userError ("deep lambda opening failed: " ++ e))

  -- A domain containing an untrusted metavariable is invalid when fully
  -- checked, even if the application body appears syntactically simple.
  let invalidDomain : PsKernelExpr :=
    .mvar (.str .anonymous "invalidDomain")
  let badPi : PsKernelExpr :=
    .forallE binder invalidDomain sort0 .default
  let badLam : PsKernelExpr :=
    .lam binder invalidDomain (.bvar 0) .default
  for bad in [badPi, badLam] do
    match psKernelSessionCheck 4096 source bad with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "invalid dependent binder accepted")
  match psKernelSessionCheck 0 source piExpr with
  | .error "kernel inference budget exhausted" => pure ()
  | _ => throw (IO.userError "Pi binder ignored zero source fuel")
  let restricted := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
  match psKernelSessionCheck 4096 restricted identity with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "lambda bypassed source recursion-depth policy")

  -- The verified public provider must inspect both the binder domain and
  -- opened body before permitting checked-root publication.
  let policy : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      policy psKernelProviderDefault with
    | .ok x => pure x
    | .error _ => throw (IO.userError "verified binder genesis failed")
  let (piChecked, _) ← match psKernelC0VerifiedProviderCheck genesis piExpr with
    | .ok x => pure x
    | .error _ => throw (IO.userError "verified Pi check failed")
  if !psKernelExprEqual piChecked piType then
    throw (IO.userError "verified Pi source output changed")
  let (lambdaChecked, _) ← match psKernelC0VerifiedProviderCheck genesis identity with
    | .ok x => pure x
    | .error _ => throw (IO.userError "verified lambda checking failed")
  if !psKernelExprEqual lambdaChecked idType then
    throw (IO.userError "verified lambda source output changed")
  let publication ← match psKernelC0VerifiedProviderPublishRoots
      genesis [piExpr, identity] with
    | .ok x => pure x
    | .error _ => throw (IO.userError "closed Pi/lambda publication rejected")
  let _sourcePublicationProof :=
    psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 2 then
    throw (IO.userError "verified binder roots lost atomic publication")
  match psKernelC0VerifiedProviderPublishRoots genesis [piExpr, badLam] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "untyped binder entered checked publication")
  IO.println "C0_BINDER source_lambda_and_dependent_Pi=pass"
  IO.println "C0_BINDER deep_range_and_recursion_budget=pass"
  IO.println "C0_BINDER public_verified_atomic_publication=pass"
