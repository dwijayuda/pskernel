import Ps.KernelCore.Core.IndexedReduction
import Ps.KernelCore.Checker.Context

/-
Experimental Lean-native head reduction on canonical indexed expressions.

This is the second half of the indexed execution architecture:
  * TermStore represents shared immutable expression nodes.
  * IndexedReduction handles capture-avoiding beta/zeta substitution.
  * IndexedWhnf traverses application spines without materializing raw Exprs.

Only context-free beta, zeta, metadata erasure and application-spine assembly
are implemented. This is NOT the trusted WHNF entry point: constants,
recursors, quotient, projection, native reduction and resource-policy
compatibility still belong to the existing production checker.

A caller supplies fuel explicitly. Fuel exhaustion fails closed.
-/

def psKernelC0IndexedApplySpine
    (store : PsKernelC0TermStore)
    (fn : Nat)
    (args : List Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match args with
  | [] => some (store, fn)
  | arg :: rest => do
      let (next, applied) ← psKernelC0Intern store (.app fn arg)
      psKernelC0IndexedApplySpine next applied rest

/--
  Indexed WHNF with an explicit unchanged-spine fast path.

  A stuck application head can only preserve its original handle if no
  metadata erasure, zeta reduction or beta reduction happened during the head
  traversal. This does not infer definitional equality from handle identity
  across stores: the original handle is returned only within the same store.
-/
def psKernelC0IndexedWhnfMachine
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (args : List Nat)
    (original : Nat)
    (changed : Bool) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match stored.node with
      | .app fn arg =>
          psKernelC0IndexedWhnfMachine remaining store fn (arg :: args)
            original changed
      | .mdata _ body =>
          psKernelC0IndexedWhnfMachine remaining store body args
            original true
      | .letE _ _ value body _ => do
          let (next, opened) ← psKernelC0Instantiate1Indexed store body value
          psKernelC0IndexedWhnfMachine remaining next opened args
            original true
      | .lam _ _ body _ =>
          match args with
          | [] => some (store, id)
          | arg :: rest => do
              let (next, opened) ← psKernelC0Instantiate1Indexed store body arg
              psKernelC0IndexedWhnfMachine remaining next opened rest
                original true
      | _ =>
          if changed then
            psKernelC0IndexedApplySpine store id args
          else
            some (store, original)


/-
  Context-dependent *single-step* indexed head unfolding.

  This is a complete, source-equivalent candidate for the one-step local-let
  and global-definition delta families, not a complete WHNF operation.
  The existing accepting WHNF may first perform recursor, projection, native,
  Nat and quotient reductions, and maintains exact resource/cache precedence.
  Those behaviors must not be bypassed by treating this helper as acceptance.

  Canonical argument handles remain in the same arena. Only a newly selected
  source declaration body is instantiated for universes and encoded; neither
  the application spine nor its previously interned arguments are decoded.
  Context is passed per operation, and no environment-dependent result is
  persisted in a syntax-only cache across environments or local scopes.
-/

/-- Inspect a canonical app spine in source order, inner argument first.
    Invalid handles and impossible non-decreasing-depth cycles fail closed
    under the root's stored depth. This is syntax observation only. -/
def psKernelC0IndexedAppHeadWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (args : List Nat) : Option (Nat × List Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match stored.node with
      | .app fn arg =>
          psKernelC0IndexedAppHeadWithFuel remaining store fn (arg :: args)
      | _ => some (id, args)

/--
  One exact local-let or delta-unfolding *step* in canonical indexed syntax.
  The source checker still owns acceptance, fuel accounting and reduction
  priority. This helper returns none for absent/opaque/unfoldable heads or
  invalid term stores, not a positive typing/DefEq/normalization verdict.
-/
def psKernelC0IndexedUnfoldHeadOnce
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (id : Nat) : Option (PsKernelC0TermStore × Nat) := do
  let root ← psKernelC0StoreGet store id
  let (head, args) ← psKernelC0IndexedAppHeadWithFuel
    root.depth store id []
  let headNode ← psKernelC0StoreGet store head
  let (value, params, levels) ←
    match headNode.node with
    | .fvar name =>
        match psKernelLocalContextFind context.localContext name with
        | none => none
        | some decl =>
            match psKernelLocalDeclValue decl with
            | none => none
            | some value => some (value, [], [])
    | .const name levels =>
        match psKernelEnvironmentFind context.environment name with
        | none => none
        | some info =>
            let params := psKernelConstantInfoLevelParams info
            if psKernelNameListLength params ==
                psKernelLevelListLength levels then
              match psKernelConstantInfoDeltaValue info with
              | none => none
              | some value => some (value, params, levels)
            else none
    | _ => none
  -- Encode the *uninstantiated* declaration body only. Universe rewriting
  -- and application of existing argument handles remain in the arena.
  let (sourceStore, sourceId) ← psKernelC0EncodeExpr store value
  let (nextStore, valueId) ←
    psKernelC0InstantiateLevelsIndexed sourceStore sourceId params levels
  psKernelC0IndexedApplySpine nextStore valueId args

/-- Demand-driven WHNF; args are earliest/innermost-first. -/
def psKernelC0IndexedWhnfWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (args : List Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  psKernelC0IndexedWhnfMachine fuel store id args id (!args.isEmpty)

/--
  Exact fuel-bound fragment normalization. No interpretation of kernel
  declarations or proof terms; never use it for checked admission.
-/
def psKernelC0IndexedWhnf
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  psKernelC0IndexedWhnfWithFuel fuel store id []
