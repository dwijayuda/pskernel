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

def psTestHigherOrderBinderTranslation : Bool :=
  let sources := [
    "def apply (f : Nat -> Nat) (x : Nat) : Nat := f x",
    "def combine (f : Nat -> Nat -> Nat) (x : Nat) : Nat := f x x",
    "def nested (f : List Nat -> Nat) : Nat := 0"]
  sources.all fun source =>
    match psTranslateLeanToProofScript source, psCanonicalizeLeanSource source with
    | .ok proofScript, .ok canonicalLean =>
        match psTranslateProofScriptToLean proofScript, psCanonicalizeProofScriptSource proofScript with
        | .ok leanAgain, .ok proofScriptAgain =>
            leanAgain == canonicalLean && proofScriptAgain == proofScript
        | _, _ => false
    | _, _ => false

def psTestProofScriptNestedBinderTypes : Bool :=
  let sources := [
    "def twice (f : ((_: Nat) -> Nat) -> Nat) : Nat := 0;",
    "def named (f : (x : Nat) -> Nat) : Nat := 0;",
    "def nested (f : List((_: Nat) -> Nat)) : Nat := 0;",
    "def implicitType (f : {x : Nat} -> Nat) : Nat := 0;",
    "def grouped (f : (Nat -> Nat)) : Nat := 0;"]
  sources.all fun source =>
    match psCanonicalizeProofScriptSource source with
    | .error _ => false
    | .ok canonical =>
        match psCanonicalizeProofScriptSource canonical with
        | .error _ => false
        | .ok again => again == canonical

def main : IO Unit := do
  if psTestProofScriptNestedBinderTypes then
    IO.println "PSC1_TRANSLATION_PASS: grouped and dependent ProofScript binder types"
  else throw (IO.userError "PSC1_TRANSLATION_FAIL: grouped and dependent ProofScript binder types")
  if psTestHigherOrderBinderTranslation then
    IO.println "PSC1_TRANSLATION_PASS: nested function binder canonical round trip"
  else throw (IO.userError "PSC1_TRANSLATION_FAIL: nested function binder canonical round trip")
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
