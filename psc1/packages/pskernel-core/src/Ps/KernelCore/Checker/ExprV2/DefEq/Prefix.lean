import Ps.KernelCore.Checker.ExprV2.DefEq.Quick

/- Ordered DefEq prefix, stopping before proposition inference/lazy delta.
An undecided stage carries state internally; unsupported work exposes no state. -/
def psKernelExprV2DefEqReflectionWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match psKernelExprV2PagedRequire state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftEntry =>
      let mayReflect := if leftEntry.hasFVar then context.scalar.eagerReduce else true;
      if mayReflect then
        match psKernelExprV2PagedRequire state.whnf.arena right with
        | Except.error error => Option.some (Except.error error)
        | Except.ok rightEntry =>
            match rightEntry.node with
            | PsKernelExprV2Node.const name levels =>
                match levels with
                | List.cons _ _ => Option.some (Except.ok (Prod.mk state Option.none))
                | List.nil =>
                    if psKernelNameEq name psKernelBoolTrueName then
                      match whnf context state.whnf left with
                      | Option.none => Option.none
                      | Option.some attempted =>
                          match attempted with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok reduced =>
                              let next := psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced);
                              match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok entry =>
                                  match entry.node with
                                  | PsKernelExprV2Node.const reducedName reducedLevels =>
                                      match reducedLevels with
                                      | List.cons _ _ =>
                                          Option.some (Except.ok (Prod.mk next Option.none))
                                      | List.nil =>
                                          if psKernelNameEq reducedName psKernelBoolTrueName then
                                            Option.some (Except.ok (Prod.mk next (Option.some true)))
                                          else Option.some (Except.ok (Prod.mk next Option.none))
                                  | _ => Option.some (Except.ok (Prod.mk next Option.none))
                    else Option.some (Except.ok (Prod.mk state Option.none))
            | _ => Option.some (Except.ok (Prod.mk state Option.none))
      else Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2DefEqCoreQuickContinueWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match coreWhnf context state.whnf left with
  | Option.none => Option.none
  | Option.some leftAttempt =>
      match leftAttempt with
      | Except.error error => Option.some (Except.error error)
      | Except.ok leftReduced =>
          let afterLeft := psKernelExprV2CheckStateWithWhnf state (Prod.fst leftReduced);
          match coreWhnf context afterLeft.whnf right with
          | Option.none => Option.none
          | Option.some rightAttempt =>
              match rightAttempt with
              | Except.error error => Option.some (Except.error error)
              | Except.ok rightReduced =>
                  let afterRight := psKernelExprV2CheckStateWithWhnf afterLeft (Prod.fst rightReduced);
                  match psKernelExprV2DefEqQuickWith defeq context afterRight
                      (Prod.snd leftReduced) (Prod.snd rightReduced) false with
                  | Option.none => Option.none
                  | Option.some quickAttempt =>
                      match quickAttempt with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok quickResult =>
                          match Prod.snd quickResult with
                          | Option.none =>
                              match continuation context (Prod.fst quickResult)
                                  (Prod.snd leftReduced) (Prod.snd rightReduced) with
                              | Option.none => Option.none
                              | Option.some continued =>
                                  match continued with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok result =>
                                      Option.some (psKernelExprV2CheckStateDefEqFinish
                                        (Prod.fst result) left right (Prod.snd result))
                          | Option.some value =>
                              Option.some (psKernelExprV2CheckStateDefEqFinish
                                (Prod.fst quickResult) left right value)

def psKernelExprV2DefEqAfterQuickContinueWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqReflectionWith whnf context state left right with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reflected =>
          match Prod.snd reflected with
          | Option.some value =>
              Option.some (psKernelExprV2CheckStateDefEqFinish
                (Prod.fst reflected) left right value)
          | Option.none =>
              psKernelExprV2DefEqCoreQuickContinueWith continuation defeq coreWhnf
                context (Prod.fst reflected) left right

def psKernelExprV2DefEqPrefixContinueWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqQuickWith defeq context state left right true with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok quickResult =>
          match Prod.snd quickResult with
          | Option.some value =>
              Option.some (psKernelExprV2CheckStateDefEqFinish
                (Prod.fst quickResult) left right value)
          | Option.none =>
              psKernelExprV2DefEqAfterQuickContinueWith continuation defeq whnf coreWhnf
                context (Prod.fst quickResult) left right

/- Compatibility prefix APIs stop at the same original boundary. -/
def psKernelExprV2DefEqNoContinuation
    (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
    (_left _right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  Option.none

def psKernelExprV2DefEqCoreQuickWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqCoreQuickContinueWith psKernelExprV2DefEqNoContinuation
    defeq coreWhnf context state left right

def psKernelExprV2DefEqAfterQuickWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqAfterQuickContinueWith psKernelExprV2DefEqNoContinuation
    defeq whnf coreWhnf context state left right

def psKernelExprV2DefEqPrefixWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqPrefixContinueWith psKernelExprV2DefEqNoContinuation
    defeq whnf coreWhnf context state left right

