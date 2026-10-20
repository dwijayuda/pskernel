/- Structural comparison facts scoped to one immutable arena and operation.
These entries are never accepted as external proof/checking certificates.
Only the owning comparison constructs them; no caller-supplied memo is used
at the checked boundary. Their Bool records syntax equality, not DefEq. -/

structure PsKernelExprV2PairMemo where
  left : Nat
  right : Nat
  result : Bool

def psKernelExprV2PairMemoFind
    (entries : List PsKernelExprV2PairMemo)
    (left right : Nat) : Option Bool :=
  match entries with
  | List.nil =>
      Option.none
  | List.cons item rest =>
      if Nat.beq left item.left then
        if Nat.beq right item.right then
          Option.some item.result
        else
          psKernelExprV2PairMemoFind rest left right
      else
        psKernelExprV2PairMemoFind rest left right

def psKernelExprV2PairMemoInsert
    (entries : List PsKernelExprV2PairMemo)
    (left right : Nat) (result : Bool) :
    List PsKernelExprV2PairMemo :=
  let item : PsKernelExprV2PairMemo := {
    left := left
    right := right
    result := result
  };
  List.cons item entries

