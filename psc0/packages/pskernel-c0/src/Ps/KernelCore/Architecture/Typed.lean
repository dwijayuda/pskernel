import Ps.KernelCore.Architecture.Budget

/-!
CDE-8B foundation: scoped source-typed observations for K recursors and
structure eta.

A K recursor is not reducible merely from the constructor name. The source
rule infers the major's type, WHNFs that type, infers the proposed canonical
constructor type and compares them by checked definitional equality. Structure
eta likewise requires inferred types and Prop/data restrictions. Reuse the
source algorithms, not a speculative reduction or a second accepting checker.

This module only returns an observation plus the source-owned checker state.
No candidate term, proof or declaration is accepted by this interface.
-/

inductive PsKernelC0TypedMajorKind where
  | k
  | structureEta
  | ordinary

structure PsKernelC0TypedMajorObservation where
  kind : PsKernelC0TypedMajorKind
  original : PsKernelExpr
  sourceResult : PsKernelExpr
  changed : Bool

/-- The recursor must be resolved from the active checked-session environment;
    externally assembled recursor metadata is never a trusted source of a
    proof judgment. This is still observational, not checked admission. -/
def psKernelC0ArchitectureObserveTypedMajor
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (recName : PsKernelName)
    (major : PsKernelExpr) :
    Except String (PsKernelC0TypedMajorObservation × PsKernelCheckerSession) := do
  let some (.recInfo recursor) :=
      psKernelEnvironmentFind session.context.environment recName
    | throw "candidate typed-major observation requires a recursor declaration"
  if recursor.isUnsafe then
    throw "candidate typed-major observation declines unsafe recursor"
  let sourceWhnf :=
    fun context state expr =>
      psKernelCheckerWhnf fuel context state expr
  let sourceInfer :=
    fun context state expr =>
      psKernelCheckerInfer fuel context state expr
  let sourceDefEq :=
    fun context state left right =>
      psKernelIsDefEq fuel context state left right
  let (result, nextState) ←
    if recursor.k then
      psKernelToConstructorWhenK
        sourceWhnf sourceInfer sourceDefEq
        session.context session.state recursor major
    else
      psKernelToConstructorWhenStructure
        sourceWhnf sourceInfer session.context session.state
        recursor major
  let kind := if recursor.k then PsKernelC0TypedMajorKind.k
    else PsKernelC0TypedMajorKind.structureEta
  let observation := {
    kind := kind
    original := major
    sourceResult := result
    changed := !psKernelExprEqual major result
  : PsKernelC0TypedMajorObservation }
  return (observation, { session with state := nextState })

/-!
CDE-8B.2: typed-major normalization as a source-justified *input* to the
existing candidate demand machine. This is not independent acceptance:
the source still normalizes first and owns every trusted state change.
-/

/-- The candidate never guesses a K or structure-eta constructor. It may
    rewrite exactly one recursor major only when the existing source
    inference/WHNF/DefEq algorithms explicitly produced the constructor.

    Source errors, unsupported metadata, unsafe declarations or wrong major
    shapes yield no candidate rewrite, not a theorem-checking success. -/
def psKernelC0ArchitectureSourceTypedRecursorMajor
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) : Option PsKernelExpr := do
  let .const recName levels := psKernelExprGetAppFn expr
    | none
  let some (.recInfo recursor) :=
      psKernelEnvironmentFind session.context.environment recName
    | none
  if recursor.isUnsafe ||
      recursor.base.levelParams.length != levels.length then none
  else do
    let majorIndex := recursor.numParams + recursor.numMotives +
      recursor.numMinors + recursor.numIndices
    let args := psKernelExprGetAppArgs expr
    let major ← args[majorIndex]?
    let (observation, _) ←
      match psKernelC0ArchitectureObserveTypedMajor
          fuel session recName major with
      | .ok result => some result
      | .error _ => none
    if !observation.changed then none
    else
      let revisedArgs := args.take majorIndex ++
        [observation.sourceResult] ++ args.drop (majorIndex + 1)
      some (psKernelApplyArgs
        (.const recName levels) revisedArgs)

/-- Source owns the first and only checked WHNF observation. The optional
    typed candidate reconstructs the same input with a source-justified major,
    then uses the already fuel/work-accounted demand evaluator with
    **only the quota remaining after typed wrapper reconstruction**. Disagreement
    and exhausted candidate resources remain observational failures. -/
def psKernelC0ArchitectureObserveTypedDemand
    (fuel quota : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelCheckerSession) := do
  let (source, checkedSession) ← psKernelSessionWhnf fuel session expr
  let candidateExpr :=
    (psKernelC0ArchitectureSourceTypedRecursorMajor fuel session expr).getD expr
  let candidate : Except String (PsKernelExpr × Nat × Nat) :=
    match psKernelC0ChargeExpr candidateExpr quota with
    | none => .error "typed major candidate work quota exhausted"
    | some remaining =>
        psKernelC0ArchitectureCandidateDemandMetered
          fuel remaining session.context candidateExpr
  let observation : PsKernelC0ExecutionObservation :=
    match candidate with
    | .ok (result, steps, _) =>
        { sourceValue := source
          candidateValue := some result
          agrees := psKernelExprEqual source result
          candidateSteps := steps }
    | .error _ =>
        { sourceValue := source
          candidateValue := none
          agrees := false
          candidateSteps := 0 }
  return (observation, checkedSession)
