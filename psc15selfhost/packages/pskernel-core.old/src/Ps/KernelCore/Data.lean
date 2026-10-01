inductive PsKernelCoreOption (alpha : Type) where
  | none
  | some (value : alpha)

inductive PsKernelCoreList (alpha : Type) where
  | nil
  | cons (head : alpha) (tail : PsKernelCoreList alpha)
