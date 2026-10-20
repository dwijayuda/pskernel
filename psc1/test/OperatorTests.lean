import Ps.Compiler.Api
import Ps.Host.LeanChecked
import Ps.CompilerIr.Validate

private def require (condition : Bool) (message : String) : IO Unit := do
  if !condition then throw (IO.userError message)

private def prepare (kind : PsCompilerSourceKind) (source : String) :
    IO PsCompilerAdmissionReadyModule := do
  let prepared ← match psCompilerPrepareSource kind source with
    | .error _ => throw (IO.userError ("operator fixture failed: " ++ source))
    | .ok value => pure value
  match ← psHostLeanCheckPrepared prepared with
  | .error message => throw (IO.userError message)
  | .ok _ => pure ()
  return prepared

private def same
    (kind : PsCompilerSourceKind) (actual expected : String) : IO Unit := do
  let first ← prepare kind actual
  let second ← prepare kind expected
  let firstBytes ← match psCompilerAdmissionsFromPrepared first with
    | .ok value => pure value
    | .error _ => throw (IO.userError "operator canonical encoding failed")
  let secondBytes ← match psCompilerAdmissionsFromPrepared second with
    | .ok value => pure value
    | .error _ => throw (IO.userError "prefix canonical encoding failed")
  require (firstBytes == secondBytes)
    ("operator changed checked Core meaning: " ++ actual)

private def rejected (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  match psCompilerPrepareSource kind source with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError ("unsupported or ill-typed operator accepted: " ++ source))

def main : IO Unit := do
  same .lean "def answer : Nat := 2 + 3 * 4\n"
    "def answer : Nat := Nat.add 2 (Nat.mul 3 4)\n"
  same .proofScript "def answer : Nat := 2 + 3 * 4\n"
    "def answer : Nat := Nat.add(2, Nat.mul(3, 4))\n"
  same .lean "def answer : Nat := (2 + 3) * 4\n"
    "def answer : Nat := Nat.mul (Nat.add 2 3) 4\n"
  same .proofScript "def answer : Nat := (2 + 3) * 4\n"
    "def answer : Nat := Nat.mul(Nat.add(2, 3), 4)\n"
  same .lean "def answer : Nat := 10 - 3 - 2\n"
    "def answer : Nat := Nat.sub (Nat.sub 10 3) 2\n"
  same .proofScript "def answer : Nat := 10 - 3 - 2\n"
    "def answer : Nat := Nat.sub(Nat.sub(10, 3), 2)\n"
  same .lean "def answer : Nat := 7 / 2 + 7 % 2\n"
    "def answer : Nat := Nat.add (Nat.div 7 2) (Nat.mod 7 2)\n"
  same .proofScript "def answer(x : Int) : Int := 1 + x\n"
    "def answer(x : Int) : Int := Int.add(1, x)\n"
  same .lean "def answer (x : Int) : Int := -x * 2\n"
    "def answer (x : Int) : Int := Int.mul (Int.neg x) 2\n"
  same .lean "def answer (x : Bool) (y : Bool) : Bool := x && y\n"
    "def answer (x : Bool) (y : Bool) : Bool := if x then y else false\n"
  same .proofScript "def answer(x : Bool, y : Bool) : Bool := x || y\n"
    "def answer(x : Bool, y : Bool) : Bool := if (x) { true } else { y }\n"
  same .lean "def answer : Bool := 1 == 2\n"
    "def answer : Bool := Nat.beq 1 2\n"
  let expectedEquality := psExprApplyMany
    (.constE psEqName [PsLevel.succ PsLevel.zero])
    [.constE psNatName [], .lit (.natural 1), .lit (.natural 2)]
  for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
    let proposition ← prepare kind "def answer : Prop := 1 = 2\n"
    match proposition.declarations with
    | [.definitionDecl _ _ type value] =>
        require (psExprAlphaEq type (.sortE .zero)) "equality did not have type Prop"
        require (psExprAlphaEq value expectedEquality) "equality did not lower to the checked Eq proposition"
    | _ => throw (IO.userError "unexpected equality declaration shape")
  let _ ← prepare .lean "def answer : Bool := !(1 == 2) && true || false\n"
  let _ ← prepare .proofScript "def answer : Bool := !false == true\n"
  rejected .lean "def bad : Nat := true + 1\n"
  rejected .proofScript "def bad : Bool := 1 = 2\n"
  rejected .lean "def bad : Bool := 1 == 2 == 3\n"
  rejected .proofScript "def bad : Bool := 1 < 2 < 3\n"
  -- Relational propositions are a declared gap until their logical and decision
  -- operations are independently admitted. Never translate them to Bool tests.
  rejected .lean "def unselected : Prop := 1 < 2\n"
  rejected .proofScript "def unselected : Bool := 1 <= 2\n"
  rejected .lean "def bad : Nat := -1\n"
  rejected .proofScript "def bad : Nat := 1 +\n"
  IO.println "PSC1_OPERATOR_TESTS: checked Core equivalence; selected primitive domains only"
