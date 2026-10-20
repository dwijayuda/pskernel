import Ps.KernelCore.Research.ExprV2PagedValidation

/-
PSC1-portable Expression V2 / M3 sharing-aware loose-bound-variable lifting.

Inputs are fully replay-validated into canonical immutable paged DAGs.
No unchecked metadata can affect pruning. New nodes come exclusively from
checked smart constructors, unchanged nodes retain their IDs, and memo keys
include the original node ID, binder cutoff, and lift amount.

All recursion is structurally fuel-bounded; no partial/unsafe, native pointer
identity, mutable global state, or trusted compiler callback is used.
This is a temporary differential storage pilot, NOT wired into production kernel reductions. Once qualified, refactor the algorithm into one canonical implementation instead of maintaining duplicated workers indefinitely.
-/

structure PsKernelExprV2PagedLiftMemo where
  source : Nat
  cutoff : Nat
  amount : Nat
  result : Nat

structure PsKernelExprV2PagedLiftState where
  arena : PsKernelExprV2PagedArena
  memo : List PsKernelExprV2PagedLiftMemo

def psKernelExprV2PagedLiftMemoFind
    (entries : List PsKernelExprV2PagedLiftMemo)
    (source cutoff amount : Nat) : Option Nat :=
  match entries with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then
        if Nat.beq first.cutoff cutoff then
          if Nat.beq first.amount amount then
            Option.some first.result
          else
            psKernelExprV2PagedLiftMemoFind
              rest source cutoff amount
        else
          psKernelExprV2PagedLiftMemoFind
            rest source cutoff amount
      else
        psKernelExprV2PagedLiftMemoFind
          rest source cutoff amount

def psKernelExprV2PagedLiftFinish
    (state : PsKernelExprV2PagedLiftState)
    (source cutoff amount result : Nat) :
    PsKernelExprV2PagedLiftState × Nat :=
  let memo : PsKernelExprV2PagedLiftMemo := {
    source := source
    cutoff := cutoff
    amount := amount
    result := result
  };
  let next : PsKernelExprV2PagedLiftState := {
    arena := state.arena
    memo := List.cons memo state.memo
  };
  Prod.mk next result

def psKernelExprV2PagedLiftRebuilt
    (state : PsKernelExprV2PagedLiftState)
    (source cutoff amount : Nat)
    (rebuilt : PsKernelExprV2PagedArena × Nat) :
    PsKernelExprV2PagedLiftState × Nat :=
  let next : PsKernelExprV2PagedLiftState := {
    arena := Prod.fst rebuilt
    memo := state.memo
  };
  psKernelExprV2PagedLiftFinish
    next source cutoff amount (Prod.snd rebuilt)

/- Reordered smart builders usable as first-class functions in PSC1. -/
def psKernelExprV2PagedLiftMkLam
    (name : PsKernelName) (binderInfo : PsKernelBinderInfo)
    (arena : PsKernelExprV2PagedArena)
    (type body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedMkLam arena name type body binderInfo

def psKernelExprV2PagedLiftMkForall
    (name : PsKernelName) (binderInfo : PsKernelBinderInfo)
    (arena : PsKernelExprV2PagedArena)
    (type body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedMkForall arena name type body binderInfo

def psKernelExprV2PagedLiftMkLet
    (name : PsKernelName) (nondep : Bool)
    (arena : PsKernelExprV2PagedArena)
    (type value body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedMkLet arena name type value body nondep

def psKernelExprV2PagedLiftMkMData
    (tag : Nat)
    (arena : PsKernelExprV2PagedArena)
    (body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedMkMData arena tag body

def psKernelExprV2PagedLiftMkProj
    (name : PsKernelName) (index : Nat)
    (arena : PsKernelExprV2PagedArena)
    (body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedMkProj arena name index body

def psKernelExprV2PagedLiftOne
    (recurse :
      PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedLiftState × Nat))
    (builder :
      PsKernelExprV2PagedArena -> Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (state : PsKernelExprV2PagedLiftState)
    (source child cutoff childCutoff amount : Nat) :
    Except String (PsKernelExprV2PagedLiftState × Nat) :=
  match recurse state child childCutoff amount with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      let nextState := Prod.fst first;
      let nextChild := Prod.snd first;
      if Nat.beq nextChild child then
        Except.ok
          (psKernelExprV2PagedLiftFinish
            nextState source cutoff amount source)
      else
        match builder nextState.arena nextChild with
        | Except.error error => Except.error error
        | Except.ok rebuilt =>
            Except.ok
              (psKernelExprV2PagedLiftRebuilt
                nextState source cutoff amount rebuilt)

def psKernelExprV2PagedLiftTwo
    (recurse :
      PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedLiftState × Nat))
    (builder :
      PsKernelExprV2PagedArena -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (state : PsKernelExprV2PagedLiftState)
    (source left right cutoff leftCutoff rightCutoff amount : Nat) :
    Except String (PsKernelExprV2PagedLiftState × Nat) :=
  match recurse state left leftCutoff amount with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      let nextState := Prod.fst first;
      let nextLeft := Prod.snd first;
      match recurse nextState right rightCutoff amount with
      | Except.error error =>
          Except.error error
      | Except.ok second =>
          let finalState := Prod.fst second;
          let nextRight := Prod.snd second;
          if Nat.beq nextLeft left then
            if Nat.beq nextRight right then
              Except.ok
                (psKernelExprV2PagedLiftFinish
                  finalState source cutoff amount source)
            else
              match builder finalState.arena nextLeft nextRight with
              | Except.error error => Except.error error
              | Except.ok rebuilt =>
                  Except.ok
                    (psKernelExprV2PagedLiftRebuilt
                      finalState source cutoff amount rebuilt)
          else
            match builder finalState.arena nextLeft nextRight with
            | Except.error error => Except.error error
            | Except.ok rebuilt =>
                Except.ok
                  (psKernelExprV2PagedLiftRebuilt
                    finalState source cutoff amount rebuilt)

def psKernelExprV2PagedLiftThree
    (recurse :
      PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedLiftState × Nat))
    (builder :
      PsKernelExprV2PagedArena -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (state : PsKernelExprV2PagedLiftState)
    (source firstId secondId thirdId cutoff amount : Nat) :
    Except String (PsKernelExprV2PagedLiftState × Nat) :=
  match recurse state firstId cutoff amount with
  | Except.error error => Except.error error
  | Except.ok first =>
      let firstState := Prod.fst first;
      let newFirst := Prod.snd first;
      match recurse firstState secondId cutoff amount with
      | Except.error error => Except.error error
      | Except.ok second =>
          let secondState := Prod.fst second;
          let newSecond := Prod.snd second;
          match recurse secondState thirdId (Nat.succ cutoff) amount with
          | Except.error error => Except.error error
          | Except.ok third =>
              let thirdState := Prod.fst third;
              let newThird := Prod.snd third;
              if Nat.beq newFirst firstId then
                if Nat.beq newSecond secondId then
                  if Nat.beq newThird thirdId then
                    Except.ok
                      (psKernelExprV2PagedLiftFinish
                        thirdState source cutoff amount source)
                  else
                    match builder
                        thirdState.arena newFirst newSecond newThird with
                    | Except.error error => Except.error error
                    | Except.ok rebuilt =>
                        Except.ok
                          (psKernelExprV2PagedLiftRebuilt
                            thirdState source cutoff amount rebuilt)
                else
                  match builder
                      thirdState.arena newFirst newSecond newThird with
                  | Except.error error => Except.error error
                  | Except.ok rebuilt =>
                      Except.ok
                        (psKernelExprV2PagedLiftRebuilt
                          thirdState source cutoff amount rebuilt)
              else
                match builder
                    thirdState.arena newFirst newSecond newThird with
                | Except.error error => Except.error error
                | Except.ok rebuilt =>
                    Except.ok
                      (psKernelExprV2PagedLiftRebuilt
                        thirdState source cutoff amount rebuilt)

def psKernelExprV2PagedLiftWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
    Except String (PsKernelExprV2PagedLiftState × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsKernelExprV2PagedLiftState) =>
        fun (_source : Nat) =>
          fun (_cutoff : Nat) =>
            fun (_amount : Nat) =>
              Except.error "PSKERNEL_V2_PORTABLE_LIFT_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
          Except String (PsKernelExprV2PagedLiftState × Nat) :=
        psKernelExprV2PagedLiftWithFuel remaining;
      fun (state : PsKernelExprV2PagedLiftState) =>
        fun (source : Nat) =>
          fun (cutoff : Nat) =>
            fun (amount : Nat) =>
              if Nat.beq amount 0 then
                Except.ok (Prod.mk state source)
              else
                match psKernelExprV2PagedFind state.arena source with
                | Option.none =>
                    Except.error "PSKERNEL_V2_PORTABLE_LIFT_INVALID_NODE"
                | Option.some entry =>
                    if Nat.ble entry.looseRange cutoff then
                      Except.ok (Prod.mk state source)
                    else
                      match psKernelExprV2PagedLiftMemoFind
                          state.memo source cutoff amount with
                      | Option.some prior =>
                          Except.ok (Prod.mk state prior)
                      | Option.none =>
                          match entry.node with
                          | PsKernelExprV2Node.bvar index =>
                              if Nat.blt index cutoff then
                                Except.ok
                                  (psKernelExprV2PagedLiftFinish
                                    state source cutoff amount source)
                              else
                                match psKernelExprV2PagedMkBVar
                                    state.arena (Nat.add index amount) with
                                | Except.error error => Except.error error
                                | Except.ok rebuilt =>
                                    Except.ok
                                      (psKernelExprV2PagedLiftRebuilt
                                        state source cutoff amount rebuilt)
                          | PsKernelExprV2Node.app fn arg =>
                              psKernelExprV2PagedLiftTwo
                                smaller
                                psKernelExprV2PagedMkApp
                                state source fn arg
                                cutoff cutoff cutoff amount
                          | PsKernelExprV2Node.lam name type body binderInfo =>
                              psKernelExprV2PagedLiftTwo
                                smaller
                                (psKernelExprV2PagedLiftMkLam name binderInfo)
                                state source type body
                                cutoff cutoff (Nat.succ cutoff) amount
                          | PsKernelExprV2Node.forallE name type body binderInfo =>
                              psKernelExprV2PagedLiftTwo
                                smaller
                                (psKernelExprV2PagedLiftMkForall name binderInfo)
                                state source type body
                                cutoff cutoff (Nat.succ cutoff) amount
                          | PsKernelExprV2Node.letE name type value body nondep =>
                              psKernelExprV2PagedLiftThree
                                smaller
                                (psKernelExprV2PagedLiftMkLet name nondep)
                                state source type value body cutoff amount
                          | PsKernelExprV2Node.mdata tag body =>
                              psKernelExprV2PagedLiftOne
                                smaller
                                (psKernelExprV2PagedLiftMkMData tag)
                                state source body cutoff cutoff amount
                          | PsKernelExprV2Node.proj typeName index body =>
                              psKernelExprV2PagedLiftOne
                                smaller
                                (psKernelExprV2PagedLiftMkProj typeName index)
                                state source body cutoff cutoff amount
                          | _ =>
                              Except.ok
                                (psKernelExprV2PagedLiftFinish
                                  state source cutoff amount source)

def psKernelExprV2PagedLiftChecked
    (source : PsKernelExprV2PagedArena)
    (root cutoff amount : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2PagedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_PORTABLE_LIFT_INVALID_ROOT"
      | Option.some rootEntry =>
          let initial : PsKernelExprV2PagedLiftState := {
            arena := canonical
            memo := List.nil
          };
          match
              psKernelExprV2PagedLiftWithFuel
                (Nat.succ rootEntry.depth)
                initial root cutoff amount with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              let transformed := Prod.fst result;
              let newRoot := Prod.snd result;
              match psKernelExprV2PagedValidate transformed.arena with
              | Except.error error =>
                  Except.error error
              | Except.ok checked =>
                  Except.ok (Prod.mk checked newRoot)
