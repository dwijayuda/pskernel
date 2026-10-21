import Ps.KernelCore.Checker.ExprV2.CheckState
import Ps.KernelCore.Core.ExprV2.Transform

/-
Lambda and forall spines share one DAG traversal. The spine budget is separate
from the injected predecessor DefEq callback. Locals use the right binder's
name, instantiated type and binder information, matching the complete checker.
Unsupported comparisons return no partial state.
-/
structure PsKernelExprV2DefEqBinderView where
  name : PsKernelName
  domain : Nat
  body : Nat
  binderInfo : PsKernelBinderInfo

structure PsKernelExprV2DefEqOpenedPair where
  state : PsKernelExprV2CheckState
  left : Nat
  right : Nat

structure PsKernelExprV2DefEqDomainResult where
  state : PsKernelExprV2CheckState
  rightType : Nat
  equal : Bool

structure PsKernelExprV2DefEqSpineScope where
  context : PsKernelExprV2CheckContext
  parent : PsKernelExprV2CheckState
  replacement : Nat

def psKernelExprV2DefEqBinderViewOf
    (isLambda : Bool) (node : PsKernelExprV2Node) :
    Option PsKernelExprV2DefEqBinderView :=
  if isLambda then
    match node with
    | PsKernelExprV2Node.lam name domain body binderInfo =>
        Option.some (PsKernelExprV2DefEqBinderView.mk name domain body binderInfo)
    | _ => Option.none
  else
    match node with
    | PsKernelExprV2Node.forallE name domain body binderInfo =>
        Option.some (PsKernelExprV2DefEqBinderView.mk name domain body binderInfo)
    | _ => Option.none

def psKernelExprV2DefEqSubstAppend (values : List Nat) (value : Nat) : List Nat :=
  match values with
  | List.nil => List.cons value List.nil
  | List.cons first rest =>
      List.cons first (psKernelExprV2DefEqSubstAppend rest value)

def psKernelExprV2DefEqSpineOpenPair
    (state : PsKernelExprV2CheckState) (left right : Nat) (subst : List Nat) :
    Except String PsKernelExprV2DefEqOpenedPair :=
  let values := psKernelExprV2TransformNatReverse subst List.nil;
  let operation := PsKernelExprV2Transform.instantiate 0 values;
  match psKernelExprV2TransformOnCanonical operation state.whnf.arena left 0 with
  | Except.error error => Except.error error
  | Except.ok leftOpened =>
      match psKernelExprV2TransformOnCanonical operation
          (Prod.fst leftOpened) right 0 with
      | Except.error error => Except.error error
      | Except.ok rightOpened =>
          Except.ok
            (PsKernelExprV2DefEqOpenedPair.mk
              (psKernelExprV2CheckStateWithArena state (Prod.fst rightOpened))
              (Prod.snd leftOpened) (Prod.snd rightOpened))

def psKernelExprV2DefEqSpineCompareFinal
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) (subst : List Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqSpineOpenPair state left right subst with
  | Except.error error => Option.some (Except.error error)
  | Except.ok opened => defeq context opened.state opened.left opened.right

def psKernelExprV2DefEqSpineDomainsWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : PsKernelExprV2DefEqBinderView) (subst : List Nat) :
    Option (Except String PsKernelExprV2DefEqDomainResult) :=
  match psKernelExprV2DefEqSpineOpenPair state left.domain right.domain subst with
  | Except.error error => Option.some (Except.error error)
  | Except.ok opened =>
      match psKernelExprV2PagedEqOnCanonical
          opened.state.whnf.arena left.domain right.domain with
      | Except.error error => Option.some (Except.error error)
      | Except.ok equal =>
          if equal then
            Option.some
              (Except.ok
                (PsKernelExprV2DefEqDomainResult.mk opened.state opened.right true))
          else
            match defeq context opened.state opened.left opened.right with
            | Option.none => Option.none
            | Option.some attempted =>
                match attempted with
                | Except.error error => Option.some (Except.error error)
                | Except.ok compared =>
                    Option.some
                      (Except.ok
                        (PsKernelExprV2DefEqDomainResult.mk
                          (Prod.fst compared) opened.right (Prod.snd compared)))

def psKernelExprV2DefEqSpineBodiesLoose
    (state : PsKernelExprV2CheckState) (left right : Nat) : Except String Bool :=
  match psKernelExprV2PagedRequire state.whnf.arena left with
  | Except.error error => Except.error error
  | Except.ok leftEntry =>
      if Nat.beq leftEntry.looseRange 0 then
        match psKernelExprV2PagedRequire state.whnf.arena right with
        | Except.error error => Except.error error
        | Except.ok rightEntry => Except.ok (Bool.not (Nat.beq rightEntry.looseRange 0))
      else Except.ok true

def psKernelExprV2DefEqSpineWithLocal
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (view : PsKernelExprV2DefEqBinderView) (type : Nat) :
    Except String PsKernelExprV2DefEqSpineScope :=
  let freshResult := psKernelExprV2CheckStateFreshName state view.name;
  let fresh := Prod.fst freshResult;
  let next := Prod.snd freshResult;
  match psKernelExprV2PagedMkFVar next.whnf.arena fresh with
  | Except.error error => Except.error error
  | Except.ok built =>
      Except.ok
        (PsKernelExprV2DefEqSpineScope.mk
          (psKernelExprV2CheckContextWithLocal
            context fresh view.name type view.binderInfo)
          (psKernelExprV2CheckStateWithArena next (Prod.fst built))
          (Prod.snd built))

def psKernelExprV2DefEqSpineExitScope
    (parent : PsKernelExprV2CheckState)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Bool))) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok compared =>
          Option.some
            (Except.ok
              (Prod.mk
                (psKernelExprV2CheckStateExitLocalScope parent (Prod.fst compared))
                (Prod.snd compared)))

def psKernelExprV2DefEqSpineStepWith
    (smaller : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      List Nat -> Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : PsKernelExprV2DefEqBinderView) (subst : List Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqSpineDomainsWith defeq context state left right subst with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok domains =>
          if domains.equal then
            match psKernelExprV2DefEqSpineBodiesLoose domains.state left.body right.body with
            | Except.error error => Option.some (Except.error error)
            | Except.ok loose =>
                if loose then
                  match psKernelExprV2DefEqSpineWithLocal
                      context domains.state right domains.rightType with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok scope =>
                      psKernelExprV2DefEqSpineExitScope scope.parent
                        (smaller scope.context scope.parent left.body right.body
                          (psKernelExprV2DefEqSubstAppend subst scope.replacement))
                else
                  match psKernelExprV2PagedMkSort domains.state.whnf.arena PsKernelLevel.zero with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok placeholder =>
                      smaller context
                        (psKernelExprV2CheckStateWithArena domains.state (Prod.fst placeholder))
                        left.body right.body
                        (psKernelExprV2DefEqSubstAppend subst (Prod.snd placeholder))
          else Option.some (Except.ok (Prod.mk domains.state false))

def psKernelExprV2DefEqBinderSpineWithFuel
    (fuel : Nat) :
    Bool ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat -> List Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero =>
      fun (isLambda : Bool)
          (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
          (_left _right : Nat) (_subst : List Nat) =>
        if isLambda then
          Option.some (Except.error "kernel defeq lambda-spine budget exhausted")
        else Option.some (Except.error "kernel defeq forall-spine budget exhausted")
  | Nat.succ remaining =>
      fun (isLambda : Bool)
          (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
          (left right : Nat) (subst : List Nat) =>
        let smaller :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat)
              (nextSubst : List Nat) =>
            let recur := psKernelExprV2DefEqBinderSpineWithFuel remaining;
            recur isLambda defeq nextContext nextState nextLeft nextRight nextSubst;
        match psKernelExprV2PagedRequire state.whnf.arena left with
        | Except.error error => Option.some (Except.error error)
        | Except.ok leftEntry =>
            match psKernelExprV2DefEqBinderViewOf isLambda leftEntry.node with
            | Option.none =>
                psKernelExprV2DefEqSpineCompareFinal defeq context state left right subst
            | Option.some leftView =>
                match psKernelExprV2PagedRequire state.whnf.arena right with
                | Except.error error => Option.some (Except.error error)
                | Except.ok rightEntry =>
                    match psKernelExprV2DefEqBinderViewOf isLambda rightEntry.node with
                    | Option.none =>
                        psKernelExprV2DefEqSpineCompareFinal defeq context state left right subst
                    | Option.some rightView =>
                        psKernelExprV2DefEqSpineStepWith smaller defeq
                          context state leftView rightView subst

def psKernelExprV2DefEqBinderSpine
    (isLambda : Bool)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2TransformCountOnCanonical state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftCount =>
      match psKernelExprV2TransformCountOnCanonical state.whnf.arena right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightCount =>
          psKernelExprV2DefEqBinderSpineWithFuel
            (Nat.succ (Nat.add leftCount rightCount))
            isLambda defeq context state left right List.nil
