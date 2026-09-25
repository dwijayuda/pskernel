import Lean
import PSC1Kernel
import PSC1Kernel.Test.StructureFixture

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

def assertWhnfLayering : IO Unit := do
  let D : PSC1Kernel.Name := .str .anonymous "D"
  let NatN : PSC1Kernel.Name := .str .anonymous "Nat"
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo {
    base := mkBase NatN type1
    isUnsafe := false
  })
  let env := env1.addUnchecked (.defnInfo {
    base := mkBase D natT
    value := .lit (.nat 23)
    hints := .regular 0
    safety := .safe
  })
  let ctx := PSC1Kernel.CheckerContext.empty env
  let d : PSC1Kernel.Expr := .const D []
  let core ← exceptToIO "whnfCore delta boundary" (PSC1Kernel.whnfCore ctx d false)
  let full ← exceptToIO "whnf delta boundary" (PSC1Kernel.whnf ctx d)
  assertTrue "whnfCore performed forbidden delta reduction" (PSC1Kernel.Expr.eq core d)
  assertTrue "full whnf failed to delta reduce" (PSC1Kernel.Expr.eq full (.lit (.nat 23)))

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

def makeStructureEnvironment : PSC1Kernel.Environment :=
  let pair : PSC1Kernel.Name := .str (.str (.str .anonymous "PSC1Kernel") "Test") "EtaPair"
  let pairMk : PSC1Kernel.Name := .str pair "mk"
  let unit : PSC1Kernel.Name := .str (.str (.str .anonymous "PSC1Kernel") "Test") "EtaUnit"
  let unitMk : PSC1Kernel.Name := .str unit "mk"
  let nat : PSC1Kernel.Name := .str .anonymous "Nat"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let natT : PSC1Kernel.Expr := .const nat []
  let pairT : PSC1Kernel.Expr := .const pair []
  let unitT : PSC1Kernel.Expr := .const unit []
  let pairCtorT : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "left") natT
      (.forallE (.str .anonymous "right") natT pairT .default)
      .default
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo { base := mkBase nat type1, isUnsafe := false })
  let env2 := env1.addUnchecked (.inductInfo {
    base := mkBase pair type1
    numParams := 0
    numIndices := 0
    all := [pair]
    ctors := [pairMk]
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  })
  let env3 := env2.addUnchecked (.ctorInfo {
    base := mkBase pairMk pairCtorT
    induct := pair
    cidx := 0
    numParams := 0
    numFields := 2
    isUnsafe := false
  })
  let env4 := env3.addUnchecked (.inductInfo {
    base := mkBase unit type1
    numParams := 0
    numIndices := 0
    all := [unit]
    ctors := [unitMk]
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  })
  env4.addUnchecked (.ctorInfo {
    base := mkBase unitMk unitT
    induct := unit
    cidx := 0
    numParams := 0
    numFields := 0
    isUnsafe := false
  })

def importStructureFixture : IO Lean.Environment := do
  Lean.initSearchPath (← Lean.findSysroot)
  Lean.importModules #[{ module := `PSC1Kernel.Test.StructureFixture }] {}

def makeDeltaEnvironment : PSC1Kernel.Environment :=
  let nat : PSC1Kernel.Name := .str .anonymous "Nat"
  let deltaA : PSC1Kernel.Name :=
    .str (.str (.str .anonymous "PSC1Kernel") "Test") "DeltaA"
  let deltaB : PSC1Kernel.Name :=
    .str (.str (.str .anonymous "PSC1Kernel") "Test") "DeltaB"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let natT : PSC1Kernel.Expr := .const nat []
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo {
    base := mkBase nat type1
    isUnsafe := false
  })
  let env2 := env1.addUnchecked (.defnInfo {
    base := mkBase deltaA natT
    value := .lit (.nat 7)
    hints := .regular 0
    safety := .safe
  })
  env2.addUnchecked (.defnInfo {
    base := mkBase deltaB natT
    value := .const deltaA []
    hints := .abbrevHint
    safety := .safe
  })

def assertLazyDeltaOracle : IO Unit := do
  let deltaB : PSC1Kernel.Name :=
    .str (.str (.str .anonymous "PSC1Kernel") "Test") "DeltaB"
  let expr : PSC1Kernel.Expr := .const deltaB []
  let ctx := PSC1Kernel.CheckerContext.empty makeDeltaEnvironment
  let ours ← exceptToIO
    "PSC1 lazy delta"
    (PSC1Kernel.isDefEq ctx expr (.lit (.nat 7)))

  let leanEnv ← importStructureFixture
  let lean ←
    match Lean.Kernel.isDefEq leanEnv ({} : Lean.LocalContext)
      (toLeanExpr expr) (.lit (.natVal 7)) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean kernel lazy-delta oracle failed"
  assertTrue "lazy delta differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should unfold the abbreviation/definition chain" lean

def assertStructureEtaOracle : IO Unit := do
  let env := makeStructureEnvironment
  let pair : PSC1Kernel.Name := .str (.str (.str .anonymous "PSC1Kernel") "Test") "EtaPair"
  let pairMk : PSC1Kernel.Name := .str pair "mk"
  let x : PSC1Kernel.Name := .str .anonymous "x"
  let pairT : PSC1Kernel.Expr := .const pair []
  let pscLctx := PSC1Kernel.LocalContext.empty.addLocal x x pairT .default
  let ctx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty env) with lctx := pscLctx }
  let xExpr : PSC1Kernel.Expr := .fvar x
  let expanded : PSC1Kernel.Expr :=
    .app
      (.app (.const pairMk []) (.proj pair 0 xExpr))
      (.proj pair 1 xExpr)
  let ours ← exceptToIO "PSC1 structure eta" (PSC1Kernel.isDefEq ctx xExpr expanded)

  let leanEnv ← importStructureFixture
  let xId : Lean.FVarId := ⟨toLeanName x⟩
  let leanPairT := toLeanExpr pairT
  let leanLctx : Lean.LocalContext :=
    ({} : Lean.LocalContext).mkLocalDecl xId (toLeanName x) leanPairT .default
  let lean ←
    match Lean.Kernel.isDefEq leanEnv leanLctx (.fvar xId) (toLeanExpr expanded) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean kernel structure eta oracle failed"
  assertTrue "structure eta differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should accept structure eta" lean

def assertUnitLikeOracle : IO Unit := do
  let env := makeStructureEnvironment
  let unit : PSC1Kernel.Name := .str (.str (.str .anonymous "PSC1Kernel") "Test") "EtaUnit"
  let a : PSC1Kernel.Name := .str .anonymous "a"
  let b : PSC1Kernel.Name := .str .anonymous "b"
  let unitT : PSC1Kernel.Expr := .const unit []
  let pscLctx0 := PSC1Kernel.LocalContext.empty.addLocal a a unitT .default
  let pscLctx := pscLctx0.addLocal b b unitT .default
  let ctx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty env) with lctx := pscLctx }
  let ours ← exceptToIO
    "PSC1 unit-like defeq"
    (PSC1Kernel.isDefEq ctx (.fvar a) (.fvar b))

  let leanEnv ← importStructureFixture
  let aId : Lean.FVarId := ⟨toLeanName a⟩
  let bId : Lean.FVarId := ⟨toLeanName b⟩
  let leanUnitT := toLeanExpr unitT
  let leanLctx0 : Lean.LocalContext :=
    ({} : Lean.LocalContext).mkLocalDecl aId (toLeanName a) leanUnitT .default
  let leanLctx :=
    leanLctx0.mkLocalDecl bId (toLeanName b) leanUnitT .default
  let lean ←
    match Lean.Kernel.isDefEq leanEnv leanLctx (.fvar aId) (.fvar bId) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean kernel unit-like oracle failed"
  assertTrue "unit-like defeq differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should identify inhabitants of a nullary structure" lean

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




def assertOrdinaryRecursorOracle : IO Unit := do
  let Flag : PSC1Kernel.Name := .str .anonymous "OracleFlag"
  let Off : PSC1Kernel.Name := .str Flag "off"
  let On : PSC1Kernel.Name := .str Flag "on"
  let Rec : PSC1Kernel.Name := .str Flag "rec"
  let u : PSC1Kernel.Name := .str .anonymous "u"
  let flagType : PSC1Kernel.Expr := .sort (.succ .zero)
  let flagExpr : PSC1Kernel.Expr := .const Flag []

  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.inductInfo {
    base := mkBase Flag flagType
    numParams := 0
    numIndices := 0
    all := [Flag]
    ctors := [Off, On]
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  })
  let env2 := env1.addUnchecked (.ctorInfo {
    base := mkBase Off flagExpr
    induct := Flag
    cidx := 0
    numParams := 0
    numFields := 0
    isUnsafe := false
  })
  let env3 := env2.addUnchecked (.ctorInfo {
    base := mkBase On flagExpr
    induct := Flag
    cidx := 1
    numParams := 0
    numFields := 0
    isUnsafe := false
  })
  let dummy : PSC1Kernel.Expr := .sort .zero
  let motiveName : PSC1Kernel.Name := .str .anonymous "motive"
  let offMinorName : PSC1Kernel.Name := .str .anonymous "offMinor"
  let onMinorName : PSC1Kernel.Name := .str .anonymous "onMinor"
  let rhsOff : PSC1Kernel.Expr :=
    .lam motiveName dummy
      (.lam offMinorName dummy
        (.lam onMinorName dummy (.bvar 1) .default)
        .default)
      .default
  let rhsOn : PSC1Kernel.Expr :=
    .lam motiveName dummy
      (.lam offMinorName dummy
        (.lam onMinorName dummy (.bvar 0) .default)
        .default)
      .default
  let env := env3.addUnchecked (.recInfo {
    base := { name := Rec, levelParams := [u], type := dummy }
    all := [Flag]
    numParams := 0
    numIndices := 0
    numMotives := 1
    numMinors := 2
    rules := [
      { ctor := Off, nFields := 0, rhs := rhsOff },
      { ctor := On, nFields := 0, rhs := rhsOn }
    ]
    k := false
    isUnsafe := false
  })
  let ctx := PSC1Kernel.CheckerContext.empty env
  let motive : PSC1Kernel.Expr := .lam motiveName flagExpr dummy .default
  let offMinor : PSC1Kernel.Expr := .lit (.nat 17)
  let onMinor : PSC1Kernel.Expr := .lit (.nat 29)
  let offApp :=
    PSC1Kernel.applyArgs (.const Rec [.zero])
      [motive, offMinor, onMinor, .const Off []]
  let onApp :=
    PSC1Kernel.applyArgs (.const Rec [.zero])
      [motive, offMinor, onMinor, .const On []]

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let lean1 ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.inductDecl [] 0 [{
      name := toLeanName Flag
      type := toLeanExpr flagType
      ctors := [
        { name := toLeanName Off, type := toLeanExpr flagExpr },
        { name := toLeanName On, type := toLeanExpr flagExpr }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean 4.34 rejected recursor oracle inductive"
  let leanEnv := Lean.Environment.ofKernelEnv lean1

  let oursOff ← exceptToIO "PSC1 ordinary recursor off" (PSC1Kernel.whnf ctx offApp)
  let leanOff ← kernelExprWhnf leanEnv offApp
  assertTrue "ordinary recursor off reduction differs from Lean 4.34"
    (toLeanExpr oursOff == leanOff)
  assertTrue "ordinary recursor off chose wrong minor"
    (PSC1Kernel.Expr.eq oursOff offMinor)

  let oursOn ← exceptToIO "PSC1 ordinary recursor on" (PSC1Kernel.whnf ctx onApp)
  let leanOn ← kernelExprWhnf leanEnv onApp
  assertTrue "ordinary recursor on reduction differs from Lean 4.34"
    (toLeanExpr oursOn == leanOn)
  assertTrue "ordinary recursor on chose wrong minor"
    (PSC1Kernel.Expr.eq oursOn onMinor)

def assertQuotReductionOracle : IO Unit := do
  let leanEnv ← importStructureFixture
  let ctx := PSC1Kernel.CheckerContext.empty PSC1Kernel.Environment.empty.markQuotInitialized
  let x : PSC1Kernel.Name := .str .anonymous "quot_x"
  let dummy : PSC1Kernel.Expr := .sort .zero
  let representative : PSC1Kernel.Expr := .lit (.nat 37)
  let fn : PSC1Kernel.Expr := .lam x dummy (.bvar 0) .default
  let quotMk : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs
      (.const PSC1Kernel.kernelQuotMkName [])
      [dummy, dummy, representative]
  let liftExpr : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs
      (.const PSC1Kernel.kernelQuotLiftName [])
      [dummy, dummy, dummy, fn, dummy, quotMk]
  let indExpr : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs
      (.const PSC1Kernel.kernelQuotIndName [])
      [dummy, dummy, dummy, fn, quotMk]

  let oursLift ← exceptToIO "PSC1 Quot.lift reduction" (PSC1Kernel.whnf ctx liftExpr)
  let leanLift ← kernelExprWhnf leanEnv liftExpr
  assertTrue "Quot.lift reduction differs from Lean 4.34"
    (toLeanExpr oursLift == leanLift)
  assertTrue "Quot.lift did not expose representative"
    (PSC1Kernel.Expr.eq oursLift representative)

  let oursInd ← exceptToIO "PSC1 Quot.ind reduction" (PSC1Kernel.whnf ctx indExpr)
  let leanInd ← kernelExprWhnf leanEnv indExpr
  assertTrue "Quot.ind reduction differs from Lean 4.34"
    (toLeanExpr oursInd == leanInd)
  assertTrue "Quot.ind did not expose representative"
    (PSC1Kernel.Expr.eq oursInd representative)

def assertDeclarationAdmissionOracle : IO Unit := do
  let P : PSC1Kernel.Name := .str .anonymous "AdmissionP"
  let h : PSC1Kernel.Name := .str .anonymous "admissionProof"
  let th : PSC1Kernel.Name := .str .anonymous "admissionTheorem"
  let op : PSC1Kernel.Name := .str .anonymous "admissionOpaque"
  let ident : PSC1Kernel.Name := .str .anonymous "admissionId"
  let bad : PSC1Kernel.Name := .str .anonymous "admissionBad"
  let badU : PSC1Kernel.Name := .str .anonymous "admissionBadUniverse"
  let u : PSC1Kernel.Name := .str .anonymous "u"
  let propSort : PSC1Kernel.Expr := .sort .zero
  let pExpr : PSC1Kernel.Expr := .const P []
  let hExpr : PSC1Kernel.Expr := .const h []

  let pBase : PSC1Kernel.ConstantBase :=
    { name := P, levelParams := [], type := propSort }
  let pAxiom : PSC1Kernel.AxiomInfo :=
    { base := pBase, isUnsafe := false }

  let ours0 : PSC1Kernel.Environment := .empty
  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let ours1 ← exceptToIO "PSC1 add axiom" (PSC1Kernel.Kernel.addAxiom ours0 pAxiom)
  let lean1 ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName P
      levelParams := []
      type := toLeanExpr propSort
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean 4.34 rejected admission axiom"

  let hBase : PSC1Kernel.ConstantBase :=
    { name := h, levelParams := [], type := pExpr }
  let hAxiom : PSC1Kernel.AxiomInfo :=
    { base := hBase, isUnsafe := false }
  let ours2 ← exceptToIO "PSC1 add proof axiom" (PSC1Kernel.Kernel.addAxiom ours1 hAxiom)
  let lean2 ←
    match Lean.Kernel.Environment.addDecl lean1 {} (.axiomDecl {
      name := toLeanName h
      levelParams := []
      type := toLeanExpr pExpr
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean 4.34 rejected proof axiom"

  let theoremValue : PSC1Kernel.TheoremInfo := {
    base := { name := th, levelParams := [], type := pExpr }
    value := hExpr
  }
  let ours3 ← exceptToIO "PSC1 add theorem" (PSC1Kernel.Kernel.addTheorem ours2 theoremValue)
  let lean3 ←
    match Lean.Kernel.Environment.addDecl lean2 {} (.thmDecl {
      name := toLeanName th
      levelParams := []
      type := toLeanExpr pExpr
      value := toLeanExpr hExpr
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean 4.34 rejected theorem"

  let opaqueValue : PSC1Kernel.OpaqueInfo := {
    base := { name := op, levelParams := [], type := pExpr }
    value := hExpr
    isUnsafe := false
  }
  let ours4 ← exceptToIO "PSC1 add opaque" (PSC1Kernel.Kernel.addOpaque ours3 opaqueValue)
  let lean4 ←
    match Lean.Kernel.Environment.addDecl lean3 {} (.opaqueDecl {
      name := toLeanName op
      levelParams := []
      type := toLeanExpr pExpr
      value := toLeanExpr hExpr
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean 4.34 rejected opaque"

  let A : PSC1Kernel.Name := .str .anonymous "A"
  let x : PSC1Kernel.Name := .str .anonymous "x"
  let sort1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let idType : PSC1Kernel.Expr :=
    .forallE A sort1
      (.forallE x (.bvar 0) (.bvar 1) .default)
      .default
  let idValue : PSC1Kernel.Expr :=
    .lam A sort1
      (.lam x (.bvar 0) (.bvar 0) .default)
      .default
  let defValue : PSC1Kernel.DefinitionInfo := {
    base := { name := ident, levelParams := [], type := idType }
    value := idValue
    hints := .regular 0
    safety := .safe
  }
  let ours5 ← exceptToIO "PSC1 add definition" (PSC1Kernel.Kernel.addDefinition ours4 defValue)
  let lean5 ←
    match Lean.Kernel.Environment.addDecl lean4 {} (.defnDecl {
      name := toLeanName ident
      levelParams := []
      type := toLeanExpr idType
      value := toLeanExpr idValue
      hints := .regular 0
      safety := .safe
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean 4.34 rejected identity definition"

  assertTrue "accepted declarations missing from PSC1 environment"
    (ours5.contains P && ours5.contains h && ours5.contains th &&
      ours5.contains op && ours5.contains ident)
  assertTrue "accepted declarations missing from Lean environment"
    ((lean5.find? (toLeanName P)).isSome &&
      (lean5.find? (toLeanName ident)).isSome)

  let duplicateOurs :=
    match PSC1Kernel.Kernel.addAxiom ours5 pAxiom with
    | .ok _ => false
    | .error _ => true
  let duplicateLean :=
    match Lean.Kernel.Environment.addDecl lean5 {} (.axiomDecl {
      name := toLeanName P
      levelParams := []
      type := toLeanExpr propSort
      isUnsafe := false
    }) with
    | .ok _ => false
    | .error _ => true
  assertTrue "duplicate-name admission differs from Lean 4.34"
    (duplicateOurs == duplicateLean && duplicateOurs)

  let badValue : PSC1Kernel.DefinitionInfo := {
    base := { name := bad, levelParams := [], type := pExpr }
    value := propSort
    hints := .regular 0
    safety := .safe
  }
  let badOurs :=
    match PSC1Kernel.Kernel.addDefinition ours5 badValue with
    | .ok _ => false
    | .error _ => true
  let badLean :=
    match Lean.Kernel.Environment.addDecl lean5 {} (.defnDecl {
      name := toLeanName bad
      levelParams := []
      type := toLeanExpr pExpr
      value := toLeanExpr propSort
      hints := .regular 0
      safety := .safe
    }) with
    | .ok _ => false
    | .error _ => true
  assertTrue "definition type-mismatch admission differs from Lean 4.34"
    (badOurs == badLean && badOurs)

  let badUniverseType : PSC1Kernel.Expr := .sort (.param u)
  let badUniverseOurs :=
    match PSC1Kernel.Kernel.addAxiom ours5 {
      base := { name := badU, levelParams := [], type := badUniverseType }
      isUnsafe := false
    } with
    | .ok _ => false
    | .error _ => true
  let badUniverseLean :=
    match Lean.Kernel.Environment.addDecl lean5 {} (.axiomDecl {
      name := toLeanName badU
      levelParams := []
      type := toLeanExpr badUniverseType
      isUnsafe := false
    }) with
    | .ok _ => false
    | .error _ => true
  assertTrue "undefined-universe admission differs from Lean 4.34"
    (badUniverseOurs == badUniverseLean && badUniverseOurs)

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
  assertWhnfLayering
  assertNatReductionOracle
  assertFunctionEtaOracle
  assertLazyDeltaOracle
  assertStructureEtaOracle
  assertUnitLikeOracle
  assertProofIrrelevanceOracle
  assertBinderInfoDefEqOracle
  assertProjectionOracle
  assertOrdinaryRecursorOracle
  assertQuotReductionOracle
  assertDeclarationAdmissionOracle
  IO.println "PSC1Kernel Lean 4.34 foundational + projection oracle: PASS"

end PSC1Kernel.Test

def main : IO Unit := PSC1Kernel.Test.run
