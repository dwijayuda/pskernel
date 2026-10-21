import Ps.KernelCore.Checker.ExprV2.CheckCore
import Ps.KernelCore.Checker.ExprV2.DefEq

/- Public and admission WHNF share the full checking owner. The DefEq callback
   keeps the caller's fixed fuel, matching the V1 SessionWhnf callback knot. -/
def psKernelExprV2TryWhnfStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let defeq :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (left right : Nat) =>
      let worker := psKernelExprV2TryDefEqStateWithFuel fuel;
      worker nextContext nextState left right;
  psKernelExprV2CheckWhnfOwnedWithFuel fuel defeq context state root


def psKernelExprV2TryInferenceStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) (inferOnly : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let defeq :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (left right : Nat) =>
      let worker := psKernelExprV2TryDefEqStateWithFuel fuel;
      worker nextContext nextState left right;
  let whnf :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2CheckWhnfOwnedWithFuel fuel defeq nextContext nextState nextRoot;
  psKernelExprV2TryInferCoreOwnedWithFuel fuel whnf defeq context state root inferOnly

def psKernelExprV2TryCheckStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2TryInferenceStateWithFuel fuel context state root false

def psKernelExprV2TryInferStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2TryInferenceStateWithFuel fuel context state root true

def psKernelExprV2TryCheckWithDeclarationsFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match context.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      let initial :=
        psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
          (psKernelExprV2WhnfStateForDeclarations arena declarations);
      match psKernelExprV2TryCheckStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty context) initial root with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checked =>
              let state := Prod.fst checked;
              Option.some (Except.ok (Prod.mk state.whnf.arena (Prod.snd checked)))

def psKernelExprV2TryCheckWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  psKernelExprV2TryCheckWithDeclarationsFuel fuel context arena List.nil root

/- Internal canonical-arena boundary for a fresh standalone WHNF operation.
   Unlike the old WhnfState compatibility ABI, the real owner supplies DefEq
   to recursor callbacks. No cache is imported from an earlier public check. -/
def psKernelExprV2TryWhnfOwnedWithDeclarationsFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match context.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      let initial :=
        psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
          (psKernelExprV2WhnfStateForDeclarations arena declarations);
      match psKernelExprV2TryWhnfStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty context) initial root with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok reduced =>
              let state := Prod.fst reduced;
              Option.some (Except.ok (Prod.mk state.whnf.arena (Prod.snd reduced)))
