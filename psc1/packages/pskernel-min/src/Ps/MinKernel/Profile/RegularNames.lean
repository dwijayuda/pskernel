import Ps.Foundation.Name

-- Internal quotation identities use absolute declaration/constructor ordinals.
-- Relative slot rebasing and canonical source-name resolution are separate bridge obligations.
def psMinRegDataName (index : Nat) : PsName := PsName.num PsName.anonymous index

def psMinRegConstructorName (index ctorIndex : Nat) : PsName :=
  PsName.num (psMinRegDataName index) ctorIndex

def psMinRegRecursorName (index : Nat) : PsName :=
  PsName.str (psMinRegDataName index) "rec"

-- Names use stable chronological ordinals; types use newest-first relative slots.
def psMinRegOrdinal (count index : Nat) : Nat := Nat.sub count (Nat.succ index)

def psMinRegSlotName (count index : Nat) : Option PsName :=
  if Nat.blt index count then Option.some (psMinRegDataName (psMinRegOrdinal count index)) else Option.none
