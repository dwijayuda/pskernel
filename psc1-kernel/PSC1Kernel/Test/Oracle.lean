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

  let hugeIndex : Nat := 4294967296
  let hugeProj : PSC1Kernel.Expr := .proj S hugeIndex value
  let oursHugeRejects :=
    match PSC1Kernel.infer ctx hugeProj with
    | .ok _ => false
    | .error _ => true

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNat ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type0
      isUnsafe := false
    }) with
    | .ok e => pure e
    | .error _ => throw <| IO.userError "Lean 4.34 rejected projection-index oracle Nat axiom"
  let lean1 ←
    match Lean.Kernel.Environment.addDecl leanNat {} (.inductDecl [] 0 [{
      name := toLeanName S
      type := toLeanExpr type0
      ctors := [{
        name := toLeanName Smk
        type := toLeanExpr ctorSType
      }]
    }] false) with
    | .ok e => pure e
    | .error _ => throw <| IO.userError "Lean 4.34 rejected projection-index oracle inductive"
  let leanEnv := Lean.Environment.ofKernelEnv lean1
  let leanHugeRejects :=
    match Lean.Kernel.check leanEnv ({} : Lean.LocalContext) (toLeanExpr hugeProj) with
    | .ok _ => false
    | .error _ => true
  assertTrue "uint32 projection-index rejection differs from Lean 4.34"
    (oursHugeRejects == leanHugeRejects && leanHugeRejects)

def assertArenaProjectionStructureSoundnessOracle : IO Unit := do
  -- Regression extracted from the Arena bug that previously let projection
  -- typing trust the declared structure family without checking the actual
  -- structure expression.  If accepted, this malformed constructor
  -- application could be projected to manufacture a proof of False.
  let FalseN : PSC1Kernel.Name := .str .anonymous "ArenaFalse"
  let TrueN : PSC1Kernel.Name := .str .anonymous "ArenaTrue"
  let TrueIntro : PSC1Kernel.Name := .str TrueN "intro"
  let Wrapper : PSC1Kernel.Name := .str (.str .anonymous "Arena") "Wrapper"
  let WrapperMk : PSC1Kernel.Name := .str Wrapper "mk"
  let prop : PSC1Kernel.Expr := .sort .zero
  let falseT : PSC1Kernel.Expr := .const FalseN []
  let trueT : PSC1Kernel.Expr := .const TrueN []
  let wrapperT : PSC1Kernel.Expr := .const Wrapper []
  let wrapperCtorT : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "p") falseT wrapperT .default

  let psc0 : PSC1Kernel.Environment := .empty
  let psc1 := psc0.addUnchecked (.axiomInfo {
    base := mkBase FalseN prop
    isUnsafe := false
  })
  let psc2 := psc1.addUnchecked (.axiomInfo {
    base := mkBase TrueN prop
    isUnsafe := false
  })
  let psc3 := psc2.addUnchecked (.axiomInfo {
    base := mkBase TrueIntro trueT
    isUnsafe := false
  })
  let pscEnv ← exceptToIO
    "PSC1 Arena projection wrapper admission"
    (PSC1Kernel.Kernel.addSimpleInductive psc3 {
      levelParams := []
      name := Wrapper
      type := prop
      ctors := [{ name := WrapperMk, type := wrapperCtorT }]
      isUnsafe := false
    })

  let badStruct : PSC1Kernel.Expr :=
    .app (.const WrapperMk []) (.const TrueIntro [])
  let badProj : PSC1Kernel.Expr :=
    .proj Wrapper 0 badStruct
  let pscRejects :=
    match PSC1Kernel.check (PSC1Kernel.CheckerContext.empty pscEnv) badProj with
    | .ok _ => false
    | .error _ => true

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let lean1 ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName FalseN
      levelParams := []
      type := toLeanExpr prop
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected Arena False axiom"
  let lean2 ←
    match Lean.Kernel.Environment.addDecl lean1 {} (.axiomDecl {
      name := toLeanName TrueN
      levelParams := []
      type := toLeanExpr prop
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected Arena True axiom"
  let lean3 ←
    match Lean.Kernel.Environment.addDecl lean2 {} (.axiomDecl {
      name := toLeanName TrueIntro
      levelParams := []
      type := toLeanExpr trueT
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected Arena True.intro axiom"
  let lean4 ←
    match Lean.Kernel.Environment.addDecl lean3 {} (.inductDecl [] 0 [{
      name := toLeanName Wrapper
      type := toLeanExpr prop
      ctors := [{ name := toLeanName WrapperMk, type := toLeanExpr wrapperCtorT }]
    }] false) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected Arena Wrapper inductive"
  let leanEnv := Lean.Environment.ofKernelEnv lean4
  let leanRejects :=
    match Lean.Kernel.check leanEnv ({} : Lean.LocalContext) (toLeanExpr badProj) with
    | .ok _ => false
    | .error _ => true

  assertTrue
    "Arena projection-structure rejection differs from Lean 4.34"
    (pscRejects == leanRejects && leanRejects)

def natConst (field : String) : PSC1Kernel.Expr :=
  .const (.str (.str .anonymous "Nat") field) []

def natUnary (field : String) (a : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  .app (natConst field) a

def natBinary
    (field : String)
    (a b : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  .app (.app (natConst field) a) b

def assertNatOffsetOracle : IO Unit := do
  let NatN := PSC1Kernel.kernelNatName
  let Succ := PSC1Kernel.kernelNatSuccName
  let ghost : PSC1Kernel.Name := .str (.str .anonymous "Offset") "ghost"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let natT : PSC1Kernel.Expr := .const NatN []
  let succType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natT natT .default

  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo {
    base := mkBase NatN type1
    isUnsafe := false
  })
  let env := env1.addUnchecked (.axiomInfo {
    base := mkBase Succ succType
    isUnsafe := false
  })
  let lctx := PSC1Kernel.LocalContext.empty.addLocal ghost ghost natT .default
  let ctx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty env) with lctx := lctx }

  let ignored : PSC1Kernel.Expr :=
    .letE (.str .anonymous "_g") natT (.fvar ghost) (.lit (.nat 4)) false
  let lhs : PSC1Kernel.Expr := .app (.const Succ []) ignored
  let rhs : PSC1Kernel.Expr := .lit (.nat 5)
  let ours ← exceptToIO "PSC1 Nat offset defeq" (PSC1Kernel.isDefEq ctx lhs rhs)

  Lean.initSearchPath (← Lean.findSysroot)
  let leanEnv ← Lean.importModules #[{ module := `Init.Prelude }] {}
  let ghostId : Lean.FVarId := ⟨toLeanName ghost⟩
  let leanLctx : Lean.LocalContext :=
    ({} : Lean.LocalContext).mkLocalDecl
      ghostId (toLeanName ghost) (toLeanExpr natT) .default
  let lean ←
    match Lean.Kernel.isDefEq leanEnv leanLctx (toLeanExpr lhs) (toLeanExpr rhs) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean 4.34 Nat offset oracle failed"

  assertTrue "Nat offset defeq differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should strip Nat.succ/literal offsets before fvar-sensitive reduction" lean

def assertEagerReduceOracle : IO Unit := do
  let NatN := PSC1Kernel.kernelNatName
  let Add := PSC1Kernel.kernelNatAddName
  let Eager := PSC1Kernel.kernelEagerReduceName
  let F : PSC1Kernel.Name := .str (.str .anonymous "Eager") "F"
  let ghost : PSC1Kernel.Name := .str (.str .anonymous "Eager") "ghost"
  let p : PSC1Kernel.Name := .str (.str .anonymous "Eager") "p"
  let q : PSC1Kernel.Name := .str (.str .anonymous "Eager") "q"
  let A : PSC1Kernel.Name := .str .anonymous "A"
  let a : PSC1Kernel.Name := .str .anonymous "a"
  let u : PSC1Kernel.Name := .str .anonymous "u"
  let one : PSC1Kernel.Level := .succ .zero
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort one
  let natBinType : PSC1Kernel.Expr :=
    .forallE a natT
      (.forallE a natT natT .default)
      .default
  let fType : PSC1Kernel.Expr :=
    .forallE a natT type1 .default
  let eagerType : PSC1Kernel.Expr :=
    .forallE A (.sort (.param u))
      (.forallE a (.bvar 0) (.bvar 1) .default)
      .implicit

  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo {
    base := mkBase NatN type1
    isUnsafe := false
  })
  let env2 := env1.addUnchecked (.axiomInfo {
    base := mkBase Add natBinType
    isUnsafe := false
  })
  let env3 := env2.addUnchecked (.axiomInfo {
    base := mkBase F fType
    isUnsafe := false
  })
  let env := env3.addUnchecked (.axiomInfo {
    base := { name := Eager, levelParams := [u], type := eagerType }
    isUnsafe := false
  })

  let lctx0 := PSC1Kernel.LocalContext.empty.addLocal ghost ghost natT .default
  let ignored : PSC1Kernel.Expr :=
    .letE (.str .anonymous "_g") natT (.fvar ghost) (.lit (.nat 1)) false
  let red : PSC1Kernel.Expr :=
    .app (.app (.const Add []) ignored) (.lit (.nat 1))
  let p1 : PSC1Kernel.Expr := .app (.const F []) red
  let p2 : PSC1Kernel.Expr := .app (.const F []) (.lit (.nat 2))
  let lctx := lctx0.addLocal p p p1 .default
  let ctx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty env) with lctx := lctx }
  let consume : PSC1Kernel.Expr :=
    .lam q p2 (.lit (.nat 0)) .default
  let plain : PSC1Kernel.Expr := .app consume (.fvar p)
  let wrappedArg : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const Eager [one]) [p1, .fvar p]
  let wrapped : PSC1Kernel.Expr := .app consume wrappedArg

  let oursPlainRejects :=
    match PSC1Kernel.check ctx plain with
    | .ok _ => false
    | .error _ => true
  let oursWrapped ← exceptToIO
    "PSC1 eagerReduce wrapped application"
    (PSC1Kernel.check ctx wrapped)
  assertTrue "PSC1 eagerReduce result type mismatch"
    (PSC1Kernel.Expr.eq oursWrapped natT)

  -- Mirror the PSC fixture exactly. Importing Init.Core here would make
  -- Nat.add delta-reducible and would no longer isolate the eagerReduce path.
  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let lean1 ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean 4.34 rejected eagerReduce oracle Nat axiom"
  let lean2 ←
    match Lean.Kernel.Environment.addDecl lean1 {} (.axiomDecl {
      name := toLeanName Add
      levelParams := []
      type := toLeanExpr natBinType
      isUnsafe := false
    }) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean 4.34 rejected eagerReduce oracle Nat.add axiom"
  let lean3 ←
    match Lean.Kernel.Environment.addDecl lean2 {} (.axiomDecl {
      name := toLeanName F
      levelParams := []
      type := toLeanExpr fType
      isUnsafe := false
    }) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean 4.34 rejected eagerReduce oracle F axiom"
  let lean4 ←
    match Lean.Kernel.Environment.addDecl lean3 {} (.axiomDecl {
      name := toLeanName Eager
      levelParams := [toLeanName u]
      type := toLeanExpr eagerType
      isUnsafe := false
    }) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean 4.34 rejected eagerReduce oracle marker axiom"
  let leanEnv := Lean.Environment.ofKernelEnv lean4
  let ghostId : Lean.FVarId := ⟨toLeanName ghost⟩
  let pId : Lean.FVarId := ⟨toLeanName p⟩
  let leanLctx0 : Lean.LocalContext :=
    ({} : Lean.LocalContext).mkLocalDecl ghostId (toLeanName ghost) (toLeanExpr natT) .default
  let leanLctx :=
    leanLctx0.mkLocalDecl pId (toLeanName p) (toLeanExpr p1) .default

  let leanPlainRejects :=
    match Lean.Kernel.check leanEnv leanLctx (toLeanExpr plain) with
    | .ok _ => false
    | .error _ => true
  let leanWrapped ←
    match Lean.Kernel.check leanEnv leanLctx (toLeanExpr wrapped) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "Lean 4.34 rejected eagerReduce wrapped application"

  assertTrue "plain application acceptance differs from Lean 4.34"
    (oursPlainRejects == leanPlainRejects && leanPlainRejects)
  assertTrue "eagerReduce wrapped result differs from Lean 4.34"
    (Lean.Expr.equal (toLeanExpr oursWrapped) leanWrapped)

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
  let core ← exceptToIO "whnfCore delta boundary" (PSC1Kernel.whnfCore ctx d false false)
  let full ← exceptToIO "whnf delta boundary" (PSC1Kernel.whnf ctx d)
  assertTrue "whnfCore performed forbidden delta reduction" (PSC1Kernel.Expr.eq core d)
  assertTrue "full whnf failed to delta reduce" (PSC1Kernel.Expr.eq full (.lit (.nat 23)))

def assertNativeEvaluatorBoundary : IO Unit := do
  let natTarget : PSC1Kernel.Name :=
    .str (.str .anonymous "NativeOracle") "nat"
  let boolTarget : PSC1Kernel.Name :=
    .str (.str .anonymous "NativeOracle") "bool"
  let provider : PSC1Kernel.NativeEvaluator := {
    evalBool := fun name =>
      if PSC1Kernel.Name.eq name boolTarget then
        .ok (some true)
      else
        .ok none
    evalNat := fun name =>
      if PSC1Kernel.Name.eq name natTarget then
        .ok (some 37)
      else
        .ok none
  }
  let baseCtx := PSC1Kernel.CheckerContext.empty .empty
  let ctx : PSC1Kernel.CheckerContext :=
    { baseCtx with nativeEvaluator := some provider }
  let natExpr : PSC1Kernel.Expr :=
    .app
      (.const PSC1Kernel.kernelReduceNatName [])
      (.const natTarget [])
  let boolExpr : PSC1Kernel.Expr :=
    .app
      (.const PSC1Kernel.kernelReduceBoolName [])
      (.const boolTarget [])

  let natResult ← exceptToIO
    "PSC1 native Nat provider"
    (PSC1Kernel.whnf ctx natExpr)
  assertTrue "native Nat provider returned the wrong kernel value"
    (PSC1Kernel.Expr.eq natResult (.lit (.nat 37)))

  let boolResult ← exceptToIO
    "PSC1 native Bool provider"
    (PSC1Kernel.whnf ctx boolExpr)
  assertTrue "native Bool provider returned the wrong kernel value"
    (PSC1Kernel.Expr.eq boolResult (.const PSC1Kernel.kernelBoolTrueName []))

  let closedResult ← exceptToIO
    "PSC1 native boundary fail-closed"
    (PSC1Kernel.whnf baseCtx natExpr)
  assertTrue "missing native provider must leave marker reduction unavailable"
    (PSC1Kernel.Expr.eq closedResult natExpr)

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
    ("ble-false", natBinary "ble" (.lit (.nat 12)) (.lit (.nat 11))),
    ("land", natBinary "land" (.lit (.nat 6)) (.lit (.nat 3))),
    ("lor", natBinary "lor" (.lit (.nat 4)) (.lit (.nat 3))),
    ("xor", natBinary "xor" (.lit (.nat 6)) (.lit (.nat 3))),
    ("shift-left", natBinary "shiftLeft" (.lit (.nat 3)) (.lit (.nat 4))),
    ("shift-right", natBinary "shiftRight" (.lit (.nat 48)) (.lit (.nat 4)))
  ]
  for item in cases do
    let label := item.1
    let input := item.2
    let ours ← exceptToIO ("PSC1 Nat whnf " ++ label) (PSC1Kernel.whnf ctx input)
    let lean ← kernelExprWhnf env input
    assertTrue
      ("Nat reduction differs from Lean 4.34: " ++ label)
      (toLeanExpr ours == lean)

  -- Final Lean 4.34 rejects pow/shiftLeft counts above UINT32_MAX before
  -- entering runtime arithmetic. This is intentionally not an arbitrary
  -- implementation cutoff.
  let tooLargeCount : Nat := 4294967296
  let hugePow := natBinary "pow" (.lit (.nat 2)) (.lit (.nat tooLargeCount))
  let oursPowRejects :=
    match PSC1Kernel.whnf ctx hugePow with
    | .ok _ => false
    | .error _ => true
  let leanPowRejects :=
    match Lean.Kernel.whnf env ({} : Lean.LocalContext) (toLeanExpr hugePow) with
    | .ok _ => false
    | .error _ => true
  assertTrue "Nat.pow UINT32 count guard differs from Lean 4.34"
    (oursPowRejects == leanPowRejects && leanPowRejects)

  let hugeShift := natBinary "shiftLeft" (.lit (.nat 1)) (.lit (.nat tooLargeCount))
  let oursShiftRejects :=
    match PSC1Kernel.whnf ctx hugeShift with
    | .ok _ => false
    | .error _ => true
  let leanShiftRejects :=
    match Lean.Kernel.whnf env ({} : Lean.LocalContext) (toLeanExpr hugeShift) with
    | .ok _ => false
    | .error _ => true
  assertTrue "Nat.shiftLeft UINT32 count guard differs from Lean 4.34"
    (oursShiftRejects == leanShiftRejects && leanShiftRejects)

  -- Lean checks the shift count only for nonzero values. Preserve that exact
  -- ordering: 0 <<< huge reduces to zero rather than rejecting the count.
  let zeroHugeShift := natBinary "shiftLeft" (.lit (.nat 0)) (.lit (.nat tooLargeCount))
  let oursZero ← exceptToIO "PSC1 zero huge shift" (PSC1Kernel.whnf ctx zeroHugeShift)
  let leanZero ← kernelExprWhnf env zeroHugeShift
  assertTrue "Nat.shiftLeft zero/count ordering differs from Lean 4.34"
    (toLeanExpr oursZero == leanZero)

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

def assertStructureMajorRecursorOracle : IO Unit := do
  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let Pair : PSC1Kernel.Name := .str .anonymous "OracleStructureMajor"
  let PairMk : PSC1Kernel.Name := .str Pair "mk"
  let PairRec : PSC1Kernel.Name := .str Pair "rec"
  let pairT : PSC1Kernel.Expr := .const Pair []
  let pairCtorT : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "left") natT
      (.forallE (.str .anonymous "right") natT pairT .default)
      .default
  let base :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursEnv ← exceptToIO
    "PSC1 structure-major inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive base {
      levelParams := []
      name := Pair
      type := type1
      ctors := [{ name := PairMk, type := pairCtorT }]
      isUnsafe := false
    })

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNat ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected structure-major Nat axiom"
  let leanKernel ←
    match Lean.Kernel.Environment.addDecl leanNat {} (.inductDecl [] 0 [{
      name := toLeanName Pair
      type := toLeanExpr type1
      ctors := [{ name := toLeanName PairMk, type := toLeanExpr pairCtorT }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected structure-major Pair"
  let leanEnv := Lean.Environment.ofKernelEnv leanKernel

  let p : PSC1Kernel.Name := .str .anonymous "p"
  let motive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "pair") pairT natT .default
  let minor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "left") natT
      (.lam (.str .anonymous "right") natT (.bvar 1) .default)
      .default
  let recApp :=
    PSC1Kernel.applyArgs (.const PairRec [.succ .zero])
      [motive, minor, .fvar p]
  let expected : PSC1Kernel.Expr := .proj Pair 0 (.fvar p)

  let pscLctx := PSC1Kernel.LocalContext.empty.addLocal p p pairT .default
  let pscCtx : PSC1Kernel.CheckerContext :=
    { (PSC1Kernel.CheckerContext.empty oursEnv) with lctx := pscLctx }
  let ours ← exceptToIO
    "PSC1 arbitrary structure-major recursor reduction"
    (PSC1Kernel.whnf pscCtx recApp)

  let pId : Lean.FVarId := ⟨toLeanName p⟩
  let leanLctx : Lean.LocalContext :=
    ({} : Lean.LocalContext).mkLocalDecl pId (toLeanName p)
      (toLeanExpr pairT) .default
  let lean ←
    match Lean.Kernel.whnf leanEnv leanLctx (toLeanExpr recApp) with
    | .ok value => pure value
    | .error _ =>
        throw <| IO.userError "Lean 4.34 structure-major recursor reduction failed"

  assertTrue "structure-major recursor reduction differs from Lean 4.34"
    (toLeanExpr ours == lean)
  assertTrue "structure-major recursor did not eta-expand the arbitrary major"
    (PSC1Kernel.Expr.eq ours expected)

def assertProjectionLazyDeltaOracle : IO Unit := do
  let env0 := makeStructureEnvironment
  let pair : PSC1Kernel.Name :=
    .str (.str (.str .anonymous "PSC1Kernel") "Test") "EtaPair"
  let pairMk : PSC1Kernel.Name := .str pair "mk"
  let pairA : PSC1Kernel.Name :=
    .str (.str (.str .anonymous "PSC1Kernel") "Test") "ProjDeltaA"
  let pairB : PSC1Kernel.Name :=
    .str (.str (.str .anonymous "PSC1Kernel") "Test") "ProjDeltaB"
  let pairT : PSC1Kernel.Expr := .const pair []
  let mkPair (a b : Nat) : PSC1Kernel.Expr :=
    .app
      (.app (.const pairMk []) (.lit (.nat a)))
      (.lit (.nat b))
  let env1 := env0.addUnchecked (.defnInfo {
    base := mkBase pairA pairT
    value := mkPair 1 2
    hints := .regular 0
    safety := .safe
  })
  let env := env1.addUnchecked (.defnInfo {
    base := mkBase pairB pairT
    value := mkPair 1 3
    hints := .regular 0
    safety := .safe
  })
  let ctx := PSC1Kernel.CheckerContext.empty env
  let left : PSC1Kernel.Expr := .proj pair 0 (.const pairA [])
  let right : PSC1Kernel.Expr := .proj pair 0 (.const pairB [])
  let ours ← exceptToIO
    "PSC1 projection lazy delta"
    (PSC1Kernel.isDefEq ctx left right)

  let leanEnv ← importStructureFixture
  let lean ← kernelExprDefEq leanEnv left right
  assertTrue "projection lazy-delta differs from Lean 4.34"
    (ours == lean)
  assertTrue "Lean 4.34 should compare projected fields before unrelated fields" lean

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

def assertBindingOpenDefEqOracle : IO Unit := do
  let NatN := PSC1Kernel.kernelNatName
  let Succ := PSC1Kernel.kernelNatSuccName
  let x : PSC1Kernel.Name := .str (.str .anonymous "Binding") "x"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let natT : PSC1Kernel.Expr := .const NatN []
  let succType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natT natT .default
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.axiomInfo {
    base := mkBase NatN type1
    isUnsafe := false
  })
  let env := env1.addUnchecked (.axiomInfo {
    base := mkBase Succ succType
    isUnsafe := false
  })
  let ctx := PSC1Kernel.CheckerContext.empty env

  let ignored : PSC1Kernel.Expr :=
    .letE (.str .anonymous "_g") natT (.bvar 0) (.lit (.nat 4)) false
  let lhs : PSC1Kernel.Expr :=
    .lam x natT
      (.app (.const Succ []) ignored)
      .default
  let rhs : PSC1Kernel.Expr :=
    .lam x natT (.lit (.nat 5)) .default

  let ours ← exceptToIO
    "PSC1 opened-binder defeq"
    (PSC1Kernel.isDefEq ctx lhs rhs)

  Lean.initSearchPath (← Lean.findSysroot)
  let leanEnv ← Lean.importModules #[{ module := `Init.Prelude }] {}
  let lean ← kernelExprDefEq leanEnv lhs rhs
  assertTrue "opened-binder defeq differs from Lean 4.34" (ours == lean)
  assertTrue "Lean 4.34 should compare binder bodies in an opened local context" lean

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

def assertStringLiteralExpansionShape : IO Unit := do
  let value := "A🙂"
  let ours := toLeanExpr (PSC1Kernel.stringLitToConstructor value)
  let charType := Lean.mkConst ``Char
  let listNil := Lean.mkApp (Lean.mkConst ``List.nil [.zero]) charType
  let listCons := Lean.mkApp (Lean.mkConst ``List.cons [.zero]) charType
  let charOfNat := Lean.mkConst ``Char.ofNat
  let data :=
    value.toList.foldr
      (fun c rest =>
        Lean.mkApp2 listCons
          (Lean.mkApp charOfNat (Lean.mkRawNatLit c.toNat))
          rest)
      listNil
  let expected := Lean.mkApp (Lean.mkConst ``String.ofList) data
  assertTrue "string literal constructor shape differs from Lean 4.34"
    (Lean.Expr.equal ours expected)

def assertStringLiteralDefEqOracle : IO Unit := do
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let pscEnv :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase PSC1Kernel.kernelStringName type1
      isUnsafe := false
    })
  let ctx := PSC1Kernel.CheckerContext.empty pscEnv
  let literal : PSC1Kernel.Expr := .lit (.str "A🙂")
  let expanded := PSC1Kernel.stringLitToConstructor "A🙂"
  let ours ← exceptToIO
    "PSC1 string literal expansion defeq"
    (PSC1Kernel.isDefEq ctx literal expanded)

  Lean.initSearchPath (← Lean.findSysroot)
  let leanEnv ← Lean.importModules #[{ module := `Init.Prelude }] {}
  let lean ← kernelExprDefEq leanEnv literal expanded
  assertTrue "string literal expansion differs from Lean 4.34"
    (ours == lean)
  assertTrue "Lean 4.34 should equate literal and String.ofList form" lean

def makeQuotEqEnvironment (varyBinderMetadata : Bool) : PSC1Kernel.Environment :=
  let u : PSC1Kernel.Name := .str .anonymous "quotOracleU"
  let eqName := PSC1Kernel.Kernel.kernelEqName
  let reflName : PSC1Kernel.Name := .str eqName "refl"
  let rawEqType := PSC1Kernel.Kernel.expectedEqType u
  let rawReflType := PSC1Kernel.Kernel.expectedEqReflType u
  let eqType :=
    if varyBinderMetadata then
      match rawEqType with
      | .forallE _ domain body _ =>
          .forallE (.str .anonymous "ChangedEqBinder") domain body .strictImplicit
      | other => other
    else
      rawEqType
  let reflType :=
    if varyBinderMetadata then
      match rawReflType with
      | .forallE _ domain body _ =>
          .forallE (.str .anonymous "ChangedReflBinder") domain body .instImplicit
      | other => other
    else
      rawReflType
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.inductInfo {
    base := { name := eqName, levelParams := [u], type := eqType }
    numParams := 2
    numIndices := 1
    all := [eqName]
    ctors := [reflName]
    numNested := 0
    isRec := false
    isReflexive := true
    isUnsafe := false
  })
  env1.addUnchecked (.ctorInfo {
    base := { name := reflName, levelParams := [u], type := reflType }
    induct := eqName
    cidx := 0
    numParams := 2
    numFields := 0
    isUnsafe := false
  })

def assertQuotAdmissionOracle : IO Unit := do
  -- Lean's quotient bootstrap compares Eq/Eq.refl structurally while ignoring
  -- binder display metadata. Exercise that exact boundary explicitly.
  let base := makeQuotEqEnvironment true
  let admitted ← exceptToIO
    "PSC1 Quot admission with binder-metadata variation"
    (PSC1Kernel.Kernel.addQuot base)
  assertTrue "Quot admission did not mark the environment initialized"
    admitted.quotInitialized

  let expectedNames : List PSC1Kernel.Name := [
    PSC1Kernel.kernelQuotName,
    PSC1Kernel.kernelQuotMkName,
    PSC1Kernel.kernelQuotLiftName,
    PSC1Kernel.kernelQuotIndName
  ]
  for name in expectedNames do
    assertTrue "Quot admission omitted a generated primitive"
      (admitted.contains name)

  -- Re-initialization is idempotent in final Lean 4.34.
  let admittedAgain ← exceptToIO
    "PSC1 Quot admission idempotence"
    (PSC1Kernel.Kernel.addQuot admitted)
  assertTrue "Quot admission idempotence changed environment size"
    (admittedAgain.size == admitted.size)

  -- Generated types must agree with the actual Lean 4.34 Prelude environment.
  Lean.initSearchPath (← Lean.findSysroot)
  let leanEnv ← Lean.importModules #[{ module := `Init.Prelude }] {}
  for name in expectedNames do
    let some oursInfo := admitted.find? name
      | throw <| IO.userError "PSC1 Quot primitive missing after admission"
    let some leanInfo := leanEnv.find? (toLeanName name)
      | throw <| IO.userError "Lean 4.34 Quot primitive missing from Init.Prelude"
    let oursType := toLeanExpr oursInfo.type
    assertTrue
      ("generated Quot primitive type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv oursType leanInfo.type)

  -- Final Lean 4.34 checks all four names before raw insertion; an occupied
  -- primitive name must reject initialization instead of overwriting it.
  let collision := base.addUnchecked (.axiomInfo {
    base := {
      name := PSC1Kernel.kernelQuotLiftName
      levelParams := []
      type := .sort .zero
    }
    isUnsafe := false
  })
  match PSC1Kernel.Kernel.addQuot collision with
  | .ok _ =>
      throw <| IO.userError "Quot admission overwrote an occupied primitive name"
  | .error _ => pure ()

def makeDeepSuccExpr (depth : Nat) : PSC1Kernel.Expr :=
  match depth with
  | 0 => .lit (.nat 0)
  | n + 1 => .app (.const PSC1Kernel.kernelNatSuccName []) (makeDeepSuccExpr n)

def assertKernelRecDepthOracle : IO Unit := do
  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let Succ : PSC1Kernel.Name := PSC1Kernel.kernelNatSuccName
  let Deep : PSC1Kernel.Name := .str .anonymous "OracleDeepRecDepth"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let natT : PSC1Kernel.Expr := .const NatN []
  let succT : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natT natT .default
  let deepValue := makeDeepSuccExpr 96

  let psc0 :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let pscBase :=
    psc0.addUnchecked (.axiomInfo {
      base := mkBase Succ succT
      isUnsafe := false
    })
  let pscDef : PSC1Kernel.DefinitionInfo := {
    base := mkBase Deep natT
    value := deepValue
    hints := .opaqueHint
    safety := .safe
  }
  let pscSmallRejects :=
    match PSC1Kernel.Kernel.addDefinition pscBase pscDef 2 with
    | .ok _ => false
    | .error _ => true
  let pscLargeAccepts :=
    match PSC1Kernel.Kernel.addDefinition pscBase pscDef 100 with
    | .ok _ => true
    | .error _ => false

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNat ←
    match lean0.addDeclCore 0 0 (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) none with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean rejected recursion-depth Nat axiom"
  let leanBase ←
    match leanNat.addDeclCore 0 0 (.axiomDecl {
      name := toLeanName Succ
      levelParams := []
      type := toLeanExpr succT
      isUnsafe := false
    }) none with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean rejected recursion-depth succ axiom"
  let leanDef : Lean.DefinitionVal := {
    name := toLeanName Deep
    levelParams := []
    type := toLeanExpr natT
    value := toLeanExpr deepValue
    hints := .opaque
    safety := .safe
  }
  let leanSmallRejects :=
    match leanBase.addDeclCore 0 2 (.defnDecl leanDef) none with
    | .ok _ => false
    | .error _ => true
  let leanLargeAccepts :=
    match leanBase.addDeclCore 0 100 (.defnDecl leanDef) none with
    | .ok _ => true
    | .error _ => false

  assertTrue "small maxRecDepth rejection differs from Lean 4.34"
    (pscSmallRejects == leanSmallRejects && leanSmallRejects)
  assertTrue "large maxRecDepth acceptance differs from Lean 4.34"
    (pscLargeAccepts == leanLargeAccepts && leanLargeAccepts)

def assertOpaqueClosureOracle : IO Unit := do
  -- Lean #14484/#14498 hardening: opaque bodies must be closed before any
  -- checker cache/history can make a dangling local look admissible.
  let OpaqueN : PSC1Kernel.Name := .str .anonymous "OracleDanglingOpaque"
  let Fresh : PSC1Kernel.Name := .str .anonymous "_kernel_fresh"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let prop : PSC1Kernel.Expr := .sort .zero
  let oursInfo : PSC1Kernel.OpaqueInfo := {
    base := mkBase OpaqueN type1
    value := .fvar Fresh
    isUnsafe := false
  }
  let oursRejects :=
    match PSC1Kernel.Kernel.addOpaque .empty oursInfo with
    | .ok _ => false
    | .error _ => true
  assertTrue "rejected opaque declaration mutated PSC1 environment"
    (!PSC1Kernel.Environment.empty.contains OpaqueN)

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanInfo : Lean.OpaqueVal := {
    name := toLeanName OpaqueN
    levelParams := []
    type := toLeanExpr type1
    value := .fvar ⟨toLeanName Fresh⟩
    isUnsafe := false
  }
  let leanRejects :=
    match Lean.Kernel.Environment.addDecl lean0 {} (.opaqueDecl leanInfo) with
    | .ok _ => false
    | .error _ => true

  assertTrue
    "dangling-free-variable opaque rejection differs from Lean 4.34"
    (oursRejects == leanRejects && leanRejects)
  let _ := prop
  pure ()

def assertMutualDuplicateNameOracle : IO Unit := do
  let Dup : PSC1Kernel.Name := .str .anonymous "OracleMutualDup"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let value : PSC1Kernel.Expr := .sort .zero
  let info : PSC1Kernel.DefinitionInfo := {
    base := mkBase Dup type1
    value := value
    hints := .opaqueHint
    safety := .partialDef
  }
  let oursRejects :=
    match PSC1Kernel.Kernel.addMutualDefinitions .empty [info, info] with
    | .ok _ => false
    | .error _ => true

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanInfo : Lean.DefinitionVal := {
    name := toLeanName Dup
    levelParams := []
    type := toLeanExpr type1
    value := toLeanExpr value
    hints := .opaque
    safety := .partial
  }
  let leanRejects :=
    match Lean.Kernel.Environment.addDecl lean0 {}
        (.mutualDefnDecl [leanInfo, leanInfo]) with
    | .ok _ => false
    | .error _ => true
  assertTrue
    "duplicate mutual-definition name rejection differs from Lean 4.34"
    (oursRejects == leanRejects && leanRejects)

def assertImaxPropOracle : IO Unit := do
  let BoolN : PSC1Kernel.Name := .str .anonymous "OracleImaxBool"
  let Data : PSC1Kernel.Name := .str .anonymous "OracleImaxData"
  let DataMk : PSC1Kernel.Name := .str Data "mk"
  let DataRec : PSC1Kernel.Name := .str Data "rec"
  let Proof : PSC1Kernel.Name := .str Data "proof"
  let UnitI : PSC1Kernel.Name := .str .anonymous "OracleImaxUnit"
  let UnitIMk : PSC1Kernel.Name := .str UnitI "mk"
  let UnitIRec : PSC1Kernel.Name := .str UnitI "rec"
  let Unit0 : PSC1Kernel.Name := .str .anonymous "OraclePropUnit"
  let Unit0Mk : PSC1Kernel.Name := .str Unit0 "mk"
  let Unit0Rec : PSC1Kernel.Name := .str Unit0 "rec"

  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let boolT : PSC1Kernel.Expr := .const BoolN []
  let imaxProp : PSC1Kernel.Expr := .sort (.imax (.succ .zero) .zero)
  let dataT : PSC1Kernel.Expr := .const Data []
  let dataCtorT : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "b") boolT dataT .default
  let unitIT : PSC1Kernel.Expr := .const UnitI []
  let unit0T : PSC1Kernel.Expr := .const Unit0 []

  let base :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase BoolN type1
      isUnsafe := false
    })
  let oursData ← exceptToIO
    "PSC1 imax-Prop data inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive base {
      levelParams := []
      name := Data
      type := imaxProp
      ctors := [{ name := DataMk, type := dataCtorT }]
      isUnsafe := false
    })
  let oursI ← exceptToIO
    "PSC1 imax-Prop unit admission"
    (PSC1Kernel.Kernel.addSimpleInductive oursData {
      levelParams := []
      name := UnitI
      type := imaxProp
      ctors := [{ name := UnitIMk, type := unitIT }]
      isUnsafe := false
    })
  let ours ← exceptToIO
    "PSC1 literal-Prop unit admission"
    (PSC1Kernel.Kernel.addSimpleInductive oursI {
      levelParams := []
      name := Unit0
      type := .sort .zero
      ctors := [{ name := Unit0Mk, type := unit0T }]
      isUnsafe := false
    })

  match ours.find? DataRec with
  | some (.recInfo info) =>
      assertTrue "imax-normalized Prop data unexpectedly allows large elimination"
        info.base.levelParams.isEmpty
  | _ => throw <| IO.userError "PSC1 imax-Prop data recursor missing"

  let some (.recInfo imaxRec) := ours.find? UnitIRec
    | throw <| IO.userError "PSC1 imax-Prop unit recursor missing"
  let some (.recInfo propRec) := ours.find? Unit0Rec
    | throw <| IO.userError "PSC1 literal-Prop unit recursor missing"
  assertTrue "imax-normalized Prop changed K metadata"
    (imaxRec.k == propRec.k)
  assertTrue "imax-normalized Prop changed elimination universe count"
    (imaxRec.base.levelParams.length == propRec.base.levelParams.length)

  let withProof := ours.addUnchecked (.axiomInfo {
    base := mkBase Proof dataT
    isUnsafe := false
  })
  let badProjection : PSC1Kernel.Expr :=
    .proj Data 0 (.const Proof [])
  let oursRejects :=
    match PSC1Kernel.check
        (PSC1Kernel.CheckerContext.empty withProof) badProjection with
    | .ok _ => false
    | .error _ => true

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanBool ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName BoolN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected imax oracle Bool axiom"
  let leanData ←
    match Lean.Kernel.Environment.addDecl leanBool {} (.inductDecl [] 0 [{
      name := toLeanName Data
      type := toLeanExpr imaxProp
      ctors := [{ name := toLeanName DataMk, type := toLeanExpr dataCtorT }]
    }] false) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected imax-Prop data inductive"
  let leanProof ←
    match Lean.Kernel.Environment.addDecl leanData {} (.axiomDecl {
      name := toLeanName Proof
      levelParams := []
      type := toLeanExpr dataT
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ => throw <| IO.userError "Lean rejected imax oracle proof axiom"
  let leanEnv := Lean.Environment.ofKernelEnv leanProof
  let leanRejects :=
    match Lean.Kernel.check leanEnv ({} : Lean.LocalContext)
        (toLeanExpr badProjection) with
    | .ok _ => false
    | .error _ => true
  assertTrue
    "imax-normalized Prop projection rejection differs from Lean 4.34"
    (oursRejects == leanRejects && leanRejects)

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




def assertSimpleInductiveAdmissionOracle : IO Unit := do
  let Enum : PSC1Kernel.Name := .str .anonymous "OracleEnum"
  let Off : PSC1Kernel.Name := .str Enum "off"
  let On : PSC1Kernel.Name := .str Enum "on"
  let Rec : PSC1Kernel.Name := .str Enum "rec"
  let enumType : PSC1Kernel.Expr := .sort (.succ .zero)
  let enumExpr : PSC1Kernel.Expr := .const Enum []
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := Enum
    type := enumType
    ctors := [
      { name := Off, type := enumExpr },
      { name := On, type := enumExpr }
    ]
    isUnsafe := false
  }

  let ours ← exceptToIO
    "PSC1 simple inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty decl)
  for name in [Enum, Off, On, Rec] do
    assertTrue "simple inductive admission omitted generated declaration"
      (ours.contains name)

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let lean1 ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.inductDecl [] 0 [{
      name := toLeanName Enum
      type := toLeanExpr enumType
      ctors := [
        { name := toLeanName Off, type := toLeanExpr enumExpr },
        { name := toLeanName On, type := toLeanExpr enumExpr }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected simple inductive oracle"
  let leanEnv := Lean.Environment.ofKernelEnv lean1

  for name in [Enum, Off, On, Rec] do
    let some oursInfo := ours.find? name
      | throw <| IO.userError "PSC1 simple inductive metadata missing"
    let some leanInfo := lean1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 simple inductive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue "simple inductive generated type differs from Lean 4.34"
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)

  let ctx := PSC1Kernel.CheckerContext.empty ours
  let motiveName : PSC1Kernel.Name := .str .anonymous "motive"
  let motive : PSC1Kernel.Expr :=
    .lam motiveName enumExpr (.sort .zero) .default
  let offMinor : PSC1Kernel.Expr := .lit (.nat 17)
  let onMinor : PSC1Kernel.Expr := .lit (.nat 29)
  let offApp :=
    PSC1Kernel.applyArgs (.const Rec [.zero])
      [motive, offMinor, onMinor, .const Off []]
  let onApp :=
    PSC1Kernel.applyArgs (.const Rec [.zero])
      [motive, offMinor, onMinor, .const On []]
  let oursOff ← exceptToIO
    "PSC1 generated simple recursor off"
    (PSC1Kernel.whnf ctx offApp)
  let oursOn ← exceptToIO
    "PSC1 generated simple recursor on"
    (PSC1Kernel.whnf ctx onApp)
  let leanOff ← kernelExprWhnf leanEnv offApp
  let leanOn ← kernelExprWhnf leanEnv onApp
  assertTrue "generated simple recursor off differs from Lean 4.34"
    (toLeanExpr oursOff == leanOff)
  assertTrue "generated simple recursor on differs from Lean 4.34"
    (toLeanExpr oursOn == leanOn)
  assertTrue "generated simple recursor selected wrong off minor"
    (PSC1Kernel.Expr.eq oursOff offMinor)
  assertTrue "generated simple recursor selected wrong on minor"
    (PSC1Kernel.Expr.eq oursOn onMinor)

  -- Empty non-Prop datatypes generate a recursor with zero minors/rules.
  let Void : PSC1Kernel.Name := .str .anonymous "OracleVoid"
  let VoidRec : PSC1Kernel.Name := .str Void "rec"
  let voidType : PSC1Kernel.Expr := .sort (.succ .zero)
  let oursVoid ← exceptToIO
    "PSC1 empty simple inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty {
      levelParams := []
      name := Void
      type := voidType
      ctors := []
      isUnsafe := false
    })
  let leanVoid0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanVoid1 ←
    match Lean.Kernel.Environment.addDecl leanVoid0 {} (.inductDecl [] 0 [{
      name := toLeanName Void
      type := toLeanExpr voidType
      ctors := []
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected empty simple inductive oracle"
  for name in [Void, VoidRec] do
    let some oursInfo := oursVoid.find? name
      | throw <| IO.userError "PSC1 empty inductive metadata missing"
    let some leanInfo := leanVoid1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 empty inductive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("empty inductive generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursVoid.find? VoidRec with
  | some (.recInfo info) =>
      assertTrue "empty inductive recursor unexpectedly has minors"
        (info.numMinors == 0)
      assertTrue "empty inductive recursor unexpectedly has rules"
        info.rules.isEmpty
  | _ =>
      throw <| IO.userError "PSC1 empty inductive recursor metadata missing"

  -- Universe-polymorphic simple inductives must use Lean's exact fresh
  -- recursor-universe naming rule: u, then u_1, u_2, ...
  let polyU : PSC1Kernel.Name := .str .anonymous "u"
  let polyElimU : PSC1Kernel.Name := .str .anonymous "u_1"
  let Poly : PSC1Kernel.Name := .str .anonymous "OraclePoly"
  let PolyMk : PSC1Kernel.Name := .str Poly "mk"
  let PolyRec : PSC1Kernel.Name := .str Poly "rec"
  let polyLevel : PSC1Kernel.Level := .param polyU
  let polyType : PSC1Kernel.Expr := .sort (.succ polyLevel)
  let polyT : PSC1Kernel.Expr := .const Poly [polyLevel]
  let polyCtorType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "α") (.sort polyLevel) polyT .default
  let oursPoly ← exceptToIO
    "PSC1 universe-polymorphic simple inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty {
      levelParams := [polyU]
      name := Poly
      type := polyType
      ctors := [{ name := PolyMk, type := polyCtorType }]
      isUnsafe := false
    })
  let leanPoly0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanPoly1 ←
    match Lean.Kernel.Environment.addDecl leanPoly0 {} (.inductDecl [toLeanName polyU] 0 [{
      name := toLeanName Poly
      type := toLeanExpr polyType
      ctors := [{ name := toLeanName PolyMk, type := toLeanExpr polyCtorType }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected universe-polymorphic simple inductive oracle"
  for name in [Poly, PolyMk, PolyRec] do
    let some oursInfo := oursPoly.find? name
      | throw <| IO.userError "PSC1 polymorphic inductive metadata missing"
    let some leanInfo := leanPoly1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 polymorphic inductive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("polymorphic inductive generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursPoly.find? PolyRec with
  | some (.recInfo info) =>
      match info.base.levelParams with
      | [elim, original] =>
          assertTrue "PSC1 recursor did not choose Lean's u_1 eliminator universe"
            (PSC1Kernel.Name.eq elim polyElimU)
          assertTrue "PSC1 recursor lost the original universe parameter"
            (PSC1Kernel.Name.eq original polyU)
      | _ =>
          throw <| IO.userError "PSC1 polymorphic recursor universe arity mismatch"
  | _ =>
      throw <| IO.userError "PSC1 polymorphic recursor metadata missing"
  match leanPoly1.find? (toLeanName PolyRec) with
  | some (.recInfo info) =>
      match info.levelParams with
      | [elim, original] =>
          assertTrue "Lean 4.34 recursor did not choose expected u_1 eliminator universe"
            (elim == toLeanName polyElimU)
          assertTrue "Lean 4.34 recursor lost the original universe parameter"
            (original == toLeanName polyU)
      | _ =>
          throw <| IO.userError "Lean 4.34 polymorphic recursor universe arity mismatch"
  | _ =>
      throw <| IO.userError "Lean 4.34 polymorphic recursor metadata missing"

  -- Shared datatype parameters: constructor parameters are checked against the
  -- header, recursor parameters are inferred implicit exactly like Lean 4.34,
  -- and computation rules receive only constructor fields after fixed params.
  let ParamBox : PSC1Kernel.Name := .str .anonymous "OracleParamBox"
  let ParamBoxMk : PSC1Kernel.Name := .str ParamBox "mk"
  let ParamBoxRec : PSC1Kernel.Name := .str ParamBox "rec"
  let paramBoxU : PSC1Kernel.Name := .str .anonymous "u"
  let paramBoxLevel : PSC1Kernel.Level := .param paramBoxU
  let alphaName : PSC1Kernel.Name := .str .anonymous "α"
  let valueName : PSC1Kernel.Name := .str .anonymous "value"
  let paramBoxType : PSC1Kernel.Expr :=
    .forallE alphaName (.sort paramBoxLevel) (.sort (.succ paramBoxLevel)) .default
  let paramBoxCtorType : PSC1Kernel.Expr :=
    .forallE alphaName (.sort paramBoxLevel)
      (.forallE valueName (.bvar 0)
        (.app (.const ParamBox [paramBoxLevel]) (.bvar 1))
        .default)
      .default
  let oursParamBox ← exceptToIO
    "PSC1 parameterized simple inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty {
      levelParams := [paramBoxU]
      name := ParamBox
      type := paramBoxType
      ctors := [{ name := ParamBoxMk, type := paramBoxCtorType }]
      isUnsafe := false
      numParams := 1
    })
  let leanParamBox0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanParamBox1 ←
    match Lean.Kernel.Environment.addDecl leanParamBox0 {} (.inductDecl [toLeanName paramBoxU] 1 [{
      name := toLeanName ParamBox
      type := toLeanExpr paramBoxType
      ctors := [{
        name := toLeanName ParamBoxMk
        type := toLeanExpr paramBoxCtorType
      }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected parameterized simple inductive oracle"
  for name in [ParamBox, ParamBoxMk, ParamBoxRec] do
    let some oursInfo := oursParamBox.find? name
      | throw <| IO.userError "PSC1 parameterized inductive metadata missing"
    let some leanInfo := leanParamBox1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 parameterized inductive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("parameterized inductive generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursParamBox.find? ParamBox with
  | some (.inductInfo info) =>
      assertTrue "PSC1 parameterized inductive numParams mismatch"
        (info.numParams == 1)
  | _ =>
      throw <| IO.userError "PSC1 parameterized inductive info missing"
  match oursParamBox.find? ParamBoxMk with
  | some (.ctorInfo info) =>
      assertTrue "PSC1 parameterized constructor numParams mismatch"
        (info.numParams == 1)
      assertTrue "PSC1 parameterized constructor numFields mismatch"
        (info.numFields == 1)
  | _ =>
      throw <| IO.userError "PSC1 parameterized constructor info missing"
  match oursParamBox.find? ParamBoxRec with
  | some (.recInfo info) =>
      assertTrue "PSC1 parameterized recursor numParams mismatch"
        (info.numParams == 1)
      match info.base.type with
      | PSC1Kernel.Expr.forallE _ _ _ binderInfo =>
          assertTrue "PSC1 inferImplicit did not infer the datatype parameter"
            (PSC1Kernel.BinderInfo.eq binderInfo .implicit)
      | _ =>
          throw <| IO.userError "PSC1 parameterized recursor has no parameter binder"
  | _ =>
      throw <| IO.userError "PSC1 parameterized recursor info missing"

  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let paramBoxBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursParamBoxRun ← exceptToIO
    "PSC1 parameterized simple inductive admission with Nat"
    (PSC1Kernel.Kernel.addSimpleInductive paramBoxBase {
      levelParams := [paramBoxU]
      name := ParamBox
      type := paramBoxType
      ctors := [{ name := ParamBoxMk, type := paramBoxCtorType }]
      isUnsafe := false
      numParams := 1
    })
  let leanParamBoxNat ←
    match Lean.Kernel.Environment.addDecl leanParamBox0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected ParamBox oracle Nat axiom"
  let leanParamBoxRun ←
    match Lean.Kernel.Environment.addDecl leanParamBoxNat {} (.inductDecl [toLeanName paramBoxU] 1 [{
      name := toLeanName ParamBox
      type := toLeanExpr paramBoxType
      ctors := [{
        name := toLeanName ParamBoxMk
        type := toLeanExpr paramBoxCtorType
      }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected ParamBox runtime oracle"
  let leanParamBoxEnv := Lean.Environment.ofKernelEnv leanParamBoxRun
  let one : PSC1Kernel.Level := .succ .zero
  let paramBoxNatT : PSC1Kernel.Expr :=
    .app (.const ParamBox [one]) natT
  let paramMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "box") paramBoxNatT natT .default
  let paramMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "value") natT (.bvar 0) .default
  let paramMajor : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const ParamBoxMk [one])
      [natT, .lit (.nat 43)]
  let paramRecApp :=
    PSC1Kernel.applyArgs (.const ParamBoxRec [one, one])
      [natT, paramMotive, paramMinor, paramMajor]
  let paramCtx := PSC1Kernel.CheckerContext.empty oursParamBoxRun
  let paramType ← exceptToIO
    "PSC1 parameterized recursor typecheck"
    (PSC1Kernel.check paramCtx paramRecApp)
  let paramTypeOk ← exceptToIO
    "PSC1 parameterized recursor result defeq"
    (PSC1Kernel.isDefEq paramCtx paramType natT)
  assertTrue "PSC1 parameterized recursor result type mismatch" paramTypeOk
  let oursParamReduced ← exceptToIO
    "PSC1 parameterized recursor reduction"
    (PSC1Kernel.whnf paramCtx paramRecApp)
  let leanParamType ←
    match Lean.Kernel.check leanParamBoxEnv ({} : Lean.LocalContext) (toLeanExpr paramRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated ParamBox recursor application"
  assertTrue "parameterized recursor type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr paramType) leanParamType)
  let leanParamReduced ← kernelExprWhnf leanParamBoxEnv paramRecApp
  assertTrue "parameterized recursor reduction differs from Lean 4.34"
    (toLeanExpr oursParamReduced == leanParamReduced)
  assertTrue "parameterized recursor did not strip the fixed constructor parameter"
    (PSC1Kernel.Expr.eq oursParamReduced (.lit (.nat 43)))

  -- Small-elimination selection follows Lean 4.34 even when the result
  -- universe is polymorphic and may instantiate to Prop.
  let Small : PSC1Kernel.Name := .str .anonymous "OracleSmallElim"
  let SmallMk : PSC1Kernel.Name := .str Small "mk"
  let SmallRec : PSC1Kernel.Name := .str Small "rec"
  let smallType : PSC1Kernel.Expr :=
    .forallE alphaName (.sort paramBoxLevel) (.sort paramBoxLevel) .default
  let smallCtorType : PSC1Kernel.Expr :=
    .forallE alphaName (.sort paramBoxLevel)
      (.forallE valueName (.bvar 0)
        (.app (.const Small [paramBoxLevel]) (.bvar 1))
        .default)
      .default
  let oursSmall ← exceptToIO
    "PSC1 small-elimination inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty {
      levelParams := [paramBoxU]
      name := Small
      type := smallType
      ctors := [{ name := SmallMk, type := smallCtorType }]
      isUnsafe := false
      numParams := 1
    })
  let leanSmall0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanSmall1 ←
    match Lean.Kernel.Environment.addDecl leanSmall0 {} (.inductDecl [toLeanName paramBoxU] 1 [{
      name := toLeanName Small
      type := toLeanExpr smallType
      ctors := [{ name := toLeanName SmallMk, type := toLeanExpr smallCtorType }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected small-elimination oracle"
  for name in [Small, SmallMk, SmallRec] do
    let some oursInfo := oursSmall.find? name
      | throw <| IO.userError "PSC1 small-elimination metadata missing"
    let some leanInfo := leanSmall1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 small-elimination metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("small-elimination generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursSmall.find? SmallRec with
  | some (.recInfo info) =>
      match info.base.levelParams with
      | [only] =>
          assertTrue "small-elimination recursor changed its original universe parameter"
            (PSC1Kernel.Name.eq only paramBoxU)
      | _ =>
          throw <| IO.userError "small-elimination recursor universe arity mismatch"
      assertTrue "small-elimination recursor was incorrectly marked K"
        (!info.k)
  | _ =>
      throw <| IO.userError "PSC1 small-elimination recursor info missing"

  -- A Prop singleton with no fields supports large elimination and K reduction.
  let Truth : PSC1Kernel.Name := .str .anonymous "OracleTruth"
  let TruthMk : PSC1Kernel.Name := .str Truth "mk"
  let TruthRec : PSC1Kernel.Name := .str Truth "rec"
  let propT : PSC1Kernel.Expr := .sort .zero
  let truthT : PSC1Kernel.Expr := .const Truth []
  let oursTruth ← exceptToIO
    "PSC1 K-target Prop inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty {
      levelParams := []
      name := Truth
      type := propT
      ctors := [{ name := TruthMk, type := truthT }]
      isUnsafe := false
    })
  let leanTruth0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanTruth1 ←
    match Lean.Kernel.Environment.addDecl leanTruth0 {} (.inductDecl [] 0 [{
      name := toLeanName Truth
      type := toLeanExpr propT
      ctors := [{ name := toLeanName TruthMk, type := toLeanExpr truthT }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected K-target Prop oracle"
  for name in [Truth, TruthMk, TruthRec] do
    let some oursInfo := oursTruth.find? name
      | throw <| IO.userError "PSC1 K-target metadata missing"
    let some leanInfo := leanTruth1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 K-target metadata missing: " ++ (toLeanName name).toString)
    assertTrue
      ("K-target generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursTruth.find? TruthRec with
  | some (.recInfo info) =>
      assertTrue "Prop singleton did not gain a fresh eliminator universe"
        (info.base.levelParams.length == 1)
      assertTrue "Prop singleton was not marked K"
        info.k
  | _ =>
      throw <| IO.userError "PSC1 K-target recursor info missing"

  -- K-like reduction converts an arbitrary proof of the singleton predicate
  -- to its nullary constructor before ordinary iota reduction.
  let TruthProof : PSC1Kernel.Name := .str Truth "proof"
  let oursTruthNat :=
    oursTruth.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursTruthRun :=
    oursTruthNat.addUnchecked (.axiomInfo {
      base := mkBase TruthProof truthT
      isUnsafe := false
    })
  let leanTruthNat ←
    match Lean.Kernel.Environment.addDecl leanTruth1 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected Truth oracle Nat axiom"
  let leanTruthRun ←
    match Lean.Kernel.Environment.addDecl leanTruthNat {} (.axiomDecl {
      name := toLeanName TruthProof
      levelParams := []
      type := toLeanExpr truthT
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected Truth proof axiom"
  let leanTruthEnv := Lean.Environment.ofKernelEnv leanTruthRun
  let truthMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "proof") truthT natT .default
  let truthMinor : PSC1Kernel.Expr := .lit (.nat 59)
  let truthRecApp :=
    PSC1Kernel.applyArgs (.const TruthRec [.succ .zero])
      [truthMotive, truthMinor, .const TruthProof []]
  let truthCtx := PSC1Kernel.CheckerContext.empty oursTruthRun
  let truthResultType ← exceptToIO
    "PSC1 K-like recursor typecheck"
    (PSC1Kernel.check truthCtx truthRecApp)
  let truthTypeOk ← exceptToIO
    "PSC1 K-like recursor result defeq"
    (PSC1Kernel.isDefEq truthCtx truthResultType natT)
  assertTrue "PSC1 K-like recursor result type mismatch" truthTypeOk
  let oursTruthReduced ← exceptToIO
    "PSC1 K-like recursor reduction"
    (PSC1Kernel.whnf truthCtx truthRecApp)
  let leanTruthType ←
    match Lean.Kernel.check leanTruthEnv ({} : Lean.LocalContext)
        (toLeanExpr truthRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated Truth K application"
  assertTrue "K-like recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr truthResultType) leanTruthType)
  let leanTruthReduced ← kernelExprWhnf leanTruthEnv truthRecApp
  assertTrue "K-like recursor reduction differs from Lean 4.34"
    (toLeanExpr oursTruthReduced == leanTruthReduced)
  assertTrue "K-like recursor did not reduce an arbitrary singleton proof"
    (PSC1Kernel.Expr.eq oursTruthReduced truthMinor)

  -- More than one constructor forces a Prop-only recursor.
  let ChoiceP : PSC1Kernel.Name := .str .anonymous "OracleChoiceProp"
  let ChoicePA : PSC1Kernel.Name := .str ChoiceP "a"
  let ChoicePB : PSC1Kernel.Name := .str ChoiceP "b"
  let ChoicePRec : PSC1Kernel.Name := .str ChoiceP "rec"
  let choicePT : PSC1Kernel.Expr := .const ChoiceP []
  let oursChoiceP ← exceptToIO
    "PSC1 multi-constructor Prop inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive .empty {
      levelParams := []
      name := ChoiceP
      type := propT
      ctors := [
        { name := ChoicePA, type := choicePT },
        { name := ChoicePB, type := choicePT }
      ]
      isUnsafe := false
    })
  let leanChoiceP0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanChoiceP1 ←
    match Lean.Kernel.Environment.addDecl leanChoiceP0 {} (.inductDecl [] 0 [{
      name := toLeanName ChoiceP
      type := toLeanExpr propT
      ctors := [
        { name := toLeanName ChoicePA, type := toLeanExpr choicePT },
        { name := toLeanName ChoicePB, type := toLeanExpr choicePT }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected multi-constructor Prop oracle"
  for name in [ChoiceP, ChoicePA, ChoicePB, ChoicePRec] do
    let some oursInfo := oursChoiceP.find? name
      | throw <| IO.userError "PSC1 multi-constructor Prop metadata missing"
    let some leanInfo := leanChoiceP1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 multi-constructor Prop metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("multi-constructor Prop generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursChoiceP.find? ChoicePRec with
  | some (.recInfo info) =>
      assertTrue "multi-constructor Prop recursor unexpectedly gained universes"
        info.base.levelParams.isEmpty
      assertTrue "multi-constructor Prop recursor was incorrectly marked K"
        (!info.k)
  | _ =>
      throw <| IO.userError "PSC1 multi-constructor Prop recursor info missing"

  -- A non-Prop field is safe for large elimination when the field itself is
  -- exposed as an index in the constructor result.
  let Reveal : PSC1Kernel.Name := .str .anonymous "OracleReveal"
  let RevealMk : PSC1Kernel.Name := .str Reveal "mk"
  let RevealRec : PSC1Kernel.Name := .str Reveal "rec"
  let revealIndexName : PSC1Kernel.Name := .str .anonymous "n"
  let revealType : PSC1Kernel.Expr :=
    .forallE revealIndexName natT propT .default
  let revealCtorType : PSC1Kernel.Expr :=
    .forallE revealIndexName natT
      (.app (.const Reveal []) (.bvar 0))
      .default
  let revealBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursReveal ← exceptToIO
    "PSC1 indexed Prop large-elimination admission"
    (PSC1Kernel.Kernel.addSimpleInductive revealBase {
      levelParams := []
      name := Reveal
      type := revealType
      ctors := [{ name := RevealMk, type := revealCtorType }]
      isUnsafe := false
    })
  let leanReveal0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanRevealNat ←
    match Lean.Kernel.Environment.addDecl leanReveal0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected Reveal oracle Nat axiom"
  let leanReveal1 ←
    match Lean.Kernel.Environment.addDecl leanRevealNat {} (.inductDecl [] 0 [{
      name := toLeanName Reveal
      type := toLeanExpr revealType
      ctors := [{ name := toLeanName RevealMk, type := toLeanExpr revealCtorType }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected indexed Prop large-elimination oracle"
  let leanRevealEnv := Lean.Environment.ofKernelEnv leanReveal1
  for name in [Reveal, RevealMk, RevealRec] do
    let some oursInfo := oursReveal.find? name
      | throw <| IO.userError "PSC1 indexed Prop metadata missing"
    let some leanInfo := leanReveal1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 indexed Prop metadata missing: " ++ (toLeanName name).toString)
    assertTrue
      ("indexed Prop generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  let revealMotive : PSC1Kernel.Expr :=
    .lam revealIndexName natT
      (.lam (.str .anonymous "proof")
        (.app (.const Reveal []) (.bvar 0))
        natT
        .default)
      .default
  let revealMinor : PSC1Kernel.Expr :=
    .lam revealIndexName natT (.bvar 0) .default
  let revealIndex : PSC1Kernel.Expr := .lit (.nat 47)
  let revealMajor : PSC1Kernel.Expr :=
    .app (.const RevealMk []) revealIndex
  let revealRecApp :=
    PSC1Kernel.applyArgs (.const RevealRec [.succ .zero])
      [revealMotive, revealMinor, revealIndex, revealMajor]
  let revealCtx := PSC1Kernel.CheckerContext.empty oursReveal
  let revealResultType ← exceptToIO
    "PSC1 indexed Prop recursor typecheck"
    (PSC1Kernel.check revealCtx revealRecApp)
  let revealTypeOk ← exceptToIO
    "PSC1 indexed Prop recursor result defeq"
    (PSC1Kernel.isDefEq revealCtx revealResultType natT)
  assertTrue "PSC1 indexed Prop recursor result type mismatch" revealTypeOk
  let oursRevealReduced ← exceptToIO
    "PSC1 indexed Prop recursor reduction"
    (PSC1Kernel.whnf revealCtx revealRecApp)
  let leanRevealType ←
    match Lean.Kernel.check leanRevealEnv ({} : Lean.LocalContext)
        (toLeanExpr revealRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated Reveal recursor application"
  assertTrue "indexed Prop recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr revealResultType) leanRevealType)
  let leanRevealReduced ← kernelExprWhnf leanRevealEnv revealRecApp
  assertTrue "indexed Prop recursor reduction differs from Lean 4.34"
    (toLeanExpr oursRevealReduced == leanRevealReduced)
  assertTrue "indexed Prop large elimination did not reveal the indexed field"
    (PSC1Kernel.Expr.eq oursRevealReduced revealIndex)

  -- Indexed, non-recursive datatype. Constructor return indices may depend
  -- on fields; recursor indices precede the major premise exactly as in Lean.
  let Tag : PSC1Kernel.Name := .str .anonymous "OracleTag"
  let TagZero : PSC1Kernel.Name := .str Tag "zero"
  let TagAt : PSC1Kernel.Name := .str Tag "at"
  let TagRec : PSC1Kernel.Name := .str Tag "rec"
  let indexName : PSC1Kernel.Name := .str .anonymous "n"
  let tagType : PSC1Kernel.Expr :=
    .forallE indexName natT type1 .default
  let tagZeroType : PSC1Kernel.Expr :=
    .app (.const Tag []) (.lit (.nat 0))
  let tagAtType : PSC1Kernel.Expr :=
    .forallE indexName natT
      (.app (.const Tag []) (.bvar 0))
      .default
  let tagBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursTag ← exceptToIO
    "PSC1 indexed simple inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive tagBase {
      levelParams := []
      name := Tag
      type := tagType
      ctors := [
        { name := TagZero, type := tagZeroType },
        { name := TagAt, type := tagAtType }
      ]
      isUnsafe := false
    })
  let leanTag0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanTagNat ←
    match Lean.Kernel.Environment.addDecl leanTag0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected Tag oracle Nat axiom"
  let leanTag1 ←
    match Lean.Kernel.Environment.addDecl leanTagNat {} (.inductDecl [] 0 [{
      name := toLeanName Tag
      type := toLeanExpr tagType
      ctors := [
        { name := toLeanName TagZero, type := toLeanExpr tagZeroType },
        { name := toLeanName TagAt, type := toLeanExpr tagAtType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected indexed simple inductive oracle"
  let leanTagEnv := Lean.Environment.ofKernelEnv leanTag1
  for name in [Tag, TagZero, TagAt, TagRec] do
    let some oursInfo := oursTag.find? name
      | throw <| IO.userError "PSC1 indexed inductive metadata missing"
    let some leanInfo := leanTag1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 indexed inductive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("indexed inductive generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursTag.find? Tag with
  | some (.inductInfo info) =>
      assertTrue "PSC1 indexed inductive numIndices mismatch"
        (info.numIndices == 1)
  | _ =>
      throw <| IO.userError "PSC1 indexed inductive info missing"
  match oursTag.find? TagRec with
  | some (.recInfo info) =>
      assertTrue "PSC1 indexed recursor numIndices mismatch"
        (info.numIndices == 1)
  | _ =>
      throw <| IO.userError "PSC1 indexed recursor info missing"

  let tagMotive : PSC1Kernel.Expr :=
    .lam indexName natT
      (.lam (.str .anonymous "tag")
        (.app (.const Tag []) (.bvar 0))
        natT
        .default)
      .default
  let tagZeroMinor : PSC1Kernel.Expr := .lit (.nat 7)
  let tagAtMinor : PSC1Kernel.Expr :=
    .lam indexName natT (.bvar 0) .default
  let tagIndex : PSC1Kernel.Expr := .lit (.nat 43)
  let tagMajor : PSC1Kernel.Expr :=
    .app (.const TagAt []) tagIndex
  let tagRecApp :=
    PSC1Kernel.applyArgs (.const TagRec [.succ .zero])
      [tagMotive, tagZeroMinor, tagAtMinor, tagIndex, tagMajor]
  let tagCtx := PSC1Kernel.CheckerContext.empty oursTag
  let tagResultType ← exceptToIO
    "PSC1 indexed recursor typecheck"
    (PSC1Kernel.check tagCtx tagRecApp)
  let tagTypeOk ← exceptToIO
    "PSC1 indexed recursor result defeq"
    (PSC1Kernel.isDefEq tagCtx tagResultType natT)
  assertTrue "PSC1 indexed recursor result type mismatch" tagTypeOk
  let oursTagReduced ← exceptToIO
    "PSC1 indexed recursor reduction"
    (PSC1Kernel.whnf tagCtx tagRecApp)
  let leanTagType ←
    match Lean.Kernel.check leanTagEnv ({} : Lean.LocalContext) (toLeanExpr tagRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated Tag recursor application"
  assertTrue "indexed recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr tagResultType) leanTagType)
  let leanTagReduced ← kernelExprWhnf leanTagEnv tagRecApp
  assertTrue "indexed recursor reduction differs from Lean 4.34"
    (toLeanExpr oursTagReduced == leanTagReduced)
  assertTrue "indexed recursor did not pass constructor field to the minor"
    (PSC1Kernel.Expr.eq oursTagReduced tagIndex)

  -- Next K5 slice: non-recursive constructor fields.
  let Box : PSC1Kernel.Name := .str .anonymous "OracleBox"
  let BoxMk : PSC1Kernel.Name := .str Box "mk"
  let BoxRec : PSC1Kernel.Name := .str Box "rec"
  let boxT : PSC1Kernel.Expr := .const Box []
  let boxCtorType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natT boxT .default
  let boxBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursBox ← exceptToIO
    "PSC1 simple inductive constructor-field admission"
    (PSC1Kernel.Kernel.addSimpleInductive boxBase {
      levelParams := []
      name := Box
      type := type1
      ctors := [{ name := BoxMk, type := boxCtorType }]
      isUnsafe := false
    })

  let leanBox0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanBoxNat ←
    match Lean.Kernel.Environment.addDecl leanBox0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected Box oracle Nat axiom"
  let leanBox1 ←
    match Lean.Kernel.Environment.addDecl leanBoxNat {} (.inductDecl [] 0 [{
      name := toLeanName Box
      type := toLeanExpr type1
      ctors := [{ name := toLeanName BoxMk, type := toLeanExpr boxCtorType }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected simple constructor-field oracle"
  let leanBoxEnv := Lean.Environment.ofKernelEnv leanBox1

  for name in [Box, BoxMk, BoxRec] do
    let some oursInfo := oursBox.find? name
      | throw <| IO.userError "PSC1 Box metadata missing"
    let some leanInfo := leanBox1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 Box metadata missing: " ++ (toLeanName name).toString)
    assertTrue
      ("simple constructor-field metadata differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)

  let boxCtx := PSC1Kernel.CheckerContext.empty oursBox
  let boxMotiveName : PSC1Kernel.Name := .str .anonymous "boxMotive"
  let boxMinorName : PSC1Kernel.Name := .str .anonymous "boxMinor"
  let boxMotive : PSC1Kernel.Expr :=
    .lam boxMotiveName boxT natT .default
  let boxMinor : PSC1Kernel.Expr :=
    .lam boxMinorName natT (.bvar 0) .default
  let boxMajor : PSC1Kernel.Expr :=
    .app (.const BoxMk []) (.lit (.nat 41))
  let boxRecApp :=
    PSC1Kernel.applyArgs (.const BoxRec [.succ .zero])
      [boxMotive, boxMinor, boxMajor]
  let boxType ← exceptToIO
    "PSC1 constructor-field recursor typecheck"
    (PSC1Kernel.check boxCtx boxRecApp)
  let boxTypeOk ← exceptToIO
    "PSC1 constructor-field recursor result defeq"
    (PSC1Kernel.isDefEq boxCtx boxType natT)
  assertTrue "PSC1 constructor-field recursor result type mismatch" boxTypeOk
  let oursBoxReduced ← exceptToIO
    "PSC1 constructor-field recursor reduction"
    (PSC1Kernel.whnf boxCtx boxRecApp)
  let leanBoxType ←
    match Lean.Kernel.check leanBoxEnv ({} : Lean.LocalContext) (toLeanExpr boxRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated Box recursor application"
  assertTrue "constructor-field recursor type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr boxType) leanBoxType)
  let leanBoxReduced ← kernelExprWhnf leanBoxEnv boxRecApp
  assertTrue "constructor-field recursor reduction differs from Lean 4.34"
    (toLeanExpr oursBoxReduced == leanBoxReduced)
  assertTrue "constructor-field recursor did not pass the field to the minor"
    (PSC1Kernel.Expr.eq oursBoxReduced (.lit (.nat 41)))

  -- Direct strictly-positive recursive fields generate induction hypotheses
  -- after all constructor fields, and computation rules synthesize recursive
  -- calls internally rather than taking IHs as rule lambda binders.
  let NatLike : PSC1Kernel.Name := .str .anonymous "OracleNatLike"
  let NatLikeZero : PSC1Kernel.Name := .str NatLike "zero"
  let NatLikeSucc : PSC1Kernel.Name := .str NatLike "succ"
  let NatLikeRec : PSC1Kernel.Name := .str NatLike "rec"
  let natLikeT : PSC1Kernel.Expr := .const NatLike []
  let natLikeSuccType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "pred") natLikeT natLikeT .default
  let natLikeBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursNatLike ← exceptToIO
    "PSC1 direct recursive inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive natLikeBase {
      levelParams := []
      name := NatLike
      type := type1
      ctors := [
        { name := NatLikeZero, type := natLikeT },
        { name := NatLikeSucc, type := natLikeSuccType }
      ]
      isUnsafe := false
    })
  let leanNatLike0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNatLikeNat ←
    match Lean.Kernel.Environment.addDecl leanNatLike0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected NatLike oracle Nat axiom"
  let leanNatLike1 ←
    match Lean.Kernel.Environment.addDecl leanNatLikeNat {} (.inductDecl [] 0 [{
      name := toLeanName NatLike
      type := toLeanExpr type1
      ctors := [
        { name := toLeanName NatLikeZero, type := toLeanExpr natLikeT },
        { name := toLeanName NatLikeSucc, type := toLeanExpr natLikeSuccType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected direct recursive inductive oracle"
  let leanNatLikeEnv := Lean.Environment.ofKernelEnv leanNatLike1
  for name in [NatLike, NatLikeZero, NatLikeSucc, NatLikeRec] do
    let some oursInfo := oursNatLike.find? name
      | throw <| IO.userError "PSC1 direct recursive inductive metadata missing"
    let some leanInfo := leanNatLike1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 direct recursive inductive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("direct recursive inductive generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursNatLike.find? NatLike with
  | some (.inductInfo info) =>
      assertTrue "PSC1 direct recursive inductive was not marked recursive"
        info.isRec
      assertTrue "PSC1 direct recursive inductive was incorrectly marked reflexive"
        (!info.isReflexive)
  | _ =>
      throw <| IO.userError "PSC1 direct recursive inductive info missing"
  match leanNatLike1.find? (toLeanName NatLike) with
  | some (.inductInfo info) =>
      assertTrue "Lean 4.34 direct recursive inductive was not marked recursive"
        info.isRec
      assertTrue "Lean 4.34 direct recursive inductive unexpectedly reflexive"
        (!info.isReflexive)
  | _ =>
      throw <| IO.userError "Lean 4.34 direct recursive inductive info missing"

  let natLikeMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "n") natLikeT natT .default
  let natLikeZeroMinor : PSC1Kernel.Expr := .lit (.nat 7)
  let natLikeSuccMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "pred") natLikeT
      (.lam (.str .anonymous "pred_ih") natT (.bvar 0) .default)
      .default
  let natLikeMajor : PSC1Kernel.Expr :=
    .app (.const NatLikeSucc []) (.const NatLikeZero [])
  let natLikeRecApp :=
    PSC1Kernel.applyArgs (.const NatLikeRec [.succ .zero])
      [natLikeMotive, natLikeZeroMinor, natLikeSuccMinor, natLikeMajor]
  let natLikeCtx := PSC1Kernel.CheckerContext.empty oursNatLike
  let natLikeResultType ← exceptToIO
    "PSC1 direct recursive recursor typecheck"
    (PSC1Kernel.check natLikeCtx natLikeRecApp)
  let natLikeTypeOk ← exceptToIO
    "PSC1 direct recursive recursor result defeq"
    (PSC1Kernel.isDefEq natLikeCtx natLikeResultType natT)
  assertTrue "PSC1 direct recursive recursor result type mismatch" natLikeTypeOk
  let oursNatLikeReduced ← exceptToIO
    "PSC1 direct recursive recursor reduction"
    (PSC1Kernel.whnf natLikeCtx natLikeRecApp)
  let leanNatLikeType ←
    match Lean.Kernel.check leanNatLikeEnv ({} : Lean.LocalContext)
        (toLeanExpr natLikeRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated NatLike recursor application"
  assertTrue "direct recursive recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr natLikeResultType) leanNatLikeType)
  let leanNatLikeReduced ← kernelExprWhnf leanNatLikeEnv natLikeRecApp
  assertTrue "direct recursive recursor reduction differs from Lean 4.34"
    (toLeanExpr oursNatLikeReduced == leanNatLikeReduced)
  assertTrue "direct recursive recursor did not feed the recursive hypothesis to the minor"
    (PSC1Kernel.Expr.eq oursNatLikeReduced (.lit (.nat 7)))

  -- Functional recursive fields are Lean "reflexive" datatypes. The IH is
  -- itself a function over the recursive field's non-recursive arguments.
  let Wide : PSC1Kernel.Name := .str .anonymous "OracleWide"
  let WideLeaf : PSC1Kernel.Name := .str Wide "leaf"
  let WideBranch : PSC1Kernel.Name := .str Wide "branch"
  let WideRec : PSC1Kernel.Name := .str Wide "rec"
  let wideT : PSC1Kernel.Expr := .const Wide []
  let wideChildrenType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natT wideT .default
  let wideBranchType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "children") wideChildrenType wideT .default
  let wideBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursWide ← exceptToIO
    "PSC1 functional recursive inductive admission"
    (PSC1Kernel.Kernel.addSimpleInductive wideBase {
      levelParams := []
      name := Wide
      type := type1
      ctors := [
        { name := WideLeaf, type := wideT },
        { name := WideBranch, type := wideBranchType }
      ]
      isUnsafe := false
    })
  let leanWide0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanWideNat ←
    match Lean.Kernel.Environment.addDecl leanWide0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected Wide oracle Nat axiom"
  let leanWide1 ←
    match Lean.Kernel.Environment.addDecl leanWideNat {} (.inductDecl [] 0 [{
      name := toLeanName Wide
      type := toLeanExpr type1
      ctors := [
        { name := toLeanName WideLeaf, type := toLeanExpr wideT },
        { name := toLeanName WideBranch, type := toLeanExpr wideBranchType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected functional recursive inductive oracle"
  let leanWideEnv := Lean.Environment.ofKernelEnv leanWide1
  for name in [Wide, WideLeaf, WideBranch, WideRec] do
    let some oursInfo := oursWide.find? name
      | throw <| IO.userError "PSC1 functional recursive metadata missing"
    let some leanInfo := leanWide1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 functional recursive metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("functional recursive generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursWide.find? Wide with
  | some (.inductInfo info) =>
      assertTrue "PSC1 functional recursive inductive was not marked recursive"
        info.isRec
      assertTrue "PSC1 functional recursive inductive was not marked reflexive"
        info.isReflexive
  | _ =>
      throw <| IO.userError "PSC1 functional recursive inductive info missing"
  match leanWide1.find? (toLeanName Wide) with
  | some (.inductInfo info) =>
      assertTrue "Lean 4.34 functional recursive inductive was not recursive"
        info.isRec
      assertTrue "Lean 4.34 functional recursive inductive was not reflexive"
        info.isReflexive
  | _ =>
      throw <| IO.userError "Lean 4.34 functional recursive inductive info missing"

  let wideMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "w") wideT natT .default
  let wideLeafMinor : PSC1Kernel.Expr := .lit (.nat 5)
  let wideIHType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natT natT .default
  let wideBranchMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "children") wideChildrenType
      (.lam (.str .anonymous "children_ih") wideIHType
        (.app (.bvar 0) (.lit (.nat 0)))
        .default)
      .default
  let wideChildren : PSC1Kernel.Expr :=
    .lam (.str .anonymous "n") natT (.const WideLeaf []) .default
  let wideMajor : PSC1Kernel.Expr :=
    .app (.const WideBranch []) wideChildren
  let wideRecApp :=
    PSC1Kernel.applyArgs (.const WideRec [.succ .zero])
      [wideMotive, wideLeafMinor, wideBranchMinor, wideMajor]
  let wideCtx := PSC1Kernel.CheckerContext.empty oursWide
  let wideResultType ← exceptToIO
    "PSC1 functional recursive recursor typecheck"
    (PSC1Kernel.check wideCtx wideRecApp)
  let wideTypeOk ← exceptToIO
    "PSC1 functional recursive recursor result defeq"
    (PSC1Kernel.isDefEq wideCtx wideResultType natT)
  assertTrue "PSC1 functional recursive recursor result type mismatch" wideTypeOk
  let oursWideReduced ← exceptToIO
    "PSC1 functional recursive recursor reduction"
    (PSC1Kernel.whnf wideCtx wideRecApp)
  let leanWideType ←
    match Lean.Kernel.check leanWideEnv ({} : Lean.LocalContext)
        (toLeanExpr wideRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated Wide recursor application"
  assertTrue "functional recursive recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr wideResultType) leanWideType)
  let leanWideReduced ← kernelExprWhnf leanWideEnv wideRecApp
  assertTrue "functional recursive recursor reduction differs from Lean 4.34"
    (toLeanExpr oursWideReduced == leanWideReduced)
  assertTrue "functional recursive recursor did not generate the functional IH"
    (PSC1Kernel.Expr.eq oursWideReduced (.lit (.nat 5)))

  -- Ordinary mutual recursion: one global motive/minor telescope and
  -- cross-recursive calls between the generated recursors.
  let Even : PSC1Kernel.Name := .str .anonymous "OracleEven"
  let EvenZero : PSC1Kernel.Name := .str Even "zero"
  let EvenSucc : PSC1Kernel.Name := .str Even "succ"
  let EvenRec : PSC1Kernel.Name := .str Even "rec"
  let Odd : PSC1Kernel.Name := .str .anonymous "OracleOdd"
  let OddSucc : PSC1Kernel.Name := .str Odd "succ"
  let OddRec : PSC1Kernel.Name := .str Odd "rec"
  let evenT : PSC1Kernel.Expr := .const Even []
  let oddT : PSC1Kernel.Expr := .const Odd []
  let evenSuccType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "odd") oddT evenT .default
  let oddSuccType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "even") evenT oddT .default
  let mutualBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursMutual ← exceptToIO
    "PSC1 ordinary mutual inductive admission"
    (PSC1Kernel.Kernel.addSimpleMutualInductive mutualBase {
      levelParams := []
      numParams := 0
      types := [
        {
          name := Even
          type := type1
          ctors := [
            { name := EvenZero, type := evenT },
            { name := EvenSucc, type := evenSuccType }
          ]
        },
        {
          name := Odd
          type := type1
          ctors := [
            { name := OddSucc, type := oddSuccType }
          ]
        }
      ]
      isUnsafe := false
    })
  let leanMutual0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanMutualNat ←
    match Lean.Kernel.Environment.addDecl leanMutual0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected mutual oracle Nat axiom"
  let leanMutual1 ←
    match Lean.Kernel.Environment.addDecl leanMutualNat {} (.inductDecl [] 0 [
      {
        name := toLeanName Even
        type := toLeanExpr type1
        ctors := [
          { name := toLeanName EvenZero, type := toLeanExpr evenT },
          { name := toLeanName EvenSucc, type := toLeanExpr evenSuccType }
        ]
      },
      {
        name := toLeanName Odd
        type := toLeanExpr type1
        ctors := [
          { name := toLeanName OddSucc, type := toLeanExpr oddSuccType }
        ]
      }
    ] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected ordinary mutual inductive oracle"
  let leanMutualEnv := Lean.Environment.ofKernelEnv leanMutual1
  for name in [Even, EvenZero, EvenSucc, EvenRec, Odd, OddSucc, OddRec] do
    let some oursInfo := oursMutual.find? name
      | throw <| IO.userError "PSC1 mutual inductive metadata missing"
    let some leanInfo := leanMutual1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 mutual metadata missing: " ++ (toLeanName name).toString)
    assertTrue
      ("mutual generated type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  for name in [Even, Odd] do
    match oursMutual.find? name with
    | some (.inductInfo info) =>
        assertTrue "PSC1 mutual inductive was not marked recursive" info.isRec
        assertTrue "PSC1 direct mutual inductive unexpectedly reflexive"
          (!info.isReflexive)
        assertTrue "PSC1 mutual declaration lost its all-types metadata"
          (info.all.length == 2)
    | _ =>
        throw <| IO.userError "PSC1 mutual inductive info missing"
  for name in [EvenRec, OddRec] do
    match oursMutual.find? name with
    | some (.recInfo info) =>
        assertTrue "PSC1 mutual recursor motive count mismatch"
          (info.numMotives == 2)
        assertTrue "PSC1 mutual recursor minor count mismatch"
          (info.numMinors == 3)
        assertTrue "PSC1 mutual recursor all-types metadata mismatch"
          (info.all.length == 2)
    | _ =>
        throw <| IO.userError "PSC1 mutual recursor info missing"

  let evenMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "even") evenT natT .default
  let oddMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "odd") oddT natT .default
  let evenZeroMinor : PSC1Kernel.Expr := .lit (.nat 61)
  let evenSuccMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "odd") oddT
      (.lam (.str .anonymous "odd_ih") natT (.bvar 0) .default)
      .default
  let oddSuccMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "even") evenT
      (.lam (.str .anonymous "even_ih") natT (.bvar 0) .default)
      .default
  let mutualMajor : PSC1Kernel.Expr :=
    .app (.const EvenSucc [])
      (.app (.const OddSucc []) (.const EvenZero []))
  let mutualRecApp :=
    PSC1Kernel.applyArgs (.const EvenRec [.succ .zero])
      [
        evenMotive, oddMotive,
        evenZeroMinor, evenSuccMinor, oddSuccMinor,
        mutualMajor
      ]
  let mutualCtx := PSC1Kernel.CheckerContext.empty oursMutual
  let mutualResultType ← exceptToIO
    "PSC1 mutual recursor typecheck"
    (PSC1Kernel.check mutualCtx mutualRecApp)
  let mutualTypeOk ← exceptToIO
    "PSC1 mutual recursor result defeq"
    (PSC1Kernel.isDefEq mutualCtx mutualResultType natT)
  assertTrue "PSC1 mutual recursor result type mismatch" mutualTypeOk
  let oursMutualReduced ← exceptToIO
    "PSC1 mutual cross-recursive reduction"
    (PSC1Kernel.whnf mutualCtx mutualRecApp)
  let leanMutualType ←
    match Lean.Kernel.check leanMutualEnv ({} : Lean.LocalContext)
        (toLeanExpr mutualRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated mutual recursor application"
  assertTrue "mutual recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr mutualResultType) leanMutualType)
  let leanMutualReduced ← kernelExprWhnf leanMutualEnv mutualRecApp
  assertTrue "mutual cross-recursive reduction differs from Lean 4.34"
    (toLeanExpr oursMutualReduced == leanMutualReduced)
  assertTrue "mutual cross-recursive hypotheses did not reach the base minor"
    (PSC1Kernel.Expr.eq oursMutualReduced (.lit (.nat 61)))

  -- Negative functional occurrences remain rejected.
  let Bad : PSC1Kernel.Name := .str .anonymous "OracleSimpleBad"
  let BadMk : PSC1Kernel.Name := .str Bad "mk"
  let badExpr : PSC1Kernel.Expr := .const Bad []
  let badFunctionType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "x") badExpr badExpr .default
  let badCtorType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "next") badFunctionType badExpr .default
  match PSC1Kernel.Kernel.addSimpleInductive .empty {
    levelParams := []
    name := Bad
    type := type1
    ctors := [{ name := BadMk, type := badCtorType }]
    isUnsafe := false
  } with
  | .ok _ =>
      throw <| IO.userError "simple inductive admission accepted unsupported functional recursion"
  | .error _ => pure ()

def assertNestedUniformityOracle : IO Unit := do
  -- Lean #14576/#14577: a non-uniform occurrence hidden in a fixed
  -- parameter of a nested outer family must be rejected before preprocessing
  -- can erase that parameter.
  let W : PSC1Kernel.Name := .str .anonymous "OracleUniformW"
  let BadW : PSC1Kernel.Name := .str W "bad"
  let L : PSC1Kernel.Name := .str .anonymous "OracleUniformL"
  let E : PSC1Kernel.Name := .str .anonymous "OracleUniformE"
  let EMk : PSC1Kernel.Name := .str E "mk"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let wT : PSC1Kernel.Expr := .const W []
  let badW : PSC1Kernel.Expr := .const BadW []
  let lType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "α") type1 type1 .default
  let eType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "w") wT type1 .default
  let badNested : PSC1Kernel.Expr :=
    .app (.const L []) (.app (.const E []) badW)
  let eCtorType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "w") wT
      (.forallE (.str .anonymous "l") badNested
        (.app (.const E []) (.bvar 1))
        .default)
      .default

  let base0 :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase W type1
      isUnsafe := false
    })
  let base1 :=
    base0.addUnchecked (.axiomInfo {
      base := mkBase BadW wT
      isUnsafe := false
    })
  let base ← exceptToIO
    "PSC1 nested-uniformity outer-family setup"
    (PSC1Kernel.Kernel.addSimpleInductive base1 {
      levelParams := []
      name := L
      type := lType
      ctors := []
      isUnsafe := false
      numParams := 1
    })

  let oursRejects :=
    match PSC1Kernel.Kernel.addSimpleNestedInductive base {
      levelParams := []
      numParams := 1
      types := [{
        name := E
        type := eType
        ctors := [{ name := EMk, type := eCtorType }]
      }]
      isUnsafe := false
    } with
    | .ok _ => false
    | .error _ => true

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanW ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName W
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean rejected nested-uniformity W axiom"
  let leanBadW ←
    match Lean.Kernel.Environment.addDecl leanW {} (.axiomDecl {
      name := toLeanName BadW
      levelParams := []
      type := toLeanExpr wT
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean rejected nested-uniformity bad W axiom"
  let leanL ←
    match Lean.Kernel.Environment.addDecl leanBadW {} (.inductDecl [] 1 [{
      name := toLeanName L
      type := toLeanExpr lType
      ctors := []
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean rejected nested-uniformity outer family"
  let leanRejects :=
    match Lean.Kernel.Environment.addDecl leanL {} (.inductDecl [] 1 [{
      name := toLeanName E
      type := toLeanExpr eType
      ctors := [{ name := toLeanName EMk, type := toLeanExpr eCtorType }]
    }] false) with
    | .ok _ => false
    | .error _ => true

  assertTrue
    "nested fixed-parameter uniformity rejection differs from Lean 4.34"
    (oursRejects == leanRejects && leanRejects)

def assertNestedReservedNameOracle : IO Unit := do
  -- Lean 4.34 reserves the _nested namespace for temporary types created by
  -- nested-inductive elimination. User declarations must not be able to name
  -- or reference those auxiliaries.
  let Host : PSC1Kernel.Name := .str .anonymous "OracleNestedReserved"
  let HostMk : PSC1Kernel.Name := .str Host "mk"
  let reserved : PSC1Kernel.Name :=
    .str (.str .anonymous "_nested") "OracleNestedReserved_1"
  let hostT : PSC1Kernel.Expr := .const Host []
  let ctorT : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "x") (.const reserved []) hostT .default
  let decl : PSC1Kernel.Kernel.SimpleMutualInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := Host
      type := .sort .zero
      ctors := [{ name := HostMk, type := ctorT }]
    }]
    isUnsafe := false
  }
  match PSC1Kernel.Kernel.addSimpleNestedInductive .empty decl with
  | .ok _ =>
      throw <| IO.userError
        "nested admission accepted a declaration using the reserved _nested namespace"
  | .error _ => pure ()

def assertNestedInductiveAdmissionOracle : IO Unit := do
  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  -- Nested-inductive preprocessing/restoration: Box Tree is replaced by an
  -- auxiliary mutual datatype, checked, then restored to Box Tree while its
  -- auxiliary recursor is published as Tree.rec_1.
  let NestedBox : PSC1Kernel.Name := .str .anonymous "OracleNestedBox"
  let NestedBoxMk : PSC1Kernel.Name := .str NestedBox "mk"
  let Tree : PSC1Kernel.Name := .str .anonymous "OracleNestedTree"
  let TreeLeaf : PSC1Kernel.Name := .str Tree "leaf"
  let TreeNode : PSC1Kernel.Name := .str Tree "node"
  let TreeRec : PSC1Kernel.Name := .str Tree "rec"
  let TreeRec1 : PSC1Kernel.Name := TreeRec.appendIndexAfter 1
  let nestedAlpha : PSC1Kernel.Name := .str .anonymous "α"
  let nestedValue : PSC1Kernel.Name := .str .anonymous "value"
  let nestedBoxType : PSC1Kernel.Expr :=
    .forallE nestedAlpha type1 type1 .default
  let nestedBoxCtorType : PSC1Kernel.Expr :=
    .forallE nestedAlpha type1
      (.forallE nestedValue (.bvar 0)
        (.app (.const NestedBox []) (.bvar 1))
        .default)
      .default
  let treeT : PSC1Kernel.Expr := .const Tree []
  let boxTreeT : PSC1Kernel.Expr :=
    .app (.const NestedBox []) treeT
  let treeNodeType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "children") boxTreeT treeT .default
  let nestedBase :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursNestedBox ← exceptToIO
    "PSC1 nested oracle outer Box admission"
    (PSC1Kernel.Kernel.addSimpleInductive nestedBase {
      levelParams := []
      name := NestedBox
      type := nestedBoxType
      ctors := [{ name := NestedBoxMk, type := nestedBoxCtorType }]
      isUnsafe := false
      numParams := 1
    })
  let oursNested ← exceptToIO
    "PSC1 nested inductive admission"
    (PSC1Kernel.Kernel.addSimpleNestedInductive oursNestedBox {
      levelParams := []
      numParams := 0
      types := [{
        name := Tree
        type := type1
        ctors := [
          { name := TreeLeaf, type := treeT },
          { name := TreeNode, type := treeNodeType }
        ]
      }]
      isUnsafe := false
    })

  let leanNested0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNestedNat ←
    match Lean.Kernel.Environment.addDecl leanNested0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected nested oracle Nat axiom"
  let leanNestedBox ←
    match Lean.Kernel.Environment.addDecl leanNestedNat {} (.inductDecl [] 1 [{
      name := toLeanName NestedBox
      type := toLeanExpr nestedBoxType
      ctors := [{
        name := toLeanName NestedBoxMk
        type := toLeanExpr nestedBoxCtorType
      }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected nested oracle Box"
  let leanNested1 ←
    match Lean.Kernel.Environment.addDecl leanNestedBox {} (.inductDecl [] 0 [{
      name := toLeanName Tree
      type := toLeanExpr type1
      ctors := [
        { name := toLeanName TreeLeaf, type := toLeanExpr treeT },
        { name := toLeanName TreeNode, type := toLeanExpr treeNodeType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected nested Tree oracle"
  let leanNestedEnv := Lean.Environment.ofKernelEnv leanNested1

  for name in [Tree, TreeLeaf, TreeNode, TreeRec, TreeRec1] do
    let some oursInfo := oursNested.find? name
      | throw <| IO.userError (
          "PSC1 restored nested metadata missing: " ++ (toLeanName name).toString)
    let some leanInfo := leanNested1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 restored nested metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("nested restored type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)
  match oursNested.find? Tree with
  | some (.inductInfo info) =>
      assertTrue "PSC1 nested datatype did not record nested families"
        (info.numNested == 1)
  | _ =>
      throw <| IO.userError "PSC1 restored nested inductive info missing"
  match leanNested1.find? (toLeanName Tree) with
  | some (.inductInfo info) =>
      assertTrue "Lean 4.34 nested datatype did not record nested families"
        (info.numNested == 1)
  | _ =>
      throw <| IO.userError "Lean 4.34 restored nested inductive info missing"
  assertTrue "PSC1 leaked a reserved _nested auxiliary declaration"
    (!oursNested.constants.any fun info =>
      PSC1Kernel.Kernel.simpleNestedPrefix.isPrefixOf info.name)

  match oursNested.find? TreeRec with
  | some (.recInfo info) =>
      assertTrue "PSC1 nested main recursor motive count mismatch"
        (info.numMotives == 2)
      assertTrue "PSC1 nested main recursor minor count mismatch"
        (info.numMinors == 3)
  | _ =>
      throw <| IO.userError "PSC1 nested main recursor info missing"
  match oursNested.find? TreeRec1 with
  | some (.recInfo info) =>
      assertTrue "PSC1 restored auxiliary recursor motive count mismatch"
        (info.numMotives == 2)
      assertTrue "PSC1 restored auxiliary recursor minor count mismatch"
        (info.numMinors == 3)
      match info.rules with
      | [rule] =>
          assertTrue "PSC1 restored auxiliary rule did not recover Box.mk"
            (PSC1Kernel.Name.eq rule.ctor NestedBoxMk)
      | _ =>
          throw <| IO.userError "PSC1 restored auxiliary rule count mismatch"
  | _ =>
      throw <| IO.userError "PSC1 restored auxiliary recursor info missing"

  let treeMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "tree") treeT natT .default
  let boxMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "box") boxTreeT natT .default
  let treeLeafMinor : PSC1Kernel.Expr := .lit (.nat 71)
  let treeNodeMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "children") boxTreeT
      (.lam (.str .anonymous "children_ih") natT (.bvar 0) .default)
      .default
  let nestedBoxMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "child") treeT
      (.lam (.str .anonymous "child_ih") natT (.bvar 0) .default)
      .default
  let nestedBoxLeaf : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const NestedBoxMk [])
      [treeT, .const TreeLeaf []]
  let nestedMajor : PSC1Kernel.Expr :=
    .app (.const TreeNode []) nestedBoxLeaf
  let nestedRecApp :=
    PSC1Kernel.applyArgs (.const TreeRec [.succ .zero])
      [
        treeMotive, boxMotive,
        treeLeafMinor, treeNodeMinor, nestedBoxMinor,
        nestedMajor
      ]
  let nestedCtx := PSC1Kernel.CheckerContext.empty oursNested
  let nestedResultType ← exceptToIO
    "PSC1 nested recursor typecheck"
    (PSC1Kernel.check nestedCtx nestedRecApp)
  let nestedTypeOk ← exceptToIO
    "PSC1 nested recursor result defeq"
    (PSC1Kernel.isDefEq nestedCtx nestedResultType natT)
  assertTrue "PSC1 nested recursor result type mismatch" nestedTypeOk
  let oursNestedReduced ← exceptToIO
    "PSC1 nested restored recursor reduction"
    (PSC1Kernel.whnf nestedCtx nestedRecApp)
  let leanNestedType ←
    match Lean.Kernel.check leanNestedEnv ({} : Lean.LocalContext)
        (toLeanExpr nestedRecApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected generated nested recursor application"
  assertTrue "nested recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr nestedResultType) leanNestedType)
  let leanNestedReduced ← kernelExprWhnf leanNestedEnv nestedRecApp
  assertTrue "nested restored recursor reduction differs from Lean 4.34"
    (toLeanExpr oursNestedReduced == leanNestedReduced)
  assertTrue "nested recursion did not traverse Box to the Tree leaf"
    (PSC1Kernel.Expr.eq oursNestedReduced (.lit (.nat 71)))



def assertParameterizedNestedInductiveAdmissionOracle : IO Unit := do
  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)

  let Box : PSC1Kernel.Name := .str .anonymous "OracleParamNestedBox"
  let BoxMk : PSC1Kernel.Name := .str Box "mk"
  let Alpha : PSC1Kernel.Name := .str .anonymous "α"
  let Value : PSC1Kernel.Name := .str .anonymous "value"
  let boxType : PSC1Kernel.Expr :=
    .forallE Alpha type1 type1 .default
  let boxCtorType : PSC1Kernel.Expr :=
    .forallE Alpha type1
      (.forallE Value (.bvar 0)
        (.app (.const Box []) (.bvar 1))
        .default)
      .default

  let Tree : PSC1Kernel.Name := .str .anonymous "OracleParamNestedTree"
  let TreeLeaf : PSC1Kernel.Name := .str Tree "leaf"
  let TreeNode : PSC1Kernel.Name := .str Tree "node"
  let TreeRec : PSC1Kernel.Name := .str Tree "rec"
  let TreeRec1 : PSC1Kernel.Name := TreeRec.appendIndexAfter 1
  let treeType : PSC1Kernel.Expr :=
    .forallE Alpha type1 type1 .default
  let treeAtBvar : PSC1Kernel.Expr :=
    .app (.const Tree []) (.bvar 0)
  let treeLeafType : PSC1Kernel.Expr :=
    .forallE Alpha type1 treeAtBvar .default
  let boxTreeAtBvar : PSC1Kernel.Expr :=
    .app (.const Box []) treeAtBvar
  let treeNodeType : PSC1Kernel.Expr :=
    .forallE Alpha type1
      (.forallE (.str .anonymous "children") boxTreeAtBvar
        (.app (.const Tree []) (.bvar 1))
        .default)
      .default

  let base :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursBox ← exceptToIO
    "PSC1 parameterized nested outer Box admission"
    (PSC1Kernel.Kernel.addSimpleInductive base {
      levelParams := []
      name := Box
      type := boxType
      ctors := [{ name := BoxMk, type := boxCtorType }]
      isUnsafe := false
      numParams := 1
    })
  let ours ← exceptToIO
    "PSC1 parameterized nested Tree admission"
    (PSC1Kernel.Kernel.addSimpleNestedInductive oursBox {
      levelParams := []
      numParams := 1
      types := [{
        name := Tree
        type := treeType
        ctors := [
          { name := TreeLeaf, type := treeLeafType },
          { name := TreeNode, type := treeNodeType }
        ]
      }]
      isUnsafe := false
    })

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNat ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected parameterized nested Nat axiom"
  let leanBox ←
    match Lean.Kernel.Environment.addDecl leanNat {} (.inductDecl [] 1 [{
      name := toLeanName Box
      type := toLeanExpr boxType
      ctors := [{
        name := toLeanName BoxMk
        type := toLeanExpr boxCtorType
      }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected parameterized nested Box"
  let lean1 ←
    match Lean.Kernel.Environment.addDecl leanBox {} (.inductDecl [] 1 [{
      name := toLeanName Tree
      type := toLeanExpr treeType
      ctors := [
        { name := toLeanName TreeLeaf, type := toLeanExpr treeLeafType },
        { name := toLeanName TreeNode, type := toLeanExpr treeNodeType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected parameterized nested Tree"
  let leanEnv := Lean.Environment.ofKernelEnv lean1

  for name in [Tree, TreeLeaf, TreeNode, TreeRec, TreeRec1] do
    let some oursInfo := ours.find? name
      | throw <| IO.userError (
          "PSC1 parameterized nested metadata missing: " ++
          (toLeanName name).toString)
    let some leanInfo := lean1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 parameterized nested metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("parameterized nested type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)

  match ours.find? Tree with
  | some (.inductInfo info) =>
      assertTrue "parameterized nested numParams mismatch"
        (info.numParams == 1)
      assertTrue "parameterized nested numNested mismatch"
        (info.numNested == 1)
  | _ =>
      throw <| IO.userError "PSC1 parameterized nested inductive info missing"

  assertTrue "parameterized nested admission leaked _nested auxiliaries"
    (!ours.constants.any fun info =>
      PSC1Kernel.Kernel.simpleNestedPrefix.isPrefixOf info.name)

  let treeNat : PSC1Kernel.Expr :=
    .app (.const Tree []) natT
  let boxTreeNat : PSC1Kernel.Expr :=
    .app (.const Box []) treeNat
  let treeMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "tree") treeNat natT .default
  let boxMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "box") boxTreeNat natT .default
  let leafMinor : PSC1Kernel.Expr := .lit (.nat 73)
  let nodeMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "children") boxTreeNat
      (.lam (.str .anonymous "children_ih") natT (.bvar 0) .default)
      .default
  let boxMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "child") treeNat
      (.lam (.str .anonymous "child_ih") natT (.bvar 0) .default)
      .default
  let leaf : PSC1Kernel.Expr :=
    .app (.const TreeLeaf []) natT
  let boxedLeaf : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const BoxMk [])
      [treeNat, leaf]
  let major : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const TreeNode [])
      [natT, boxedLeaf]
  let recApp :=
    PSC1Kernel.applyArgs (.const TreeRec [.succ .zero])
      [
        natT,
        treeMotive, boxMotive,
        leafMinor, nodeMinor, boxMinor,
        major
      ]
  let ctx := PSC1Kernel.CheckerContext.empty ours
  let resultType ← exceptToIO
    "PSC1 parameterized nested recursor typecheck"
    (PSC1Kernel.check ctx recApp)
  let resultTypeOk ← exceptToIO
    "PSC1 parameterized nested recursor result defeq"
    (PSC1Kernel.isDefEq ctx resultType natT)
  assertTrue "parameterized nested recursor result type mismatch"
    resultTypeOk
  let oursReduced ← exceptToIO
    "PSC1 parameterized nested recursor reduction"
    (PSC1Kernel.whnf ctx recApp)
  let leanType ←
    match Lean.Kernel.check leanEnv ({} : Lean.LocalContext)
        (toLeanExpr recApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected parameterized nested recursor application"
  assertTrue "parameterized nested recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr resultType) leanType)
  let leanReduced ← kernelExprWhnf leanEnv recApp
  assertTrue "parameterized nested recursor reduction differs from Lean 4.34"
    (toLeanExpr oursReduced == leanReduced)
  assertTrue "parameterized nested recursion did not reach leaf minor"
    (PSC1Kernel.Expr.eq oursReduced (.lit (.nat 73)))

def assertUniverseNestedInductiveAdmissionOracle : IO Unit := do
  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)

  let u : PSC1Kernel.Name := .str .anonymous "u"
  let v : PSC1Kernel.Name := .str .anonymous "v"
  let U : PSC1Kernel.Level := .param u
  let V : PSC1Kernel.Level := .param v

  let Box : PSC1Kernel.Name := .str .anonymous "OracleUniverseNestedBox"
  let BoxMk : PSC1Kernel.Name := .str Box "mk"
  let Beta : PSC1Kernel.Name := .str .anonymous "β"
  let boxType : PSC1Kernel.Expr :=
    .forallE Beta (.sort V) (.sort V) .default
  let boxCtorType : PSC1Kernel.Expr :=
    .forallE Beta (.sort V)
      (.forallE (.str .anonymous "value") (.bvar 0)
        (.app (.const Box [V]) (.bvar 1))
        .default)
      .default

  let Tree : PSC1Kernel.Name := .str .anonymous "OracleUniverseNestedTree"
  let TreeLeaf : PSC1Kernel.Name := .str Tree "leaf"
  let TreeNode : PSC1Kernel.Name := .str Tree "node"
  let TreeRec : PSC1Kernel.Name := .str Tree "rec"
  let TreeRec1 : PSC1Kernel.Name := TreeRec.appendIndexAfter 1
  let Alpha : PSC1Kernel.Name := .str .anonymous "α"
  let treeType : PSC1Kernel.Expr :=
    .forallE Alpha (.sort U) (.sort (.succ U)) .default
  let treeAtBvar : PSC1Kernel.Expr :=
    .app (.const Tree [U]) (.bvar 0)
  let treeLeafType : PSC1Kernel.Expr :=
    .forallE Alpha (.sort U) treeAtBvar .default
  let boxTreeAtBvar : PSC1Kernel.Expr :=
    .app (.const Box [.succ U]) treeAtBvar
  let treeNodeType : PSC1Kernel.Expr :=
    .forallE Alpha (.sort U)
      (.forallE (.str .anonymous "children") boxTreeAtBvar
        (.app (.const Tree [U]) (.bvar 1))
        .default)
      .default

  let base :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursBox ← exceptToIO
    "PSC1 universe-nested outer Box admission"
    (PSC1Kernel.Kernel.addSimpleInductive base {
      levelParams := [v]
      name := Box
      type := boxType
      ctors := [{ name := BoxMk, type := boxCtorType }]
      isUnsafe := false
      numParams := 1
    })
  let ours ← exceptToIO
    "PSC1 universe-polymorphic nested Tree admission"
    (PSC1Kernel.Kernel.addSimpleNestedInductive oursBox {
      levelParams := [u]
      numParams := 1
      types := [{
        name := Tree
        type := treeType
        ctors := [
          { name := TreeLeaf, type := treeLeafType },
          { name := TreeNode, type := treeNodeType }
        ]
      }]
      isUnsafe := false
    })

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNat ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected universe-nested Nat axiom"
  let leanBox ←
    match Lean.Kernel.Environment.addDecl leanNat {} (.inductDecl [toLeanName v] 1 [{
      name := toLeanName Box
      type := toLeanExpr boxType
      ctors := [{
        name := toLeanName BoxMk
        type := toLeanExpr boxCtorType
      }]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected universe-nested Box"
  let lean1 ←
    match Lean.Kernel.Environment.addDecl leanBox {} (.inductDecl [toLeanName u] 1 [{
      name := toLeanName Tree
      type := toLeanExpr treeType
      ctors := [
        { name := toLeanName TreeLeaf, type := toLeanExpr treeLeafType },
        { name := toLeanName TreeNode, type := toLeanExpr treeNodeType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected universe-polymorphic nested Tree"
  let leanEnv := Lean.Environment.ofKernelEnv lean1

  for name in [Tree, TreeLeaf, TreeNode, TreeRec, TreeRec1] do
    let some oursInfo := ours.find? name
      | throw <| IO.userError (
          "PSC1 universe-nested metadata missing: " ++
          (toLeanName name).toString)
    let some leanInfo := lean1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 universe-nested metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("universe-nested type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)

  match ours.find? Tree with
  | some (.inductInfo info) =>
      assertTrue "universe-nested level parameter count mismatch"
        (info.base.levelParams.length == 1)
      assertTrue "universe-nested numNested mismatch"
        (info.numNested == 1)
  | _ =>
      throw <| IO.userError "PSC1 universe-nested inductive info missing"

  let one : PSC1Kernel.Level := .succ .zero
  let two : PSC1Kernel.Level := .succ one
  let treeNat : PSC1Kernel.Expr :=
    .app (.const Tree [one]) natT
  let boxTreeNat : PSC1Kernel.Expr :=
    .app (.const Box [two]) treeNat
  let treeMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "tree") treeNat natT .default
  let boxMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "box") boxTreeNat natT .default
  let leafMinor : PSC1Kernel.Expr := .lit (.nat 79)
  let nodeMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "children") boxTreeNat
      (.lam (.str .anonymous "children_ih") natT (.bvar 0) .default)
      .default
  let boxMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "child") treeNat
      (.lam (.str .anonymous "child_ih") natT (.bvar 0) .default)
      .default
  let leaf : PSC1Kernel.Expr :=
    .app (.const TreeLeaf [one]) natT
  let boxedLeaf : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const BoxMk [two])
      [treeNat, leaf]
  let major : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const TreeNode [one])
      [natT, boxedLeaf]
  let recApp :=
    PSC1Kernel.applyArgs (.const TreeRec [one, one])
      [
        natT,
        treeMotive, boxMotive,
        leafMinor, nodeMinor, boxMinor,
        major
      ]
  let ctx := PSC1Kernel.CheckerContext.empty ours
  let resultType ← exceptToIO
    "PSC1 universe-nested recursor typecheck"
    (PSC1Kernel.check ctx recApp)
  let resultTypeOk ← exceptToIO
    "PSC1 universe-nested recursor result defeq"
    (PSC1Kernel.isDefEq ctx resultType natT)
  assertTrue "PSC1 universe-nested recursor result type mismatch"
    resultTypeOk
  let oursReduced ← exceptToIO
    "PSC1 universe-nested recursor reduction"
    (PSC1Kernel.whnf ctx recApp)
  let leanType ←
    match Lean.Kernel.check leanEnv ({} : Lean.LocalContext)
        (toLeanExpr recApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected universe-nested recursor application"
  assertTrue "universe-nested recursor result type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr resultType) leanType)
  let leanReduced ← kernelExprWhnf leanEnv recApp
  assertTrue "universe-nested recursor reduction differs from Lean 4.34"
    (toLeanExpr oursReduced == leanReduced)
  assertTrue "universe-nested recursion did not reach leaf minor"
    (PSC1Kernel.Expr.eq oursReduced (.lit (.nat 79)))

def assertOuterMutualNestedInductiveAdmissionOracle : IO Unit := do
  let NatN : PSC1Kernel.Name := PSC1Kernel.kernelNatName
  let natT : PSC1Kernel.Expr := .const NatN []
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)

  let EvenBox : PSC1Kernel.Name := .str .anonymous "OracleOuterEvenBox"
  let EvenMk : PSC1Kernel.Name := .str EvenBox "mk"
  let OddBox : PSC1Kernel.Name := .str .anonymous "OracleOuterOddBox"
  let OddMk : PSC1Kernel.Name := .str OddBox "mk"
  let Alpha : PSC1Kernel.Name := .str .anonymous "α"
  let evenType : PSC1Kernel.Expr :=
    .forallE Alpha type1 type1 .default
  let oddType : PSC1Kernel.Expr :=
    .forallE Alpha type1 type1 .default
  let evenCtorType : PSC1Kernel.Expr :=
    .forallE Alpha type1
      (.forallE (.str .anonymous "odd")
        (.app (.const OddBox []) (.bvar 0))
        (.app (.const EvenBox []) (.bvar 1))
        .default)
      .default
  let oddCtorType : PSC1Kernel.Expr :=
    .forallE Alpha type1
      (.forallE (.str .anonymous "value") (.bvar 0)
        (.app (.const OddBox []) (.bvar 1))
        .default)
      .default

  let Tree : PSC1Kernel.Name := .str .anonymous "OracleOuterMutualTree"
  let TreeLeaf : PSC1Kernel.Name := .str Tree "leaf"
  let TreeNode : PSC1Kernel.Name := .str Tree "node"
  let TreeRec : PSC1Kernel.Name := .str Tree "rec"
  let TreeRec1 : PSC1Kernel.Name := TreeRec.appendIndexAfter 1
  let TreeRec2 : PSC1Kernel.Name := TreeRec.appendIndexAfter 2
  let treeT : PSC1Kernel.Expr := .const Tree []
  let evenTreeT : PSC1Kernel.Expr :=
    .app (.const EvenBox []) treeT
  let treeNodeType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "children") evenTreeT treeT .default

  let base :=
    PSC1Kernel.Environment.empty.addUnchecked (.axiomInfo {
      base := mkBase NatN type1
      isUnsafe := false
    })
  let oursOuter ← exceptToIO
    "PSC1 nested outer mutual family admission"
    (PSC1Kernel.Kernel.addSimpleMutualInductive base {
      levelParams := []
      numParams := 1
      types := [
        {
          name := EvenBox
          type := evenType
          ctors := [{ name := EvenMk, type := evenCtorType }]
        },
        {
          name := OddBox
          type := oddType
          ctors := [{ name := OddMk, type := oddCtorType }]
        }
      ]
      isUnsafe := false
    })
  let ours ← exceptToIO
    "PSC1 outer-mutual nested Tree admission"
    (PSC1Kernel.Kernel.addSimpleNestedInductive oursOuter {
      levelParams := []
      numParams := 0
      types := [{
        name := Tree
        type := type1
        ctors := [
          { name := TreeLeaf, type := treeT },
          { name := TreeNode, type := treeNodeType }
        ]
      }]
      isUnsafe := false
    })

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanNat ←
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName NatN
      levelParams := []
      type := toLeanExpr type1
      isUnsafe := false
    }) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected outer-mutual nested Nat axiom"
  let leanOuter ←
    match Lean.Kernel.Environment.addDecl leanNat {} (.inductDecl [] 1 [
      {
        name := toLeanName EvenBox
        type := toLeanExpr evenType
        ctors := [{ name := toLeanName EvenMk, type := toLeanExpr evenCtorType }]
      },
      {
        name := toLeanName OddBox
        type := toLeanExpr oddType
        ctors := [{ name := toLeanName OddMk, type := toLeanExpr oddCtorType }]
      }
    ] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected outer mutual family"
  let lean1 ←
    match Lean.Kernel.Environment.addDecl leanOuter {} (.inductDecl [] 0 [{
      name := toLeanName Tree
      type := toLeanExpr type1
      ctors := [
        { name := toLeanName TreeLeaf, type := toLeanExpr treeT },
        { name := toLeanName TreeNode, type := toLeanExpr treeNodeType }
      ]
    }] false) with
    | .ok env => pure env
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected outer-mutual nested Tree"
  let leanEnv := Lean.Environment.ofKernelEnv lean1

  for name in [Tree, TreeLeaf, TreeNode, TreeRec, TreeRec1, TreeRec2] do
    let some oursInfo := ours.find? name
      | throw <| IO.userError (
          "PSC1 outer-mutual nested metadata missing: " ++
          (toLeanName name).toString)
    let some leanInfo := lean1.find? (toLeanName name)
      | throw <| IO.userError (
          "Lean 4.34 outer-mutual nested metadata missing: " ++
          (toLeanName name).toString)
    assertTrue
      ("outer-mutual nested type differs from Lean 4.34 at " ++
        (toLeanName name).toString)
      (Lean.Expr.eqv (toLeanExpr oursInfo.type) leanInfo.type)

  match ours.find? Tree with
  | some (.inductInfo info) =>
      assertTrue "outer-mutual nested numNested mismatch"
        (info.numNested == 2)
  | _ =>
      throw <| IO.userError "PSC1 outer-mutual nested inductive info missing"

  match ours.find? TreeRec with
  | some (.recInfo info) =>
      assertTrue "outer-mutual nested main recursor motive count mismatch"
        (info.numMotives == 3)
      assertTrue "outer-mutual nested main recursor minor count mismatch"
        (info.numMinors == 4)
  | _ =>
      throw <| IO.userError "PSC1 outer-mutual nested main recursor missing"

  match ours.find? TreeRec1 with
  | some (.recInfo info) =>
      match info.rules with
      | [rule] =>
          assertTrue "first restored outer-mutual auxiliary rule ctor mismatch"
            (PSC1Kernel.Name.eq rule.ctor EvenMk)
      | _ =>
          throw <| IO.userError "first outer-mutual auxiliary rule count mismatch"
  | _ =>
      throw <| IO.userError "first outer-mutual auxiliary recursor missing"

  match ours.find? TreeRec2 with
  | some (.recInfo info) =>
      match info.rules with
      | [rule] =>
          assertTrue "second restored outer-mutual auxiliary rule ctor mismatch"
            (PSC1Kernel.Name.eq rule.ctor OddMk)
      | _ =>
          throw <| IO.userError "second outer-mutual auxiliary rule count mismatch"
  | _ =>
      throw <| IO.userError "second outer-mutual auxiliary recursor missing"

  assertTrue "outer-mutual nested admission leaked _nested auxiliaries"
    (!ours.constants.any fun info =>
      PSC1Kernel.Kernel.simpleNestedPrefix.isPrefixOf info.name)

  let oddTreeT : PSC1Kernel.Expr :=
    .app (.const OddBox []) treeT
  let treeMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "tree") treeT natT .default
  let evenMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "even") evenTreeT natT .default
  let oddMotive : PSC1Kernel.Expr :=
    .lam (.str .anonymous "odd") oddTreeT natT .default
  let leafMinor : PSC1Kernel.Expr := .lit (.nat 83)
  let nodeMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "children") evenTreeT
      (.lam (.str .anonymous "children_ih") natT (.bvar 0) .default)
      .default
  let evenMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "odd") oddTreeT
      (.lam (.str .anonymous "odd_ih") natT (.bvar 0) .default)
      .default
  let oddMinor : PSC1Kernel.Expr :=
    .lam (.str .anonymous "tree") treeT
      (.lam (.str .anonymous "tree_ih") natT (.bvar 0) .default)
      .default
  let leaf : PSC1Kernel.Expr := .const TreeLeaf []
  let oddLeaf : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const OddMk []) [treeT, leaf]
  let evenOddLeaf : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const EvenMk []) [treeT, oddLeaf]
  let major : PSC1Kernel.Expr :=
    .app (.const TreeNode []) evenOddLeaf
  let recApp :=
    PSC1Kernel.applyArgs (.const TreeRec [.succ .zero])
      [
        treeMotive, evenMotive, oddMotive,
        leafMinor, nodeMinor, evenMinor, oddMinor,
        major
      ]
  let ctx := PSC1Kernel.CheckerContext.empty ours
  let resultType ← exceptToIO
    "PSC1 outer-mutual nested recursor typecheck"
    (PSC1Kernel.check ctx recApp)
  let resultTypeOk ← exceptToIO
    "PSC1 outer-mutual nested recursor result defeq"
    (PSC1Kernel.isDefEq ctx resultType natT)
  assertTrue "PSC1 outer-mutual nested recursor result type mismatch"
    resultTypeOk
  let oursReduced ← exceptToIO
    "PSC1 outer-mutual nested recursor reduction"
    (PSC1Kernel.whnf ctx recApp)
  let leanType ←
    match Lean.Kernel.check leanEnv ({} : Lean.LocalContext)
        (toLeanExpr recApp) with
    | .ok ty => pure ty
    | .error _ =>
        throw <| IO.userError "Lean 4.34 rejected outer-mutual nested recursor application"
  assertTrue "outer-mutual nested recursor type differs from Lean 4.34"
    (Lean.Expr.eqv (toLeanExpr resultType) leanType)
  let leanReduced ← kernelExprWhnf leanEnv recApp
  assertTrue "outer-mutual nested reduction differs from Lean 4.34"
    (toLeanExpr oursReduced == leanReduced)
  assertTrue "outer-mutual nested recursion did not reach leaf minor"
    (PSC1Kernel.Expr.eq oursReduced (.lit (.nat 83)))

def assertLetTypeClosureOracle : IO Unit := do
  let h : PSC1Kernel.Name := .str .anonymous "letClosureH"
  let A : PSC1Kernel.Name := .str .anonymous "letClosureA"
  let x : PSC1Kernel.Name := .str .anonymous "letClosureX"
  let prop : PSC1Kernel.Expr := .sort .zero
  let type : PSC1Kernel.Expr := .sort (.succ .zero)
  let term : PSC1Kernel.Expr :=
    .lam h prop
      (.letE A type prop
        (.lam x (.bvar 0) (.bvar 0) .default)
        false)
      .default
  let ctx := PSC1Kernel.CheckerContext.empty .empty
  let inferred ← exceptToIO
    "PSC1 let-local inferred-type closure"
    (PSC1Kernel.check ctx term)
  match inferred with
  | .forallE _ _ (.letE _ _ _ _ _) _ => pure ()
  | _ =>
      throw <| IO.userError
        "let-local inferred type escaped its closing let binder"
  let expected : PSC1Kernel.Expr :=
    .forallE h prop
      (.forallE x prop prop .default)
      .default
  let ok ← exceptToIO
    "PSC1 closed let-local type defeq"
    (PSC1Kernel.isDefEq ctx inferred expected)
  assertTrue "closed let-local inferred type is not definitionally correct" ok

def assertReplayCoreOracle : IO Unit := do
  let metaRecord : PSC1Kernel.Replay.Record :=
    .metaR {
      leanVersion := PSC1Kernel.Replay.pinnedLeanVersion
      leanGitHash := PSC1Kernel.Replay.pinnedLeanGitHash
      formatVersion := PSC1Kernel.Replay.supportedFormatVersion
    }

  -- Metadata is mandatory and identity-pinned.
  match PSC1Kernel.Replay.State.empty.replay
      (.nameR { index := 1, node := .str 0 "Bad" }) with
  | .ok _ =>
      throw <| IO.userError "replay accepted a pre-metadata record"
  | .error _ => pure ()
  match PSC1Kernel.Replay.State.empty.replay
      (.metaR {
        leanVersion := PSC1Kernel.Replay.pinnedLeanVersion
        leanGitHash := "wrong"
        formatVersion := PSC1Kernel.Replay.supportedFormatVersion
      }) with
  | .ok _ =>
      throw <| IO.userError "replay accepted a wrong Lean git hash"
  | .error _ => pure ()

  let records : List PSC1Kernel.Replay.Record := [
    metaRecord,

    -- Sparse Name table entries are legal as long as references are defined.
    .nameR { index := 1, node := .str 0 "ReplayA" },
    .nameR { index := 3, node := .str 0 "x" },
    .nameR { index := 5, node := .str 0 "ReplayId" },
    .nameR { index := 7, node := .str 0 "ReplayF" },
    .nameR { index := 9, node := .str 0 "ReplayG" },
    .nameR { index := 11, node := .str 0 "ReplayFlag" },
    .nameR { index := 13, node := .str 11 "off" },
    .nameR { index := 15, node := .str 11 "on" },

    .levelR { index := 2, node := .succ 0 },

    -- 20: Type, 22: A, 24: #0, 26: A -> A, 28: fun x => x
    .exprR { index := 20, node := .sort 2 },
    .exprR { index := 22, node := .const 1 [] },
    .exprR { index := 24, node := .bvar 0 },
    .exprR {
      index := 26
      node := .forallE 3 22 22 .default
    },
    .exprR {
      index := 28
      node := .lam 3 22 24 .default
    },

    .axiomR {
      name := 1
      levelParams := []
      type := 20
      isUnsafe := false
    },
    .definitionR {
      name := 5
      levelParams := []
      type := 26
      value := 28
      hints := .regular 0
      safety := .safe
      all := []
    },

    -- Mutual unsafe definitions:
    -- f x := g x, g x := f x.
    .exprR { index := 30, node := .const 7 [] },
    .exprR { index := 32, node := .const 9 [] },
    .exprR { index := 34, node := .app 32 24 },
    .exprR { index := 36, node := .lam 3 22 34 .default },
    .exprR { index := 38, node := .app 30 24 },
    .exprR { index := 40, node := .lam 3 22 38 .default },
    .definitionR {
      name := 7
      levelParams := []
      type := 26
      value := 36
      hints := .regular 1
      safety := .unsafeDef
      all := [7, 9]
    },
    .definitionR {
      name := 9
      levelParams := []
      type := 26
      value := 40
      hints := .regular 1
      safety := .unsafeDef
      all := [7, 9]
    },

    -- Flag : Type with two nullary constructors. Replay regenerates Flag.rec.
    .exprR { index := 42, node := .const 11 [] },
    .inductiveR {
      levelParams := []
      numParams := 0
      types := [{
        name := 11
        type := 20
        ctors := [
          { name := 13, type := 42 },
          { name := 15, type := 42 }
        ]
      }]
      isUnsafe := false
      numNested := 0
    }
  ]

  let final ← exceptToIO
    "PSC1 typed Lean4Export replay"
    (PSC1Kernel.Replay.replayAll PSC1Kernel.Replay.State.empty records)
  let stats ← exceptToIO
    "PSC1 replay finish"
    final.finish
  assertTrue "replay declaration count mismatch"
    (stats.declarations == 5)
  assertTrue "replay sparse Name count mismatch"
    (stats.names == 8)
  assertTrue "replay Level count mismatch"
    (stats.levels == 1)
  assertTrue "replay Expr count mismatch"
    (stats.expressions == 12)

  let A : PSC1Kernel.Name := .str .anonymous "ReplayA"
  let Id : PSC1Kernel.Name := .str .anonymous "ReplayId"
  let F : PSC1Kernel.Name := .str .anonymous "ReplayF"
  let G : PSC1Kernel.Name := .str .anonymous "ReplayG"
  let Flag : PSC1Kernel.Name := .str .anonymous "ReplayFlag"
  let Off : PSC1Kernel.Name := .str Flag "off"
  let On : PSC1Kernel.Name := .str Flag "on"
  let Rec : PSC1Kernel.Name := .str Flag "rec"
  for name in [A, Id, F, G, Flag, Off, On, Rec] do
    assertTrue "replay omitted an admitted declaration"
      (final.env.contains name)

  -- Stop immediately after the first mutual definition to verify finish
  -- rejects an incomplete exported group.
  let pendingRecords := records.take 24
  let pending ← exceptToIO
    "PSC1 pending mutual replay setup"
    (let rec go
        (state : PSC1Kernel.Replay.State)
        (items : List PSC1Kernel.Replay.Record) :
        Except String PSC1Kernel.Replay.State := do
      match items with
      | [] => pure state
      | item :: rest => go (← state.replay item) rest
     go PSC1Kernel.Replay.State.empty pendingRecords)
  match pending.finish with
  | .ok _ =>
      throw <| IO.userError "replay finish accepted an incomplete mutual group"
  | .error _ => pure ()

def assertReplayJsonOracle : IO Unit := do
  let metaLine :=
    "{\"meta\":{\"lean\":{\"version\":\"4.34.0\",\"githash\":\"" ++
      PSC1Kernel.Replay.pinnedLeanGitHash ++
      "\"},\"format\":{\"version\":\"3.1.0\"}}}"
  let nameLine :=
    "{\"in\":1,\"str\":{\"pre\":0,\"str\":\"ReplayJsonA\"}}"
  let levelLine := "{\"il\":2,\"succ\":0}"
  let exprLine := "{\"ie\":20,\"sort\":2}"
  let axiomLine :=
    "{\"axiom\":{\"name\":1,\"levelParams\":[],\"type\":20,\"isUnsafe\":false}}"
  let final ← exceptToIO
    "PSC1 Lean4Export NDJSON replay"
    (PSC1Kernel.ReplayJson.replayLines
      PSC1Kernel.Replay.State.empty
      [metaLine, "", nameLine, levelLine, exprLine, axiomLine])
  let stats ← exceptToIO
    "PSC1 Lean4Export NDJSON finish"
    final.finish
  assertTrue "NDJSON replay declaration count mismatch"
    (stats.declarations == 1)
  assertTrue "NDJSON replay Name count mismatch"
    (stats.names == 1)
  assertTrue "NDJSON replay Level count mismatch"
    (stats.levels == 1)
  assertTrue "NDJSON replay Expr count mismatch"
    (stats.expressions == 1)
  let A : PSC1Kernel.Name := .str .anonymous "ReplayJsonA"
  assertTrue "NDJSON replay omitted admitted axiom"
    (final.env.contains A)

  -- Arena regression: valid sparse/out-of-order intern IDs must be
  -- accepted and promoted into the dense prefix when the missing IDs arrive.
  let sparseName2 :=
    "{\"in\":2,\"str\":{\"pre\":0,\"str\":\"SparseTwo\"}}"
  let sparseName1 :=
    "{\"in\":1,\"str\":{\"pre\":0,\"str\":\"SparseOne\"}}"
  let sparseLevel2 := "{\"il\":2,\"succ\":0}"
  let sparseLevel1 := "{\"il\":1,\"succ\":0}"
  let sparseExpr2 := "{\"ie\":2,\"sort\":2}"
  let sparseExpr0 := "{\"ie\":0,\"sort\":1}"
  let sparseExpr1 := "{\"ie\":1,\"sort\":0}"
  let sparse ← exceptToIO
    "PSC1 sparse/out-of-order NDJSON replay"
    (PSC1Kernel.ReplayJson.replayLines
      PSC1Kernel.Replay.State.empty
      [
        metaLine,
        sparseName2, sparseName1,
        sparseLevel2, sparseLevel1,
        sparseExpr2, sparseExpr0, sparseExpr1
      ])
  let sparseStats ← exceptToIO
    "PSC1 sparse/out-of-order replay finish"
    sparse.finish
  assertTrue "sparse replay Name count mismatch" (sparseStats.names == 2)
  assertTrue "sparse replay Level count mismatch" (sparseStats.levels == 2)
  assertTrue "sparse replay Expr count mismatch" (sparseStats.expressions == 3)
  let sparseOne : PSC1Kernel.Name := .str .anonymous "SparseOne"
  let sparseTwo : PSC1Kernel.Name := .str .anonymous "SparseTwo"
  assertTrue "out-of-order Name id 1 was not promoted correctly"
    (match sparse.names.get? 1 with
     | some got => PSC1Kernel.Name.eq got sparseOne
     | none => false)
  assertTrue "out-of-order Name id 2 was not retained correctly"
    (match sparse.names.get? 2 with
     | some got => PSC1Kernel.Name.eq got sparseTwo
     | none => false)
  assertTrue "out-of-order Expr id 2 was not retained correctly"
    ((sparse.exprs.get? 2).isSome)

  let duplicateTop :=
    "{\"in\":1,\"in\":2,\"str\":{\"pre\":0,\"str\":\"Dup\"}}"
  match PSC1Kernel.ReplayJson.decodeLine duplicateTop with
  | .ok _ =>
      throw <| IO.userError "NDJSON decoder accepted duplicate top-level JSON keys"
  | .error _ => pure ()

  let duplicateNested :=
    "{\"meta\":{\"lean\":{\"version\":\"4.34.0\",\"version\":\"4.34.0\",\"githash\":\"" ++
      PSC1Kernel.Replay.pinnedLeanGitHash ++
      "\"},\"format\":{\"version\":\"3.1.0\"}}}"
  match PSC1Kernel.ReplayJson.decodeLine duplicateNested with
  | .ok _ =>
      throw <| IO.userError "NDJSON decoder accepted duplicate nested JSON keys"
  | .error _ => pure ()

  let ambiguous :=
    "{\"in\":1,\"il\":2,\"str\":{\"pre\":0,\"str\":\"Ambiguous\"},\"succ\":0}"
  match PSC1Kernel.ReplayJson.decodeLine ambiguous with
  | .ok _ =>
      throw <| IO.userError "NDJSON decoder accepted multiple record kinds on one line"
  | .error _ => pure ()

  match PSC1Kernel.ReplayJson.decodeLine "{\"unknown\":true}" with
  | .ok _ =>
      throw <| IO.userError "NDJSON decoder accepted an unknown record kind"
  | .error _ => pure ()

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
  let env4 := env3.addUnchecked (.recInfo {
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
  let Major : PSC1Kernel.Name := .str Flag "major"
  let env := env4.addUnchecked (.defnInfo {
    base := mkBase Major flagExpr
    value := .const On []
    hints := .regular 0
    safety := .safe
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
  let onViaDefinition :=
    PSC1Kernel.applyArgs (.const Rec [.zero])
      [motive, offMinor, onMinor, .const Major []]

  -- Final Lean 4.34 separates cheap_rec from cheap_proj. A cheap recursor
  -- leaves the delta-reducible major stuck, while cheap projection alone
  -- must not suppress recursor-major delta reduction.
  let recCheap ← exceptToIO
    "PSC1 cheap-rec control"
    (PSC1Kernel.whnfCore ctx onViaDefinition true true)
  assertTrue "cheap_rec unexpectedly delta-reduced the recursor major"
    (PSC1Kernel.Expr.eq recCheap onViaDefinition)
  let projOnlyCheap ← exceptToIO
    "PSC1 cheap-proj-only control"
    (PSC1Kernel.whnfCore ctx onViaDefinition false true)
  assertTrue "cheap_proj incorrectly enabled cheap_rec behavior"
    (PSC1Kernel.Expr.eq projOnlyCheap onMinor)

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


def assertNatLiteralRecursorOracle : IO Unit := do
  let NatN := PSC1Kernel.kernelNatName
  let Zero := PSC1Kernel.kernelNatZeroName
  let Succ := PSC1Kernel.kernelNatSuccName
  let Rec : PSC1Kernel.Name := .str NatN "rec"
  let u : PSC1Kernel.Name := .str .anonymous "u"
  let natType : PSC1Kernel.Expr := .sort (.succ .zero)
  let natExpr : PSC1Kernel.Expr := .const NatN []
  let succType : PSC1Kernel.Expr :=
    .forallE (.str .anonymous "n") natExpr natExpr .default
  let env0 : PSC1Kernel.Environment := .empty
  let env1 := env0.addUnchecked (.inductInfo {
    base := mkBase NatN natType
    numParams := 0
    numIndices := 0
    all := [NatN]
    ctors := [Zero, Succ]
    numNested := 0
    isRec := true
    isReflexive := false
    isUnsafe := false
  })
  let env2 := env1.addUnchecked (.ctorInfo {
    base := mkBase Zero natExpr
    induct := NatN
    cidx := 0
    numParams := 0
    numFields := 0
    isUnsafe := false
  })
  let env3 := env2.addUnchecked (.ctorInfo {
    base := mkBase Succ succType
    induct := NatN
    cidx := 1
    numParams := 0
    numFields := 1
    isUnsafe := false
  })
  let motiveF : PSC1Kernel.Name := .str .anonymous "natMotive"
  let zeroF : PSC1Kernel.Name := .str .anonymous "natZeroMinor"
  let succF : PSC1Kernel.Name := .str .anonymous "natSuccMinor"
  let nF : PSC1Kernel.Name := .str .anonymous "natPred"
  let dummy : PSC1Kernel.Expr := .sort .zero

  let zeroBody : PSC1Kernel.Expr := .fvar zeroF
  let zeroClosed := zeroBody.abstractFVars [motiveF, zeroF, succF]
  let rhsZero : PSC1Kernel.Expr :=
    .lam motiveF dummy
      (.lam zeroF dummy
        (.lam succF dummy zeroClosed .default)
        .default)
      .default

  let recursiveCall :=
    PSC1Kernel.applyArgs
      (.const Rec [.param u])
      [.fvar motiveF, .fvar zeroF, .fvar succF, .fvar nF]
  let succBody : PSC1Kernel.Expr :=
    .app (.app (.fvar succF) (.fvar nF)) recursiveCall
  let succClosed :=
    succBody.abstractFVars [motiveF, zeroF, succF, nF]
  let rhsSucc : PSC1Kernel.Expr :=
    .lam motiveF dummy
      (.lam zeroF dummy
        (.lam succF dummy
          (.lam nF dummy succClosed .default)
          .default)
        .default)
      .default

  let env := env3.addUnchecked (.recInfo {
    base := { name := Rec, levelParams := [u], type := dummy }
    all := [NatN]
    numParams := 0
    numIndices := 0
    numMotives := 1
    numMinors := 2
    rules := [
      { ctor := Zero, nFields := 0, rhs := rhsZero },
      { ctor := Succ, nFields := 1, rhs := rhsSucc }
    ]
    k := false
    isUnsafe := false
  })
  let ctx := PSC1Kernel.CheckerContext.empty env
  let nName : PSC1Kernel.Name := .str .anonymous "n"
  let ihName : PSC1Kernel.Name := .str .anonymous "ih"
  let motive : PSC1Kernel.Expr := .lam nName natExpr natExpr .default
  let zeroMinor : PSC1Kernel.Expr := .lit (.nat 0)
  let succMinor : PSC1Kernel.Expr :=
    .lam nName natExpr
      (.lam ihName natExpr
        (.app (.const Succ []) (.bvar 0))
        .default)
      .default
  let input :=
    PSC1Kernel.applyArgs
      (.const Rec [.succ .zero])
      [motive, zeroMinor, succMinor, .lit (.nat 3)]
  let ours ← exceptToIO "PSC1 Nat literal recursor" (PSC1Kernel.whnf ctx input)
  let leanEnv ← Lean.importModules #[{ module := `Init.Prelude }] {}
  let lean ← kernelExprWhnf leanEnv input
  assertTrue "Nat literal recursor reduction differs from Lean 4.34"
    (toLeanExpr ours == lean)
  assertTrue "Nat literal recursor did not normalize recursively"
    (PSC1Kernel.Expr.eq ours (.lit (.nat 3)))

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

def assertMetavariableRejectionOracle : IO Unit := do
  let ExprBad : PSC1Kernel.Name := .str .anonymous "OracleExprMVar"
  let UnivBad : PSC1Kernel.Name := .str .anonymous "OracleUniverseMVar"
  let BodyBad : PSC1Kernel.Name := .str .anonymous "OracleBodyMVar"
  let ExprMeta : PSC1Kernel.Name := .str .anonymous "exprMeta"
  let UnivMeta : PSC1Kernel.Name := .str .anonymous "univMeta"
  let type1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let exprMVar : PSC1Kernel.Expr := .mvar ExprMeta
  let universeMVarType : PSC1Kernel.Expr := .sort (.mvar UnivMeta)

  let oursExprRejects :=
    match PSC1Kernel.Kernel.addAxiom .empty {
      base := mkBase ExprBad exprMVar
      isUnsafe := false
    } with
    | .ok _ => false
    | .error _ => true
  let oursUniverseRejects :=
    match PSC1Kernel.Kernel.addAxiom .empty {
      base := mkBase UnivBad universeMVarType
      isUnsafe := false
    } with
    | .ok _ => false
    | .error _ => true
  let oursBodyRejects :=
    match PSC1Kernel.Kernel.addDefinition .empty {
      base := mkBase BodyBad type1
      value := exprMVar
      hints := .opaqueHint
      safety := .safe
    } with
    | .ok _ => false
    | .error _ => true

  let lean0 := (← Lean.mkEmptyEnvironment).toKernelEnv
  let leanExprRejects :=
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName ExprBad
      levelParams := []
      type := toLeanExpr exprMVar
      isUnsafe := false
    }) with
    | .ok _ => false
    | .error _ => true
  let leanUniverseRejects :=
    match Lean.Kernel.Environment.addDecl lean0 {} (.axiomDecl {
      name := toLeanName UnivBad
      levelParams := []
      type := toLeanExpr universeMVarType
      isUnsafe := false
    }) with
    | .ok _ => false
    | .error _ => true
  let leanBodyRejects :=
    match Lean.Kernel.Environment.addDecl lean0 {} (.defnDecl {
      name := toLeanName BodyBad
      levelParams := []
      type := toLeanExpr type1
      value := toLeanExpr exprMVar
      hints := .opaque
      safety := .safe
    }) with
    | .ok _ => false
    | .error _ => true

  assertTrue "expression-metavariable declaration rejection differs from Lean 4.34"
    (oursExprRejects == leanExprRejects && leanExprRejects)
  assertTrue "universe-metavariable declaration rejection differs from Lean 4.34"
    (oursUniverseRejects == leanUniverseRejects && leanUniverseRejects)
  assertTrue "definition-body metavariable rejection differs from Lean 4.34"
    (oursBodyRejects == leanBodyRejects && leanBodyRejects)
  assertTrue "failed metavariable declarations mutated PSC1 environment"
    (!PSC1Kernel.Environment.empty.contains ExprBad &&
      !PSC1Kernel.Environment.empty.contains UnivBad &&
      !PSC1Kernel.Environment.empty.contains BodyBad)
  assertTrue "failed metavariable declarations mutated Lean environment"
    ((lean0.find? (toLeanName ExprBad)).isNone &&
      (lean0.find? (toLeanName UnivBad)).isNone &&
      (lean0.find? (toLeanName BodyBad)).isNone)

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
  assertNatOffsetOracle
  assertEagerReduceOracle
  assertNativeEvaluatorBoundary
  assertNatReductionOracle
  assertFunctionEtaOracle
  assertLazyDeltaOracle
  assertProjectionLazyDeltaOracle
  assertStructureMajorRecursorOracle
  assertStructureEtaOracle
  assertUnitLikeOracle
  assertProofIrrelevanceOracle
  assertBindingOpenDefEqOracle
  assertBinderInfoDefEqOracle
  assertStringLiteralExpansionShape
  assertStringLiteralDefEqOracle
  assertQuotAdmissionOracle
  assertKernelRecDepthOracle
  assertOpaqueClosureOracle
  assertMutualDuplicateNameOracle
  assertImaxPropOracle
  assertProjectionOracle
  assertArenaProjectionStructureSoundnessOracle
  assertSimpleInductiveAdmissionOracle
  assertNestedUniformityOracle
  assertNestedReservedNameOracle
  assertNestedInductiveAdmissionOracle
  assertParameterizedNestedInductiveAdmissionOracle
  assertUniverseNestedInductiveAdmissionOracle
  assertOuterMutualNestedInductiveAdmissionOracle
  assertLetTypeClosureOracle
  assertReplayCoreOracle
  assertReplayJsonOracle
  assertOrdinaryRecursorOracle
  assertNatLiteralRecursorOracle
  assertQuotReductionOracle
  assertMetavariableRejectionOracle
  assertDeclarationAdmissionOracle
  IO.println "PSC1Kernel Lean 4.34 foundational + projection oracle: PASS"

end PSC1Kernel.Test

def main : IO Unit := PSC1Kernel.Test.run
