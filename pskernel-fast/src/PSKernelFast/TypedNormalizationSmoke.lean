import PSKernelFast.TypedNormalization

/-!
Focused native G4.4b tests and an INDEPENDENT official C++ kernel oracle.
The oracle checks an Eq.refl proof against Eq ty lhs rhs via a checked
lambda application. It is never called from the PSKernel-Fast reducer.
A finite passing corpus is not a universal model-soundness theorem.
-/

namespace PSKernelFast.Core

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw (IO.userError message)

private def testName (n : KName) : Lean.Name :=
  match n with
  | .anonymous => .anonymous
  | .str p s => .str (testName p) s
  | .num p i => .num (testName p) i

private def testLevel : ULevel → Option Lean.Level
  | .zero => some .zero
  | .succ u => return .succ (← testLevel u)
  | .max a b => return .max (← testLevel a) (← testLevel b)
  | .imax a b => return .imax (← testLevel a) (← testLevel b)
  | .param n => some (.param (testName n))
  | .mvar _ => none

/-- Test-only exact mapping for default-binder fixtures. Others decline. -/
private def testExpr : KExpr → Option Lean.Expr
  | .bvar i => some (.bvar i)
  | .sort u => return .sort (← testLevel u)
  | .app f a => return .app (← testExpr f) (← testExpr a)
  | .lam n a b .default =>
      return .lam (testName n) (← testExpr a) (← testExpr b) .default
  | .forallE n a b .default =>
      return .forallE (testName n) (← testExpr a) (← testExpr b) .default
  | .letE n a v b flag =>
      return .letE (testName n) (← testExpr a) (← testExpr v) (← testExpr b) flag
  | _ => none

private def kernelEquality (env : Lean.Environment)
    (lhs rhs ty : KExpr) : IO Bool := do
  let some l := testExpr lhs | throw (IO.userError "unsupported oracle lhs")
  let some r := testExpr rhs | throw (IO.userError "unsupported oracle rhs")
  let some t := testExpr ty | throw (IO.userError "unsupported oracle type")
  let .ok (.sort u) := Lean.Kernel.check env {} t
    | throw (IO.userError "oracle fixture type is not a checked sort")
  let eqType := Lean.mkApp3 (Lean.mkConst ``Eq [u]) t l r
  let reflProof := Lean.mkApp2 (Lean.mkConst ``Eq.refl [u]) t l
  let checkedCast := Lean.Expr.app
    (.lam `w eqType (.bvar 0) .default) reflProof
  match Lean.Kernel.check env {} checkedCast with
  | .ok _ => pure true
  | .error _ => pure false

private def expectJoin {params : List KName} (ctx : GeneralPiContext params)
    (lhs rhs expected : KExpr) (fuel leftCount rightCount : Nat) : IO Unit := do
  match compareTypedWH ctx lhs rhs fuel with
  | .equal c =>
      require (c.common == expected && c.leftSteps == leftCount &&
        c.rightSteps == rightCount) "wrong common reduct or contraction count"
  | _ => throw (IO.userError "supported typed common-head join declined")

private def expectUnresolved {params : List KName}
    (ctx : GeneralPiContext params) (lhs rhs : KExpr) : IO Unit := do
  match compareTypedWH ctx lhs rhs 32 with
  | .unresolved => pure ()
  | _ => throw (IO.userError "unsupported conversion was not unresolved")

def typedNormalizationSmoke : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let oracle ← Lean.importModules #[{ module := `Init }] {}
  let ctx := GeneralPiContext.empty []
  let x : KName := .str .anonymous "x"
  let a : KName := .str .anonymous "A"
  let p : KName := .str .anonymous "P"
  let q : KName := .str .anonymous "Q"
  let s0 : KExpr := .sort .zero
  let s1 : KExpr := .sort (.succ .zero)
  let s2 : KExpr := .sort (.succ (.succ .zero))
  let ident : KExpr := .lam x s1 (.bvar 0) .default
  let beta := fun e : KExpr => KExpr.app ident e
  let zeta := fun e : KExpr => KExpr.letE x s1 e (.bvar 0) false
  let mut chain := s0
  let mut count : Nat := 0
  let mut oraclePositives : Nat := 0
  for i in [0:12] do
    expectJoin ctx chain s0 s0 (count + 1) count 0
    expectJoin ctx s0 chain s0 (count + 1) 0 count
    require (← kernelEquality oracle chain s0 s1)
      "official kernel disagreed with generated positive conversion"
    oraclePositives := oraclePositives + 1
    chain := if i % 2 == 0 then beta chain else zeta chain
    count := count + 1
  expectJoin ctx (beta (zeta s0)) (zeta (beta s0)) s0 3 2 2
  require (← kernelEquality oracle (beta (zeta s0)) (zeta (beta s0)) s1)
    "official kernel disagreed on two-sided beta/zeta join"
  oraclePositives := oraclePositives + 1

  let higher : KExpr := .lam a s2 (.lam x (.bvar 0) (.bvar 0) .default) .default
  let spine : KExpr := .app (.app higher s1) s0
  expectJoin ctx spine s0 s0 3 2 0
  require (← kernelEquality oracle spine s0 s1) "official beta-spine disagreement"
  oraclePositives := oraclePositives + 1

  let identTy : KExpr := .forallE x s1 s1 .default
  let letHead : KExpr := .app (.letE x identTy ident (.bvar 0) false) s0
  expectJoin ctx letHead s0 s0 3 2 0
  require (← kernelEquality oracle letHead s0 s1) "official let-spine disagreement"
  oraclePositives := oraclePositives + 1

  match compareTypedWH ctx chain s0 count with
  | .resourceExhausted => pure ()
  | _ => throw (IO.userError "missing terminal inspection did not exhaust fuel")
  match compareTypedWH ctx s0 s0 0 with
  | .resourceExhausted => pure ()
  | _ => throw (IO.userError "zero fuel authorized reflexivity")
  match compareTypedWH ctx (.bvar 0) (.bvar 0) 0 with
  | .malformed => pure ()
  | _ => throw (IO.userError "malformed scope did not precede fuel result")
  expectUnresolved ctx (.app ident s1) s0
  require (!(← kernelEquality oracle (.app ident s1) s0 s1))
    "official oracle accepted an ill-typed application"

  let first : KExpr := .lam p s0 (.lam q s0 (.bvar 1) .default) .default
  let second : KExpr := .lam p s0 (.lam q s0 (.bvar 0) .default) .default
  let pairTy : KExpr := .forallE p s0 (.forallE q s0 s0 .default) .default
  expectUnresolved ctx first second
  require (!(← kernelEquality oracle first second pairTy))
    "official oracle failed to distinguish unequal same-typed functions"

  -- This valid Lean equality requires reduction under a lambda, deliberately
  -- outside a common-WHNF-only comparator. It must remain UNRESOLVED.
  let underBinder : KExpr := .lam x s1 (.app ident (.bvar 0)) .default
  expectUnresolved ctx ident underBinder
  require (← kernelEquality oracle ident underBinder identTy)
    "intended completeness-gap fixture is not equal in the official kernel"

  -- Capture avoidance in a real nonempty dependent source context.
  let some c1 := ctx.extend s1 | throw (IO.userError "first context binder failed")
  let some c2 := c1.extend (.bvar 0) | throw (IO.userError "dependent binder failed")
  let outer : KExpr := .app (.lam x s1 (.bvar 2) .default) s0
  expectJoin c2 outer (.bvar 1) (.bvar 1) 2 1 0

  -- Do not reduce the argument of a neutral head. This is weak-head, not NF.
  let some cf := ctx.extend identTy | throw (IO.userError "function binder failed")
  let neutral : KExpr := .app (.bvar 0) (beta s0)
  expectJoin cf neutral neutral neutral 1 0 0
  expectUnresolved cf neutral (.app (.bvar 0) s0)

  require (oraclePositives == 15) "official positive fixture count changed"
  IO.println "G4.4b typed multistep normalization PASS: exact counts, both paths, function spine, scope, fuel, capture and neutral heads"
  IO.println s!"G4.4b official C++ kernel differential PASS: {oraclePositives} equalities, 2 rejection controls, 1 intentional completeness gap"

end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.typedNormalizationSmoke
