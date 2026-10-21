import Ps.KernelCore.Core.ExprV2.Equality

/-
Successful DefEq pairs belong to one checking state and its append-only arena.
The hash sum is a symmetric filter only; both orientations are compared by
collision-safe structural equality. No transitive closure or cross-arena key
is accepted. Free-variable-sensitive pairs are excluded by the owning state.
-/
structure PsKernelExprV2DefEqPair where
  left : Nat
  right : Nat
  hash : Nat

def psKernelExprV2DefEqPairMatchesOrdered
    (arena : PsKernelExprV2PagedArena)
    (left right storedLeft storedRight : Nat) : Except String Bool :=
  match psKernelExprV2PagedEqOnCanonical arena left storedLeft with
  | Except.error error => Except.error error
  | Except.ok equal =>
      if equal then
        psKernelExprV2PagedEqOnCanonical arena right storedRight
      else Except.ok false

def psKernelExprV2DefEqPairMatches
    (arena : PsKernelExprV2PagedArena)
    (pair : PsKernelExprV2DefEqPair) (left right : Nat) : Except String Bool :=
  match psKernelExprV2DefEqPairMatchesOrdered
      arena left right pair.left pair.right with
  | Except.error error => Except.error error
  | Except.ok equal =>
      if equal then Except.ok true
      else psKernelExprV2DefEqPairMatchesOrdered
        arena left right pair.right pair.left

/- The recursive scan receives every argument explicitly. Keep FindIn's
   generated curried ABI while avoiding one argument-closure chain per entry.
   Candidate order, both orientations, structural collision checks and errors
   remain exactly those of the original list scan. -/
def psKernelExprV2DefEqPairFindWorker
    (pairs : List PsKernelExprV2DefEqPair)
    (arena : PsKernelExprV2PagedArena) (left right hash : Nat) : Except String Bool :=
  match pairs with
  | List.nil => Except.ok false
  | List.cons first rest =>
      if Nat.beq first.hash hash then
        match psKernelExprV2DefEqPairMatches arena first left right with
        | Except.error error => Except.error error
        | Except.ok equal =>
            if equal then Except.ok true
            else psKernelExprV2DefEqPairFindWorker rest arena left right hash
      else psKernelExprV2DefEqPairFindWorker rest arena left right hash

def psKernelExprV2DefEqPairFindIn
    (pairs : List PsKernelExprV2DefEqPair) :
    PsKernelExprV2PagedArena -> Nat -> Nat -> Nat -> Except String Bool :=
  match pairs with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_left _right _hash : Nat) =>
        Except.ok false
  | List.cons _ _ =>
      fun (arena : PsKernelExprV2PagedArena) (left right hash : Nat) =>
        psKernelExprV2DefEqPairFindWorker pairs arena left right hash

def psKernelExprV2DefEqPairContains
    (arena : PsKernelExprV2PagedArena)
    (pairs : List PsKernelExprV2DefEqPair) (left right : Nat) : Except String Bool :=
  match psKernelExprV2PagedRequire arena left with
  | Except.error error => Except.error error
  | Except.ok leftEntry =>
      match psKernelExprV2PagedRequire arena right with
      | Except.error error => Except.error error
      | Except.ok rightEntry =>
          if leftEntry.hasFVar then Except.ok false
          else
            if rightEntry.hasFVar then Except.ok false
            else psKernelExprV2DefEqPairFindIn pairs arena left right
              (Nat.mod (Nat.add leftEntry.hash rightEntry.hash) psKernelCacheHashModulus)
