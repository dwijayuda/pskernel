inductive PsKernelOneOption (alpha : Type) where
  | none
  | some (value : alpha)

inductive PsKernelOneList (alpha : Type) where
  | nil
  | cons (head : alpha) (tail : PsKernelOneList alpha)
