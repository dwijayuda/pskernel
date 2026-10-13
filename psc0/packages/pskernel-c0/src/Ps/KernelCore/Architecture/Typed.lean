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
