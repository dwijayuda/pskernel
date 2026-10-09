inductive Sh1Empty (alpha : Type) where
def sh1EmptyNat (value : Sh1Empty Nat) : Nat := nomatch value
def sh1EmptyFunction (value : Sh1Empty Nat) : Nat -> Nat := nomatch value
def sh1EmptyGeneric (alpha : Type) (value : Sh1Empty alpha) : alpha := nomatch value
def sh1EmptyFresh (value : Sh1Empty Nat) (emptyResult : Nat) : Nat := nomatch value
