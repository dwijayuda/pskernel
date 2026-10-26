import Ps.KernelCore.API.DagMutualRecursiveArgument
import Ps.KernelCore.API.DagOrdinaryConstructorFields

/- Private mutual constructor fields. The original syntactic field telescope,
   check/mandatory EnsureSort/universe order, per-field fuel and scope restore
   are retained. No declaration or provisional environment is published. -/
structure PsKernelExprV2MutualOpenedField where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  field : PsKernelExprV2OrdinaryOpenBinder
  body : Nat
  recursiveField : Option PsKernelExprV2MutualRecursiveField

structure PsKernelExprV2MutualOpenFieldsResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  fields : List PsKernelExprV2OrdinaryOpenBinder
  recursiveFields : List PsKernelExprV2MutualRecursiveField
  result : Nat

def psKernelExprV2MutualReverseRecursiveFieldsWorker
    (values : List PsKernelExprV2MutualRecursiveField) :
    List PsKernelExprV2MutualRecursiveField -> List PsKernelExprV2MutualRecursiveField :=
  match values with
  | List.nil => fun (acc : List PsKernelExprV2MutualRecursiveField) => acc
  | List.cons value rest =>
      let smaller := psKernelExprV2MutualReverseRecursiveFieldsWorker rest;
      fun (acc : List PsKernelExprV2MutualRecursiveField) => smaller (List.cons value acc)

def psKernelExprV2MutualPrepareFieldAfterSort
    (context : PsKernelExprV2CheckContext)
    (sorted : Prod PsKernelExprV2CheckState PsKernelLevel)
    (resultLevel : PsKernelLevel) (userName : PsKernelName)
    (domain : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String PsKernelExprV2OrdinaryPreparedField :=
  if
      if psKernelLevelLe (Prod.snd sorted) resultLevel then true
      else psKernelLevelNormalizesToZero resultLevel then
    let next := Prod.fst sorted;
    match psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
        next.whnf.arena domain with
    | Except.error error => Except.error error
    | Except.ok localDomain =>
        let freshResult := psKernelExprV2CheckStateFreshName next userName;
        let fresh := Prod.fst freshResult;
        Except.ok
          (PsKernelExprV2OrdinaryPreparedField.mk
            (psKernelExprV2CheckContextWithLocal
              context fresh userName localDomain binderInfo)
            (Prod.snd freshResult)
            (PsKernelExprV2OrdinaryOpenBinder.mk
              fresh userName localDomain binderInfo))
  else
    Except.error "mutual inductive constructor field universe is too large"

def psKernelExprV2MutualPrepareFieldWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (resultLevel : PsKernelLevel)
    (userName : PsKernelName) (domain : Nat) (binderInfo : PsKernelBinderInfo) :
    Option (Except String PsKernelExprV2OrdinaryPreparedField) :=
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
              | Except.ok sorted =>
                  Option.some
                    (psKernelExprV2MutualPrepareFieldAfterSort
                      context sorted resultLevel userName domain binderInfo)

/- Only the successful recursive child's arena and monotone freshness cross
   back to the field owner. Temporary argument locals and child caches do not. -/
def psKernelExprV2MutualFinishField
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (analysis : PsKernelExprV2MutualRecursiveArgumentResult)
    (body : Nat) : Except String PsKernelExprV2MutualOpenedField :=
  let restored := psKernelExprV2CheckStateExitLocalScope prepared.state analysis.state;
  match psKernelExprV2PagedMkFVar restored.whnf.arena prepared.field.internalName with
  | Except.error error => Except.error error
  | Except.ok fvarBuilt =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.instantiate 0 (List.cons (Prod.snd fvarBuilt) List.nil))
          (Prod.fst fvarBuilt) body 0 with
      | Except.error error => Except.error error
      | Except.ok instantiated =>
          Except.ok (PsKernelExprV2MutualOpenedField.mk prepared.context
            (psKernelExprV2CheckStateWithArena restored (Prod.fst instantiated))
            prepared.field (Prod.snd instantiated) analysis.recursiveInfo)

def psKernelExprV2MutualOpenConstructorFieldWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      List PsKernelName -> List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel ->
      List PsKernelExprV2OrdinaryOpenBinder -> PsKernelExprV2OrdinaryOpenBinder -> Nat ->
      Option (Except String PsKernelExprV2MutualRecursiveArgumentResult))
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (userName : PsKernelName)
    (domain body : Nat) (binderInfo : PsKernelBinderInfo) :
    Option (Except String PsKernelExprV2MutualOpenedField) :=
  match psKernelExprV2MutualPrepareFieldWith
      check whnf fuel context state resultLevel userName domain binderInfo with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok prepared =>
          match analyze fuel prepared.context prepared.state targets types levels
              parameters prepared.field domain with
          | Option.none => Option.none
          | Option.some attemptedAnalysis =>
              match attemptedAnalysis with
              | Except.error error => Option.some (Except.error error)
              | Except.ok analysis => Option.some (psKernelExprV2MutualFinishField prepared analysis body)

def psKernelExprV2MutualOpenConstructorFieldsWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      List PsKernelName -> List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel ->
      List PsKernelExprV2OrdinaryOpenBinder -> PsKernelExprV2OrdinaryOpenBinder -> Nat -> Option (Except String PsKernelExprV2MutualRecursiveArgumentResult)) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> List PsKernelName ->
    List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
    PsKernelLevel -> Nat -> List PsKernelExprV2OrdinaryOpenBinder ->
    List PsKernelExprV2MutualRecursiveField ->
    Option (Except String PsKernelExprV2MutualOpenFieldsResult) :=
  match fuel with
  | Nat.zero =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          List PsKernelName -> List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel ->
          List PsKernelExprV2OrdinaryOpenBinder -> PsKernelExprV2OrdinaryOpenBinder -> Nat -> Option (Except String PsKernelExprV2MutualRecursiveArgumentResult))
        (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
        (_targets : List PsKernelName) (_types : List PsKernelExprV2MutualTypeHeader)
        (_levels : List PsKernelLevel)
        (_parameters : List PsKernelExprV2OrdinaryOpenBinder)
        (_resultLevel : PsKernelLevel) (_type : Nat)
        (_revFields : List PsKernelExprV2OrdinaryOpenBinder)
        (_revRecursive : List PsKernelExprV2MutualRecursiveField) =>
        Option.some (Except.error "mutual constructor field budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2MutualOpenConstructorFieldsWorker remaining;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          List PsKernelName -> List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel ->
          List PsKernelExprV2OrdinaryOpenBinder -> PsKernelExprV2OrdinaryOpenBinder -> Nat -> Option (Except String PsKernelExprV2MutualRecursiveArgumentResult))
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
        (levels : List PsKernelLevel)
        (parameters : List PsKernelExprV2OrdinaryOpenBinder)
        (resultLevel : PsKernelLevel) (type : Nat)
        (revFields : List PsKernelExprV2OrdinaryOpenBinder)
        (revRecursive : List PsKernelExprV2MutualRecursiveField) =>
        match psKernelExprV2PagedRequire state.whnf.arena type with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                match psKernelExprV2MutualOpenConstructorFieldWith
                    check whnf analyze remaining context state targets types levels parameters
                    resultLevel userName domain body binderInfo with
                | Option.none => Option.none
                | Option.some attemptedField =>
                    match attemptedField with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok opened =>
                        let nextRecursive : List PsKernelExprV2MutualRecursiveField :=
                          match opened.recursiveField with
                          | Option.none => revRecursive
                          | Option.some recursiveField =>
                              List.cons recursiveField revRecursive;
                        smaller check whnf analyze opened.context opened.state
                          targets types levels parameters resultLevel opened.body
                          (List.cons opened.field revFields) nextRecursive
            | _ =>
                Option.some
                  (Except.ok
                    (PsKernelExprV2MutualOpenFieldsResult.mk context state
                      (psKernelExprV2OrdinaryReverseOpenBinders revFields)
                      (psKernelExprV2MutualReverseRecursiveFieldsWorker revRecursive List.nil) type))

def psKernelExprV2MutualOpenConstructorFieldsWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (type : Nat) :
    Option (Except String PsKernelExprV2MutualOpenFieldsResult) :=
  psKernelExprV2MutualOpenConstructorFieldsWorker (Nat.succ fuel) check whnf
    (psKernelExprV2MutualAnalyzeRecursiveArgumentWith whnf)
    context state targets types levels parameters resultLevel type List.nil List.nil

def psKernelExprV2MutualOpenConstructorFieldsWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) (type : Nat) :
    Option (Except String PsKernelExprV2MutualOpenFieldsResult) :=
  psKernelExprV2MutualOpenConstructorFieldsWith
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
    fuel context state targets types levels parameters resultLevel type
