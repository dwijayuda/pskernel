import Ps.KernelCore.API.DagOrdinaryRecursiveArgument

/-
Private ordinary-constructor field opening over a canonical owning arena.
The original constructor telescope is inspected syntactically; no WHNF opens
its outer field spine. Checking and mandatory admission EnsureSort precede
the universe guard, annotation consumption and field-local allocation.

Recursive-argument analysis receives that post-field owner and the ORIGINAL
domain. Only after successful analysis do we restore the post-field scope,
retain the child's arena and monotone freshness, and instantiate the body.
These helpers do not admit or publish declarations.
-/
structure PsKernelExprV2OrdinaryPreparedField where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  field : PsKernelExprV2OrdinaryOpenBinder

structure PsKernelExprV2OrdinaryOpenedField where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  field : PsKernelExprV2OrdinaryOpenBinder
  body : Nat
  recursiveField : Option PsKernelExprV2OrdinaryRecursiveField

def psKernelExprV2OrdinaryPrepareFieldAfterSort
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
    Except.error "simple inductive constructor field universe is too large"

def psKernelExprV2OrdinaryPrepareFieldWith
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
                    (psKernelExprV2OrdinaryPrepareFieldAfterSort
                      context sorted resultLevel userName domain binderInfo)

/- The child context is intentionally discarded. Temporary recursive-function
   arguments do not enter the next field scope, but returned descriptor IDs
   remain valid in the retained child arena. -/
def psKernelExprV2OrdinaryFinishField
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (analysis : PsKernelExprV2OrdinaryRecursiveArgumentResult)
    (body : Nat) : Except String PsKernelExprV2OrdinaryOpenedField :=
  let restored := psKernelExprV2CheckStateExitLocalScope prepared.state analysis.state;
  match psKernelExprV2PagedMkFVar restored.whnf.arena prepared.field.internalName with
  | Except.error error => Except.error error
  | Except.ok fvarBuilt =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.instantiate 0
            (List.cons (Prod.snd fvarBuilt) List.nil))
          (Prod.fst fvarBuilt) body 0 with
      | Except.error error => Except.error error
      | Except.ok instantiated =>
          let recursiveField :=
            match analysis.recursiveInfo with
            | Option.none => Option.none
            | Option.some info =>
                Option.some
                  (PsKernelExprV2OrdinaryRecursiveField.mk
                    prepared.field (Prod.fst info) (Prod.snd info));
          Except.ok
            (PsKernelExprV2OrdinaryOpenedField.mk prepared.context
              (psKernelExprV2CheckStateWithArena restored (Prod.fst instantiated))
              prepared.field (Prod.snd instantiated) recursiveField)

def psKernelExprV2OrdinaryOpenConstructorFieldWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
      Nat -> Nat -> Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices : Nat) (resultLevel : PsKernelLevel)
    (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo) :
    Option (Except String PsKernelExprV2OrdinaryOpenedField) :=
  match psKernelExprV2OrdinaryPrepareFieldWith
      check whnf fuel context state resultLevel userName domain binderInfo with
  | Option.none => Option.none
  | Option.some attemptedField =>
      match attemptedField with
      | Except.error error => Option.some (Except.error error)
      | Except.ok prepared =>
          match analyze fuel prepared.context prepared.state
              target levels parameters numIndices domain with
          | Option.none => Option.none
          | Option.some attemptedAnalysis =>
              match attemptedAnalysis with
              | Except.error error => Option.some (Except.error error)
              | Except.ok analysis =>
                  Option.some (psKernelExprV2OrdinaryFinishField prepared analysis body)

def psKernelExprV2OrdinaryOpenConstructorFieldsWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
      Nat -> Nat -> Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult)) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> PsKernelName ->
    List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder -> Nat ->
    PsKernelLevel -> Nat -> List PsKernelExprV2OrdinaryOpenBinder ->
    List PsKernelExprV2OrdinaryRecursiveField ->
    Option (Except String PsKernelExprV2OrdinaryOpenFieldsResult) :=
  match fuel with
  | Nat.zero =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
          Nat -> Nat -> Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult))
        (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
        (_target : PsKernelName) (_levels : List PsKernelLevel)
        (_parameters : List PsKernelExprV2OrdinaryOpenBinder) (_numIndices : Nat)
        (_resultLevel : PsKernelLevel) (_type : Nat)
        (_revFields : List PsKernelExprV2OrdinaryOpenBinder)
        (_revRecursive : List PsKernelExprV2OrdinaryRecursiveField) =>
        Option.some (Except.error "simple inductive field budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2OrdinaryOpenConstructorFieldsWorker remaining;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
          Nat -> Nat -> Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult))
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (target : PsKernelName) (levels : List PsKernelLevel)
        (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
        (resultLevel : PsKernelLevel) (type : Nat)
        (revFields : List PsKernelExprV2OrdinaryOpenBinder)
        (revRecursive : List PsKernelExprV2OrdinaryRecursiveField) =>
        match psKernelExprV2PagedRequire state.whnf.arena type with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                match psKernelExprV2OrdinaryOpenConstructorFieldWith
                    check whnf analyze remaining context state target levels parameters
                    numIndices resultLevel userName domain body binderInfo with
                | Option.none => Option.none
                | Option.some attemptedField =>
                    match attemptedField with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok opened =>
                        let nextRecursive :=
                          match opened.recursiveField with
                          | Option.none => revRecursive
                          | Option.some recursiveField =>
                              List.cons recursiveField revRecursive;
                        smaller check whnf analyze opened.context opened.state
                          target levels parameters numIndices resultLevel opened.body
                          (List.cons opened.field revFields) nextRecursive
            | _ =>
                Option.some
                  (Except.ok
                    (PsKernelExprV2OrdinaryOpenFieldsResult.mk context state
                      (psKernelExprV2OrdinaryReverseOpenBinders revFields)
                      (psKernelExprV2OrdinaryReverseRecursiveFields revRecursive) type))

def psKernelExprV2OrdinaryOpenConstructorFieldsWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices : Nat) (resultLevel : PsKernelLevel) (type : Nat) :
    Option (Except String PsKernelExprV2OrdinaryOpenFieldsResult) :=
  psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel)
    check whnf (psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWith check whnf)
    context state target levels parameters numIndices resultLevel type List.nil List.nil

def psKernelExprV2OrdinaryOpenConstructorFieldsWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices : Nat) (resultLevel : PsKernelLevel) (type : Nat) :
    Option (Except String PsKernelExprV2OrdinaryOpenFieldsResult) :=
  psKernelExprV2OrdinaryOpenConstructorFieldsWith
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
    fuel context state target levels parameters numIndices resultLevel type
