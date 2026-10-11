import Ps.Syntax.Pscv0.Module

-- Native preflight only: these files are never selected as compiler inputs.
-- The generated portable bridge must independently reproduce the same views.
def authoringGet {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

def main : IO Unit := do
  let source ← IO.FS.readFile "packages/syntax/src-ps/Ps/Syntax/Translate.ps"
  let baseline ← IO.FS.readFile "packages/syntax/src/Ps/Syntax/Translate.lean"
  let current ← authoringGet (psPscv0ParseSource true source)
  let previous ← authoringGet (psPscv0ParseSource false baseline)
  unless !current.commentTrivia && !previous.commentTrivia do
    throw (IO.userError "PSCV0-AUTHORING-COMMENT-ANCHOR-REQUIRED")
  unless psPscv0ReplayOriginal current == source do
    throw (IO.userError "PSCV0-AUTHORING-REPLAY-MISMATCH")
  let readable ← authoringGet (psPscv0PrintSurfaceModule false current)
  let lowered ← authoringGet (psPscv0LowerToLean true source)
  let roundtrip ← authoringGet (psPscv0TranslateReadable false true readable)
  let repeated ← authoringGet (psPscv0LowerToLean true roundtrip)
  unless repeated == lowered do
    throw (IO.userError "PSCV0-AUTHORING-ROUNDTRIP-MISMATCH")
  let dir : System.FilePath := "dist/pscv0-native-authoring"
  IO.FS.createDirAll dir
  IO.FS.writeFile (dir / "readable.lean") readable
  IO.FS.writeFile (dir / "lowered.lean") lowered
  IO.FS.writeFile (dir / "roundtrip.ps") roundtrip
  IO.println readable
  IO.println "PSCV0_AUTHORING_NATIVE_PREFLIGHT: PASS; generated bridge correspondence still required"
