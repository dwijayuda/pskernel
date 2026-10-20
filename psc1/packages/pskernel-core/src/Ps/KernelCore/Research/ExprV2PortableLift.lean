import Ps.KernelCore.Research.ExprV2PortableValidation

/-
PSC1-portable Expression V2 / M3 sharing-aware loose-bound-variable lifting.

Inputs are fully replay-validated into canonical immutable chunked DAGs.
No unchecked metadata can affect pruning. New nodes come exclusively from
checked smart constructors, unchanged nodes retain their IDs, and memo keys
include the original node ID, binder cutoff, and lift amount.

All recursion is structurally fuel-bounded; no partial/unsafe, native pointer
identity, mutable global state, or trusted compiler callback is used.
This is isolated research, NOT wired into production kernel reductions.
-/

structure PsKernelExprV2PortableLiftMemo where
  source : Nat
  cutoff : Nat
  amount : Nat
  result : Nat

structure PsKernelExprV2PortableLiftState where
  arena : PsKernelExprV2ChunkedArena
  memo : List PsKernelExprV2PortableLiftMemo

def psKernelExprV2PortableLiftMemoFind
    (entries : List PsKernelExprV2PortableLiftMemo)
    (source cutoff amount : Nat) : Option Nat :=
  match entries with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then
        if Nat.beq first.cutoff cutoff then
          if Nat.beq first.amount amount then
            Option.some first.result
          else
            psKernelExprV2PortableLiftMemoFind
              rest source cutoff amount
        else
          psKernelExprV2PortableLiftMemoFind
            rest source cutoff amount
      else
        psKernelExprV2PortableLiftMemoFind
          rest source cutoff amount

def psKernelExprV2PortableLiftFinish
    (state : PsKernelExprV2PortableLiftState)
    (source cutoff amount result : Nat) :
    PsKernelExprV2PortableLiftState × Nat :=
  let memo : PsKernelExprV2PortableLiftMemo := {
    source := source
    cutoff := cutoff
    amount := amount
    result := result
  };
  let next : PsKernelExprV2PortableLiftState := {
    arena := state.arena
    memo := List.cons memo state.memo
  };
  Prod.mk next result

def psKernelExprV2PortableLiftRebuilt
    (state : PsKernelExprV2PortableLiftState)
    (source cutoff amount : Nat)
    (rebuilt : PsKernelExprV2ChunkedArena × Nat) :
    PsKernelExprV2PortableLiftState × Nat :=
  let next : PsKernelExprV2PortableLiftState := {
    arena := Prod.fst rebuilt
    memo := state.memo
  };
  psKernelExprV2PortableLiftFinish
    next source cutoff amount (Prod.snd rebuilt)

/- Reordered smart builders usable as first-class functions in PSC1. -/
def psKernelExprV2PortableLiftMkLam
    (name : PsKernelName) (binderInfo : PsKernelBinderInfo)
    (arena : PsKernelExprV2ChunkedArena)
    (type body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedMkLam arena name type body binderInfo

def psKernelExprV2PortableLiftMkForall
    (name : PsKernelName) (binderInfo : PsKernelBinderInfo)
    (arena : PsKernelExprV2ChunkedArena)
    (type body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedMkForall arena name type body binderInfo

def psKernelExprV2PortableLiftMkLet
    (name : PsKernelName) (nondep : Bool)
    (arena : PsKernelExprV2ChunkedArena)
    (type value body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedMkLet arena name type value body nondep

def psKernelExprV2PortableLiftMkMData
    (tag : Nat)
    (arena : PsKernelExprV2ChunkedArena)
    (body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedMkMData arena tag body

def psKernelExprV2PortableLiftMkProj
    (name : PsKernelName) (index : Nat)
    (arena : PsKernelExprV2ChunkedArena)
    (body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedMkProj arena name index body

def psKernelExprV2PortableLiftOne
    (recurse :
      PsKernelExprV2PortableLiftState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PortableLiftState × Nat))
    (builder :
      PsKernelExprV2ChunkedArena -> Nat ->
      Except String (PsKernelExprV2ChunkedArena × Nat))
    (state : PsKernelExprV2PortableLiftState)
    (source child cutoff childCutoff amount : Nat) :
    Except String (PsKernelExprV2PortableLiftState × Nat) :=
  match recurse state child childCutoff amount with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      let nextState := Prod.fst first;
      let nextChild := Prod.snd first;
      if Nat.beq nextChild child then
        Except.ok
          (psKernelExprV2PortableLiftFinish
            nextState source cutoff amount source)
      else
        match builder nextState.arena nextChild with
        | Except.error error => Except.error error
        | Except.ok rebuilt =>
            Except.ok
              (psKernelExprV2PortableLiftRebuilt
                nextState source cutoff amount rebuilt)

def psKernelExprV2PortableLiftTwo
    (recurse :
      PsKernelExprV2PortableLiftState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PortableLiftState × Nat))
    (builder :
      PsKernelExprV2ChunkedArena -> Nat -> Nat ->
      Except String (PsKernelExprV2ChunkedArena × Nat))
    (state : PsKernelExprV2PortableLiftState)
    (source left right cutoff leftCutoff rightCutoff amount : Nat) :
    Except String (PsKernelExprV2PortableLiftState × Nat) :=
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
                (psKernelExprV2PortableLiftFinish
                  finalState source cutoff amount source)
            else
              match builder finalState.arena nextLeft nextRight with
              | Except.error error => Except.error error
              | Except.ok rebuilt =>
                  Except.ok
                    (psKernelExprV2PortableLiftRebuilt
                      finalState source cutoff amount rebuilt)
          else
            match builder finalState.arena nextLeft nextRight with
            | Except.error error => Except.error error
            | Except.ok rebuilt =>
                Except.ok
                  (psKernelExprV2PortableLiftRebuilt
                    finalState source cutoff amount rebuilt)

def psKernelExprV2PortableLiftThree
    (recurse :
      PsKernelExprV2PortableLiftState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PortableLiftState × Nat))
    (builder :
      PsKernelExprV2ChunkedArena -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2ChunkedArena × Nat))
    (state : PsKernelExprV2PortableLiftState)
    (source firstId secondId thirdId cutoff amount : Nat) :
    Except String (PsKernelExprV2PortableLiftState × Nat) :=
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
                      (psKernelExprV2PortableLiftFinish
                        thirdState source cutoff amount source)
                  else
                    match builder
                        thirdState.arena newFirst newSecond newThird with
                    | Except.error error => Except.error error
                    | Except.ok rebuilt =>
                        Except.ok
                          (psKernelExprV2PortableLiftRebuilt
                            thirdState source cutoff amount rebuilt)
                else
                  match builder
                      thirdState.arena newFirst newSecond newThird with
                  | Except.error error => Except.error error
                  | Except.ok rebuilt =>
                      Except.ok
                        (psKernelExprV2PortableLiftRebuilt
                          thirdState source cutoff amount rebuilt)
              else
                match builder
                    thirdState.arena newFirst newSecond newThird with
                | Except.error error => Except.error error
                | Except.ok rebuilt =>
                    Except.ok
                      (psKernelExprV2PortableLiftRebuilt
                        thirdState source cutoff amount rebuilt)

def psKernelExprV2PortableLiftWithFuel
    (fuel : Nat) :
    PsKernelExprV2PortableLiftState -> Nat -> Nat -> Nat ->
    Except String (PsKernelExprV2PortableLiftState × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsKernelExprV2PortableLiftState) =>
        fun (_source : Nat) =>
          fun (_cutoff : Nat) =>
            fun (_amount : Nat) =>
              Except.error "PSKERNEL_V2_PORTABLE_LIFT_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PortableLiftState -> Nat -> Nat -> Nat ->
          Except String (PsKernelExprV2PortableLiftState × Nat) :=
        psKernelExprV2PortableLiftWithFuel remaining;
      fun (state : PsKernelExprV2PortableLiftState) =>
        fun (source : Nat) =>
          fun (cutoff : Nat) =>
            fun (amount : Nat) =>
              if Nat.beq amount 0 then
                Except.ok (Prod.mk state source)
              else
                match psKernelExprV2ChunkedFind state.arena source with
                | Option.none =>
                    Except.error "PSKERNEL_V2_PORTABLE_LIFT_INVALID_NODE"
                | Option.some entry =>
                    if Nat.ble entry.looseRange cutoff then
                      Except.ok (Prod.mk state source)
                    else
                      match psKernelExprV2PortableLiftMemoFind
                          state.memo source cutoff amount with
                      | Option.some prior =>
                          Except.ok (Prod.mk state prior)
                      | Option.none =>
                          match entry.node with
                          | PsKernelExprV2Node.bvar index =>
                              if Nat.blt index cutoff then
                                Except.ok
                                  (psKernelExprV2PortableLiftFinish
                                    state source cutoff amount source)
                              else
                                match psKernelExprV2ChunkedMkBVar
                                    state.arena (Nat.add index amount) with
                                | Except.error error => Except.error error
                                | Except.ok rebuilt =>
                                    Except.ok
                                      (psKernelExprV2PortableLiftRebuilt
                                        state source cutoff amount rebuilt)
                          | PsKernelExprV2Node.app fn arg =>
                              psKernelExprV2PortableLiftTwo
                                smaller
                                psKernelExprV2ChunkedMkApp
                                state source fn arg
                                cutoff cutoff cutoff amount
                          | PsKernelExprV2Node.lam name type body binderInfo =>
                              psKernelExprV2PortableLiftTwo
                                smaller
                                (psKernelExprV2PortableLiftMkLam name binderInfo)
                                state source type body
                                cutoff cutoff (Nat.succ cutoff) amount
                          | PsKernelExprV2Node.forallE name type body binderInfo =>
                              psKernelExprV2PortableLiftTwo
                                smaller
                                (psKernelExprV2PortableLiftMkForall name binderInfo)
                                state source type body
                                cutoff cutoff (Nat.succ cutoff) amount
                          | PsKernelExprV2Node.letE name type value body nondep =>
                              psKernelExprV2PortableLiftThree
                                smaller
                                (psKernelExprV2PortableLiftMkLet name nondep)
                                state source type value body cutoff amount
                          | PsKernelExprV2Node.mdata tag body =>
                              psKernelExprV2PortableLiftOne
                                smaller
                                (psKernelExprV2PortableLiftMkMData tag)
                                state source body cutoff cutoff amount
                          | PsKernelExprV2Node.proj typeName index body =>
                              psKernelExprV2PortableLiftOne
                                smaller
                                (psKernelExprV2PortableLiftMkProj typeName index)
                                state source body cutoff cutoff amount
                          | _ =>
                              Except.ok
                                (psKernelExprV2PortableLiftFinish
                                  state source cutoff amount source)

def psKernelExprV2PortableLiftChecked
    (source : PsKernelExprV2ChunkedArena)
    (root cutoff amount : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2PortableValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2ChunkedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_PORTABLE_LIFT_INVALID_ROOT"
      | Option.some rootEntry =>
          let initial : PsKernelExprV2PortableLiftState := {
            arena := canonical
            memo := List.nil
          };
          match
              psKernelExprV2PortableLiftWithFuel
                (Nat.succ rootEntry.depth)
                initial root cutoff amount with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              let transformed := Prod.fst result;
              let newRoot := Prod.snd result;
              match psKernelExprV2PortableValidate transformed.arena with
              | Except.error error =>
                  Except.error error
              | Except.ok checked =>
                  Except.ok (Prod.mk checked newRoot)
