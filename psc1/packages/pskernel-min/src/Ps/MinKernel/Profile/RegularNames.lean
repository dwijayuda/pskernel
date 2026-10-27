import Ps.Foundation.Name

-- Internal quotation identities use absolute declaration/constructor ordinals.
-- Relative slot rebasing and canonical source-name resolution are separate bridge obligations.
def psMinRegDataName (index : Nat) : PsName := PsName.num PsName.anonymous index

def psMinRegConstructorName (index ctorIndex : Nat) : PsName :=
  PsName.num (psMinRegDataName index) ctorIndex

def psMinRegRecursorName (index : Nat) : PsName :=
  PsName.str (psMinRegDataName index) "rec"
