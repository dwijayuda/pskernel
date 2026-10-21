import Ps.KernelCore.Checker.ExprV2.DefEq.Args
import Ps.KernelCore.Checker.ExprV2.DefEq.Quick
import Ps.KernelCore.Checker.ExprV2.Delta

/- One ordered lazy-delta step over the owning DAG. Live environment metadata
selects definitions and hints. Bodies are read only through the admitted-ID
index when the selected side is actually unfolded. Missing owning references
decline the whole attempt; they never mean a stuck or unequal expression. -/
structure PsKernelExprV2DeltaDefinitionView where
  name : PsKernelName
  hints : PsKernelReducibilityHints
  levels : List PsKernelLevel
  hasArgs : Bool

inductive PsKernelExprV2DeltaStepResult where
  | equal
  | different (left right : Nat)
  | continue (left right : Nat)
  | unknown (left right : Nat)

def psKernelExprV2DeltaDefinition
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) : Except String (Option PsKernelExprV2DeltaDefinitionView) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.whnf.arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name levels =>
              match psKernelEnvironmentFind context.scalar.environment name with
              | Option.none => Except.ok Option.none
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.defnInfo definition =>
                      if Nat.beq (psKernelNameListLength definition.base.levelParams)
                          (psKernelLevelListLength levels) then
                        let hasArgs :=
                          match Prod.snd spine with
                          | List.nil => false
                          | List.cons _ _ => true;
                        Except.ok (Option.some
                          (PsKernelExprV2DeltaDefinitionView.mk
                            definition.base.name definition.hints levels hasArgs))
                      else Except.ok Option.none
                  | _ => Except.ok Option.none
          | _ => Except.ok Option.none

/- This cache stores unfolding results, separately from core/public WHNF.
Closed-source lookup precedes environment/body access, as in the reference. -/
def psKernelExprV2DefEqUnfold
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match psKernelExprV2PagedRequire state.whnf.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      let cached :=
        if entry.hasFVar then Except.ok Option.none
        else psKernelExprV2WhnfCacheFindIn state.unfold state.whnf.arena root entry.hash;
      match cached with
      | Except.error error => Option.some (Except.error error)
      | Except.ok found =>
          match found with
          | Option.some value => Option.some (Except.ok (Prod.mk state (Option.some value)))
          | Option.none =>
              match psKernelExprV2TryUnfoldDefinition context.scalar state.whnf root with
              | Option.none => Option.none
              | Option.some attempted =>
                  match attempted with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok unfolded =>
                      let next := psKernelExprV2CheckStateWithWhnf state (Prod.fst unfolded);
                      match Prod.snd unfolded with
                      | Option.none => Option.some (Except.ok (Prod.mk next Option.none))
                      | Option.some value =>
                          let published :=
                            if entry.hasFVar then next
                            else psKernelExprV2CheckStateWithUnfold next
                              (List.cons
                                (PsKernelExprV2WhnfCacheEntry.mk root value entry.hash)
                                next.unfold);
                          Option.some (Except.ok (Prod.mk published (Option.some value)))

def psKernelExprV2DefEqDeltaOnceWith
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2DefEqUnfold context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok unfolded =>
          match Prod.snd unfolded with
          | Option.none =>
              Option.some (Except.error "internal lazy-delta request for non-definition")
          | Option.some value =>
              match coreWhnf context (Prod.fst unfolded).whnf value true with
              | Option.none => Option.none
              | Option.some reduced =>
                  match reduced with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok result =>
                      Option.some (Except.ok
                        (Prod.mk
                          (psKernelExprV2CheckStateWithWhnf (Prod.fst unfolded) (Prod.fst result))
                          (Prod.snd result)))

def psKernelExprV2DefEqTryUnfoldProjAppWith
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.whnf.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.proj _ _ _ =>
              match coreWhnf context state.whnf root false with
              | Option.none => Option.none
              | Option.some attempted =>
                  match attempted with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok reduced =>
                      let next := psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced);
                      match psKernelExprV2PagedEqOnCanonical
                          next.whnf.arena (Prod.snd reduced) root with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok unchanged =>
                          let value :=
                            if unchanged then Option.none else Option.some (Prod.snd reduced);
                          Option.some (Except.ok (Prod.mk next value))
          | _ => Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2DefEqFinishLazyStepWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult)) :=
  match psKernelExprV2DefEqQuickWith defeq context state left right false with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok compared =>
          let step :=
            match Prod.snd compared with
            | Option.none => PsKernelExprV2DeltaStepResult.continue left right
            | Option.some value =>
                if value then PsKernelExprV2DeltaStepResult.equal
                else PsKernelExprV2DeltaStepResult.different left right;
          Option.some (Except.ok (Prod.mk (Prod.fst compared) step))

def psKernelExprV2DefEqUnfoldSideWith
    (unfoldLeft : Bool)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult)) :=
  match psKernelExprV2DefEqDeltaOnceWith coreWhnf context state
      (if unfoldLeft then left else right) with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          if unfoldLeft then
            psKernelExprV2DefEqFinishLazyStepWith defeq context
              (Prod.fst reduced) (Prod.snd reduced) right
          else
            psKernelExprV2DefEqFinishLazyStepWith defeq context
              (Prod.fst reduced) left (Prod.snd reduced)

/- A projection-headed peer is tried before the only available definition. -/
def psKernelExprV2DefEqLazyStepOneWith
    (leftHasDefinition : Bool)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult)) :=
  match psKernelExprV2DefEqTryUnfoldProjAppWith coreWhnf context state
      (if leftHasDefinition then right else left) with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok peer =>
          match Prod.snd peer with
          | Option.none =>
              psKernelExprV2DefEqUnfoldSideWith leftHasDefinition defeq coreWhnf
                context (Prod.fst peer) left right
          | Option.some value =>
              if leftHasDefinition then
                psKernelExprV2DefEqFinishLazyStepWith defeq context
                  (Prod.fst peer) left value
              else
                psKernelExprV2DefEqFinishLazyStepWith defeq context
                  (Prod.fst peer) value right

def psKernelExprV2DefEqFailureInsert
    (state : PsKernelExprV2CheckState) (left right : Nat) :
    Except String PsKernelExprV2CheckState :=
  match psKernelExprV2PagedRequire state.whnf.arena left with
  | Except.error error => Except.error error
  | Except.ok leftEntry =>
      match psKernelExprV2PagedRequire state.whnf.arena right with
      | Except.error error => Except.error error
      | Except.ok rightEntry =>
          if leftEntry.hasFVar then Except.ok state
          else if rightEntry.hasFVar then Except.ok state
          else
            let hash := Nat.mod (Nat.add leftEntry.hash rightEntry.hash) psKernelCacheHashModulus;
            match psKernelExprV2DefEqPairFindIn state.failure state.whnf.arena left right hash with
            | Except.error error => Except.error error
            | Except.ok present =>
                if present then Except.ok state
                else Except.ok (psKernelExprV2CheckStateWithFailure state
                  (List.cons (PsKernelExprV2DefEqPair.mk left right hash) state.failure))

def psKernelExprV2DefEqUnfoldBothWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult)) :=
  match psKernelExprV2DefEqDeltaOnceWith coreWhnf context state left with
  | Option.none => Option.none
  | Option.some attemptedLeft =>
      match attemptedLeft with
      | Except.error error => Option.some (Except.error error)
      | Except.ok leftResult =>
          match psKernelExprV2DefEqDeltaOnceWith coreWhnf context (Prod.fst leftResult) right with
          | Option.none => Option.none
          | Option.some attemptedRight =>
              match attemptedRight with
              | Except.error error => Option.some (Except.error error)
              | Except.ok rightResult =>
                  psKernelExprV2DefEqFinishLazyStepWith defeq context
                    (Prod.fst rightResult) (Prod.snd leftResult) (Prod.snd rightResult)

def psKernelExprV2DefEqSameDefinitionShortcut
    (left right : PsKernelExprV2DeltaDefinitionView) : Bool :=
  if left.hasArgs then
    if right.hasArgs then
      if psKernelNameEq left.name right.name then
        if psKernelReducibilityHintsIsRegular left.hints then
          psKernelLevelListsEquivalent left.levels right.levels
        else false
      else false
    else false
  else false

def psKernelExprV2DefEqLazyStepBothWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) (leftDef rightDef : PsKernelExprV2DeltaDefinitionView) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult)) :=
  if psKernelReducibilityHintsLt leftDef.hints rightDef.hints then
    psKernelExprV2DefEqUnfoldSideWith true defeq coreWhnf context state left right
  else if psKernelReducibilityHintsLt rightDef.hints leftDef.hints then
    psKernelExprV2DefEqUnfoldSideWith false defeq coreWhnf context state left right
  else
    let sameShortcut := psKernelExprV2DefEqSameDefinitionShortcut leftDef rightDef;
    let argsResult :=
      if sameShortcut then
        match psKernelExprV2DefEqPairContains state.whnf.arena state.failure left right with
        | Except.error error => Option.some (Except.error error)
        | Except.ok failed =>
            if failed then Option.some (Except.ok (Prod.mk state false))
            else psKernelExprV2DefEqArgs defeq context state left right
      else Option.some (Except.ok (Prod.mk state false));
    match argsResult with
    | Option.none => Option.none
    | Option.some attemptedArgs =>
        match attemptedArgs with
        | Except.error error => Option.some (Except.error error)
        | Except.ok compared =>
            if if sameShortcut then Prod.snd compared else false then
              Option.some (Except.ok (Prod.mk (Prod.fst compared) PsKernelExprV2DeltaStepResult.equal))
            else
              let afterFailure :=
                if sameShortcut then
                  psKernelExprV2DefEqFailureInsert (Prod.fst compared) left right
                else Except.ok (Prod.fst compared);
              match afterFailure with
              | Except.error error => Option.some (Except.error error)
              | Except.ok next =>
                  psKernelExprV2DefEqUnfoldBothWith defeq coreWhnf context next left right

def psKernelExprV2DefEqLazyStepWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult)) :=
  match psKernelExprV2DeltaDefinition context state left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftDefinition =>
      match psKernelExprV2DeltaDefinition context state right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightDefinition =>
          match leftDefinition with
          | Option.none =>
              match rightDefinition with
              | Option.none =>
                  Option.some (Except.ok
                    (Prod.mk state (PsKernelExprV2DeltaStepResult.unknown left right)))
              | Option.some _ =>
                  psKernelExprV2DefEqLazyStepOneWith false defeq coreWhnf context state left right
          | Option.some leftDef =>
              match rightDefinition with
              | Option.none =>
                  psKernelExprV2DefEqLazyStepOneWith true defeq coreWhnf context state left right
              | Option.some rightDef =>
                  psKernelExprV2DefEqLazyStepBothWith defeq coreWhnf context state left right
                    leftDef rightDef
