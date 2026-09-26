inductive PsKernelCoreName where
  | anonymous
  | str (parent : PsKernelCoreName) (value : String)
  | num (parent : PsKernelCoreName) (value : Nat)
