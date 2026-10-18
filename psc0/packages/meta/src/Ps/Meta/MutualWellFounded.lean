import Ps.Meta.WellFounded
import Ps.Meta.MutualPacking

/-!
Typed component construction for Lean4.35.0-style mutual well-founded recursion.
Reference eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
ArgsPacker.Mutual and PreDefinition/WF/{PackMutual,Rel,Fix}.
The original source owner supplies unary member types/measures in one fixed
parameter context. Result motives may depend on the component tag; measures
must have one fixed codomain and one actual checked relation dictionary.
This module has no source strategy, temporary declarations or runtime authority.
-/

structure PsMutualWellFoundedPlan where
  types : List PsExpr
  type : PsExpr
  relation : PsWellFoundedRelationPlan

def psMutualWellFoundedPlanFor (environment : PsEnvironment)
    (metaContext : PsMetaContext) (locals : PsLocalContext)
    (types measures : List PsExpr) (dictionary : PsExpr) :
    Except PsInferError PsMutualWellFoundedPlan := do
  if types.isEmpty || types.length != measures.length then throw .applicationTypeMismatch
  let type ← psMutualPackingUncurryType environment metaContext locals types
  let measureTypes ← measures.mapM (psInferType environment metaContext locals)
  -- Check the per-member domains before aggregate construction. Equal sum
  -- shapes alone do not establish the original positional correspondence.
  for (memberType, measureType) in types.zip measureTypes do
    let member ← psInferEnsureForall environment metaContext locals memberType
    let measure ← psInferEnsureForall environment metaContext locals measureType
    if !psWellFoundedDefEq environment metaContext locals member.domain measure.domain then
      throw .applicationTypeMismatch
  let measureType ← psMutualPackingUncurryTypeND environment metaContext locals measureTypes
  let parameter ← psInferEnsureForall environment metaContext locals measureType
  let measure ← psMutualPackingUncurry environment metaContext locals measureType measures
  let relation ← psWellFoundedPlanForMeasure environment metaContext locals
    parameter.domain parameter.body measure dictionary
  let resultParameter ← psInferEnsureForall environment metaContext locals type
  if !psWellFoundedDefEq environment metaContext locals resultParameter.domain relation.domain then
    throw .applicationTypeMismatch
  return { types, type, relation }

-- Infer the actual fixpoint constructor's required functional type. The
-- selected checked declaration, not a second hand-written signature, owns
-- the callback's proof and dependent result telescope.
def psMutualWellFoundedFixBase (environment : PsEnvironment)
    (metaContext : PsMetaContext) (locals : PsLocalContext)
    (plan : PsMutualWellFoundedPlan) : Except PsInferError PsExpr := do
  let parameter ← psInferEnsureForall environment metaContext locals plan.type
  if !psWellFoundedDefEq environment metaContext locals parameter.domain plan.relation.domain then
    throw .applicationTypeMismatch
  let domainSort ← psInferType environment metaContext locals parameter.domain
  let domainLevel ← psInferEnsureSort environment metaContext locals domainSort
  let major := psLocalPushBinding locals parameter.name parameter.domain .explicit
  let result := psExprInstantiate1 parameter.body (.fvar major.id)
  let resultSort ← psInferType environment metaContext major.context result
  let resultLevel ← psInferEnsureSort environment metaContext major.context resultSort
  let motive := PsExpr.lam parameter.name parameter.domain parameter.body .explicit
  let base := psWellFoundedFixBase plan.relation [domainLevel, resultLevel] motive
  let actual ← psInferType environment metaContext locals base
  let functional ← psInferEnsureForall environment metaContext locals actual
  if !psWellFoundedDefEq environment metaContext locals functional.body plan.type then
    throw .applicationTypeMismatch
  return base

def psMutualWellFoundedFunctionalType (environment : PsEnvironment)
    (metaContext : PsMetaContext) (locals : PsLocalContext)
    (plan : PsMutualWellFoundedPlan) : Except PsInferError PsExpr := do
  let base ← psMutualWellFoundedFixBase environment metaContext locals plan
  let actual ← psInferType environment metaContext locals base
  let parameter ← psInferEnsureForall environment metaContext locals actual
  return parameter.domain

def psMutualWellFoundedBranchType (environment : PsEnvironment)
    (metaContext : PsMetaContext) (locals : PsLocalContext)
    (plan : PsMutualWellFoundedPlan) (index : Nat) : Except PsInferError PsExpr := do
  let type ← psMutualWellFoundedFunctionalType environment metaContext locals plan
  psMutualPackingProjectionType environment metaContext locals plan.types.length index type

structure PsMutualWellFoundedValue where
  functional : PsExpr
  value : PsExpr

def psMutualWellFoundedBuild (environment : PsEnvironment)
    (metaContext : PsMetaContext) (locals : PsLocalContext)
    (plan : PsMutualWellFoundedPlan) (branches : List PsExpr) :
    Except PsInferError PsMutualWellFoundedValue := do
  if branches.length != plan.types.length then throw .applicationTypeMismatch
  for (branch, index) in branches.zipIdx do
    let actual ← psInferType environment metaContext locals branch
    let expected ← psMutualWellFoundedBranchType environment metaContext locals plan index
    if !psWellFoundedDefEq environment metaContext locals actual expected then
      throw .applicationTypeMismatch
  let type ← psMutualWellFoundedFunctionalType environment metaContext locals plan
  let functional ← psMutualPackingUncurry environment metaContext locals type branches
  let base ← psMutualWellFoundedFixBase environment metaContext locals plan
  let value := PsExpr.app base functional
  let actual ← psInferType environment metaContext locals value
  if !psWellFoundedDefEq environment metaContext locals actual plan.type then
    throw .applicationTypeMismatch
  return { functional, value }
