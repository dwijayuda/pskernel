import Ps.KernelCore.Architecture.Execution

/-!
CDE-2: bounded literal Nat reduction on the candidate's delayed argument spine.

This is an observational execution step, not a typing or proof judgment. The
existing source primitive functions own both numerical semantics and numeral
size restrictions. Arguments are quoted only as needed and non-literals are
left for other candidate steps (or the authoritative source checker).

Importantly, this does not call the source WHNF oracle to decide a candidate
result. It only shares its already defined primitive arithmetic rules.
-/

/-- Reify one delayed argument and recognize a source Nat numeral. Quotation
    may fail: a failure does not authorize a kernel rejection. -/
def psKernelC0CandidateNatArgument
    (quoteFuel : Nat)
    (argument : PsKernelC0Closure) : Option Nat := do
  let expr ← psKernelC0QuoteClosure quoteFuel argument
  psKernelExprNatLiteralValue expr

/-- Resume the lazy machine after one literal primitive reduction. Excess
    application arguments remain on the operation-local spine. -/
def psKernelC0CandidateNatContinue
    (machine : PsKernelC0Machine)
    (value : PsKernelExpr)
    (remaining : List PsKernelC0Closure) : PsKernelC0MachineStep :=
  .next {
    control := .mk value []
    arguments := remaining
    steps := machine.steps + 1
  }

/-- Evaluate only primitive Nat heads with exactly the literal arguments
    needed for the operation. No speculative evaluation of neutral operands
    or unchecked declaration unfolding is performed here.

    The source helper enforces maxNatSize, count limits, and the pinned
    Lean 4.35 Nat operation definitions. A resource/size failure is a
    candidate decline; it is never converted to a logical rejection. -/
def psKernelC0CandidateNatStep
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine) : PsKernelC0MachineStep :=
  match machine.control with
  | .mk (.const name levels) _ =>
      if !levels.isEmpty then
        .halted
      else if psKernelNameEq name psKernelNatSuccName then
        match machine.arguments with
        | [] => .halted
        | arg :: remaining =>
            match psKernelC0CandidateNatArgument quoteFuel arg with
            | none => .halted
            | some value =>
                let successor := Nat.succ value
                match psKernelCheckNatSize context.maxNatSize successor with
                | .error reason => .declined reason
                | .ok _ =>
                    psKernelC0CandidateNatContinue machine
                      (.lit (.nat successor)) remaining
      else
        match machine.arguments with
        | left :: right :: remaining =>
            match psKernelC0CandidateNatArgument quoteFuel left,
                  psKernelC0CandidateNatArgument quoteFuel right with
            | some l, some r =>
                match psKernelReduceNatBinary context.maxNatSize name l r with
                | .error reason => .declined reason
                | .ok (some value) =>
                    psKernelC0CandidateNatContinue machine value remaining
                | .ok none => .halted
            | _, _ => .halted
        | _ => .halted
  | _ => .halted
