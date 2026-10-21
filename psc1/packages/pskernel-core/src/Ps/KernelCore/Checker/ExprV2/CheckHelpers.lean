import Ps.KernelCore.Checker.ExprV2.CheckWhnf

/-
Shared binder rules for checked and inference-only modes. The supplied typed WHNF callback
keeps the original top-level checking fuel; only the supplied recursive checker
consumes predecessor inference fuel. Local types and optional let values belong
to the same canonical arena.
-/
structure PsKernelExprV2OpenedCheckBinder where
  context : PsKernelExprV2CheckContext
  parent : PsKernelExprV2CheckState
  fresh : PsKernelName
  body : Nat

def psKernelExprV2CheckOpenLocal
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (name : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)
    (value : Option Nat) :
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
              (psKernelExprV2CheckContextWithLocalValue
                context fresh name domain binderInfo value)
              (psKernelExprV2CheckStateWithArena next (Prod.fst opened))
              fresh
              (Prod.snd opened))

def psKernelExprV2CheckOpenBinder
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (name : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String PsKernelExprV2OpenedCheckBinder :=
  psKernelExprV2CheckOpenLocal context state name domain body binderInfo Option.none

def psKernelExprV2CheckEnsureSortWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
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
          match whnf context state.whnf type with
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
    (state : PsKernelExprV2CheckState) (type _root : Nat)
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
          let scopedState := psKernelExprV2CheckStateExitLocalScope opened.parent state;
          psKernelExprV2InferenceBuilt scopedState
            (psKernelExprV2PagedMkForall
              (Prod.fst closed) name domain (Prod.snd closed) binderInfo)

def psKernelExprV2CheckCloseForallWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (opened : PsKernelExprV2OpenedCheckBinder)
    (state : PsKernelExprV2CheckState) (type _root : Nat)
    (domainLevel : PsKernelLevel) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheckEnsureSortWith whnf opened.context state type with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok bodySort =>
          let scopedState :=
            psKernelExprV2CheckStateExitLocalScope opened.parent (Prod.fst bodySort);
          Option.some
            (psKernelExprV2InferenceBuilt scopedState
              (psKernelExprV2PagedMkSort scopedState.whnf.arena
                (psKernelLevelMkIMax domainLevel (Prod.snd bodySort))))

def psKernelExprV2CheckBinderWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat)
    (name : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)
    (isLambda inferOnly : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let skipDomain := if isLambda then inferOnly else false;
  let checkedDomain :
      Option (Except String (Prod PsKernelExprV2CheckState PsKernelLevel)) :=
    if skipDomain then
      -- A lambda result uses its original domain, not a domain universe.
      -- The placeholder level is never read in the lambda closing branch.
      Option.some (Except.ok (Prod.mk state PsKernelLevel.zero))
    else
      match check context state domain with
      | Option.none => Option.none
      | Option.some attemptedDomain =>
          match attemptedDomain with
          | Except.error error => Option.some (Except.error error)
          | Except.ok domainResult =>
              psKernelExprV2CheckEnsureSortWith
                whnf context (Prod.fst domainResult) (Prod.snd domainResult);
  match checkedDomain with
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
