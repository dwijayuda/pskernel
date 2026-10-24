import Ps.KernelCore.API.DagOrdinaryHeaderTypes

/-
Private constructor-analysis records over one canonical owning arena.
These records carry expression IDs and checker state, not admission receipts.
Temporary recursive-argument locals are restored by the field caller.
-/
structure PsKernelExprV2OrdinaryRecursiveArgumentResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  recursiveInfo :
    Option (Prod (List PsKernelExprV2OrdinaryOpenBinder) (List Nat))

structure PsKernelExprV2OrdinaryRecursiveField where
  field : PsKernelExprV2OrdinaryOpenBinder
  arguments : List PsKernelExprV2OrdinaryOpenBinder
  indices : List Nat

structure PsKernelExprV2OrdinaryOpenFieldsResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  fields : List PsKernelExprV2OrdinaryOpenBinder
  recursiveFields : List PsKernelExprV2OrdinaryRecursiveField
  result : Nat

def psKernelExprV2OrdinaryReverseRecursiveFieldsWorker
    (values : List PsKernelExprV2OrdinaryRecursiveField) :
    List PsKernelExprV2OrdinaryRecursiveField ->
    List PsKernelExprV2OrdinaryRecursiveField :=
  match values with
  | List.nil =>
      fun (acc : List PsKernelExprV2OrdinaryRecursiveField) => acc
  | List.cons head tail =>
      let smaller := psKernelExprV2OrdinaryReverseRecursiveFieldsWorker tail;
      fun (acc : List PsKernelExprV2OrdinaryRecursiveField) =>
        smaller (List.cons head acc)

def psKernelExprV2OrdinaryReverseRecursiveFields
    (values : List PsKernelExprV2OrdinaryRecursiveField) :
    List PsKernelExprV2OrdinaryRecursiveField :=
  psKernelExprV2OrdinaryReverseRecursiveFieldsWorker values List.nil
