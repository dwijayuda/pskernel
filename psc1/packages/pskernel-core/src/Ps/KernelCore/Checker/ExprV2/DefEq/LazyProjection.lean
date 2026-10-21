import Ps.KernelCore.Checker.ExprV2.DefEq.DeltaStep
import Ps.KernelCore.Checker.ExprV2.CheckWhnf

/- Matching projections use their own expanded-node-count budget. Their
DefEq callback stays fixed at the owning predecessor, while the lazy loop
decreases only its own fuel. This loop deliberately calls one delta step;
it does not run the eager Nat/predecessor stage of general lazy reduction. -/
def psKernelExprV2DefEqLazyProjFinishWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) (typeName : PsKernelName) (index : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2ReduceProjOnCanonical
      context.scalar state.whnf.arena typeName index left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftField =>
      match psKernelExprV2ReduceProjOnCanonical
          context.scalar state.whnf.arena typeName index right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightField =>
          match leftField with
          | Option.none => defeq context state left right
          | Option.some leftValue =>
              match rightField with
              | Option.none => defeq context state left right
              | Option.some rightValue => defeq context state leftValue rightValue

def psKernelExprV2DefEqLazyProjReductionWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    Nat -> Nat -> PsKernelName -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero =>
      fun (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
          (_left _right : Nat) (_typeName : PsKernelName) (_index : Nat) =>
        Option.some (Except.error "kernel lazy-projection budget exhausted")
  | Nat.succ remaining =>
      fun (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
          (left right : Nat) (typeName : PsKernelName) (index : Nat) =>
        match psKernelExprV2DefEqLazyStepWith defeq coreWhnf context state left right with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok stepped =>
                match Prod.snd stepped with
                | PsKernelExprV2DeltaStepResult.continue nextLeft nextRight =>
                    let recur := psKernelExprV2DefEqLazyProjReductionWithFuel remaining;
                    recur defeq coreWhnf context (Prod.fst stepped)
                      nextLeft nextRight typeName index
                | PsKernelExprV2DeltaStepResult.equal =>
                    Option.some (Except.ok (Prod.mk (Prod.fst stepped) true))
                | PsKernelExprV2DeltaStepResult.unknown nextLeft nextRight =>
                    psKernelExprV2DefEqLazyProjFinishWith defeq context (Prod.fst stepped)
                      nextLeft nextRight typeName index
                | PsKernelExprV2DeltaStepResult.different nextLeft nextRight =>
                    psKernelExprV2DefEqLazyProjFinishWith defeq context (Prod.fst stepped)
                      nextLeft nextRight typeName index

def psKernelExprV2DefEqMatchingProjectionWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) (typeName : PsKernelName) (index : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match psKernelExprV2TransformCountOnCanonical state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftCount =>
      match psKernelExprV2TransformCountOnCanonical state.whnf.arena right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightCount =>
          let budget := Nat.succ (Nat.add leftCount rightCount);
          let coreWhnf :
              PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
                Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
            fun (nextContext : PsKernelExprV2CheckContext)
                (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) (cheapProj : Bool) =>
              psKernelExprV2CheckWhnfCoreWithFuel budget
                nextContext nextState nextRoot cheapProj;
          match psKernelExprV2DefEqLazyProjReductionWithFuel budget defeq coreWhnf
              context state left right typeName index with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok compared =>
                  let decision : Option Bool :=
                    if Prod.snd compared then Option.some true else Option.none;
                  Option.some (Except.ok (Prod.mk (Prod.fst compared) decision))

def psKernelExprV2DefEqProjectionShortcutWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match psKernelExprV2PagedRequire state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftEntry =>
      match psKernelExprV2PagedRequire state.whnf.arena right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightEntry =>
          match leftEntry.node with
          | PsKernelExprV2Node.const leftName leftLevels =>
              match rightEntry.node with
              | PsKernelExprV2Node.const rightName rightLevels =>
                  let sameConstant : Bool :=
                    if psKernelNameEq leftName rightName then
                      psKernelLevelListsEquivalent leftLevels rightLevels
                    else false;
                  if sameConstant then
                    Option.some (Except.ok (Prod.mk state (Option.some true)))
                  else Option.some (Except.ok (Prod.mk state Option.none))
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | PsKernelExprV2Node.fvar leftName =>
              match rightEntry.node with
              | PsKernelExprV2Node.fvar rightName =>
                  if psKernelNameEq leftName rightName then
                    Option.some (Except.ok (Prod.mk state (Option.some true)))
                  else Option.some (Except.ok (Prod.mk state Option.none))
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | PsKernelExprV2Node.proj leftName leftIndex leftExpr =>
              match rightEntry.node with
              | PsKernelExprV2Node.proj rightName rightIndex rightExpr =>
                  let sameProjection : Bool :=
                    if psKernelNameEq leftName rightName then
                      Nat.beq leftIndex rightIndex
                    else false;
                  if sameProjection then
                    psKernelExprV2DefEqMatchingProjectionWith defeq context state
                      leftExpr rightExpr leftName leftIndex
                  else Option.some (Except.ok (Prod.mk state Option.none))
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | _ => Option.some (Except.ok (Prod.mk state Option.none))
