import Ps.KernelCore.Checker.ExprV2.DefEq.Quick
import Ps.KernelCore.Checker.ExprV2.DefEq.LazyProjection
import Ps.KernelCore.Checker.ExprV2.DefEq.FinalRules
import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
DAG full-shape rules and the residual continuation after ordered lazy delta.
Callbacks keep their owning DefEq predecessor fuel. This stage adds neither a
checker recursion entry nor success-pair publication.

Outer None declines an unsupported descendant. Inner None means that the
original full-shape rule was undecided. In particular a failed application,
binder, or function-eta comparison must not become a final false decision.
Matching projections and final structure/string/unit rules keep their
reference ordering; unsupported descendants still decline the whole attempt.
-/

def psKernelExprV2DefEqFullShapePositive
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Bool))) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok compared =>
          if Prod.snd compared then
            Option.some (Except.ok (Prod.mk (Prod.fst compared) (Option.some true)))
          else Option.some (Except.ok (Prod.mk (Prod.fst compared) Option.none))

/- Full-shape application arguments are compared left to right. This is
 different from the right-to-left lazy-delta argument shortcut. -/
def psKernelExprV2DefEqFullShapeListsWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> List Nat -> List Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero =>
      fun (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
          (_left _right : List Nat) =>
        Option.some (Except.error "kernel defeq argument-list budget exhausted")
  | Nat.succ remaining =>
      fun (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
          (left right : List Nat) =>
        match left with
        | List.nil =>
            match right with
            | List.nil => Option.some (Except.ok (Prod.mk state true))
            | List.cons _ _ => Option.some (Except.ok (Prod.mk state false))
        | List.cons leftFirst leftRest =>
            match right with
            | List.nil => Option.some (Except.ok (Prod.mk state false))
            | List.cons rightFirst rightRest =>
                match defeq context state leftFirst rightFirst with
                | Option.none => Option.none
                | Option.some attempted =>
                    match attempted with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok result =>
                        if Prod.snd result then
                          let smaller := psKernelExprV2DefEqFullShapeListsWithFuel remaining;
                          smaller defeq context (Prod.fst result) leftRest rightRest
                        else Option.some (Except.ok result)

def psKernelExprV2DefEqFullShapeAppWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftSpine =>
      match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightSpine =>
          match defeq context state (Prod.fst leftSpine) (Prod.fst rightSpine) with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok result =>
                  if Prod.snd result then
                    let leftArgs := Prod.snd leftSpine;
                    let rightArgs := Prod.snd rightSpine;
                    let leftLength := psKernelExprV2TransformNatLength leftArgs;
                    let rightLength := psKernelExprV2TransformNatLength rightArgs;
                    if Nat.beq leftLength rightLength then
                      psKernelExprV2DefEqFullShapeListsWithFuel
                        (Nat.succ (Nat.add leftLength rightLength))
                        defeq context (Prod.fst result) leftArgs rightArgs
                    else Option.some (Except.ok (Prod.mk (Prod.fst result) false))
                  else Option.some (Except.ok result)

def psKernelExprV2DefEqFullShapeEtaOwnedWith
    (lambdaOnLeft : Bool)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (lambdaValue other : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match inferType context state other with
  | Option.none => Option.none
  | Option.some inferred =>
      match inferred with
      | Except.error error => Option.some (Except.error error)
      | Except.ok typeResult =>
          let afterType := Prod.fst typeResult;
          match whnf context afterType (Prod.snd typeResult) with
          | Option.none => Option.none
          | Option.some reduced =>
              match reduced with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reducedType =>
                  let nextState := Prod.fst reducedType;
                  match psKernelExprV2PagedRequire nextState.whnf.arena (Prod.snd reducedType) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok typeEntry =>
                      match typeEntry.node with
                      | PsKernelExprV2Node.forallE name domain _ binderInfo =>
                          match psKernelExprV2PagedMkBVar nextState.whnf.arena 0 with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok bound =>
                              match psKernelExprV2PagedMkApp (Prod.fst bound) other (Prod.snd bound) with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok body =>
                                  match psKernelExprV2PagedMkLam
                                      (Prod.fst body) name domain (Prod.snd body) binderInfo with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok eta =>
                                      let finalState := psKernelExprV2CheckStateWithArena
                                        nextState (Prod.fst eta);
                                      if lambdaOnLeft then
                                        psKernelExprV2DefEqFullShapePositive
                                          (defeq context finalState lambdaValue (Prod.snd eta))
                                      else
                                        psKernelExprV2DefEqFullShapePositive
                                          (defeq context finalState (Prod.snd eta) lambdaValue)
                      | _ => Option.some (Except.ok (Prod.mk nextState Option.none))

def psKernelExprV2DefEqFullShapeOwnedWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
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
          | PsKernelExprV2Node.lam _ _ _ _ =>
              match rightEntry.node with
              | PsKernelExprV2Node.lam _ _ _ _ =>
                  psKernelExprV2DefEqFullShapePositive
                    (psKernelExprV2DefEqBinderSpine true defeq context state left right)
              | _ =>
                  psKernelExprV2DefEqFullShapeEtaOwnedWith
                    true defeq inferType whnf context state left right
          | _ =>
              match rightEntry.node with
              | PsKernelExprV2Node.lam _ _ _ _ =>
                  psKernelExprV2DefEqFullShapeEtaOwnedWith
                    false defeq inferType whnf context state right left
              | _ =>
                  match leftEntry.node with
                  | PsKernelExprV2Node.sort leftLevel =>
                      match rightEntry.node with
                      | PsKernelExprV2Node.sort rightLevel =>
                          Option.some (Except.ok (Prod.mk state
                            (Option.some (psKernelLevelEquivalent leftLevel rightLevel))))
                      | _ => Option.some (Except.ok (Prod.mk state Option.none))
                  | PsKernelExprV2Node.lit leftLiteral =>
                      match rightEntry.node with
                      | PsKernelExprV2Node.lit rightLiteral =>
                          Option.some (Except.ok (Prod.mk state
                            (Option.some (psKernelLiteralEq leftLiteral rightLiteral))))
                      | _ => Option.some (Except.ok (Prod.mk state Option.none))
                  | PsKernelExprV2Node.app _ _ =>
                      match rightEntry.node with
                      | PsKernelExprV2Node.app _ _ =>
                          psKernelExprV2DefEqFullShapePositive
                            (psKernelExprV2DefEqFullShapeAppWith defeq context state left right)
                      | _ => Option.some (Except.ok (Prod.mk state Option.none))
                  | PsKernelExprV2Node.forallE _ _ _ _ =>
                      match rightEntry.node with
                      | PsKernelExprV2Node.forallE _ _ _ _ =>
                          psKernelExprV2DefEqFullShapePositive
                            (psKernelExprV2DefEqBinderSpine false defeq context state left right)
                      | _ => Option.some (Except.ok (Prod.mk state Option.none))
                  | _ => Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2DefEqResidualAfterFullWhnfOwnedWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right leftFull rightFull : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2PagedEqOnCanonical state.whnf.arena leftFull left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftUnchanged =>
      let afterChanged :
          Bool -> Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
        fun (changed : Bool) =>
          if changed then defeq context state leftFull rightFull
          else
            match psKernelExprV2DefEqFullShapeOwnedWith
                defeq inferType whnf context state leftFull rightFull with
            | Option.none => Option.none
            | Option.some attempted =>
                match attempted with
                | Except.error error => Option.some (Except.error error)
                | Except.ok shaped =>
                    match Prod.snd shaped with
                    | Option.none =>
                        psKernelExprV2DefEqFinalRulesOwnedWith defeq inferType whnf
                          context (Prod.fst shaped) leftFull rightFull
                    | Option.some value =>
                        Option.some (Except.ok (Prod.mk (Prod.fst shaped) value));
      if leftUnchanged then
        match psKernelExprV2PagedEqOnCanonical state.whnf.arena rightFull right with
        | Except.error error => Option.some (Except.error error)
        | Except.ok rightUnchanged =>
            if rightUnchanged then afterChanged false else afterChanged true
      else afterChanged true

def psKernelExprV2DefEqResidualOwnedWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqProjectionShortcutWith defeq context state left right with
  | Option.none => Option.none
  | Option.some shortcut =>
      match shortcut with
      | Except.error error => Option.some (Except.error error)
      | Except.ok projected =>
          match Prod.snd projected with
          | Option.some value => Option.some (Except.ok (Prod.mk (Prod.fst projected) value))
          | Option.none =>
              let afterShortcut := Prod.fst projected;
              match coreWhnf context afterShortcut left false with
              | Option.none => Option.none
              | Option.some leftAttempt =>
                  match leftAttempt with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok leftResult =>
                      match coreWhnf context (Prod.fst leftResult) right false with
                      | Option.none => Option.none
                      | Option.some rightAttempt =>
                          match rightAttempt with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok rightResult =>
                              psKernelExprV2DefEqResidualAfterFullWhnfOwnedWith
                                defeq inferType whnf context
                                (Prod.fst rightResult)
                                left right (Prod.snd leftResult) (Prod.snd rightResult)

/- Original WHNF-only callback signatures remain compatibility wrappers.
   Each callback is lifted against the actual complete state at its call. -/

def psKernelExprV2DefEqFullShapeEtaWith
    (lambdaOnLeft : Bool)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (lambdaValue other : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  psKernelExprV2DefEqFullShapeEtaOwnedWith
    lambdaOnLeft defeq inferType (psKernelExprV2LiftCheckWhnf whnf) context state lambdaValue other

def psKernelExprV2DefEqFullShapeWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  psKernelExprV2DefEqFullShapeOwnedWith
    defeq inferType (psKernelExprV2LiftCheckWhnf whnf) context state left right

def psKernelExprV2DefEqResidualAfterFullWhnfWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right leftFull rightFull : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqResidualAfterFullWhnfOwnedWith
    defeq inferType (psKernelExprV2LiftCheckWhnf whnf) context state left right leftFull rightFull

def psKernelExprV2DefEqResidualWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqResidualOwnedWith
    defeq inferType (psKernelExprV2LiftCheckWhnf whnf) (psKernelExprV2LiftCheckCoreWhnf coreWhnf) context state left right
