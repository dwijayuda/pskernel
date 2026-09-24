inductive PsName where
  | anonymous
  | str (parent : PsName) (value : String)
  | num (parent : PsName) (value : Nat)

def psNameDepth : PsName -> Nat
  | .anonymous => 0
  | .str parent _ => psNameDepth parent + 1
  | .num parent _ => psNameDepth parent + 1

def psNameEq : PsName -> PsName -> Bool
  | .anonymous, .anonymous => true
  | .str leftPrefix leftValue, .str rightPrefix rightValue =>
      psNameEq leftPrefix rightPrefix && leftValue == rightValue
  | .num leftPrefix leftValue, .num rightPrefix rightValue =>
      psNameEq leftPrefix rightPrefix && leftValue == rightValue
  | _, _ => false

def psNameAppendStr (parent : PsName) (value : String) : PsName :=
  PsName.str parent value

def psNameAppendNum (parent : PsName) (value : Nat) : PsName :=
  PsName.num parent value

def psNameToString : PsName -> String
  | .anonymous => ""
  | .str parent value =>
      let prefixText := psNameToString parent
      if prefixText.isEmpty then
        value
      else
        prefixText ++ "." ++ value
  | .num parent value =>
      let prefixText := psNameToString parent
      let suffix := toString value
      if prefixText.isEmpty then
        suffix
      else
        prefixText ++ "." ++ suffix

def psNameLastComponent : PsName -> String
  | .anonymous => ""
  | .str _ value => value
  | .num _ value => toString value
