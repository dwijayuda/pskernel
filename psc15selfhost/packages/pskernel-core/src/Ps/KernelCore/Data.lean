inductive PsKernelCoreOption (alpha : Type) where
  | none
  | some (value : alpha)

inductive PsKernelCoreList (alpha : Type) where
  | nil
  | cons (head : alpha) (tail : PsKernelCoreList alpha)

inductive PsKernelCoreResult (error : Type) (ok : Type) where
  | error (value : error)
  | ok (value : ok)
