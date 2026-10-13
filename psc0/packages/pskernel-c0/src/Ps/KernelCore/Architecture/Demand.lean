import Ps.KernelCore.Architecture.Structural

/-!
CDE-4/5/6: fuel-accounted Nat, projection, Quot and recursor demand.

This small-step machine evaluates the major premise of a projection and the
necessary operands of a recognized Nat primitive without borrowing the source
checker's recursive WHNF or allocating independent fuel allowances. Nested
evaluation uses continuation frames, so one structurally recursive fuel loop
bounds *every* transition, including entering and resuming a premise.

Every result is an observation. The authoritative checker continues to
compute typing, WHNF, definitional equality and declaration admission.
Ordinary non-K recursors over constructor-headed or Nat literal majors use
the source's recursor rule metadata; quotient demand follows source arities.
K-reduction, structure eta and String-literal constructor expansion remain
outside the candidate scope.
-/

/-- A saved parent expression is preserved verbatim when a demanded operand
    does not permit a primitive or projection reduction. No speculative
    normalization of a stuck application is published. -/
inductive PsKernelC0DemandFrame where
  | natSucc (parent : PsKernelC0Machine)
  | natLeft (parent : PsKernelC0Machine) (right : PsKernelC0Closure)
  | natRight (parent : PsKernelC0Machine) (left : Nat)
  | projection (parent : PsKernelC0Machine)
      (typeName : PsKernelName) (fieldIndex : Nat)
  | quotient (parent : PsKernelC0Machine) (majorIndex : Nat)
  | recursor (parent : PsKernelC0Machine)
      (metadata : PsKernelRecursorInfo) (levels : List PsKernelLevel)

structure PsKernelC0DemandState where
  machine : PsKernelC0Machine
  frames : List PsKernelC0DemandFrame := []
  blocked : Bool := false
  steps : Nat := 0

inductive PsKernelC0DemandStep where
  | next (state : PsKernelC0DemandState)
  | halted
  | declined (reason : String)

/-- Every nested premise starts with its own empty argument spine but shares
    the enclosing operation's fuel loop and continuation stack. -/
def psKernelC0DemandEnter
    (state : PsKernelC0DemandState)
    (premise : PsKernelC0Closure)
    (frame : PsKernelC0DemandFrame) : PsKernelC0DemandStep :=
  .next {
    machine := { control := premise }
    frames := frame :: state.frames
    blocked := false
    steps := state.steps + 1
  }

/-- Restore a stuck parent exactly, without rewriting its argument syntax. -/
def psKernelC0DemandStuck
    (state : PsKernelC0DemandState)
    (parent : PsKernelC0Machine)
    (remaining : List PsKernelC0DemandFrame) : PsKernelC0DemandStep :=
  .next {
    machine := parent
    frames := remaining
    blocked := true
    steps := state.steps + 1
  }

/-- Resume the saved argument spine after a successful primitive or
    constructor-field reduction. -/
def psKernelC0DemandValue
    (state : PsKernelC0DemandState)
    (parent : PsKernelC0Machine)
    (result : PsKernelExpr)
    (arguments : List PsKernelC0Closure)
    (remaining : List PsKernelC0DemandFrame) : PsKernelC0DemandStep :=
  .next {
    machine := {
      control := .mk result []
      arguments := arguments
      steps := parent.steps + 1
    }
    frames := remaining
    blocked := false
    steps := state.steps + 1
  }

/-- Enter a relevant premise only after the simple lazy, δ and primitive
    steps have halted. Unrecognized heads never quote their arguments. -/
def psKernelC0DemandStart
    (context : PsKernelCheckerContext)
    (state : PsKernelC0DemandState) :
    Option PsKernelC0DemandStep :=
  match state.machine.control with
  | .mk (.proj typeName fieldIndex structValue) env =>
      some (psKernelC0DemandEnter state (.mk structValue env)
        (.projection state.machine typeName fieldIndex))
  | .mk (.const name levels) _ =>
      -- Classify environment-dependent eliminators before the Nat-only
      -- empty-universe check: both Quot and polymorphic recursors have
      -- genuine level instantiations.
      if context.environment.quotInitialized &&
          (psKernelNameEq name psKernelQuotLiftName ||
            psKernelNameEq name psKernelQuotIndName) then
        let majorIndex :=
          if psKernelNameEq name psKernelQuotLiftName then 5 else 4
        match state.machine.arguments[majorIndex]? with
        | some major =>
            some (psKernelC0DemandEnter state major
              (.quotient state.machine majorIndex))
        | none => none
      else
        match psKernelEnvironmentFind context.environment name with
        | some (.recInfo recursor) =>
            if recursor.k || recursor.isUnsafe ||
                recursor.base.levelParams.length != levels.length then
              none
            else
              let majorIndex :=
                recursor.numParams + recursor.numMotives +
                  recursor.numMinors + recursor.numIndices
              match state.machine.arguments[majorIndex]? with
              | some major =>
                  some (psKernelC0DemandEnter state major
                    (.recursor state.machine recursor levels))
              | none => none
        | _ =>
            if !levels.isEmpty then none
            else if psKernelNameEq name psKernelNatSuccName then
              match state.machine.arguments with
              | arg :: _ =>
                  some (psKernelC0DemandEnter state arg
                    (.natSucc state.machine))
              | [] => none
            else if psKernelC0CandidateIsNatBinary name then
              match state.machine.arguments with
              | left :: right :: _ =>
                  some (psKernelC0DemandEnter state left
                    (.natLeft state.machine right))
              | _ => none
            else none
  | _ => none

/-- Source-aligned literal-to-constructor view used only for ordinary
    recursor pattern selection. Full String literal expansion is deferred. -/
def psKernelC0RecursorMajorConstructor
    (major : PsKernelExpr) : Option PsKernelExpr :=
  match major with
  | .lit (.nat 0) =>
      some (.const psKernelNatZeroName [])
  | .lit (.nat (n + 1)) =>
      some (.app (.const psKernelNatSuccName []) (.lit (.nat n)))
  | .lit (.str _) => none
  | _ => some major

/-- Build the source recursor's exact rule application using one reified
    parent spine, selected constructor fields and source universe instantiation.
    This is a candidate rewrite only; no type/DefEq decision is inferred. -/
def psKernelC0RecursorRewrite
    (quoteFuel : Nat)
    (parent : PsKernelC0Machine)
    (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel)
    (normalizedMajor : PsKernelExpr) : Option PsKernelExpr := do
  if recursor.k || recursor.isUnsafe then none
  else if recursor.base.levelParams.length != levels.length then none
  else do
    let major ← psKernelC0RecursorMajorConstructor normalizedMajor
    let head := psKernelExprGetAppFn major
    let ctorName ← match head with
      | .const name _ => some name
      | _ => none
    let rule ← psKernelFindRecursorRule ctorName recursor.rules
    let majorArgs := psKernelExprGetAppArgs major
    if rule.nFields > majorArgs.length then none
    else do
      let quotedParent ← psKernelC0QuoteMachine quoteFuel parent
      let args := psKernelExprGetAppArgs quotedParent
      let fixedCount := recursor.numParams + recursor.numMotives +
        recursor.numMinors
      let majorIndex := fixedCount + recursor.numIndices
      if args.length <= majorIndex then none
      else
        let rhs0 := psKernelExprInstantiateLevelParams
          rule.rhs recursor.base.levelParams levels
        let rhs1 := psKernelExprApplyArgsCheap rhs0 (args.take fixedCount)
        let ctorParams := majorArgs.length - rule.nFields
        let rhs2 := psKernelExprApplyArgsCheap rhs1
          ((majorArgs.drop ctorParams).take rule.nFields)
        some (psKernelExprApplyArgsCheap rhs2
          (args.drop (majorIndex + 1)))

/-- Demand frames only consult a value returned from the *same* candidate
    evaluator. Arithmetic and constructor selection reuse the source's
    existing primitive rules but not its trusted WHNF judgment. -/
def psKernelC0DemandResume
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelC0DemandState)
    (frame : PsKernelC0DemandFrame)
    (remaining : List PsKernelC0DemandFrame) : PsKernelC0DemandStep :=
  match psKernelC0QuoteMachine quoteFuel state.machine with
  | none => .declined "candidate demanded-value quotation budget exhausted"
  | some reduced =>
      match frame with
      | .natSucc parent =>
          match psKernelExprNatLiteralValue reduced, parent.arguments with
          | some value, _ :: rest =>
              let next := Nat.succ value
              match psKernelCheckNatSize context.maxNatSize next with
              | .ok _ =>
                  psKernelC0DemandValue state parent (.lit (.nat next))
                    rest remaining
              | .error reason => .declined reason
          | _, _ => psKernelC0DemandStuck state parent remaining
      | .natLeft parent right =>
          match psKernelExprNatLiteralValue reduced with
          | none => psKernelC0DemandStuck state parent remaining
          | some left =>
              psKernelC0DemandEnter
                { state with frames := remaining } right (.natRight parent left)
      | .natRight parent left =>
          match psKernelExprNatLiteralValue reduced, parent.control,
                parent.arguments with
          | some right, .mk (.const name _) _, _ :: _ :: rest =>
              match psKernelReduceNatBinary context.maxNatSize name left right with
              | .error reason => .declined reason
              | .ok (some result) =>
                  psKernelC0DemandValue state parent result rest remaining
              | .ok none => psKernelC0DemandStuck state parent remaining
          | _, _, _ => psKernelC0DemandStuck state parent remaining
      | .projection parent typeName fieldIndex =>
          match psKernelReduceProjCore context typeName fieldIndex reduced with
          | some result =>
              psKernelC0DemandValue state parent result parent.arguments remaining
          | none => psKernelC0DemandStuck state parent remaining
      | .quotient parent majorIndex =>
          -- Reuse the source's exact Quot.mk arity and representative index.
          -- An invalid/unfinished major remains unchanged.
          if psKernelExprGetAppNumArgs reduced != 3 then
            psKernelC0DemandStuck state parent remaining
          else
            match psKernelExprGetAppFn reduced with
            | .const mkName _ =>
                if !psKernelNameEq mkName psKernelQuotMkName then
                  psKernelC0DemandStuck state parent remaining
                else
                  match (psKernelExprGetAppArgs reduced)[2]?,
                      parent.arguments[3]? with
                  | some representative, some functionClosure =>
                      match psKernelC0QuoteClosure quoteFuel functionClosure with
                      | none =>
                          .declined "candidate quotient function quotation budget exhausted"
                      | some functionValue =>
                          psKernelC0DemandValue state parent
                            (.app functionValue representative)
                            (parent.arguments.drop (majorIndex + 1))
                            remaining
                  | _, _ => psKernelC0DemandStuck state parent remaining
            | _ => psKernelC0DemandStuck state parent remaining
      | .recursor parent recursor levels =>
          match psKernelC0RecursorRewrite quoteFuel parent recursor
              levels reduced with
          | some result =>
              psKernelC0DemandValue state parent result [] remaining
          | none => psKernelC0DemandStuck state parent remaining

/-- One total transition. 'blocked' means the finished subexpression must
    return to its saved caller rather than retrying an already failed head. -/
def psKernelC0DemandTransition
    (quoteFuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelC0DemandState) : PsKernelC0DemandStep :=
  if state.blocked then
    match state.frames with
    | [] => .halted
    | frame :: rest => psKernelC0DemandResume quoteFuel context state frame rest
  else
    match psKernelC0ArchitectureStructuralStep quoteFuel context state.machine with
    | .next next =>
        .next {
          state with
          machine := next
          blocked := false
          steps := state.steps + 1
        }
    | .declined reason => .declined reason
    | .halted =>
        match psKernelC0DemandStart context state with
        | some transition => transition
        | none =>
            match state.frames with
            | [] => .halted
            | frame :: rest =>
                psKernelC0DemandResume quoteFuel context state frame rest

/-- Structural recursion on the one operation-local fuel. Nested
    projection, Nat, or quotient majors cannot reset the reduction budget. -/
def psKernelC0DemandRun :
    Nat → Nat → PsKernelCheckerContext → PsKernelC0DemandState →
      Except String PsKernelC0DemandState
  | 0, _, _, _ => .error "candidate shared-demand budget exhausted"
  | fuel + 1, quoteFuel, context, state =>
      match psKernelC0DemandTransition quoteFuel context state with
      | .next next => psKernelC0DemandRun fuel quoteFuel context next
      | .halted => .ok state
      | .declined reason => .error reason

def psKernelC0ArchitectureCandidateDemand
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) : Except String (PsKernelExpr × Nat) := do
  let final ← psKernelC0DemandRun fuel fuel context
    { machine := { control := .mk expr [] } }
  let some result := psKernelC0QuoteMachine fuel final.machine
    | throw "candidate shared-demand readback budget exhausted"
  return (result, final.steps)

/-- Trusted source WHNF first. Candidate results, disagreements and budget
    failures cannot write a checking cache, a declaration or a proof receipt. -/
def psKernelC0ArchitectureObserveDemand
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelCheckerSession) := do
  let (source, checkedSession) ← psKernelSessionWhnf fuel session expr
  let observation : PsKernelC0ExecutionObservation :=
    match psKernelC0ArchitectureCandidateDemand fuel session.context expr with
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
