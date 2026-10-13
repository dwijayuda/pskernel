import Ps.KernelCore.Architecture.Demand

/-!
CDE-8A foundation: conservative, operation-scoped candidate readback.

Unlike depth-only quotation, the remaining work quota is threaded through
head, captured closures and application arguments. Every source node is
counted under a shared bound. Before instantiating a closure, we reserve a
conservative expansion bound based on the source node count and the total
size of the fully quoted substitutions, so duplication cannot bypass the
quota. These are *candidate* limits, not kernel typing/acceptance decisions.

Demand-step active syntax, retained continuation frames, delayed captured
environments, String UTF-8 storage, pre-expansion String.ofList reservations, source-delta and recursor-RHS
preflight traversals, and final quotation now consume one quota. Intermediate quotation and resulting machine syntax are now also
charged against the operation quota. This remains a candidate *syntactic
work* model, not a formally proven bound on Lean runtime/heap allocations.
-/

/-- Spend a nonnegative number of syntactic-work units. Resource
    depletion is not a logical rejection in the source kernel. -/
def psKernelC0SpendWork (quota cost : Nat) : Option Nat :=
  if cost > quota then none else some (quota - cost)

/-- Charge all name components, including UTF-8 segment storage and Nat
    components, rather than treating an arbitrarily long name as one node. -/
def psKernelC0ChargeName
    (name : PsKernelName) (quota : Nat) : Option Nat :=
  match name with
  | .anonymous => psKernelC0SpendWork quota 1
  | .str parent value => do
      let left ← psKernelC0ChargeName parent quota
      psKernelC0SpendWork left (String.utf8ByteSize value + 1)
  | .num parent value => do
      let left ← psKernelC0ChargeName parent quota
      psKernelC0SpendWork left (psKernelNatSizeInBytes value + 1)

/-- Recursive universe levels and named parameters also consume syntactic
    work. A deeply nested max/imax/succ expression therefore cannot hide
    unbounded reconstruction behind one .sort or constant occurrence. -/
def psKernelC0ChargeLevel
    (level : PsKernelLevel) (quota : Nat) : Option Nat := do
  let left ← psKernelC0SpendWork quota 1
  match level with
  | .zero => some left
  | .succ inner => psKernelC0ChargeLevel inner left
  | .max a b => do
      let rest ← psKernelC0ChargeLevel a left
      psKernelC0ChargeLevel b rest
  | .imax a b => do
      let rest ← psKernelC0ChargeLevel a left
      psKernelC0ChargeLevel b rest
  | .param name => psKernelC0ChargeName name left
  | .mvar name => psKernelC0ChargeName name left

/-- Constant universe instantiations reuse the same quota across all levels. -/
def psKernelC0ChargeLevelList
    (levels : List PsKernelLevel) (quota : Nat) : Option Nat :=
  levels.foldlM
    (fun remaining level => psKernelC0ChargeLevel level remaining)
    quota

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
      | .lam name ty body _ => do
          let afterName ← psKernelC0ChargeName name remaining
          let left ← psKernelC0ChargeExpr ty afterName
          psKernelC0ChargeExpr body left
      | .forallE name ty body _ => do
          let afterName ← psKernelC0ChargeName name remaining
          let left ← psKernelC0ChargeExpr ty afterName
          psKernelC0ChargeExpr body left
      | .letE name ty value body _ => do
          let afterName ← psKernelC0ChargeName name remaining
          let afterTy ← psKernelC0ChargeExpr ty afterName
          let afterValue ← psKernelC0ChargeExpr value afterTy
          psKernelC0ChargeExpr body afterValue
      | .mdata metadata body => do
          let left ← psKernelC0SpendWork remaining
            (psKernelNatSizeInBytes metadata)
          psKernelC0ChargeExpr body left
      | .proj typeName index struct => do
          let afterName ← psKernelC0ChargeName typeName remaining
          let afterIndex ← psKernelC0SpendWork afterName
            (psKernelNatSizeInBytes index)
          psKernelC0ChargeExpr struct afterIndex
      | .lit (.nat value) =>
          let bytes := psKernelNatSizeInBytes value
          if bytes > remaining then none else some (remaining - bytes)
      | .lit (.str value) =>
          let bytes := String.utf8ByteSize value
          if bytes > remaining then none else some (remaining - bytes)
      | .bvar index =>
          psKernelC0SpendWork remaining (psKernelNatSizeInBytes index)
      | .fvar name => psKernelC0ChargeName name remaining
      | .mvar name => psKernelC0ChargeName name remaining
      | .sort level => psKernelC0ChargeLevel level remaining
      | .const name levels => do
          let afterName ← psKernelC0ChargeName name remaining
          psKernelC0ChargeLevelList levels afterName

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

/-- Charge source syntax and all captured binder closures under the
    same finite depth and monotonically decreasing work quota. This
    includes environment entries previously omitted from the step footprint.
    Shared closures may be charged again: conservative decline is allowed
    in this observational evaluator, but a resource failure cannot reject
    a theorem. -/
def psKernelC0ChargeClosureSyntax :
    Nat → PsKernelC0Closure → Nat → Option Nat
  | 0, _, _ => none
  | depth + 1, .mk expr env, quota => do
      let afterExpr ← psKernelC0ChargeExpr expr quota
      env.foldlM
        (fun remaining captured =>
          psKernelC0ChargeClosureSyntax depth captured remaining)
        afterExpr

/-- Charge an active machine including the delayed argument environments,
    rather than only the outer expressions. -/
def psKernelC0ChargeMachineSyntax
    (depth : Nat) (machine : PsKernelC0Machine)
    (quota : Nat) : Option Nat := do
  let afterControl ←
    psKernelC0ChargeClosureSyntax depth machine.control quota
  machine.arguments.foldlM
    (fun remaining closure =>
      psKernelC0ChargeClosureSyntax depth closure remaining)
    afterControl

/-- A continuation retains parent control and argument environments.
    The work budget charges those retained references on every transition
    as a deliberately conservative bound on the traversal footprint.
    The source recursor metadata is borrowed from the immutable checked
    environment and is not considered a fresh candidate allocation. -/
def psKernelC0ChargeFrameSyntax
    (depth : Nat) (frame : PsKernelC0DemandFrame)
    (quota : Nat) : Option Nat :=
  match frame with
  | .natSucc parent => psKernelC0ChargeMachineSyntax depth parent quota
  | .natLeft parent right => do
      let left ← psKernelC0ChargeMachineSyntax depth parent quota
      psKernelC0ChargeClosureSyntax depth right left
  | .natRight parent _ => psKernelC0ChargeMachineSyntax depth parent quota
  | .projection parent _ _ =>
      psKernelC0ChargeMachineSyntax depth parent quota
  | .quotient parent _ =>
      psKernelC0ChargeMachineSyntax depth parent quota
  | .recursor parent _ _ =>
      psKernelC0ChargeMachineSyntax depth parent quota

/-- Charge the whole reachable demand-stack syntax from one shared quota.
    No untrusted candidate cache or proof judgment is produced. -/
def psKernelC0ChargeDemandStateSyntax
    (depth : Nat) (state : PsKernelC0DemandState)
    (quota : Nat) : Option Nat := do
  let afterActive ←
    psKernelC0ChargeMachineSyntax depth state.machine quota
  state.frames.foldlM
    (fun remaining frame =>
      psKernelC0ChargeFrameSyntax depth frame remaining)
    afterActive

/-- String.ofList materialization in a demanded projection/recursor
    creates several AST nodes per UTF-8 byte. Reserve a deliberately high,
    fixed per-byte allowance *before* invoking the existing transition,
    rather than letting a small quota trigger large unchecked expansion.
    This is a conservative candidate work bound, not a measured heap-byte
    guarantee. Every extra reservation can only cause candidate decline. -/
def psKernelC0DemandStringReserve
    (state : PsKernelC0DemandState) : Nat :=
  match state.machine.control, state.frames with
  | .mk (.lit (.str value)) _, .projection _ _ _ :: _ =>
      (String.utf8ByteSize value + 1) * 16
  | .mk (.lit (.str value)) _, .recursor _ _ _ :: _ =>
      (String.utf8ByteSize value + 1) * 16
  | _, _ => 0

/-- Account for source-body traversal and every occurrence-level
    instantiation without allocating the substituted result first.
    Levels can be a tree of max/imax/succ/parameters, not a constant-cost
    field. Each source node may refer to all supplied universe expressions,
    so the extra preflight conservatively reserves sourceWork * levelWork.

    This is a syntactic-work bound, not a claim about the Lean runtime heap. -/
def psKernelC0ReserveLevelInstantiation
    (body : PsKernelExpr)
    (levels : List PsKernelLevel)
    (quota : Nat) : Option Nat := do
  let afterBody ← psKernelC0ChargeExpr body quota
  let afterLevels ← psKernelC0ChargeLevelList levels afterBody
  let sourceWork := quota - afterBody
  let levelWork := afterBody - afterLevels
  psKernelC0SpendWork afterLevels (sourceWork * levelWork)

/-- Source δ may instantiate a declaration body at a nontrivial universe
    substitution and then append the original application spine. Reserve
    both work families from the same candidate operation allowance before
    calling the existing source reduction helper. -/
def psKernelC0ReserveDeltaSyntax
    (context : PsKernelCheckerContext)
    (machine : PsKernelC0Machine)
    (quota : Nat) : Option Nat := do
  match machine.control with
  | .mk (.const name levels) _ =>
      match psKernelEnvironmentFind context.environment name with
      | some declaration =>
          match psKernelConstantInfoDeltaValue declaration with
          | none => some quota
          | some body => do
              let afterLevels ←
                psKernelC0ReserveLevelInstantiation body levels quota
              psKernelC0SpendWork afterLevels machine.arguments.length
      | none => some quota
  | _ => some quota

/-- A selected iota rule clones the instantiated recursor RHS, applies
    fixed arguments and selected constructor fields, then restores surplus
    arguments. Preflight universe substitution plus those future app nodes
    under the same quota; unsupported constructor shapes remain neutral. -/
def psKernelC0ReserveRecursorSyntax
    (state : PsKernelC0DemandState)
    (quota : Nat) : Option Nat := do
  match state.frames with
  | .recursor parent metadata levels :: _ =>
      let ruleName : Option PsKernelName :=
        match state.machine.control with
        | .mk (.const name _) _ => some name
        | .mk (.lit (.nat 0)) _ => some psKernelNatZeroName
        | .mk (.lit (.nat (_ + 1))) _ => some psKernelNatSuccName
        | _ => none
      match ruleName with
      | none => some quota
      | some name =>
          match psKernelFindRecursorRule name metadata.rules with
          | some rule => do
              let afterLevels ←
                psKernelC0ReserveLevelInstantiation rule.rhs levels quota
              let fixedArgs :=
                metadata.numParams + metadata.numMotives + metadata.numMinors
              let appNodes := fixedArgs + rule.nFields +
                parent.arguments.length
              psKernelC0SpendWork afterLevels appNodes
          | none => some quota
  | _ => some quota

/-- Resource preflight shares the operation quota between source-definition
    body traversal and the selected recursor RHS. Both can only decline a
    speculative candidate; neither can reject a source-checked declaration. -/
def psKernelC0ReserveSourceRewrites
    (context : PsKernelCheckerContext)
    (state : PsKernelC0DemandState)
    (quota : Nat) : Option Nat := do
  let afterDelta ←
    psKernelC0ReserveDeltaSyntax context state.machine quota
  psKernelC0ReserveRecursorSyntax state afterDelta

/-- Before a step that can inspect its scrutinee or a resumed
    continuation, reify that intermediate using the *metered* quotation
    path. This gives every source quotation inside the existing demand
    dispatcher a conservative charge against the SAME operation quota.
    No checked value or proof is produced by this speculative preflight.

    Syntactic β/ζ/app transitions do not need eager quotation and remain
    lazy; unsupported neutral heads may conservatively decline at very low
    budgets without affecting the authoritative source checker. -/
/-- The saved parent of an ordinary recursor and the eliminator
    function of Quot are separately quoted when their major premise
    resumes. These obligations are identical for an ordinary halted child
    and a 'blocked' child: neither path may skip the shared quota. -/
def psKernelC0ReserveResumeReadbacks
    (depth : Nat)
    (frames : List PsKernelC0DemandFrame)
    (quota : Nat) : Option Nat := do
  match frames with
  | .recursor parent _ _ :: _ => do
      let (_, left) ← psKernelC0QuoteMachineMetered depth quota parent
      some left
  | .quotient parent _ :: _ =>
      match parent.arguments[3]? with
      | none => some quota
      | some fn => do
          let (_, left) ← psKernelC0QuoteClosureMetered depth fn quota
          some left
  | _ => some quota

def psKernelC0ReserveIntermediateReadbacks
    (depth : Nat)
    (state : PsKernelC0DemandState)
    (quota : Nat) : Option Nat := do
  if state.blocked then
    match state.frames with
    | [] => some quota
    | _ => do
        let (_, left) ←
          psKernelC0QuoteMachineMetered depth quota state.machine
        psKernelC0ReserveResumeReadbacks depth state.frames left
  else
    match psKernelC0MachineStep state.machine with
    | .next _ => some quota
    | .declined _ => some quota
    | .halted =>
        let afterProjection ←
          match state.machine.control with
          | .mk (.proj _ _ struct) captured => do
              let (_, left) ←
                psKernelC0QuoteClosureMetered depth
                  (.mk struct captured) quota
              some left
          | _ => some quota
        let afterHead ←
          match state.machine.control with
          | .mk (.const _ _) _ => do
              let (_, left) ←
                psKernelC0QuoteMachineMetered
                  depth afterProjection state.machine
              some left
          | _ => some afterProjection
        match state.frames with
        | [] => some afterHead
        | _ => do
            let (_, afterResume) ←
              psKernelC0QuoteMachineMetered
                depth afterHead state.machine
            psKernelC0ReserveResumeReadbacks
              depth state.frames afterResume

/-- The cost of primitive numeral work is checked BEFORE calling the
    existing Nat reducer. The bound is conservative in units of numerical
    byte-work, not a claim about Lean heap allocations or runtime cycles.
    In particular, pow/left-shift reserve space proportional to possible
    output growth, and other arithmetic reserves operand-dependent work.
    Unknown operations do not incur a speculative rewrite charge. -/
def psKernelC0ReserveNatBinaryWork
    (name : PsKernelName)
    (left right quota : Nat) : Option Nat :=
  if !psKernelC0CandidateIsNatBinary name then some quota
  else
    let leftBytes := psKernelNatSizeInBytes left
    let rightBytes := psKernelNatSizeInBytes right
    let input := leftBytes + rightBytes + 1
    let cost :=
      if psKernelNameEq name psKernelNatPowName then
        input * (right + 1)
      else if psKernelNameEq name psKernelNatShiftLeftName then
        input + right + leftBytes
      else if psKernelNameEq name psKernelNatShiftRightName then
        input + leftBytes * 8
      else if psKernelNameEq name psKernelNatGcdName then
        input * input
      else
        input * 2
    if cost > quota then none else some (quota - cost)

/-- Inspect the active Nat head independently of any enclosing
    continuation. A nested Nat.pow under an outer Nat argument must pay for
    its own primitive before it can create a large intermediate numeral. -/
def psKernelC0ReservePrimitiveHeadWork
    (depth : Nat)
    (machine : PsKernelC0Machine)
    (quota : Nat) : Option Nat := do
  match machine.control with
  | .mk (.const op levels) _ =>
      if !levels.isEmpty then some quota
      else if psKernelNameEq op psKernelNatSuccName then
        match machine.arguments with
        | [] => some quota
        | arg :: _ => do
            let (valueExpr, afterQuote) ←
              psKernelC0QuoteClosureMetered depth arg quota
            match psKernelExprNatLiteralValue valueExpr with
            | none => some afterQuote
            | some n =>
                psKernelC0SpendWork afterQuote
                  (psKernelNatSizeInBytes (n + 1))
      else if psKernelC0CandidateIsNatBinary op then
        match machine.arguments with
        | left :: right :: _ => do
            let (aExpr, afterA) ←
              psKernelC0QuoteClosureMetered depth left quota
            let (bExpr, afterB) ←
              psKernelC0QuoteClosureMetered depth right afterA
            match psKernelExprNatLiteralValue aExpr,
                  psKernelExprNatLiteralValue bExpr with
            | some a, some b =>
                psKernelC0ReserveNatBinaryWork op a b afterB
            | _, _ => some afterB
        | _ => some quota
      else some quota
  | _ => some quota

/-- A finished nested operand may trigger Nat.succ or a binary primitive
    in its saved parent frame; that additional work is never free. -/
def psKernelC0ReservePrimitiveResumeWork
    (depth : Nat)
    (state : PsKernelC0DemandState)
    (quota : Nat) : Option Nat := do
  match state.frames with
  | .natRight parent left :: _ => do
      let (rightExpr, afterQuote) ←
        psKernelC0QuoteMachineMetered depth quota state.machine
      match parent.control, psKernelExprNatLiteralValue rightExpr with
      | .mk (.const op _) _, some right =>
          psKernelC0ReserveNatBinaryWork op left right afterQuote
      | _, _ => some afterQuote
  | .natSucc _ :: _ => do
      let (valueExpr, afterQuote) ←
        psKernelC0QuoteMachineMetered depth quota state.machine
      match psKernelExprNatLiteralValue valueExpr with
      | none => some afterQuote
      | some n =>
          psKernelC0SpendWork afterQuote (psKernelNatSizeInBytes (n + 1))
  | _ => some quota

/-- Primitive accounting is composed head-first and resume-second, sharing
    the *same* decreasing quota. We only preflight a saved frame when the
    machine has halted (or is explicitly blocked): syntactic app/beta/zeta
    steps do not force a neutral operand or reset the work budget. -/
def psKernelC0ReservePrimitiveWork
    (depth : Nat)
    (state : PsKernelC0DemandState)
    (quota : Nat) : Option Nat := do
  let afterHead ←
    psKernelC0ReservePrimitiveHeadWork depth state.machine quota
  if state.blocked then
    psKernelC0ReservePrimitiveResumeWork depth state afterHead
  else
    match psKernelC0MachineStep state.machine with
    | .halted =>
        psKernelC0ReservePrimitiveResumeWork depth state afterHead
    | _ => some afterHead

/-- One transition loop and one remaining quota. This delegates *all*
    reduction rules to the existing demand dispatcher and therefore cannot
    introduce separate candidate reduction semantics. -/
def psKernelC0DemandRunWithBudget :
    Nat → Nat → Nat → PsKernelCheckerContext → PsKernelC0DemandState →
      Except String (PsKernelC0DemandState × Nat)
  | 0, _, _, _, _ =>
      .error "candidate shared-demand transition budget exhausted"
  | fuel + 1, depth, quota, context, state => do
      let some rest := psKernelC0ChargeDemandStateSyntax depth state quota
        | throw "candidate shared syntactic-work quota exhausted"
      let reserve := psKernelC0DemandStringReserve state
      if reserve > rest then
        throw "candidate String expansion work quota exhausted"
      let afterReserve := rest - reserve
      let some afterRewrites :=
          psKernelC0ReserveSourceRewrites context state afterReserve
        | throw "candidate source-rewrite work quota exhausted"
      let some afterQuotes :=
          psKernelC0ReserveIntermediateReadbacks depth state afterRewrites
        | throw "candidate intermediate quotation work quota exhausted"
      let some afterPrimitive :=
          psKernelC0ReservePrimitiveWork depth state afterQuotes
        | throw "candidate primitive numerical work quota exhausted"
      match psKernelC0DemandTransition depth context state with
      | .next next =>
          -- A transition may create a fresh intermediate expression. Count
          -- the entire reachable result (including its saved frames) before
          -- allowing the next candidate transition to consume it.
          let some afterResult :=
              psKernelC0ChargeDemandStateSyntax depth next afterPrimitive
            | throw "candidate intermediate rewrite work quota exhausted"
          psKernelC0DemandRunWithBudget fuel depth afterResult context next
      | .halted => return (state, afterPrimitive)
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
