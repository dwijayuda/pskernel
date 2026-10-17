import Ps.Meta.Infer

/-!
Search-table identity follows Lean 4.35.0 Lean/Meta/SynthInstance.lean
(MkTableKey): structural equality is sufficient; definitionally equal but
structurally different goals may have separate generators. Hashes never supply
evidence. PSC0's ready goals have no input metavariables and already mask output
arguments/levels, so no assignable-meta renaming pass is needed here.

A bounded, read-only instances-transparent normalization preserves sharing of
selected reducible wrappers (e.g. optParam) before structural indexing. It is
an optimization, not a complete conversion decision. No target, local context
or speculative assignment is rewritten. Algorithms independently authored;
Lean project reference licensed Apache-2.0.
-/
-- Table identity must not execute primitive arithmetic or recursive runtime
-- computations inside a type index. Only beta/zeta/permitted delta reduction
-- is useful here. Matching candidates still uses the full checked unifier.
private def psInstanceKeyHead (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) : Nat → PsExpr → PsExpr
  | 0, value => value
  | fuel + 1, value =>
    let next := psInstanceKeyHead environment locals context fuel
    let view := psReduceAppView value []
    match view.head with
    | .constE name levels =>
      if !psEnvironmentCanUnfold environment .instances name then value else
      match psEnvironmentFind environment name with
      | none => value
      | some declaration =>
        match psDeclarationValue declaration with
        | none => value
        | some body =>
          let parameters := psDeclarationLevelParams declaration
          if parameters.length != levels.length then value else
            next (psReduceApply (psExprInstantiateLevelParams parameters levels body) view.args)
    | .lam _ _ body _ =>
      match view.args with
      | [] => value
      | arg :: rest => next (psReduceApply (psExprInstantiate1 body arg) rest)
    | .letE _ _ bound body =>
      next (psReduceApply (psExprInstantiate1 body bound) view.args)
    | .fvar id =>
      match psLocalFindById locals id with
      | some (.letDecl _ _ _ bound) =>
        next (psReduceApply (psMetaInstantiate context bound) view.args)
      | _ => value
    | _ => value

def psInstanceCanonicalKey (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) : Nat → PsExpr → PsExpr
  | 0, value => value
  | fuel + 1, value =>
    let next := psInstanceCanonicalKey environment locals context fuel
    match psInstanceKeyHead environment locals context 256 value with
    | .sortE level => .sortE (psLevelNormalize level)
    | .constE name levels => .constE name (levels.map psLevelNormalize)
    | .app fn arg => .app (next fn) (next arg)
    | .lam name domain body binder => .lam name (next domain) (next body) binder
    | .forallE name domain body binder => .forallE name (next domain) (next body) binder
    | .letE name domain value body => .letE name (next domain) (next value) (next body)
    | .proj owner index value => .proj owner index (next value)
    | value => value

private def psInstanceHashMix (left right : Nat) : Nat :=
  (left * 131 + right) % 65521

def psInstanceLevelHash : PsLevel → Nat
  | .zero => 1
  | .succ value => psInstanceHashMix 2 (psInstanceLevelHash value)
  | .max a b => psInstanceHashMix (psInstanceHashMix 3 (psInstanceLevelHash a)) (psInstanceLevelHash b)
  | .imax a b => psInstanceHashMix (psInstanceHashMix 4 (psInstanceLevelHash a)) (psInstanceLevelHash b)
  | .param name => psInstanceHashMix 5 (psEnvironmentNameHash name)
  | .mvar id => psInstanceHashMix 6 id

-- Alpha equality ignores binder names. Omitting binder annotations from the
-- hash only creates harmless collisions; the bucket comparator checks them.
def psInstanceExprHash : PsExpr → Nat
  | .bvar index => psInstanceHashMix 1 index
  | .fvar id => psInstanceHashMix 2 id
  | .mvar id => psInstanceHashMix 3 id
  | .sortE level => psInstanceHashMix 4 (psInstanceLevelHash level)
  | .constE name levels => levels.foldl
      (fun hash level => psInstanceHashMix hash (psInstanceLevelHash level))
      (psInstanceHashMix 5 (psEnvironmentNameHash name))
  | .app fn arg => psInstanceHashMix
      (psInstanceHashMix 6 (psInstanceExprHash fn)) (psInstanceExprHash arg)
  | .lam _ domain body _ => psInstanceHashMix
      (psInstanceHashMix 7 (psInstanceExprHash domain)) (psInstanceExprHash body)
  | .forallE _ domain body _ => psInstanceHashMix
      (psInstanceHashMix 8 (psInstanceExprHash domain)) (psInstanceExprHash body)
  | .letE _ domain value body => psInstanceHashMix
      (psInstanceHashMix (psInstanceHashMix 9 (psInstanceExprHash domain))
        (psInstanceExprHash value)) (psInstanceExprHash body)
  | .lit (.natural value) => psInstanceHashMix 10 value
  | .lit (.string value) => psEnvironmentHashStringWorker
      (value.utf8ByteSize + 1) value 0 11
  | .proj owner index value => psInstanceHashMix
      (psInstanceHashMix (psInstanceHashMix 12 (psEnvironmentNameHash owner)) index)
      (psInstanceExprHash value)

def psInstanceScopedKeyHash (scope : Nat) (key : PsExpr) : Nat :=
  psInstanceHashMix scope (psInstanceExprHash key)
