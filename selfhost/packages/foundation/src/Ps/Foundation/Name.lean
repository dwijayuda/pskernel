inductive PsName where
  | anonymous
  | str (prefix : PsName) (value : String)
  | num (prefix : PsName) (value : Nat)

def psNameDepth : PsName -> Nat
  | .anonymous => 0
  | .str prefix _ => psNameDepth prefix + 1
  | .num prefix _ => psNameDepth prefix + 1

def psNameAppendStr (prefix : PsName) (value : String) : PsName :=
  PsName.str prefix value

def psNameAppendNum (prefix : PsName) (value : Nat) : PsName :=
  PsName.num prefix value
