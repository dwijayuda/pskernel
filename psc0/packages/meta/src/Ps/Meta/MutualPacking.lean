import Ps.Meta.Infer

/-!
Arity-owned disjoint-union packing, following Lean4.35.0
Lean/Meta/ArgsPacker.lean:Mutual, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) 2024 Lean FRO, LLC. Author: Joachim Breitner. Apache-2.0.
Unlike a type-driven flattening pass, the supplied member count stops at
the final original domain even when that domain is itself PSum.
-/

structure PsMutualPackingSum where
  levels : List PsLevel
  leftType : PsExpr
  rightType : PsExpr

def psMutualPackingSumView (type : PsExpr) : Option PsMutualPackingSum := do
  let view := psInferAppView type
  let .constE name levels := view.head | none
  if !psNameEq name (psRootName "PSum") || levels.length != 2 then none else do
    let [leftType, rightType] := view.args | none
    return { levels, leftType, rightType }

def psMutualPackingInjection (sum : PsMutualPackingSum) (left : Bool)
    (value : PsExpr) : PsExpr :=
  psReduceApply (.constE (psNameAppendStr (psRootName "PSum")
    (if left then "inl" else "inr")) sum.levels) [sum.leftType, sum.rightType, value]

def psMutualPackingDomain (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (domains : List PsExpr) : Except PsInferError PsExpr := do
  match domains with
  | [] => throw .expectedFunction
  | [domain] => return domain
  | domain :: next :: rest =>
    let tail ← psMutualPackingDomain environment metaContext locals (next :: rest)
    let leftSort ← psInferType environment metaContext locals domain
    let leftLevel ← psInferEnsureSort environment metaContext locals leftSort
    let rightSort ← psInferType environment metaContext locals tail
    let rightLevel ← psInferEnsureSort environment metaContext locals rightSort
    let type := psReduceApply (.constE (psRootName "PSum") [leftLevel, rightLevel])
      [domain, tail]
    let sort ← psInferType environment metaContext locals type
    let _ ← psInferEnsureSort environment metaContext locals sort
    return type

def psMutualPackingPack (arity : Nat) (domain : PsExpr) (index : Nat)
    (value : PsExpr) : Except PsInferError PsExpr := do
  match arity with
  | 0 => throw .applicationTypeMismatch
  | 1 =>
    if index != 0 then throw .applicationTypeMismatch
    return value
  | arity + 2 =>
    let some sum := psMutualPackingSumView domain | throw .applicationTypeMismatch
    match index with
    | 0 => return psMutualPackingInjection sum true value
    | index + 1 =>
      let tail ← psMutualPackingPack (arity + 1) sum.rightType index value
      return psMutualPackingInjection sum false tail

-- This is a syntactic view, not typing evidence. Consumers also check the
-- actual full application and member entry telescope in their real scope.
def psMutualPackingUnpack (arity : Nat) (domain value : PsExpr) :
    Option (Nat × PsExpr) := do
  match arity with
  | 0 => none
  | 1 => some (0, value)
  | arity + 2 =>
    let some sum := psMutualPackingSumView domain | none
    let view := psInferAppView value
    let [left, right, field] := view.args | none
    if !psExprAlphaEq left sum.leftType || !psExprAlphaEq right sum.rightType then none else do
      if psExprAlphaEq view.head (.constE (psNameAppendStr (psRootName "PSum") "inl") sum.levels) then
        some (0, field)
      else if psExprAlphaEq view.head (.constE (psNameAppendStr (psRootName "PSum") "inr") sum.levels) then do
        let (index, field) ← psMutualPackingUnpack (arity + 1) sum.rightType field
        return (index + 1, field)
      else none

-- The original alternatives own the arity. Every branch is constructed
-- using the actual dependent motive; the caller independently checks the
-- completed term against its declared type, as for unary tuple elimination.
def psMutualPackingCases (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (majorId : Nat) (codomain : PsExpr)
    (alternatives : List PsExpr) : Except PsInferError PsExpr := do
  let major := PsExpr.fvar majorId
  match alternatives with
  | [] => throw .expectedFunction
  | [alternative] => return .app alternative major
  | alternative :: next :: rest =>
    let type ← psInferType environment metaContext locals major
    let domain := psWhnf environment metaContext locals type
    let some sum := psMutualPackingSumView domain | throw .applicationTypeMismatch
    let sort ← psInferType environment metaContext locals codomain
    let level ← psInferEnsureSort environment metaContext locals sort
    let motive := PsExpr.lam (psRootName "_sum") domain
      (psExprAbstractFVar majorId codomain) .explicit
    let tail := psLocalPushBinding locals (psRootName "_tail") sum.rightType .explicit
    let injected := psMutualPackingInjection sum false (.fvar tail.id)
    let tailCodomain := psExprInstantiate1 (psExprAbstractFVar majorId codomain) injected
    let branch ← psMutualPackingCases environment metaContext tail.context tail.id
      tailCodomain (next :: rest)
    let alternativeRight := PsExpr.lam (psRootName "_tail") sum.rightType
      (psExprAbstractFVar tail.id branch) .explicit
    return psReduceApply (.constE (psNameAppendStr (psRootName "PSum") "casesOn")
      (level :: sum.levels)) [sum.leftType, sum.rightType, motive, major, alternative, alternativeRight]

-- Split exactly the owned component count, preserving a user PSum in the
-- final slot. This view is shared by projection types and callback adapters.
def psMutualPackingDomains (arity : Nat) (domain : PsExpr) :
    Except PsInferError (List PsExpr) := do
  match arity with
  | 0 => throw .expectedFunction
  | 1 => return [domain]
  | arity + 2 =>
    let some sum := psMutualPackingSumView domain | throw .applicationTypeMismatch
    return sum.leftType :: (← psMutualPackingDomains (arity + 1) sum.rightType)

-- The same result universe is required by native ArgsPacker.Mutual. Every
-- alternative is checked in its original domain, before constructing the
-- dependent sum motive. A mismatch is not hidden by a guessed universe.
def psMutualPackingCodomain (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (majorId : Nat) (types : List PsExpr) :
    Except PsInferError PsExpr := do
  if types.isEmpty then throw .expectedFunction
  let mut alternatives := []
  let mut commonLevel : Option PsLevel := none
  for type in types do
    let parameter ← psInferEnsureForall environment metaContext locals type
    let value := psLocalPushBinding locals parameter.name parameter.domain .explicit
    let result := psExprInstantiate1 parameter.body (.fvar value.id)
    let sort ← psInferType environment metaContext value.context result
    let level ← psInferEnsureSort environment metaContext value.context sort
    match commonLevel with
    | none => commonLevel := some level
    | some expected =>
      if !psLevelEquivalent level expected then throw .applicationTypeMismatch
    alternatives := alternatives ++ [PsExpr.lam parameter.name parameter.domain
      (psExprAbstractFVar value.id result) .explicit]
  let some level := commonLevel | throw .expectedFunction
  psMutualPackingCases environment metaContext locals majorId (.sortE level) alternatives

def psMutualPackingUncurryType (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (types : List PsExpr) : Except PsInferError PsExpr := do
  let parameters ← types.mapM (psInferEnsureForall environment metaContext locals)
  let domain ← psMutualPackingDomain environment metaContext locals (parameters.map (·.domain))
  let major := psLocalPushBinding locals (psRootName "_component") domain .explicit
  let codomain ← psMutualPackingCodomain environment metaContext major.context major.id types
  let type := PsExpr.forallE (psRootName "_component") domain
    (psExprAbstractFVar major.id codomain) .explicit
  let sort ← psInferType environment metaContext locals type
  let _ ← psInferEnsureSort environment metaContext locals sort
  return type

def psMutualPackingUncurry (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (type : PsExpr) (values : List PsExpr) :
    Except PsInferError PsExpr := do
  let parameter ← psInferEnsureForall environment metaContext locals type
  let major := psLocalPushBinding locals parameter.name parameter.domain .explicit
  let codomain := psExprInstantiate1 parameter.body (.fvar major.id)
  let body ← psMutualPackingCases environment metaContext major.context major.id codomain values
  let value := PsExpr.lam parameter.name parameter.domain
    (psExprAbstractFVar major.id body) parameter.binder
  let inferred ← psInferType environment metaContext locals value
  if !psDefEqReadOnlyWithEnv environment metaContext locals inferred type then
    throw .applicationTypeMismatch
  return value

def psMutualPackingProjection (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (arity index : Nat) (function : PsExpr) :
    Except PsInferError PsExpr := do
  let type ← psInferType environment metaContext locals function
  let parameter ← psInferEnsureForall environment metaContext locals type
  let domains ← psMutualPackingDomains arity parameter.domain
  let some domain := domains[index]? | throw .applicationTypeMismatch
  let argument := psLocalPushBinding locals parameter.name domain .explicit
  let packed ← psMutualPackingPack arity parameter.domain index (.fvar argument.id)
  let body := PsExpr.app function packed
  let _ ← psInferType environment metaContext argument.context body
  return .lam parameter.name domain (psExprAbstractFVar argument.id body) .explicit
