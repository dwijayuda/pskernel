import Lean
import ProofScript.Kernel.PSC1.Instantiate

namespace ProofScript.Kernel.PSC1.Test

abbrev KName := ProofScript.Kernel.PSC1.Name
abbrev KLevel := ProofScript.Kernel.PSC1.Level
abbrev KExpr := ProofScript.Kernel.PSC1.Expr
abbrev KBinderInfo := ProofScript.Kernel.PSC1.BinderInfo
abbrev KLiteral := ProofScript.Kernel.PSC1.Literal

def toLeanName : KName → Lean.Name
  | .anonymous => .anonymous
  | .str p s => .str (toLeanName p) s
  | .num p n => .num (toLeanName p) n

def toLeanLevel : KLevel → Lean.Level
  | .zero => .zero
  | .succ u => .succ (toLeanLevel u)
  | .max u v => .max (toLeanLevel u) (toLeanLevel v)
  | .imax u v => .imax (toLeanLevel u) (toLeanLevel v)
  | .param n => .param (toLeanName n)
  | .mvar n => .mvar ⟨toLeanName n⟩

def toLeanBinderInfo : KBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

def toLeanLiteral : KLiteral → Lean.Literal
  | .natVal n => .natVal n
  | .strVal s => .strVal s

def toLeanExpr : KExpr → Lean.Expr
  | .bvar i => .bvar i
  | .fvar n => .fvar ⟨toLeanName n⟩
  | .mvar n => .mvar ⟨toLeanName n⟩
  | .sort u => .sort (toLeanLevel u)
  | .const n us => .const (toLeanName n) (us.map toLeanLevel)
  | .app f a => .app (toLeanExpr f) (toLeanExpr a)
  | .lam n type body bi =>
      .lam (toLeanName n) (toLeanExpr type) (toLeanExpr body) (toLeanBinderInfo bi)
  | .forallE n type body bi =>
      .forallE (toLeanName n) (toLeanExpr type) (toLeanExpr body) (toLeanBinderInfo bi)
  | .letE n type value body nondep =>
      .letE (toLeanName n) (toLeanExpr type) (toLeanExpr value) (toLeanExpr body) nondep
  | .lit l => .lit (toLeanLiteral l)
  | .proj n i e => .proj (toLeanName n) i (toLeanExpr e)

def assertTrue (label : String) (value : Bool) : IO Unit := do
  if value then
    pure ()
  else
    throw <| IO.userError ("PSC1 Lean kernel parity failure: " ++ label)

def n (s : String) : KName := .str .anonymous s

def levelSamples : List KLevel :=
  [
    .zero,
    .succ .zero,
    .succ (.succ .zero),
    .param (n "u"),
    .max (.param (n "u")) .zero,
    .imax (.param (n "u")) .zero,
    .imax (.succ .zero) (.param (n "v")),
    .max (.succ (.param (n "u"))) (.succ .zero)
  ]

def checkLevelSample (u : KLevel) : IO Unit := do
  let lu := toLeanLevel u
  assertTrue "Level.depth" (ProofScript.Kernel.PSC1.Level.depth u == Lean.Level.depth lu)
  assertTrue "Level.isExplicit" (ProofScript.Kernel.PSC1.Level.isExplicit u == Lean.Level.isExplicit lu)
  assertTrue "Level.isNotZero" (ProofScript.Kernel.PSC1.Level.isNotZero u == Lean.Level.isNeverZero lu)
  assertTrue "Level.normalizesToZero"
    (ProofScript.Kernel.PSC1.Level.normalizesToZero u == Lean.Level.isAlwaysZero lu)
  assertTrue "Level.normalize"
    (toLeanLevel (ProofScript.Kernel.PSC1.Level.normalize u) == Lean.Level.normalize lu)

def sampleExpr : KExpr :=
  .lam (n "x") (.sort .zero)
    (.app (.bvar 1) (.bvar 0))
    .default

def sampleLet : KExpr :=
  .letE (n "x") (.sort .zero) (.bvar 0)
    (.app (.bvar 1) (.bvar 0))
    false

def sameLeanExpr (a b : Lean.Expr) : Bool :=
  Lean.Expr.equal a b

def checkExprParity (e : KExpr) : IO Unit := do
  let le := toLeanExpr e
  let liftedK := ProofScript.Kernel.PSC1.Expr.liftLooseBVars e 0 2
  let liftedLean := Lean.Expr.liftLooseBVars le 0 2
  assertTrue "Expr.liftLooseBVars"
    (sameLeanExpr (toLeanExpr liftedK) liftedLean)


  let loweredK := ProofScript.Kernel.PSC1.Expr.lowerLooseBVars
    (ProofScript.Kernel.PSC1.Expr.liftLooseBVars e 0 2) 2 2
  let loweredLean := Lean.Expr.lowerLooseBVars
    (Lean.Expr.liftLooseBVars le 0 2) 2 2
  assertTrue "Expr.lowerLooseBVars"
    (sameLeanExpr (toLeanExpr loweredK) loweredLean)

  assertTrue "Expr.hasLooseBVar 0"
    (ProofScript.Kernel.PSC1.Expr.hasLooseBVar e 0 ==
      Lean.Expr.hasLooseBVar le 0)
  assertTrue "Expr.hasLooseBVar 1"
    (ProofScript.Kernel.PSC1.Expr.hasLooseBVar e 1 ==
      Lean.Expr.hasLooseBVar le 1)

  let substK : List KExpr := [.bvar 0, .const (n "C") []]
  let substLean := (substK.map toLeanExpr).toArray
  let instantiatedK := ProofScript.Kernel.PSC1.Expr.instantiate e substK
  let instantiatedLean := Lean.Expr.instantiate le substLean
  assertTrue "Expr.instantiate"
    (sameLeanExpr (toLeanExpr instantiatedK) instantiatedLean)

  let instantiatedRevK := ProofScript.Kernel.PSC1.Expr.instantiateRev e substK
  let instantiatedRevLean := Lean.Expr.instantiateRev le substLean
  assertTrue "Expr.instantiateRev"
    (sameLeanExpr (toLeanExpr instantiatedRevK) instantiatedRevLean)

def run : IO Unit := do
  for u in levelSamples do
    checkLevelSample u

  assertTrue "mkMax explicit"
    (ProofScript.Kernel.PSC1.Level.beq (ProofScript.Kernel.PSC1.Level.mkMax (.succ .zero) (.succ (.succ .zero)))
      (.succ (.succ .zero)))
  assertTrue "mkMax zero"
    (ProofScript.Kernel.PSC1.Level.beq (ProofScript.Kernel.PSC1.Level.mkMax .zero (.param (n "u"))) (.param (n "u")))
  assertTrue "mkIMax rhs zero"
    (ProofScript.Kernel.PSC1.Level.beq (ProofScript.Kernel.PSC1.Level.mkIMax (.param (n "u")) .zero) .zero)
  assertTrue "mkIMax lhs one"
    (ProofScript.Kernel.PSC1.Level.beq
      (ProofScript.Kernel.PSC1.Level.mkIMax (.succ .zero) (.param (n "u")))
      (.param (n "u")))

  let u : KLevel := .param (n "u")
  let v : KLevel := .param (n "v")
  let levelPairs : List (KLevel × KLevel) := [
    (.zero, .zero),
    (.succ .zero, .zero),
    (.max u v, .max v u),
    (.imax u v, .imax u v),
    (.max v u, .max (.imax u v) u),
    (.succ (.max u v), .max (.succ u) (.succ v)),
    (.imax u (.succ v), .max u (.succ v))
  ]
  for p in levelPairs do
    let a := p.1
    let b := p.2
    let la := toLeanLevel a
    let lb := toLeanLevel b
    assertTrue "Level.isEquivalent"
      (ProofScript.Kernel.PSC1.Level.isEquivalent a b == Lean.Level.isEquiv la lb)
    assertTrue "Level.geq"
      (ProofScript.Kernel.PSC1.Level.geq a b == Lean.Level.geq la lb)
    assertTrue "Level.geq reverse"
      (ProofScript.Kernel.PSC1.Level.geq b a == Lean.Level.geq lb la)

  checkExprParity sampleExpr
  checkExprParity sampleLet

  let binderA : KExpr :=
    .lam (n "x") (.sort .zero) (.bvar 0) .default
  let binderB : KExpr :=
    .lam (n "different") (.sort .zero) (.bvar 0) .implicit
  assertTrue "Expr.eqv ignores binder metadata"
    (ProofScript.Kernel.PSC1.Expr.eqv binderA binderB ==
      Lean.Expr.eqv (toLeanExpr binderA) (toLeanExpr binderB))
  assertTrue "Expr.equal compares binder metadata"
    (ProofScript.Kernel.PSC1.Expr.equal binderA binderB ==
      Lean.Expr.equal (toLeanExpr binderA) (toLeanExpr binderB))

  let fv := n "free"
  let abstractedK := ProofScript.Kernel.PSC1.Expr.abstractFVar (.app (.fvar fv) (.bvar 0)) fv
  let leanSource := Lean.Expr.app (.fvar ⟨toLeanName fv⟩) (.bvar 0)
  let leanAbstracted := Lean.Expr.abstract leanSource #[.fvar ⟨toLeanName fv⟩]
  assertTrue "Expr.abstractFVar"
    (sameLeanExpr (toLeanExpr abstractedK) leanAbstracted)

  IO.println "ok - PSC1 Lean kernel K0/K1 universe+expr parity"

end ProofScript.Kernel.PSC1.Test

def main : IO Unit :=
  ProofScript.Kernel.PSC1.Test.run
