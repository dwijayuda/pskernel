import Ps.Core.InductiveGroup
import Ps.Elab.Refinement

-- A recursor consumer supplies terms for the actual registered argument
-- domains. The cursor advances only after ordinary Core inference/unification;
-- group metadata determines order, never an invented motive or hypothesis.
structure PsElabRecursorArgument where
  context : PsElabContext
  term : PsExpr

structure PsElabRecursorArguments where
  context : PsElabContext
  arguments : List PsExpr
  cursor : PsExpr

def psElabRecursorArguments {α : Type} (items : List α)
    (make : PsElabContext → α → PsExpr → Except PsElabError PsElabRecursorArgument)
    (context : PsElabContext) (cursor : PsExpr) :
    Except PsElabError PsElabRecursorArguments := do
  match items with
  | [] => return { context, arguments := [], cursor }
  | item :: rest =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let argument ← make context item pi.domain
    let actual ← (psInferType argument.context.environment argument.context.metaContext
      argument.context.localContext argument.term).mapError PsElabError.infer
    let unified := psUnify argument.context.environment argument.context.localContext
      argument.context.metaContext pi.domain actual
    -- These are complete Core recursor arguments. Preserve the application
    -- error that final Core inference reports, including forbidden Prop
    -- elimination, while rejecting the incompatible domain at this cursor.
    if !unified.success then throw (.infer .applicationTypeMismatch)
    let context := psElabContextWithMeta argument.context unified.context
    let term := psMetaInstantiate context.metaContext argument.term
    let tail ← psElabRecursorArguments rest make context
      (psExprInstantiate1 pi.body term)
    return {
      context := tail.context
      arguments := term :: tail.arguments
      cursor := tail.cursor }

structure PsElabEliminationRecursorPlan where
  plan : PsInductiveEliminationPlan
  slotIndex : Nat
  slot : PsInductiveEliminationSlot
  recursor : PsRecursorInfo
  levels : List PsLevel
  context : PsElabContext
  cursor : PsExpr

def psElabEliminationRecursorPlanFor (context : PsElabContext)
    (family : PsInductiveInfo) (levels : List PsLevel)
    (parameters : List PsExpr) (motiveLevel : PsLevel) :
    Except PsElabError PsElabEliminationRecursorPlan := do
  let some plan := psInductiveEliminationPlanFor
      (psWhnf context.environment context.metaContext psLocalEmpty)
      (psEnvironmentFindInductive context.environment)
      (psEnvironmentFindConstructor context.environment)
      (psEnvironmentFindRecursor context.environment) family
    | throw .matchRecursorUnsupported
  let name := psNameAppendStr family.name "rec"
  let some (slotIndex, slot) := psInductiveEliminationSlotFor plan name
    | throw .matchRecursorUnsupported
  let some recursor := psEnvironmentFindRecursor context.environment name
    | throw .matchRecursorUnsupported
  if parameters.length != family.numParams then throw .matchParameterArity
  let recursorLevels ← psElabRecursorLevels family recursor levels motiveLevel
  let applied ← psElabApplyCore context (.constE recursor.name recursorLevels) parameters
  return {
    plan, slotIndex, slot, recursor
    levels := recursorLevels
    context := applied.context
    cursor := applied.type }

def psElabEliminationConstructors (context : PsElabContext)
    (plan : PsInductiveEliminationPlan) :
    Except PsElabError (List (Nat × PsInductiveEliminationSlot × PsInductiveEliminationConstructor)) := do
  let members ← (plan.slots.zipIdx).mapM fun (slot, index) =>
    slot.constructors.mapM fun constructor => do
      let some registered := psEnvironmentFindConstructor context.environment constructor.info.name
        | throw (.matchConstructorUnknown constructor.info.name)
      if !psNameEq registered.inductiveName slot.family.name ||
          registered.constructorIndex != constructor.info.constructorIndex ||
          registered.numParams != slot.family.numParams ||
          registered.numFields != constructor.info.numFields ||
          !psExprAlphaEq registered.type constructor.info.type ||
          !psInductiveGroupNamesEqual registered.levelParams slot.family.levelParams ||
          !psInductiveEliminationConstructorMetadataValid slot constructor then
        throw .matchRecursorUnsupported
      return (index, slot, constructor)
  return members.flatten

-- Existing direct consumers retain their contract while using the same
-- complete slot owner. A singleton public family with nested slots is not a
-- singleton eliminator and cannot silently enter a direct-group strategy.
structure PsElabGroupRecursorPlan where
  group : PsInductiveGroupPlan
  recursor : PsRecursorInfo
  levels : List PsLevel
  context : PsElabContext
  cursor : PsExpr

def psElabGroupRecursorPlanFor (context : PsElabContext)
    (family : PsInductiveInfo) (levels : List PsLevel)
    (parameters : List PsExpr) (motiveLevel : PsLevel) :
    Except PsElabError PsElabGroupRecursorPlan := do
  let complete ← psElabEliminationRecursorPlanFor context family levels parameters motiveLevel
  if complete.plan.slots.length != complete.plan.group.members.length then
    throw .matchRecursorUnsupported
  return {
    group := complete.plan.group, recursor := complete.recursor
    levels := complete.levels
    context := complete.context
    cursor := complete.cursor }

-- The flattened minor slots retain their owner as well as their local ordinal.
-- Every consumer uses this same order, including the singleton case.
def psElabGroupConstructors (context : PsElabContext) (group : PsInductiveGroupPlan) :
    Except PsElabError (List (PsInductiveInfo × PsConstructorInfo)) := do
  let some plan := psBuildInductiveEliminationPlan
      (psWhnf context.environment context.metaContext psLocalEmpty)
      (psEnvironmentFindInductive context.environment)
      (psEnvironmentFindConstructor context.environment) group
    | throw .matchRecursorUnsupported
  if plan.slots.length != group.members.length then throw .matchRecursorUnsupported
  let constructors ← psElabEliminationConstructors context plan
  return constructors.map (fun (_, slot, constructor) => (slot.family, constructor.info))
