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


private def orderWitness (environment : Lean.Environment) (relation : PsName)
    (left right : PsExpr) (expected : Bool) : IO Unit := do
  let proposition := psExprApplyMany (.constE relation []) [left,right]
  let declaration := PsDeclaration.theoremDecl (psRootName "orderBoundaryWitness") [] proposition
    (.constE psOrderIntroName [])
  let converted ← match PsKernelLean.toLeanPreludeDeclaration [declaration] declaration with
    | .ok (some value) => pure value
    | _ => throw (IO.userError "order witness conversion failed")
  match environment.addDeclCore 2000000 20000 converted none true with
  | .ok _ => require expected "false order proposition admitted an inhabitant"
  | .error _ => require (!expected) "true order proposition refused its constructive inhabitant"

private def integerCore (value : Int) : PsExpr :=
  match value with
  | .ofNat n => .app (.constE psIntOfNatName []) (.lit (.natural n))
  | .negSucc n => .app (.constE psIntNegSuccName []) (.lit (.natural n))

private def orderBoundaries : IO Unit := do
  let environment ← match ← PsKernelLean.buildLeanPreludeEnvironment with
    | .ok value => pure value
    | .error error => throw (IO.userError error.message)
  for left in [0,1,2] do
    for right in [0,1,2] do
      for (relation,expected) in [(psNatLtName,decide (left < right)),(psNatLeName,decide (left ≤ right)),
          (psNatGtName,decide (left > right)),(psNatGeName,decide (left ≥ right))] do
        orderWitness environment relation (.lit (.natural left)) (.lit (.natural right)) expected
  for left in [(-2 : Int),-1,0,1,2] do
    for right in [(-2 : Int),-1,0,1,2] do
      for (relation,expected) in [(psIntLtName,decide (left < right)),(psIntLeName,decide (left ≤ right)),
          (psIntGtName,decide (left > right)),(psIntGeName,decide (left ≥ right))] do
        orderWitness environment relation (integerCore left) (integerCore right) expected
  IO.println "PSC1_ORDER_KERNEL_BOUNDARIES: PASS 136 independent native truth/false inhabitation checks"

private def integerEqualityBoundary (environment : Lean.Environment)
    (left right : Int) (expected : Bool) : IO Unit := do
  let actual := psOperatorIntEquality (integerCore left) (integerCore right)
  let boolType := PsExpr.constE psBoolName []
  let target := PsExpr.constE (if expected then psBoolTrueName else psBoolFalseName) []
  let predicateType := PsExpr.forallE (psRootName "index") boolType
    (.sortE (.succ .zero)) .explicit
  let premise := PsExpr.app (.bvar 0) target
  let conclusion := PsExpr.app (.bvar 1) (psExprLiftBVars 2 0 actual)
  let type := PsExpr.forallE (psRootName "P") predicateType
    (.forallE (psRootName "h") premise conclusion .explicit) .explicit
  let value := PsExpr.lam (psRootName "P") predicateType
    (.lam (psRootName "h") premise (.bvar 0) .explicit) .explicit
  let declaration := PsDeclaration.definitionDecl (psRootName "integerEqualityBoundary") [] type value
  let converted ← match PsKernelLean.toLeanPreludeDeclaration [declaration] declaration with
    | .ok (some value) => pure value
    | _ => throw (IO.userError "integer equality conversion failed")
  let correct := left == right
  match environment.addDeclCore 2000000 20000 converted none true with
  | .ok _ => require (expected == correct) "incorrect signed equality result admitted"
  | .error error =>
      require (expected != correct)
        ("correct signed equality result refused: " ++ toString left ++ "/" ++
          toString right ++ "/" ++ toString expected ++ ": " ++
          PsKernelLean.kernelExceptionSummary error)

private def integerEqualityBoundaries : IO Unit := do
  let environment ← match ← PsKernelLean.buildLeanPreludeEnvironment with
    | .ok value => pure value
    | .error error => throw (IO.userError error.message)
  for left in [(-2 : Int), -1, 0, 1, 2] do
    for right in [(-2 : Int), -1, 0, 1, 2] do
      integerEqualityBoundary environment left right true
      integerEqualityBoundary environment left right false
  let left := PsExpr.app (.constE (psRootName "leftOperand") []) (.constE psUnitUnitName [])
  let right := PsExpr.app (.constE (psRootName "rightOperand") []) (.constE psUnitUnitName [])
  match psOperatorIntEquality left right with
  | .letE _ _ first (.letE _ _ second _) =>
      require (psExprAlphaEq first left) "signed equality changed left operand ownership"
      require (psExprAlphaEq second (psExprLiftBVars 1 0 right))
        "signed equality changed right operand order or scope"
  | _ => throw (IO.userError "signed equality lost its strict operand lets")
  IO.println "PSC1_INT_EQUALITY_KERNEL_BOUNDARIES: PASS 50 true/false conversion checks and strict operand lets"

private def linearConditionSize : IO Unit := do
  let conjunction := String.intercalate " && " (List.replicate 64 "flag")
  let equality := (List.range 64).foldr (fun _ rest => "flag == (" ++ rest ++ ")") "flag"
  for expression in [conjunction, equality] do
    for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
      let signature := match kind with
        | .lean => "def boundedCondition (flag : Bool) : Bool := "
        | .proofScript => "def boundedCondition(flag : Bool) : Bool := "
      let prepared ← prepare kind (signature ++ expression ++ "\n")
      let some declaration := prepared.declarations.find? (fun d =>
        psNameEq (psDeclarationName d) (psRootName "boundedCondition"))
        | throw (IO.userError "bounded condition missing")
      let some body := psDeclarationValue declaration
        | throw (IO.userError "bounded condition body missing")
      require (psCheckedNestedSize body <= 10000) "nested Bool conditions expanded beyond a linear Core bound"
      let encoded ← match psCompilerAdmissionsFromPrepared prepared with
        | .error _ => throw (IO.userError "bounded condition encoding failed")
        | .ok value => pure value
      require (encoded.utf8ByteSize <= 1048576) "bounded condition admission payload exceeded one MiB"
      let _ ← match psCompilerVerifiedIrFromPrepared prepared with
        | .error _ => throw (IO.userError "bounded condition erasure failed")
        | .ok ir =>
            match psStrictValidateModule ir with
            | .error _ => throw (IO.userError "bounded condition strict IR refused")
            | .ok value => pure value
      IO.println ("PSC1_LINEAR_CONDITION_CORE: PASS 64 conditions nodes=" ++
        toString (psCheckedNestedSize body) ++ " admissionBytes=" ++ toString encoded.utf8ByteSize)

def main : IO Unit := do
  linearConditionSize
  orderBoundaries
  integerEqualityBoundaries
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
  let _ ← prepare .lean "def answer (left right : Int) : Bool := left == right\n"
  let _ ← prepare .proofScript "def answer(left : Int, right : Int) : Bool := left != right\n"
  rejected .lean "def bad (left : Int) (right : Nat) : Bool := left == right\n"
  rejected .proofScript "def bad(left : Int) : Bool := left == true\n"
  rejected .lean "def bad : Nat := true + 1\n"
  rejected .proofScript "def bad : Bool := 1 = 2\n"
  rejected .lean "def bad : Bool := 1 == 2 == 3\n"
  rejected .proofScript "def bad : Bool := 1 < 2 < 3\n"
  let _ ← prepare .lean "def selected : Prop := 1 < 2\n"
  rejected .proofScript "def unselected : Bool := 1 <= 2\n"
  rejected .lean "def bad : Nat := -1\n"
  rejected .proofScript "def bad : Nat := 1 +\n"
  for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
    let _ ← prepare kind "def relation : Prop := 1 < 2\n"
  let _ ← prepare .lean "def observed : Bool := if 1 < 2 then true else false\n"
  let _ ← prepare .proofScript "def observed : Bool := if (1 >= 2) { true } else { false }\n"
  require (!psOrderDeclarations.any (fun d => match d with | .axiomDecl _ _ _ => true | _ => false))
    "ordering introduced a logical axiom"
  let corrupted ← match psNatDecLeDeclaration with
    | .definitionDecl _ levels type _ =>
        pure (PsDeclaration.definitionDecl (psRootName "corruptOrderDecision") levels type
          (PsExpr.constE psBoolTrueName []))
    | _ => throw (IO.userError "missing constructive decision")
  match ← PsKernelLean.buildLeanPreludeEnvironment with
  | .error error => throw (IO.userError error.message)
  | .ok environment =>
      match PsKernelLean.toLeanPreludeDeclaration [corrupted] corrupted with
      | .error error => throw (IO.userError error.message)
      | .ok none => throw (IO.userError "missing corrupt decision")
      | .ok (some declaration) =>
          match environment.addDeclCore 2000000 20000 declaration none true with
          | .error _ => pure ()
          | .ok _ => throw (IO.userError "kernel accepted corrupt decision")
  IO.println "PSC1_OPERATOR_TESTS: checked arithmetic and proposition-valued Nat/Int order"
