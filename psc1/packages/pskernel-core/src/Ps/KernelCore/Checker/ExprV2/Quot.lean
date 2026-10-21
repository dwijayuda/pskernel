import Ps.KernelCore.Checker.ExprV2.CheckCallbacks
import Ps.KernelCore.Checker.ExprV2.Projection

/-
Quot reduction over one owning canonical arena. The environment's quotient
flag comes from validated Eq/Quot admission; constructor names are not a
replacement for that admission. This helper receives the fixed callback from
the recursor-budget owner. It does not choose or reset checker fuel.

All arguments and rebuilt applications remain DAG IDs. Only the major premise
is normalized, and its state is preserved even when no reduction applies.
Quot.mk must have exactly three arguments. Arguments following the major
premise are reapplied in order. An outer none propagates unsupported work;
an inner none means that this supported hook did not reduce.
-/

def psKernelExprV2QuotDrop
    (count : Nat) (values : List Nat) : List Nat :=
  match count with
  | Nat.zero => values
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons _ rest => psKernelExprV2QuotDrop remaining rest

def psKernelExprV2TryReduceQuotMajorOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (args : List Nat) (majorPosition : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  if Nat.ble (psKernelExprV2TransformNatLength args) majorPosition then
    Option.some (Except.ok (Prod.mk state Option.none))
  else
    match psKernelExprV2TransformNatGet args majorPosition with
    | Option.none => Option.some (Except.ok (Prod.mk state Option.none))
    | Option.some major =>
        match publicWhnf context state major with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok reduced =>
                let next := Prod.fst reduced;
                match psKernelExprV2TransformAppSpineOnCanonical
                    next.whnf.arena (Prod.snd reduced) with
                | Except.error error => Option.some (Except.error error)
                | Except.ok spine =>
                    match psKernelExprV2PagedRequire next.whnf.arena (Prod.fst spine) with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok head =>
                        match head.node with
                        | PsKernelExprV2Node.const name _ =>
                            if psKernelNameEq name psKernelQuotMkName then
                              if Nat.beq (psKernelExprV2TransformNatLength (Prod.snd spine)) 3 then
                                match psKernelExprV2TransformNatGet (Prod.snd spine) 2 with
                                | Option.none => Option.some (Except.ok (Prod.mk next Option.none))
                                | Option.some representative =>
                                    match psKernelExprV2TransformNatGet args 3 with
                                    | Option.none => Option.some (Except.ok (Prod.mk next Option.none))
                                    | Option.some fnValue =>
                                        match psKernelExprV2PagedMkApp
                                            next.whnf.arena fnValue representative with
                                        | Except.error error => Option.some (Except.error error)
                                        | Except.ok applied =>
                                            let trailing := psKernelExprV2QuotDrop
                                              (Nat.succ majorPosition) args;
                                            match psKernelExprV2TransformApplyArgsOnCanonical
                                                trailing (Prod.fst applied) (Prod.snd applied) with
                                            | Except.error error => Option.some (Except.error error)
                                            | Except.ok result =>
                                                Option.some (Except.ok (Prod.mk
                                                  (psKernelExprV2CheckStateWithArena next
                                                    (Prod.fst result))
                                                  (Option.some (Prod.snd result))))
                              else Option.some (Except.ok (Prod.mk next Option.none))
                            else Option.some (Except.ok (Prod.mk next Option.none))
                        | _ => Option.some (Except.ok (Prod.mk next Option.none))

def psKernelExprV2TryReduceQuotOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  if context.scalar.environment.quotInitialized then
    match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena root with
    | Except.error error => Option.some (Except.error error)
    | Except.ok spine =>
        match psKernelExprV2PagedRequire state.whnf.arena (Prod.fst spine) with
        | Except.error error => Option.some (Except.error error)
        | Except.ok head =>
            match head.node with
            | PsKernelExprV2Node.const name _ =>
                if psKernelNameEq name psKernelQuotLiftName then
                  psKernelExprV2TryReduceQuotMajorOwnedWith publicWhnf context state (Prod.snd spine) 5
                else if psKernelNameEq name psKernelQuotIndName then
                  psKernelExprV2TryReduceQuotMajorOwnedWith publicWhnf context state (Prod.snd spine) 4
                else Option.some (Except.ok (Prod.mk state Option.none))
            | _ => Option.some (Except.ok (Prod.mk state Option.none))
  else Option.some (Except.ok (Prod.mk state Option.none))

/- This is the remaining ordinary-inductive decision after the Quot hook.
   Active ordinary recursors still request fallback until their own DAG rule
   bodies and inference callbacks are available. A quotInfo is not a recInfo. -/
def psKernelExprV2InductiveRecursorInert
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena)
    (root : Nat) : Except String Bool :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name _ =>
              match psKernelEnvironmentFind context.environment name with
              | Option.none => Except.ok true
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.recInfo _ => Except.ok false
                  | _ => Except.ok true
          | _ => Except.ok true

/- Original public helpers retain their WHNF-only callback signatures. -/

def psKernelExprV2TryReduceQuotMajorWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (args : List Nat) (majorPosition : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  psKernelExprV2LowerOptionalWhnfAttempt
    (psKernelExprV2TryReduceQuotMajorOwnedWith (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) args majorPosition)

def psKernelExprV2TryReduceQuotWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  psKernelExprV2LowerOptionalWhnfAttempt
    (psKernelExprV2TryReduceQuotOwnedWith (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) root)
