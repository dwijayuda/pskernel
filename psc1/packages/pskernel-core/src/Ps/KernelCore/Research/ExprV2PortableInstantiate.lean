import Ps.KernelCore.Research.ExprV2PortableLift

/-
PSC1 Expression V2 / M3 portable capture-avoiding instantiate1.

This is a checked research alternative to the production (unchanged)
psKernelExprInstantiate1. The initial input DAG is independently validated
and replayed. Every resulting DAG node is added through checked immutable
chunked smart constructors. The final graph is replay-validated.

The operation memo is scoped to its own invocation and keyed by
(sourceNode, binderDepth, replacementId). Child references are node IDs in the
same immutable arena. The cutoff-adjusted replacement is lifted using the
already-qualified, portable V2 lifting worker with a separate memo and
discarded memo state. Neither cached hash nor node IDs grant proof authority.
-/

structure PsKernelExprV2PortableInstMemo where
  source : Nat
  depth : Nat
  replacement : Nat
  result : Nat

structure PsKernelExprV2PortableInstState where
  arena : PsKernelExprV2ChunkedArena
  memo : List PsKernelExprV2PortableInstMemo

def psKernelExprV2PortableInstMemoFind
    (memo : List PsKernelExprV2PortableInstMemo)
    (source depth replacement : Nat) : Option Nat :=
  match memo with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then
        if Nat.beq first.depth depth then
          if Nat.beq first.replacement replacement then
            Option.some first.result
          else
            psKernelExprV2PortableInstMemoFind
              rest source depth replacement
        else
          psKernelExprV2PortableInstMemoFind
            rest source depth replacement
      else
        psKernelExprV2PortableInstMemoFind
          rest source depth replacement

def psKernelExprV2PortableInstFinish
    (state : PsKernelExprV2PortableInstState)
    (source depth replacement result : Nat) :
    PsKernelExprV2PortableInstState × Nat :=
  let item : PsKernelExprV2PortableInstMemo := {
    source := source
    depth := depth
    replacement := replacement
    result := result
  };
  let next : PsKernelExprV2PortableInstState := {
    arena := state.arena
    memo := List.cons item state.memo
  };
  Prod.mk next result

def psKernelExprV2PortableInstRebuilt
    (state : PsKernelExprV2PortableInstState)
    (source depth replacement : Nat)
    (rebuilt : PsKernelExprV2ChunkedArena × Nat) :
    PsKernelExprV2PortableInstState × Nat :=
  let next : PsKernelExprV2PortableInstState := {
    arena := Prod.fst rebuilt
    memo := state.memo
  };
  psKernelExprV2PortableInstFinish
    next source depth replacement (Prod.snd rebuilt)

/- Reuse binder-preserving builder adapters from portable lifting. -/
def psKernelExprV2PortableInstOne
    (recurse :
      PsKernelExprV2PortableInstState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PortableInstState × Nat))
    (builder :
      PsKernelExprV2ChunkedArena -> Nat ->
      Except String (PsKernelExprV2ChunkedArena × Nat))
    (state : PsKernelExprV2PortableInstState)
    (source child depth childDepth replacement : Nat) :
    Except String (PsKernelExprV2PortableInstState × Nat) :=
  match recurse state child childDepth replacement with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      let nextState := Prod.fst first;
      let nextChild := Prod.snd first;
      if Nat.beq nextChild child then
        Except.ok
          (psKernelExprV2PortableInstFinish
            nextState source depth replacement source)
      else
        match builder nextState.arena nextChild with
        | Except.error error => Except.error error
        | Except.ok rebuilt =>
            Except.ok
              (psKernelExprV2PortableInstRebuilt
                nextState source depth replacement rebuilt)

def psKernelExprV2PortableInstTwo
    (recurse :
      PsKernelExprV2PortableInstState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PortableInstState × Nat))
    (builder :
      PsKernelExprV2ChunkedArena -> Nat -> Nat ->
      Except String (PsKernelExprV2ChunkedArena × Nat))
    (state : PsKernelExprV2PortableInstState)
    (source left right depth leftDepth rightDepth replacement : Nat) :
    Except String (PsKernelExprV2PortableInstState × Nat) :=
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
                (psKernelExprV2PortableInstFinish
                  finalState source depth replacement source)
            else
              match builder finalState.arena newLeft newRight with
              | Except.error error => Except.error error
              | Except.ok rebuilt =>
                  Except.ok
                    (psKernelExprV2PortableInstRebuilt
                      finalState source depth replacement rebuilt)
          else
            match builder finalState.arena newLeft newRight with
            | Except.error error => Except.error error
            | Except.ok rebuilt =>
                Except.ok
                  (psKernelExprV2PortableInstRebuilt
                    finalState source depth replacement rebuilt)

def psKernelExprV2PortableInstThree
    (recurse :
      PsKernelExprV2PortableInstState -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2PortableInstState × Nat))
    (builder :
      PsKernelExprV2ChunkedArena -> Nat -> Nat -> Nat ->
      Except String (PsKernelExprV2ChunkedArena × Nat))
    (state : PsKernelExprV2PortableInstState)
    (source firstId secondId thirdId depth replacement : Nat) :
    Except String (PsKernelExprV2PortableInstState × Nat) :=
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
                      (psKernelExprV2PortableInstFinish
                        lastState source depth replacement source)
                  else
                    match builder
                        lastState.arena newFirst newSecond newThird with
                    | Except.error error => Except.error error
                    | Except.ok rebuilt =>
                        Except.ok
                          (psKernelExprV2PortableInstRebuilt
                            lastState source depth replacement rebuilt)
                else
                  match builder
                      lastState.arena newFirst newSecond newThird with
                  | Except.error error => Except.error error
                  | Except.ok rebuilt =>
                      Except.ok
                        (psKernelExprV2PortableInstRebuilt
                          lastState source depth replacement rebuilt)
              else
                match builder
                    lastState.arena newFirst newSecond newThird with
                | Except.error error => Except.error error
                | Except.ok rebuilt =>
                    Except.ok
                      (psKernelExprV2PortableInstRebuilt
                        lastState source depth replacement rebuilt)

/- For a hit on BVar(depth), substitute shift(replacement, 0, depth). -/
def psKernelExprV2PortableInstReplace
    (state : PsKernelExprV2PortableInstState)
    (source depth replacement : Nat) :
    Except String (PsKernelExprV2PortableInstState × Nat) :=
  match psKernelExprV2ChunkedFind state.arena replacement with
  | Option.none =>
      Except.error "PSKERNEL_V2_INST_INVALID_REPLACEMENT"
  | Option.some entry =>
      let liftState : PsKernelExprV2PortableLiftState := {
        arena := state.arena
        memo := List.nil
      };
      match
          psKernelExprV2PortableLiftWithFuel
            (Nat.succ entry.depth)
            liftState replacement 0 depth with
      | Except.error error =>
          Except.error error
      | Except.ok lifted =>
          let output : PsKernelExprV2PortableInstState := {
            arena := (Prod.fst lifted).arena
            memo := state.memo
          };
          Except.ok
            (psKernelExprV2PortableInstFinish
              output source depth replacement (Prod.snd lifted))

def psKernelExprV2PortableInstWithFuel
    (fuel : Nat) :
    PsKernelExprV2PortableInstState -> Nat -> Nat -> Nat ->
    Except String (PsKernelExprV2PortableInstState × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsKernelExprV2PortableInstState) =>
        fun (_source : Nat) =>
          fun (_depth : Nat) =>
            fun (_replacement : Nat) =>
              Except.error "PSKERNEL_V2_INST_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PortableInstState -> Nat -> Nat -> Nat ->
          Except String (PsKernelExprV2PortableInstState × Nat) :=
        psKernelExprV2PortableInstWithFuel remaining;
      fun (state : PsKernelExprV2PortableInstState) =>
        fun (source : Nat) =>
          fun (depth : Nat) =>
            fun (replacement : Nat) =>
              match psKernelExprV2ChunkedFind state.arena source with
              | Option.none =>
                  Except.error "PSKERNEL_V2_INST_INVALID_NODE"
              | Option.some entry =>
                  if Nat.ble entry.looseRange depth then
                    Except.ok (Prod.mk state source)
                  else
                    match psKernelExprV2PortableInstMemoFind
                        state.memo source depth replacement with
                    | Option.some result =>
                        Except.ok (Prod.mk state result)
                    | Option.none =>
                        match entry.node with
                        | PsKernelExprV2Node.bvar index =>
                            if Nat.blt index depth then
                              Except.ok
                                (psKernelExprV2PortableInstFinish
                                  state source depth replacement source)
                            else if Nat.beq index depth then
                              psKernelExprV2PortableInstReplace
                                state source depth replacement
                            else
                              match psKernelExprV2ChunkedMkBVar
                                  state.arena (Nat.sub index 1) with
                              | Except.error error => Except.error error
                              | Except.ok rebuilt =>
                                  Except.ok
                                    (psKernelExprV2PortableInstRebuilt
                                      state source depth replacement rebuilt)
                        | PsKernelExprV2Node.app fn arg =>
                            psKernelExprV2PortableInstTwo
                              smaller psKernelExprV2ChunkedMkApp
                              state source fn arg
                              depth depth depth replacement
                        | PsKernelExprV2Node.lam name type body binderInfo =>
                            psKernelExprV2PortableInstTwo
                              smaller
                              (psKernelExprV2PortableLiftMkLam name binderInfo)
                              state source type body
                              depth depth (Nat.succ depth) replacement
                        | PsKernelExprV2Node.forallE name type body binderInfo =>
                            psKernelExprV2PortableInstTwo
                              smaller
                              (psKernelExprV2PortableLiftMkForall name binderInfo)
                              state source type body
                              depth depth (Nat.succ depth) replacement
                        | PsKernelExprV2Node.letE name type value body nondep =>
                            psKernelExprV2PortableInstThree
                              smaller
                              (psKernelExprV2PortableLiftMkLet name nondep)
                              state source type value body depth replacement
                        | PsKernelExprV2Node.mdata tag body =>
                            psKernelExprV2PortableInstOne
                              smaller
                              (psKernelExprV2PortableLiftMkMData tag)
                              state source body depth depth replacement
                        | PsKernelExprV2Node.proj typeName index body =>
                            psKernelExprV2PortableInstOne
                              smaller
                              (psKernelExprV2PortableLiftMkProj typeName index)
                              state source body depth depth replacement
                        | _ =>
                            Except.ok
                              (psKernelExprV2PortableInstFinish
                                state source depth replacement source)

/-
Research-only checked entrypoint. Rechecks every input node, ensures the
replacement is in this exact canonical arena, performs the capture-avoiding
transformation, and rechecks every output node. No trust in arbitrary cached
metadata or exported node IDs.
-/
def psKernelExprV2PortableInstantiate1Checked
    (source : PsKernelExprV2ChunkedArena)
    (root replacement : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2PortableValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2ChunkedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_INST_INVALID_ROOT"
      | Option.some rootEntry =>
          match psKernelExprV2ChunkedFind canonical replacement with
          | Option.none =>
              Except.error "PSKERNEL_V2_INST_INVALID_REPLACEMENT"
          | Option.some _ =>
              let initial : PsKernelExprV2PortableInstState := {
                arena := canonical
                memo := List.nil
              };
              match
                  psKernelExprV2PortableInstWithFuel
                    (Nat.succ rootEntry.depth)
                    initial root 0 replacement with
              | Except.error error =>
                  Except.error error
              | Except.ok finished =>
                  let finishedState := Prod.fst finished;
                  let result := Prod.snd finished;
                  match psKernelExprV2PortableValidate finishedState.arena with
                  | Except.error error => Except.error error
                  | Except.ok validated =>
                      Except.ok (Prod.mk validated result)
