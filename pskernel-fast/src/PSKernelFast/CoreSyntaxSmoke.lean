import PSKernelFast.CoreSyntax

namespace PSKernelFast.Core

private def require (ok : Bool) (description : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError description

def coreSyntaxSmoke : IO Unit := do
  let u : KName := .str .anonymous "u"
  let v : KName := .str .anonymous "v"
  let n : KName := .str .anonymous "Example"
  let x : KName := .str .anonymous "x"
  let a : ULevel := .imax (.succ .zero) (.param u)
  let assignment : KName → Option Nat :=
    fun name => if name == u then some 3 else none

  require ((ULevel.groundEval assignment a) == some 3)
    "ground imax with positive codomain was incorrect"
  require ((ULevel.groundEval assignment
    (.imax (.succ (.succ .zero)) .zero)) == some 0)
    "ground imax into Prop must be zero"
  require ((ULevel.groundEval assignment (.param v)) == none)
    "unknown symbolic assignment did not decline"
  require ((ULevel.groundEval assignment (.mvar v)) == none)
    "metavariable ground evaluation was accepted"

  for left in [:20] do
    for right in [:20] do
      require (numericImax left right == Lean.Nat.imax left right)
        "ground imax differs from official Lean.Nat.imax"

  let goodPi : KExpr :=
    .forallE x (.sort .zero) (.sort (.param u)) .default
  require (goodPi.closedInput [u]) "closed dependent product was rejected"
  require (!(goodPi.closedInput [])) "unknown universe parameter was accepted"

  let goodLam : KExpr :=
    .lam x (.sort .zero) (.app (.bvar 0) (.lit (.nat 3))) .implicit
  require (goodLam.closedInput []) "scoped lambda was rejected"

  let goodLet : KExpr :=
    .letE x (.sort .zero) (.lit (.nat 7)) (.bvar 0) false
  require (goodLet.closedInput []) "let binder was rejected"
  let badLet : KExpr :=
    .letE x (.bvar 0) (.lit (.nat 7)) (.bvar 0) false
  require (!(badLet.closedInput []))
    "let type illegally referenced its own binder"

  let badPi : KExpr :=
    .forallE x (.sort .zero) (.bvar 1) .instImplicit
  require (!(badPi.closedInput [])) "escaped Pi bvar was accepted"
  require (!((.bvar 0 : KExpr).closedInput []))
    "escaped top-level bvar was accepted"
  require (!((.fvar x : KExpr).closedInput []))
    "free variable in closed declaration was accepted"
  require (!((.mvar x : KExpr).closedInput []))
    "metavariable in closed declaration was accepted"
  require (!((.sort (.mvar u) : KExpr).closedInput [u]))
    "universe metavariable was accepted"
  require (!((.const n [.param v] : KExpr).closedInput [u]))
    "undefined constant universe parameter was accepted"

  let projected : KExpr :=
    .proj n 0 (.mdata 42 (.const n [.param u]))
  require (projected.closedInput [u]) "projection/mdata structure was rejected"
  require ((.lit (.str "hello") : KExpr).closedInput [])
    "String literal structurally rejected"

  IO.println "PSKernel-Fast V3 G3: official-shape syntax and strict structural preflight PASS"
end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.coreSyntaxSmoke
