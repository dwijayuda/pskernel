import Ps.KernelCore.Checker.ExprV2.CheckState

/- The proof-irrelevance continuation follows the original checker order.
Inference uses its own cache; this helper cannot publish checked judgments.
The caller owns entry guards and publishes only its original successful pair.
The caller supplies the non-proposition continuation with the complete state. -/
def psKernelExprV2DefEqIsPropWith
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match inferType context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok inferred =>
          let afterInfer := Prod.fst inferred;
          match whnf context afterInfer.whnf (Prod.snd inferred) with
          | Option.none => Option.none
          | Option.some attemptedWhnf =>
              match attemptedWhnf with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  let next := psKernelExprV2CheckStateWithWhnf afterInfer (Prod.fst reduced);
                  match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok entry =>
                      match entry.node with
                      | PsKernelExprV2Node.sort level =>
                          Option.some
                            (Except.ok (Prod.mk next (psKernelLevelNormalizesToZero level)))
                      | _ => Option.some (Except.error "expected sort")

def psKernelExprV2DefEqProofIrrelevanceContinueWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match inferType context state left with
  | Option.none => Option.none
  | Option.some leftAttempt =>
      match leftAttempt with
      | Except.error error => Option.some (Except.error error)
      | Except.ok leftType =>
          match psKernelExprV2DefEqIsPropWith inferType whnf
              context (Prod.fst leftType) (Prod.snd leftType) with
          | Option.none => Option.none
          | Option.some propAttempt =>
              match propAttempt with
              | Except.error error => Option.some (Except.error error)
              | Except.ok isProp =>
                  if Prod.snd isProp then
                    match inferType context (Prod.fst isProp) right with
                    | Option.none => Option.none
                    | Option.some rightAttempt =>
                        match rightAttempt with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok rightType =>
                            defeq context (Prod.fst rightType)
                              (Prod.snd leftType) (Prod.snd rightType)
                  else continuation context (Prod.fst isProp) left right

/- Preserve the standalone proof stage's existing unsupported boundary. -/
def psKernelExprV2DefEqProofIrrelevanceWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  let unsupported :
      PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
    fun (_context : PsKernelExprV2CheckContext)
        (_state : PsKernelExprV2CheckState) (_left _right : Nat) => Option.none;
  psKernelExprV2DefEqProofIrrelevanceContinueWith unsupported defeq inferType whnf
    context state left right
