import Ps.Elab.DerivingContext
import Ps.Environment.InhabitedExpr

/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/Inhabited.lean at eb6cafb.
Copyright (c) 2020 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: the actual constructor result constrains its field metavariables
before remaining defaults are synthesized. Complete group order, ordinary
unification, parameter-only requirements and checked Core admission are retained.
-/

-- Native mkDefaultValue unifies the fully applied constructor result first.
-- Index-determining fields must therefore receive their forced index values,
-- rather than arbitrary defaults such as Nat.zero or Fin.zero.
def psElabDeriveInhabitedConstructor (plan : PsElabDeriveContext)
    (constructor : PsConstructorInfo) : Except PsElabError PsExpr := do
  let (initial, type) ← psElabDeriveConstructor plan constructor
  let mut context := plan.context
  let mut cursor := type
  let mut constructorValue := initial
  let mut fields : List (Nat × PsExpr) := []
  for _ in [:constructor.numFields] do
    let field ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let fresh := psMetaFresh context.metaContext context.localContext field.domain .natural
    let .mvar id := fresh.expr | throw (.data "derived constructor field is not a metavariable")
    context := psElabContextWithMeta context fresh.context
    fields := fields ++ [(id, field.domain)]
    cursor := psExprInstantiate1 field.body fresh.expr
    constructorValue := .app constructorValue fresh.expr
  let result := psUnify context.environment context.localContext context.metaContext
    cursor plan.family
  if !result.success then
    throw (.data "derived constructor does not produce the expected family")
  context := psElabContextWithMeta context result.context
  -- Filling in telescope order instantiates every earlier choice into later
  -- dependent field types. A result-constrained field is already assigned.
  for (id, domain) in fields do
    if (psMetaFindAssignment context.metaContext id).isNone then
      let domain := psMetaInstantiate context.metaContext domain
      let defaultValue ← match psElabDefaultValue context domain with
        | some defaultCore => pure defaultCore
        | none => do
          let level ← psElabExpressionSort context domain
          let dictionary ← psElabDeriveInstance context (psStandardInhabitedType domain level)
          pure (psStandardInhabitedDefault level domain dictionary)
      -- The existing checked term owner propagates constraints from declared
      -- defaults or an actual instance back into this constructor telescope.
      let checked ← psElabResolvedTerm context defaultValue (some domain)
      let assigned := psUnify checked.context.environment checked.context.localContext
        checked.context.metaContext (.mvar id) checked.term
      if !assigned.success then
        throw (.data "derived constructor default does not fill its field")
      context := psElabContextWithMeta checked.context assigned.context
  let value := psMetaInstantiate context.metaContext constructorValue
  let checked ← psElabResolvedTerm context value (some plan.family)
  let value := psMetaInstantiate checked.context.metaContext checked.term
  if psExprHasUnresolvedMeta value then throw .unresolvedMetavariable
  if !psExprFVarsInContext plan.context.localContext value then
    throw (.data "derived constructor default escaped its index context")
  return value

def psElabDeriveInhabitedValue (plan : PsElabDeriveContext) : Except PsElabError PsExpr := do
  for name in plan.info.constructors do
    let some constructor := psEnvironmentFindConstructor plan.context.environment name
      | throw (.data "deriving constructor is missing")
    match psElabDeriveInhabitedConstructor plan constructor with
    | .ok value => return value
    | .error _ => pure ()
  throw (.data "Inhabited deriving requires a constructor with inhabitable fields")

def psElabDeriveInhabited (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  -- Complete nested/group metadata is validated by the shared preparation.
  -- Defaults themselves use only actual constructor terms and available
  -- dictionaries; a recursive slot never creates a self/default assumption.
  let plan ← psElabDerivePrepare environment origin { groups := true, indices := true, nested := true }
  -- RC4 chooses across all constructors before adding assumptions: a later
  -- empty constructor must beat an earlier constructor requiring Inhabited α.
  let (plan, defaultValue) ← match psElabDeriveInhabitedValue plan with
    | .ok value => pure (plan, value)
    | .error _ => do
      let plan := psElabDeriveRequirements plan (psRootName "Inhabited")
      let value ← psElabDeriveInhabitedValue plan
      pure (plan, value)
  let level ← psElabExpressionSort plan.context plan.family
  psElabDeriveFinish plan "instInhabited"
    (psStandardInhabitedType plan.family level)
    (psStandardInhabitedValue plan.family defaultValue level) true

