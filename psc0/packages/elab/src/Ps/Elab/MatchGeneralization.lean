import Ps.Elab.Refinement
import Ps.Elab.ExprAbstraction

/-
Optional source-match generalization follows Lean 4.35.0
Meta/GeneralizeVars.lean, Elab/Match.lean and Meta/KAbstract.lean.
Pinned reference: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) 2020-2021 Microsoft Corporation. Released under Apache 2.0.
The PsExpr implementation and explicit lexical ownership below are PSC0 code.
-/

def psElabSourceMatchLocalDependencies (context : PsElabContext)
    (declaration : PsLocalDecl) : List Nat :=
  let type := psMetaInstantiate context.metaContext (psLocalDeclType declaration)
  let values := match declaration with
    | .binding .. => []
    | .letDecl _ _ _ value => psExprFVarIds (psMetaInstantiate context.metaContext value)
  (psExprFVarIds type ++ values).eraseDups

-- Seed computed-major type dependencies before visiting source fvar roots.
-- Preserve the pinned native loop's visited-set behavior: dependencies are
-- marked when discovered, so an already marked root is not revisited.
-- Runtime aliases and computed-major value dependencies are not source roots.
def psElabSourceMatchForbidden (context : PsElabContext)
    (majors : List (PsExpr × PsExpr)) : List Nat :=
  let forbidden := (majors.flatMap (fun entry =>
    match entry.fst with | .fvar _ => [] | _ => psExprFVarIds entry.snd)).eraseDups
  majors.foldl (fun forbidden entry =>
    match entry.fst with
    | .fvar id =>
      if forbidden.contains id then forbidden else
        let dependencies := match psLocalFindById context.localContext id with
          | some declaration => psElabSourceMatchLocalDependencies context declaration
          | none => [] -- The caller has already inferred every source major.
        (id :: (dependencies ++ forbidden)).eraseDups
    | _ => forbidden) forbidden

-- Source policy needs native may-dependencies: an unassigned metavariable
-- may use any local in its saved scope. Free-variable occurrences do not unfold
-- their local let values. This does not change mandatory refinement transport.
-- Only beta steps exposed by an assigned metavariable head are reduced here.
def psElabSourceMatchApplyMetaWithFuel (metaContext : PsMetaContext) :
    Nat → PsExpr → List PsExpr → Except PsElabError PsExpr
  | 0, _, _ => throw .fuelExhausted
  | fuel + 1, fn, args => do
    let view := psReduceAppView fn args
    match view.head with
    | .mvar id =>
      match psMetaFindAssignment metaContext id with
      | some value => psElabSourceMatchApplyMetaWithFuel metaContext fuel value view.args
      | none => return psReduceApply view.head view.args
    | .lam _ _ body _ =>
      match view.args with
      | argument :: rest =>
        psElabSourceMatchApplyMetaWithFuel metaContext fuel
          (psExprInstantiate1 body argument) rest
      | [] => return view.head
    | _ => return psReduceApply view.head view.args

def psElabSourceMatchExprMayDependWithFuel (context : PsElabContext)
    (roots : List Nat) : Nat → PsExpr → Except PsElabError Bool
  | 0, _ => throw .fuelExhausted
  | fuel + 1, term => do
    let visit := psElabSourceMatchExprMayDependWithFuel context roots fuel
    match term with
    | .fvar id => return roots.contains id
    | .mvar id =>
      match psMetaFindAssignment context.metaContext id with
      | some value => visit value
      | none =>
        let some declaration := psMetaFindDecl context.metaContext id
          | throw (.infer (.unknownMetavariable id))
        return declaration.localContext.declarations.any fun localDecl =>
          roots.contains (psLocalDeclId localDecl)
    | .app fn arg =>
      let view := psReduceAppView term []
      match view.head with
      | .mvar id =>
        match psMetaFindAssignment context.metaContext id with
        | some value =>
          let term ← psElabSourceMatchApplyMetaWithFuel context.metaContext fuel value view.args
          visit term
        | none => if (← visit fn) then return true else visit arg
      | _ => if (← visit fn) then return true else visit arg
    | .lam _ type body _ | .forallE _ type body _ =>
      if (← visit type) then return true else visit body
    | .letE _ type value body =>
      if (← visit type) then return true else
      if (← visit value) then return true else visit body
    | .proj _ _ value => visit value
    | _ => return false

def psElabSourceMatchExprMayDepend (context : PsElabContext)
    (roots : List Nat) (term : PsExpr) : Except PsElabError Bool :=
  psElabSourceMatchExprMayDependWithFuel context roots psInferDefaultFuel term

def psElabSourceMatchLocalMayDepend (context : PsElabContext)
    (roots : List Nat) (declaration : PsLocalDecl) : Except PsElabError Bool := do
  if (← psElabSourceMatchExprMayDepend context roots (psLocalDeclType declaration)) then
    return true
  match declaration with
  | .binding .. => return false
  | .letDecl _ _ _ value => psElabSourceMatchExprMayDepend context roots value

-- This is optional source policy. Mandatory equality/index transport keeps its
-- separate psElabDependentLocals owner, including the let values it needs.
def psElabSourceMatchLocals (context : PsElabContext) (roots forbidden : List Nat) :
    Except PsElabError (List PsElabTypedBinder) := do
  let selected ← context.localContext.declarations.reverse.foldlM
    (fun (state : List Nat × List PsElabTypedBinder) declaration => do
      match declaration with
      | .letDecl .. => return state
      | .binding id name sourceType binder =>
        if forbidden.contains id || context.auxiliaryLocalIds.contains id ||
            psBinderInfoEq binder .instanceImplicit then return state
        if !(← psElabSourceMatchExprMayDepend context state.fst sourceType) then return state
        let type := psMetaInstantiate context.metaContext sourceType
        return (id :: state.fst, PsElabTypedBinder.mk id name type binder :: state.snd))
    (roots, [])
  return selected.snd.reverse

-- Test this exact de Bruijn binder, including its shifted position under
-- nested binders. Other surrounding locals do not keep an unused let alive.
def psElabSourceMatchUsesBinder (term : PsExpr) (index : Nat := 0) : Bool :=
  match term with
  | .bvar actual => actual == index
  | .app fn arg =>
    psElabSourceMatchUsesBinder fn index || psElabSourceMatchUsesBinder arg index
  | .lam _ type body _ | .forallE _ type body _ =>
    psElabSourceMatchUsesBinder type index || psElabSourceMatchUsesBinder body (index + 1)
  | .letE _ type value body =>
    psElabSourceMatchUsesBinder type index || psElabSourceMatchUsesBinder value index ||
      psElabSourceMatchUsesBinder body (index + 1)
  | .proj _ _ value => psElabSourceMatchUsesBinder value index
  | _ => false

-- The native match-type builder removes unused lets from major domains.
def psElabSourceMatchPruneLets (term : PsExpr) : PsExpr :=
  match term with
  | .app fn arg => .app (psElabSourceMatchPruneLets fn) (psElabSourceMatchPruneLets arg)
  | .lam name type body binder =>
    .lam name (psElabSourceMatchPruneLets type) (psElabSourceMatchPruneLets body) binder
  | .forallE name type body binder =>
    .forallE name (psElabSourceMatchPruneLets type) (psElabSourceMatchPruneLets body) binder
  | .letE name type value body =>
    let body := psElabSourceMatchPruneLets body
    if psElabSourceMatchUsesBinder body 0 then
      .letE name (psElabSourceMatchPruneLets type) (psElabSourceMatchPruneLets value) body
    else psExprInstantiate1 body value
  | .proj name index value => .proj name index (psElabSourceMatchPruneLets value)
  | _ => term

-- First build the original match telescope. Computed-major occurrences are
-- abstracted here, before optional locals are inserted. Required abstraction
-- failures propagate; they cannot become an unabstracted fallback telescope.
def psElabSourceMatchBaseType (context : PsElabContext)
    (majors : List (PsExpr × PsExpr)) (expected : PsExpr) :
    Except PsElabError (PsElabContext × PsExpr) := do
  match majors with
  | [] => return (context, psMetaInstantiate context.metaContext expected)
  | (major, type) :: rest =>
    let (context, body) ← psElabSourceMatchBaseType context rest expected
    let (context, body) ← psElabKeyAbstract context major body .«default»
    let type := psElabSourceMatchPruneLets (psMetaInstantiate context.metaContext type)
    return (context, .forallE (psRootName "_match") type body .explicit)

-- Open exactly the major prefix. Only original direct source fvars receive
-- replacements when the new dependent-local telescope is inserted. Prepending
-- gives repeated source fvars the last-major precedence of native abstract.
def psElabSourceMatchOpenMajors (majors : List PsExpr) (context : PsElabContext)
    (type : PsExpr) (bindersRev : List PsElabTypedBinder := [])
    (replacements : List (Nat × PsExpr) := []) :
    Except PsElabError (PsElabOpenTelescope × List (Nat × PsExpr)) := do
  match majors with
  | [] => return ({ context, bindersRev, body := type }, replacements)
  | major :: rest =>
    let .forallE _ domain body binder := type
      | throw (.infer .expectedFunction)
    let name := psNameAppendNum (psRootName "$psc0MatchDiscriminant") context.localContext.nextId
    let pushed := psLocalPushBinding context.localContext name domain binder
    let replacements := match major with
      | .fvar id => (id, PsExpr.fvar pushed.id) :: replacements
      | _ => replacements
    psElabSourceMatchOpenMajors rest (psElabContextWithLocal context pushed.context)
      (psExprInstantiate1 body (.fvar pushed.id))
      (PsElabTypedBinder.mk pushed.id name domain binder :: bindersRev) replacements

structure PsElabSourceMatchPlan where
  context : PsElabContext
  rawMajors : List PsExpr
  majorTypes : List PsExpr
  selectedIds : List Nat
  matchType : PsExpr

-- Select optional locals against an existing complete base telescope. Optional
-- binding may repair dependencies in that base, so check the chosen telescope,
-- not an unrepaired base before selection. Index retries do not rebuild domains.
def psElabSourceMatchGeneralizationFromType (context : PsElabContext)
    (rawMajors majorTypes : List PsExpr) (baseMatchType : PsExpr)
    (generalizing? : Option Bool) : Except PsElabError PsElabSourceMatchPlan := do
  if rawMajors.length != majorTypes.length then
    throw (.refinement "source match major/type metadata arity mismatch")
  let matchType := psMetaInstantiate context.metaContext baseMatchType
  let majorTypes := majorTypes.map (psMetaInstantiate context.metaContext)
  let typed := rawMajors.zip majorTypes
  let base : PsElabSourceMatchPlan := {
    context, rawMajors, majorTypes, selectedIds := [], matchType }
  let checkedBase : Unit → Except PsElabError PsElabSourceMatchPlan := fun _ => do
    let _ ← psElabExpressionSort context matchType
    return base
  if !(generalizing?.getD true) then checkedBase () else do
    let roots := rawMajors.filterMap fun major =>
      match major with | .fvar id => some id | _ => none
    let selected ← psElabSourceMatchLocals context roots (psElabSourceMatchForbidden context typed)
    if selected.isEmpty then checkedBase () else do
      let (opened, replacements) ← psElabSourceMatchOpenMajors rawMajors context matchType
      let body := selected.foldr (fun binder body =>
        .forallE binder.name binder.type (psExprAbstractFVar binder.id body) binder.binder) opened.body
      let body := psElabSubstituteLocals replacements body
      let proposed := psCloseElabForallBinders context.metaContext opened.bindersRev body
      -- Check the COMPLETE proposed telescope in the original scope. Only an
      -- ill-typed optional extension may fall back to a separately checked base.
      match psElabExpressionSort context proposed with
      | .ok _ => return { base with selectedIds := selected.map (·.id), matchType := proposed }
      | .error error => if psElabErrorIsResource error then throw error else checkedBase ()

-- The initial source Matrix builds the base once. Required key-abstraction
-- assignments travel with the returned plan; failures propagate.
def psElabSourceMatchGeneralization (context : PsElabContext) (majors : List PsExpr)
    (expected : PsExpr) (generalizing? : Option Bool) :
    Except PsElabError PsElabSourceMatchPlan := do
  let majors := majors.map (psMetaInstantiate context.metaContext)
  let typed ← majors.mapM fun major => do
    let type ← (psInferType context.environment context.metaContext context.localContext major).mapError
      PsElabError.infer
    return (major, psMetaInstantiate context.metaContext type)
  let (context, baseMatchType) ← psElabSourceMatchBaseType context typed expected
  psElabSourceMatchGeneralizationFromType context majors (typed.map Prod.snd)
    baseMatchType generalizing?

-- Pinned Elab.Match.collectDeps: one pass over variables occurring in current
-- major TYPES; dependence is tested against only the originally requested
-- fvar indices. Preserve lexical order and the non-fvar suffix.
def psElabSourceMatchIndexDependencies (context : PsElabContext)
    (indices majors : List PsExpr) : Except PsElabError (List PsExpr) := do
  let indexIds := indices.filterMap fun index =>
    match index with | .fvar id => some id | _ => none
  let majorIds := majors.filterMap fun major =>
    match major with | .fvar id => some id | _ => none
  let candidates ← majors.foldlM (fun ids major => do
    let type ← (psInferType context.environment context.metaContext context.localContext major).mapError
      PsElabError.infer
    return (ids ++ psExprFVarIds (psMetaInstantiate context.metaContext type)).eraseDups) []
  let toAdd ← candidates.foldlM (fun added id => do
    if majorIds.contains id || indexIds.contains id then return added
    let some declaration := psLocalFindById context.localContext id
      | throw (.infer (.unknownFreeVariable id))
    indexIds.foldlM (fun added root => do
      if (← psElabSourceMatchLocalMayDepend context [root] declaration) then
        return id :: added
      else return added) added) []
  for id in indexIds do
    if (psLocalFindById context.localContext id).isNone then
      throw (.infer (.unknownFreeVariable id))
  let wanted := indexIds ++ toAdd
  let sorted := context.localContext.declarations.reverse.flatMap fun declaration =>
    wanted.filterMap fun id =>
      if psLocalDeclId declaration == id then some (PsExpr.fvar id) else none
  let nonFVars := indices.filter fun index =>
    match index with | .fvar _ => false | _ => true
  return sorted ++ nonFVars

-- Native updateMatchType prefixes an existing complete base telescope. Unlike
-- the initial match builder, it does not prune lets from added index domains.
def psElabSourceMatchPrefixIndicesWorker (context : PsElabContext)
    (indices : List PsExpr) (matchType : PsExpr) :
    Except PsElabError (PsElabContext × PsExpr) := do
  match indices with
  | [] => return (context, matchType)
  | index :: rest =>
    let (context, matchType) ← psElabSourceMatchPrefixIndicesWorker context rest matchType
    let indexType ← (psInferType context.environment context.metaContext context.localContext index).mapError
      PsElabError.infer
    let (context, body) ← psElabKeyAbstract context index matchType .«default»
    let name := match index with
      | .fvar id =>
        match psLocalFindById context.localContext id with
        | some declaration => psLocalDeclUserName declaration
        | none => psRootName "_matchIndex"
      | _ => psRootName "_matchIndex"
    return (context, .forallE name (psMetaInstantiate context.metaContext indexType) body .explicit)

def psElabSourceMatchPrefixIndices (context : PsElabContext)
    (indices : List PsExpr) (matchType : PsExpr) :
    Except PsElabError (PsElabContext × PsExpr) := do
  let (context, matchType) ← psElabSourceMatchPrefixIndicesWorker context indices matchType
  let matchType := psMetaInstantiate context.metaContext matchType
  let _ ← psElabExpressionSort context matchType
  return (context, matchType)
