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

def psTestPartialDefinitionTranslationRoundTrip : Bool :=
  let leanSource :=
    "partial def loop (n : Nat) : Nat := loop n"
  let proofScriptSource :=
    "partial def loop(n : Nat) : Nat := loop(n);"
  match
      psTranslateLeanToProofScript leanSource,
      psTranslateProofScriptToLean proofScriptSource with
  | Except.ok proofScript, Except.ok lean =>
      proofScript.contains "partial def loop"
        && lean.contains "partial def loop"
        && match
            psTranslateProofScriptToLean proofScript,
            psTranslateLeanToProofScript lean with
           | Except.ok leanAgain, Except.ok proofScriptAgain =>
               leanAgain == lean
                 && proofScriptAgain == proofScript
           | _, _ => false
  | _, _ => false

def psTestComplexApplicationTranslationRoundTrip : Bool :=
  let leanSource :=
    "def effectDo (state : Nat) : Nat := do\n" ++
    "  let next : Nat <- compilerPure state;\n" ++
    "  return next"
  match
      psTranslateLeanToProofScript leanSource,
      psCanonicalizeLeanSource leanSource with
  | Except.ok proofScript, Except.ok canonicalLean =>
      proofScript.contains "compilerBind("
        && proofScript.contains "fun "
        && match psTranslateProofScriptToLean proofScript with
           | Except.error _ => false
           | Except.ok leanAgain =>
               leanAgain == canonicalLean
  | _, _ => false

def psAnonymousArrowLeanSource : String :=
  "def applyLater (x : Nat) : (Nat -> Nat) -> Nat := " ++
  "fun (f : Nat -> Nat) => f x"

def psTestAnonymousArrowTranslationRoundTrip : Bool :=
  match
      psTranslateLeanToProofScript psAnonymousArrowLeanSource,
      psCanonicalizeLeanSource psAnonymousArrowLeanSource with
  | Except.ok proofScript, Except.ok canonicalLean =>
      if proofScript.contains "(_ :" then
        false
      else
        match psTranslateProofScriptToLean proofScript with
        | Except.error _ => false
        | Except.ok leanAgain =>
            match psCanonicalizeLeanSource leanAgain with
            | Except.error _ => false
            | Except.ok canonicalLeanAgain =>
                canonicalLeanAgain == canonicalLean
  | _, _ => false

def psPrintAnonymousArrowDiagnostics : IO Unit := do
  match psTranslateLeanToProofScript psAnonymousArrowLeanSource with
  | Except.error _ =>
      IO.println "PSC1_ARROW_DIAG: lean-to-ps failed"
  | Except.ok proofScript =>
      IO.println ("PSC1_ARROW_DIAG_PS:\n" ++ proofScript)
      IO.println
        ("PSC1_ARROW_DIAG_HAS_DEPENDENT_ANON: " ++
          toString (proofScript.contains "(_ :"))
      match psCanonicalizeLeanSource psAnonymousArrowLeanSource with
      | Except.error _ =>
          IO.println "PSC1_ARROW_DIAG: canonical source Lean failed"
      | Except.ok canonicalLean =>
          IO.println ("PSC1_ARROW_DIAG_CANONICAL_SOURCE:\n" ++ canonicalLean)
          match psTranslateProofScriptToLean proofScript with
          | Except.error _ =>
              IO.println "PSC1_ARROW_DIAG: ps-to-lean failed"
          | Except.ok leanAgain =>
              IO.println ("PSC1_ARROW_DIAG_LEAN_AGAIN:\n" ++ leanAgain)
              match psCanonicalizeLeanSource leanAgain with
              | Except.error _ =>
                  IO.println "PSC1_ARROW_DIAG: canonical translated Lean failed"
              | Except.ok canonicalLeanAgain =>
                  IO.println
                    ("PSC1_ARROW_DIAG_CANONICAL_AGAIN:\n" ++ canonicalLeanAgain)
                  IO.println
                    ("PSC1_ARROW_DIAG_EQUAL: " ++
                      toString (canonicalLeanAgain == canonicalLean))

def main : IO Unit := do
  if psTestAnonymousArrowTranslationRoundTrip then
    IO.println
      "PSC1_TRANSLATION_PASS: anonymous arrow .lean <-> .ps"
  else
    psPrintAnonymousArrowDiagnostics
    throw
      (IO.userError
        "PSC1_TRANSLATION_FAIL: anonymous arrow .lean <-> .ps")
  if psTestComplexApplicationTranslationRoundTrip then
    IO.println
      "PSC1_TRANSLATION_PASS: complex application .lean <-> .ps"
  else
    throw
      (IO.userError
        "PSC1_TRANSLATION_FAIL: complex application .lean <-> .ps")
  if psTestPartialDefinitionTranslationRoundTrip then
    IO.println
      "PSC1_TRANSLATION_PASS: partial def .lean <-> .ps"
  else
    throw
      (IO.userError
        "PSC1_TRANSLATION_FAIL: partial def .lean <-> .ps")
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
