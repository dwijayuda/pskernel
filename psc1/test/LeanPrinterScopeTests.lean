import Ps.Host.LeanChecked
import Ps.CompilerIr.Validate
import Ps.CompilerIr.Encode

/-! Scope-sensitive source printing must preserve actual checked terms.
Canonical string idempotence alone cannot detect a consistently wrong tree. -/

private def demand (ok : Bool) (label : String) : IO Unit :=
  if ok then pure () else throw (IO.userError ("PSC1_PRINTER_SCOPE: " ++ label))

private def prepare (source : String) : IO PsCompilerAdmissionReadyModule := do
  let prepared ← match psCompilerPrepareSource .lean source with
    | .ok value => pure value
    | .error error => throw (IO.userError "PSC1_PRINTER_SCOPE_PREPARATION")
  match ← psHostLeanCheckPrepared prepared with
  | .error message => throw (IO.userError message)
  | .ok _ => pure ()
  let ir ← match psCompilerVerifiedIrFromPrepared prepared with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_ERASURE")
  match psStrictValidateModule ir with
  | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_STRICT_IR")
  | .ok _ => pure ()
  return prepared

private def checkedBytes (prepared : PsCompilerAdmissionReadyModule) : IO (String × String) := do
  let admissions ← match psCompilerAdmissionsFromPrepared prepared with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_ADMISSIONS")
  let ir ← match psCompilerVerifiedIrFromPrepared prepared with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_IR")
  let encoded ← match psIrEncodeModule ir with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_IR_ENCODING")
  return (admissions, encoded)

private def roundTrip (source : String) : IO String := do
  let before ← prepare source
  let ps ← match psTranslateLeanToProofScript source with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_TO_PS")
  let lean ← match psTranslateProofScriptToLean ps with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_TO_LEAN")
  let after ← prepare lean
  let a ← checkedBytes before
  let b ← checkedBytes after
  demand (a == b) "changed exact admission/IR bytes"
  match psCanonicalizeLeanSource lean with
  | .ok again => demand (lean == again) "not idempotent"
  | .error _ => throw (IO.userError "PSC1_PRINTER_SCOPE_REPARSE")
  return lean

private def nest (depth : Nat) (name : String) : String :=
  match depth with
  | 0 => "0"
  | n + 1 =>
      let child := "step" ++ toString n
      "match " ++ name ++ " with\n  | Nat.zero => 0\n  | Nat.succ " ++ child ++
        " => (" ++ nest n child ++ ")\n"

def main : IO Unit := do
  let source :=
    "inductive PrinterTag where\n  | a\n  | b\n  | c\n" ++
    "def printerEqual (left : PrinterTag) (right : PrinterTag) : Bool :=\n" ++
    "  match left with\n" ++
    "  | PrinterTag.a => match right with\n    | PrinterTag.a => true\n    | _ => false\n" ++
    "  | PrinterTag.b => match right with\n    | PrinterTag.b => true\n    | _ => false\n" ++
    "  | PrinterTag.c => match right with\n    | PrinterTag.c => true\n    | _ => false\n" ++
    "def printerLet (left : PrinterTag) (right : PrinterTag) : Nat :=\n" ++
    "  let value : Nat := (match left with\n" ++
    "    | PrinterTag.a => (match right with\n      | PrinterTag.a => 1\n      | _ => 2)\n" ++
    "    | _ => 3); value\n" ++
    "def printerIf (flag : Bool) (tag : PrinterTag) : Nat :=\n" ++
    "  if flag then (match tag with\n    | PrinterTag.a => 1\n    | _ => 2)\n" ++
    "  else (match tag with\n    | PrinterTag.b => 3\n    | _ => 4)\n" ++
    "def printerLambda (tag : PrinterTag) : PrinterTag -> Bool :=\n" ++
    "  fun (other : PrinterTag) => match tag with\n" ++
    "    | PrinterTag.a => (match other with\n      | PrinterTag.a => true\n      | _ => false)\n" ++
    "    | _ => false\n"
  let output ← roundTrip source
  IO.FS.createDirAll "dist/source-conversion/layout"
  IO.FS.writeFile "dist/source-conversion/layout/PrinterScopes.lean" output
  for depth in [1, 2, 4, 8, 12] do
    let code := "def printerDepth" ++ toString depth ++ " (value : Nat) : Nat := (" ++
      nest depth "value" ++ ")\n"
    let printed ← roundTrip code
    IO.FS.writeFile ("dist/source-conversion/layout/Depth" ++ toString depth ++ ".lean") printed
  let span := PsSourceSpan.mk (PsSourcePos.mk 0 1 1) (PsSourcePos.mk 1 1 2)
  match psPrintLeanTermWithFuel 0 (.natural "0" span) with
  | .error .fuelExhausted => pure ()
  | _ => throw (IO.userError "PSC1_PRINTER_SCOPE_FUEL_CHANGED")
  IO.println "PSC1_PRINTER_SCOPE: PASS nested alternatives, let/if/lambda contexts, depths 1/2/4/8/12, exact checked graphs and unchanged fuel"
