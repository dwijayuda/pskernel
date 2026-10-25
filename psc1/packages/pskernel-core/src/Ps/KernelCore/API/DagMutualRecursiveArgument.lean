import Ps.KernelCore.API.DagMutualConstructorResult
import Ps.KernelCore.API.DagOrdinaryParameters
import Ps.KernelCore.Core.ExprV2.ExpandedSize

/- Private mutual recursive-argument analysis. Structural traversal uses the
   exact original expanded-tree budget; checker fuel remains fixed across
   opened arguments. Unlike ordinary admission, original structural selection
   precedes WHNF. Complete constructor checking belongs to the outer caller.
   No environment or declaration is published here. -/

structure PsKernelExprV2MutualRecursiveField where
  field : PsKernelExprV2OrdinaryOpenBinder
  arguments : List PsKernelExprV2OrdinaryOpenBinder
  target : Nat
  indices : List Nat

structure PsKernelExprV2MutualRecursiveArgumentResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  recursiveInfo : Option PsKernelExprV2MutualRecursiveField

def psKernelExprV2MutualRecursiveSelected
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (field : PsKernelExprV2OrdinaryOpenBinder)
    (revArgs : List PsKernelExprV2OrdinaryOpenBinder)
    (info : PsKernelExprV2MutualAppInfo) : PsKernelExprV2MutualRecursiveArgumentResult :=
  PsKernelExprV2MutualRecursiveArgumentResult.mk context state
    (Option.some (PsKernelExprV2MutualRecursiveField.mk field
      (psKernelExprV2OrdinaryReverseOpenBinders revArgs) info.target info.indices))

def psKernelExprV2MutualRecursiveTerminal
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (original reduced : Nat) :
    Except String PsKernelExprV2MutualRecursiveArgumentResult :=
  match psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena targets original with
  | Except.error error => Except.error error
  | Except.ok found =>
      if found then
        Except.error "nested or invalid mutual inductive occurrence is not supported"
      else
        match psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena targets reduced with
        | Except.error error => Except.error error
        | Except.ok reducedFound =>
            if reducedFound then
              Except.error "nested or invalid mutual inductive occurrence is not supported"
            else Except.ok
              (PsKernelExprV2MutualRecursiveArgumentResult.mk context state Option.none)

/- The original mutual worker checks the syntactic argument domain before
   consuming annotations and allocating a local. It does not add a checker or
   WHNF call for this domain: the outer constructor type was already checked. -/
def psKernelExprV2MutualRecursiveOpenBinder
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (userName : PsKernelName)
    (domain body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String (Prod PsKernelExprV2OpenedCheckBinder PsKernelExprV2OrdinaryOpenBinder) :=
  match psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena targets domain with
  | Except.error error => Except.error error
  | Except.ok negative =>
      if negative then
        Except.error "mutual inductive field has a non-positive recursive occurrence"
      else
        match psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical state.whnf.arena domain with
        | Except.error error => Except.error error
        | Except.ok localDomain =>
            match psKernelExprV2CheckOpenBinder context state userName localDomain body binderInfo with
            | Except.error error => Except.error error
            | Except.ok opened => Except.ok (Prod.mk opened
                (PsKernelExprV2OrdinaryOpenBinder.mk opened.fresh userName localDomain binderInfo))

def psKernelExprV2MutualRecursiveAfterWhnfWith
    (recur : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      List PsKernelExprV2OrdinaryOpenBinder ->
      Option (Except String PsKernelExprV2MutualRecursiveArgumentResult))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (field : PsKernelExprV2OrdinaryOpenBinder) (original reduced : Nat)
    (revArgs : List PsKernelExprV2OrdinaryOpenBinder) :
    Option (Except String PsKernelExprV2MutualRecursiveArgumentResult) :=
  match psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena targets types levels parameters reduced with
  | Except.error error => Option.some (Except.error error)
  | Except.ok selected =>
      match selected with
      | Option.some info =>
          Option.some (Except.ok (psKernelExprV2MutualRecursiveSelected context state field revArgs info))
      | Option.none =>
          match psKernelExprV2PagedRequire state.whnf.arena reduced with
          | Except.error error => Option.some (Except.error error)
          | Except.ok entry =>
              match entry.node with
              | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                  match psKernelExprV2MutualRecursiveOpenBinder
                      context state targets userName domain body binderInfo with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok step =>
                      let opened := Prod.fst step;
                      recur opened.context opened.parent opened.body (List.cons (Prod.snd step) revArgs)
              | _ => Option.some
                  (psKernelExprV2MutualRecursiveTerminal context state targets original reduced)

def psKernelExprV2MutualAnalyzeRecursiveArgumentWorker
    (structuralFuel checkerFuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    List PsKernelName -> List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel ->
    List PsKernelExprV2OrdinaryOpenBinder -> PsKernelExprV2OrdinaryOpenBinder -> Nat ->
    List PsKernelExprV2OrdinaryOpenBinder ->
    Option (Except String PsKernelExprV2MutualRecursiveArgumentResult) :=
  match structuralFuel with
  | Nat.zero =>
      fun
        (_whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
        (_targets : List PsKernelName) (_types : List PsKernelExprV2MutualTypeHeader)
        (_levels : List PsKernelLevel) (_parameters : List PsKernelExprV2OrdinaryOpenBinder)
        (_field : PsKernelExprV2OrdinaryOpenBinder) (_domain : Nat)
        (_revArgs : List PsKernelExprV2OrdinaryOpenBinder) =>
        Option.some (Except.error "mutual recursive-argument budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2MutualAnalyzeRecursiveArgumentWorker remaining checkerFuel;
      fun
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
        (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
        (field : PsKernelExprV2OrdinaryOpenBinder) (domain : Nat)
        (revArgs : List PsKernelExprV2OrdinaryOpenBinder) =>
        match psKernelExprV2MutualAppInfoOnCanonical
            state.whnf.arena targets types levels parameters domain with
        | Except.error error => Option.some (Except.error error)
        | Except.ok selected =>
            match selected with
            | Option.some info => Option.some
                (Except.ok (psKernelExprV2MutualRecursiveSelected context state field revArgs info))
            | Option.none =>
                match whnf checkerFuel context state domain with
                | Option.none => Option.none
                | Option.some attempted =>
                    match attempted with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok result =>
                        let next := Prod.fst result;
                        let reduced := Prod.snd result;
                        let recur := fun (childContext : PsKernelExprV2CheckContext)
                            (childState : PsKernelExprV2CheckState) (childDomain : Nat)
                            (childArgs : List PsKernelExprV2OrdinaryOpenBinder) =>
                          smaller whnf childContext childState targets types levels parameters field childDomain childArgs;
                        psKernelExprV2MutualRecursiveAfterWhnfWith recur context next
                          targets types levels parameters field domain reduced revArgs

def psKernelExprV2MutualAnalyzeRecursiveArgumentWith
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (checkerFuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (field : PsKernelExprV2OrdinaryOpenBinder) (domain : Nat) :
    Option (Except String PsKernelExprV2MutualRecursiveArgumentResult) :=
  match psKernelExprV2ExpandedSizeOnCanonical state.whnf.arena domain with
  | Except.error error => Option.some (Except.error error)
  | Except.ok count =>
      psKernelExprV2MutualAnalyzeRecursiveArgumentWorker (Nat.succ count) checkerFuel
        whnf context state targets types levels parameters field domain List.nil

def psKernelExprV2MutualAnalyzeRecursiveArgumentWithFuel
    (checkerFuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (field : PsKernelExprV2OrdinaryOpenBinder) (domain : Nat) :
    Option (Except String PsKernelExprV2MutualRecursiveArgumentResult) :=
  psKernelExprV2MutualAnalyzeRecursiveArgumentWith psKernelExprV2TryWhnfCheckStateWithFuel
    checkerFuel context state targets types levels parameters field domain
