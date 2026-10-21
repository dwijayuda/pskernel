import Ps.KernelCore.Checker.ExprV2.Knot

/-
Historical WHNF-state entry points. The recursive algorithm lives only in
WhnfOwned and the full checker-state callback knot. These wrappers preserve
the original signatures, staged fuel ABI, cheapRec=false selection and
caller-supplied public/recursor callbacks.

Initialization and lowering occur only at these standalone WhnfState
boundaries. Production checker callbacks use CheckState directly; an old
callback is lifted against its actual input state.
-/

def psKernelExprV2WhnfCoreFinishMode
    (cheapProj : Bool) (state : PsKernelExprV2WhnfState)
    (source result : Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  if cheapProj then Except.ok (Prod.mk state result)
  else psKernelExprV2WhnfCoreFinish state source result

def psKernelExprV2WhnfFinishAttempt
    (source : Nat) (cheapProj : Bool)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some
            (psKernelExprV2WhnfCoreFinishMode cheapProj
              (Prod.fst reduced) source (Prod.snd reduced))

def psKernelExprV2TryWhnfProjectionWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (typeName : PsKernelName) (index structValue : Nat)
    (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2TryWhnfProjectionOwnedWith
      (psKernelExprV2LiftScalarWhnf recurse)
      (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state)
      root typeName index structValue cheapProj)

def psKernelExprV2TryWhnfAppWithReducer
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2TryWhnfAppOwnedWithReducer
      (psKernelExprV2LiftScalarWhnf recurse)
      (psKernelExprV2LiftScalarRecursor reduceRecursor)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) root false cheapProj)

def psKernelExprV2TryWhnfCompositeWithReducer
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2TryWhnfCompositeOwnedWithReducer
      (psKernelExprV2LiftScalarWhnf recurse)
      (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2LiftScalarRecursor reduceRecursor)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) root entry false cheapProj)

def psKernelExprV2TryWhnfCoreModeWithReducerFuel
    (fuel : Nat) :
    Bool -> (PsKernelName -> Option Nat) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat)))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_cheapProj : Bool) (_localValue : PsKernelName -> Option Nat)
          (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (cheapProj : Bool) (localValue : PsKernelName -> Option Nat)
          (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2LowerWhnfAttempt
          (psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel fuel
            false cheapProj (psKernelExprV2LiftLocalValue localValue)
            (psKernelExprV2LiftScalarWhnf publicWhnf)
            (psKernelExprV2LiftScalarRecursor reduceRecursor)
            (psKernelExprV2CheckContextEmpty context)
            (psKernelExprV2CheckStateFromWhnf state) root)

def psKernelExprV2WhnfPublicFinishAttempt
    (source : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some
            (psKernelExprV2WhnfPublicFinish
              (Prod.fst reduced) source (Prod.snd reduced))

def psKernelExprV2TryWhnfAfterCoreWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (original core : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2TryWhnfOwnedAfterCoreWith
      (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) original core)

def psKernelExprV2TryWhnfPublicNonterminalWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2TryWhnfPublicOwnedNonterminalWith
      (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2LiftScalarWhnf coreWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) root entry)

def psKernelExprV2TryWhnfStateWithReducerFuel
    (fuel : Nat) :
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat)))) ->
    (PsKernelName -> Option Nat) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (_localValue : PsKernelName -> Option Nat)
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (localValue : PsKernelName -> Option Nat)
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2LowerWhnfAttempt
          (psKernelExprV2TryWhnfOwnedWithReducerFuel fuel
            (psKernelExprV2LiftScalarRecursor reduceRecursor)
            (psKernelExprV2LiftLocalValue localValue)
            (psKernelExprV2CheckContextEmpty context)
            (psKernelExprV2CheckStateFromWhnf state) root)

def psKernelExprV2TryReduceRecursorWithLocalValuesFuel
    (fuel : Nat) :
    (PsKernelName -> Option Nat) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match fuel with
  | Nat.zero =>
      fun (_localValue : PsKernelName -> Option Nat)
          (_context : PsKernelCheckerContext) (_state : PsKernelExprV2WhnfState)
          (_root : Nat) (_cheapProj : Bool) =>
        Option.some (Except.error "kernel recursor budget exhausted")
  | Nat.succ remaining =>
      fun (localValue : PsKernelName -> Option Nat)
          (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
          (root : Nat) (cheapProj : Bool) =>
        psKernelExprV2LowerOptionalWhnfAttempt
          (psKernelExprV2TryReduceRecursorOwnedWithFuel fuel
            psKernelExprV2NoOwnedDefEq (psKernelExprV2LiftLocalValue localValue)
            (psKernelExprV2CheckContextEmpty context)
            (psKernelExprV2CheckStateFromWhnf state) root false cheapProj)

def psKernelExprV2WhnfInertRecursor
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (_cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          if psKernelExprV2WhnfRecursorInert context head.node then
            Option.some (Except.ok (Prod.mk state Option.none))
          else Option.none

def psKernelExprV2TryWhnfAppWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2TryWhnfAppWithReducer recurse psKernelExprV2WhnfInertRecursor
    context state root cheapProj

def psKernelExprV2TryWhnfCompositeWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2TryWhnfCompositeWithReducer recurse publicWhnf psKernelExprV2WhnfInertRecursor
    context state root entry cheapProj

def psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel
    (fuel : Nat) :
    Bool -> (PsKernelName -> Option Nat) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  fun (cheapProj : Bool) (localValue : PsKernelName -> Option Nat)
      (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
        Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
      (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
    let ownedLocalValue := psKernelExprV2LiftLocalValue localValue;
    let reducer :=
      fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
          (nextRoot : Nat) (nextCheapRec nextCheapProj : Bool) =>
        let worker := psKernelExprV2TryReduceRecursorOwnedWithFuel fuel;
        worker psKernelExprV2NoOwnedDefEq ownedLocalValue
          nextContext nextState nextRoot nextCheapRec nextCheapProj;
    psKernelExprV2LowerWhnfAttempt
      (psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel fuel
        false cheapProj ownedLocalValue (psKernelExprV2LiftScalarWhnf publicWhnf)
        reducer (psKernelExprV2CheckContextEmpty context)
        (psKernelExprV2CheckStateFromWhnf state) root)

def psKernelExprV2TryWhnfCoreWithLocalValuesFuel
    (fuel : Nat) :
    (PsKernelName -> Option Nat) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_localValue : PsKernelName -> Option Nat)
          (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
            Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (localValue : PsKernelName -> Option Nat)
          (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
            Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel (Nat.succ remaining)
          false localValue publicWhnf context state root

def psKernelExprV2NoLocalValue
    (_name : PsKernelName) : Option Nat :=
  Option.none

def psKernelExprV2TryWhnfCoreWithPublicFuel
    (fuel : Nat) :
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2TryWhnfCoreWithLocalValuesFuel (Nat.succ remaining)
          psKernelExprV2NoLocalValue publicWhnf context state root

/- Public staged ABI and original entry budget are retained. -/

def psKernelExprV2TryWhnfStateWithLocalValuesFuel
    (fuel : Nat) :
    (PsKernelName -> Option Nat) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  fun (localValue : PsKernelName -> Option Nat)
      (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
    psKernelExprV2LowerWhnfAttempt
      (psKernelExprV2TryWhnfOwnedWithLocalValuesFuel fuel
        psKernelExprV2NoOwnedDefEq (psKernelExprV2LiftLocalValue localValue)
        (psKernelExprV2CheckContextEmpty context)
        (psKernelExprV2CheckStateFromWhnf state) root)

def psKernelExprV2TryWhnfStateWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2TryWhnfStateWithLocalValuesFuel (Nat.succ remaining)
          psKernelExprV2NoLocalValue context state root

def psKernelExprV2TryWhnfCoreStateWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  let publicWhnf :=
    fun (nextContext : PsKernelCheckerContext)
        (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
      let worker := psKernelExprV2TryWhnfStateWithFuel fuel;
      worker nextContext nextState nextRoot;
  let core := psKernelExprV2TryWhnfCoreWithPublicFuel fuel;
  core publicWhnf context state root

def psKernelExprV2TryWhnfWithDeclarationsFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match psKernelExprV2TryWhnfStateWithFuel fuel context
      (psKernelExprV2WhnfStateForDeclarations arena declarations) root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let state := Prod.fst reduced;
          Option.some (Except.ok (Prod.mk state.arena (Prod.snd reduced)))

def psKernelExprV2TryWhnfWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  psKernelExprV2TryWhnfWithDeclarationsFuel fuel context arena List.nil root
