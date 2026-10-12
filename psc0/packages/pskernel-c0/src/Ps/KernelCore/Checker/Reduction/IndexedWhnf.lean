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

/-- Unfold an already selected local/constant head and reapply the
    existing canonical arguments. The body is the only source-to-index
    import; universe substitution and applications stay indexed. -/
def psKernelC0IndexedUnfoldKnownHead
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (head : PsKernelC0Node)
    (args : List Nat) : Option (PsKernelC0TermStore × Nat) := do
  let (value, params, levels) ←
    match head with
    | .fvar name =>
        match psKernelLocalContextFind context.localContext name with
        | none => none
        | some decl =>
            match psKernelLocalDeclValue decl with
            | none => none
            | some body => some (body, [], [])
    | .const name levels =>
        match psKernelEnvironmentFind context.environment name with
        | none => none
        | some info =>
            let params := psKernelConstantInfoLevelParams info
            if psKernelNameListLength params ==
                psKernelLevelListLength levels then
              match psKernelConstantInfoDeltaValue info with
              | none => none
              | some body => some (body, params, levels)
            else none
    | _ => none
  let (importedStore, bodyId) ← psKernelC0EncodeExpr store value
  let (rewrittenStore, valueId) ←
    psKernelC0InstantiateLevelsIndexed importedStore bodyId params levels
  psKernelC0IndexedApplySpine rewrittenStore valueId args

/-- Source-equivalent candidate for local let/global delta single-head
    unfolding. No checker decision or fuel accounting is inferred. -/
def psKernelC0IndexedUnfoldHeadOnce
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (id : Nat) : Option (PsKernelC0TermStore × Nat) := do
  let root ← psKernelC0StoreGet store id
  let (headId, args) ← psKernelC0IndexedAppHeadWithFuel
    root.depth store id []
  let head ← psKernelC0StoreGet store headId
  psKernelC0IndexedUnfoldKnownHead context store head.node args

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

/-
  Constructor projection is another exact *one-step* indexed family.
  It observes the already constructor-shaped value, not a reconstructed
  source term. This mirrors psKernelReduceProjCore exactly: UInt32 index
  limit, constructor lookup, inductive-name match, field position after
  numParams, and original application argument order.

  Struct-value WHNF, literal-string expansion, recursor/native hooks and
  resource accounting remain external. A missing match is never evidence
  that a projection is irreducible for the full checker.
-/
/-- Select an already constructor-headed field without unpacking source
    expressions. The original outer application arguments are reapplied in
    their original left-to-right order. -/
def psKernelC0IndexedProjectKnownHead
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (typeName : PsKernelName)
    (index structId : Nat)
    (args : List Nat) : Option (PsKernelC0TermStore × Nat) := do
  if psKernelNatGt index psKernelLeanUInt32Max then none
  else do
    let structEntry ← psKernelC0StoreGet store structId
    let (fn, ctorArgs) ← psKernelC0IndexedAppHeadWithFuel
      structEntry.depth store structId []
    let ctorHead ← psKernelC0StoreGet store fn
    match ctorHead.node with
    | .const ctorName _ =>
        let info ← psKernelEnvironmentFind context.environment ctorName
        match info with
        | .ctorInfo ctor =>
            if psKernelNameEq ctor.induct typeName then do
              let field ← ctorArgs[ctor.numParams + index]?
              psKernelC0IndexedApplySpine store field args
            else none
        | _ => none
    | _ => none

/-- Select a projection, including when the projection is the head of an
    outer application. It remains only a candidate indexed reduction step. -/
def psKernelC0IndexedReduceProjectionOnce
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (id : Nat) : Option (PsKernelC0TermStore × Nat) := do
  let root ← psKernelC0StoreGet store id
  let (fn, args) ← psKernelC0IndexedAppHeadWithFuel
    root.depth store id []
  let head ← psKernelC0StoreGet store fn
  match head.node with
  | .proj typeName index structId =>
      psKernelC0IndexedProjectKnownHead
        context store typeName index structId args
  | _ => none

/-- One head-spine traversal dispatches the supported contextual reduction
    families. Add future recursor/quotient/native cases here only after their
    source ordering and fuel behavior have been qualified independently. -/
def psKernelC0IndexedReduceHeadOnce
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (id : Nat) : Option (PsKernelC0TermStore × Nat) := do
  let root ← psKernelC0StoreGet store id
  let (fn, args) ← psKernelC0IndexedAppHeadWithFuel
    root.depth store id []
  let head ← psKernelC0StoreGet store fn
  match head.node with
  | .proj typeName index structId =>
      psKernelC0IndexedProjectKnownHead
        context store typeName index structId args
  | .fvar _ | .const _ _ =>
      psKernelC0IndexedUnfoldKnownHead context store head.node args
  | _ => none

/-
  Opt-in context-sensitive indexed reduction FRAGMENT.

  This composes the already independent indexed beta/zeta/metadata engine
  with one-step local-let/delta/constructor-projection unfolding,
  carrying one canonical arena
  through an arbitrarily long supported rewrite sequence. It is NOT
  general WHNF: quotient, recursor/iota, projection-of-reducible-values,
  native/Nat primitives,
  proof irrelevance, checker caches and exact Lean 4.34 resource semantics
  are not implemented here. No accepting operation calls this fragment.

  A successful result only means at least one supported syntactic rewrite
  took place. It is NOT a normal-form or type-checking verdict. Returning
  none means unchanged, unsupported, malformed, or exhausted: consumers
  may not convert that into a positive checker judgment. The 'fuel' here
  bounds this experimental fragment's iterations and indexed path walks;
  it is NOT a replacement for the source checker reduction budget.
-/
def psKernelC0IndexedContextFragmentWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (hadProgress : Bool) :
    Option (PsKernelC0TermStore × Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let (syntacticStore, syntacticId) ←
        psKernelC0IndexedWhnf fuel store id
      -- All supported contextual rules use the same head-spine dispatch.
      -- Unknown/unsupported rules remain non-authoritative and must not
      -- be interpreted as an accepting WHNF/DefEq success.
      let nextStep :=
        psKernelC0IndexedReduceHeadOnce
          context syntacticStore syntacticId
      match nextStep with
      | some (nextStore, nextId) =>
          -- Malformed cyclic definitions cannot silently become success.
          if nextId == syntacticId then
            none
          else
            psKernelC0IndexedContextFragmentWithFuel remaining
              context nextStore nextId true
      | none =>
          if hadProgress || syntacticId != id then
            some (syntacticStore, syntacticId)
          else
            none

/-- Require an actual supported rewrite, never claim WHNF completeness. -/
def psKernelC0IndexedContextFragment
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (store : PsKernelC0TermStore)
    (id : Nat) :
    Option (PsKernelC0TermStore × Nat) :=
  psKernelC0IndexedContextFragmentWithFuel fuel context store id false
