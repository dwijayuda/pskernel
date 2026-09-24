inductive PsName where
  | anonymous
  | str (prefix : PsName) (value : String)
  | num (prefix : PsName) (value : Nat)

def psNameDepth : PsName -> Nat
  | .anonymous => 0
  | .str prefix _ => psNameDepth prefix + 1
  | .num prefix _ => psNameDepth prefix + 1

def psNameEq : PsName -> PsName -> Bool
  | .anonymous, .anonymous => true
  | .str leftPrefix leftValue, .str rightPrefix rightValue =>
      psNameEq leftPrefix rightPrefix && leftValue == rightValue
  | .num leftPrefix leftValue, .num rightPrefix rightValue =>
      psNameEq leftPrefix rightPrefix && leftValue == rightValue
  | _, _ => false

def psNameAppendStr (prefix : PsName) (value : String) : PsName :=
  PsName.str prefix value

def psNameAppendNum (prefix : PsName) (value : Nat) : PsName :=
  PsName.num prefix value
