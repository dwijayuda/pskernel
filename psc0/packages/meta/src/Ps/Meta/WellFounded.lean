import Ps.Meta.Infer

/-!
Checked well-founded construction shared by elaboration and typed erasure.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Lean/Elab/PreDefinition/WF/Rel.lean:57-69 and WF/Fix.lean:281-319.
The source owner supplies the already checked unary domain and measure.
This owner selects the actual dictionary, relation, fixpoint and equation
shape. The arity-aware telescope helpers below share its checked domain
encoding; they do not choose source parameters or prove a call decreases.
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

/-
The selected dependent unary encoding follows ArgsPacker.Unary in pinned
Lean/Meta/ArgsPacker.lean:65-95,133-183. This view owns exactly one PSigma
layer; a user-supplied PSigma field is never recursively flattened.
Every consumer checks the complete constructed term in its actual context.
-/
def psWellFoundedPairName : PsName := psRootName "PSigma"

structure PsWellFoundedPairPacking where
  levels : List PsLevel
  firstType : PsExpr
  secondFamily : PsExpr

def psWellFoundedPairPackingView (type : PsExpr) : Option PsWellFoundedPairPacking := do
  let view := psInferAppView type
  let .constE name levels := view.head | none
  if !psNameEq name psWellFoundedPairName || levels.length != 2 then none else do
    let [firstType, secondFamily] := view.args | none
    return { levels, firstType, secondFamily }

def psWellFoundedPairType (packing : PsWellFoundedPairPacking) : PsExpr :=
  psReduceApply (.constE psWellFoundedPairName packing.levels)
    [packing.firstType, packing.secondFamily]

def psWellFoundedPairTypeChecked (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (firstType secondFamily : PsExpr) :
    Except PsInferError PsExpr := do
  let firstSort ← psInferType environment metaContext locals firstType
  let firstLevel ← psInferEnsureSort environment metaContext locals firstSort
  let familyType ← psInferType environment metaContext locals secondFamily
  let family ← psInferEnsureForall environment metaContext locals familyType
  if !psWellFoundedDefEq environment metaContext locals family.domain firstType then
    throw .applicationTypeMismatch
  let first := psLocalPushBinding locals family.name firstType family.binder
  let secondLevel ← psInferEnsureSort environment metaContext first.context
    (psExprInstantiate1 family.body (.fvar first.id))
  let type := psWellFoundedPairType {
    levels := [firstLevel, secondLevel], firstType, secondFamily }
  let sort ← psInferType environment metaContext locals type
  let _ ← psInferEnsureSort environment metaContext locals sort
  return type

-- Owned packing layers use a manifest lambda family. Instantiate it before
-- inspecting the next layer; psReduceApply only builds applications and does
-- not perform beta reduction. Leave an arbitrary final user family opaque.
def psWellFoundedPairTailType (packing : PsWellFoundedPairPacking) (first : PsExpr) : PsExpr :=
  match packing.secondFamily with
  | .lam _ _ body _ => psExprInstantiate1 body first
  | family => .app family first

def psWellFoundedPairPack (packing : PsWellFoundedPairPacking)
    (first second : PsExpr) : PsExpr :=
  psReduceApply (.constE (psNameAppendStr psWellFoundedPairName "mk") packing.levels)
    [packing.firstType, packing.secondFamily, first, second]

def psWellFoundedPairFirst (value : PsExpr) : PsExpr :=
  .proj psWellFoundedPairName 0 value

def psWellFoundedPairSecond (value : PsExpr) : PsExpr :=
  .proj psWellFoundedPairName 1 value

def psWellFoundedPairCases (packing : PsWellFoundedPairPacking)
    (resultLevel : PsLevel) (motive major minor : PsExpr) : PsExpr :=
  psReduceApply (.constE (psNameAppendStr psWellFoundedPairName "casesOn")
    (resultLevel :: packing.levels))
    [packing.firstType, packing.secondFamily, motive, major, minor]

-- Only the manifest constructor shape produced by pack is viewed as a pair
-- entry. The caller still checks its actual type and original entry slots.
def psWellFoundedPairUnpack (packing : PsWellFoundedPairPacking)
    (value : PsExpr) : Option (PsExpr × PsExpr) := do
  let view := psInferAppView value
  if !psExprAlphaEq view.head
      (.constE (psNameAppendStr psWellFoundedPairName "mk") packing.levels) then none else do
    let [firstType, secondFamily, first, second] := view.args | none
    if !psExprAlphaEq firstType packing.firstType ||
        !psExprAlphaEq secondFamily packing.secondFamily then none
    else some (first, second)

/-!
N-ary dependent packing adapts Lean/Meta/ArgsPacker.Unary (4.35.0).
Arity is supplied by the owned telescope, never inferred from a user type.
The last field is left intact even when it is itself a PSigma.
-/

def psWellFoundedTupleTypeChecked (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (values : List PsExpr) : Except PsInferError PsExpr := do
  match values with
  | [] => throw .expectedFunction
  | [value] => psInferType environment metaContext locals value
  | first :: second :: rest =>
    let .fvar id := first | throw .applicationTypeMismatch
    let some declaration := psLocalFindById locals id | throw .applicationTypeMismatch
    let firstType ← psInferType environment metaContext locals first
    let tailType ← psWellFoundedTupleTypeChecked environment metaContext locals (second :: rest)
    let family := PsExpr.lam (psLocalDeclUserName declaration) firstType
      (psExprAbstractFVar id tailType) .explicit
    psWellFoundedPairTypeChecked environment metaContext locals firstType family

def psWellFoundedTuplePack (domain : PsExpr) (values : List PsExpr) :
    Except PsInferError PsExpr := do
  match values with
  | [] => throw .expectedFunction
  | [value] => return value
  | first :: second :: rest =>
    let some packing := psWellFoundedPairPackingView domain | throw .applicationTypeMismatch
    let tailDomain := psWellFoundedPairTailType packing first
    let tail ← psWellFoundedTuplePack tailDomain (second :: rest)
    return psWellFoundedPairPack packing first tail

def psWellFoundedTupleProjections (arity : Nat) (value : PsExpr) : List PsExpr :=
  match arity with
  | 0 => []
  | 1 => [value]
  | n + 2 => psWellFoundedPairFirst value ::
      psWellFoundedTupleProjections (n + 1) (psWellFoundedPairSecond value)

structure PsWellFoundedTupleBinder where
  id : Nat
  name : PsName
  type : PsExpr

def psWellFoundedTupleLambdas (binders : List PsWellFoundedTupleBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    .lam binder.name binder.type (psExprAbstractFVar binder.id body) .explicit) body

def psWellFoundedTupleForalls (binders : List PsWellFoundedTupleBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    .forallE binder.name binder.type (psExprAbstractFVar binder.id body) .explicit) body

def psWellFoundedTupleOpen (locals : PsLocalContext) (domain : PsExpr)
    (names : List PsName) : Except PsInferError (PsLocalContext × List PsWellFoundedTupleBinder) := do
  match names with
  | [] => throw .expectedFunction
  | [name] =>
    let pushed := psLocalPushBinding locals name domain .explicit
    return (pushed.context, [{ id := pushed.id, name, type := domain }])
  | name :: next :: rest =>
    let some packing := psWellFoundedPairPackingView domain | throw .applicationTypeMismatch
    let pushed := psLocalPushBinding locals name packing.firstType .explicit
    let tailDomain := psWellFoundedPairTailType packing (.fvar pushed.id)
    let (inner, tail) ← psWellFoundedTupleOpen pushed.context tailDomain (next :: rest)
    return (inner, { id := pushed.id, name, type := packing.firstType } :: tail)

def psWellFoundedTupleCurryType (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (names : List PsName) (callbackType : PsExpr) :
    Except PsInferError PsExpr := do
  let parameter ← psInferEnsureForall environment metaContext locals callbackType
  let (_, binders) ← psWellFoundedTupleOpen locals parameter.domain names
  let packed ← psWellFoundedTuplePack parameter.domain (binders.map fun binder => .fvar binder.id)
  let type := psWellFoundedTupleForalls binders (psExprInstantiate1 parameter.body packed)
  let sort ← psInferType environment metaContext locals type
  let _ ← psInferEnsureSort environment metaContext locals sort
  return type

-- Retain an explicit proof lambda: the exact same adapter is reconstructed by
-- erasure and is checked against the complete source callback telescope.
def psWellFoundedTupleCurryCallback (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (names : List PsName) (sourceType callback : PsExpr) :
    Except PsInferError PsExpr := do
  let callbackType ← psInferType environment metaContext locals callback
  let parameter ← psInferEnsureForall environment metaContext locals callbackType
  let (inner, binders) ← psWellFoundedTupleOpen locals parameter.domain names
  let packed ← psWellFoundedTuplePack parameter.domain (binders.map fun binder => .fvar binder.id)
  let proof ← psInferEnsureForall environment metaContext inner
    (psExprInstantiate1 parameter.body packed)
  let evidence := psLocalPushBinding inner proof.name proof.domain proof.binder
  let body := psReduceApply callback [packed, .fvar evidence.id]
  let value := psWellFoundedTupleLambdas binders
    (.lam proof.name proof.domain (psExprAbstractFVar evidence.id body) proof.binder)
  let inferred ← psInferType environment metaContext locals value
  if !psWellFoundedDefEq environment metaContext locals inferred sourceType then
    throw .applicationTypeMismatch
  return value

-- Iterated dependent elimination, not projection substitution plus an eta
-- conversion rule. The major is an actual local; codomain may depend on it.
def psWellFoundedTupleCases (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (names : List PsName) (majorId : Nat)
    (resultLevel : PsLevel) (codomain alternative : PsExpr) : Except PsInferError PsExpr := do
  let major := PsExpr.fvar majorId
  match names with
  | [] => throw .expectedFunction
  | [_] => return psReduceApply alternative [major]
  | firstName :: nextName :: rest =>
    let domain ← psInferType environment metaContext locals major
    let some packing := psWellFoundedPairPackingView
        (psWhnf environment metaContext locals domain) | throw .applicationTypeMismatch
    let motive := PsExpr.lam (psRootName "_packed") domain
      (psExprAbstractFVar majorId codomain) .explicit
    let first := psLocalPushBinding locals firstName packing.firstType .explicit
    let tailDomain := psWellFoundedPairTailType packing (.fvar first.id)
    let tail := psLocalPushBinding first.context nextName tailDomain .explicit
    let constructed := psWellFoundedPairPack packing (.fvar first.id) (.fvar tail.id)
    let innerCodomain := psReduceApply motive [constructed]
    let inner ← psWellFoundedTupleCases environment metaContext tail.context
      (nextName :: rest) tail.id resultLevel innerCodomain
      (psReduceApply alternative [.fvar first.id])
    let minor := PsExpr.lam firstName packing.firstType
      (psExprAbstractFVar first.id (.lam nextName tailDomain
        (psExprAbstractFVar tail.id inner) .explicit)) .explicit
    return psWellFoundedPairCases packing resultLevel motive major minor
