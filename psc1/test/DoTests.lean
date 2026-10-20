import Ps.Host.LeanChecked
import Ps.CompilerIr.Check

private def require (label : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_DO_FAIL: " ++ label))
  IO.println ("PSC1_DO_PASS: " ++ label)

private def prepare (label : String) (kind : PsCompilerSourceKind) (source : String) :
    IO PsCompilerAdmissionReadyModule := do
  match psCompilerPrepareSource kind source with
  | .ok value => pure value
  | .error (.elaboration .doExpectedType) =>
      throw (IO.userError (label ++ ": do expected type"))
  | .error (.elaboration .doUnsupportedEffect) =>
      throw (IO.userError (label ++ ": unsupported do effect"))
  | .error (.elaboration .typeMismatch) =>
      throw (IO.userError (label ++ ": type mismatch"))
  | .error (.elaboration (.infer _)) =>
      throw (IO.userError (label ++ ": Core inference"))
  | .error (.elaboration _) =>
      throw (IO.userError (label ++ ": elaboration"))
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

private def testCompilerM (natType seven : PsExpr) : IO Unit := do
  let resultLibrary ← IO.FS.readFile "stdlib/ProofScript/Data/Result.lean"
  let effectLibrary ← IO.FS.readFile "stdlib/ProofScript/Compiler/Effect.lean"
  let fixture :=
    "def program : CompilerM Unit Nat String Nat := do\n" ++
    "  let original : Nat <- compilerGet ()\n" ++
    "  let next := Nat.succ original\n" ++
    "  compilerSet next\n" ++
    "  return original\n" ++
    "def result : Nat := match program.run () 7 with\n" ++
    "  | Result.ok pair => pair.fst\n" ++
    "  | Result.error error => 0\n"
  let prepared ←
    match psCompilerPrepareSources .lean [resultLibrary, effectLibrary, fixture] with
    | .ok value => pure value
    | .error _ => throw (IO.userError "CompilerM library preparation")
  checkReduced "existing checked CompilerM" prepared natType seven

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
  reject "mutation is outside first do slice" .lean
    "def result : Id Nat := do { let mut value := 7; return value }"
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
  testCompilerM natType seven
  IO.println "PSC1_DO_TESTS: PASS"
