import Ps.KernelCore.Checker.ExprV2.CheckApplication

/-
Inference-only application exposes the whole function spine without checking
arguments. Pending arguments are instantiated only when a non-forall type
must be exposed, and once at the end. The loop retains the original
1 + argument-count budget and the original fixed WHNF callback.
The caller publishes the result in the separate inference-only cache.
-/
def psKernelExprV2InferArgsTake
    (count : Nat) (values : List Nat) : List Nat :=
  match count with
  | Nat.zero => List.nil
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons first rest =>
          List.cons first (psKernelExprV2InferArgsTake remaining rest)

def psKernelExprV2InferArgsDrop
    (count : Nat) (values : List Nat) : List Nat :=
  match count with
  | Nat.zero => values
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons _ rest => psKernelExprV2InferArgsDrop remaining rest

def psKernelExprV2InferInstantiateRev
    (state : PsKernelExprV2CheckState) (root : Nat) (values : List Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0
        (psKernelExprV2TransformNatReverse values List.nil))
      state.whnf.arena root 0 with
  | Except.error error => Except.error error
  | Except.ok built =>
      Except.ok
        (Prod.mk (psKernelExprV2CheckStateWithArena state (Prod.fst built))
          (Prod.snd built))

def psKernelExprV2InferAppOnlyLoopOwnedWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    List Nat -> Nat -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState)
          (_args : List Nat) (_index _instantiated _current : Nat) =>
        Option.some (Except.error "kernel inference budget exhausted")
  | Nat.succ remaining =>
      fun (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState)
          (args : List Nat) (index instantiated current : Nat) =>
        let smaller :=
          fun (nextState : PsKernelExprV2CheckState)
              (nextIndex nextInstantiated nextCurrent : Nat) =>
            let recur := psKernelExprV2InferAppOnlyLoopOwnedWithFuel remaining;
            recur whnf context nextState args
              nextIndex nextInstantiated nextCurrent;
        let argCount := psKernelExprV2TransformNatLength args;
        if psKernelNatLt index argCount then
          match psKernelExprV2PagedRequire state.whnf.arena current with
          | Except.error error => Option.some (Except.error error)
          | Except.ok entry =>
              match entry.node with
              | PsKernelExprV2Node.forallE _ _ body _ =>
                  smaller state (Nat.succ index) instantiated body
              | _ =>
                  let pending :=
                    psKernelExprV2InferArgsTake (Nat.sub index instantiated)
                      (psKernelExprV2InferArgsDrop instantiated args);
                  match psKernelExprV2InferInstantiateRev state current pending with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok exposed =>
                      match psKernelExprV2CheckEnsureForallOwnedWith
                          whnf context (Prod.fst exposed) (Prod.snd exposed) with
                      | Option.none => Option.none
                      | Option.some attempted =>
                          match attempted with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok forallResult =>
                              let view := Prod.snd forallResult;
                              smaller (Prod.fst forallResult)
                                (Nat.succ index) index view.body
        else
          Option.some
            (psKernelExprV2InferInstantiateRev state current
              (psKernelExprV2InferArgsDrop instantiated args))

def psKernelExprV2InferApplicationOwnedWith
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match inferType context state (Prod.fst spine) with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok inferred =>
              let args := Prod.snd spine;
              psKernelExprV2InferAppOnlyLoopOwnedWithFuel
                (Nat.succ (psKernelExprV2TransformNatLength args))
                whnf context (Prod.fst inferred) args 0 0 (Prod.snd inferred)

/- The original callback ABI is retained by lifting the supplied WHNF callback
   against the complete state already owned by this helper. -/

def psKernelExprV2InferAppOnlyLoopWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    List Nat -> Nat -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState)
          (_args : List Nat) (_index _instantiated _current : Nat) =>
        Option.some (Except.error "kernel inference budget exhausted")
  | Nat.succ remaining =>
      fun (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState)
          (args : List Nat) (index instantiated current : Nat) =>
        psKernelExprV2InferAppOnlyLoopOwnedWithFuel (Nat.succ remaining)
          (psKernelExprV2LiftCheckWhnf whnf) context state args index instantiated current

def psKernelExprV2InferApplicationWith
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2InferApplicationOwnedWith
    inferType (psKernelExprV2LiftCheckWhnf whnf) context state root
