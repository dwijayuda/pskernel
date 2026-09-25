import Lean
import PSC1Kernel

namespace PSC1Kernel.Test

def toLeanName : PSC1Kernel.Name → Lean.Name
  | .anonymous => .anonymous
  | .str p s => .str (toLeanName p) s
  | .num p n => .num (toLeanName p) n

def toLeanLevel : PSC1Kernel.Level → Lean.Level
  | .zero => .zero
  | .succ l => .succ (toLeanLevel l)
  | .max a b => .max (toLeanLevel a) (toLeanLevel b)
  | .imax a b => .imax (toLeanLevel a) (toLeanLevel b)
  | .param n => .param (toLeanName n)
  | .mvar n => .mvar ⟨toLeanName n⟩

def toLeanBinderInfo : PSC1Kernel.BinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

def toLeanLiteral : PSC1Kernel.Literal → Lean.Literal
  | .nat n => .natVal n
  | .str s => .strVal s

partial def toLeanExpr : PSC1Kernel.Expr → Lean.Expr
  | .bvar i => .bvar i
  | .fvar n => .fvar ⟨toLeanName n⟩
  | .mvar n => .mvar ⟨toLeanName n⟩
  | .sort u => .sort (toLeanLevel u)
  | .const n us => .const (toLeanName n) (us.map toLeanLevel)
  | .app f a => .app (toLeanExpr f) (toLeanExpr a)
  | .lam n t b bi => .lam (toLeanName n) (toLeanExpr t) (toLeanExpr b) (toLeanBinderInfo bi)
  | .forallE n t b bi => .forallE (toLeanName n) (toLeanExpr t) (toLeanExpr b) (toLeanBinderInfo bi)
  | .letE n t v b nd => .letE (toLeanName n) (toLeanExpr t) (toLeanExpr v) (toLeanExpr b) nd
  | .lit l => .lit (toLeanLiteral l)
  | .mdata _ b => toLeanExpr b
  | .proj n i b => .proj (toLeanName n) i (toLeanExpr b)

def assertTrue (label : String) (value : Bool) : IO Unit :=
  if value then pure () else throw <| IO.userError ("FAIL: " ++ label)

def exceptToIO (label : String) : Except String α → IO α
  | .ok value => pure value
  | .error message => throw <| IO.userError (label ++ ": " ++ message)

def kernelExprWhnf
    (env : Lean.Environment) (e : PSC1Kernel.Expr) : IO Lean.Expr := do
  match Lean.Kernel.whnf env ({} : Lean.LocalContext) (toLeanExpr e) with
  | .ok value => pure value
  | .error _ => throw <| IO.userError "Lean kernel whnf failed"

def kernelExprDefEq
    (env : Lean.Environment) (a b : PSC1Kernel.Expr) : IO Bool := do
  match Lean.Kernel.isDefEq env ({} : Lean.LocalContext) (toLeanExpr a) (toLeanExpr b) with
  | .ok value => pure value
  | .error _ => throw <| IO.userError "Lean kernel expression isDefEq failed"

def kernelSortDefEq
    (env : Lean.Environment) (a b : PSC1Kernel.Level) : IO Bool := do
  match Lean.Kernel.isDefEq env ({} : Lean.LocalContext)
      (.sort (toLeanLevel a)) (.sort (toLeanLevel b)) with
  | .ok value => pure value
  | .error _ => throw <| IO.userError "Lean kernel isDefEq failed"

def assertLevelPairs (levels : List PSC1Kernel.Level) : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let mut i := 0
  for a in levels do
    let mut j := 0
    for b in levels do
      let actualEq := PSC1Kernel.Level.equivalent a b
      let kernelEq ← kernelSortDefEq env a b
      assertTrue
        ("level equivalence differs from Lean 4.34 C++ kernel at " ++
         toString i ++ "," ++ toString j ++
         " ours=" ++ toString actualEq ++ " kernel=" ++ toString kernelEq)
        (actualEq == kernelEq)
      j := j + 1
    i := i + 1


def mkBase (name : PSC1Kernel.Name) (type : PSC1Kernel.Expr) : PSC1Kernel.ConstantBase :=
  { name := name, levelParams := [], type := type }

def assertProjectionOracle : IO Unit := do
  let S : PSC1Kernel.Name := .str .anonymous "S"
  let Smk : PSC1Kernel.Name := .str S "mk"
  let T : PSC1Kernel.Name := .str .anonymous "T"
  let Tmk : PSC1Kernel.Name := .str T "mk"
  let NatN : PSC1Kernel.Name := .str .anonymous "Nat"
  let type0 : PSC1Kernel.Expr := .sort (.succ .zero)
  let natT : PSC1Kernel.Expr := .const NatN []
  let sT : PSC1Kernel.Expr := .const S []
  let tT : PSC1Kernel.Expr := .const T []
  let ctorSType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "a") natT
      (.forallE (.str .anonymous "b") natT sT .default)
      .default
  let ctorTType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "a") natT tT .default
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo { base := mkBase NatN type0, isUnsafe := false })
  let env2 := env1.addUnchecked (.inductInfo {
    base := mkBase S type0
    numParams := 0
    numIndices := 0
    all := [S]
    ctors := [Smk]
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  })
  let env3 := env2.addUnchecked (.ctorInfo {
    base := mkBase Smk ctorSType
    induct := S
    cidx := 0
    numParams := 0
    numFields := 2
    isUnsafe := false
  })
  let env4 := env3.addUnchecked (.inductInfo {
    base := mkBase T type0
    numParams := 0
    numIndices := 0
    all := [T]
    ctors := [Tmk]
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  })
  let env := env4.addUnchecked (.ctorInfo {
    base := mkBase Tmk ctorTType
    induct := T
    cidx := 0
    numParams := 0
    numFields := 1
    isUnsafe := false
  })
  let ctx := PSC1Kernel.CheckerContext.empty env
  let value : PSC1Kernel.Expr :=
    .app (.app (.const Smk []) (.lit (.nat 7))) (.lit (.nat 11))
  let p0 : PSC1Kernel.Expr := .proj S 0 value
  let p1 : PSC1Kernel.Expr := .proj S 1 value
  let badName : PSC1Kernel.Expr := .proj T 0 value
  let r0 ← exceptToIO "projection field 0 whnf" (PSC1Kernel.whnf ctx p0)
  let r1 ← exceptToIO "projection field 1 whnf" (PSC1Kernel.whnf ctx p1)
  assertTrue "projection field 0 did not reduce" (PSC1Kernel.Expr.eq r0 (.lit (.nat 7)))
  assertTrue "projection field 1 did not reduce" (PSC1Kernel.Expr.eq r1 (.lit (.nat 11)))
  match PSC1Kernel.infer ctx p0 with
  | .ok ty => assertTrue "projection field type mismatch" (PSC1Kernel.Expr.eq ty natT)
  | .error msg => throw <| IO.userError ("projection infer failed: " ++ msg)
  match PSC1Kernel.infer ctx badName with
  | .ok _ => throw <| IO.userError "projection with wrong structure name was accepted"
  | .error _ => pure ()
  let badReduce := PSC1Kernel.reduceProjCore ctx T 0 value
  assertTrue "reduceProjCore ignored structure name" badReduce.isNone

def natConst (field : String) : PSC1Kernel.Expr :=
  .const (.str (.str .anonymous "Nat") field) []

def natUnary (field : String) (a : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  .app (natConst field) a

def natBinary
    (field : String)
    (a b : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  .app (.app (natConst field) a) b

def assertNatReductionOracle : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let ctx := PSC1Kernel.CheckerContext.empty .empty
  let cases : List (String × PSC1Kernel.Expr) := [
    ("succ", natUnary "succ" (.lit (.nat 4))),
    ("add", natBinary "add" (.lit (.nat 7)) (.lit (.nat 11))),
    ("sub-saturating", natBinary "sub" (.lit (.nat 7)) (.lit (.nat 11))),
    ("mul", natBinary "mul" (.lit (.nat 7)) (.lit (.nat 11))),
    ("pow", natBinary "pow" (.lit (.nat 3)) (.lit (.nat 4))),
    ("gcd", natBinary "gcd" (.lit (.nat 84)) (.lit (.nat 30))),
    ("mod-zero", natBinary "mod" (.lit (.nat 11)) (.lit (.nat 0))),
    ("div-zero", natBinary "div" (.lit (.nat 11)) (.lit (.nat 0))),
    ("beq-true", natBinary "beq" (.lit (.nat 11)) (.lit (.nat 11))),
    ("ble-false", natBinary "ble" (.lit (.nat 12)) (.lit (.nat 11)))
  ]
  for item in cases do
    let label := item.1
    let input := item.2
    let ours ← exceptToIO ("PSC1 Nat whnf " ++ label) (PSC1Kernel.whnf ctx input)
    let lean ← kernelExprWhnf env input
    assertTrue
      ("Nat reduction differs from Lean 4.34: " ++ label)
      (toLeanExpr ours == lean)

def assertFunctionEtaOracle : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let x : PSC1Kernel.Name := .str .anonymous "x"
  let f : PSC1Kernel.Name := .str .anonymous "f"
  let prop : PSC1Kernel.Expr := .sort .zero
  let fnType : PSC1Kernel.Expr := .forallE x prop prop .default

  let pscLctx := PSC1Kernel.LocalContext.empty.addLocal f f fnType .default
  let ctx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty .empty) with lctx := pscLctx }
  let eta : PSC1Kernel.Expr :=
    .lam x prop (.app (.fvar f) (.bvar 0)) .default
  let ours ← exceptToIO "PSC1 eta defeq" (PSC1Kernel.isDefEq ctx eta (.fvar f))

  let fId : Lean.FVarId := ⟨toLeanName f⟩
  let leanFnType := toLeanExpr fnType
  let leanLctx : Lean.LocalContext :=
    ({} : Lean.LocalContext).mkLocalDecl fId (toLeanName f) leanFnType .default
  let lean ←
    match Lean.Kernel.isDefEq env leanLctx (toLeanExpr eta) (.fvar fId) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean kernel eta oracle failed"

  assertTrue "function eta differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should accept function eta" lean

def assertProofIrrelevanceOracle : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let P : PSC1Kernel.Name := .str .anonymous "P"
  let h₁ : PSC1Kernel.Name := .str .anonymous "h1"
  let h₂ : PSC1Kernel.Name := .str .anonymous "h2"

  let lctx0 : PSC1Kernel.LocalContext := .empty
  let lctx1 := lctx0.addLocal P P (.sort .zero) .default
  let lctx2 := lctx1.addLocal h₁ h₁ (.fvar P) .default
  let lctx3 := lctx2.addLocal h₂ h₂ (.fvar P) .default
  let ctx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty .empty) with lctx := lctx3 }

  let ours ← exceptToIO
    "PSC1 proof irrelevance"
    (PSC1Kernel.isDefEq ctx (.fvar h₁) (.fvar h₂))

  let pId : Lean.FVarId := ⟨toLeanName P⟩
  let h1Id : Lean.FVarId := ⟨toLeanName h₁⟩
  let h2Id : Lean.FVarId := ⟨toLeanName h₂⟩
  let leanLctx0 : Lean.LocalContext := {}
  let leanLctx1 := leanLctx0.mkLocalDecl pId (toLeanName P) (.sort .zero) .default
  let leanLctx2 := leanLctx1.mkLocalDecl h1Id (toLeanName h₁) (.fvar pId) .default
  let leanLctx3 := leanLctx2.mkLocalDecl h2Id (toLeanName h₂) (.fvar pId) .default
  let lean ←
    match Lean.Kernel.isDefEq env leanLctx3 (.fvar h1Id) (.fvar h2Id) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean kernel proof-irrelevance oracle failed"

  assertTrue "proof irrelevance differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should identify proofs of the same proposition" lean

def assertBinderInfoDefEqOracle : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let x : PSC1Kernel.Name := .str .anonymous "x"
  let p : PSC1Kernel.Expr := .sort .zero
  let lamDefault : PSC1Kernel.Expr := .lam x p (.bvar 0) .default
  let lamImplicit : PSC1Kernel.Expr := .lam x p (.bvar 0) .implicit
  let piDefault : PSC1Kernel.Expr := .forallE x p p .default
  let piImplicit : PSC1Kernel.Expr := .forallE x p p .implicit
  let ctx := PSC1Kernel.CheckerContext.empty .empty
  let oursLam ← exceptToIO "PSC1 lambda defeq" (PSC1Kernel.isDefEq ctx lamDefault lamImplicit)
  let leanLam ← kernelExprDefEq env lamDefault lamImplicit
  assertTrue "lambda binder info differs from Lean 4.34 defeq" (oursLam == leanLam)
  assertTrue "Lean 4.34 lambda binder info should be ignored by defeq" leanLam
  let oursPi ← exceptToIO "PSC1 forall defeq" (PSC1Kernel.isDefEq ctx piDefault piImplicit)
  let leanPi ← kernelExprDefEq env piDefault piImplicit
  assertTrue "forall binder info differs from Lean 4.34 defeq" (oursPi == leanPi)
  assertTrue "Lean 4.34 forall binder info should be ignored by defeq" leanPi

def assertExprOracle : IO Unit := do
  let x : PSC1Kernel.Name := .str .anonymous "x"
  let A : PSC1Kernel.Name := .str .anonymous "A"
  let type0 : PSC1Kernel.Expr := .sort .zero
  let cA : PSC1Kernel.Expr := .const A []
  let e : PSC1Kernel.Expr :=
    .app
      (.bvar 1)
      (.lam x type0 (.app (.bvar 1) (.bvar 0)) .default)
  let subst : List PSC1Kernel.Expr := [cA, .lit (.nat 7)]
  let ours := e.instantiate subst
  let lean := (toLeanExpr e).instantiate (subst.map toLeanExpr).toArray
  assertTrue "Expr.instantiate differs from Lean 4.34" (toLeanExpr ours == lean)

  let liftedOurs := e.liftLooseBVars 0 3
  let liftedLean := (toLeanExpr e).liftLooseBVars 0 3
  assertTrue "Expr.liftLooseBVars differs from Lean 4.34" (toLeanExpr liftedOurs == liftedLean)

  let nested : PSC1Kernel.Expr :=
    .forallE x type0
      (.letE x type0 (.bvar 0) (.app (.bvar 2) (.bvar 0)) false)
      .default
  let replacement : PSC1Kernel.Expr := .lit (.nat 11)
  let nestedOurs := nested.instantiate [replacement]
  let nestedLean := (toLeanExpr nested).instantiate #[toLeanExpr replacement]
  assertTrue "nested instantiate differs from Lean 4.34" (toLeanExpr nestedOurs == nestedLean)

def run : IO Unit := do
  let u : PSC1Kernel.Name := .str .anonymous "u"
  let v : PSC1Kernel.Name := .str .anonymous "v"
  let U : PSC1Kernel.Level := .param u
  let V : PSC1Kernel.Level := .param v
  let levels : List PSC1Kernel.Level := [
    .zero,
    .succ .zero,
    U,
    V,
    .succ U,
    .max U V,
    .max (.succ U) V,
    .imax U V,
    .imax (.succ .zero) U,
    .max U (.imax U V),
    .max (.imax U V) U,
    .imax (.max U V) (.succ U)
  ]
  assertLevelPairs levels
  assertExprOracle
  assertNatReductionOracle
  assertFunctionEtaOracle
  assertProofIrrelevanceOracle
  assertBinderInfoDefEqOracle
  assertProjectionOracle
  IO.println "PSC1Kernel Lean 4.34 foundational + projection oracle: PASS"

end PSC1Kernel.Test

def main : IO Unit := PSC1Kernel.Test.run
