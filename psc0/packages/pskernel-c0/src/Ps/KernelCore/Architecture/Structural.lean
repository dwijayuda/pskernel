import Ps.KernelCore.Architecture.Delta

/-!
CDE-3: local-let and constructor-headed projection execution.

This candidate-only layer extends the same closure/spine machine; it does not
create a second independent accepting checker. Source local-context lookup
decides which fvars are local lets. The source's constructor projection helper
decides the exact field selector, including structure name and parameter offset.

Deliberately bounded: an unevaluated projection scrutinee is not recursively
forced here; it remains stuck, with source WHNF comparison detecting any
missing reduction. Recursor and quotient semantics remain future work.
-/

/-- Work-local context lookup respects the authoritative newest-first source
    local context and does not reinterpret opaque local hypotheses as lets. -/
def psKernelC0ArchitectureLocalStep
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine) : PsKernelC0MachineStep :=
  match machine.control with
  | .mk (.fvar name) _ =>
      match psKernelLocalContextFind context.localContext name with
      | some decl =>
          match psKernelLocalDeclValue decl with
          | some value =>
              .next {
                control := .mk value []
                arguments := machine.arguments
                steps := machine.steps + 1
              }
          | none => .halted
      | none => .halted
  | _ => .halted

/-- Only constructor-headed projections are reduced by the candidate. The
    exact source store/metadata lookup and parameter-offset field selection
    are reused; no constructor-name heuristic can synthesize a field. -/
def psKernelC0ArchitectureProjectionStep
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine) : PsKernelC0MachineStep :=
  match machine.control with
  | .mk (.proj typeName fieldIndex structValue) env =>
      match psKernelC0QuoteClosure quoteFuel (.mk structValue env) with
      | none => .declined "candidate projection quotation budget exhausted"
      | some exact =>
          match psKernelReduceProjCore context typeName fieldIndex exact with
          | none => .halted
          | some result =>
              .next {
                control := .mk result []
                arguments := machine.arguments
                steps := machine.steps + 1
              }
  | _ => .halted

/-- The single candidate step dispatcher preserves β/ζ and source-primitive
    ordering. A neutral or unresolved form remains non-accepting, rather
    than invoking the source checker to manufacture a candidate result. -/
def psKernelC0ArchitectureStructuralStep
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine) : PsKernelC0MachineStep :=
  match psKernelC0ArchitectureDeltaStep quoteFuel context machine with
  | .next next => .next next
  | .declined reason => .declined reason
  | .halted =>
      match psKernelC0ArchitectureLocalStep context machine with
      | .next next => .next next
      | .declined reason => .declined reason
      | .halted =>
          psKernelC0ArchitectureProjectionStep quoteFuel context machine

/-- The same monotone operation-local step budget is applied to β/ζ,
    δ/Nat, local-let and projection transitions. Readback has a separate
    explicit structural budget. No candidate result is an admission verdict. -/
def psKernelC0ArchitectureRunStructural :
    Nat → Nat → PsKernelCheckerContext → PsKernelC0Machine →
    Except String PsKernelC0Machine
  | 0, _, _, _ => .error "candidate structural execution budget exhausted"
  | fuel + 1, quoteFuel, context, machine =>
      match psKernelC0ArchitectureStructuralStep quoteFuel context machine with
      | .next next =>
          psKernelC0ArchitectureRunStructural fuel quoteFuel context next
      | .halted => .ok machine
      | .declined reason => .error reason

def psKernelC0ArchitectureCandidateStructural
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × Nat) := do
  let final ← psKernelC0ArchitectureRunStructural fuel fuel context
    { control := .mk expr [] }
  let some result := psKernelC0QuoteMachine fuel final
    | throw "candidate structural readback budget exhausted"
  return (result, final.steps)

/-- Source WHNF is computed independently and first. The candidate's output,
    disagreement, or resource decline never enters source checker state. -/
def psKernelC0ArchitectureObserveStructural
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelCheckerSession) := do
  let (source, checkedSession) ← psKernelSessionWhnf fuel session expr
  let observation : PsKernelC0ExecutionObservation :=
    match psKernelC0ArchitectureCandidateStructural fuel session.context expr with
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
