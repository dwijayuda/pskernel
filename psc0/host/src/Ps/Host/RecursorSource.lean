/-
Copyright (c) 2026 ProofScript contributors.
Released under the Apache 2.0 license; see THIRD_PARTY_NOTICES.md.
Native-only recursor source annotation correspondence.
Pinned reference: Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
Lean/Expr.lean beta/instantiateLevelParams and kernel structure projections.
This is not a logical checker, a runtime reducer or an asset-selection policy.
-/
import Lean

namespace PsV7Native.RecursorSource

-- Only a safe definition's actual pinned body may expose a projection.
-- Do not unfold an axiom, opaque constant, recursor, unsafe or partial body.
private def unfoldSafe? (native : Lean.Environment) (expression : Lean.Expr) :
    Option Lean.Expr := do
  let .const name levels := expression.getAppFn | none
  let info ← native.find? name
  if info.isUnsafe || info.isPartial then none else do
    let .defnInfo definition := info | none
    if definition.levelParams.length != levels.length then none else
      return (definition.value.instantiateLevelParams definition.levelParams levels).beta
        expression.getAppArgs

-- Follow the actual dictionary to a fully saturated constructor. This bound
-- limits annotation-view exposure only; no checker/elaborator budget changes.
private def field? (native : Lean.Environment) (owner : Lean.Name) (index : Nat) :
    Nat → Lean.Expr → Option Lean.Expr
  | 0, _ => none
  | fuel + 1, expression => do
    let expression := expression.consumeMData.headBeta
    let .const name _ := expression.getAppFn | none
    let info ← native.find? name
    match info with
    | .ctorInfo constructor =>
      let args := expression.getAppArgs
      if constructor.induct != owner || index >= constructor.numFields ||
          args.size != constructor.numParams + constructor.numFields then none
      else args[constructor.numParams + index]?
    | .defnInfo _ =>
      let next ← unfoldSafe? native expression
      if Lean.Expr.equal next expression then none
      else field? native owner index fuel next
    | _ => none

-- A reference projection is exposed through its real safe definition and
-- actual constructor field, not a Nat/Fin/formatter name replacement table.
private def projectionView? (native : Lean.Environment) (reference : Lean.Expr) :
    Option Lean.Expr := do
  let exposed ← match reference.getAppFn with
    | .proj .. => some reference
    | _ => unfoldSafe? native reference
  let .proj owner index major := exposed.getAppFn | none
  let value ← field? native owner index 16 major
  return (Lean.mkAppN value exposed.getAppArgs).headBeta

-- Optional arguments are an existing selected source annotation, not a new
-- binder in the recursor telescope. Validate the pinned identity reduction
-- before looking through it, and preserve the selected wrapper/default bytes.
private def optionalView? (native : Lean.Environment) (expression : Lean.Expr) :
    Option (Lean.Expr × Lean.Expr × Lean.Expr) := do
  let .app (.app head@(.const name _) type) value := expression | none
  if name != ``optParam then none else do
    let exposed ← unfoldSafe? native expression
    if Lean.Expr.equal exposed type then some (head, type, value) else none

private partial def transfer (native : Lean.Environment) (fuel : Nat)
    (selected reference : Lean.Expr) : Except String Lean.Expr := do
  let reference := reference.consumeMData
  match selected with
  | .mdata data value =>
    return .mdata data (← transfer native fuel value reference)
  | _ => pure ()
  let selectedOptional := optionalView? native selected
  let referenceOptional := optionalView? native reference
  match selectedOptional, referenceOptional with
  | some (head, type, value), none =>
    return .app (.app head (← transfer native fuel type reference)) value
  | none, some (_, type, _) => return ← transfer native fuel selected type
  | _, _ => pure ()
  let exposeReference := fun (_ : Unit) => do
    if fuel == 0 then throw "recursor source reference projection exposure exhausted"
    let some next := projectionView? native reference
      | throw "recursor source annotations have no checked structural correspondence"
    if Lean.Expr.equal next reference then
      throw "recursor source reference projection made no progress"
    transfer native (fuel - 1) selected next
  match selected, reference with
  | .forallE _ domain body _, .forallE name nativeDomain nativeBody binder =>
    return .forallE name (← transfer native fuel domain nativeDomain)
      (← transfer native fuel body nativeBody) binder
  | .lam _ domain body _, .lam name nativeDomain nativeBody binder =>
    return .lam name (← transfer native fuel domain nativeDomain)
      (← transfer native fuel body nativeBody) binder
  | .app fn arg, .app nativeFn nativeArg =>
    return .app (← transfer native fuel fn nativeFn)
      (← transfer native fuel arg nativeArg)
  | .letE _ type value body nondep, .letE name nativeType nativeValue nativeBody _ =>
    return .letE name (← transfer native fuel type nativeType)
      (← transfer native fuel value nativeValue)
      (← transfer native fuel body nativeBody) nondep
  | .proj owner index value, .proj nativeOwner nativeIndex nativeValue =>
    unless owner == nativeOwner && index == nativeIndex do
      throw "projection identity differs"
    return .proj owner index (← transfer native fuel value nativeValue)
  | .const name _, .const nativeName _ =>
    if name == nativeName then return selected else exposeReference ()
  | .sort _, .sort _ => return selected
  | .bvar index, .bvar nativeIndex =>
    unless index == nativeIndex do throw "bound index differs"
    return selected
  | .lit _, .lit _ =>
    unless selected == reference do throw "literal differs"
    return selected
  | _, _ => exposeReference ()

-- Preserve every selected logical node and level. Specialization of an
-- existing selected universe profile remains exactly the exporter's policy.
-- The unchanged authorer still checks complete layout, fresh kernel replay,
-- generated signatures, symbolic iota rules, proof closure and exact digests.
def copy (native : Lean.Environment) (selected reference : Lean.Expr) :
    Except String Lean.Expr := do
  let annotated ← transfer native 16 selected reference
  unless annotated == selected do
    throw "recursor source annotations altered the selected logical structure"
  return annotated

end PsV7Native.RecursorSource
