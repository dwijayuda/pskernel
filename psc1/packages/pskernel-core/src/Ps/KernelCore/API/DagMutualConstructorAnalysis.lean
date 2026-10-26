import Ps.KernelCore.API.DagMutualConstructorFields
import Ps.KernelCore.API.DagOrdinaryConstructorAnalysis

/- One private mutual constructor analysis. All-family result recognition runs
   before owner equality, preserving the two original errors. The complete
   closed constructor type is checked in a fresh owner, then only its arena
   resumes the shared parameter owner. No constructor metadata or environment
   is published here. The outer loop supplies the exact original phase fuel. -/
structure PsKernelExprV2MutualConstructorShape where
  owner : Nat
  ctor : PsKernelDagConstructor
  fields : List PsKernelExprV2OrdinaryOpenBinder
  recursiveFields : List PsKernelExprV2MutualRecursiveField
  resultIndices : List Nat

structure PsKernelExprV2MutualConstructorAnalysis where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  shape : PsKernelExprV2MutualConstructorShape

def psKernelExprV2MutualValidateConstructorResult
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName)
    (types : List PsKernelExprV2MutualTypeHeader) (owner : Nat)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (root : Nat) : Except String (List Nat) :=
  match psKernelExprV2MutualAppInfoOnCanonical arena targets types levels parameters root with
  | Except.error error => Except.error error
  | Except.ok selected =>
      match selected with
      | Option.none => Except.error "mutual constructor has invalid return type"
      | Option.some info =>
          if Nat.beq info.target owner then Except.ok info.indices
          else Except.error "mutual constructor returns the wrong datatype"

def psKernelExprV2MutualFinishConstructorAnalysis
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (owner : Nat) (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (ctor : PsKernelDagConstructor)
    (opened : PsKernelExprV2MutualOpenFieldsResult) :
    Except String PsKernelExprV2MutualConstructorAnalysis :=
  match psKernelExprV2MutualValidateConstructorResult opened.state.whnf.arena
      targets types owner levels parameters opened.result with
  | Except.error error => Except.error error
  | Except.ok resultIndices => Except.ok
      (PsKernelExprV2MutualConstructorAnalysis.mk opened.context opened.state
        (PsKernelExprV2MutualConstructorShape.mk owner ctor opened.fields opened.recursiveFields resultIndices))

def psKernelExprV2MutualConstructorAfterClosedWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
    (headerState closedState : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (owner : Nat) (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2MutualConstructorAnalysis) :=
  let resumed := psKernelExprV2OrdinaryResumeConstructorState headerState closedState;
  match psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context resumed parameters ctor.type with
  | Option.none => Option.none
  | Option.some attemptedParameters =>
      match attemptedParameters with
      | Except.error error => Option.some (Except.error error)
      | Except.ok afterParameters =>
          match psKernelExprV2MutualOpenConstructorFieldsWith
              check whnf phaseFuel context (Prod.fst afterParameters)
              targets types levels parameters resultLevel (Prod.snd afterParameters) with
          | Option.none => Option.none
          | Option.some attemptedFields =>
              match attemptedFields with
              | Except.error error => Option.some (Except.error error)
              | Except.ok opened =>
                  Option.some
                    (psKernelExprV2MutualFinishConstructorAnalysis
                      targets types owner levels parameters ctor opened)

def psKernelExprV2MutualAnalyzeConstructorWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader) (owner : Nat)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2MutualConstructorAnalysis) :=
  match psKernelExprV2AdmissionStaticOnCanonical
      state.whnf.arena ctor.type context.scalar.levelParams with
  | Except.error error => Option.some (Except.error error)
  | Except.ok _ =>
      let closedContext := psKernelExprV2OrdinaryClosedConstructorContext context;
      let closedState := psKernelExprV2OrdinaryClosedConstructorState state;
      match check phaseFuel closedContext closedState ctor.type with
      | Option.none => Option.none
      | Option.some attemptedType =>
          match attemptedType with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checkedType =>
              match psKernelExprV2AdmissionEnsureSortOwnedWith
                  (whnf phaseFuel) closedContext
                  (Prod.fst checkedType) (Prod.snd checkedType) with
              | Option.none => Option.none
              | Option.some attemptedSort =>
                  match attemptedSort with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok sorted =>
                      psKernelExprV2MutualConstructorAfterClosedWith
                        check whnf defeq phaseFuel context state (Prod.fst sorted)
                        targets types owner levels parameters resultLevel ctor

def psKernelExprV2MutualAnalyzeConstructorWithFuel
    (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader) (owner : Nat)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2MutualConstructorAnalysis) :=
  let check :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryCheckStateWithFuel nextFuel nextContext nextState nextRoot;
  let whnf :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel nextFuel nextContext nextState nextRoot;
  psKernelExprV2MutualAnalyzeConstructorWith
    check whnf psKernelExprV2TryDefEqStateWithFuel phaseFuel
    context state targets types owner levels parameters resultLevel ctor
