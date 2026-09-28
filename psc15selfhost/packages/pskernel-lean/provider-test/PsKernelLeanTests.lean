import PsKernelLean.Protocol
import PsKernelLean.Convert
import PsKernelLean.Prelude

def expectEq (label actual expected : String) : IO Unit := do
  if actual == expected then
    pure ()
  else
    throw <| IO.userError s!"{label}: expected {expected}, got {actual}"

def expectTrue (label : String) (value : Bool) : IO Unit := do
  if value then
    pure ()
  else
    throw <| IO.userError s!"{label}: expected true"

def expectOk {α : Type} (label : String)
    (result : Except PsKernelLean.PsKernelLeanError α) : IO α := do
  match result with
  | .ok value => pure value
  | .error error =>
      throw <| IO.userError s!"{label}: unexpected error {error.message}"

def expectErrorKind {α : Type} (label : String)
    (expected : PsKernelLean.PsKernelLeanErrorKind)
    (result : Except PsKernelLean.PsKernelLeanError α) : IO Unit := do
  match result with
  | .ok _ => throw <| IO.userError s!"{label}: expected error"
  | .error error =>
      expectTrue label (error.kind == expected)

def testCoreConversion : IO Unit := do
  let psName := PsName.num (PsName.str PsName.anonymous "A") 7
  let expectedName := Lean.Name.num (Lean.Name.str Lean.Name.anonymous "A") 7
  expectTrue "name conversion" (PsKernelLean.toLeanName psName == expectedName)

  let psLevel := PsLevel.imax
    (PsLevel.max PsLevel.zero (PsLevel.param (PsName.str PsName.anonymous "u")))
    (PsLevel.succ PsLevel.zero)
  let leanLevel ← expectOk "level conversion" (PsKernelLean.toLeanLevel psLevel)
  let expectedLevel := Lean.Level.imax
    (Lean.Level.max Lean.Level.zero (Lean.Level.param (Lean.Name.str Lean.Name.anonymous "u")))
    (Lean.Level.succ Lean.Level.zero)
  expectTrue "level shape" (leanLevel == expectedLevel)
  expectErrorKind "level mvar rejection"
    .unsupportedCoreForm
    (PsKernelLean.toLeanLevel (PsLevel.mvar 1))

  let binderName := PsName.str PsName.anonymous "x"
  let natName := PsName.str PsName.anonymous "Nat"
  let type0 := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let natType := PsExpr.constE natName []
  let composite :=
    PsExpr.letE binderName type0 type0
      (PsExpr.forallE binderName natType
        (PsExpr.lam binderName natType
          (PsExpr.app
            (PsExpr.constE (PsName.str natName "succ") [])
            (PsExpr.bvar 0))
          PsBinderInfo.strictImplicit)
        PsBinderInfo.instanceImplicit)
  let leanComposite ← expectOk "expression conversion" (PsKernelLean.toLeanExpr composite)
  let expectedComposite :=
    Lean.Expr.letE (Lean.Name.str Lean.Name.anonymous "x")
      (Lean.Expr.sort (Lean.Level.succ Lean.Level.zero))
      (Lean.Expr.sort (Lean.Level.succ Lean.Level.zero))
      (Lean.Expr.forallE (Lean.Name.str Lean.Name.anonymous "x")
        (Lean.Expr.const (Lean.Name.str Lean.Name.anonymous "Nat") [])
        (Lean.Expr.lam (Lean.Name.str Lean.Name.anonymous "x")
          (Lean.Expr.const (Lean.Name.str Lean.Name.anonymous "Nat") [])
          (Lean.Expr.app
            (Lean.Expr.const
              (Lean.Name.str (Lean.Name.str Lean.Name.anonymous "Nat") "succ") [])
            (Lean.Expr.bvar 0))
          Lean.BinderInfo.strictImplicit)
        Lean.BinderInfo.instImplicit)
      false
  expectTrue "expression shape" (leanComposite == expectedComposite)

  let natLiteral ← expectOk "nat literal"
    (PsKernelLean.toLeanExpr (PsExpr.lit (PsLiteral.natural 13)))
  expectTrue "nat literal shape"
    (natLiteral == Lean.Expr.lit (Lean.Literal.natVal 13))
  let stringLiteral ← expectOk "string literal"
    (PsKernelLean.toLeanExpr (PsExpr.lit (PsLiteral.string "psc")))
  expectTrue "string literal shape"
    (stringLiteral == Lean.Expr.lit (Lean.Literal.strVal "psc"))
  let projection ← expectOk "projection"
    (PsKernelLean.toLeanExpr
      (PsExpr.proj
        (PsName.str PsName.anonymous "Pair")
        1
        (PsExpr.bvar 0)))
  expectTrue "projection shape"
    (projection ==
      Lean.Expr.proj (Lean.Name.str Lean.Name.anonymous "Pair") 1 (Lean.Expr.bvar 0))

  expectErrorKind "free variable rejection"
    .unsupportedCoreForm
    (PsKernelLean.toLeanExpr (PsExpr.fvar 1))
  expectErrorKind "expression metavariable rejection"
    .unsupportedCoreForm
    (PsKernelLean.toLeanExpr (PsExpr.mvar 1))

def testPreludeReplay : IO Unit := do
  let result ← PsKernelLean.buildLeanPreludeEnvironment
  let env ← expectOk "prelude replay" result
  expectTrue "trust level zero" (env.header.trustLevel == 0)
  let required : List Lean.Name := [
    Lean.Name.str Lean.Name.anonymous "Nat",
    Lean.Name.str (Lean.Name.str Lean.Name.anonymous "Nat") "zero",
    Lean.Name.str (Lean.Name.str Lean.Name.anonymous "Nat") "succ",
    Lean.Name.str Lean.Name.anonymous "List",
    Lean.Name.str Lean.Name.anonymous "Option",
    Lean.Name.str Lean.Name.anonymous "Except",
    Lean.Name.str Lean.Name.anonymous "Prod"
  ]
  for name in required do
    expectTrue s!"prelude declaration {name}" (env.find? name).isSome

def main : IO Unit := do
  expectEq "providerProtocol" PsKernelLean.providerProtocol "pskernel-lean/1"
  expectEq "providerName" PsKernelLean.providerName "lean4-cpp"
  expectEq "providerVersion" PsKernelLean.providerVersion "4.34.0"
  expectEq "providerProfile" PsKernelLean.providerProfile "lean4.34-core"
  expectEq "leanVersion" Lean.versionString "4.34.0"
  testCoreConversion
  testPreludeReplay
  IO.println "PSC2_LEAN_KERNEL_PROVIDER_TESTS: PASS"
