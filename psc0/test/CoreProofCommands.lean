import Ps.Host.NativeV7
import Ps.Compiler.Pscv0ModuleEngine
import Ps.Syntax.PrintLean
import Ps.Syntax.PrintProofScript
import PsKernelLean.Admission
import PsKernelLean.Replay
import PsKernelLean.Protocol

-- The native commands below are compiled by the exact same pinned Lean as the
-- surrounding qualification gate. Portable source readers run independently.
namespace CoreProofCommandsOracle
structure CoreProofPair (P Q : Prop) : Prop where
  left : P
  right : Q

inductive CoreProofChoice (P : Prop) : Prop where
  | first (proof : P)
  | second (proof : P)

def CoreProofAlias (P : Prop) : Prop := P → P

theorem coreProofIntroNamed (P Q : Prop) (hp : P) : Q → P := by
  intros hq
  exact hp

theorem coreProofIntrosRaw (P : Prop) : P → P := by
  intros
  assumption

theorem coreProofIntrosAliasStop (P : Prop) : CoreProofAlias P := by
  intros
  exact fun (h : P) => h

theorem coreProofIntrosAliasNamed (P : Prop) : CoreProofAlias P := by
  intros h
  exact h

theorem coreProofIntroLet (P : Prop) (hp : P) : (let Q : Prop := P; Q) := by
  intro Q
  exact hp

theorem coreProofIntroUnderscore (P : Prop) : P → P := by
  intro «_»
  assumption

theorem coreProofIntroIndented (P Q : Prop) : P → Q → P := by
  intros
    hp
    hq
  exact hp

theorem coreProofConstructorFirst (P : Prop) (hp : P) : CoreProofChoice P := by
  constructor!
  exact hp

theorem coreProofAndThen (P : Prop) (hp : P) :
    CoreProofPair (CoreProofPair P P) (CoreProofPair P P) := by
  constructor! <;> constructor! <;> exact hp

theorem coreProofAndThenSiblings (P Q : Prop) (hp : P) (hq : Q) :
    CoreProofPair (CoreProofPair P P) Q := by
  constructor!
  constructor! <;> exact hp
  exact hq

theorem coreProofAndThenGroup (P : Prop) : CoreProofPair (P → P) (P → P) := by
  constructor! <;> (
    intro h
    exact h
  )

theorem coreProofAndThenClosed (P : Prop) (hp : P) : P := by
  exact hp <;> assumption

theorem coreProofSuffices (P : Prop) (hp : P) : P := by
  suffices h : P from h
  exact hp

theorem coreProofSufficesDefault (P : Prop) (hp : P) : P := by
  suffices P from this
  exact hp

theorem coreProofSufficesBy (P : Prop) (hp : P) : P := by
  suffices h : P by
    exact h
  exact hp

theorem coreProofSufficesHole (P : Prop) (hp : P) : P := by
  suffices h : P from _
  exact hp
  exact h

theorem coreProofSufficesTerm (P : Prop) (hp : P) : P :=
  suffices h : P from h
  hp

theorem coreProofSufficesDependent (A : Type) (p : A → Prop) (a : A) (hp : p a) :
    p a := by
  suffices h : p a from h
  exact hp

def coreProofNeedDecision (P : Prop) [Decidable P] : True := True.intro
def coreProofDecision (P : Prop) [d : Decidable P] : Bool := Decidable.decide P

theorem coreProofClassical (P : Prop) : True := by
  classical
  exact coreProofNeedDecision P

theorem coreProofClassicalLocal (P : Prop) [d : Decidable P] :
    coreProofDecision P (d := d) = coreProofDecision P (d := d) := by
  classical
  exact Eq.refl (coreProofDecision P)

theorem coreProofClassicalOrdinary : coreProofDecision True = true := by
  classical
  exact Eq.refl true

def checkNativeRefusal (label : String) (parseOnly : Bool) (source : String) :
    Lean.Elab.Command.CommandElabM Unit := do
  let saved ← get
  try
    modify fun (state : Lean.Elab.Command.State) =>
      { state with messages := Lean.MessageLog.empty, snapshotTasks := #[] }
    match Lean.Parser.runParserCategory (← Lean.getEnv) (Lean.Name.mkSimple "command") source with
    | .error message => do
      unless parseOnly do throwError "{label} failed before native elaboration: {message}"
      if ["heartbeat", "recursion depth", "timeout"].any
          (fun word => (message.splitOn word).length > 1) then
        throwError "{label} exhausted native parser resources: {message}"
    | .ok command => do
      if parseOnly then throwError "{label} escaped native command grammar"
      let messages ← Lean.Elab.Tactic.GuardMsgs.runAndCollectMessages command
      let errors := messages.toList.filter fun message => message.severity == .error
      if errors.isEmpty then throwError "{label} was accepted by the pinned native elaborator"
      for message in errors do
        let content ← message.data.toString
        if ["heartbeat", "recursion depth", "maximum recursion", "timeout"].any
            (fun word => (content.splitOn word).length > 1) then
          throwError "{label} exhausted native elaboration resources: {content}"
  finally
    set saved

run_cmd do
  for (label, parseOnly, source) in [
    ("intros stops at a definition", false, "theorem bad (P : Prop) : CoreProofAlias P := by\n  intros\n  assumption\n"),
    ("quoted underscore remains inaccessible", false, "theorem bad (P : Prop) : P → P := by\n  intro «_»\n  exact «_»\n"),
    ("too many named introductions", false, "theorem bad (P : Prop) : P → P := by\n  intros h k\n  exact h\n"),
    ("suffices antecedent excludes its assumption", false, "theorem bad (P : Prop) : P := by\n  suffices h : P from h\n  exact h\n"),
    ("suffices proof has the original target", false, "theorem bad (P Q : Prop) (hp : P) : Q := by\n  suffices h : P from h\n  exact hp\n"),
    ("suffices cannot discard its proof hole", false, "theorem bad (P : Prop) (hp : P) : P := by\n  suffices h : P from _\n  exact hp\n"),
    ("and-then checks every generated goal", false, "theorem bad (P Q : Prop) (hp : P) : CoreProofPair P Q := by\n  constructor! <;> exact hp\n"),
    ("classical does not leak to a sibling goal", false, "theorem bad (P : Prop) : And True True := by\n  constructor!\n  case left =>\n    classical\n    exact coreProofNeedDecision P\n  case right =>\n    exact coreProofNeedDecision P\n"),
    ("missing and-then operand", true, "theorem bad (P : Prop) (hp : P) : P := by\n  exact hp <;>\n"),
    ("empty classical scope", true, "theorem bad (P : Prop) (hp : P) : P := by\n  classical\n"),
    ("empty parenthesized tactic", true, "theorem bad (P : Prop) (hp : P) : P := by\n  ()\n"),
    ("suffices needs a proof separator", true, "theorem bad (P : Prop) (hp : P) : P := by\n  suffices h : P\n")] do
    checkNativeRefusal label parseOnly source


theorem coreProofBraced (P : Prop) (hp : P) : P := by
  { exact hp
  }

theorem coreProofClassicalBraced (P : Prop) : True := by
  classical {
    exact coreProofNeedDecision P
  }

run_cmd do
  checkNativeRefusal "an empty braced group leaves its focused goal" false "theorem bad (P : Prop) (hp : P) : P := by\n  {}\n"
  checkNativeRefusal "an empty braced classical scope leaves its goal" false "theorem bad (P : Prop) (hp : P) : P := by\n  classical {}\n"
  checkNativeRefusal "classical braces end their decision scope" false "theorem bad (P : Prop) : And True True := by\n  constructor!\n  classical {\n    exact coreProofNeedDecision P\n  }\n  exact coreProofNeedDecision P\n"

end CoreProofCommandsOracle

namespace CoreProofCommands

private def pureLeanSource : String := "structure CoreProofPair (P Q : Prop) : Prop where\n  left : P\n  right : Q\n\ninductive CoreProofChoice (P : Prop) : Prop where\n  | first (proof : P)\n  | second (proof : P)\n\ndef CoreProofAlias (P : Prop) : Prop := P → P\n\ntheorem coreProofIntroNamed (P Q : Prop) (hp : P) : Q → P := by\n  intros hq\n  exact hp\n\ntheorem coreProofIntrosRaw (P : Prop) : P → P := by\n  intros\n  assumption\n\ntheorem coreProofIntrosAliasStop (P : Prop) : CoreProofAlias P := by\n  intros\n  exact fun (h : P) => h\n\ntheorem coreProofIntrosAliasNamed (P : Prop) : CoreProofAlias P := by\n  intros h\n  exact h\n\ntheorem coreProofIntroLet (P : Prop) (hp : P) : (let Q : Prop := P; Q) := by\n  intro Q\n  exact hp\n\ntheorem coreProofIntroUnderscore (P : Prop) : P → P := by\n  intro «_»\n  assumption\n\ntheorem coreProofIntroIndented (P Q : Prop) : P → Q → P := by\n  intros\n    hp\n    hq\n  exact hp\n\ntheorem coreProofConstructorFirst (P : Prop) (hp : P) : CoreProofChoice P := by\n  constructor!\n  exact hp\n\ntheorem coreProofAndThen (P : Prop) (hp : P) :\n    CoreProofPair (CoreProofPair P P) (CoreProofPair P P) := by\n  constructor! <;> constructor! <;> exact hp\n\ntheorem coreProofAndThenSiblings (P Q : Prop) (hp : P) (hq : Q) :\n    CoreProofPair (CoreProofPair P P) Q := by\n  constructor!\n  constructor! <;> exact hp\n  exact hq\n\ntheorem coreProofAndThenGroup (P : Prop) : CoreProofPair (P → P) (P → P) := by\n  constructor! <;> (\n    intro h\n    exact h\n  )\n\ntheorem coreProofAndThenClosed (P : Prop) (hp : P) : P := by\n  exact hp <;> assumption\n\ntheorem coreProofSuffices (P : Prop) (hp : P) : P := by\n  suffices h : P from h\n  exact hp\n\ntheorem coreProofSufficesDefault (P : Prop) (hp : P) : P := by\n  suffices P from this\n  exact hp\n\ntheorem coreProofSufficesBy (P : Prop) (hp : P) : P := by\n  suffices h : P by\n    exact h\n  exact hp\n\ntheorem coreProofSufficesHole (P : Prop) (hp : P) : P := by\n  suffices h : P from _\n  exact hp\n  exact h\n\ntheorem coreProofSufficesTerm (P : Prop) (hp : P) : P :=\n  suffices h : P from h\n  hp\n\ntheorem coreProofSufficesDependent (A : Type) (p : A → Prop) (a : A) (hp : p a) :\n    p a := by\n  suffices h : p a from h\n  exact hp\n\ntheorem coreProofBraced (P : Prop) (hp : P) : P := by\n  { exact hp\n  }\n"
private def purePsSource : String := "structure CoreProofPair(P: Prop, Q: Prop): Prop where {\n  left: P\n  right: Q\n}\ninductive CoreProofChoice(P: Prop): Prop where {\n  | first(proof: P)\n  | second(proof: P)\n}\nfunction CoreProofAlias(P: Prop): Prop := P -> P\n\ntheorem coreProofIntroNamed(P: Prop, Q: Prop, hp: P): Q -> P := by {\n  intros hq\n  exact hp\n}\ntheorem coreProofIntrosRaw(P: Prop): P -> P := by {\n  intros\n  assumption\n}\ntheorem coreProofIntrosAliasStop(P: Prop): CoreProofAlias(P) := by {\n  intros\n  exact fun (h: P) => h\n}\ntheorem coreProofIntrosAliasNamed(P: Prop): CoreProofAlias(P) := by {\n  intros h\n  exact h\n}\ntheorem coreProofIntroLet(P: Prop, hp: P): (let Q: Prop := P\n  Q) := by {\n  intro Q\n  exact hp\n}\ntheorem coreProofIntroUnderscore(P: Prop): P -> P := by {\n  intro «_»\n  assumption\n}\ntheorem coreProofIntroIndented(P: Prop, Q: Prop): P -> Q -> P := by {\n  intros\n    hp\n    hq\n  exact hp\n}\ntheorem coreProofConstructorFirst(P: Prop, hp: P): CoreProofChoice(P) := by {\n  constructor!\n  exact hp\n}\ntheorem coreProofAndThen(P: Prop, hp: P):\n    CoreProofPair(CoreProofPair(P, P), CoreProofPair(P, P)) := by {\n  constructor! <;> constructor! <;> exact hp\n}\ntheorem coreProofAndThenSiblings(P: Prop, Q: Prop, hp: P, hq: Q):\n    CoreProofPair(CoreProofPair(P, P), Q) := by {\n  constructor!\n  constructor! <;> exact hp\n  exact hq\n}\ntheorem coreProofAndThenGroup(P: Prop): CoreProofPair(P -> P, P -> P) := by {\n  constructor! <;> (\n    intro h\n    exact h\n  )\n}\ntheorem coreProofAndThenClosed(P: Prop, hp: P): P := by {\n  exact hp <;> assumption\n}\ntheorem coreProofSuffices(P: Prop, hp: P): P := by {\n  suffices h: P from h\n  exact hp\n}\ntheorem coreProofSufficesDefault(P: Prop, hp: P): P := by {\n  suffices P from this\n  exact hp\n}\ntheorem coreProofSufficesBy(P: Prop, hp: P): P := by {\n  suffices h: P by {\n    exact h\n  }\n  exact hp\n}\ntheorem coreProofSufficesHole(P: Prop, hp: P): P := by {\n  suffices h: P from _\n  exact hp\n  exact h\n}\ntheorem coreProofSufficesTerm(P: Prop, hp: P): P :=\n  suffices h: P from h\n  hp\ntheorem coreProofSufficesDependent(A: Type, p: A -> Prop, a: A, hp: p(a)):\n    p(a) := by {\n  suffices h: p(a) from h\n  exact hp\n}\n\ntheorem coreProofBraced(P: Prop, hp: P): P := by {\n  { exact hp\n  }\n}\n"
private def classicalLeanSource : String := "def coreProofNeedDecision (P : Prop) [Decidable P] : True := True.intro\ndef coreProofDecision (P : Prop) [d : Decidable P] : Bool := Decidable.decide P\n\ntheorem coreProofClassical (P : Prop) : True := by\n  classical\n  exact coreProofNeedDecision P\n\ntheorem coreProofClassicalLocal (P : Prop) [d : Decidable P] :\n    coreProofDecision P (d := d) = coreProofDecision P (d := d) := by\n  classical\n  exact Eq.refl (coreProofDecision P)\n\ntheorem coreProofClassicalOrdinary : coreProofDecision True = true := by\n  classical\n  exact Eq.refl true\n\ntheorem coreProofClassicalBraced (P : Prop) : True := by\n  classical {\n    exact coreProofNeedDecision P\n  }\n"
private def classicalPsSource : String := "function coreProofNeedDecision(P: Prop)[Decidable(P)]: True := True.intro\nfunction coreProofDecision(P: Prop)[d: Decidable(P)]: Bool := Decidable.decide(P)\n\ntheorem coreProofClassical(P: Prop): True := by {\n  classical\n  exact coreProofNeedDecision(P)\n}\ntheorem coreProofClassicalLocal(P: Prop)[d: Decidable(P)]:\n    coreProofDecision(P, d := d) = coreProofDecision(P, d := d) := by {\n  classical\n  exact Eq.refl(coreProofDecision(P))\n}\ntheorem coreProofClassicalOrdinary: coreProofDecision(True) = true := by {\n  classical\n  exact Eq.refl(true)\n}\n\ntheorem coreProofClassicalBraced(P: Prop): True := by {\n  classical {\n    exact coreProofNeedDecision(P)\n  }\n}\n"
private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("CORE-PROOF-COMMANDS: " ++ message))

private def fromExcept {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError ("CORE-PROOF-COMMANDS: " ++ message))

private def admit (seed : Lean.Kernel.Environment) (admissions : String) :
    IO Lean.Kernel.Environment := do
  let declarations ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions admissions).mapError
    (·.message))
  declarations.toList.foldlM (fun (current : Lean.Kernel.Environment) (declaration : Lean.Declaration) => do
    let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      (current.addDeclCore 2000000 20000
        (PsKernelLean.psKernelWithDefinitionHeight current declaration) none).mapError
        PsKernelLean.kernelExceptionSummary
    fromExcept checked) seed

def seedContext : IO (Lean.Kernel.Environment × PsCompilerProfileContext) := do
  let names := [psEqName, psNameAppendStr psEqName "refl", psNameAppendStr psEqName "rec"]
  let declarations := psLogicDeclarations.filter fun declaration =>
    names.any (psNameEq (psDeclarationName declaration))
  ensure (declarations.length == 3 &&
    (declarations.zip names).all (fun (declaration, name) => psNameEq (psDeclarationName declaration) name))
    "the explicit equality seed roster changed"
  ensure (match declarations with
    | [.inductiveDecl _, .constructorDecl _, .recursorDecl _] => true
    | _ => false) "the equality seed contains an assumption or changed declaration kind"
  let seed ← fromExcept ((← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations declarations).mapError
    (·.message))
  let environment ← declarations.foldlM (fun (environment : PsEnvironment) (declaration : PsDeclaration) => do
    let some next := psEnvironmentAdd environment declaration
      | throw (IO.userError "duplicate equality seed declaration")
    pure next) psEnvironmentEmpty
  ensure (environment.declarations.length == 3) "the equality seed gained declarations"
  for name in ["Nat", "Bool", "True", "False", "Classical.propDecidable"] do
    ensure (!(psEnvironmentContains environment (psSyntaxNameAppendSegments (name.splitOn ".") .anonymous)))
      ("the minimal fixture seed gained " ++ name)
  return (seed, { baseEnvironment := environment, runtimePrelude := fun _ _ => [] })

private def sameDeclarations (left right : List PsDeclaration) : IO Unit := do
  ensure (left.length == right.length) "paired source declaration counts differ"
  for (left, right) in left.zip right do
    ensure (psNameEq (psDeclarationName left) (psDeclarationName right))
      "paired source declaration identities differ"
    match left, right with
    | .definitionDecl _ ll lt lv, .definitionDecl _ rl rt rv
    | .theoremDecl _ ll lt lv, .theoremDecl _ rl rt rv =>
      ensure (psElabMutualLevelNamesEqual ll rl && psExprAlphaEq lt rt && psExprAlphaEq lv rv)
        ("paired checked values differ: " ++ psNameToString (psDeclarationName left))
    | .inductiveDecl l, .inductiveDecl r =>
      ensure (psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && l.numParams == r.numParams && l.numIndices == r.numIndices &&
        psElabMutualLevelNamesEqual l.constructors r.constructors && l.isStructure == r.isStructure)
        "paired inductive metadata differs"
    | .constructorDecl l, .constructorDecl r =>
      ensure (psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psNameEq l.inductiveName r.inductiveName &&
        l.constructorIndex == r.constructorIndex && l.numParams == r.numParams &&
        l.numFields == r.numFields && l.recursiveFields == r.recursiveFields)
        "paired constructor metadata differs"
    | .recursorDecl l, .recursorDecl r =>
      ensure (psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psElabMutualLevelNamesEqual l.inductiveNames r.inductiveNames &&
        l.numParams == r.numParams && l.numIndices == r.numIndices &&
        l.numMotives == r.numMotives && l.numMinors == r.numMinors)
        "paired recursor metadata differs"
    | _, _ => throw (IO.userError "unexpected proof fixture declaration kind")

private def elaborate (profile : PsCompilerProfileContext) (kind : PsCompilerSourceKind)
    (source : String) : IO (PsSyntaxProgram × PsCompilerEngineElaborated) := do
  let program ← fromExcept (psCompilerParsePscv0 source kind)
  let result ← fromExcept ((psCompilerEngineElaboratePscv0 profile program).mapError psCompilerPscv0Error)
  return (program, result)

private def printOpposite (kind : PsCompilerSourceKind) (program : PsSyntaxProgram) :
    IO (PsCompilerSourceKind × String) := do
  -- This fixture contains declarations only; the public printer's separate
  -- command/program boundary remains explicit.
  let declarations ← program.commands.mapM fun command => match command with
    | .declaration declaration => pure declaration
    | _ => throw (IO.userError "printer fixture unexpectedly contains a nondeclaration command")
  let syntaxModule := PsSyntaxModule.mk program.imports declarations
  match kind with
  | .lean => do
    let source ← fromExcept ((psPrintProofScriptModule syntaxModule).mapError
      (fun _ => "PS printer rejected a selected proof command"))
    return (.proofScript, source)
  | .proofScript => do
    let source ← fromExcept ((psPrintLeanModule syntaxModule).mapError
      (fun _ => "Lean printer rejected a selected proof command"))
    return (.lean, source)

def checkPair (profile : PsCompilerProfileContext) (seed : Option Lean.Kernel.Environment)
    (leanSource psSource : String) : IO (List PsCompilerEngineElaborated) := do
  let inputs := [(PsCompilerSourceKind.lean, leanSource), (.proofScript, psSource)]
  let results ← inputs.mapM fun (kind, source) => do
    let (program, result) ← elaborate profile kind source
    let output ← fromExcept ((psCompilerEnginePrepareElaboratedWithOutput result).mapError psCompilerPscv0Error)
    match seed with
    | some environment => do
      let _ ← admit environment output.admissions
      pure ()
    | none => do
      let _ ← fromExcept ((← PsKernelLean.admitCanonicalAdmissions output.admissions).mapError (·.message))
      pure ()
    let (printedKind, printed) ← printOpposite kind program
    let (_, repeated) ← elaborate profile printedKind printed
    sameDeclarations result.declarations repeated.declarations
    return result
  let [left, right] := results | throw (IO.userError "missing paired proof fixture")
  sameDeclarations left.declarations right.declarations
  return results

private def ownedRefusal (owner : String) : PsElabError → Bool
  | .atDeclaration _ cause | .atContext _ cause => ownedRefusal owner cause
  | .proof _ => owner == "proof" || owner == "unsolved"
  | .scope _ | .unknownName _ => owner == "scope"
  | .infer .expectedFunction => owner == "intro"
  | .typeMismatch | .infer .applicationTypeMismatch => owner == "type"
  | .unresolvedMetavariable => owner == "unsolved"
  | .implicitApplicationUnsupported => owner == "instance"
  | .data message => owner == "profile" && message.startsWith "PSCV0-PROOF-PROFILE:"
  | _ => false

def refuse (profile : PsCompilerProfileContext) (owner label leanSource psSource : String) :
    IO Unit := do
  for (kind, source) in [(PsCompilerSourceKind.lean, leanSource), (.proofScript, psSource)] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerEngineElaboratePscv0 profile program with
    | .error (.elaboration cause) =>
      ensure (!psElabErrorIsResource cause && ownedRefusal owner cause)
        (label ++ " failed outside its owned elaboration phase: " ++ psCompilerPscv0ElabError cause)
    | .error error => throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError (label ++ " was accepted"))

private def checkSourceNames : IO Unit := do
  let span := PsSourceSpan.mk (.mk 0 1 1) (.mk 1 1 2)
  let ordinary := PsSyntaxName.mk ["h"] span
  let forged := { ordinary with resolvedName := some (.num (psRootName "$psc0Private") 0) }
  let term := PsSyntaxTerm.hole span
  let forms : List PsSyntaxTactic := [
    .intros [forged] span,
    .suffices forged term term span,
    .suffices ordinary (.reference forged) term span,
    .classicalE [.intro [forged] span] span]
  for tactic in forms do
    match psElabSourceTermNames 4096 (.byE [tactic] {} span) with
    | .error (.scope message) =>
      ensure (message == "source syntax contains an internal resolved name")
        "a new tactic lost the source-name provenance refusal"
    | .error error => throw (IO.userError ("wrong source-name refusal: " ++ psCompilerPscv0ElabError error))
    | .ok _ => throw (IO.userError "a new tactic admitted a forged internal source name")

private def checkResourcePropagation : IO Unit := do
  let span := PsSourceSpan.mk (.mk 0 1 1) (.mk 1 1 2)
  let context := psElabContextEmpty psEnvironmentEmpty []
  let fresh := psMetaFresh context.metaContext context.localContext (.sortE .zero) .syntheticOpaque
  let .mvar id := fresh.expr | throw (IO.userError "invalid resource-control goal")
  let state : PsProofState := {
    context := psElabContextWithMeta context fresh.context
    goals := [{ id }] }
  let elaborate : PsElaborator := fun _ _ _ => .error .fuelExhausted
  let tactic := PsSyntaxTactic.each [.exactE (.hole span) false span] true span
  match psProofRun elaborate {} 64 state [tactic] with
  | .error error => ensure (psElabErrorIsResource error) "any_goals hid a genuine resource failure"
  | .ok _ => throw (IO.userError "any_goals converted resource exhaustion into success")

private def checkClassicalMetadata (results : List PsCompilerEngineElaborated) : IO Unit := do
  let name := psNameAppendStr (psRootName "Classical") "propDecidable"
  for result in results do
    let some declaration := psEnvironmentFind result.environment (psRootName "coreProofClassical")
      | throw (IO.userError "missing checked classical proof")
    let .theoremDecl _ _ _ proof := declaration
      | throw (IO.userError "classical proof changed declaration kind")
    ensure ((psPscv0ExprConstants proof).any (psNameEq name))
      "classical proof did not use the actual checked decision declaration"
    ensure (result.environment.instances.entries.length ==
      psCompilerFullProfileContext.baseEnvironment.instances.entries.length)
      "classical changed the global instance registry"

-- The rule has no separate v7.2 ID; these rows retain its selected section,
-- concrete source form, executable owner, positive declaration and refusal.
def responsibilityRows : List (String × String × String × String) := [
  ("v7.2 §6", "intros", "Goals.psProofIntros / coreProofIntrosRaw / coreProofIntrosAliasNamed",
    "ELAB: intros stops at a definition; quoted underscore remains inaccessible"),
  ("v7.2 §6", "intro let / named / quoted", "Goals.psProofPrepareIntro / coreProofIntroLet / coreProofIntroIndented",
    "ELAB: too many named introductions"),
  ("v7.2 §6", "constructor!", "Proof.psProofConstructor / coreProofConstructorFirst",
    "ELAB: and-then checks every generated goal"),
  ("v7.2 §6", "<;> / parenthesized and braced tactic", "ProofRead.psPscv0ReadAndThen / coreProofAndThenSiblings / coreProofAndThenGroup / coreProofBraced",
    "PARSE: missing and-then operand; empty parenthesized tactic"),
  ("v7.2 §6", "suffices term / from / by / default name / proof hole",
    "ProofIntermediate.psProofSuffices / coreProofSufficesTerm / coreProofSufficesHole / coreProofSufficesDependent",
    "ELAB: original target and antecedent scope; PARSE: missing proof separator"),
  ("v7.2 §6", "classical",
    "ProofClassical.psElabClassicalContext / coreProofClassical / coreProofClassicalLocal / coreProofClassicalOrdinary / coreProofClassicalBraced",
    "ELAB: scope leakage and selected-profile availability; PARSE: empty classical scope")]

def check : IO Unit := do
  ensure (responsibilityRows.length == 6 &&
    (responsibilityRows.map (fun row => row.2.1)).eraseDups.length == 6)
    "the finite proof-command responsibility roster changed"
  let (seed, profile) ← seedContext
  let pureResults ← checkPair profile (some seed) pureLeanSource purePsSource
  let some pureResult := pureResults.head? | throw (IO.userError "missing ordinary proof result")
  let populated := { profile with baseEnvironment := pureResult.environment }
  for (label, owner, leanSource, psSource) in [
      ("intros stops at a definition", "proof", "theorem bad (P : Prop) : CoreProofAlias P := by\n  intros\n  assumption\n", "theorem bad(P: Prop): CoreProofAlias(P) := by {\n  intros\n  assumption\n}\n"),
      ("quoted underscore remains inaccessible", "scope", "theorem bad (P : Prop) : P → P := by\n  intro «_»\n  exact «_»\n", "theorem bad(P: Prop): P -> P := by {\n  intro «_»\n  exact «_»\n}\n"),
      ("too many named introductions", "intro", "theorem bad (P : Prop) : P → P := by\n  intros h k\n  exact h\n", "theorem bad(P: Prop): P -> P := by {\n  intros h k\n  exact h\n}\n"),
      ("suffices antecedent excludes its assumption", "scope", "theorem bad (P : Prop) : P := by\n  suffices h : P from h\n  exact h\n", "theorem bad(P: Prop): P := by {\n  suffices h: P from h\n  exact h\n}\n"),
      ("suffices proof has the original target", "type", "theorem bad (P Q : Prop) (hp : P) : Q := by\n  suffices h : P from h\n  exact hp\n", "theorem bad(P: Prop, Q: Prop, hp: P): Q := by {\n  suffices h: P from h\n  exact hp\n}\n"),
      ("suffices cannot discard its proof hole", "unsolved", "theorem bad (P : Prop) (hp : P) : P := by\n  suffices h : P from _\n  exact hp\n", "theorem bad(P: Prop, hp: P): P := by {\n  suffices h: P from _\n  exact hp\n}\n"),
      ("and-then checks every generated goal", "type", "theorem bad (P Q : Prop) (hp : P) : CoreProofPair P Q := by\n  constructor! <;> exact hp\n", "theorem bad(P: Prop, Q: Prop, hp: P): CoreProofPair(P, Q) := by {\n  constructor! <;> exact hp\n}\n")] do
    refuse populated owner label leanSource psSource
  let classicalResults ← checkPair psCompilerFullProfileContext none classicalLeanSource classicalPsSource
  checkClassicalMetadata classicalResults
  let some classicalResult := classicalResults.head? | throw (IO.userError "missing classical result")
  refuse { psCompilerFullProfileContext with baseEnvironment := classicalResult.environment }
    "instance" "classical does not leak to a sibling goal"
    "theorem bad (P : Prop) : And True True := by\n  constructor!\n  case left =>\n    classical\n    exact coreProofNeedDecision P\n  case right =>\n    exact coreProofNeedDecision P\n"
    "theorem bad(P: Prop): And(True, True) := by {\n  constructor!\n  case left =>\n    classical\n    exact coreProofNeedDecision(P)\n  case right =>\n    exact coreProofNeedDecision(P)\n}\n"
  refuse profile "profile" "classical requires its checked profile declaration"
    "theorem bad (P : Prop) (hp : P) : P := by\n  classical\n  exact hp\n"
    "theorem bad(P: Prop, hp: P): P := by {\n  classical\n  exact hp\n}\n"
  for (label, leanSource, psSource) in [
      ("missing and-then operand", "theorem bad (P : Prop) (hp : P) : P := by\n  exact hp <;>\n", "theorem bad(P: Prop, hp: P): P := by {\n  exact hp <;>\n}\n"),
      ("empty classical scope", "theorem bad (P : Prop) (hp : P) : P := by\n  classical\n", "theorem bad(P: Prop, hp: P): P := by {\n  classical\n}\n"),
      ("empty parenthesized tactic", "theorem bad (P : Prop) (hp : P) : P := by\n  ()\n", "theorem bad(P: Prop, hp: P): P := by {\n  ()\n}\n"),
      ("suffices needs a proof separator", "theorem bad (P : Prop) (hp : P) : P := by\n  suffices h : P\n", "theorem bad(P: Prop, hp: P): P := by {\n  suffices h: P\n}\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanSource), (.proofScript, psSource)] do
      match psCompilerParsePscv0 source kind with
      | .error message =>
        ensure (!["BUDGET", "heartbeat", "recursion depth", "timeout"].any
          (fun marker => (message.splitOn marker).length > 1))
          (label ++ " exhausted parser resources: " ++ message)
      | .ok _ => throw (IO.userError (label ++ " escaped the selected parser"))
  refuse populated "proof" "an empty braced group leaves its focused goal"
    "theorem bad (P : Prop) (hp : P) : P := by\n  {}\n"
    "theorem bad(P: Prop, hp: P): P := by {\n  {}\n}\n"
  refuse { psCompilerFullProfileContext with baseEnvironment := classicalResult.environment } "proof" "an empty braced classical scope leaves its goal"
    "theorem bad (P : Prop) (hp : P) : P := by\n  classical {}\n"
    "theorem bad(P: Prop, hp: P): P := by {\n  classical {}\n}\n"
  refuse { psCompilerFullProfileContext with baseEnvironment := classicalResult.environment } "instance" "classical braces end their decision scope"
    "theorem bad (P : Prop) : And True True := by\n  constructor!\n  classical {\n    exact coreProofNeedDecision P\n  }\n  exact coreProofNeedDecision P\n"
    "theorem bad(P: Prop): And(True, True) := by {\n  constructor!\n  classical {\n    exact coreProofNeedDecision(P)\n  }\n  exact coreProofNeedDecision(P)\n}\n"
  checkSourceNames
  checkResourcePropagation
  IO.println "CORE-PROOF-COMMANDS: PASS 19 ordinary positives over three checked Eq declarations; 4 explicit Full classical positives; paired declaration and printer parity; fresh trust-zero admissions; 22 paired semantic and 2 profile refusals; 8 paired parser refusals; 15 pinned native refusal controls; 4 source-provenance controls; actual resource propagation"

end CoreProofCommands
