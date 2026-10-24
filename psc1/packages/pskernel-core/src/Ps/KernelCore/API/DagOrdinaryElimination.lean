import Ps.KernelCore.API.DagTypes
import Ps.KernelCore.API.DagOrdinaryConstructorParams
import Ps.KernelCore.API.DagOrdinaryParameters
import Ps.KernelCore.Core.ExprV2.Equality

/-
Private ordinary-inductive elimination policy over an established constructor
owner. The original constructor types have already passed the ordinary header
and constructor checks. The canonical arena and every local/reference ID belong
to that owner. These are internal preconditions, not new acceptance rules for
untrusted constructors or forged arenas.

This phase reopens original parameters, then WHNFs the remaining telescope,
matching the frozen V1 elimination helper. Constructor field admission itself
still uses its syntactic telescope. Non-Prop fields must occur as complete
result application arguments under structural expression equality.

The final result is a Bool only, as in V1. Elimination-local names, caches and
appended nodes are private to this phase; its final owner does not become the
later recursor-checking owner. None/error discard the attempted phase. This
module generates no recursor, stages no metadata and changes no public route.
-/
def psKernelExprV2OrdinaryEliminationMemberWorker
    (values : List Nat) :
    PsKernelExprV2PagedArena -> Nat -> Except String Bool :=
  match values with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_needle : Nat) => Except.ok false
  | List.cons value rest =>
      let smaller := psKernelExprV2OrdinaryEliminationMemberWorker rest;
      fun (arena : PsKernelExprV2PagedArena) (needle : Nat) =>
        match psKernelExprV2PagedEqOnCanonical arena needle value with
        | Except.error error => Except.error error
        | Except.ok equal =>
            if equal then Except.ok true
            else smaller arena needle

def psKernelExprV2OrdinaryEliminationMember
    (arena : PsKernelExprV2PagedArena) (needle : Nat) (values : List Nat) :
    Except String Bool :=
  psKernelExprV2OrdinaryEliminationMemberWorker values arena needle

def psKernelExprV2OrdinaryEliminationAllMembersWorker
    (values : List Nat) :
    PsKernelExprV2PagedArena -> List Nat -> Except String Bool :=
  match values with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_haystack : List Nat) => Except.ok true
  | List.cons value rest =>
      let smaller := psKernelExprV2OrdinaryEliminationAllMembersWorker rest;
      fun (arena : PsKernelExprV2PagedArena) (haystack : List Nat) =>
        match psKernelExprV2OrdinaryEliminationMember arena value haystack with
        | Except.error error => Except.error error
        | Except.ok found =>
            if found then smaller arena haystack
            else Except.ok false

def psKernelExprV2OrdinaryEliminationAllMembers
    (arena : PsKernelExprV2PagedArena) (values haystack : List Nat) :
    Except String Bool :=
  psKernelExprV2OrdinaryEliminationAllMembersWorker values arena haystack

structure PsKernelExprV2OrdinaryEliminationStep where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  body : Nat
  revNonProp : List Nat

def psKernelExprV2OrdinaryEliminationAfterSort
    (context : PsKernelExprV2CheckContext)
    (sorted : Prod PsKernelExprV2CheckState PsKernelLevel)
    (userName : PsKernelName) (domain body : Nat)
    (binderInfo : PsKernelBinderInfo) (revNonProp : List Nat) :
    Except String PsKernelExprV2OrdinaryEliminationStep :=
  let state := Prod.fst sorted;
  match psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical state.whnf.arena domain with
  | Except.error error => Except.error error
  | Except.ok localDomain =>
      let freshResult := psKernelExprV2CheckStateFreshName state userName;
      let fresh := Prod.fst freshResult;
      let next := Prod.snd freshResult;
      let nextContext :=
        psKernelExprV2CheckContextWithLocal context fresh userName localDomain binderInfo;
      match psKernelExprV2PagedMkFVar next.whnf.arena fresh with
      | Except.error error => Except.error error
      | Except.ok fvarBuilt =>
          let nextNonProp : List Nat :=
            if psKernelLevelNormalizesToZero (Prod.snd sorted) then revNonProp
            else List.cons (Prod.snd fvarBuilt) revNonProp;
          match psKernelExprV2TransformOnCanonical
              (PsKernelExprV2Transform.instantiate 0 (List.cons (Prod.snd fvarBuilt) List.nil))
              (Prod.fst fvarBuilt) body 0 with
          | Except.error error => Except.error error
          | Except.ok instantiated =>
              Except.ok
                (PsKernelExprV2OrdinaryEliminationStep.mk nextContext
                  (psKernelExprV2CheckStateWithArena next (Prod.fst instantiated))
                  (Prod.snd instantiated) nextNonProp)

def psKernelExprV2OrdinaryEliminationStepWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (userName : PsKernelName)
    (domain body : Nat) (binderInfo : PsKernelBinderInfo) (revNonProp : List Nat) :
    Option (Except String PsKernelExprV2OrdinaryEliminationStep) :=
  match check fuel context state domain with
  | Option.none => Option.none
  | Option.some attemptedType =>
      match attemptedType with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          match psKernelExprV2AdmissionEnsureSortOwnedWith
              (whnf fuel) context (Prod.fst checked) (Prod.snd checked) with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok sorted =>
                  Option.some
                    (psKernelExprV2OrdinaryEliminationAfterSort
                      context sorted userName domain body binderInfo revNonProp)

def psKernelExprV2OrdinaryCtorAllowsLargeElimWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> List Nat ->
    Option (Except String Bool) :=
  match fuel with
  | Nat.zero =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
        (_type : Nat) (_revNonProp : List Nat) =>
        Option.some (Except.error "simple inductive elimination budget exhausted")
  | Nat.succ remaining =>
      let smaller :
          (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
          (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
          PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> List Nat ->
          Option (Except String Bool) :=
        psKernelExprV2OrdinaryCtorAllowsLargeElimWorker remaining;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (type : Nat) (revNonProp : List Nat) =>
        match whnf remaining context state type with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok reduced =>
                let next := Prod.fst reduced;
                let root := Prod.snd reduced;
                match psKernelExprV2PagedRequire next.whnf.arena root with
                | Except.error error => Option.some (Except.error error)
                | Except.ok entry =>
                    match entry.node with
                    | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                        match psKernelExprV2OrdinaryEliminationStepWith
                            check whnf remaining context next userName
                            domain body binderInfo revNonProp with
                        | Option.none => Option.none
                        | Option.some attemptedStep =>
                            match attemptedStep with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok step =>
                                smaller check whnf step.context step.state step.body step.revNonProp
                    | _ =>
                        match psKernelExprV2TransformAppSpineOnCanonical next.whnf.arena root with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok spine =>
                            Option.some
                              (psKernelExprV2OrdinaryEliminationAllMembers
                                next.whnf.arena revNonProp (Prod.snd spine))

def psKernelExprV2OrdinaryCtorAllowsLargeElimWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (type : Nat) :
    Option (Except String Bool) :=
  match psKernelExprV2OrdinaryOpenConstructorParamsWith defeq fuel context state parameters type with
  | Option.none => Option.none
  | Option.some attemptedParameters =>
      match attemptedParameters with
      | Except.error error => Option.some (Except.error error)
      | Except.ok opened =>
          psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
            check whnf context (Prod.fst opened) (Prod.snd opened) List.nil

def psKernelExprV2OrdinaryCtorAllowsLargeElimWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (type : Nat) :
    Option (Except String Bool) :=
  psKernelExprV2OrdinaryCtorAllowsLargeElimWith
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
    psKernelExprV2TryDefEqStateWithFuel fuel context state parameters type

def psKernelExprV2OrdinaryElimOnlyAtZeroWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (ctors : List PsKernelDagConstructor) :
    Option (Except String Bool) :=
  if psKernelLevelIsNotZero resultLevel then
    Option.some (Except.ok false)
  else
    match ctors with
    | List.nil => Option.some (Except.ok false)
    | List.cons ctor rest =>
        match rest with
        | List.nil =>
            match psKernelExprV2OrdinaryCtorAllowsLargeElimWith
                check whnf defeq fuel context state parameters ctor.type with
            | Option.none => Option.none
            | Option.some attempted =>
                match attempted with
                | Except.error error => Option.some (Except.error error)
                | Except.ok canLarge =>
                    if canLarge then Option.some (Except.ok false)
                    else Option.some (Except.ok true)
        | List.cons _ _ => Option.some (Except.ok true)

def psKernelExprV2OrdinaryElimOnlyAtZeroWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (ctors : List PsKernelDagConstructor) :
    Option (Except String Bool) :=
  psKernelExprV2OrdinaryElimOnlyAtZeroWith
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
    psKernelExprV2TryDefEqStateWithFuel fuel context state parameters resultLevel ctors
