import Ps.KernelCore.API.DagOrdinaryHeaderTypes
import Ps.KernelCore.API.DagOrdinaryAnnotations
import Ps.KernelCore.Checker.ExprV2.AdmissionHelpers
import Ps.KernelCore.Checker.ExprV2.CheckHelpers

/-
Private ordinary-inductive binder opening over one canonical append-only arena.
Every callback receives the current complete owner. Parameter opening retains
the original checking fuel, including its final WHNF. Index opening consumes
one structural fuel step before inspecting the type and supplies predecessor
fuel to each checking and public-WHNF callback.
-/

def psKernelExprV2OrdinaryReverseOpenBindersWorker
    (values : List PsKernelExprV2OrdinaryOpenBinder) :
    List PsKernelExprV2OrdinaryOpenBinder -> List PsKernelExprV2OrdinaryOpenBinder :=
  match values with
  | List.nil =>
      fun (acc : List PsKernelExprV2OrdinaryOpenBinder) => acc
  | List.cons head tail =>
      let smaller := psKernelExprV2OrdinaryReverseOpenBindersWorker tail;
      fun (acc : List PsKernelExprV2OrdinaryOpenBinder) =>
        smaller (List.cons head acc)

def psKernelExprV2OrdinaryReverseOpenBinders
    (values : List PsKernelExprV2OrdinaryOpenBinder) :
    List PsKernelExprV2OrdinaryOpenBinder :=
  psKernelExprV2OrdinaryReverseOpenBindersWorker values List.nil

def psKernelExprV2OrdinaryOpenResult
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (revBinders : List PsKernelExprV2OrdinaryOpenBinder) (result : Nat) :
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  Option.some
    (Except.ok
      (PsKernelExprV2OrdinaryOpenResult.mk context state
        (psKernelExprV2OrdinaryReverseOpenBinders revBinders) result))

def psKernelExprV2OrdinaryFinishOpenBindersWithWhnf
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type : Nat)
    (revBinders : List PsKernelExprV2OrdinaryOpenBinder) :
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  match whnf fuel context state type with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          psKernelExprV2OrdinaryOpenResult context (Prod.fst reduced)
            revBinders (Prod.snd reduced)

/- The checked type of the domain is used only for mandatory public EnsureSort.
   The original domain is then annotation-consumed in that returned owner's
   arena. CheckOpenBinder's field named parent is the post-opening owner. -/
def psKernelExprV2OrdinaryOpenHeaderBinderWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo) :
    Option (Except String
      (Prod PsKernelExprV2OpenedCheckBinder PsKernelExprV2OrdinaryOpenBinder)) :=
  match check fuel context state domain with
  | Option.none => Option.none
  | Option.some attemptedDomain =>
      match attemptedDomain with
      | Except.error error => Option.some (Except.error error)
      | Except.ok domainType =>
          match psKernelExprV2AdmissionEnsureSortOwnedWith
              (whnf fuel) context (Prod.fst domainType) (Prod.snd domainType) with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok sortResult =>
                  let next := Prod.fst sortResult;
                  match psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
                      next.whnf.arena domain with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok localDomain =>
                      match psKernelExprV2CheckOpenBinder
                          context next userName localDomain body binderInfo with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok opened =>
                          Option.some
                            (Except.ok
                              (Prod.mk opened
                                (PsKernelExprV2OrdinaryOpenBinder.mk opened.fresh
                                  userName localDomain binderInfo)))

def psKernelExprV2OrdinaryOpenHeaderParamStepWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type : Nat) :
    Option (Except String
      (Prod PsKernelExprV2OpenedCheckBinder PsKernelExprV2OrdinaryOpenBinder)) :=
  match whnf fuel context state type with
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
              | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                  psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel
                    context next userName domain body binderInfo
              | _ =>
                  Option.some
                    (Except.error
                      "simple inductive declaration has fewer parameters than declared")

def psKernelExprV2OrdinaryOpenHeaderParamsWorker
    (remainingParams : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    List PsKernelExprV2OrdinaryOpenBinder ->
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  match remainingParams with
  | Nat.zero =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (fuel : Nat) (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (type : Nat)
        (revParams : List PsKernelExprV2OrdinaryOpenBinder) =>
        psKernelExprV2OrdinaryFinishOpenBindersWithWhnf
          whnf fuel context state type revParams
  | Nat.succ remaining =>
      let smaller := psKernelExprV2OrdinaryOpenHeaderParamsWorker remaining;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (fuel : Nat) (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (type : Nat)
        (revParams : List PsKernelExprV2OrdinaryOpenBinder) =>
        match psKernelExprV2OrdinaryOpenHeaderParamStepWith
            check whnf fuel context state type with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok step =>
                let opened := Prod.fst step;
                smaller check whnf fuel opened.context opened.parent opened.body
                  (List.cons (Prod.snd step) revParams)

def psKernelExprV2OrdinaryOpenHeaderParamsWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type numParams : Nat) :
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  psKernelExprV2OrdinaryOpenHeaderParamsWorker numParams
    check whnf fuel context state type List.nil

def psKernelExprV2OrdinaryOpenHeaderIndicesWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    List PsKernelExprV2OrdinaryOpenBinder ->
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  match fuel with
  | Nat.zero =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_context : PsKernelExprV2CheckContext)
        (_state : PsKernelExprV2CheckState) (_type : Nat)
        (_revIndices : List PsKernelExprV2OrdinaryOpenBinder) =>
        Option.some (Except.error "simple inductive index budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2OrdinaryOpenHeaderIndicesWorker remaining;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (type : Nat)
        (revIndices : List PsKernelExprV2OrdinaryOpenBinder) =>
        match whnf remaining context state type with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok reduced =>
                let next := Prod.fst reduced;
                let current := Prod.snd reduced;
                match psKernelExprV2PagedRequire next.whnf.arena current with
                | Except.error error => Option.some (Except.error error)
                | Except.ok entry =>
                    match entry.node with
                    | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                        match psKernelExprV2OrdinaryOpenHeaderBinderWith
                            check whnf remaining context next
                            userName domain body binderInfo with
                        | Option.none => Option.none
                        | Option.some attemptedBinder =>
                            match attemptedBinder with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok step =>
                                let opened := Prod.fst step;
                                smaller check whnf opened.context opened.parent opened.body
                                  (List.cons (Prod.snd step) revIndices)
                    | _ =>
                        psKernelExprV2OrdinaryOpenResult context next revIndices current

def psKernelExprV2OrdinaryOpenHeaderIndicesWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type : Nat) :
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ fuel)
    check whnf context state type List.nil
