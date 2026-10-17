import Ps.Meta.Infer

/-!
Checked well-founded construction shared by elaboration and typed erasure.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Lean/Elab/PreDefinition/WF/Rel.lean:57-69 and WF/Fix.lean:281-319.
The source owner supplies the already checked unary domain and measure.
This owner selects the actual dictionary, relation, fixpoint and equation
shape; it does not pack arguments or prove that a recursive call decreases.
-/

-- Keep the established names for the qualified Nat specialization.
def psWellFoundedFixName : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "WellFounded") "Nat") "fix"

def psWellFoundedFixEqName : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "WellFounded") "Nat") "fix_eq"

def psWellFoundedGenericFixName : PsName :=
  psNameAppendStr (psRootName "WellFounded") "fix"

def psWellFoundedGenericFixEqName : PsName :=
  psNameAppendStr (psRootName "WellFounded") "fix_eq"

def psWellFoundedRelationName : PsName := psRootName "WellFoundedRelation"

inductive PsWellFoundedConstruction where
  | natMeasure (measure : PsExpr)
  | relation (relation wellFounded : PsExpr)

structure PsWellFoundedRelationPlan where
  domain : PsExpr
  construction : PsWellFoundedConstruction

def psWellFoundedConstructionArguments : PsWellFoundedConstruction → List PsExpr
  | .natMeasure measure => [measure]
  | .relation relation wellFounded => [relation, wellFounded]

def psWellFoundedConstructionFixName : PsWellFoundedConstruction → PsName
  | .natMeasure _ => psWellFoundedFixName
  | .relation _ _ => psWellFoundedGenericFixName

def psWellFoundedConstructionEquationName : PsWellFoundedConstruction → PsName
  | .natMeasure _ => psWellFoundedFixEqName
  | .relation _ _ => psWellFoundedGenericFixEqName

def psWellFoundedPlanMap (f : PsExpr → PsExpr) (plan : PsWellFoundedRelationPlan) :
    PsWellFoundedRelationPlan :=
  { domain := f plan.domain
    construction := match plan.construction with
      | .natMeasure measure => .natMeasure (f measure)
      | .relation relation wellFounded => .relation (f relation) (f wellFounded) }

def psWellFoundedPlanTerms (plan : PsWellFoundedRelationPlan) : List PsExpr :=
  plan.domain :: psWellFoundedConstructionArguments plan.construction

def psWellFoundedDecreases (plan : PsWellFoundedRelationPlan)
    (smaller current : PsExpr) : PsExpr :=
  match plan.construction with
  | .natMeasure measure =>
    psReduceApply (.constE (psNameAppendStr psNatName "lt") [])
      [.app measure smaller, .app measure current]
  | .relation relation _ => psReduceApply relation [smaller, current]

-- Use the existing typed, read-only conversion rule. Proof irrelevance is
-- needed for the real sizeOfWFRel/Nat instance proof; no meta is assigned.
def psWellFoundedDefEq (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (left right : PsExpr) : Bool :=
  psDefEqReadOnlyWithTransparencyProofs .«default» environment metaContext
    (psInferGroundProofIrrelevanceAt .«default» (psInferType environment metaContext)
      environment metaContext) 256 locals left right

def psWellFoundedPlanForMeasure (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (domain codomain measure dictionary : PsExpr) :
    Except PsInferError PsWellFoundedRelationPlan := do
  let domainSort ← psInferType environment metaContext locals domain
  let domainLevel ← psInferEnsureSort environment metaContext locals domainSort
  let codomainSort ← psInferType environment metaContext locals codomain
  let codomainLevel ← psInferEnsureSort environment metaContext locals codomainSort
  let pulled := psReduceApply (.constE (psRootName "invImage") [domainLevel, codomainLevel])
    [domain, codomain, measure, dictionary]
  -- Inference checks the actual measure domain/codomain and dictionary type.
  let pulledType ← psInferType environment metaContext locals pulled
  let expected := PsExpr.app (.constE psWellFoundedRelationName [domainLevel]) domain
  if !psWellFoundedDefEq environment metaContext locals pulledType expected then
    throw .applicationTypeMismatch
  let nat := PsExpr.constE psNatName []
  let natRelation := PsExpr.constE (psNameAppendStr psNatName "lt_wfRel") []
  let construction := if psWellFoundedDefEq environment metaContext locals codomain nat &&
      psWellFoundedDefEq environment metaContext locals dictionary natRelation then
    PsWellFoundedConstruction.natMeasure measure
  else
    -- Both projections retain the real checked inverse-image dictionary.
    -- Lean's opaqueId proof barrier is not in this selected closure; the
    -- direct proof remains checked by inference and kernel admission.
    .relation (.proj psWellFoundedRelationName 0 pulled)
      (.proj psWellFoundedRelationName 1 pulled)
  return { domain, construction }

def psWellFoundedFixBase (plan : PsWellFoundedRelationPlan)
    (levels : List PsLevel) (motive : PsExpr) : PsExpr :=
  psReduceApply (.constE (psWellFoundedConstructionFixName plan.construction) levels)
    ([plan.domain, motive] ++ psWellFoundedConstructionArguments plan.construction)

def psWellFoundedEquation (plan : PsWellFoundedRelationPlan)
    (levels : List PsLevel) (motive functional major : PsExpr) : PsExpr :=
  psReduceApply (.constE (psWellFoundedConstructionEquationName plan.construction) levels)
    ([plan.domain, motive] ++ psWellFoundedConstructionArguments plan.construction ++
      [functional, major])

structure PsWellFoundedFixApplication where
  plan : PsWellFoundedRelationPlan
  levels : List PsLevel
  motive : PsExpr
  functional : PsExpr
  major : PsExpr
  arguments : List PsExpr

-- This is a view of the actual Core application, never source metadata.
-- The consumer still validates the complete application in its real context
-- and requires exact agreement with the checked root declaration entry.
def psWellFoundedFixApplicationView (head : PsExpr) (arguments : List PsExpr) :
    Except PsInferError (Option PsWellFoundedFixApplication) := do
  let .constE name levels := head | return none
  if !psNameEq name psWellFoundedFixName && !psNameEq name psWellFoundedGenericFixName then
    return none
  if levels.length != 2 then throw (.incorrectUniverseArity name)
  if psNameEq name psWellFoundedFixName then
    let domain :: motive :: measure :: functional :: major :: rest := arguments
      | throw .expectedFunction
    return some {
      plan := { domain, construction := .natMeasure measure }
      levels := levels
      motive := motive
      functional := functional
      major := major
      arguments := rest }
  else
    let domain :: motive :: relation :: wellFounded :: functional :: major :: rest := arguments
      | throw .expectedFunction
    return some {
      plan := { domain, construction := .relation relation wellFounded }
      levels := levels
      motive := motive
      functional := functional
      major := major
      arguments := rest }
