import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Core.IndexedExpr
import Ps.KernelCore.Checker.Reduction.IndexedWhnf
import Ps.KernelCore.Admission.Declaration.Admission

/-
Opt-in, session-owned indexed expression retention around the accepting
recursive-expression checker.

This is a *staging boundary*, not a new type-checking rule. All judgments,
environment-dependent reduction, fuel and failure semantics are delegated to
PsKernelCheckerSession. The arena stores only exact syntax already supplied to
or returned by that checker. Handles are never exposed by this API, so neither
an external arena's Nat ID nor an environment-dependent cache value can enter
acceptance through this component.

Snapshots are persistent: extending one session leaves earlier snapshots
untouched. Root entries use exact syntax equality (including binder names and
metadata), not the kernel's binder-name-insensitive semantic comparator.
Root memo starts with a tiny list and promotes to a collision-checked radix
index. Root caching is purely syntactic, independent of contextual judgments.
-/

/-- A root-only memo index: never an environment-dependent judgment. -/
abbrev PsKernelC0IndexedRootIndex :=
  PsKernelC0HashTrie (Prod PsKernelExpr Nat)

/-- Coarse expression hash plus exact top-level binder identity. All collisions
    are checked with complete PsKernelExprEqual before reusing a handle. -/
private def psKernelC0IndexedRootHashFromBase
    (base : Nat) (expr : PsKernelExpr) : Nat :=
  match expr with
  | .lam name _ _ _ => psKernelCacheMix base (psKernelCacheNameHash name)
  | .forallE name _ _ _ => psKernelCacheMix base (psKernelCacheNameHash name)
  | .letE name _ _ _ _ => psKernelCacheMix base (psKernelCacheNameHash name)
  | _ => base

/-- A source-side lookup needs a source hash; successful insertion can reuse
    the equivalent cached hash of the just-interned canonical root. -/
private def psKernelC0IndexedRootHash (expr : PsKernelExpr) : Nat :=
  psKernelC0IndexedRootHashFromBase (psKernelExprHash expr) expr

structure PsKernelC0IndexedCheckerSession where
  checker : PsKernelCheckerSession
  store : PsKernelC0TermStore
  -- Small-first root memo, promoted to collision-checked radix-16 index.
  roots : List (Prod PsKernelExpr Nat)
  rootIndex : Option PsKernelC0IndexedRootIndex
  rootCount : Nat

def psKernelC0IndexedSessionNew
    (checker : PsKernelCheckerSession) : PsKernelC0IndexedCheckerSession :=
  {
    checker := checker
    store := psKernelC0StoreEmpty
    roots := []
    rootIndex := none
    rootCount := 0
  }

def psKernelC0IndexedSessionNodeCount
    (session : PsKernelC0IndexedCheckerSession) : Nat :=
  session.store.nodes.size

def psKernelC0IndexedSessionRootCount
    (session : PsKernelC0IndexedCheckerSession) : Nat :=
  session.rootCount

private def psKernelC0IndexedRootFind
    (expr : PsKernelExpr) :
    List (Prod PsKernelExpr Nat) → Option Nat
  | [] => none
  | (saved, id) :: rest =>
      if psKernelExprEqual expr saved then some id
      else psKernelC0IndexedRootFind expr rest

private def psKernelC0IndexedRootsToTrie
    (roots : List (Prod PsKernelExpr Nat))
    (index : PsKernelC0IndexedRootIndex) : PsKernelC0IndexedRootIndex :=
  match roots with
  | [] => index
  | entry :: rest =>
      let hash := psKernelC0IndexedRootHash entry.fst
      let bucket := psKernelC0TrieBucket psKernelC0IndexDepth index hash
      let next := psKernelC0TrieSet psKernelC0IndexDepth
        index hash (entry :: bucket)
      psKernelC0IndexedRootsToTrie rest next

private def psKernelC0IndexedSessionLookup
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) : Option Nat :=
  match session.rootIndex with
  | none => psKernelC0IndexedRootFind expr session.roots
  | some index =>
      let hash := psKernelC0IndexedRootHash expr
      psKernelC0IndexedRootFind expr
        (psKernelC0TrieBucket psKernelC0IndexDepth index hash)

/-- Retain a root only in the arena of this immutable checker session.
    Small sessions scan at most eight roots; large sessions share a radix trie.
    Never use a root-cache hit as a type-checking or DefEq success predicate. -/
def psKernelC0IndexedSessionRetain
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) :
    Option PsKernelC0IndexedCheckerSession :=
  match psKernelC0IndexedSessionLookup session expr with
  | some id =>
      if psKernelC0StoreValid session.store id then some session else none
  | none => do
      let (store, id) ← psKernelC0EncodeExpr session.store expr
      let stored ← psKernelC0StoreGet store id
      -- Root-index publication is syntactic only. The child-derived
      -- checkerHash matches psKernelExprHash and never decides acceptance.
      let indexedHash :=
        psKernelC0IndexedRootHashFromBase stored.checkerHash expr
      let entry := (expr, id)
      let count := session.rootCount + 1
      match session.rootIndex with
      | some index =>
          let bucket := psKernelC0TrieBucket psKernelC0IndexDepth
            index indexedHash
          let next := psKernelC0TrieSet psKernelC0IndexDepth
            index indexedHash (entry :: bucket)
          some {
            checker := session.checker
            store := store
            roots := []
            rootIndex := some next
            rootCount := count
          }
      | none =>
          let small := entry :: session.roots
          if count <= 8 then
            some {
              checker := session.checker
              store := store
              roots := small
              rootIndex := none
              rootCount := count
            }
          else
            some {
              checker := session.checker
              store := store
              roots := []
              rootIndex :=
                some (psKernelC0IndexedRootsToTrie small
                  PsKernelC0HashTrie.empty)
              rootCount := count
            }

/-- Encoding failure never supplies a kernel result; the accepting result is
    already established by the checker and remains the authority. -/
private def psKernelC0IndexedSessionKeep
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) : PsKernelC0IndexedCheckerSession :=
  match psKernelC0IndexedSessionRetain session expr with
  | some next => next
  | none => session

def psKernelC0IndexedSessionWhnf
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelC0IndexedCheckerSession) := do
  let (value, checked) ← psKernelSessionWhnf fuel session.checker expr
  let kept := psKernelC0IndexedSessionKeep { session with checker := checked } expr
  let kept := psKernelC0IndexedSessionKeep kept value
  pure (value, kept)

def psKernelC0IndexedSessionInfer
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelC0IndexedCheckerSession) := do
  let (value, checked) ← psKernelSessionInfer fuel session.checker expr
  let kept := psKernelC0IndexedSessionKeep { session with checker := checked } expr
  let kept := psKernelC0IndexedSessionKeep kept value
  pure (value, kept)

def psKernelC0IndexedSessionCheck
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelC0IndexedCheckerSession) := do
  let (value, checked) ← psKernelSessionCheck fuel session.checker expr
  let kept := psKernelC0IndexedSessionKeep { session with checker := checked } expr
  let kept := psKernelC0IndexedSessionKeep kept value
  pure (value, kept)

def psKernelC0IndexedSessionIsDefEq
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (left right : PsKernelExpr) :
    Except String (Prod Bool PsKernelC0IndexedCheckerSession) := do
  let (value, checked) ←
    psKernelSessionIsDefEq fuel session.checker left right
  let kept := psKernelC0IndexedSessionKeep { session with checker := checked } left
  let kept := psKernelC0IndexedSessionKeep kept right
  pure (value, kept)

/-
  Checked declaration admission on a persistent indexed *syntax* session.

  The original native checker validates each full declaration atomically.
  When a declaration is accepted, every environment-dependent checker
  cache is discarded before the next check, while nextFresh, local context,
  resource configuration and the immutable indexed syntax store survive.
  Retained roots are not checked judgments and remain valid syntax across
  environments. Admission deliberately does NOT encode every accepted body:
  the checked environment owns those expressions and indexed reduction may
  import a body on demand. Eager indexing adds unused allocations to ordinary
  declaration chains. A rejection does not return an updated session.

  This is an opt-in session-management boundary. Inference, DefEq, WHNF
  and declaration checks are still executed by the recursive accepting
  checker. No indexed term handle grants admission.
-/
private def psKernelC0IndexedSessionCommitEnvironment
    (session : PsKernelC0IndexedCheckerSession)
    (environment : PsKernelEnvironment) :
    PsKernelC0IndexedCheckerSession :=
  let context := psKernelCheckerContextWithEnvironment
    session.checker.context environment
  let state : PsKernelCheckerState :=
    { psKernelCheckerStateEmpty with
      nextFresh := session.checker.state.nextFresh }
  { session with checker := { context := context, state := state } }

/-- Exact checked axiom admission, with environment-cache invalidation. -/
def psKernelC0IndexedSessionAdmitAxiom
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (info : PsKernelAxiomInfo) :
    Except String PsKernelC0IndexedCheckerSession := do
  let environment ← psKernelAddAxiom fuel
    session.checker.context.environment info
    session.checker.context.maxRecDepth
    session.checker.context.maxNatSize
  pure (psKernelC0IndexedSessionCommitEnvironment session environment)

/-- Exact checked definition admission; no source checker rule is bypassed. -/
def psKernelC0IndexedSessionAdmitDefinition
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (info : PsKernelDefinitionInfo) :
    Except String PsKernelC0IndexedCheckerSession := do
  let environment ← psKernelAddDefinition fuel
    session.checker.context.environment info
    session.checker.context.maxRecDepth
    session.checker.context.maxNatSize
  pure (psKernelC0IndexedSessionCommitEnvironment session environment)

/-- Exact checked theorem admission; index syntax only if later requested. -/
def psKernelC0IndexedSessionAdmitTheorem
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (info : PsKernelTheoremInfo) :
    Except String PsKernelC0IndexedCheckerSession := do
  let environment ← psKernelAddTheorem fuel
    session.checker.context.environment info
    session.checker.context.maxRecDepth
    session.checker.context.maxNatSize
  pure (psKernelC0IndexedSessionCommitEnvironment session environment)

/-- Exact checked opaque admission; the original checker decides safety. -/
def psKernelC0IndexedSessionAdmitOpaque
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (info : PsKernelOpaqueInfo) :
    Except String PsKernelC0IndexedCheckerSession := do
  let environment ← psKernelAddOpaque fuel
    session.checker.context.environment info
    session.checker.context.maxRecDepth
    session.checker.context.maxNatSize
  pure (psKernelC0IndexedSessionCommitEnvironment session environment)

/-
  Opt-in indexed diagnostic execution linked to an immutable checker session.
  The source term is imported once. Subsequent operations keep canonical
  terms inside the same persistent store. The context snapshot is inherited
  from the session and is never inferred from a numeric term handle.

  This is a syntax-transformation interface, not a checked judgment API:
  indexed results must still pass the authoritative recursive checker.
-/
structure PsKernelC0IndexedWork where
  session : PsKernelC0IndexedCheckerSession
  term : Nat
  progressed : Bool
  halt : PsKernelC0IndexedFragmentHalt

/-- Import one exact source term into a session-owned indexed work state. -/
def psKernelC0IndexedSessionStartWork
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) : Option PsKernelC0IndexedWork := do
  let retained ← psKernelC0IndexedSessionRetain session expr
  let id ← psKernelC0IndexedSessionLookup retained expr
  if psKernelC0StoreValid retained.store id then
    some {
      session := retained
      term := id
      progressed := false
      halt := .needsChecker
    }
  else none

/-- Apply the supported indexed reduction fragment in this work snapshot.
    This produces diagnostic syntax only, never proof acceptance. -/
def psKernelC0IndexedWorkRun
    (fuel : Nat)
    (work : PsKernelC0IndexedWork) : PsKernelC0IndexedWork :=
  let result := psKernelC0IndexedContextFragment
    fuel work.session.checker.context work.session.store work.term
  {
    session := { work.session with store := result.store }
    term := result.id
    progressed := result.progressed
    halt := result.halt
  }

/-- Decode once when a diagnostic consumer explicitly requests syntax. -/
def psKernelC0IndexedWorkInspect
    (work : PsKernelC0IndexedWork) : Option PsKernelExpr :=
  psKernelC0DecodeExpr work.session.store work.term
