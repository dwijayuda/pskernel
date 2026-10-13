import Ps.KernelCore.Architecture.Demand

/-!
CDE-8A foundation: conservative, operation-scoped candidate readback.

Unlike depth-only quotation, the remaining work quota is threaded through
head, captured closures and application arguments. Every source node is
counted under a shared bound. Before instantiating a closure, we reserve a
conservative expansion bound based on the source node count and the total
size of the fully quoted substitutions, so duplication cannot bypass the
quota. These are *candidate* limits, not kernel typing/acceptance decisions.

Demand-step source-syntax traversal and final quotation now consume one
quota. Intermediate primitive/delta/projection/recursor allocation remains
outside complete accounting; this is a bounded *candidate work* foundation,
not the final allocation/refinement contract.
-/

/-- Consume one unit per visited expression node, traversing immediate
    children with one monotonically decreasing quota. None means exhausted.
    The expression recursion is structural; no unchecked node count prepass. -/
def psKernelC0ChargeExpr
    (expr : PsKernelExpr) (quota : Nat) : Option Nat :=
  match quota with
  | 0 => none
  | remaining + 1 =>
      match expr with
      | .app fn arg => do
          let left ← psKernelC0ChargeExpr fn remaining
          psKernelC0ChargeExpr arg left
      | .lam _ ty body _ => do
          let left ← psKernelC0ChargeExpr ty remaining
          psKernelC0ChargeExpr body left
      | .forallE _ ty body _ => do
          let left ← psKernelC0ChargeExpr ty remaining
          psKernelC0ChargeExpr body left
      | .letE _ ty value body _ => do
          let afterTy ← psKernelC0ChargeExpr ty remaining
          let afterValue ← psKernelC0ChargeExpr value afterTy
          psKernelC0ChargeExpr body afterValue
      | .mdata _ body => psKernelC0ChargeExpr body remaining
      | .proj _ _ struct => psKernelC0ChargeExpr struct remaining
      | _ => some remaining

/-- A conservative quota is also charged for *possible* binder-occurrence
    substitution duplication before invoking source capture-avoiding
    instantiation. Unused captured values may cost extra quota; this is
    safe for a non-accepting optional evaluator and is not a semantic reject. -/
def psKernelC0QuoteClosureMetered :
    Nat → PsKernelC0Closure → Nat → Option (PsKernelExpr × Nat)
  | 0, _, _ => none
  | depth + 1, .mk expr env, quota => do
      let afterRaw ← psKernelC0ChargeExpr expr quota
      let sourceNodes := quota - afterRaw
      let (quotedRev, afterEnv, envNodes) ←
        env.foldlM
          (fun (acc : List PsKernelExpr × Nat × Nat) closure => do
            let (value, next) ←
              psKernelC0QuoteClosureMetered depth closure acc.2.1
            -- Counting the quoted substitution twice is deliberate:
            -- once for its own readback and once for the expansion bound.
            let counted ← psKernelC0ChargeExpr value next
            let added := next - counted
            some (value :: acc.1, counted, acc.2.2 + added))
          ([], afterRaw, 0)
      let reserve := sourceNodes * (envNodes + 1)
      if reserve > afterEnv then none
      else
        let result := psKernelExprInstantiate expr quotedRev.reverse
        some (result, afterEnv - reserve)

/-- The whole quoted head, delayed arguments and reconstructed spine share
    one budget. The final application nodes are reserved *before* building
    them, preventing an unchecked spine-growth success. -/
def psKernelC0QuoteMachineMetered
    (depth quota : Nat)
    (machine : PsKernelC0Machine) : Option (PsKernelExpr × Nat) := do
  let (head, afterHead) ←
    psKernelC0QuoteClosureMetered depth machine.control quota
  let (reversed, afterArgs) ←
    machine.arguments.foldlM
      (fun (acc : List PsKernelExpr × Nat) arg => do
        let (value, left) ←
          psKernelC0QuoteClosureMetered depth arg acc.2
        some (value :: acc.1, left))
      ([], afterHead)
  if machine.arguments.length > afterArgs then none
  else
    let result := psKernelExprApplyArgsCheap head reversed.reverse
    some (result, afterArgs - machine.arguments.length)

/-- Charge the active syntactic control and the stored argument spine.
    Each transition reuses one operation quota. This is a conservative
    work-footprint allowance, NOT a complete accounting of temporary
    reconstructions inside the unchanged source-rule callbacks. -/
def psKernelC0ChargeMachineSyntax
    (machine : PsKernelC0Machine) (quota : Nat) : Option Nat := do
  let (.mk expr _) := machine.control
  let left ← psKernelC0ChargeExpr expr quota
  machine.arguments.foldlM
    (fun remaining closure =>
      match closure with
      | .mk argument _ => psKernelC0ChargeExpr argument remaining)
    left

/-- One transition loop and one remaining quota. This delegates *all*
    reduction rules to the existing demand dispatcher and therefore cannot
    introduce separate candidate reduction semantics. -/
def psKernelC0DemandRunWithBudget :
    Nat → Nat → Nat → PsKernelCheckerContext → PsKernelC0DemandState →
      Except String (PsKernelC0DemandState × Nat)
  | 0, _, _, _, _ =>
      .error "candidate shared-demand transition budget exhausted"
  | fuel + 1, depth, quota, context, state => do
      let some rest := psKernelC0ChargeMachineSyntax state.machine quota
        | throw "candidate shared syntactic-work quota exhausted"
      match psKernelC0DemandTransition depth context state with
      | .next next =>
          psKernelC0DemandRunWithBudget fuel depth rest context next
      | .halted => return (state, rest)
      | .declined reason => throw reason

/-- Non-accepting, explicit-quota candidate bridge. The existing demand
    execution still owns its independent transition budget; this new API
    qualifies the *readback* resource scope only. -/
def psKernelC0ArchitectureCandidateDemandMetered
    (fuel quoteQuota : Nat)
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) : Except String (PsKernelExpr × Nat × Nat) := do
  let (final, afterSteps) ←
    psKernelC0DemandRunWithBudget fuel fuel quoteQuota context
      { machine := { control := .mk expr [] } }
  match psKernelC0QuoteMachineMetered fuel afterSteps final.machine with
  | some (value, remaining) =>
      return (value, final.steps, remaining)
  | none =>
      throw "candidate shared readback quota exhausted"

/-- Source authority is unchanged, even if an opt-in metered candidate
    declines due to its stricter-than-source resource policy. -/
def psKernelC0ArchitectureObserveDemandMetered
    (fuel quoteQuota : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelCheckerSession) := do
  let (source, checkedSession) ← psKernelSessionWhnf fuel session expr
  let observation : PsKernelC0ExecutionObservation :=
    match psKernelC0ArchitectureCandidateDemandMetered
        fuel quoteQuota session.context expr with
    | .ok (candidate, steps, _) =>
        { sourceValue := source
          candidateValue := some candidate
          agrees := psKernelExprEqual source candidate
          candidateSteps := steps }
    | .error _ =>
        { sourceValue := source
          candidateValue := none
          agrees := false
          candidateSteps := 0 }
  return (observation, checkedSession)
