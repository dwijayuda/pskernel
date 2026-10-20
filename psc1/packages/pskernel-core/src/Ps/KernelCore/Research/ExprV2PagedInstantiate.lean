import Ps.KernelCore.Research.ExprV2PagedLift

/-
PSC1 Expression V2 / M3 portable capture-avoiding instantiate1.

This is a temporary paged-storage comparison against the independent chunked research worker and the production (unchanged) kernel implementation. Refactor shared algorithms into one implementation after parity qualifies.

This remains a checked research alternative to the production (unchanged)
psKernelExprInstantiate1. The initial input DAG is independently validated
and replayed. Every resulting DAG node is added through checked immutable
paged smart constructors. The final graph is replay-validated.

The operation memo is scoped to its own invocation and keyed by
(sourceNode, binderDepth, replacementId). Child references are node IDs in the
same immutable arena. The cutoff-adjusted replacement is lifted using the
already-qualified, portable V2 lifting worker with a separate memo and
discarded memo state. Neither cached hash nor node IDs grant proof authority.
-/

structure PsKernelExprV2PagedInstMemo where
  source : Nat
  depth : Nat
  replacement : Nat
  result : Nat

structure PsKernelExprV2PagedInstState where
  arena : PsKernelExprV2PagedArena
  memo : List PsKernelExprV2PagedInstMemo

def psKernelExprV2PagedInstMemoFind
    (memo : List PsKernelExprV2PagedInstMemo)
    (source depth replacement : Nat) : Option Nat :=
  match memo with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then
        if Nat.beq first.depth depth then
          if Nat.beq first.replacement replacement then
            Option.some first.result
          else
            psKernelExprV2PagedInstMemoFind
              rest source depth replacement
        else
          psKernelExprV2PagedInstMemoFind
            rest source depth replacement
      else
        psKernelExprV2PagedInstMemoFind
          rest source depth replacement

def psKernelExprV2PagedInstFinish
    (state : PsKernelExprV2PagedInstState)
    (source depth replacement result : Nat) :
    PsKernelExprV2PagedInstState × Nat :=
  let item : PsKernelExprV2PagedInstMemo := {
    source := source
    depth := depth
    replacement := replacement
    result := result
  };
  let next : PsKernelExprV2PagedInstState := {
    arena := state.arena
    memo := List.cons item state.memo
  };
  Prod.mk next result

def psKernelExprV2PagedInstRebuilt
    (state : PsKernelExprV2PagedInstState)
    (source depth replacement : Nat)
    (rebuilt : PsKernelExprV2PagedArena × Nat) :
    PsKernelExprV2PagedInstState × Nat :=
  let next : PsKernelExprV2PagedInstState := {
    arena := Prod.fst rebuilt
    memo := state.memo
  };
  psKernelExprV2PagedInstFinish
    next source depth replacement (Prod.snd rebuilt)

/- Reuse binder-preserving builder adapters from portable lifting. -/
def psKernelExprV2PagedInstOne
    (recurse :
      PsKernelExprV2PagedInstState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedInstState × Nat))
    (builder :
      PsKernelExprV2PagedArena -> Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (state : PsKernelExprV2PagedInstState)
    (source child depth childDepth replacement : Nat) :
    Except String (PsKernelExprV2PagedInstState × Nat) :=
  match recurse state child childDepth replacement with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      let nextState := Prod.fst first;
      let nextChild := Prod.snd first;
      if Nat.beq nextChild child then
        Except.ok
          (psKernelExprV2PagedInstFinish
            nextState source depth replacement source)
      else
        match builder nextState.arena nextChild with
        | Except.error error => Except.error error
        | Except.ok rebuilt =>
            Except.ok
              (psKernelExprV2PagedInstRebuilt
                nextState source depth replacement rebuilt)

def psKernelExprV2PagedInstTwo
    (recurse :
      PsKernelExprV2PagedInstState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedInstState × Nat))
    (builder :
      PsKernelExprV2PagedArena -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (state : PsKernelExprV2PagedInstState)
    (source left right depth leftDepth rightDepth replacement : Nat) :
    Except String (PsKernelExprV2PagedInstState × Nat) :=
  match recurse state left leftDepth replacement with
  | Except.error error => Except.error error
  | Except.ok first =>
      let firstState := Prod.fst first;
      let newLeft := Prod.snd first;
      match recurse firstState right rightDepth replacement with
      | Except.error error => Except.error error
      | Except.ok second =>
          let finalState := Prod.fst second;
          let newRight := Prod.snd second;
          if Nat.beq newLeft left then
            if Nat.beq newRight right then
              Except.ok
                (psKernelExprV2PagedInstFinish
                  finalState source depth replacement source)
            else
              match builder finalState.arena newLeft newRight with
              | Except.error error => Except.error error
              | Except.ok rebuilt =>
                  Except.ok
                    (psKernelExprV2PagedInstRebuilt
                      finalState source depth replacement rebuilt)
          else
            match builder finalState.arena newLeft newRight with
            | Except.error error => Except.error error
            | Except.ok rebuilt =>
                Except.ok
                  (psKernelExprV2PagedInstRebuilt
                    finalState source depth replacement rebuilt)

def psKernelExprV2PagedInstThree
    (recurse :
      PsKernelExprV2PagedInstState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedInstState × Nat))
    (builder :
      PsKernelExprV2PagedArena -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (state : PsKernelExprV2PagedInstState)
    (source firstId secondId thirdId depth replacement : Nat) :
    Except String (PsKernelExprV2PagedInstState × Nat) :=
  match recurse state firstId depth replacement with
  | Except.error error => Except.error error
  | Except.ok first =>
      let firstState := Prod.fst first;
      let newFirst := Prod.snd first;
      match recurse firstState secondId depth replacement with
      | Except.error error => Except.error error
      | Except.ok second =>
          let secondState := Prod.fst second;
          let newSecond := Prod.snd second;
          match recurse secondState thirdId (Nat.succ depth) replacement with
          | Except.error error => Except.error error
          | Except.ok third =>
              let lastState := Prod.fst third;
              let newThird := Prod.snd third;
              if Nat.beq newFirst firstId then
                if Nat.beq newSecond secondId then
                  if Nat.beq newThird thirdId then
                    Except.ok
                      (psKernelExprV2PagedInstFinish
                        lastState source depth replacement source)
                  else
                    match builder
                        lastState.arena newFirst newSecond newThird with
                    | Except.error error => Except.error error
                    | Except.ok rebuilt =>
                        Except.ok
                          (psKernelExprV2PagedInstRebuilt
                            lastState source depth replacement rebuilt)
                else
                  match builder
                      lastState.arena newFirst newSecond newThird with
                  | Except.error error => Except.error error
                  | Except.ok rebuilt =>
                      Except.ok
                        (psKernelExprV2PagedInstRebuilt
                          lastState source depth replacement rebuilt)
              else
                match builder
                    lastState.arena newFirst newSecond newThird with
                | Except.error error => Except.error error
                | Except.ok rebuilt =>
                    Except.ok
                      (psKernelExprV2PagedInstRebuilt
                        lastState source depth replacement rebuilt)

/- For a hit on BVar(depth), substitute shift(replacement, 0, depth). -/
def psKernelExprV2PagedInstReplace
    (state : PsKernelExprV2PagedInstState)
    (source depth replacement : Nat) :
    Except String (PsKernelExprV2PagedInstState × Nat) :=
  match psKernelExprV2PagedFind state.arena replacement with
  | Option.none =>
      Except.error "PSKERNEL_V2_INST_INVALID_REPLACEMENT"
  | Option.some entry =>
      let liftState : PsKernelExprV2PagedLiftState := {
        arena := state.arena
        memo := List.nil
      };
      match
          psKernelExprV2PagedLiftWithFuel
            (Nat.succ entry.depth)
            liftState replacement 0 depth with
      | Except.error error =>
          Except.error error
      | Except.ok lifted =>
          let liftedState : PsKernelExprV2PagedLiftState :=
            Prod.fst lifted;
          let output : PsKernelExprV2PagedInstState := {
            arena := liftedState.arena
            memo := state.memo
          };
          Except.ok
            (psKernelExprV2PagedInstFinish
              output source depth replacement (Prod.snd lifted))

def psKernelExprV2PagedInstWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedInstState -> Nat -> Nat -> Nat ->
    Except String (PsKernelExprV2PagedInstState × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsKernelExprV2PagedInstState) =>
        fun (_source : Nat) =>
          fun (_depth : Nat) =>
            fun (_replacement : Nat) =>
              Except.error "PSKERNEL_V2_INST_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedInstState -> Nat -> Nat -> Nat ->
          Except String (PsKernelExprV2PagedInstState × Nat) :=
        psKernelExprV2PagedInstWithFuel remaining;
      fun (state : PsKernelExprV2PagedInstState) =>
        fun (source : Nat) =>
          fun (depth : Nat) =>
            fun (replacement : Nat) =>
              match psKernelExprV2PagedFind state.arena source with
              | Option.none =>
                  Except.error "PSKERNEL_V2_INST_INVALID_NODE"
              | Option.some entry =>
                  if Nat.ble entry.looseRange depth then
                    Except.ok (Prod.mk state source)
                  else
                    match psKernelExprV2PagedInstMemoFind
                        state.memo source depth replacement with
                    | Option.some result =>
                        Except.ok (Prod.mk state result)
                    | Option.none =>
                        match entry.node with
                        | PsKernelExprV2Node.bvar index =>
                            if Nat.blt index depth then
                              Except.ok
                                (psKernelExprV2PagedInstFinish
                                  state source depth replacement source)
                            else if Nat.beq index depth then
                              psKernelExprV2PagedInstReplace
                                state source depth replacement
                            else
                              match psKernelExprV2PagedMkBVar
                                  state.arena (Nat.sub index 1) with
                              | Except.error error => Except.error error
                              | Except.ok rebuilt =>
                                  Except.ok
                                    (psKernelExprV2PagedInstRebuilt
                                      state source depth replacement rebuilt)
                        | PsKernelExprV2Node.app fn arg =>
                            psKernelExprV2PagedInstTwo
                              smaller psKernelExprV2PagedMkApp
                              state source fn arg
                              depth depth depth replacement
                        | PsKernelExprV2Node.lam name type body binderInfo =>
                            psKernelExprV2PagedInstTwo
                              smaller
                              (psKernelExprV2PagedLiftMkLam name binderInfo)
                              state source type body
                              depth depth (Nat.succ depth) replacement
                        | PsKernelExprV2Node.forallE name type body binderInfo =>
                            psKernelExprV2PagedInstTwo
                              smaller
                              (psKernelExprV2PagedLiftMkForall name binderInfo)
                              state source type body
                              depth depth (Nat.succ depth) replacement
                        | PsKernelExprV2Node.letE name type value body nondep =>
                            psKernelExprV2PagedInstThree
                              smaller
                              (psKernelExprV2PagedLiftMkLet name nondep)
                              state source type value body depth replacement
                        | PsKernelExprV2Node.mdata tag body =>
                            psKernelExprV2PagedInstOne
                              smaller
                              (psKernelExprV2PagedLiftMkMData tag)
                              state source body depth depth replacement
                        | PsKernelExprV2Node.proj typeName index body =>
                            psKernelExprV2PagedInstOne
                              smaller
                              (psKernelExprV2PagedLiftMkProj typeName index)
                              state source body depth depth replacement
                        | _ =>
                            Except.ok
                              (psKernelExprV2PagedInstFinish
                                state source depth replacement source)

/-
Research-only checked entrypoint. Rechecks every input node, ensures the
replacement is in this exact canonical arena, performs the capture-avoiding
transformation, and rechecks every output node. No trust in arbitrary cached
metadata or exported node IDs.
-/
def psKernelExprV2PagedInstantiate1Checked
    (source : PsKernelExprV2PagedArena)
    (root replacement : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2PagedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_INST_INVALID_ROOT"
      | Option.some rootEntry =>
          match psKernelExprV2PagedFind canonical replacement with
          | Option.none =>
              Except.error "PSKERNEL_V2_INST_INVALID_REPLACEMENT"
          | Option.some _ =>
              let initial : PsKernelExprV2PagedInstState := {
                arena := canonical
                memo := List.nil
              };
              match
                  psKernelExprV2PagedInstWithFuel
                    (Nat.succ rootEntry.depth)
                    initial root 0 replacement with
              | Except.error error =>
                  Except.error error
              | Except.ok finished =>
                  let finishedState := Prod.fst finished;
                  let result := Prod.snd finished;
                  match psKernelExprV2PagedValidate finishedState.arena with
                  | Except.error error => Except.error error
                  | Except.ok validated =>
                      Except.ok (Prod.mk validated result)
