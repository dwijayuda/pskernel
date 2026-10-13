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
  -- One application and two small Nat literals charge the AST nodes
  -- plus their eight-byte source numeral storage, shared across siblings.
  match psKernelC0ChargeExpr (.app v v) 19 with
  | some 0 => pure ()
  | _ => throw (IO.userError "Nat payload and node work charge changed")
  if (psKernelC0ChargeExpr (.app v v) 18).isSome then
    throw (IO.userError "Nat payload or sibling work bypassed quota")
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
  -- UTF-8 byte storage must be charged in addition to the literal node.
  -- "é" occupies two bytes; a zero-sized String still costs one AST node.
  match psKernelC0ChargeExpr (.lit (.str "é")) 3 with
  | some 0 => pure ()
  | _ => throw (IO.userError "UTF-8 source work charge was not exact")
  if (psKernelC0ChargeExpr (.lit (.str "é")) 2).isSome then
    throw (IO.userError "UTF-8 literal bypassed shared work quota")
  match psKernelC0ChargeExpr (.lit (.str "")) 1 with
  | some 0 => pure ()
  | _ => throw (IO.userError "empty String literal node not charged")
  -- Previously machine-step charging ignored captured environments; a
  -- large delayed value could be hidden inside one cheap .bvar control.
  let capturedControl : PsKernelC0Machine := {
    control := .mk (.bvar 0) [.mk deepValue []]
  }
  if (psKernelC0ChargeMachineSyntax 32 capturedControl 3).isSome then
    throw (IO.userError "captured environment evaded work quota")
  match psKernelC0ChargeMachineSyntax 32 capturedControl 64 with
  | none => throw (IO.userError "captured syntax declined adequate quota")
  | some remaining =>
      if remaining >= 64 then
        throw (IO.userError "captured environment charged zero work")
  -- Delayed arguments and saved parent continuation frames are both
  -- part of the reachable operation state, not free resources.
  let withContinuation : PsKernelC0DemandState := {
    machine := { control := .mk v [] }
    frames := [.natLeft machine (.mk deepValue [])]
  }
  if (psKernelC0ChargeDemandStateSyntax 32 withContinuation 5).isSome then
    throw (IO.userError "saved Nat continuation was not charged")
  match psKernelC0ChargeDemandStateSyntax 32 withContinuation 128 with
  | none => throw (IO.userError "valid continuation exhausted wide quota")
  | some remaining =>
      if remaining >= 128 then
        throw (IO.userError "continuation footprint did not consume budget")
  -- Every quoted environment has a finite recursion depth as well as a
  -- shared work quota; no nested environment bypasses the depth cutoff.
  if (psKernelC0ChargeMachineSyntax 1 capturedControl 128).isSome then
    throw (IO.userError "captured closure exceeded finite depth")
  -- UTF-8 expansion reservation is charged before String.ofList
  -- syntax materialization for projection/recursor major premises.
  let stringProjectionState : PsKernelC0DemandState := {
    machine := { control := .mk (.lit (.str "é")) [] }
    frames := [
      .projection { control := .mk (.proj (c0BudgetName "T") 0
        (.lit (.str "é"))) [] } (c0BudgetName "T") 0
    ]
  }
  if psKernelC0DemandStringReserve stringProjectionState != 48 then
    throw (IO.userError "String major reservation ignored UTF-8 byte size")
  if psKernelC0DemandStringReserve withContinuation != 0 then
    throw (IO.userError "non-String demand unexpectedly reserves expansion")
  -- Source-controlled delta may allocate a definition body and app spine
  -- in one machine transition; charge its body before unfolding.
  let deltaName := c0BudgetName "BudgetDeltaAlias"
  let definition : PsKernelDefinitionInfo := {
    base := {
      name := deltaName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := deepValue
    hints := .abbrevHint
    safety := .safe
  }
  let deltaEnv := psKernelEnvironmentAddUnchecked
    psKernelEnvironmentEmpty (.defnInfo definition)
  let deltaSession := psKernelMkCheckerSession deltaEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let deltaMachine : PsKernelC0Machine := {
    control := .mk (.const deltaName []) []
  }
  if (psKernelC0ReserveDeltaSyntax deltaSession.context
      deltaMachine 2).isSome then
    throw (IO.userError "unfolding bypassed definition body reservation")
  match psKernelC0ReserveDeltaSyntax deltaSession.context
      deltaMachine 128 with
  | none => throw (IO.userError "valid delta RHS declined generous quota")
  | some left =>
      if left >= 128 then
        throw (IO.userError "delta body incurred no work charge")
  -- Recursor iota rules clone/instantiate a source rule RHS. Precharge the
  -- selected rule, but leave unmatched constructor majors observationally
  -- neutral rather than falsely classifying them as resource exhaustion.
  let ctorName := c0BudgetName "BudgetCtor"
  let recName := c0BudgetName "BudgetRecursor"
  let recursor : PsKernelRecursorInfo := {
    base := { name := recName, levelParams := [], type := .sort .zero }
    all := []
    numParams := 0
    numIndices := 0
    numMotives := 0
    numMinors := 0
    rules := [{ ctor := ctorName, nFields := 0, rhs := deepValue }]
    k := false
    isUnsafe := false
  }
  let recParent : PsKernelC0Machine := {
    control := .mk (.const recName []) []
  }
  let recState : PsKernelC0DemandState := {
    machine := { control := .mk (.const ctorName []) [] }
    frames := [.recursor recParent recursor []]
  }
  if (psKernelC0ReserveRecursorSyntax recState 2).isSome then
    throw (IO.userError "recursor RHS bypassed preflight reservation")
  match psKernelC0ReserveRecursorSyntax recState 128 with
  | none => throw (IO.userError "valid iota rule exhausted generous quota")
  | some left =>
      if left >= 128 then
        throw (IO.userError "recursor RHS incurred zero charge")
  let unknownState : PsKernelC0DemandState := {
    recState with machine := {
      control := .mk (.const (c0BudgetName "UnknownCtor") []) []
    }
  }
  match psKernelC0ReserveRecursorSyntax unknownState 10 with
  | some 10 => pure ()
  | _ => throw (IO.userError "nonmatching recursor major should stay neutral")
  -- Intermediate quotation must not reset its allowance between
  -- declaration heads, projection scrutinees and saved recursor parents.
  let quoteState : PsKernelC0DemandState := {
    machine := { control := .mk (.const deltaName []) [] }
  }
  if (psKernelC0ReserveIntermediateReadbacks 64 quoteState 1).isSome then
    throw (IO.userError "constant-head quotation bypassed quota")
  match psKernelC0ReserveIntermediateReadbacks 64 quoteState 128 with
  | none => throw (IO.userError "ample constant-head quotation declined")
  | some remaining =>
      if remaining >= 128 then
        throw (IO.userError "constant-head quotation charged zero work")
  let projected : PsKernelC0DemandState := {
    machine := { control := .mk
      (.proj (c0BudgetName "T") 0 deepValue) [] }
  }
  if (psKernelC0ReserveIntermediateReadbacks 64 projected 4).isSome then
    throw (IO.userError "projection scrutinee quotation was unmetered")
  match psKernelC0ReserveIntermediateReadbacks 64 projected 256 with
  | none => throw (IO.userError "projection quotation declined wide quota")
  | some remaining =>
      if remaining >= 256 then
        throw (IO.userError "projection quotation spent no quota")
  match psKernelC0ReserveIntermediateReadbacks 64 recState 2 with
  | none => pure ()
  | some _ =>
      throw (IO.userError "recursor parent quotation bypassed work limit")
  match psKernelC0ReserveIntermediateReadbacks 64 recState 256 with
  | none =>
      throw (IO.userError "valid recursor intermediate reification declined")
  | some remaining =>
      if remaining >= 256 then
        throw (IO.userError "recursor intermediate quotation cost missing")
  -- Exact finished syntax of each rewrite is counted, not only its input.
  let rewritten : PsKernelC0DemandState := {
    machine := { control := .mk deepValue [] }
  }
  if (psKernelC0ChargeDemandStateSyntax 64 rewritten 2).isSome then
    throw (IO.userError "newly materialized intermediate bypassed quota")
  -- Primitive computation must reserve numerical byte-work before
  -- dispatch, including potentially expanding pow and shifts.
  if (psKernelC0ReserveNatBinaryWork psKernelNatPowName 2 64 128).isSome then
    throw (IO.userError "Nat.pow growth bypassed primitive preflight")
  match psKernelC0ReserveNatBinaryWork psKernelNatPowName 2 5 4096 with
  | none => throw (IO.userError "small Nat.pow preflight declined")
  | some left =>
      if left >= 4096 then
        throw (IO.userError "Nat.pow preflight spent zero work")
  if (psKernelC0ReserveNatBinaryWork
      psKernelNatShiftLeftName 3 200 64).isSome then
    throw (IO.userError "Nat.shiftLeft bypassed count work cap")
  match psKernelC0ReserveNatBinaryWork
      psKernelNatAddName 20 30 128 with
  | none => throw (IO.userError "small Nat.add arithmetic declined")
  | some left =>
      if left >= 128 then
        throw (IO.userError "Nat.add arithmetic spent no work")
  match psKernelC0ReserveNatBinaryWork
      (c0BudgetName "Unrelated") 20 30 11 with
  | some 11 => pure ()
  | _ => throw (IO.userError "unknown primitive incurred inferred work")
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let arg : PsKernelExpr := .app
    (.lam x (.sort .zero) (.bvar 0) .default) v
  match psKernelC0DemandRunWithBudget 128 128 32
      session.context stringProjectionState with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "String expansion bypassed preallocation guard")
  match psKernelC0ArchitectureObserveDemandMetered 4096 4096 session arg with
  | .error reason =>
      throw (IO.userError ("trusted source WHNF declined: " ++ reason))
  | .ok (observation, _) =>
      if !observation.agrees ||
          !psKernelExprEqual observation.sourceValue v then
        throw (IO.userError "metered candidate/source WHNF divergence")
  -- One quota is shared between visits to demand-machine syntax and
  -- the final quotation, not reset for each transition.
  let initial : PsKernelC0DemandState := {
    machine := { control := .mk arg [] }
  }
  match psKernelC0DemandRunWithBudget 4096 4096 4096
      session.context initial with
  | .error reason =>
      throw (IO.userError ("metered demand loop unexpectedly declined: " ++ reason))
  | .ok (finished, left) =>
      if finished.steps == 0 || left >= 4096 then
        throw (IO.userError "demand transition did not consume quota")
  match psKernelC0DemandRunWithBudget 4096 4096 2
      session.context initial with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "demand traversal used fresh work quota")
  match psKernelC0ArchitectureObserveDemandMetered 4096 1 session arg with
  | .error reason =>
      throw (IO.userError ("candidate quota polluted source: " ++ reason))
  | .ok (observation, _) =>
      if observation.agrees || observation.candidateValue.isSome ||
          !psKernelExprEqual observation.sourceValue v then
        throw (IO.userError "quota failure approved or altered trusted WHNF")
  IO.println "C0_ARCHITECTURE readback_shared_quota_capture_and_spine=pass"
  IO.println "C0_ARCHITECTURE metered_candidate_source_authority=pass"
