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
  let some group := psInductiveGroupPlanFor
      (psEnvironmentFindInductive context.environment)
      (psEnvironmentFindRecursor context.environment) family
    | throw .matchRecursorUnsupported
  let some recursor := psEnvironmentFindRecursor context.environment
      (psNameAppendStr family.name "rec")
    | throw .matchRecursorUnsupported
  if parameters.length != family.numParams then throw .matchParameterArity
  let recursorLevels ← psElabRecursorLevels family recursor levels motiveLevel
  let applied ← psElabApplyCore context (.constE recursor.name recursorLevels) parameters
  return {
    group, recursor
    levels := recursorLevels
    context := applied.context
    cursor := applied.type }

-- The flattened minor slots retain their owner as well as their local ordinal.
-- Every consumer uses this same order, including the singleton case.
def psElabGroupConstructors (context : PsElabContext) (group : PsInductiveGroupPlan) :
    Except PsElabError (List (PsInductiveInfo × PsConstructorInfo)) := do
  let families ← group.members.mapM fun family =>
    (family.constructors.zipIdx).mapM fun (name, index) => do
      let some constructor := psEnvironmentFindConstructor context.environment name
        | throw (.matchConstructorUnknown name)
      if !psNameEq constructor.inductiveName family.name ||
          constructor.constructorIndex != index ||
          constructor.numParams != family.numParams ||
          !psInductiveGroupNamesEqual constructor.levelParams family.levelParams ||
          constructor.recursiveFields.eraseDups.length != constructor.recursiveFields.length ||
          constructor.recursiveFields.any (· >= constructor.numFields) then
        throw .matchRecursorUnsupported
      return (family, constructor)
  return families.flatten
