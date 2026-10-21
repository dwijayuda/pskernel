import Lean

-- Independent native parser: split statements/operands, trim only the ends,
-- then use native decimal parsing. No PSC1 scanner or state-machine code.
def miniReferenceWhitespace (c : Char) : Bool :=
  c == ' ' || c == '\t' || c == '\r' || c == '\n'
def miniReferenceTrim (text : String) : String :=
  String.ofList (((text.toList.dropWhile miniReferenceWhitespace).reverse.dropWhile miniReferenceWhitespace).reverse)

def miniReference (source : String) : Except String String := do
  let mut count : Nat := 0
  let mut total : Nat := 0
  if miniReferenceTrim source != "" then
    match (source.splitOn ";").reverse with
    | [] => throw "expected semicolon"
    | last :: statements =>
      if miniReferenceTrim last != "" then throw "expected semicolon"
      for statement in statements.reverse do
        match (miniReferenceTrim statement).splitOn "+" with
        | [left,right] =>
            let some a := (miniReferenceTrim left).toNat? | throw "invalid left operand"
            let some b := (miniReferenceTrim right).toNat? | throw "invalid right operand"
            count := count + 1
            total := total + a + b
        | _ => throw "expected addition"
  pure (Lean.Json.mkObj [("statements",Lean.toJson count),("total",Lean.toJson total)]).compress

def main : IO Unit := do
  let input ← (← IO.getStdin).readToEnd
  match miniReference input with
  | .error error => throw (IO.userError error)
  | .ok output =>
      IO.println ("PSC1_PRACTICAL_APPLICATION_REFERENCE: " ++ (Lean.Json.mkObj [
        ("leanVersion",Lean.toJson Lean.versionString),("leanCommit",Lean.toJson Lean.githash),
        ("output",Lean.toJson output)]).compress)
