import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Core.Substitution.Instantiate

/-!
Architecture-first C–D–E candidate execution substrate.

This source deliberately does not replace the accepting checker. The
independent recursive source-owned checker still decides type judgments and
admission. A candidate result is only an observation and must never issue
proof receipts or modify the accepted environment.

This first coherent foundation models beta/zeta/metadata WHNF using delayed
environments and a separate argument spine, instead of rebuilding each
application spine at every beta reduction. Delta, projections, primitive
operations, recursors, quotient, and context-sensitive reductions remain
unimplemented here; these will be added as complete qualified families.
-/

/-- A call-by-name term with a delayed environment of surrounding binders. -/
inductive PsKernelC0Closure where
  | mk (term : PsKernelExpr) (substitutions : List PsKernelC0Closure)

/-- Explicit machine: pending arguments are ordered left-to-right when the
    head is reached. This state is operation-local, not a cache or verdict. -/
structure PsKernelC0Machine where
  control : PsKernelC0Closure
  arguments : List PsKernelC0Closure := []
  steps : Nat := 0

inductive PsKernelC0MachineStep where
  | next (state : PsKernelC0Machine)
  | halted
  | declined (reason : String)

/-- A single syntactic transition. No environment-dependent delta or iota
    step is guessed by this pure, untrusted candidate machine. -/
def psKernelC0MachineStep (state : PsKernelC0Machine) :
    PsKernelC0MachineStep :=
  match state.control with
  | .mk expr env =>
      let count := state.steps + 1
      match expr with
      | .app fn arg =>
          .next {
            control := .mk fn env
            arguments := .mk arg env :: state.arguments
            steps := count
          }
      | .letE _ _ value body _ =>
          .next {
            control := .mk body (.mk value env :: env)
            arguments := state.arguments
            steps := count
          }
      | .mdata _ body =>
          .next {
            control := .mk body env
            arguments := state.arguments
            steps := count
          }
      | .bvar index =>
          match env[index]? with
          | some closure =>
              .next {
                control := closure
                arguments := state.arguments
                steps := count
              }
          | none => .declined "unbound candidate de Bruijn reference"
      | .lam _ _ body _ =>
          match state.arguments with
          | arg :: rest =>
              .next {
                control := .mk body (arg :: env)
                arguments := rest
                steps := count
              }
          | [] => .halted
      | _ => .halted

/-- Resource failure is a candidate-only decline, never a kernel rejection. -/
def psKernelC0MachineRun : Nat → PsKernelC0Machine →
    Except String PsKernelC0Machine
  | 0, _ => .error "candidate execution budget exhausted"
  | fuel + 1, state =>
      match psKernelC0MachineStep state with
      | .next next => psKernelC0MachineRun fuel next
      | .halted => .ok state
      | .declined reason => .error reason

/-- Read back a delayed closure by capture-avoiding source substitution.
    This is a separately resource-bounded bridge for differential tests; it
    does not certify a typed term or change the checked source environment. -/
def psKernelC0QuoteClosure : Nat → PsKernelC0Closure →
    Option PsKernelExpr
  | 0, _ => none
  | fuel + 1, .mk expr env => do
      let substituted ← env.mapM (psKernelC0QuoteClosure fuel)
      some (psKernelExprInstantiate expr substituted)

/-- Reconstitute only the weak-head result. Neutral arguments remain delayed
    until the readback boundary, not eagerly evaluated as runtime values. -/
def psKernelC0QuoteMachine
    (fuel : Nat)
    (machine : PsKernelC0Machine) : Option PsKernelExpr := do
  let head ← psKernelC0QuoteClosure fuel machine.control
  let args ← machine.arguments.mapM (psKernelC0QuoteClosure fuel)
  some (psKernelExprApplyArgsCheap head args)

def psKernelC0CandidateWhnf
    (fuel : Nat)
    (expr : PsKernelExpr) : Except String (PsKernelExpr × Nat) := do
  let machine ← psKernelC0MachineRun fuel
    { control := .mk expr [] }
  match psKernelC0QuoteMachine fuel machine with
  | some value => .ok (value, machine.steps)
  | none => .error "candidate quotation budget exhausted"

/-- Observe candidate and source judgments independently. Both a candidate
    decline and a disagreement are recorded, never used as acceptance. -/
structure PsKernelC0ExecutionObservation where
  sourceValue : PsKernelExpr
  candidateValue : Option PsKernelExpr
  agrees : Bool
  candidateSteps : Nat

/-- The source WHNF runs first, and owns the sole checked observation. -/
def psKernelC0ObserveWhnf
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelCheckerSession) := do
  let (source, nextSession) ← psKernelSessionWhnf fuel session expr
  let candidate := psKernelC0CandidateWhnf fuel expr
  let observation :=
    match candidate with
    | .ok (result, steps) =>
        { sourceValue := source
          candidateValue := some result
          agrees := psKernelExprEqual source result
          candidateSteps := steps : PsKernelC0ExecutionObservation }
    | .error _ =>
        { sourceValue := source
          candidateValue := none
          agrees := false
          candidateSteps := 0 : PsKernelC0ExecutionObservation }
  return (observation, nextSession)

/-- Phase E's explicit checked boundary: no experimental evaluator result is
    an argument, and a failed check never produces a checked session result.
    This remains the only path from architecture experiments to a judgment. -/
def psKernelC0ArchitectureChecked
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelCheckerSession) :=
  psKernelSessionCheck fuel session expr
