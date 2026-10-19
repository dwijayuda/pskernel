import Ps.Elab.Class

-- Selected source attributes follow Lean 4.35.0 Meta/Tactic/Simp/Attr.lean
-- and SimpTheorems.checkBadRewrite. This owner checks registration and keeps
-- typed declaration identities. Proof-producing simp execution belongs to M4.
-- Simp's global registration mode does not unfold semireducible definitions,
-- perform iota, reduce projections, or expand let-bound free variables.

def psElabSimpHasBound (target : Nat) : PsExpr → Bool
  | .bvar index => index == target
  | .app function argument =>
    psElabSimpHasBound target function || psElabSimpHasBound target argument
  | .lam _ type body _ | .forallE _ type body _ =>
    psElabSimpHasBound target type || psElabSimpHasBound (target + 1) body
  | .letE _ type value body =>
    psElabSimpHasBound target type || psElabSimpHasBound target value ||
      psElabSimpHasBound (target + 1) body
  | .proj _ _ value => psElabSimpHasBound target value
  | _ => false

def psElabSimpEta : PsExpr → PsExpr
  | .lam name type body binder =>
    let body := psElabSimpEta body
    match body with
    | .app function (.bvar 0) =>
      if !psElabSimpHasBound 0 function then
        psExprInstantiate1 function (.sortE .zero)
      else .lam name type body binder
    | _ => .lam name type body binder
  | expression => expression

def psElabSimpCoreWhnf (fuel : Nat) (expression : PsExpr) :
    Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw (.data "PSCV0-SIMP-ATTRIBUTE-BUDGET: head reduction")
  | fuel + 1 =>
    let view := psReduceAppView expression []
    match view.head, view.args with
    | .letE _ _ value body, arguments =>
      psElabSimpCoreWhnf fuel (psExprApplyMany (psExprInstantiate1 body value) arguments)
    | .lam _ _ body _, argument :: arguments =>
      psElabSimpCoreWhnf fuel (psExprApplyMany (psExprInstantiate1 body argument) arguments)
    | _, _ => pure expression

def psElabSimpBadHead : PsExpr → Bool
  | .lit _ | .constE _ _ | .fvar _ | .proj _ _ _ | .forallE _ _ _ _ => false
  | _ => true

def psElabSimpReduce (fuel : Nat) (root : Bool)
    (environment : PsEnvironment) (expression : PsExpr) :
    Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw (.data "PSCV0-SIMP-ATTRIBUTE-BUDGET: reducible traversal")
  | fuel + 1 =>
    let expression ← psElabSimpCoreWhnf 4096 expression
    let view := psReduceAppView expression []
    let unfolded ← match view.head with
      | .constE name levels =>
        if !psEnvironmentCanUnfold environment .reducible name then pure none
        else match psEnvironmentFind environment name with
          | some (.definitionDecl _ parameters _ value) =>
            if parameters.length != levels.length then throw .typeMismatch
            let value := psExprInstantiateLevelParams parameters levels value
            let value ← psElabSimpCoreWhnf 4096 (psExprApplyMany value view.args)
            if root && psElabSimpBadHead (psReduceAppView value []).head then pure none
            else pure (some value)
          | _ => pure none
      | _ => pure none
    if let some value := unfolded then
      return ← psElabSimpReduce fuel root environment value
    let eta := psElabSimpEta expression
    if psExprAlphaEq eta expression then return expression
    psElabSimpReduce fuel root environment eta

def psElabSimpCheckRewrite (environment : PsEnvironment) (left right : PsExpr) :
    Except PsElabError Unit := do
  let left ← psElabSimpReduce 4096 true environment left
  if let .fvar _ := left then
    if psExprAlphaEq left right then
      throw (.data "PSCV0-SIMP-ATTRIBUTE: equation is equivalent to variable reflexivity")

-- Native preprocessing splits conjunctions and opens forall telescopes before
-- checking Eq/Iff leaves. Other propositions become conditional True/False
-- rewrite rules when the proof-producing simplifier consumes this registry.
def psElabSimpCheckType (fuel : Nat) (environment : PsEnvironment)
    (locals : PsLocalContext) (type : PsExpr) : Except PsElabError Unit := do
  match fuel with
  | 0 => throw (.data "PSCV0-SIMP-ATTRIBUTE-BUDGET: proposition traversal")
  | fuel + 1 =>
    let type ← psElabSimpReduce 4096 false environment type
    match type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      psElabSimpCheckType fuel environment pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | _ =>
      let view := psReduceAppView type []
      match view.head, view.args with
      | .constE name _, [_, left, right] =>
        if psNameEq name psEqName then psElabSimpCheckRewrite environment left right
        else pure ()
      | .constE name _, [left, right] =>
        if psNameEq name (psRootName "Iff") then
          psElabSimpCheckRewrite environment left right
        else if psNameEq name (psRootName "And") then do
          psElabSimpCheckType fuel environment locals left
          psElabSimpCheckType fuel environment locals right
        else pure ()
      | _, _ => pure ()

def psElabRegisterSimp (environment : PsEnvironment) (name : PsName) :
    Except PsElabError PsEnvironment := do
  let some declaration := psEnvironmentFind environment name
    | throw (.data "PSCV0-SIMP-ATTRIBUTE: declaration is missing")
  let type := psDeclarationType declaration
  let context := psElabContextEmpty environment (psDeclarationLevelParams declaration)
  let level ← psElabExpressionSort context type
  let kind ← if psLevelEquivalent level .zero then do
    psElabSimpCheckType 4096 environment psLocalEmpty type
    pure PsSimpEntryKind.proof
  else match declaration with
    | .definitionDecl .. => pure PsSimpEntryKind.unfoldDefinition
    | _ => throw (.data "PSCV0-SIMP-ATTRIBUTE: expected proposition or definition")
  return { environment with
    simpEntries := psSimpEntriesAdd environment.simpEntries { name, kind } }

def psElabApplySourceAttributes (environment : PsEnvironment) (name : PsName)
    (attributes : List PsSyntaxAttribute) : Except PsElabError PsEnvironment :=
  attributes.foldlM (fun environment attribute => match attribute with
    | .simpAttribute => psElabRegisterSimp environment name
    | .instanceAttribute => psElabRegisterInstance environment name 1000
    | .defaultInstanceAttribute priority =>
      psElabRegisterDefaultInstance environment name priority) environment
