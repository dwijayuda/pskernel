import Ps.KernelCore.Architecture.Budget

def c0BudgetName (s : String) : PsKernelName := .str .anonymous s

def c0BudgetAssertQuote
    (label : String) (depth quota : Nat)
    (closure : PsKernelC0Closure)
    (expected : PsKernelExpr) : IO Unit := do
  match psKernelC0QuoteClosureMetered depth closure quota with
  | none => throw (IO.userError (label ++ ": metered readback declined"))
  | some (expr, remaining) =>
      if !psKernelExprEqual expr expected || remaining >= quota then
        throw (IO.userError (label ++ ": wrong syntax or missing quota charge"))

def main : IO Unit := do
  let v : PsKernelExpr := .lit (.nat 23)
  let x := c0BudgetName "x"
  let captured : PsKernelC0Closure := .mk (.app (.bvar 0) (.bvar 0))
    [.mk v []]
  c0BudgetAssertQuote "duplicated-capture" 64 128 captured (.app v v)
  let some (raw, remainingRaw) :=
      psKernelC0QuoteClosureMetered 64 (.mk v []) 128
    | throw (IO.userError "basic budgeted quote declined")
  if !psKernelExprEqual raw v || remainingRaw >= 128 then
    throw (IO.userError "basic budgeted quote did not charge")
  match psKernelC0QuoteClosureMetered 64 captured 1 with
  | none => pure ()
  | some _ => throw (IO.userError "duplicated capture bypassed quota")
  match psKernelC0QuoteClosureMetered 0 (.mk v []) 128 with
  | none => pure ()
  | some _ => throw (IO.userError "quote depth exhaustion bypassed")
  let neutral : PsKernelExpr := .const (c0BudgetName "f") []
  let machine : PsKernelC0Machine := {
    control := .mk neutral []
    arguments := [.mk v [], .mk v []]
  }
  match psKernelC0QuoteMachineMetered 64 128 machine with
  | none => throw (IO.userError "spine quote declined")
  | some (expr, left) =>
      let expected := .app (.app neutral v) v
      if !psKernelExprEqual expr expected || left >= 128 then
        throw (IO.userError "spine quote semantics or quota mismatch")
  match psKernelC0QuoteMachineMetered 64 2 machine with
  | none => pure ()
  | some _ => throw (IO.userError "spine reconstruction exceeded quota")
  -- Exact node charge is global across siblings, not reset per branch.
  match psKernelC0ChargeExpr (.app v v) 3 with
  | some 0 => pure ()
  | _ => throw (IO.userError "exact three-node charge changed")
  if (psKernelC0ChargeExpr (.app v v) 2).isSome then
    throw (IO.userError "wide expression reused sibling quota")
  -- Repeated captures must reserve enough capacity for both copies of
  -- their quoted values before source substitution reconstructs syntax.
  let deepValue : PsKernelExpr := .app (.app neutral v) v
  let repeated : PsKernelC0Closure :=
    .mk (.app (.bvar 0) (.bvar 0)) [.mk deepValue []]
  c0BudgetAssertQuote "wide-repeated-capture" 64 256 repeated
    (.app deepValue deepValue)
  if (psKernelC0QuoteClosureMetered 64 repeated 7).isSome then
    throw (IO.userError "repeated captured syntax bypassed expansion quota")
  let doublyNested : PsKernelC0Closure := .mk (.bvar 0)
    [.mk (.bvar 0) [.mk v []]]
  c0BudgetAssertQuote "nested-captured-environments" 64 128
    doublyNested v
  -- Binder metadata, names and sort levels remain source-exact.
  let polymorphic : PsKernelExpr :=
    .lam x (.sort (.succ .zero)) (.bvar 0) .implicit
  c0BudgetAssertQuote "binder-exact-readback" 64 128
    (.mk polymorphic []) polymorphic
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let arg : PsKernelExpr := .app
    (.lam x (.sort .zero) (.bvar 0) .default) v
  match psKernelC0ArchitectureObserveDemandMetered 4096 4096 session arg with
  | .error reason =>
      throw (IO.userError ("trusted source WHNF declined: " ++ reason))
  | .ok (observation, _) =>
      if !observation.agrees ||
          !psKernelExprEqual observation.sourceValue v then
        throw (IO.userError "metered candidate/source WHNF divergence")
  match psKernelC0ArchitectureObserveDemandMetered 4096 1 session arg with
  | .error reason =>
      throw (IO.userError ("candidate quota polluted source: " ++ reason))
  | .ok (observation, _) =>
      if observation.agrees || observation.candidateValue.isSome ||
          !psKernelExprEqual observation.sourceValue v then
        throw (IO.userError "quota failure approved or altered trusted WHNF")
  IO.println "C0_ARCHITECTURE readback_shared_quota_capture_and_spine=pass"
  IO.println "C0_ARCHITECTURE metered_candidate_source_authority=pass"
