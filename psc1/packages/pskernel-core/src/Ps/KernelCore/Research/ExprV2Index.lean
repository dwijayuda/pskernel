import Ps.KernelCore.Research.ExprV2

/-
Persistent indexed arena experiment for Expression V2.

The current array-backed V2 arena is efficient in native Lean but PSC1's
generated TypeScript and DirectJS compile Array.push as [...a, value],
copying O(number of previously inserted nodes) per append. A complete
DAG built by repeated Array.push can therefore cost quadratic allocation.

This alternative persistent binary index shares unchanged tree branches.
An entry with ID i is stored at heap-key i+1. At each node the low bit
chooses a branch, and division by two consumes one digit; heap-key 1
stores the value at the current branch. Insertion and lookup visit
O(log i) nodes. The full natural key avoids hash collisions.

V2Index contains research metadata only. It is not a proof token and must
never grant independent declaration admissions or unchecked DefEq results.
-/

inductive PsKernelExprV2Index where
  | empty
  | branch
      (value : Option PsKernelExprV2Entry)
      (left right : PsKernelExprV2Index)

structure PsKernelExprV2IndexedArena where
  index : PsKernelExprV2Index
  size : Nat

def psKernelExprV2IndexedEmpty : PsKernelExprV2IndexedArena :=
  {
    index := PsKernelExprV2Index.empty
    size := 0
  }

def psKernelExprV2IndexFindFuel
    (fuel : Nat) :
    PsKernelExprV2Index -> Nat -> Option PsKernelExprV2Entry :=
  match fuel with
  | Nat.zero =>
      fun (_tree : PsKernelExprV2Index) (_key : Nat) =>
        Option.none
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2Index -> Nat -> Option PsKernelExprV2Entry :=
        psKernelExprV2IndexFindFuel remaining;
      fun (tree : PsKernelExprV2Index) (key : Nat) =>
        match tree with
        | PsKernelExprV2Index.empty =>
            Option.none
        | PsKernelExprV2Index.branch value left right =>
            if Nat.beq key 1 then
              value
            else if Nat.beq key 0 then
              Option.none
            else if Nat.beq (Nat.mod key 2) 0 then
              smaller left (Nat.div key 2)
            else
              smaller right (Nat.div key 2)

def psKernelExprV2IndexInsertFuel
    (fuel : Nat) :
    PsKernelExprV2Index -> Nat -> PsKernelExprV2Entry ->
    Except String PsKernelExprV2Index :=
  match fuel with
  | Nat.zero =>
      fun (_tree : PsKernelExprV2Index)
          (_key : Nat)
          (_entry : PsKernelExprV2Entry) =>
        Except.error "PSKERNEL_V2_INDEX_FUEL_EXHAUSTED"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2Index -> Nat -> PsKernelExprV2Entry ->
          Except String PsKernelExprV2Index :=
        psKernelExprV2IndexInsertFuel remaining;
      fun (tree : PsKernelExprV2Index)
          (key : Nat)
          (entry : PsKernelExprV2Entry) =>
        let current : Option PsKernelExprV2Entry :=
          match tree with
          | PsKernelExprV2Index.branch value _ _ => value
          | _ => Option.none;
        let left : PsKernelExprV2Index :=
          match tree with
          | PsKernelExprV2Index.branch _ l _ => l
          | _ => PsKernelExprV2Index.empty;
        let right : PsKernelExprV2Index :=
          match tree with
          | PsKernelExprV2Index.branch _ _ r => r
          | _ => PsKernelExprV2Index.empty;
        if Nat.beq key 1 then
          Except.ok
            (PsKernelExprV2Index.branch
              (Option.some entry) left right)
        else if Nat.beq key 0 then
          Except.error "PSKERNEL_V2_INDEX_ZERO_KEY"
        else if Nat.beq (Nat.mod key 2) 0 then
          match smaller left (Nat.div key 2) entry with
          | Except.error error =>
              Except.error error
          | Except.ok newLeft =>
              Except.ok
                (PsKernelExprV2Index.branch
                  current newLeft right)
        else
          match smaller right (Nat.div key 2) entry with
          | Except.error error =>
              Except.error error
          | Except.ok newRight =>
              Except.ok
                (PsKernelExprV2Index.branch
                  current left newRight)

def psKernelExprV2IndexedFind
    (arena : PsKernelExprV2IndexedArena)
    (id : Nat) : Option PsKernelExprV2Entry :=
  if Nat.blt id arena.size then
    psKernelExprV2IndexFindFuel
      (Nat.succ (Nat.succ id))
      arena.index
      (Nat.succ id)
  else
    Option.none

def psKernelExprV2IndexedPush
    (arena : PsKernelExprV2IndexedArena)
    (entry : PsKernelExprV2Entry) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  let key := Nat.succ arena.size;
  match
      psKernelExprV2IndexInsertFuel
        (Nat.succ key)
        arena.index
        key
        entry with
  | Except.error error =>
      Except.error error
  | Except.ok index =>
      Except.ok
        (Prod.mk
          {
            index := index
            size := key
          }
          arena.size)
