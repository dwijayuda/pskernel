import Ps.KernelCore.API.DagTypes
import Ps.KernelCore.API.DagAdmissionGuards
import Ps.KernelCore.API.DagOrdinaryConstructorParams
import Ps.KernelCore.API.DagOrdinaryConstructorFields
import Ps.KernelCore.API.DagOrdinaryConstructorResult

/-
Private analysis of one ordinary constructor over its canonical owning arena.
The caller has established the header parameter context/state and matching
provisional environment/references containing the datatype. This helper does
not install constructor metadata, generate recursors or publish any state.

phaseFuel is the predecessor chosen by the future outer constructor loop.
This helper neither adds nor consumes that outer step. Its parameter/field
wrappers retain their own existing successor conventions.

The constructor's closed type is checked in an independent fresh owner.
After mandatory public EnsureSort, only its appended arena is retained when
resuming the original header owner. Closed-check caches, references, locals
and freshness do not become constructor-opening state.
-/
structure PsKernelExprV2OrdinaryConstructorShape where
  ctor : PsKernelDagConstructor
  fields : List PsKernelExprV2OrdinaryOpenBinder
  recursiveFields : List PsKernelExprV2OrdinaryRecursiveField
  resultIndices : List Nat

structure PsKernelExprV2OrdinaryConstructorAnalysis where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  shape : PsKernelExprV2OrdinaryConstructorShape

def psKernelExprV2OrdinaryClosedConstructorContext
    (header : PsKernelExprV2CheckContext) : PsKernelExprV2CheckContext :=
  let closed := psKernelMkCheckerSession header.scalar.environment
    header.scalar.levelParams header.scalar.safety
    header.scalar.maxRecDepth header.scalar.maxNatSize;
  psKernelExprV2CheckContextEmpty closed.context

def psKernelExprV2OrdinaryClosedConstructorState
    (header : PsKernelExprV2CheckState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty header.whnf.arena)
    (psKernelExprV2WhnfStateForDeclarations
      header.whnf.arena header.whnf.declarations)

/- This is an independent-owner fork, not local-scope exit: even the closed
   owner's larger fresh counter is intentionally discarded, as in V1. -/
def psKernelExprV2OrdinaryResumeConstructorState
    (header closed : PsKernelExprV2CheckState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithArena header closed.whnf.arena

def psKernelExprV2OrdinaryFinishConstructorAnalysis
    (target : PsKernelName) (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
    (ctor : PsKernelDagConstructor)
    (opened : PsKernelExprV2OrdinaryOpenFieldsResult) :
    Except String PsKernelExprV2OrdinaryConstructorAnalysis :=
  match psKernelExprV2OrdinaryValidateConstructorResult
      opened.state.whnf.arena target levels parameters numIndices opened.result with
  | Except.error error => Except.error error
  | Except.ok resultIndices =>
      Except.ok
        (PsKernelExprV2OrdinaryConstructorAnalysis.mk opened.context opened.state
          (PsKernelExprV2OrdinaryConstructorShape.mk
            ctor opened.fields opened.recursiveFields resultIndices))

def psKernelExprV2OrdinaryConstructorAfterClosedWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
    (headerState closedState : PsKernelExprV2CheckState)
    (target : PsKernelName) (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
    (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis) :=
  let resumed := psKernelExprV2OrdinaryResumeConstructorState headerState closedState;
  match psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context resumed parameters ctor.type with
  | Option.none => Option.none
  | Option.some attemptedParameters =>
      match attemptedParameters with
      | Except.error error => Option.some (Except.error error)
      | Except.ok afterParameters =>
          match psKernelExprV2OrdinaryOpenConstructorFieldsWith
              check whnf phaseFuel context (Prod.fst afterParameters)
              target levels parameters numIndices resultLevel (Prod.snd afterParameters) with
          | Option.none => Option.none
          | Option.some attemptedFields =>
              match attemptedFields with
              | Except.error error => Option.some (Except.error error)
              | Except.ok opened =>
                  Option.some
                    (psKernelExprV2OrdinaryFinishConstructorAnalysis
                      target levels parameters numIndices ctor opened)

def psKernelExprV2OrdinaryAnalyzeConstructorWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
    (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis) :=
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
                      psKernelExprV2OrdinaryConstructorAfterClosedWith
                        check whnf defeq phaseFuel context state (Prod.fst sorted)
                        target levels parameters numIndices resultLevel ctor

def psKernelExprV2OrdinaryAnalyzeConstructorWithFuel
    (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
    (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis) :=
  let check :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryCheckStateWithFuel nextFuel nextContext nextState nextRoot;
  let whnf :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel nextFuel nextContext nextState nextRoot;
  psKernelExprV2OrdinaryAnalyzeConstructorWith
    check whnf psKernelExprV2TryDefEqStateWithFuel phaseFuel
    context state target levels parameters numIndices resultLevel ctor
