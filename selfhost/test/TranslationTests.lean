import Ps.Syntax.Translate

def psTranslationLeanFixture : String :=
  "import Demo.Core\n\n" ++
  "inductive Choice where\n" ++
  "  | left\n" ++
  "  | right\n\n" ++
  "def choose (x : Choice) : Nat := " ++
  "match x with | Choice.left => 1 | Choice.right => 2"

def psTranslationProofScriptFixture : String :=
  "import Demo.Core\n\n" ++
  "inductive Choice where {\n" ++
  "  | left;\n" ++
  "  | right;\n" ++
  "};\n\n" ++
  "def choose (x : Choice) : Nat := " ++
  "match x with { | Choice.left => 1; | Choice.right => 2 };"

def psTestLeanProofScriptLeanRoundTrip : Bool :=
  match
      psTranslateLeanToProofScript
        psTranslationLeanFixture with
  | Except.error _ => false
  | Except.ok proofScript =>
      match psTranslateProofScriptToLean proofScript with
      | Except.error _ => false
      | Except.ok lean =>
          match psTranslateLeanToProofScript lean with
          | Except.error _ => false
          | Except.ok proofScriptAgain =>
              proofScriptAgain == proofScript

def psTestProofScriptLeanProofScriptRoundTrip : Bool :=
  match
      psTranslateProofScriptToLean
        psTranslationProofScriptFixture with
  | Except.error _ => false
  | Except.ok lean =>
      match psTranslateLeanToProofScript lean with
      | Except.error _ => false
      | Except.ok proofScript =>
          match
              psTranslateProofScriptToLean
                proofScript with
          | Except.error _ => false
          | Except.ok leanAgain =>
              leanAgain == lean

def psTranslationStructureLeanFixture : String :=
  "structure User where\n" ++
  "  age : Nat\n\n" ++
  "def ageOf (u : User) : Nat := u.age"

def psTranslationStructureProofScriptFixture : String :=
  "structure User where {\n" ++
  "  age : Nat;\n" ++
  "};\n\n" ++
  "def ageOf (u : User) : Nat := u.age;"

def psTestStructureTranslationRoundTrip : Bool :=
  match
      psTranslateLeanToProofScript
        psTranslationStructureLeanFixture,
      psTranslateProofScriptToLean
        psTranslationStructureProofScriptFixture with
  | Except.ok proofScript, Except.ok lean =>
      match
          psTranslateProofScriptToLean proofScript,
          psTranslateLeanToProofScript lean with
      | Except.ok leanAgain, Except.ok proofScriptAgain =>
          leanAgain == lean
            && proofScriptAgain == proofScript
      | _, _ => false
  | _, _ => false

def main : IO Unit := do
  if psTestStructureTranslationRoundTrip then
    IO.println
      "PSC1_TRANSLATION_PASS: structure .lean <-> .ps"
  else
    throw
      (IO.userError
        "PSC1_TRANSLATION_FAIL: structure .lean <-> .ps")
  if psTestLeanProofScriptLeanRoundTrip then
    IO.println
      "PSC1_TRANSLATION_PASS: .lean -> .ps -> .lean"
  else
    throw
      (IO.userError
        "PSC1_TRANSLATION_FAIL: .lean -> .ps -> .lean")
  if psTestProofScriptLeanProofScriptRoundTrip then
    IO.println
      "PSC1_TRANSLATION_PASS: .ps -> .lean -> .ps"
  else
    throw
      (IO.userError
        "PSC1_TRANSLATION_FAIL: .ps -> .lean -> .ps")
