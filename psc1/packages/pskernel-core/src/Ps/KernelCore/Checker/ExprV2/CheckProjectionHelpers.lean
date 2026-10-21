import Ps.KernelCore.Checker.ExprV2.CheckApplication

/-
Projection inference uses the original predecessor checking callback and the
fixed top-level WHNF callback. In particular, projection sort expectations
always run WHNF, even when the input is already a Sort. Every type and
intermediate projection remains an ID in the owning canonical arena.
-/
def psKernelExprV2CheckProjectionWhnfWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match whnf context state.whnf root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result =>
          Option.some
            (Except.ok
              (Prod.mk
                (psKernelExprV2CheckStateWithWhnf state (Prod.fst result))
                (Prod.snd result)))

def psKernelExprV2CheckProjectionSortWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelLevel)) :=
  match psKernelExprV2CheckProjectionWhnfWith whnf context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result =>
          let next := Prod.fst result;
          match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd result) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok entry =>
              match entry.node with
              | PsKernelExprV2Node.sort level =>
                  Option.some (Except.ok (Prod.mk next level))
              | _ => Option.some (Except.error "expected sort")

def psKernelExprV2CheckProjectionIsPropWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match check context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result =>
          match psKernelExprV2CheckProjectionSortWith
              whnf context (Prod.fst result) (Prod.snd result) with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok sortResult =>
                  Option.some
                    (Except.ok
                      (Prod.mk (Prod.fst sortResult)
                        (psKernelLevelNormalizesToZero (Prod.snd sortResult))))

def psKernelExprV2CheckProjectionInstantiate
    (state : PsKernelExprV2CheckState) (body value : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons value List.nil))
      state.whnf.arena body 0 with
  | Except.error error => Except.error error
  | Except.ok result =>
      Except.ok
        (Prod.mk
          (psKernelExprV2CheckStateWithArena state (Prod.fst result))
          (Prod.snd result))

def psKernelExprV2CheckProjectionApplyParamsWithFuel
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
          (_state : PsKernelExprV2CheckState) (_args : List Nat)
          (_index _numParams _current : Nat) =>
        Option.some (Except.error "kernel projection parameter budget exhausted")
  | Nat.succ remaining =>
      fun (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (args : List Nat)
          (index numParams current : Nat) =>
        if psKernelNatLt index numParams then
          match psKernelExprV2CheckProjectionWhnfWith whnf context state current with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  let next := Prod.fst reduced;
                  match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok entry =>
                      match entry.node with
                      | PsKernelExprV2Node.forallE _ _ body _ =>
                          match psKernelExprV2TransformNatGet args index with
                          | Option.none =>
                              Option.some
                                (Except.error "invalid projection: missing structure parameter")
                          | Option.some argument =>
                              match psKernelExprV2CheckProjectionInstantiate next body argument with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok instantiated =>
                                  let recur := psKernelExprV2CheckProjectionApplyParamsWithFuel remaining;
                                  recur whnf context (Prod.fst instantiated) args
                                    (Nat.succ index) numParams (Prod.snd instantiated)
                      | _ =>
                          Option.some
                            (Except.error "invalid projection: constructor parameter is not a forall")
        else Option.some (Except.ok (Prod.mk state current))

def psKernelExprV2CheckProjectionInstantiateField
    (state : PsKernelExprV2CheckState) (inductName : PsKernelName)
    (structValue index body : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2PagedMkProj state.whnf.arena inductName index structValue with
  | Except.error error => Except.error error
  | Except.ok projected =>
      psKernelExprV2CheckProjectionInstantiate
        (psKernelExprV2CheckStateWithArena state (Prod.fst projected))
        body (Prod.snd projected)

def psKernelExprV2CheckProjectionSkipFieldsWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    PsKernelName -> Nat -> Bool -> Nat -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
          (_whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_inductName : PsKernelName)
          (_structValue : Nat) (_propType : Bool)
          (_targetIndex _index _current : Nat) =>
        Option.some (Except.error "kernel projection field budget exhausted")
  | Nat.succ remaining =>
      fun (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
          (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (inductName : PsKernelName)
          (structValue : Nat) (propType : Bool)
          (targetIndex index current : Nat) =>
        let continueWith :
            PsKernelExprV2CheckState -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
          fun (nextState : PsKernelExprV2CheckState) (nextType : Nat) =>
            let recur := psKernelExprV2CheckProjectionSkipFieldsWithFuel remaining;
            recur check whnf context nextState inductName structValue propType
              targetIndex (Nat.succ index) nextType;
        if psKernelNatLt index targetIndex then
          match psKernelExprV2CheckProjectionWhnfWith whnf context state current with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  let next := Prod.fst reduced;
                  match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok entry =>
                      match entry.node with
                      | PsKernelExprV2Node.forallE _ domain body _ =>
                          match psKernelExprV2PagedRequire next.whnf.arena body with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok bodyEntry =>
                              if Nat.beq bodyEntry.looseRange 0 then continueWith next body
                              else
                                let instantiateAndContinue :
                                    PsKernelExprV2CheckState ->
                                    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
                                  fun (fieldState : PsKernelExprV2CheckState) =>
                                    match psKernelExprV2CheckProjectionInstantiateField
                                        fieldState inductName structValue index body with
                                    | Except.error error => Option.some (Except.error error)
                                    | Except.ok instantiated =>
                                        continueWith (Prod.fst instantiated) (Prod.snd instantiated);
                                if propType then
                                  match psKernelExprV2CheckProjectionIsPropWith
                                      check whnf context next domain with
                                  | Option.none => Option.none
                                  | Option.some attemptedProp =>
                                      match attemptedProp with
                                      | Except.error error => Option.some (Except.error error)
                                      | Except.ok propResult =>
                                          if Prod.snd propResult then
                                            instantiateAndContinue (Prod.fst propResult)
                                          else
                                            Option.some
                                              (Except.error
                                                "invalid projection: proof structure depends on data field")
                                else instantiateAndContinue next
                      | _ => Option.some (Except.error "invalid projection index")
        else Option.some (Except.ok (Prod.mk state current))
