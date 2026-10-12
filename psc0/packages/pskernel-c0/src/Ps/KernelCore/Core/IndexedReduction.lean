import Ps.KernelCore.Core.IndexedExpr

/-
PSKernel-C0 experimental indexed de Bruijn execution.

All operations use the native Lean PsKernelC0TermStore. Expressions are
represented as Nat handles, with immutable shared child nodes.

This is the prerequisite for a future full indexed WHNF / DefEq checker. It
does not change the accepting API. In particular, the original resource
budget and all recursive/nat/native/quotient rules remain authoritative.

Fuel is bounded by the *stored expression depth* (one step for each path
edge). Child handles were already validated at intern time.
-/

/-- Retain the exact old handle when an indexed rewrite changes nothing. -/
def psKernelC0KeepOrIntern
    (store : PsKernelC0TermStore)
    (id : Nat)
    (node : PsKernelC0Node) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let original ← psKernelC0StoreGet store id
  if psKernelC0NodeEq original.node node then
    some (store, id)
  else
    psKernelC0Intern store node

/-- Shift loose de Bruijn variables in an indexed term, preserving shares. -/
def psKernelC0LiftIndexedWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (start : Nat)
    (amount : Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      if amount == 0 || stored.looseBVarRange <= start then
        some (store, id)
      else
        match stored.node with
        | .bvar i =>
            if i < start then some (store, id)
            else psKernelC0Intern store (.bvar (i + amount))
        | .app fn arg => do
            let (s1, f) ← psKernelC0LiftIndexedWithFuel remaining store fn start amount
            let (s2, a) ← psKernelC0LiftIndexedWithFuel remaining s1 arg start amount
            psKernelC0KeepOrIntern s2 id (.app f a)
        | .lam name ty body info => do
            let (s1, t) ← psKernelC0LiftIndexedWithFuel remaining store ty start amount
            let (s2, b) ← psKernelC0LiftIndexedWithFuel remaining s1 body (start + 1) amount
            psKernelC0KeepOrIntern s2 id (.lam name t b info)
        | .forallE name ty body info => do
            let (s1, t) ← psKernelC0LiftIndexedWithFuel remaining store ty start amount
            let (s2, b) ← psKernelC0LiftIndexedWithFuel remaining s1 body (start + 1) amount
            psKernelC0KeepOrIntern s2 id (.forallE name t b info)
        | .letE name ty value body nondep => do
            let (s1, t) ← psKernelC0LiftIndexedWithFuel remaining store ty start amount
            let (s2, v) ← psKernelC0LiftIndexedWithFuel remaining s1 value start amount
            let (s3, b) ← psKernelC0LiftIndexedWithFuel remaining s2 body (start + 1) amount
            psKernelC0KeepOrIntern s3 id (.letE name t v b nondep)
        | .mdata metadata body => do
            let (s1, b) ← psKernelC0LiftIndexedWithFuel remaining store body start amount
            psKernelC0KeepOrIntern s1 id (.mdata metadata b)
        | .proj name index body => do
            let (s1, b) ← psKernelC0LiftIndexedWithFuel remaining store body start amount
            psKernelC0KeepOrIntern s1 id (.proj name index b)
        | _ => some (store, id)

def psKernelC0LiftIndexed
    (store : PsKernelC0TermStore)
    (id start amount : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store id
  psKernelC0LiftIndexedWithFuel entry.depth store id start amount

/-- Capture-avoiding substitution for exactly one removed binder. -/
def psKernelC0Instantiate1IndexedWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (replacement : Nat)
    (offset : Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match stored.node with
      | .bvar i =>
          if i < offset then
            some (store, id)
          else if i == offset then
            psKernelC0LiftIndexed store replacement 0 offset
          else
            psKernelC0Intern store (.bvar (i - 1))
      | .app fn arg => do
          let (s1, f) ← psKernelC0Instantiate1IndexedWithFuel remaining store fn replacement offset
          let (s2, a) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 arg replacement offset
          psKernelC0KeepOrIntern s2 id (.app f a)
      | .lam name ty body info => do
          let (s1, t) ← psKernelC0Instantiate1IndexedWithFuel remaining store ty replacement offset
          let (s2, b) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 body replacement (offset + 1)
          psKernelC0KeepOrIntern s2 id (.lam name t b info)
      | .forallE name ty body info => do
          let (s1, t) ← psKernelC0Instantiate1IndexedWithFuel remaining store ty replacement offset
          let (s2, b) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 body replacement (offset + 1)
          psKernelC0KeepOrIntern s2 id (.forallE name t b info)
      | .letE name ty value body nondep => do
          let (s1, t) ← psKernelC0Instantiate1IndexedWithFuel remaining store ty replacement offset
          let (s2, v) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 value replacement offset
          let (s3, b) ← psKernelC0Instantiate1IndexedWithFuel remaining s2 body replacement (offset + 1)
          psKernelC0KeepOrIntern s3 id (.letE name t v b nondep)
      | .mdata metadata body => do
          let (s1, b) ← psKernelC0Instantiate1IndexedWithFuel remaining store body replacement offset
          psKernelC0KeepOrIntern s1 id (.mdata metadata b)
      | .proj name index body => do
          let (s1, b) ← psKernelC0Instantiate1IndexedWithFuel remaining store body replacement offset
          psKernelC0KeepOrIntern s1 id (.proj name index b)
      | _ => some (store, id)

/--
  Substitution over same-store handles; result is *not* a checked proof term.
  It remains the caller's job to compare against the normal kernel semantics.
-/
def psKernelC0Instantiate1IndexedReference
    (store : PsKernelC0TermStore)
    (id replacement : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store id
  if !(psKernelC0StoreValid store replacement) then none
  else psKernelC0Instantiate1IndexedWithFuel entry.depth store id replacement 0


/-
Memoized indexed-beta engine.

The original indexed recursive worker above remains an executable oracle.
The accepting checker remains unchanged. Canonical handles and an immutable
trie support a per-operation table keyed by (term ID, binder depth): every
shared DAG node is rewritten at most once at each scope depth. Hash collisions
are resolved by exact pair comparisons. No cached result is shared between
different source stores, replacements, or checked contexts.
-/

abbrev PsKernelC0RewriteTable :=
  PsKernelC0HashTrie (Prod Nat (Prod Nat Nat))

structure PsKernelC0RewriteState where
  store : PsKernelC0TermStore
  memo : PsKernelC0RewriteTable

def psKernelC0RewriteTableEmpty : PsKernelC0RewriteTable :=
  PsKernelC0HashTrie.empty

def psKernelC0RewriteKey (id offset : Nat) : Nat :=
  psKernelCacheMix (psKernelCacheMix 43 id) offset

def psKernelC0RewriteFind
    (id offset : Nat) :
    List (Prod Nat (Prod Nat Nat)) -> Option Nat
  | [] => none
  | entry :: rest =>
      if Nat.beq (Prod.fst entry) id &&
         Nat.beq (Prod.fst (Prod.snd entry)) offset then
        some (Prod.snd (Prod.snd entry))
      else
        psKernelC0RewriteFind id offset rest

def psKernelC0RewriteLookup
    (memo : PsKernelC0RewriteTable)
    (id offset : Nat) : Option Nat :=
  psKernelC0RewriteFind id offset
    (psKernelC0TrieBucket psKernelC0IndexDepth memo
      (psKernelC0RewriteKey id offset))

def psKernelC0RewriteInsert
    (memo : PsKernelC0RewriteTable)
    (id offset result : Nat) : PsKernelC0RewriteTable :=
  let hash := psKernelC0RewriteKey id offset
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ((Prod.mk id (Prod.mk offset result)) :: bucket)

def psKernelC0RewritePublish
    (state : PsKernelC0RewriteState)
    (id offset result : Nat) : PsKernelC0RewriteState :=
  { store := state.store
    memo := psKernelC0RewriteInsert state.memo id offset result }

def psKernelC0RewriteIntern
    (state : PsKernelC0RewriteState)
    (oldId : Nat)
    (node : PsKernelC0Node) :
    Option (Prod PsKernelC0RewriteState Nat) := do
  let (nextStore, result) ← psKernelC0KeepOrIntern state.store oldId node
  some ({ store := nextStore, memo := state.memo }, result)

/-
Indexed lifting with operation-local DAG memoization.

The amount is fixed for one invocation. A memo entry is keyed by the
canonical child handle and binder cutoff; nested binders advance only the
cutoff. All rewritten nodes live in the same persistent store, and cached
IDs are never reused across stores or invocations. A zero loose-variable
range or an unchanged cutoff returns the original handle without caching.
This is an untrusted optimization candidate, never a checking verdict.
-/
def psKernelC0LiftMemoWithFuel
    (fuel : Nat)
    (state : PsKernelC0RewriteState)
    (id start amount : Nat) :
    Option (Prod PsKernelC0RewriteState Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet state.store id
      if amount == 0 || stored.looseBVarRange <= start then
        some (state, id)
      else
        match psKernelC0RewriteLookup state.memo id start with
        | some result => some (state, result)
        | none => do
            let (nextState, result) ←
              match stored.node with
              | .bvar i =>
                  psKernelC0RewriteIntern state id (.bvar (i + amount))
              | .app fn arg => do
                  let (s1, f) ← psKernelC0LiftMemoWithFuel
                    remaining state fn start amount
                  let (s2, a) ← psKernelC0LiftMemoWithFuel
                    remaining s1 arg start amount
                  psKernelC0RewriteIntern s2 id (.app f a)
              | .lam name ty body info => do
                  let (s1, t) ← psKernelC0LiftMemoWithFuel
                    remaining state ty start amount
                  let (s2, b) ← psKernelC0LiftMemoWithFuel
                    remaining s1 body (start + 1) amount
                  psKernelC0RewriteIntern s2 id (.lam name t b info)
              | .forallE name ty body info => do
                  let (s1, t) ← psKernelC0LiftMemoWithFuel
                    remaining state ty start amount
                  let (s2, b) ← psKernelC0LiftMemoWithFuel
                    remaining s1 body (start + 1) amount
                  psKernelC0RewriteIntern s2 id (.forallE name t b info)
              | .letE name ty value body nondep => do
                  let (s1, t) ← psKernelC0LiftMemoWithFuel
                    remaining state ty start amount
                  let (s2, v) ← psKernelC0LiftMemoWithFuel
                    remaining s1 value start amount
                  let (s3, b) ← psKernelC0LiftMemoWithFuel
                    remaining s2 body (start + 1) amount
                  psKernelC0RewriteIntern s3 id (.letE name t v b nondep)
              | .mdata metadata body => do
                  let (s1, b) ← psKernelC0LiftMemoWithFuel
                    remaining state body start amount
                  psKernelC0RewriteIntern s1 id (.mdata metadata b)
              | .proj name index body => do
                  let (s1, b) ← psKernelC0LiftMemoWithFuel
                    remaining state body start amount
                  psKernelC0RewriteIntern s1 id (.proj name index b)
              | _ => some (state, id)
            some (psKernelC0RewritePublish nextState id start result, result)

/-- Indexed lifting candidate with exact recursive lifting kept as oracle.
    A per-call memo never outlives its input arena or shift amount. -/
def psKernelC0LiftIndexedMemoized
    (store : PsKernelC0TermStore)
    (id start amount : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store id
  let state : PsKernelC0RewriteState :=
    { store := store, memo := psKernelC0RewriteTableEmpty }
  let (resultState, result) ← psKernelC0LiftMemoWithFuel
    entry.depth state id start amount
  some (resultState.store, result)

def psKernelC0InstantiateMemoWithFuel
    (fuel : Nat)
    (state : PsKernelC0RewriteState)
    (id replacement offset : Nat) :
    Option (Prod PsKernelC0RewriteState Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      match psKernelC0RewriteLookup state.memo id offset with
      | some cached => some (state, cached)
      | none =>
          let stored ← psKernelC0StoreGet state.store id
          -- Every affected de Bruijn variable must have index >= offset.
          -- Skip complete closed sub-DAGs without constructing memo entries.
          if stored.looseBVarRange <= offset then
            some (state, id)
          else
            let (nextState, result) ←
              match stored.node with
              | .bvar i =>
                  if i < offset then some (state, id)
                  else if i == offset then do
                    let (nextStore, lifted) ←
                      psKernelC0LiftIndexed state.store replacement 0 offset
                    some ({ store := nextStore, memo := state.memo }, lifted)
                  else psKernelC0RewriteIntern state id (.bvar (i - 1))
              | .app fn arg => do
                  let (s1, f) ← psKernelC0InstantiateMemoWithFuel
                    remaining state fn replacement offset
                  let (s2, a) ← psKernelC0InstantiateMemoWithFuel
                    remaining s1 arg replacement offset
                  psKernelC0RewriteIntern s2 id (.app f a)
              | .lam name ty body info => do
                  let (s1, t) ← psKernelC0InstantiateMemoWithFuel
                    remaining state ty replacement offset
                  let (s2, b) ← psKernelC0InstantiateMemoWithFuel
                    remaining s1 body replacement (offset + 1)
                  psKernelC0RewriteIntern s2 id (.lam name t b info)
              | .forallE name ty body info => do
                  let (s1, t) ← psKernelC0InstantiateMemoWithFuel
                    remaining state ty replacement offset
                  let (s2, b) ← psKernelC0InstantiateMemoWithFuel
                    remaining s1 body replacement (offset + 1)
                  psKernelC0RewriteIntern s2 id (.forallE name t b info)
              | .letE name ty value body nondep => do
                  let (s1, t) ← psKernelC0InstantiateMemoWithFuel
                    remaining state ty replacement offset
                  let (s2, v) ← psKernelC0InstantiateMemoWithFuel
                    remaining s1 value replacement offset
                  let (s3, b) ← psKernelC0InstantiateMemoWithFuel
                    remaining s2 body replacement (offset + 1)
                  psKernelC0RewriteIntern s3 id (.letE name t v b nondep)
              | .mdata metadata body => do
                  let (s1, b) ← psKernelC0InstantiateMemoWithFuel
                    remaining state body replacement offset
                  psKernelC0RewriteIntern s1 id (.mdata metadata b)
              | .proj name index body => do
                  let (s1, b) ← psKernelC0InstantiateMemoWithFuel
                    remaining state body replacement offset
                  psKernelC0RewriteIntern s1 id (.proj name index b)
              | _ => some (state, id)
            some (psKernelC0RewritePublish nextState id offset result, result)

/--
  Memoized beta-substitution on one immutable, indexed term store.
  The table is deliberately fresh for every call: the replacement and arena
  must not be conflated with those from another operation.
-/
def psKernelC0Instantiate1Indexed
    (store : PsKernelC0TermStore)
    (id replacement : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store id
  if !(psKernelC0StoreValid store replacement) then none
  else
    let state : PsKernelC0RewriteState :=
      { store := store, memo := psKernelC0RewriteTableEmpty }
    let (resultState, result) ← psKernelC0InstantiateMemoWithFuel
      entry.depth state id replacement 0
    some (resultState.store, result)

/-
  Canonical indexed universe-level instantiation.

  Universe parameter/value lists are held fixed throughout *one* rewrite.
  The existing exact (term ID, offset) collision-checked memo is reused
  with offset zero, but a fresh table is created for each invocation.
  No result can cross a different substitution mapping or arena. This is
  an expression transformation, not universe inference or a kernel verdict.

  Rewriting stays indexed through all children: only the independent
  PsKernelLevelInstantiateParams/psKernelInstantiateLevelList routines
  transform the level payloads. KeepOrIntern retains unchanged term IDs.
-/
def psKernelC0InstantiateLevelsMemoWithFuel
    (fuel : Nat)
    (state : PsKernelC0RewriteState)
    (id : Nat)
    (params : List PsKernelName)
    (levels : List PsKernelLevel) :
    Option (PsKernelC0RewriteState × Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet state.store id
      match psKernelC0RewriteLookup state.memo id 0 with
      | some cached => some (state, cached)
      | none => do
          let (nextState, result) ←
            match stored.node with
            | .sort level =>
                psKernelC0RewriteIntern state id
                  (.sort (psKernelLevelInstantiateParams
                    level params levels))
            | .const name arguments =>
                psKernelC0RewriteIntern state id
                  (.const name
                    (psKernelInstantiateLevelList arguments params levels))
            | .app fn arg => do
                let (s1, f) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining state fn params levels
                let (s2, a) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining s1 arg params levels
                psKernelC0RewriteIntern s2 id (.app f a)
            | .lam name ty body info => do
                let (s1, t) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining state ty params levels
                let (s2, b) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining s1 body params levels
                psKernelC0RewriteIntern s2 id (.lam name t b info)
            | .forallE name ty body info => do
                let (s1, t) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining state ty params levels
                let (s2, b) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining s1 body params levels
                psKernelC0RewriteIntern s2 id (.forallE name t b info)
            | .letE name ty value body nondep => do
                let (s1, t) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining state ty params levels
                let (s2, v) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining s1 value params levels
                let (s3, b) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining s2 body params levels
                psKernelC0RewriteIntern s3 id (.letE name t v b nondep)
            | .mdata metadata body => do
                let (s1, b) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining state body params levels
                psKernelC0RewriteIntern s1 id (.mdata metadata b)
            | .proj name index body => do
                let (s1, b) ← psKernelC0InstantiateLevelsMemoWithFuel
                  remaining state body params levels
                psKernelC0RewriteIntern s1 id (.proj name index b)
            | _ => some (state, id)
          some (psKernelC0RewritePublish nextState id 0 result, result)

/-- Lossless universe instantiation on *the existing arena*, with bounded
    traversal and full syntactic identity checks inside interning. -/
def psKernelC0InstantiateLevelsIndexed
    (store : PsKernelC0TermStore)
    (id : Nat)
    (params : List PsKernelName)
    (levels : List PsKernelLevel) : Option (PsKernelC0TermStore × Nat) := do
  let entry ← psKernelC0StoreGet store id
  match params, levels with
  | [], _ => some (store, id)
  | _, [] => some (store, id)
  | _, _ =>
      let initial : PsKernelC0RewriteState :=
        { store := store, memo := psKernelC0RewriteTableEmpty }
      let (resultState, result) ← psKernelC0InstantiateLevelsMemoWithFuel
        entry.depth initial id params levels
      some (resultState.store, result)

/-- The only reduction performed is beta on an explicit indexed lambda head. -/
def psKernelC0IndexedBetaStep
    (store : PsKernelC0TermStore)
    (fn arg : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store fn
  match entry.node with
  | .lam _ _ body _ => psKernelC0Instantiate1Indexed store body arg
  | _ => none
