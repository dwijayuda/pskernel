import Ps.Host.LeanChecked
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Check

private def require (label : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_DO_FAIL: " ++ label))
  IO.println ("PSC1_DO_PASS: " ++ label)

private def prepare (label : String) (kind : PsCompilerSourceKind) (source : String) :
    IO PsCompilerAdmissionReadyModule := do
  match psCompilerPrepareSource kind source with
  | .ok value => pure value
  | .error (.leanFrontend (.lex error)) =>
      throw (IO.userError (label ++ ": " ++ psHostLexErrorText error))
  | .error (.leanFrontend (.parse error)) =>
      throw (IO.userError (label ++ ": " ++ psHostParseErrorText error))
  | .error (.proofScriptFrontend (.lex error)) =>
      throw (IO.userError (label ++ ": " ++ psHostLexErrorText error))
  | .error (.proofScriptFrontend (.parse error)) =>
      throw (IO.userError (label ++ ": " ++ psHostParseErrorText error))
  | .error (.elaboration error) =>
      throw (IO.userError (label ++ ": " ++ psHostElabErrorText error))
  | .error (.admission _) =>
      throw (IO.userError (label ++ ": admission encoding"))
  | .error _ => throw (IO.userError (label ++ ": parsing/preparation"))

-- A polymorphic identity checks conversion without relying on an Eq axiom,
-- Eq.refl, or an extra trusted declaration. The kernel must compare the
-- independently specified indices P expected and P result.
private def conversionFixture (prepared : PsCompilerAdmissionReadyModule)
    (type expected : PsExpr) : PsCompilerAdmissionReadyModule :=
  let actual := PsExpr.constE (psRootName "result") []
  let predicateName := psRootName "P"
  let witnessName := psRootName "h"
  let predicateType := PsExpr.forallE (psRootName "index") type
    (PsExpr.sortE (PsLevel.succ PsLevel.zero)) PsBinderInfo.explicit
  let premise := PsExpr.app (PsExpr.bvar 0) (psExprLiftBVars 1 0 expected)
  let conclusion := PsExpr.app (PsExpr.bvar 1) (psExprLiftBVars 2 0 actual)
  let checkType := PsExpr.forallE predicateName predicateType
    (PsExpr.forallE witnessName premise conclusion PsBinderInfo.explicit) PsBinderInfo.explicit
  let checkValue := PsExpr.lam predicateName predicateType
    (PsExpr.lam witnessName premise (PsExpr.bvar 0) PsBinderInfo.explicit) PsBinderInfo.explicit
  PsCompilerAdmissionReadyModule.mk (prepared.declarations ++
    [PsDeclaration.definitionDecl (psRootName "doResultConversion") [] checkType checkValue])

private def checkReduced (label : String) (prepared : PsCompilerAdmissionReadyModule)
    (type expected : PsExpr) : IO Unit := do
  let checked := conversionFixture prepared type expected
  match ← psHostLeanCheckPrepared checked with
  | .error error => throw (IO.userError (label ++ ": " ++ error))
  | .ok _ => pure ()
  match psCompilerVerifiedIrFromPrepared prepared with
  | .error _ => throw (IO.userError (label ++ ": ordinary erasure"))
  | .ok ir =>
      let report := psCheckVerifiedIrModule psIrCheckDefaultOptions ir
      if !report.accepted then
        let findings := report.findings.map (fun finding => finding.code ++ ":" ++ finding.detail)
        throw (IO.userError (label ++ ": " ++ String.intercalate ", " findings))
      require (label ++ " kernel reduction and typed IR") report.traversalComplete

private def checkSource (label : String) (kind : PsCompilerSourceKind)
    (source : String) (type expected : PsExpr) : IO Unit := do
  let prepared ← prepare label kind source
  checkReduced label prepared type expected

private def reject (label : String) (kind : PsCompilerSourceKind) (source : String) : IO Unit :=
  require label (match psCompilerPrepareSource kind source with | .error _ => true | .ok _ => false)

private def roundTrip (label : String) (kind target : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let original ← prepare label kind source
  let translated ←
    match psCompilerTranslateSource kind target source with
    | .ok value => pure value
    | .error _ => throw (IO.userError (label ++ ": translation"))
  let reparsed ← prepare label target translated
  match psCompilerAdmissionsFromPrepared original, psCompilerAdmissionsFromPrepared reparsed with
  | .ok first, .ok second => require label (first == second)
  | _, _ => throw (IO.userError (label ++ ": canonical admissions"))

private def testCompilerM (natType : PsExpr) : IO Unit := do
  let resultLibrary ← IO.FS.readFile "stdlib/ProofScript/Data/Result.lean"
  let effectLibrary ← IO.FS.readFile "stdlib/ProofScript/Compiler/Effect.lean"
  let fixture :=
    "def program : CompilerM Unit Nat String Nat := do\n" ++
    "  let original : Nat <- compilerGet ()\n" ++
    "  let next := Nat.succ original\n" ++
    "  compilerSet next\n" ++
    "  return original\n" ++
    "def result : Nat := match program.run () 7 with\n" ++
    "  | Result.ok pair => Nat.add pair.fst pair.snd\n" ++
    "  | Result.error error => 0\n"
  let prepared ←
    match psCompilerPrepareSources .lean [resultLibrary, effectLibrary, fixture] with
    | .ok value => pure value
    | .error _ => throw (IO.userError "CompilerM library preparation")
  checkReduced "existing checked CompilerM read and state update" prepared natType
    (PsExpr.lit (PsLiteral.natural 15))

  let controlFixture :=
    "def program : CompilerM Unit Nat String Nat := do\n" ++
    "  let original : Nat <- compilerGet ()\n" ++
    "  let mut next : Nat := original\n" ++
    "  if Nat.beq original 7 then\n" ++
    "    next := Nat.add next 1\n" ++
    "  else\n" ++
    "    next := Nat.add next 2\n" ++
    "  compilerSet next\n" ++
    "  if Nat.beq next 8 then\n" ++
    "    return original\n" ++
    "  return 0\n" ++
    "def result : Nat := match program.run () 7 with\n" ++
    "  | Result.ok pair => Nat.add pair.fst pair.snd\n" ++
    "  | Result.error error => 0\n"
  let controlled ←
    match psCompilerPrepareSources .lean [resultLibrary, effectLibrary, controlFixture] with
    | .ok value => pure value
    | .error _ => throw (IO.userError "CompilerM control-flow library preparation")
  checkReduced "checked CompilerM mutation branch and early return" controlled natType
    (PsExpr.lit (PsLiteral.natural 15))

private def testControlFlow (natType : PsExpr) : IO Unit := do
  let seven := PsExpr.lit (PsLiteral.natural 7)
  let psMutation :=
    "def result : Id Nat := do {\n" ++
    "  let mut value : Nat := 1\n" ++
    "  value := value + 2\n" ++
    "  if (true) {\n" ++
    "    value := value + 4\n" ++
    "  } else {\n" ++
    "    value := 99\n" ++
    "  }\n" ++
    "  return value\n}\n"
  let leanMutation :=
    "def result : Id Nat := do\n" ++
    "  let mut value : Nat := 1\n" ++
    "  value := value + 2\n" ++
    "  if true then\n" ++
    "    value := value + 4\n" ++
    "  else\n" ++
    "    value := 99\n" ++
    "  return value\n"
  checkSource "PS lexical mutation and branch join" .proofScript psMutation natType seven
  checkSource "Lean lexical mutation and branch join" .lean leanMutation natType seven
  checkSource "Lean braced mutable locals" .lean
    "def result : Id Nat := do { let mut value := 3; value := value + 4; return value }"
    natType seven
  roundTrip "PS mutation to Lean preserves checked Core" .proofScript .lean psMutation
  roundTrip "Lean mutation to PS preserves checked Core" .lean .proofScript leanMutation
  checkSource "false branch updates outer mutable local" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 1\n" ++
      "  if false then\n" ++
      "    value := 99\n" ++
      "  else\n" ++
      "    value := 7\n" ++
      "  return value\n") natType seven
  checkSource "omitted else preserves current state" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 7\n" ++
      "  if false then\n" ++
      "    value := 99\n" ++
      "  return value\n") natType seven
  checkSource "nested branch mutation and early return" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 3\n" ++
      "  if true then\n" ++
      "    value := 7\n" ++
      "    if Nat.beq value 7 then\n" ++
      "      return value\n" ++
      "    value := 99\n" ++
      "  value := value + 1\n" ++
      "  return value\n") natType seven
  let psEarly :=
    "def result : Id Nat := do {\n" ++
    "  let mut value := 3\n" ++
    "  if (true) {\n" ++
    "    value := 7\n" ++
    "    return value\n" ++
    "  }\n" ++
    "  value := 99\n" ++
    "  return value\n}\n"
  checkSource "PS branch return bypasses continuation" .proofScript psEarly natType seven
  roundTrip "PS early return roundtrip" .proofScript .lean psEarly
  checkSource "mutable capture retains captured value" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 3\n" ++
      "  let captured : Nat -> Nat := fun (n : Nat) => value + n\n" ++
      "  value := 100\n" ++
      "  return captured 4\n") natType seven
  checkSource "mutable local may shadow an immutable binding" .lean
    ("def result : Id Nat := do\n" ++
      "  let value : Bool := false\n" ++
      "  let mut value : Nat := 3\n" ++
      "  value := value + 4\n" ++
      "  return value\n") natType seven
  checkSource "direct nested do shares mutable locals" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 3\n" ++
      "  do\n" ++
      "    value := value + 4\n" ++
      "  return value\n") natType seven
  checkSource "direct nested do carries branch return outward" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 3\n" ++
      "  do\n" ++
      "    if true then\n" ++
      "      return 7\n" ++
      "    value := 99\n" ++
      "  return value\n") natType seven
  checkSource "terminal expression-valued if remains supported" .lean
    "def result : Id Nat := do if true then 7 else 9" natType seven
  checkSource "PS terminal expression-valued if remains supported" .proofScript
    "def result : Id Nat := do { if (true) { 7 } else { 9 } }\n" natType seven
  checkSource "dedented else belongs to the outer conditional" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 7\n" ++
      "  if true then\n" ++
      "    if false then\n" ++
      "      value := 99\n" ++
      "  else\n" ++
      "    value := 50\n" ++
      "  return value\n") natType seven
  checkSource "nested do return has its own boundary" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 3\n" ++
      "  let inner : Id Nat := (do { return 4 })\n" ++
      "  value := value + Id.run inner\n" ++
      "  return value\n") natType seven
  let stringType := PsExpr.constE psStringName []
  let exceptType := psSelfHostExceptOf stringType natType
  checkSource "Except early branch return preserves effect" .lean
    ("def result : Except String Nat := do\n" ++
      "  let mut value := 3\n" ++
      "  if true then\n" ++
      "    value := 7\n" ++
      "    return value\n" ++
      "  return 99\n") exceptType (psSelfHostExceptOkOf stringType natType seven)
  checkSource "Except error bypasses assignment and continuation" .proofScript
    ("def result : Except String Nat := do {\n" ++
      "  let mut value := 3\n" ++
      "  value := value + 4\n" ++
      "  if (true) {\n" ++
      "    let ignored : Unit <- Except.error(\"first\")\n" ++
      "    value := 99\n" ++
      "  }\n" ++
      "  return value\n}\n")
    exceptType (psSelfHostExceptErrorOf stringType natType
      (PsExpr.lit (PsLiteral.string "first")))
  reject "assignment to immutable local" .lean
    "def result : Id Nat := do { let value := 7; value := 8; return value }"
  reject "assignment to unknown local" .proofScript
    "def result : Id Nat := do {\n value := 8\n return 7\n}\n"
  reject "assignment type mismatch" .lean
    "def result : Id Nat := do { let mut value : Nat := 7; value := true; return value }"
  reject "immutable binding cannot shadow a mutable local" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 7\n" ++
      "  if true then\n" ++
      "    let value := 1\n" ++
      "    value := 9\n" ++
      "  return value\n")
  reject "mutable binding cannot shadow a mutable local" .lean
    "def result : Id Nat := do { let mut value := 7; let mut value := 8; return value }"
  reject "branch local cannot escape" .proofScript
    ("def result : Id Nat := do {\n" ++
      "  if (true) {\n" ++
      "    let hidden := 7\n" ++
      "    ()\n" ++
      "  }\n" ++
      "  return hidden\n}\n")
  reject "branch return type mismatch" .lean
    ("def result : Id Nat := do\n" ++
      "  if true then\n" ++
      "    return false\n" ++
      "  return 7\n")
  reject "fallthrough branch cannot invent a Nat result" .lean
    "def result : Id Nat := do\n  if true then\n    return 7\n"
  reject "independent nested do cannot assign outer mutable local" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut value := 7\n" ++
      "  let inner : Id Nat := do { value := 8; return value }\n" ++
      "  return Id.run inner\n")
  require "unassured partial control flow retains the admission refusal"
    (match psCompilerPrepareSource .lean
      ("partial def result (flag : Bool) : Id Nat := do\n" ++
        "  let mut value := 7\n" ++
        "  if flag then\n" ++
        "    value := 8\n" ++
        "  return value\n") with
      | .error (.admission _) => true
      | _ => false)

private def testFiniteLoops (natType : PsExpr) : IO Unit := do
  let nat (n : Nat) := PsExpr.lit (PsLiteral.natural n)
  let list := "List.cons 1 (List.cons 2 (List.cons 3 List.nil))"
  let array := "Array.push (Array.push (Array.push (Array.emptyWithCapacity 0) 1) 2) 3"
  let leanList :=
    "def result : Id Nat := do\n" ++
    "  let mut total : Nat := 0\n" ++
    "  for value in " ++ list ++ " do\n" ++
    "    total := Nat.add (Nat.mul total 10) value\n" ++
    "  return total\n"
  let psList :=
    "def result : Id Nat := do {\n" ++
    "  let mut total : Nat := 0\n" ++
    "  for value in List.cons(1, List.cons(2, List.cons(3, List.nil))) {\n" ++
    "    total := Nat.add(Nat.mul(total, 10), value)\n" ++
    "  }\n  return total\n}\n"
  checkSource "finite List iterates left-to-right" .lean leanList natType (nat 123)
  checkSource "PS finite List iterates left-to-right" .proofScript psList natType (nat 123)
  roundTrip "finite List PS to Lean" .proofScript .lean psList
  checkSource "finite List empty does not execute body" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total := 7\n" ++
      "  let values : List Nat := List.nil\n" ++
      "  for value in values do\n    total := Nat.add total value\n" ++
      "  return total\n") natType (nat 7)
  checkSource "finite List singleton" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total := 1\n" ++
      "  for value in List.cons 8 List.nil do\n    total := Nat.add total value\n" ++
      "  return total\n") natType (nat 9)
  checkSource "finite Array iterates left-to-right" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for value in " ++ array ++ " do\n" ++
      "    total := Nat.add (Nat.mul total 10) value\n" ++
      "  return total\n") natType (nat 123)
  checkSource "finite Array collection is captured once" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut values := " ++ array ++ "\n" ++
      "  let mut total := 0\n" ++
      "  for value in values do\n" ++
      "    values := Array.emptyWithCapacity 0\n" ++
      "    total := Nat.add total value\n" ++
      "  return total\n") natType (nat 6)
  checkSource "finite Array empty" .lean
    ("def result : Id Nat := do\n" ++
      "  let values : Array Nat := Array.emptyWithCapacity 0\n" ++
      "  let mut total := 7\n" ++
      "  for value in values do\n    total := Nat.add total value\n" ++
      "  return total\n") natType (nat 7)
  let leanRange :=
    "def result : Id Nat := do\n" ++
    "  let mut total := 0\n" ++
    "  let mut lower := 2\n" ++
    "  let mut upper := 5\n" ++
    "  for value in [lower:upper] do\n" ++
    "    lower := 100\n" ++
    "    upper := 0\n" ++
    "    total := Nat.add (Nat.mul total 10) value\n" ++
    "  return total\n"
  let psRange :=
    "def result : Id Nat := do {\n" ++
    "  let mut total := 0\n" ++
    "  let mut lower := 2\n" ++
    "  let mut upper := 5\n" ++
    "  for value in [lower:upper] {\n" ++
    "    lower := 100\n" ++
    "    upper := 0\n" ++
    "    total := Nat.add(Nat.mul(total, 10), value)\n" ++
    "  }\n  return total\n}\n"
  checkSource "finite range is ascending and captures both bounds once" .lean
    leanRange natType (nat 234)
  checkSource "PS finite range and loop-carried state" .proofScript
    psRange natType (nat 234)
  roundTrip "finite range Lean to PS" .lean .proofScript leanRange
  checkSource "finite range equal bounds is empty" .lean
    "def result : Id Nat := do { let mut n := 7; for i in [3:3] do { n := Nat.add n i }; return n }"
    natType (nat 7)
  checkSource "finite range reversed bounds is empty" .lean
    "def result : Id Nat := do { let mut n := 7; for i in [5:2] do { n := Nat.add n i }; return n }"
    natType (nat 7)
  checkSource "finite range omitted lower bound" .lean
    "def result : Id Nat := do { let mut n := 0; for i in [:3] do { n := Nat.add n i }; return n }"
    natType (nat 3)
  checkSource "finite nested loops carry the outer mutable local" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for x in List.cons 1 (List.cons 2 List.nil) do\n" ++
      "    for y in [3:5] do\n" ++
      "      total := Nat.add total (Nat.add x y)\n" ++
      "  return total\n") natType (nat 20)
  checkSource "finite loop early return skips later iterations and rest" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for value in " ++ list ++ " do\n" ++
      "    if Nat.beq value 2 then\n      return total\n" ++
      "    total := Nat.add total value\n" ++
      "  return 999\n") natType (nat 1)
  checkSource "return from nested finite loops leaves the enclosing computation" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for x in [1:4] do\n" ++
      "    for y in [1:4] do\n" ++
      "      if Nat.beq y 2 then\n        return Nat.add total x\n" ++
      "      total := Nat.add total y\n" ++
      "  return 999\n") natType (nat 2)
  let stringType := PsExpr.constE psStringName []
  let exceptType := psSelfHostExceptOf stringType natType
  let expectedError := psSelfHostExceptErrorOf stringType natType
    (PsExpr.lit (PsLiteral.string "two"))
  checkSource "finite loops propagate typed Except failure" .lean
    ("def result : Except String Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for i in [0:4] do\n" ++
      "    let value : Nat <- if Nat.beq i 2 then Except.error \"two\" else Except.ok i\n" ++
      "    total := Nat.add total value\n" ++
      "  return total\n") exceptType expectedError
  checkSource "finite early return is separate from a later typed error" .lean
    ("def result : Except String Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for i in [0:4] do\n" ++
      "    if Nat.beq i 1 then\n      return total\n" ++
      "    let value : Nat <- if Nat.beq i 2 then Except.error \"two\" else Except.ok i\n" ++
      "    total := Nat.add total value\n" ++
      "  return 999\n") exceptType (psSelfHostExceptOkOf stringType natType (nat 0))
  reject "finite for rejects a noniterable" .lean
    "def result : Id Nat := do { for value in true do { () }; return 7 }"
  reject "finite range rejects a non-Nat bound" .lean
    "def result : Id Nat := do { for value in [false:3] do { () }; return 7 }"
  reject "finite loop variable is immutable" .lean
    "def result : Id Nat := do { for value in [0:3] do { value := 4 }; return 7 }"
  reject "finite loop variable cannot shadow a mutable local" .lean
    "def result : Id Nat := do { let mut value := 0; for value in [0:3] do { () }; return value }"
  reject "finite loop iterator does not escape" .lean
    "def result : Id Nat := do { for value in [0:3] do { () }; return value }"
  reject "finite loop local does not escape" .lean
    "def result : Id Nat := do { for value in [0:3] do { let local := value; () }; return local }"
  reject "finite loop mutation keeps one type" .lean
    "def result : Id Nat := do { let mut value := 0; for i in [0:3] do { value := true }; return value }"

def main : IO Unit := do
  let natType := PsExpr.constE psNatName []
  let stringType := PsExpr.constE psStringName []
  let seven := PsExpr.lit (PsLiteral.natural 7)
  let exceptType := psSelfHostExceptOf stringType natType
  let firstError := psSelfHostExceptErrorOf stringType natType
    (PsExpr.lit (PsLiteral.string "first"))
  let psId :=
    "def result : Id Nat := do {\n" ++
    "  let a : Nat := 7\n" ++
    "  let b := a\n" ++
    "  let c : Nat <- b\n" ++
    "  let d ← c\n" ++
    "  ()\n" ++
    "  return d\n}\n"
  let leanId :=
    "def result : Id Nat := do\n" ++
    "  let a : Nat := 7\n" ++
    "  let b := a\n" ++
    "  let c : Nat <- b\n" ++
    "  let d ← c\n" ++
    "  ()\n" ++
    "  return d\n"
  checkSource "PS Id locals binds sequence" .proofScript psId natType seven
  checkSource "Lean Id layout" .lean leanId natType seven
  checkSource "Lean Id semicolons" .lean
    "def result : Id Nat := do { let value := 7; return value }" natType seven
  checkSource "Id terminal action" .proofScript
    "def result : Id Nat := do {\n  let value := 7\n  value\n}\n" natType seven
  checkSource "Id alias" .lean
    "def Action : Type := Id Nat\ndef result : Action := do { return 7 }" natType seven
  checkSource "PS nested Id.run" .proofScript
    ("def result : Nat := Id.run(do {\n" ++
      "  let value : Nat := Id.run(do { return 7 })\n  return value\n})\n") natType seven
  checkSource "Lean nested Id.run" .lean
    "def result : Nat := Id.run (do { let value : Nat := Id.run (do { return 7 }); return value })"
    natType seven
  checkSource "Id preserves inner Except alias boundary" .proofScript
    ("def result : Id(Except String Nat) := do {\n" ++
      "  let value : Except String Nat := Except.error(\"first\")\n" ++
      "  return value\n}\n") exceptType firstError
  let psExcept :=
    "def result : Except String Nat := do {\n" ++
    "  let a : Nat <- Except.ok(7)\n" ++
    "  let b ← Except.ok(a)\n" ++
    "  Except.ok(())\n" ++
    "  return b\n}\n"
  checkSource "Except successful typed/inferred sequencing" .proofScript psExcept
    exceptType (psSelfHostExceptOkOf stringType natType seven)
  checkSource "Except short circuit" .lean
    ("def result : Except String Nat := do\n" ++
      "  let a : Nat <- Except.error \"first\"\n" ++
      "  let b : Nat <- Except.error \"second\"\n" ++
      "  return b\n") exceptType firstError
  roundTrip "PS do to Lean preserves checked Core" .proofScript .lean psId
  roundTrip "Lean do to PS preserves checked Core" .lean .proofScript leanId
  roundTrip "Except do roundtrip" .proofScript .lean psExcept
  let scopedSource := "def result : Id Nat := do { let x := 7; (let x := 8; ()); return x }"
  checkSource "discarded compound action preserves lexical scope" .lean scopedSource natType seven
  roundTrip "discarded compound action roundtrip" .lean .proofScript scopedSource
  reject "bare Nat is not an effect" .lean "def result : Nat := do { return 7 }"
  reject "Option has no registered operations in this slice" .proofScript
    "def result : Option Nat := do { return 7 }\n"
  reject "return type mismatch" .lean "def result : Id Nat := do { return true }"
  reject "Type0 Id refuses a higher-universe bind" .lean
    "def result : Id Nat := do { let A : Type <- Nat; return 7 }"
  reject "higher-universe Id is outside the bounded profile" .lean
    "def result : Id Type := do { return Nat }"
  reject "bind annotation mismatch" .lean
    "def result : Except String Nat := do { let x : Bool <- Except.ok 7; return 7 }"
  reject "Except error type mismatch" .lean
    ("def wrong : Except Bool Nat := Except.error true\n" ++
      "def result : Except String Nat := do { let x <- wrong; return x }")
  reject "discarded action must return Unit" .lean
    "def result : Except String Nat := do { Except.ok 7; return 7 }"
  reject "terminal return cannot silently discard remaining syntax" .lean
    "def result : Id Nat := do { return 7; missing }"
  reject "PS semicolon remains rejected" .proofScript
    "def result : Id Nat := do { let value := 7; return value }\n"
  reject "PS braces required" .proofScript
    "def result : Id Nat := do\n  return 7\n"
  reject "missing expected effect" .lean
    "def result : Nat := let value := do { return 7 }; value"
  require "unassured partial do retains the admission refusal"
    (match psCompilerPrepareSource .lean "partial def result : Id Nat := do { return 7 }" with
      | .error (.admission _) => true
      | _ => false)
  let plain ← prepare "plain declaration" .lean "def result : Nat := 7"
  match psCompilerVerifiedIrFromPrepared plain with
  | .error _ => throw (IO.userError "plain declaration erasure")
  | .ok ir => require "unused Id.run is not emitted" (ir.declarations.length == 1)
  let wrongConversion ← psHostLeanCheckPrepared
    (conversionFixture plain natType (PsExpr.lit (PsLiteral.natural 8)))
  require "kernel conversion harness rejects a wrong result"
    (match wrongConversion with | .error _ => true | .ok _ => false)
  testCompilerM natType
  testControlFlow natType
  testFiniteLoops natType
  IO.println "PSC1_DO_TESTS: PASS"
