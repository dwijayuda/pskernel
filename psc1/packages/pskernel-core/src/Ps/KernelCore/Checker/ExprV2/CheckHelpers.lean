import Ps.KernelCore.Checker.ExprV2.CheckState
import Ps.KernelCore.Checker.ExprV2.Whnf

/-
Binder rules for fully checked inference. The supplied WHNF callback keeps the
original top-level checking fuel; only the supplied recursive checker consumes
the predecessor inference fuel. Every local introduced here has no let value,
so its scalar WHNF behavior is exactly the unchanged-fvar case.
-/
structure PsKernelExprV2OpenedCheckBinder where
  context : PsKernelExprV2CheckContext
  parent : PsKernelExprV2CheckState
  fresh : PsKernelName
  body : Nat

def psKernelExprV2CheckOpenBinder
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (name : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String PsKernelExprV2OpenedCheckBinder :=
  let freshResult := psKernelExprV2CheckStateFreshName state name;
  let fresh := Prod.fst freshResult;
  let next := Prod.snd freshResult;
  match psKernelExprV2PagedMkFVar next.whnf.arena fresh with
  | Except.error error => Except.error error
  | Except.ok fvarBuilt =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.instantiate 0 (List.cons (Prod.snd fvarBuilt) List.nil))
          (Prod.fst fvarBuilt) body 0 with
      | Except.error error => Except.error error
      | Except.ok opened =>
          Except.ok
            (PsKernelExprV2OpenedCheckBinder.mk
              (psKernelExprV2CheckContextWithLocal context fresh name domain binderInfo)
              (psKernelExprV2CheckStateWithArena next (Prod.fst opened))
              fresh
              (Prod.snd opened))

def psKernelExprV2CheckEnsureSortWith
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelLevel)) :=
  match psKernelExprV2PagedRequire state.whnf.arena type with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.sort level =>
          Option.some (Except.ok (Prod.mk state level))
      | _ =>
          match whnf context.scalar state.whnf type with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  let next := Prod.fst reduced;
                  match psKernelExprV2PagedRequire next.arena (Prod.snd reduced) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok result =>
                      match result.node with
                      | PsKernelExprV2Node.sort level =>
                          Option.some
                            (Except.ok
                              (Prod.mk
                                (psKernelExprV2CheckStateWithWhnf state next)
                                level))
                      | _ => Option.some (Except.error "expected sort")

def psKernelExprV2CheckCloseLambda
    (opened : PsKernelExprV2OpenedCheckBinder)
    (state : PsKernelExprV2CheckState) (type root : Nat)
    (name : PsKernelName) (domain : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2CheapBetaOnCanonical state.whnf.arena type with
  | Except.error error => Except.error error
  | Except.ok cheap =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.abstractFVars (List.cons opened.fresh List.nil))
          (Prod.fst cheap) (Prod.snd cheap) 0 with
      | Except.error error => Except.error error
      | Except.ok closed =>
          let scoped := psKernelExprV2CheckStateExitLocalScope opened.parent state;
          psKernelExprV2CheckedInferBuilt scoped root
            (psKernelExprV2PagedMkForall
              (Prod.fst closed) name domain (Prod.snd closed) binderInfo)

def psKernelExprV2CheckCloseForallWith
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (opened : PsKernelExprV2OpenedCheckBinder)
    (state : PsKernelExprV2CheckState) (type root : Nat)
    (domainLevel : PsKernelLevel) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheckEnsureSortWith whnf opened.context state type with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok bodySort =>
          let scoped :=
            psKernelExprV2CheckStateExitLocalScope opened.parent (Prod.fst bodySort);
          Option.some
            (psKernelExprV2CheckedInferBuilt scoped root
              (psKernelExprV2PagedMkSort scoped.whnf.arena
                (psKernelLevelMkIMax domainLevel (Prod.snd bodySort))))

def psKernelExprV2CheckBinderWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat)
    (name : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)
    (isLambda : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match check context state domain with
  | Option.none => Option.none
  | Option.some attemptedDomain =>
      match attemptedDomain with
      | Except.error error => Option.some (Except.error error)
      | Except.ok domainResult =>
          match psKernelExprV2CheckEnsureSortWith
              whnf context (Prod.fst domainResult) (Prod.snd domainResult) with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok domainSort =>
                  match psKernelExprV2CheckOpenBinder
                      context (Prod.fst domainSort) name domain body binderInfo with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok opened =>
                      match check opened.context opened.parent opened.body with
                      | Option.none => Option.none
                      | Option.some attemptedBody =>
                          match attemptedBody with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok bodyResult =>
                              if isLambda then
                                Option.some
                                  (psKernelExprV2CheckCloseLambda opened
                                    (Prod.fst bodyResult) (Prod.snd bodyResult) root
                                    name domain binderInfo)
                              else
                                psKernelExprV2CheckCloseForallWith whnf opened
                                  (Prod.fst bodyResult) (Prod.snd bodyResult) root
                                  (Prod.snd domainSort)

def psKernelExprV2CheckFinishAttempt
    (source : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Nat))) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          Option.some
            (psKernelExprV2CheckedInferFinish
              (Prod.fst checked) source (Prod.snd checked))
