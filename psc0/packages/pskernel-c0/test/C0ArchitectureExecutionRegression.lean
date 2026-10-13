import Ps.KernelCore.Architecture.Execution

def c0ArchitectureName (name : String) : PsKernelName :=
  .str .anonymous name

def c0ArchitectureAssertWhnf
    (label : String)
    (source : PsKernelExpr)
    (expected : PsKernelExpr) : IO Unit := do
  match psKernelC0CandidateWhnf 256 source with
  | .error err =>
      throw (IO.userError (label ++ ": candidate declined: " ++ err))
  | .ok (value, _) =>
      if !psKernelExprEqual value expected then
        throw (IO.userError (label ++ ": candidate mismatch"))
  let session := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  match psKernelC0ObserveWhnf 4096 session source with
  | .error err =>
      throw (IO.userError (label ++ ": checked WHNF failed: " ++ err))
  | .ok (observation, _) =>
      if !observation.agrees ||
          !psKernelExprEqual observation.sourceValue expected then
        throw (IO.userError (label ++ ": source differential mismatch"))

def main : IO Unit := do
  let x := c0ArchitectureName "x"
  let y := c0ArchitectureName "y"
  let a := PsKernelExpr.const (c0ArchitectureName "a") []
  let b := PsKernelExpr.const (c0ArchitectureName "b") []
  let ty := PsKernelExpr.sort .zero
  let id := PsKernelExpr.lam x ty (.bvar 0) .default
  c0ArchitectureAssertWhnf "identity-beta" (.app id a) a
  c0ArchitectureAssertWhnf "nested-beta"
    (.app id (.app id a)) a
  c0ArchitectureAssertWhnf "zeta"
    (.letE x ty a (.app id (.bvar 0)) false) a
  c0ArchitectureAssertWhnf "captured-closure"
    (.app (.app (.lam x ty
      (.lam y ty (.bvar 1) .default) .default) a) b) a
  c0ArchitectureAssertWhnf "neutral-spine"
    (.app (.const (c0ArchitectureName "f") []) (.app id a))
    (.app (.const (c0ArchitectureName "f") []) (.app id a))
  c0ArchitectureAssertWhnf "lambda-value"
    (.lam x ty (.bvar 0) .default)
    (.lam x ty (.bvar 0) .default)
  c0ArchitectureAssertWhnf "metadata-whnf"
    (.mdata 7 (.app id a)) a
  match psKernelC0CandidateWhnf 0 (.app id a) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "candidate accepted exhausted fuel")
  match psKernelC0CandidateWhnf 30 (.bvar 0) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "candidate accepted unbound term")
  let session := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  match psKernelC0ArchitectureChecked 4096 session (.sort .zero) with
  | .error err =>
      throw (IO.userError ("source-checked architecture seam failed: " ++ err))
  | .ok (_, _) => pure ()
  IO.println "C0_ARCHITECTURE lazy_closure_beta_zeta_source_differential=pass"
  IO.println "C0_ARCHITECTURE checked_session_authority=pass"
