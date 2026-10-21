import Ps.KernelCore.Checker.ExprV2.RecursorMajor

/-
K-major conversion over the current canonical DAG and complete checking owner.

The caller obtains the major family from this recursor's checked, privately
owned type before entering this helper. The sequence follows
Lean 4.35.0 src/kernel/inductive.h::to_cnstr_when_K at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc and the existing bounded V1 operation:
infer major, public WHNF of its type, family/index guards, constructor candidate,
infer candidate, then DefEq. All callbacks retain the caller's fixed budget.

Only validated entry metadata is used for the expression-metavariable guard;
universe metavariables do not trigger that guard. No callback is skipped by a
cached judgment here. Every callback's entire state is retained, including a
false DefEq result. An unsupported callback remains an unsupported operation.
-/

def psKernelExprV2RecursorKIndicesHaveMVar
    (arena : PsKernelExprV2PagedArena) (indices : List Nat) :
    Except String Bool :=
  match indices with
  | List.nil => Except.ok false
  | List.cons first rest =>
      match psKernelExprV2PagedRequire arena first with
      | Except.error error => Except.error error
      | Except.ok entry =>
          if entry.hasExprMVar then Except.ok true
          else psKernelExprV2RecursorKIndicesHaveMVar arena rest

def psKernelExprV2RecursorKCandidateOwnedWith
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (major appType : Nat) (ctorName : PsKernelName)
    (typeLevels : List PsKernelLevel) (params : List Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2PagedMkConst state.whnf.arena ctorName typeLevels with
  | Except.error error => Option.some (Except.error error)
  | Except.ok head =>
      match psKernelExprV2TransformApplyArgsOnCanonical params
          (Prod.fst head) (Prod.snd head) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok candidate =>
          let afterConstruction :=
            psKernelExprV2CheckStateWithArena state (Prod.fst candidate);
          match inferType context afterConstruction (Prod.snd candidate) with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok candidateType =>
                  match defeq context (Prod.fst candidateType)
                      appType (Prod.snd candidateType) with
                  | Option.none => Option.none
                  | Option.some equalAttempt =>
                      match equalAttempt with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok equalResult =>
                          let result :=
                            if Prod.snd equalResult then Prod.snd candidate
                            else major;
                          Option.some (Except.ok (Prod.mk (Prod.fst equalResult) result))

def psKernelExprV2RecursorKAfterTypeOwnedWith
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (majorInduct : PsKernelName)
    (major appType : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena appType with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.whnf.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const typeInduct typeLevels =>
              if psKernelNameEq typeInduct majorInduct then
                match psKernelExprV2PagedRequire state.whnf.arena appType with
                | Except.error error => Option.some (Except.error error)
                | Except.ok typeEntry =>
                    let indexAttempt : Except String Bool :=
                      if typeEntry.hasExprMVar then
                        psKernelExprV2RecursorKIndicesHaveMVar state.whnf.arena
                          (psKernelExprV2QuotDrop recursor.numParams (Prod.snd spine))
                      else Except.ok false;
                    match indexAttempt with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok hasIndexMVar =>
                        if hasIndexMVar then Option.some (Except.ok (Prod.mk state major))
                        else
                          match psKernelEnvironmentFind context.scalar.environment typeInduct with
                          | Option.none => Option.some (Except.ok (Prod.mk state major))
                          | Option.some info =>
                              match info with
                              | PsKernelConstantInfo.inductInfo inductInfo =>
                                  match inductInfo.ctors with
                                  | List.nil => Option.some (Except.ok (Prod.mk state major))
                                  | List.cons ctorName _ =>
                                      let params := psKernelExprV2RecursorTake
                                        recursor.numParams (Prod.snd spine);
                                      if Nat.beq (psKernelExprV2TransformNatLength params)
                                          recursor.numParams then
                                        psKernelExprV2RecursorKCandidateOwnedWith
                                          inferType defeq context state major appType ctorName
                                          typeLevels params
                                      else Option.some (Except.ok (Prod.mk state major))
                              | _ => Option.some (Except.ok (Prod.mk state major))
              else Option.some (Except.ok (Prod.mk state major))
          | _ => Option.some (Except.ok (Prod.mk state major))

def psKernelExprV2RecursorKForFamilyOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (majorInduct : PsKernelName) (major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match inferType context state major with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok majorType =>
          match publicWhnf context (Prod.fst majorType) (Prod.snd majorType) with
          | Option.none => Option.none
          | Option.some whnfAttempt =>
              match whnfAttempt with
              | Except.error error => Option.some (Except.error error)
              | Except.ok appType =>
                  psKernelExprV2RecursorKAfterTypeOwnedWith inferType defeq context
                    (Prod.fst appType) recursor majorInduct major (Prod.snd appType)

/- Resolve the family from the same checked, private recursor owner before any
   semantic callback. Missing ownership is not evidence of a stuck major. -/
def psKernelExprV2RecursorKOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2RecursorMajorInduct state recursor with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok found =>
          match found with
          | Option.none => Option.some (Except.ok (Prod.mk state major))
          | Option.some family =>
              psKernelExprV2RecursorKForFamilyOwnedWith
                publicWhnf inferType defeq context state recursor family major
