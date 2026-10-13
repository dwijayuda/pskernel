import Ps.KernelCore.Architecture.Work

def main : IO Unit := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some initial := psKernelC0ArchitectureBegin checker
    | throw (IO.userError "C0 architecture refused valid empty store")
  let x := PsKernelName.str .anonymous "x"
  let a := PsKernelExpr.const (.str .anonymous "a") []
  let id := PsKernelExpr.lam x (.sort .zero) (.bvar 0) .default
  let first := PsKernelExpr.app id a
  let some staged := psKernelC0ArchitectureStage initial first
    | throw (IO.userError "C0 architecture could not stage first syntax")
  let some repeated := psKernelC0ArchitectureStage staged first
    | throw (IO.userError "C0 architecture could not stage repeated syntax")
  if !psKernelC0ArchitectureWorkValid repeated then
    throw (IO.userError "C0 staged work failed full store replay")
  match psKernelC0ArchitecturePreview 4096 repeated first with
  | .ok (observation, _) =>
      if !observation.agrees || !psKernelExprEqual observation.sourceValue a then
        throw (IO.userError "C0 architecture preview was not source-owned")
  | .error err => throw (IO.userError ("C0 architecture preview failed: " ++ err))
  let some (committed, roots) := psKernelC0ArchitectureCommitSyntax repeated
    | throw (IO.userError "C0 architecture declined valid promotion")
  if !psKernelC0ReplayValidateStore committed ||
      roots.length != 2 ||
      !roots.all (psKernelExprEqual first) then
    throw (IO.userError "C0 architecture lost duplicate roots or canonical syntax")
  if (psKernelC0ArchitectureAbort repeated).nodes.size !=
      psKernelC0StoreEmpty.nodes.size then
    throw (IO.userError "C0 architecture abort changed persistent prefix")
  let forged := { repeated with stagedRoots := [committed.nodes.size + 10] }
  if (psKernelC0ArchitectureCommitSyntax forged).isSome then
    throw (IO.userError "C0 architecture accepted foreign root handle")
  let some untyped := psKernelC0ArchitectureStage initial (.bvar 0)
    | throw (IO.userError "C0 syntax arena should not decide typing")
  if (psKernelC0ArchitectureCommitSyntax untyped).isNone then
    throw (IO.userError "C0 syntax stage incorrectly made a typing decision")
  match psKernelC0ArchitectureCheckWork 4096 untyped (.bvar 0) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "C0 source checker approved an unbound variable")
  match psKernelC0ArchitectureCheckWork 4096 initial (.sort .zero) with
  | .error err =>
      throw (IO.userError ("C0 source-authoritative check failed: " ++ err))
  | .ok (_, work) =>
      if !psKernelC0ArchitectureWorkValid work then
        throw (IO.userError "C0 checked transaction became invalid")
  IO.println "C0_ARCHITECTURE validated_scratch_transaction=pass"
  IO.println "C0_ARCHITECTURE candidate_does_not_authorize_admission=pass"
