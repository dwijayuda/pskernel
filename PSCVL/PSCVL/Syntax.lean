import Lean

/-!
A *small, deliberately incomplete* ProofScript syntax bridge. The Lean parser
handles all source forms that are already Lean-compatible. These two aliases
are from the PSCV language reference §§8–9; broader ProofScript grammar is
not accepted or silently approximated.
-/

namespace PSCVL

syntax (name := pscvConst) "const " ident ":" term ":=" term : command

macro_rules
  | `(const $name:ident : $ty:term := $value:term) =>
    `(def $name : $ty := $value)

syntax (name := pscvFunction1) "function " ident "(" ident ":" term ")" ":" term ":=" term : command

macro_rules
  | `(function $name:ident ($x:ident : $a:term) : $b:term := $body:term) =>
    `(def $name ($x : $a) : $b := $body)

syntax (name := pscvFunction2) "function " ident "(" ident ":" term "," ident ":" term ")" ":" term ":=" term : command

macro_rules
  | `(function $name:ident ($x:ident : $a:term, $y:ident : $b:term) : $result:term := $body:term) =>
    `(def $name ($x : $a) ($y : $b) : $result := $body)

end PSCVL
