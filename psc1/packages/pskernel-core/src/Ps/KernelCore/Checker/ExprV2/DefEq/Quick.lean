import Ps.KernelCore.Checker.DefEq.Quick
import Ps.KernelCore.Checker.ExprV2.DefEq.BinderSpines

/- Quick consumes no additional recursive entry. Outer None declines an
unsupported descendant; inner None is the original stage's undecided result. -/
def psKernelExprV2DefEqFinishAttempt
    (left right : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Bool))) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok compared =>
          Option.some (psKernelExprV2CheckStateDefEqFinish
            (Prod.fst compared) left right (Prod.snd compared))

def psKernelExprV2DefEqQuickLift
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Bool))) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok compared =>
          Option.some (Except.ok
            (Prod.mk (Prod.fst compared) (Option.some (Prod.snd compared))))

def psKernelExprV2DefEqQuickShapesWith
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
          | PsKernelExprV2Node.lam _ _ _ _ =>
              match rightEntry.node with
              | PsKernelExprV2Node.lam _ _ _ _ =>
                  psKernelExprV2DefEqQuickLift
                    (psKernelExprV2DefEqBinderSpine true defeq context state left right)
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | PsKernelExprV2Node.forallE _ _ _ _ =>
              match rightEntry.node with
              | PsKernelExprV2Node.forallE _ _ _ _ =>
                  psKernelExprV2DefEqQuickLift
                    (psKernelExprV2DefEqBinderSpine false defeq context state left right)
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
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
          | PsKernelExprV2Node.mdata _ leftBody =>
              match rightEntry.node with
              | PsKernelExprV2Node.mdata _ rightBody =>
                  psKernelExprV2DefEqQuickLift (defeq context state leftBody rightBody)
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | _ => Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2DefEqQuickAfterSyntaxWith
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
          let eligible := if leftEntry.hasFVar then false else if rightEntry.hasFVar then false else true;
          if eligible then
            match psKernelExprV2DefEqPairContains
                state.whnf.arena state.success left right with
            | Except.error error => Option.some (Except.error error)
            | Except.ok cached =>
                if cached then Option.some (Except.ok (Prod.mk state (Option.some true)))
                else psKernelExprV2DefEqQuickShapesWith defeq context state left right
          else psKernelExprV2DefEqQuickShapesWith defeq context state left right

def psKernelExprV2DefEqQuickWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) (entryChecked : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))) :=
  if entryChecked then
    psKernelExprV2DefEqQuickShapesWith defeq context state left right
  else
    match psKernelExprV2PagedEqOnCanonical state.whnf.arena left right with
    | Except.error error => Option.some (Except.error error)
    | Except.ok equal =>
        if equal then Option.some (Except.ok (Prod.mk state (Option.some true)))
        else psKernelExprV2DefEqQuickAfterSyntaxWith defeq context state left right
