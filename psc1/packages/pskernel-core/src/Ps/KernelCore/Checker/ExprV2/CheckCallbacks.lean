import Ps.KernelCore.Checker.ExprV2.CheckState

/-
Compatibility adapters between the original WHNF-only callback ABI and the
owning checker's complete state. The primary checker carries CheckState across
every callback; these adapters only wrap an explicitly supplied old callback.

A successful old callback can update only WhnfState, so lifting that callback
preserves all other fields from its actual input state. No lifted callback
creates a fresh checker owner. Initialization and lowering are reserved for
the old standalone WHNF entry points, which expose only WhnfState.
-/

def psKernelExprV2CheckStateFromWhnf
    (state : PsKernelExprV2WhnfState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty state.arena) state

def psKernelExprV2LiftWhnfAttempt
    (state : PsKernelExprV2CheckState)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some (Except.ok (Prod.mk
            (psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced))
            (Prod.snd reduced)))

def psKernelExprV2LiftOptionalWhnfAttempt
    (state : PsKernelExprV2CheckState)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat)))) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match attempt with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some (Except.ok (Prod.mk
            (psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced))
            (Prod.snd reduced)))

def psKernelExprV2LowerWhnfAttempt
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Nat))) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let state := Prod.fst reduced;
          Option.some (Except.ok (Prod.mk state.whnf (Prod.snd reduced)))

def psKernelExprV2LowerOptionalWhnfAttempt
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState (Option Nat)))) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match attempt with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let state := Prod.fst reduced;
          Option.some (Except.ok (Prod.mk state.whnf (Prod.snd reduced)))

def psKernelExprV2LiftCheckWhnf
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2LiftWhnfAttempt state (whnf context state.whnf root)

def psKernelExprV2LiftCheckCoreWhnf
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2LiftWhnfAttempt state (whnf context state.whnf root cheapProj)

def psKernelExprV2LiftScalarWhnf
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2LiftWhnfAttempt state (whnf context.scalar state.whnf root)

/- Old core/reducer entry points select cheapRec=false. Their supplied reducer
   has only the historical cheapProj argument, which this adapter preserves. -/
def psKernelExprV2LiftScalarRecursor
    (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (_cheapRec cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  psKernelExprV2LiftOptionalWhnfAttempt state
    (reduceRecursor context.scalar state.whnf root cheapProj)

def psKernelExprV2LiftLocalValue
    (localValue : PsKernelName -> Option Nat)
    (_context : PsKernelExprV2CheckContext) (name : PsKernelName) : Option Nat :=
  localValue name

def psKernelExprV2NoOwnedDefEq
    (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
    (_left _right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  Option.none
