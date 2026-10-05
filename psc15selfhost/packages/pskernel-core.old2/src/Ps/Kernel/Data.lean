/-
Owned kernel data. No logical admission is implemented here.
Binary positives have a unique representation: the high end terminates in `one`.
Consequently identifier numerals never pass through a JavaScript Number.
-/
inductive PsKernelPositive where
  | one
  | bit0 (high : PsKernelPositive)
  | bit1 (high : PsKernelPositive)

inductive PsKernelNatural where
  | zero
  | positive (value : PsKernelPositive)

/- Raw internal UTF-8 byte sequence. Future ingress must validate byte range and
UTF-8 well-formedness; structural comparison does not establish either property. -/
inductive PsKernelText where
  | empty
  | byte (value : PsKernelNatural) (rest : PsKernelText)

inductive PsKernelName where
  | anonymous
  | str (parent : PsKernelName) (value : PsKernelText)
  | num (parent : PsKernelName) (value : PsKernelNatural)

/- Metavariables deliberately have no representation in this closed-core model. -/
inductive PsKernelLevel where
  | zero
  | succ (value : PsKernelLevel)
  | max (left : PsKernelLevel) (right : PsKernelLevel)
  | imax (left : PsKernelLevel) (right : PsKernelLevel)
  | param (name : PsKernelName)

inductive PsKernelList (a : Type) where
  | nil
  | cons (head : a) (tail : PsKernelList a)

/- Exhaustion is not a successful equality result or a proof of inequality. -/
inductive PsKernelCompareResult where
  | outOfFuel
  | equal
  | different

inductive PsKernelCompareTask where
  | positive (left : PsKernelPositive) (right : PsKernelPositive)
  | natural (left : PsKernelNatural) (right : PsKernelNatural)
  | name (left : PsKernelName) (right : PsKernelName)
  | text (left : PsKernelText) (right : PsKernelText)
  | level (left : PsKernelLevel) (right : PsKernelLevel)

/- An owned, finite work budget; avoids relying on a seed's Nat recursor lowering. -/
inductive PsKernelFuel where
  | stop
  | more (remaining : PsKernelFuel)

/- Owned branch flag. Seed Bool/ite are opaque logical prelude assumptions; use
this inductive for kernel computation instead of a host-only conditional. -/
inductive PsKernelFlag where
  | no
  | yes
