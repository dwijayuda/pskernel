import Ps.KernelCore.Architecture.NatLiteral

/-!
CDE-1/2: environment-aware candidate delta and primitive Nat evaluation.

The pure closure machine remains separate. This *non-accepting* layer uses the
source checker's own delta-unfolding function for one fully reified stuck
constant application, then returns to the lazy closure/spine machine. It does
not synthesize new reducibility rules, mutate a checked session or authorize
admission. Unsafe/partial definitions are explicitly declined.
-/

/-- Diagnostics and resource limits are separate from the kernel's typed
    rejection/acceptance contract. -/
/-- Source-policy delta on one exact, reified constant application. -/
def psKernelC0ArchitectureDefinitionStep
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine) : PsKernelC0MachineStep :=
  match machine.control with
  | .mk (.const name _) _ =>
      match psKernelEnvironmentFind context.environment name with
      | some declaration =>
          if psKernelConstantInfoIsUnsafe declaration ||
              psKernelConstantInfoIsPartial declaration then
            .declined "candidate unsafe or partial delta definition"
          else
            match psKernelC0QuoteMachine quoteFuel machine with
            | none => .declined "candidate delta quotation budget exhausted"
            | some exact =>
                match psKernelUnfoldDefinition context exact with
                | none => .halted
                | some unfolded =>
                    if psKernelExprEqual exact unfolded then
                      .declined "candidate unchanged delta unfolding"
                    else
                      .next {
                        control := .mk unfolded []
                        arguments := []
                        steps := machine.steps + 1
                      }
      | none => .halted
  | _ => .halted


/-- Candidate reduction order follows source WHNF: try literal Nat
    primitives before unfolding ordinary definitions. All candidate
    results remain outside the checked admission boundary. -/
def psKernelC0ArchitectureDeltaStep
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine) : PsKernelC0MachineStep :=
  match psKernelC0MachineStep machine with
  | .next next => .next next
  | .declined reason => .declined reason
  | .halted =>
      match psKernelC0CandidateNatStep quoteFuel context machine with
      | .next next => .next next
      | .declined reason => .declined reason
      | .halted =>
          psKernelC0ArchitectureDefinitionStep quoteFuel context machine

/-- Fuel is charged for each syntactic and delta step. Quotation has its own
    explicit structural budget and cannot affect the checked source verdict. -/
def psKernelC0ArchitectureRunDelta :
    Nat → Nat → PsKernelCheckerContext → PsKernelC0Machine →
    Except String PsKernelC0Machine
  | 0, _, _, _ => .error "candidate delta execution budget exhausted"
  | fuel + 1, quoteFuel, context, machine =>
      match psKernelC0ArchitectureDeltaStep quoteFuel context machine with
      | .next next =>
          psKernelC0ArchitectureRunDelta fuel quoteFuel context next
      | .halted => .ok machine
      | .declined reason => .error reason

/-- The closure readback is capture-avoiding and the delta expansion is the
    existing source operation. Neither grants a proof judgment. -/
def psKernelC0ArchitectureCandidateDelta
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × Nat) := do
  let final ← psKernelC0ArchitectureRunDelta fuel fuel context
    { control := .mk expr [] }
  let some result := psKernelC0QuoteMachine fuel final
    | throw "candidate delta readback budget exhausted"
  return (result, final.steps)

/-- Compare one whole source WHNF with the candidate; a disagreement or
    decline is observed but never used to approve a type or declaration. -/
def psKernelC0ArchitectureObserveDelta
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelCheckerSession) := do
  let (source, checkedSession) ← psKernelSessionWhnf fuel session expr
  let observation : PsKernelC0ExecutionObservation :=
    match psKernelC0ArchitectureCandidateDelta fuel session.context expr with
    | .ok (candidate, steps) =>
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
