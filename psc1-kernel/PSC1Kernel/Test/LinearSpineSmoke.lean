import PSC1Kernel

open PSC1Kernel

def expect (condition : Bool) (message : String) : IO Unit := do
  unless condition do
    throw <| IO.userError message

def deepApp (count : Nat) : Expr :=
  let rec go : Nat → Expr → Expr
    | 0, acc => acc
    | n + 1, acc => go n (.app acc (.lit (.nat n)))
  go count (.const (.str .anonymous "f") [])

def main : IO Unit := do
  let a : Expr := .lit (.nat 10)
  let b : Expr := .lit (.nat 20)
  let reversed := Expr.reverseList [a, b]
  expect (reversed.length == 2) "reverseList changed length"
  match reversed with
  | [first, second] => do
      expect (Expr.eq first b) "reverseList first element mismatch"
      expect (Expr.eq second a) "reverseList second element mismatch"
  | _ => throw <| IO.userError "reverseList unexpected shape"

  let instantiated :=
    (.app (.bvar 1) (.bvar 0) : Expr).instantiateRev [a, b]
  expect (Expr.eq instantiated (.app a b))
    "instantiateRev observable ordering changed"

  let application := deepApp 4096
  expect (application.getAppNumArgs == 4096)
    "getAppNumArgs changed application-spine count"
  IO.println "PSC1 linear spine smoke PASS"
