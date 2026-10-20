import Ps.Host.LeanChecked
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Validate
import PracticalExecution
import Ps.Elab.DoLoopLift

private def fail (label detail : String) : IO α :=
  throw (IO.userError ("PSC1_NAMESPACE_FAIL: " ++ label ++ ": " ++ detail))

private def prepare (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO PsCompilerAdmissionReadyModule := do
  let prepared ← match psCompilerPrepareSource kind source with
    | .ok value => pure value
    | .error (.leanFrontend (.lex error)) => fail label (psHostLexErrorText error)
    | .error (.leanFrontend (.parse error)) => fail label (psHostParseErrorText error)
    | .error (.proofScriptFrontend (.lex error)) => fail label (psHostLexErrorText error)
    | .error (.proofScriptFrontend (.parse error)) => fail label (psHostParseErrorText error)
    | .error (.elaboration error) => fail label (psHostElabErrorText error)
    | .error _ => fail label "preparation"
  match ← psHostLeanCheckPrepared prepared with
  | .error error => fail label error
  | .ok _ => pure ()
  let ir ← match psCompilerVerifiedIrFromPrepared prepared with
    | .error _ => fail label "erasure"
    | .ok value => pure value
  match psStrictValidateModule ir with
  | .error _ => fail label "strict typed IR validation"
  | .ok _ => pure ()
  return prepared

private def same (label : String) (kind : PsCompilerSourceKind)
    (actual expected : String) : IO Unit := do
  let first ← prepare label kind actual
  let second ← prepare (label ++ " named form") kind expected
  match psCompilerAdmissionsFromPrepared first, psCompilerAdmissionsFromPrepared second with
  | .ok left, .ok right =>
      if left != right then fail label "namespace syntax changed canonical checked Core"
  | _, _ => fail label "canonical admission encoding"
  IO.println ("PSC1_NAMESPACE_PASS: " ++ label)

private def rejectedParse (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  match psCompilerParseSource kind source with
  | .error _ => IO.println ("PSC1_NAMESPACE_PASS: " ++ label)
  | .ok _ => fail label "malformed source parsed"

private def rejectedType (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let parsed ← match psCompilerParseSource kind source with
    | .error _ => fail label "negative typing example failed to parse"
    | .ok value => pure value
  match psCompilerElaborateModule parsed with
  | .error _ => IO.println ("PSC1_NAMESPACE_PASS: " ++ label)
  | .ok _ => fail label "ill-typed source elaborated"

private def roundTrip (label : String) (kind other : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let initial ← prepare label kind source
  let translated ← match psCompilerTranslateSource kind other source with
    | .error _ => fail label "translation"
    | .ok text => pure text
  let restored ← prepare label other translated
  match psCompilerAdmissionsFromPrepared initial, psCompilerAdmissionsFromPrepared restored with
  | .ok first, .ok second =>
      if first != second then fail label "translation changed canonical admission"
  | _, _ => fail label "translation admission encoding"

private def checkExecuted (label : String) (kind : PsCompilerSourceKind)
    (source : String) (type expected : PsExpr) : IO Unit := do
  let prepared ← prepare label kind source
  psPracticalCheckExecuted label prepared type expected

private def elaborateOrdinary (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO PsElabModuleResult :=
  match psCompilerElaborateSource kind source with
  | .ok value => pure value
  | .error (.leanFrontend (.lex error)) => fail label (psHostLexErrorText error)
  | .error (.leanFrontend (.parse error)) => fail label (psHostParseErrorText error)
  | .error (.proofScriptFrontend (.lex error)) => fail label (psHostLexErrorText error)
  | .error (.proofScriptFrontend (.parse error)) => fail label (psHostParseErrorText error)
  | .error (.elaboration error) => fail label (psHostElabErrorText error)
  | .error _ => fail label "ordinary elaboration"

private def checkWhile (label : String) (kind other : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let original ← elaborateOrdinary label kind source
  let owner := psNameAppendStr (psRootName "Loop") "prior"
  let marker := psElabDoLoopName owner
  if !(original.declarations.any (fun declaration =>
      match declaration with
      | .partialDecl name _ _ _ => psElabDoLoopIsLiftedName owner name
      | _ => false)) then
    fail label "missing private while helper under qualified source owner"
  if !(original.declarations.all (fun declaration =>
      match declaration with
      | .partialDecl _ _ type body | .definitionDecl _ _ type body =>
          !(psElabDoLoopOccurs marker type || psElabDoLoopOccurs marker body)
      | _ => true)) then
    fail label "temporary generic while marker escaped"
  psPracticalCheckExecutedOrdinary label original
    (.constE psNatName []) (.lit (.natural 3))
  let translated ← match psCompilerTranslateSource kind other source with
    | .error _ => fail label "ordinary namespace translation"
    | .ok value => pure value
  let restored ← elaborateOrdinary label other translated
  let first ← match psCompilerPrepareOrdinary original with
    | .error error => fail label error
    | .ok value => pure value
  let second ← match psCompilerPrepareOrdinary restored with
    | .error error => fail label error
    | .ok value => pure value
  match psCompilerAdmissionsFromPrepared first.logical,
      psCompilerAdmissionsFromPrepared second.logical with
  | .ok left, .ok right =>
      if left != right then fail label "namespace translation changed ordinary logical graph"
  | _, _ => fail label "ordinary canonical admission"
  IO.println ("PSC1_NAMESPACE_PASS: " ++ label ++ " qualified private helper and ordinary round trip")

private def checkScopeMetadata (label : String) (kind : PsCompilerSourceKind) : IO Unit := do
  let source := "namespace A\nnamespace B\ndef value : Nat := 7\nend B\nend A\n"
  let parsed ← match psCompilerParseSource kind source with
    | .error _ => fail label "namespace metadata parse"
    | .ok value => pure value
  match parsed.declarations with
  | [.scopedDecl path (.definition name _ _ _ _)] =>
      if path != ["A", "B"] then fail label "lost nested scope path"
      if name.segments != ["value"] then fail label "parser rewrote authored declaration name"
  | _ => fail label "missing per-declaration namespace metadata"
  IO.println ("PSC1_NAMESPACE_PASS: " ++ label ++ " semantic scope metadata")

private def testShared (label : String) (kind other : PsCompilerSourceKind) : IO Unit := do
  checkScopeMetadata label kind
  let nested :=
    "namespace A\ndef leaf : Nat := 7\n" ++
    "namespace B\ndef value : Nat := leaf\nend B\nend A\n" ++
    "namespace A\ndef reopened : Nat := B.value\nend A\n" ++
    "def result : Nat := A.reopened\n"
  same (label ++ " nested and reopened canonical identities") kind nested
    ("def A.leaf : Nat := 7\ndef A.B.value : Nat := A.leaf\n" ++
      "def A.reopened : Nat := A.B.value\ndef result : Nat := A.reopened\n")
  roundTrip (label ++ " namespace translation") kind other nested
  same (label ++ " dotted namespace and declaration context") kind
    ("namespace A.B\ndef base : Nat := 11\nend A.B\n" ++
      "def A.B.selected : Nat := base\ndef result : Nat := A.B.selected\n")
    ("def A.B.base : Nat := 11\ndef A.B.selected : Nat := A.B.base\n" ++
      "def result : Nat := A.B.selected\n")
  checkExecuted (label ++ " current enclosing root and relative qualified priority") kind
    ("def rootValue : Nat := 5\ndef B.current : Nat := 90\n" ++
      "namespace A\ndef base : Nat := 2\ndef outer : Nat := 4\n" ++
      "namespace B\ndef base : Nat := 3\ndef current : Nat := base\n" ++
      "def enclosing : Nat := outer\ndef root : Nat := rootValue\nend B\n" ++
      "namespace C\ndef sibling : Nat := B.current\nend C\nend A\n" ++
      "def result : Nat := A.C.sibling + A.B.enclosing + A.B.root\n")
    (.constE psNatName []) (.lit (.natural 12))
  rejectedType (label ++ " namespace does not leak unqualified names") kind
    "namespace A\ndef hidden : Nat := 7\nend A\ndef result : Nat := hidden\n"
  rejectedType (label ++ " duplicate full identity across declaration spellings") kind
    "namespace A\ndef value : Nat := 7\nend A\ndef A.value : Nat := 8\n"
  rejectedType (label ++ " duplicate full identity across reopened scopes") kind
    "namespace A\ndef value : Nat := 7\nend A\nnamespace A\ndef value : Nat := 8\nend A\n"
  rejectedParse (label ++ " wrong end") kind
    "namespace A\ndef value : Nat := 7\nend B\n"
  rejectedParse (label ++ " unmatched end") kind "end A\n"
  rejectedParse (label ++ " missing end") kind "namespace A\ndef value : Nat := 7\n"
  rejectedParse (label ++ " nested ends are stack matched") kind
    "namespace A\nnamespace B\ndef value : Nat := 7\nend A\nend B\n"
  rejectedParse (label ++ " dotted namespace end must match opened name") kind
    "namespace A.B\ndef value : Nat := 7\nend B\n"
  rejectedParse (label ++ " imports remain module headers") kind
    "namespace A\nimport Helpers\nend A\n"
  rejectedParse (label ++ " root escape namespace is outside selected surface") kind
    "namespace _root_.A\ndef value : Nat := 7\nend _root_.A\n"
  rejectedParse (label ++ " root escape declaration is outside selected surface") kind
    "def _root_.A.value : Nat := 7\n"
  rejectedParse (label ++ " root escape reference is outside selected surface") kind
    "def value : Nat := 7\ndef result : Nat := _root_.value\n"

private def rejectedStructural (label : String) (kind : PsCompilerSourceKind)
    (source : String) (accept : PsElabError -> Bool) : IO Unit := do
  match psCompilerElaborateSource kind source with
  | .error (.elaboration error) =>
      if !(accept error) then fail label (psHostElabErrorText error)
  | .error _ => fail label "structural negative failed before elaboration"
  | .ok _ => fail label "unsafe structural source elaborated"
  IO.println ("PSC1_NAMESPACE_PASS: " ++ label)

private def checkNormalized (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let prepared ← prepare label kind source
  let owner := psNameAppendStr (psRootName "Math") "accumulate"
  let worker := psNameAppendNum (psNameAppendStr owner "$psc0SH") 0
  if !(prepared.declarations.any (fun declaration =>
      psNameEq (psDeclarationName declaration) worker)) then
    fail label "missing qualified structural normalization worker"
  psPracticalCheckExecuted label prepared (.constE psNatName []) (.lit (.natural 12))

private def testLean : IO Unit := do
  let natType := PsExpr.constE psNatName []
  checkExecuted "Lean local parameter shadows namespace declaration" .lean
    ("namespace A\ndef value : Nat := 7\n" ++
      "def choose (value : Nat) : Nat := value\nend A\n" ++
      "def result : Nat := A.choose 11\n") natType (.lit (.natural 11))
  checkExecuted "Lean namespace-local pure wins over contextual sugar" .lean
    ("namespace A\ndef pure (x : Nat) : Id Nat := Nat.add x 100\n" ++
      "def run : Id Nat := do\n  pure 2\nend A\n" ++
      "def result : Nat := Id.run A.run\n") natType (.lit (.natural 102))
  rejectedType "Lean ill-typed namespace-local pure is not rewritten" .lean
    ("namespace A\ndef pure (x : Nat) : Nat := x\n" ++
      "def run : Except String Nat := do\n  pure 2\nend A\n")
  checkExecuted "Lean namespace-qualified constructor patterns" .lean
    ("namespace Model\ninductive Flag where\n  | off\n  | on\n" ++
      "def decide (flag : Flag) : Nat := match flag with\n" ++
      "  | Flag.off => 0\n  | Flag.on => 11\nend Model\n" ++
      "def result : Nat := Model.decide Model.Flag.on\n") natType (.lit (.natural 11))
  checkExecuted "Lean namespaced structure and qualified global projection" .lean
    ("namespace Model\nstructure Box where\n  value : Nat\n" ++
      "def box : Box := { value := 13 }\nend Model\n" ++
      "def result : Nat := Model.box.value\n") natType (.lit (.natural 13))
  checkExecuted "Lean namespaced structural self" .lean
    ("namespace Math\ndef count (n : Nat) : Nat := match n with\n" ++
      "  | Nat.zero => 0\n  | Nat.succ k => Nat.succ (count k)\nend Math\n" ++
      "def result : Nat := Math.count 4\n") natType (.lit (.natural 4))
  checkNormalized "Lean namespaced structural fallback keeps qualified worker" .lean
    ("namespace Math\ndef accumulate (n : Nat) (acc : Nat) : Nat := match n with\n" ++
      "  | Nat.zero => acc\n  | Nat.succ k => accumulate k (Nat.succ acc)\nend Math\n" ++
      "def result : Nat := Math.accumulate 4 8\n")
  checkExecuted "Lean local self-name shadow is not recursion" .lean
    ("namespace Math\ndef count (n : Nat) : Nat := match n with\n" ++
      "  | Nat.zero => 0\n" ++
      "  | Nat.succ k => let count : Nat -> Nat := fun (x : Nat) => x; count k\n" ++
      "end Math\ndef result : Nat := Math.count 4\n") natType (.lit (.natural 3))
  rejectedStructural "Lean namespaced self cannot escape" .lean
    ("namespace Math\ndef bad (n : Nat) : Nat := match n with\n" ++
      "  | Nat.zero => 0\n" ++
      "  | Nat.succ k => let escaped : Nat -> Nat := bad; escaped k\nend Math\n")
    (fun error => match error with | .structuralRecursionEscapingReference => true | _ => false)
  rejectedStructural "Lean qualified self must decrease" .lean
    ("namespace Math\ndef bad (n : Nat) : Nat := match n with\n" ++
      "  | Nat.zero => 0\n  | Nat.succ k => Math.bad (Nat.succ k)\nend Math\n")
    (fun error => match error with | .structuralRecursionNotDecreasing => true | _ => false)

private def testProofScript : IO Unit := do
  let natType := PsExpr.constE psNatName []
  checkExecuted "PS local parameter shadows namespace declaration" .proofScript
    ("namespace A\ndef value : Nat := 7\n" ++
      "def choose(value : Nat) : Nat := value\nend A\n" ++
      "def result : Nat := A.choose(11)\n") natType (.lit (.natural 11))
  checkExecuted "PS namespace-local pure wins over contextual sugar" .proofScript
    ("namespace A\ndef pure(x : Nat) : Id(Nat) := Nat.add(x, 100)\n" ++
      "def run : Id(Nat) := do {\n  pure(2)\n}\nend A\n" ++
      "def result : Nat := Id.run(A.run)\n") natType (.lit (.natural 102))
  rejectedType "PS ill-typed namespace-local pure is not rewritten" .proofScript
    ("namespace A\ndef pure(x : Nat) : Nat := x\n" ++
      "def run : Except(String, Nat) := do {\n  pure(2)\n}\nend A\n")
  checkExecuted "PS namespace-qualified constructor patterns" .proofScript
    ("namespace Model\ninductive Flag where {\n  | off\n  | on\n}\n" ++
      "def decide(flag : Flag) : Nat := match flag with {\n" ++
      "  | Flag.off => 0\n  | Flag.on => 11\n}\nend Model\n" ++
      "def result : Nat := Model.decide(Model.Flag.on)\n") natType (.lit (.natural 11))
  checkExecuted "PS namespaced structure and qualified global projection" .proofScript
    ("namespace Model\nstructure Box where {\n  value : Nat\n}\n" ++
      "def box : Box := { value := 13 }\nend Model\n" ++
      "def result : Nat := Model.box.value\n") natType (.lit (.natural 13))
  checkExecuted "PS namespaced structural self" .proofScript
    ("namespace Math\ndef count(n : Nat) : Nat := match n with {\n" ++
      "  | Nat.zero => 0\n  | Nat.succ k => Nat.succ(count(k))\n}\nend Math\n" ++
      "def result : Nat := Math.count(4)\n") natType (.lit (.natural 4))
  checkNormalized "PS namespaced structural fallback keeps qualified worker" .proofScript
    ("namespace Math\ndef accumulate(n : Nat, acc : Nat) : Nat := match n with {\n" ++
      "  | Nat.zero => acc\n  | Nat.succ k => accumulate(k, Nat.succ(acc))\n}\nend Math\n" ++
      "def result : Nat := Math.accumulate(4, 8)\n")
  checkExecuted "PS local self-name shadow is not recursion" .proofScript
    ("namespace Math\ndef count(n : Nat) : Nat := match n with {\n" ++
      "  | Nat.zero => 0\n" ++
      "  | Nat.succ k => let count : Nat -> Nat := fun (x : Nat) => x\n    count(k)\n" ++
      "}\nend Math\ndef result : Nat := Math.count(4)\n") natType (.lit (.natural 3))
  rejectedStructural "PS namespaced self cannot escape" .proofScript
    ("namespace Math\ndef bad(n : Nat) : Nat := match n with {\n" ++
      "  | Nat.zero => 0\n" ++
      "  | Nat.succ k => let escaped : Nat -> Nat := bad\n    escaped(k)\n}\nend Math\n")
    (fun error => match error with | .structuralRecursionEscapingReference => true | _ => false)
  rejectedStructural "PS qualified self must decrease" .proofScript
    ("namespace Math\ndef bad(n : Nat) : Nat := match n with {\n" ++
      "  | Nat.zero => 0\n  | Nat.succ k => Math.bad(Nat.succ(k))\n}\nend Math\n")
    (fun error => match error with | .structuralRecursionNotDecreasing => true | _ => false)

private def testWhile : IO Unit := do
  checkWhile "Lean namespace partial self captured by while" .lean .proofScript
    ("namespace Loop\npartial def prior (n : Nat) : Id Nat := do\n" ++
      "  if Nat.beq n 0 then\n    return 0\n" ++
      "  let mut i := 0\n" ++
      "  while Nat.blt i 1 do\n" ++
      "    let previous : Nat := Id.run (prior (Nat.sub n 1))\n" ++
      "    return Nat.succ previous\n" ++
      "  return 999\nend Loop\n" ++
      "def result : Nat := Id.run (Loop.prior 3)\n")
  checkWhile "PS namespace partial self captured by while" .proofScript .lean
    ("namespace Loop\npartial def prior(n : Nat) : Id(Nat) := do {\n" ++
      "  if (Nat.beq(n, 0)) { return 0 }\n" ++
      "  let mut i := 0\n" ++
      "  while (Nat.blt(i, 1)) {\n" ++
      "    let previous : Nat := Id.run(prior(Nat.sub(n, 1)))\n" ++
      "    return Nat.succ(previous)\n  }\n" ++
      "  return 999\n}\nend Loop\n" ++
      "def result : Nat := Id.run(Loop.prior(3))\n")

def main : IO Unit := do
  testShared "Lean" .lean .proofScript
  testShared "PS" .proofScript .lean
  testLean
  testProofScript
  testWhile
  IO.println "PSC1_NAMESPACE_TESTS: PASS"
