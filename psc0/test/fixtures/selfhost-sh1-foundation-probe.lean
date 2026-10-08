-- Typed partial applications exercise the PSC calling convention, not only JS exports.
def sh1ReverseCurried (values : List Nat) (acc : List Nat) : List Nat :=
  let next : List Nat -> List Nat := psListReverseAcc values;
  next acc

def sh1AppendCurried (left : List Nat) (right : List Nat) : List Nat :=
  let next : List Nat -> List Nat := psListAppend left;
  next right

def sh1TakeCurried (count : Nat) (values : List Nat) : List Nat :=
  let next : List Nat -> List Nat := psListTake count;
  next values

def sh1ZipCurried (left : List Nat) (right : List Nat) : List (Prod Nat Nat) :=
  let next : List Nat -> List (Prod Nat Nat) := psListZip left;
  next right

def sh1ZipText (left : List Nat) (right : List String) : List (Prod Nat String) :=
  psListZip left right
