import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Core.IndexedExpr

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
Small root-list lookup is deliberate at this phase; profile before replacing
it with a provenance-scoped trie.
-/

structure PsKernelC0IndexedCheckerSession where
  checker : PsKernelCheckerSession
  store : PsKernelC0TermStore
  roots : List (Prod PsKernelExpr Nat)

def psKernelC0IndexedSessionNew
    (checker : PsKernelCheckerSession) : PsKernelC0IndexedCheckerSession :=
  { checker := checker, store := psKernelC0StoreEmpty, roots := [] }

def psKernelC0IndexedSessionNodeCount
    (session : PsKernelC0IndexedCheckerSession) : Nat :=
  session.store.nodes.size

def psKernelC0IndexedSessionRootCount
    (session : PsKernelC0IndexedCheckerSession) : Nat :=
  session.roots.length

private def psKernelC0IndexedRootFind
    (expr : PsKernelExpr) :
    List (Prod PsKernelExpr Nat) → Option Nat
  | [] => none
  | (saved, id) :: rest =>
      if psKernelExprEqual expr saved then some id
      else psKernelC0IndexedRootFind expr rest

/-- Retain a root only in the arena of this immutable checker session. -/
def psKernelC0IndexedSessionRetain
    (session : PsKernelC0IndexedCheckerSession)
    (expr : PsKernelExpr) :
    Option PsKernelC0IndexedCheckerSession :=
  match psKernelC0IndexedRootFind expr session.roots with
  | some id =>
      if psKernelC0StoreValid session.store id then
        some session
      else
        none
  | none => do
      let (store, id) ← psKernelC0EncodeExpr session.store expr
      some {
        checker := session.checker
        store := store
        roots := (expr, id) :: session.roots
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
