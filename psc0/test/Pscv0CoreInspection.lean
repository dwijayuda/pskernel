import Ps.Host.NativeV7
import PsKernelLean.Admission
import Ps.Environment.CompilerSourceCandidate
import Ps.Elab.Inspection
import Ps.Syntax.Translate

namespace CoreInspectionQualification

private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("CORE-INSPECTION: " ++ message))

private def fromExcept {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError ("CORE-INSPECTION: " ++ message))

private def containsText (needle value : String) : Bool :=
  (value.splitOn needle).length > 1

private structure Expected where
  exactText : Option String := none
  fragments : List String := []
  absent : List String := []
  deriving Lean.ToJson

private def exactMessage (value : String) : Expected := { exactText := some value }

-- Actual values and formatter dictionaries from the pinned native toolchain.
private def nativeScalarMessages : List Expected := [
  exactMessage (reprStr (37 + 5 : Nat)),
  exactMessage (reprStr (-7 : Int)),
  exactMessage (reprStr true),
  exactMessage (reprStr "λ\n"),
  exactMessage (reprStr 'λ'),
  exactMessage (reprStr ([1, 2, 3] : List Nat)),
  exactMessage (reprStr (#[1, 2, 3] : Array Nat)),
  exactMessage (reprStr (some 7 : Option Nat)),
  exactMessage (reprStr ((1, true) : Nat × Bool)),
  exactMessage (reprStr ((255 : UInt8) + 2)),
  exactMessage (reprStr ((18446744073709551615 : UInt64) + 2)),
  exactMessage (reprStr ((0.25 : Float) + 1.5)),
  exactMessage (reprStr ((0.25 : Float32) + 1.5)),
  exactMessage (reprStr System.Platform.numBits),
  exactMessage (reprStr (String.length "λ")),
  exactMessage (reprStr (String.hash "λ").toNat),
  exactMessage (reprStr (mixHash 1 2).toNat)]

private structure Fixture where
  label : String
  leanSource : String
  psSource : String
  expected : List Expected
  nativeExpected : List Expected

private def fixtures : List Fixture := [
  { label := "core-statements"
    leanSource := "def coreInspectionStep (n : Nat) : Nat := n + 1\n#check coreInspectionStep\n#check (coreInspectionStep 41)\n#check (_ : Nat)\n#reduce coreInspectionStep 41\n#print coreInspectionStep\n#print axioms coreInspectionStep\n"
    psSource := "function coreInspectionStep(n: Nat): Nat := n + 1\n#check coreInspectionStep\n#check coreInspectionStep(41)\n#check (_ : Nat)\n#reduce coreInspectionStep(41)\n#print coreInspectionStep\n#print axioms coreInspectionStep\n"
    expected := [{ fragments := ["coreInspectionStep", "Nat"] }, { fragments := ["coreInspectionStep", "Nat"] }, { fragments := ["?m", "Nat"] }, { exactText := some "42" }, { fragments := ["def coreInspectionStep", "Nat", ":="] }, { exactText := some "'coreInspectionStep' does not depend on any axioms" }]
    nativeExpected := [{ fragments := ["coreInspectionStep", "Nat"] }, { fragments := ["coreInspectionStep", "Nat"] }, { fragments := ["Nat", "?"] }, { exactText := some "42" }, { fragments := ["def coreInspectionStep", "Nat", ":="] }, { exactText := some "'coreInspectionStep' does not depend on any axioms" }] },
  { label := "lexical-check"
    leanSource := "section InspectionScope\nvariable (A : Type) (x : A)\n#check x\n#check (fun (x : Nat) => x)\nend InspectionScope\ndef coreInspectionScopedStamp : Nat := 1\n"
    psSource := "section InspectionScope\nvariable (A: Type) (x: A)\n#check x\n#check (fun (x: Nat) => x)\nend InspectionScope\nconst coreInspectionScopedStamp: Nat := 1\n"
    expected := [{ exactText := some "x : A" }, { fragments := ["fun", "Nat"] }]
    nativeExpected := [{ exactText := some "x : A" }, { fragments := ["fun", "Nat"] }] },
  { label := "pure-foundation-values"
    leanSource := "def coreInspectionScalarStamp : Nat := 1\n#eval (37 + 5 : Nat)\n#eval (-7 : Int)\n#eval true\n#eval \"λ\\n\"\n#eval 'λ'\n#eval ([1, 2, 3] : List Nat)\n#eval (#[1, 2, 3] : Array Nat)\n#eval (some 7 : Option Nat)\n#eval ((1, true) : Nat × Bool)\n#eval ((255 : UInt8) + 2)\n#eval ((18446744073709551615 : UInt64) + 2)\n#eval ((0.25 : Float) + 1.5)\n#eval ((0.25 : Float32) + 1.5)\n#eval System.Platform.numBits\n#eval String.length \"λ\"\n#eval (String.hash \"λ\").toNat\n#eval (mixHash 1 2).toNat\n"
    psSource := "const coreInspectionScalarStamp: Nat := 1\n#eval (37 + 5 : Nat)\n#eval (-7 : Int)\n#eval true\n#eval \"λ\\n\"\n#eval 'λ'\n#eval ([1, 2, 3] : List(Nat))\n#eval (#[1, 2, 3] : Array(Nat))\n#eval (some(7) : Option(Nat))\n#eval ((1, true) : Prod(Nat, Bool))\n#eval ((255 : UInt8) + 2)\n#eval ((18446744073709551615 : UInt64) + 2)\n#eval ((0.25 : Float) + 1.5)\n#eval ((0.25 : Float32) + 1.5)\n#eval System.Platform.numBits\n#eval String.length(\"λ\")\n#eval UInt64.toNat(String.hash(\"λ\"))\n#eval UInt64.toNat(mixHash(1, 2))\n"
    expected := nativeScalarMessages
    nativeExpected := nativeScalarMessages },
  { label := "proposition-and-proof-erasure"
    leanSource := "def coreInspectionProofStamp : Nat := 1\n#eval (1 = 1)\n#eval (let h : True := Classical.choice (Nonempty.intro True.intro); 7)\n"
    psSource := "const coreInspectionProofStamp: Nat := 1\n#eval (1 = 1)\n#eval (let h: True := Classical.choice(Nonempty.intro(True.intro)); 7)\n"
    expected := [{ exactText := some "true" }, { exactText := some "7" }]
    nativeExpected := [{ exactText := some "true" }, { exactText := some "7" }] },
  { label := "automatic-repr"
    leanSource := "inductive CoreInspectionAuto where\n  | item (value : Nat)\n#eval CoreInspectionAuto.item 7\n"
    psSource := "inductive CoreInspectionAuto where { | item(value: Nat) }\n#eval CoreInspectionAuto.item(7)\n"
    expected := [{ exactText := some "CoreInspectionAuto.item 7" }]
    nativeExpected := [{ exactText := some "CoreInspectionAuto.item 7" }] },
  { label := "checked-to-string"
    leanSource := "inductive CoreInspectionDisplay where\n  | item (value : Nat)\ninstance coreInspectionDisplayToString : ToString CoreInspectionDisplay where\n  toString := fun _ => \"selected custom display\"\n#eval CoreInspectionDisplay.item 8\n"
    psSource := "inductive CoreInspectionDisplay where { | item(value: Nat) }\ninstance coreInspectionDisplayToString: ToString(CoreInspectionDisplay) where {\n  toString := fun _ => \"selected custom display\"\n}\n#eval CoreInspectionDisplay.item(8)\n"
    expected := [{ exactText := some "selected custom display" }]
    nativeExpected := [{ exactText := some "selected custom display" }] },
  { label := "repr-preference"
    leanSource := "inductive CoreInspectionPreferred where\n  | item (value : Nat)\n  deriving Repr\ninstance coreInspectionPreferredToString : ToString CoreInspectionPreferred where\n  toString := fun _ => \"must not select this fallback\"\n#eval CoreInspectionPreferred.item 9\n"
    psSource := "inductive CoreInspectionPreferred where { | item(value: Nat) } deriving Repr\ninstance coreInspectionPreferredToString: ToString(CoreInspectionPreferred) where {\n  toString := fun _ => \"must not select this fallback\"\n}\n#eval CoreInspectionPreferred.item(9)\n"
    expected := [{ exactText := some "CoreInspectionPreferred.item 9" }]
    nativeExpected := [{ exactText := some "CoreInspectionPreferred.item 9" }] },
  { label := "command-scope-and-call-interactions"
    leanSource := "namespace CoreInspectionMath\ndef twice (n : Nat) : Nat := n + n\ndef now (_ : Unit) : Nat := 23\nend CoreInspectionMath\n#check Nat.succ\n#check (CoreInspectionMath.twice 7)\n#eval CoreInspectionMath.now ()\n#reduce Nat.succ 2\n#print Nat.add\nopen CoreInspectionMath\nsection CoreInspectionCapture\nvariable (n : Nat)\ndef coreInspectionCaptured : Nat := twice n\n#check n\nend CoreInspectionCapture\n#check coreInspectionCaptured\n#eval coreInspectionCaptured 7\ndef «axioms» : Nat := 31\ndef «commands» : Nat := 37\n#print «axioms»\n#print «commands»\n#print axioms «commands»\n"
    psSource := "namespace CoreInspectionMath\nfunction twice(n: Nat): Nat := n + n\nfunction now(): Nat := 23\nend CoreInspectionMath\n#check Nat.succ\n#check (CoreInspectionMath.twice 7)\n#eval CoreInspectionMath.now()\n#reduce Nat.succ(2)\n#print Nat.add\nopen CoreInspectionMath\nsection CoreInspectionCapture\nvariable (n: Nat)\ndef coreInspectionCaptured: Nat := twice(n)\n#check n\nend CoreInspectionCapture\n#check coreInspectionCaptured\n#eval coreInspectionCaptured(7)\nconst «axioms»: Nat := 31\nconst «commands»: Nat := 37\n#print «axioms»\n#print «commands»\n#print axioms «commands»\n"
    expected := [{ fragments := ["Nat.succ", "Nat"] }, { fragments := ["CoreInspectionMath.twice", "Nat"] }, { exactText := some "23" }, { exactText := some "3" }, { fragments := ["Nat.add", "Nat"] }, { exactText := some "n : Nat" }, { fragments := ["coreInspectionCaptured", "Nat"] }, { exactText := some "14" }, { fragments := ["axioms", "Nat", ":="] }, { fragments := ["commands", "Nat", ":="] }, { exactText := some "'commands' does not depend on any axioms" }]
    nativeExpected := [{ fragments := ["Nat.succ", "Nat"] }, { fragments := ["CoreInspectionMath.twice", "Nat"] }, { exactText := some "23" }, { exactText := some "3" }, { fragments := ["Nat.add", "Nat"] }, { exactText := some "n : Nat" }, { fragments := ["coreInspectionCaptured", "Nat"] }, { exactText := some "14" }, { fragments := ["axioms", "Nat", ":="] }, { fragments := ["commands", "Nat", ":="] }, { exactText := some "'commands' does not depend on any axioms" }] }
]

private def checkMessages (label source : String) (expected : List Expected)
    (diagnostics : List PsDiagnostic) : IO Unit := do
  ensure (diagnostics.length == expected.length)
    (label ++ ": diagnostic count, got " ++ toString diagnostics.length)
  let mut previous := 0
  for (message, wanted) in diagnostics.zip expected do
    let .info := message.severity
      | throw (IO.userError ("CORE-INSPECTION: " ++ label ++ ": non-information diagnostic"))
    ensure (message.span.start.byteOffset >= previous &&
        message.span.start.byteOffset < message.span.stop.byteOffset &&
        message.span.stop.byteOffset <= source.utf8ByteSize)
      (label ++ ": command diagnostic lost its actual ordered source span")
    previous := message.span.stop.byteOffset
    if let some value := wanted.exactText then
      ensure (message.message == value)
        (label ++ ": wanted " ++ value ++ ", got " ++ message.message)
    for fragment in wanted.fragments do
      ensure (containsText fragment message.message)
        (label ++ ": missing " ++ fragment ++ " in " ++ message.message)
    for fragment in wanted.absent do
      ensure (!containsText fragment message.message)
        (label ++ ": unexpected " ++ fragment ++ " in " ++ message.message)

private def withoutInspections (program : PsSyntaxProgram) : PsSyntaxProgram :=
  { program with commands := program.commands.filter fun command =>
    match command with | .inspectionCmd .. => false | _ => true }

private def elaborate (program : PsSyntaxProgram) : IO PsCompilerEngineElaborated :=
  fromExcept ((psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program).mapError
    psCompilerPscv0Error)

private def checkPair (fixture : Fixture) : IO Unit := do
  let mut admissions : List String := []
  for (kind, source) in [(PsCompilerSourceKind.lean, fixture.leanSource),
      (.proofScript, fixture.psSource)] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    let result ← elaborate program
    checkMessages fixture.label source fixture.expected result.commandDiagnostics
    let ordinary ← elaborate (withoutInspections program)
    ensure (ordinary.declarations.length == result.declarations.length &&
      (ordinary.declarations.zip result.declarations).all (fun pair =>
        psInspectionDeclarationEqual pair.1 pair.2) &&
      ordinary.environment.instances.entries.length == result.environment.instances.entries.length &&
      ordinary.environment.classes.length == result.environment.classes.length &&
      ordinary.environment.exportedAliases.length == result.environment.exportedAliases.length &&
      ordinary.environment.inspectionDeclarations.length == result.environment.inspectionDeclarations.length)
      (fixture.label ++ ": inspection published a declaration, dictionary, alias or execution entry")
    let output ← fromExcept
      ((psCompilerEnginePrepareElaboratedWithOutput result).mapError psCompilerPscv0Error)
    checkMessages fixture.label source fixture.expected output.commandDiagnostics
    let baseline ← fromExcept
      ((psCompilerEnginePrepareElaboratedWithOutput ordinary).mapError psCompilerPscv0Error)
    ensure (output.admissions == baseline.admissions)
      (fixture.label ++ ": command-only data changed canonical admissions")
    let _ ← fromExcept ((← PsKernelLean.admitCanonicalAdmissions output.admissions).mapError (·.message))
    admissions := admissions ++ [output.admissions]
  let [left, right] := admissions
    | throw (IO.userError "CORE-INSPECTION: missing paired reader")
  ensure (left == right) (fixture.label ++ ": paired canonical declarations differ")
  IO.println ("CORE-INSPECTION paired commands: " ++ fixture.label)

private def checkFoundationSeam : IO Unit := do
  let environment ← fromExcept psCompilerSourceCandidateEnvironment
  let source := "function coreInspectionIdentity(n: Nat): Nat := n\n#check coreInspectionIdentity\n#reduce coreInspectionIdentity(7)\n"
  let program ← fromExcept (psCompilerParsePscv0 source .proofScript)
  let profile : PsCompilerProfileContext := {
    baseEnvironment := environment, runtimePrelude := fun _ _ => [] }
  let output ← fromExcept
    ((psCompilerEnginePreparePscv0WithOutput profile .proofScript source).mapError psCompilerPscv0Error)
  checkMessages "caller Foundation context" source
    [{ fragments := ["coreInspectionIdentity", "Nat"] }, { exactText := some "7" }]
    output.commandDiagnostics
  let ordinary ← fromExcept
    ((psCompilerEngineElaboratePscv0 profile (withoutInspections program)).mapError psCompilerPscv0Error)
  let baseline ← fromExcept
    ((psCompilerEnginePrepareElaboratedWithOutput ordinary).mapError psCompilerPscv0Error)
  ensure (output.admissions == baseline.admissions &&
      output.prepared.profile.baseEnvironment.declarations.length == environment.declarations.length)
    "Foundation command seam changed the supplied profile or admissions"

private def checkRefusals : IO Unit := do
  for (label, expected, leanSource, psSource) in [
    ("computational-choice", "Classical.choice", "#eval Classical.choice (Nonempty.intro (7 : Nat))\n", "#eval Classical.choice(Nonempty.intro((7 : Nat)))\n"),
    ("proof-result", "cannot evaluate a proof", "#eval True.intro\n", "#eval True.intro\n"),
    ("type-result", "cannot evaluate a type", "#eval Nat\n", "#eval Nat\n"),
    ("open-evaluation", "requires a closed value", "section\nvariable (x : Nat)\n#eval x\nend\n", "section\nvariable (x: Nat)\n#eval x\nend\n"),
    ("unresolved-evaluation", "PSCV0-UNSOLVED-INFERENCE", "#eval (_ : Nat)\n", "#eval (_ : Nat)\n"),
    ("verified-declaration-hole", "PSCV0-UNSOLVED-INFERENCE", "def coreInspectionHole : Nat := _\n", "const coreInspectionHole: Nat := _\n"),
    ("no-functional-formatter", "no Repr or ToString", "#eval (fun (x : Nat) => x)\n", "#eval (fun (x: Nat) => x)\n"),
    ("partial-is-not-total", "partial", "partial def coreInspectionPartial (n : Nat) : Nat := n\n#eval coreInspectionPartial 1\n", "partial function coreInspectionPartial(n: Nat): Nat := n\n#eval coreInspectionPartial(1)\n"),
    ("noncomputable-policy", "noncomputable", "noncomputable def coreInspectionChosen : Nat := Classical.choice (Nonempty.intro 7)\n#eval coreInspectionChosen\n", "noncomputable def coreInspectionChosen: Nat := Classical.choice(Nonempty.intro(7))\n#eval coreInspectionChosen\n")
      ] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanSource), (.proofScript, psSource)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
      | .error (.elaboration error) =>
        ensure (containsText expected (psCompilerPscv0ElabError error))
          (label ++ ": wrong elaboration owner: " ++ psCompilerPscv0ElabError error)
      | .error error => throw (IO.userError (label ++ ": wrong phase: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ ": incorrectly accepted"))
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "#eval IO.println \"hi\"\n"),
      (.proofScript, "#eval IO.println(\"hi\")\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
    | .error (.elaboration error) =>
      let message := psCompilerPscv0ElabError error
      ensure (containsText "unknown name IO" message ||
          containsText "requires a pure total value" message)
        ("closed-effect command lost its selected source/profile owner: " ++ message)
    | .error error => throw (IO.userError ("closed-effect command failed outside elaboration: " ++ psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError "closed-effect command was accepted")
  for source in ["#eval! 1\n", "#print commands\n", "#check_failure Nat\n",
      "#synth Inhabited Nat\n", "#guard true\n", "#eval_msgs 1\n"] do
    for kind in [PsCompilerSourceKind.lean, .proofScript] do
      match psCompilerParsePscv0 source kind with
      | .error message =>
        ensure (containsText "PSCV0-INSPECTION-COMMAND" message)
          ("excluded command had wrong grammar owner: " ++ message)
      | .ok _ => throw (IO.userError "excluded inspection command parsed")
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    match psCompilerParsePscv0 "set_option pp.universes true\n" kind with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "inspection accepted source-affecting set_option")
  for source in [
      "function f(n: Nat): Nat := n\n#check f (1)\n",
      "function f(n: Nat): Nat := n\n#eval f (1)\n",
      "function f(n: Nat): Nat := n\n#reduce f (1)\n"] do
    match psCompilerParsePscv0 source .proofScript with
    | .error message =>
      ensure (containsText "APP-02" message || containsText "APP02" message)
        ("inspection application bypassed APP02: " ++ message)
    | .ok _ => throw (IO.userError "inspection accepted spaced ProofScript application")

private def checkMetadataControls : IO Unit := do
  let base := psCompilerFullProfileContext.baseEnvironment
  let name := psRootName "coreInspectionMetadata"
  let declaration := PsDeclaration.definitionDecl name [] (.constE psNatName []) (.lit (.natural 1))
  let some environment := psEnvironmentAdd base declaration
    | throw (IO.userError "metadata fixture collision")
  let attached ← fromExcept (psInspectionAttach environment [{ declaration }])
  ensure (attached.declarations.length == environment.declarations.length &&
      attached.instances.entries.length == environment.instances.entries.length)
    "inspection metadata entered ordinary declaration or instance lookup"
  let changed := PsDeclaration.definitionDecl name [] (.constE psNatName []) (.lit (.natural 2))
  let refuse := fun (label : String) (value : Except String PsEnvironment) => do
    match value with
    | .error message => ensure (containsText "PSCV0-INSPECTION: conflicting" message)
        (label ++ ": wrong metadata refusal")
    | .ok _ => throw (IO.userError ("metadata conflict accepted: " ++ label))
  refuse "visible body" (psInspectionAttach environment [{ declaration := changed }])
  refuse "noncomputable policy" (psInspectionAttach
    (psEnvironmentMarkNoncomputable environment name) [{ declaration }])
  let hiddenName := psRootName "coreInspectionMetadataHidden"
  let hidden := PsDeclaration.definitionDecl hiddenName [] (.constE psNatName []) (.lit (.natural 3))
  let hiddenView ← fromExcept (psInspectionAttach base [{ declaration := hidden }])
  ensure (!psEnvironmentContains hiddenView hiddenName &&
      hiddenView.instances.entries.length == base.instances.entries.length &&
      hiddenView.exportedAliases.length == base.exportedAliases.length)
    "diagnostic-only hidden identity entered source lookup"
  let execution ← fromExcept (psInspectionExecutionEnvironment hiddenView)
  ensure (psEnvironmentContains execution hiddenName && !psEnvironmentContains hiddenView hiddenName)
    "temporary execution view changed its source environment"
  let changedHidden := PsDeclaration.definitionDecl hiddenName [] (.constE psNatName []) (.lit (.natural 4))
  refuse "duplicate closure body" (psInspectionAttach hiddenView [{ declaration := changedHidden }])
  let recursorName := psNameAppendStr psNatName "rec"
  let some recursor := psEnvironmentFindRecursor base recursorName
    | throw (IO.userError "missing checked Nat recursor")
  refuse "recursor family identity" (psInspectionAttach base [{
    declaration := .recursorDecl { recursor with inductiveNames := [psBoolName] } }])
  refuse "recursor minor count" (psInspectionAttach base [{
    declaration := .recursorDecl { recursor with numMinors := recursor.numMinors + 1 } }])
  let context := psElabContextEmpty base
  match psInspectionNormalize 0 context false (.lit (.natural 7)) with
  | .error .fuelExhausted => pure ()
  | _ => throw (IO.userError "normalizer reported a successful fuel-truncated residual")
  match psInspectionAxioms 0 base [psNatName] [] [] with
  | .error .fuelExhausted => pure ()
  | _ => throw (IO.userError "axiom closure reported a successful truncated graph")

private def inspectionProviderSource (kind : PsCompilerSourceKind) : String :=
  match kind with
  | .lean => "module\nprivate def coreInspectionHidden (n : Nat) : Nat := n + 1\npublic def coreInspectionPublic (n : Nat) : Nat := coreInspectionHidden n\nprivate theorem coreInspectionHiddenExt (p q : Prop) (h : Iff p q) : p = q := propext h\npublic theorem coreInspectionPublicExt (p q : Prop) (h : Iff p q) : p = q :=\n  coreInspectionHiddenExt p q h\n"
  | .proofScript => "private function coreInspectionHidden(n: Nat): Nat := n + 1\nfunction coreInspectionPublic(n: Nat): Nat := coreInspectionHidden(n)\nprivate theorem coreInspectionHiddenExt(p q: Prop, h: Iff(p, q)): p = q := propext(h)\ntheorem coreInspectionPublicExt(p q: Prop, h: Iff(p, q)): p = q :=\n  coreInspectionHiddenExt(p, q, h)\n"

private def inspectionFacadeSource (kind : PsCompilerSourceKind) : String :=
  match kind with
  | .lean => "module\nimport InspectionProvider\npublic def coreInspectionFacade (n : Nat) : Nat := coreInspectionPublic n\npublic theorem coreInspectionFacadeExt (p q : Prop) (h : Iff p q) : p = q :=\n  coreInspectionPublicExt p q h\n"
  | .proofScript => "import InspectionProvider\nfunction coreInspectionFacade(n: Nat): Nat := coreInspectionPublic(n)\ntheorem coreInspectionFacadeExt(p q: Prop, h: Iff(p, q)): p = q :=\n  coreInspectionPublicExt(p, q, h)\n"

private def inspectionEntrySource (kind : PsCompilerSourceKind) : String :=
  match kind with
  | .lean => "module\nimport InspectionFacade\n#eval coreInspectionFacade 41\n#reduce coreInspectionFacade 41\n#print coreInspectionFacade\n#print axioms coreInspectionFacadeExt\n"
  | .proofScript => "import InspectionFacade\n#eval coreInspectionFacade(41)\n#reduce coreInspectionFacade(41)\n#print coreInspectionFacade\n#print axioms coreInspectionFacadeExt\n"

private def projectExpected : List Expected := [
  { exactText := some "42" },
  { fragments := ["coreInspectionFacade", "41"], absent := ["42"] },
  { fragments := ["coreInspectionFacade", "Nat"] },
  { exactText := some "'coreInspectionFacadeExt' depends on axioms: [propext]" }]

private def moduleSource (kind : PsCompilerSourceKind) (name source : String) : PsPscv0ModuleSource :=
  { name, source, sourceKind := kind, sourceName := name ++ psCompilerSourceKindExtension kind }

private def projectModules (kind : PsCompilerSourceKind) : List PsPscv0ModuleSource := [
  moduleSource kind "InspectionProvider" (inspectionProviderSource kind),
  moduleSource kind "InspectionFacade" (inspectionFacadeSource kind),
  moduleSource kind "InspectionEntry" (inspectionEntrySource kind)]

private def checkProject : IO Unit := do
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let output ← fromExcept (psCompilerEnginePreparePscv0Project
      psCompilerFullProfileContext "InspectionEntry" (projectModules kind))
    let some origin := output.origins.find? (fun item => item.moduleName == "InspectionEntry")
      | throw (IO.userError "inspection-only entry lost its source provenance")
    ensure (origin.batches.isEmpty && origin.source == inspectionEntrySource kind &&
        origin.sourceName == "InspectionEntry" ++ psCompilerSourceKindExtension kind)
      "inspection-only entry acquired a fake declaration origin"
    checkMessages "private implementation closure" origin.source projectExpected origin.commandDiagnostics
    let some provider := output.moduleProfiles.find? (fun item => item.name == "InspectionProvider")
      | throw (IO.userError "missing provider receipt")
    ensure (!provider.privateNames.isEmpty && provider.privateNames.all (fun name =>
        !provider.interface.declarations.any (fun declaration =>
          psNameEq (psDeclarationName declaration) name)))
      "inspection closure leaked a private declaration into the source interface"
    let _ ← fromExcept ((← PsKernelLean.admitCanonicalAdmissions output.admissions).mapError (·.message))
    let hidden := (match kind with | .lean => "module\n" | .proofScript => "") ++
      "import InspectionFacade\n#check coreInspectionHidden\n"
    let sources := (projectModules kind).take 2 ++ [
      moduleSource kind "InspectionEntry" hidden]
    match psCompilerEnginePreparePscv0Project psCompilerFullProfileContext "InspectionEntry" sources with
    | .error message =>
      ensure (containsText "unknown name coreInspectionHidden" message)
        ("private direct reference refused at wrong owner: " ++ message)
    | .ok _ => throw (IO.userError "inspection resolved a hidden implementation identifier")

private def checkHostDiagnostics : IO Unit := do
  let some first := fixtures.head? | throw (IO.userError "missing command fixture")
  let commandOnly := "#check Nat\n#reduce 1 + 1\n#eval false\n"
  let onlyExpected : List Expected :=
    [{ exactText := some "Nat : Type" }, { exactText := some "2" }, { exactText := some "false" }]
  let inputs : List (PsV7Native.Request × List Expected) :=
    [({ source := first.leanSource, sourceKind := .lean, sourceName := "inspection.lean" }, first.expected),
     ({ source := first.psSource, sourceKind := .proofScript, sourceName := "inspection.ps" }, first.expected),
     ({ source := commandOnly, sourceKind := .proofScript, sourceName := "only.ps" }, onlyExpected)] ++
    [PsCompilerSourceKind.lean, .proofScript].map fun kind =>
      ({ source := inspectionEntrySource kind, sourceKind := kind,
         sourceName := "InspectionEntry" ++ psCompilerSourceKindExtension kind,
         moduleName := "InspectionEntry", modules := (projectModules kind).take 2 },
       projectExpected)
  let batch ← match ← PsV7Native.runBatch (inputs.map Prod.fst).toArray with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == inputs.length) "host omitted an inspection request"
  for ((request, expected), result) in inputs.zip batch.results.toList do
    let result ← match result with
      | .ok value => pure value
      | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
    ensure (result.artifacts.isEmpty &&
        result.diagnostics.all (fun item => item.sourceName == request.sourceName))
      "host diagnostics lost their real source file"
    checkMessages "host diagnostic metadata" request.source expected
      (result.diagnostics.map (·.diagnostic))
    if request.sourceName == "only.ps" then
      ensure (result.declarationCount == 0)
        "inspection-only source acquired a fake checked declaration"

-- Legacy translation accepts declaration-only modules. Program commands must
-- be refused at that API, never silently removed from a successful rendering.
private def checkLegacyTranslationBoundary : IO Unit := do
  let baseline := "def coreInspectionTranslation : Nat := 1\n"
  let _ ← fromExcept ((psTranslateLeanToProofScript baseline).mapError
    (fun _ => "legacy native declaration baseline failed"))
  let _ ← fromExcept ((psTranslateProofScriptToLean baseline).mapError
    (fun _ => "legacy ProofScript declaration baseline failed"))
  let _ ← fromExcept (psPscv0TranslateReadable false true baseline)
  let _ ← fromExcept (psPscv0TranslateReadable true false baseline)
  for source in [
      baseline ++ "#check coreInspectionTranslation\n",
      "namespace InspectionTranslation\n" ++ baseline ++ "end InspectionTranslation\n"] do
    match psTranslateLeanToProofScript source with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "legacy native translation silently erased program commands")
    match psPscv0TranslateReadable false true source with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "legacy native surface translation accepted program commands")
    match psTranslateProofScriptToLean source with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "legacy ProofScript translation silently erased program commands")
    match psPscv0TranslateReadable true false source with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "legacy ProofScript surface translation accepted program commands")

private def nativeCase (name source : String) (expected : List Expected := [])
    (errors : List String := []) : Lean.Json :=
  Lean.Json.mkObj [
    ("name", Lean.toJson name), ("source", Lean.toJson source),
    ("messages", Lean.toJson expected), ("errors", Lean.toJson errors)]

private def nativeManifest : Lean.Json :=
  let ordinary := fixtures.zipIdx.map fun (fixture, index) =>
    nativeCase ("Inspection" ++ toString index) fixture.leanSource fixture.nativeExpected
  let modules := [
    nativeCase "InspectionProvider" (inspectionProviderSource .lean),
    nativeCase "InspectionFacade" (inspectionFacadeSource .lean),
    nativeCase "InspectionEntry" (inspectionEntrySource .lean) projectExpected,
    nativeCase "InspectionHiddenRefusal"
      "module\nimport InspectionFacade\n#check coreInspectionHidden\n" []
      ["Unknown identifier", "coreInspectionHidden"]]
  let refusalControls := [
    nativeCase "InspectionNativeProofRefusal" "#eval True.intro\n" []
      ["proofs are not computationally relevant"],
    nativeCase "InspectionNativeTypeRefusal" "#eval Nat\n" []
      ["types are not computationally relevant"],
    nativeCase "InspectionNativeOpenRefusal"
      "section\nvariable (x : Nat)\n#eval x\nend\n" [] ["contains free variable"],
    nativeCase "InspectionNativeFormatterRefusal" "#eval (fun (x : Nat) => x)\n" []
      ["could not synthesize", "Repr", "ToString"],
    nativeCase "InspectionNativeChoiceRefusal"
      "#eval Classical.choice (Nonempty.intro (7 : Nat))\n" [] ["Classical.choice"]]
  -- Native #eval can execute partial programs. The selected M2 command keeps
  -- its documented pure-total boundary, independently of native execution.
  let policyControl := nativeCase "InspectionNativePartialPolicy"
    "partial def coreInspectionPartial (n : Nat) : Nat := n\n#eval coreInspectionPartial 1\n"
    [{ exactText := some "1" }]
  Lean.Json.mkObj [
    ("schema", Lean.toJson ("psc0-core-inspection-native-fixtures/1" : String)),
    ("nativeVersion", Lean.toJson Lean.versionString),
    ("nativeCommit", Lean.toJson Lean.githash),
    ("cases", Lean.Json.arr (ordinary ++ modules ++ refusalControls ++ [policyControl]).toArray)]

def run (directory : String) : IO Unit := do
  ensure (Lean.versionString == "4.35.0" &&
      Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc")
    "expected the pinned official native toolchain"
  let _ ← fromExcept psCompilerValidatePscv0Standard
  let root := System.FilePath.mk directory
  IO.FS.createDirAll root
  IO.FS.writeFile (root / "native-fixtures.json") nativeManifest.pretty
  checkFoundationSeam
  for fixture in fixtures do checkPair fixture
  checkRefusals
  checkMetadataControls
  checkProject
  checkHostDiagnostics
  checkLegacyTranslationBoundary
  IO.FS.writeFile (root / "portable-report.json") (Lean.Json.mkObj [
    ("schema", Lean.toJson ("psc0-core-inspection-qualification/1" : String)),
    ("status", Lean.toJson ("PASS" : String)),
    ("pairedGroups", Lean.toJson fixtures.length),
    ("pairedCommandDiagnostics", Lean.toJson (82 : Nat)),
    ("pairedProjectGraphs", Lean.toJson (2 : Nat)),
    ("semanticRefusals", Lean.toJson (20 : Nat)),
    ("grammarRefusals", Lean.toJson (17 : Nat)),
    ("closedEffectRefusals", Lean.toJson (2 : Nat)),
    ("closedEffectMayFailAtUnavailableProfile", Lean.toJson true),
    ("privateReferenceRefusals", Lean.toJson (2 : Nat)),
    ("metadataConflictRefusals", Lean.toJson (5 : Nat)),
    ("resourceRefusals", Lean.toJson (2 : Nat)),
    ("legacyTranslationRefusals", Lean.toJson (8 : Nat)),
    ("hostRequests", Lean.toJson (5 : Nat)),
    ("nativeValueObservations", Lean.toJson (17 : Nat)),
    ("declarationOnlyTranslationAcceptsPrograms", Lean.toJson false),
    ("nativeCommandOracleQualified", Lean.toJson false),
    ("completeCoreProfileQualified", Lean.toJson false),
    ("compilerSelfhostQualified", Lean.toJson false)]).pretty
  IO.println "PSCV0_CORE_INSPECTION: PASS paired command semantics, unchanged independent admissions, actual module implementation closure, privacy/refusal controls and host diagnostics; native command oracle follows"

end CoreInspectionQualification

def main (arguments : List String) : IO Unit := do
  let [directory] := arguments
    | throw (IO.userError "expected inspection output directory")
  CoreInspectionQualification.run directory
