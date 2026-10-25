import Ps.Host.LeanChecked
import Ps.Host.SourceBindings
import Ps.Host.ProjectCompiler

private def demand (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw (IO.userError ("PSC1_SOURCE_TRACE: " ++ message))

private def extract (source : String) : IO PsSyntaxDeclaration := do
  let parsed ← match psParseLeanSource source with
    | .ok parsed => pure parsed
    | .error _ => throw (IO.userError "PSC1_TRACE_PARSE")
  match parsed.declarations with
  | [declaration] => pure (psSyntaxDeclarationQualify [] declaration)
  | _ => throw (IO.userError "PSC1_TRACE_ONE_DECLARATION")

private def traceDeclaration (enabled : Bool) (source : PsSyntaxDeclaration) :
    Except PsElabError PsElabDeclarationTraceResult :=
  match source with
  | .definition name binders type value _ =>
      psElabDeclarationPartsWithSourceTrace enabled psSelfHostProdPreludeEnvironment
        name binders type value false
  | .partialDefinition name binders type value _ =>
      psElabPartialDeclarationWithSourceTrace enabled psSelfHostProdPreludeEnvironment
        name binders type value
  | _ => .error .unsupportedTerm

private def check (label source : String) (reuse : Bool := false) : IO Unit := do
  let parsedDecl ← extract source
  let before ← match traceDeclaration false parsedDecl with
    | .ok result => pure result
    | .error error => throw (IO.userError (label ++ ": " ++ psHostElabErrorText error))
  let after ← match traceDeclaration true parsedDecl with
    | .ok result => pure result
    | .error error => throw (IO.userError (label ++ ": traced: " ++ psHostElabErrorText error))
  let encode (declaration : PsDeclaration) := psEncodeCheckedAdmissionsCanonical [declaration]
  let beforeBytes ← match encode before.result.declaration with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TRACE_BEFORE_ENCODING")
  let afterBytes ← match encode after.result.declaration with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TRACE_AFTER_ENCODING")
  demand (beforeBytes == afterBytes) (label ++ ": tracing changed actual declaration bytes")
  match ← psHostLeanCheckPrepared (PsCompilerAdmissionReadyModule.mk [after.result.declaration]) with
  | .error message => throw (IO.userError message)
  | .ok _ => pure ()
  demand (!before.trace.enabled && before.trace.nextId == 0 &&
    before.trace.bindersRev.isEmpty && before.trace.referencesRev.isEmpty)
    (label ++ ": disabled tracing accumulated events")
  demand (after.trace.enabled && after.trace.complete) (label ++ ": incomplete local trace")
  demand (!after.trace.bindersRev.isEmpty && !after.trace.referencesRev.isEmpty)
    (label ++ ": no actual events")
  demand (after.trace.bindersRev.any (fun binder => binder.source.isSome))
    (label ++ ": no actual source binder spans")
  for binder in after.trace.bindersRev do
    demand (binder.index < after.trace.nextId) (label ++ ": bad binder index")
    match binder.parent with
    | .none => pure ()
    | .some parent =>
        demand (parent < binder.index &&
          after.trace.bindersRev.any (fun other => other.index == parent))
          (label ++ ": bad lexical parent")
  for reference in after.trace.referencesRev do
    demand (reference.index < after.trace.nextId) (label ++ ": bad reference index")
    match reference.target with
    | .local localId (.some binder) =>
        demand (binder < reference.index && after.trace.bindersRev.any
          (fun entry => entry.index == binder && entry.localId == localId))
          (label ++ ": local target not from actual allocation")
    | .local _ .none => demand false (label ++ ": unbound actual local")
    | _ => pure ()
  if reuse then
    demand (after.trace.bindersRev.any (fun left => after.trace.bindersRev.any
      (fun right => left.index != right.index && left.localId == right.localId)))
      (label ++ ": fixture did not exercise reused context-local IDs")
  IO.println ("PSC1_TRACE_CASE: " ++ label ++ " binders=" ++ toString after.trace.bindersRev.length ++
    " references=" ++ toString after.trace.referencesRev.length)

private def checkModule (grammar : PsCompilerSourceKind) (text : String) : IO Unit := do
  let parsed ← match psCompilerParseSource grammar text with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TRACE_MODULE_PARSE")
  let before ← match psElabModuleWithOrigins psSelfHostProdPreludeEnvironment parsed with
    | .ok value => pure value
    | .error error => throw (IO.userError (psHostElabErrorText error.error))
  let after ← match psElabModuleWithSourceTrace true psSelfHostProdPreludeEnvironment parsed with
    | .ok value => pure value
    | .error error => throw (IO.userError (psHostElabErrorText error.error))
  let a ← match psEncodeCheckedAdmissionsCanonical before.result.declarations with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TRACE_MODULE_BEFORE")
  let b ← match psEncodeCheckedAdmissionsCanonical after.result.declarations with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TRACE_MODULE_AFTER")
  demand (a == b) "opt-in module path changed actual prepared declarations"
  demand (before.origins.all (fun origin => origin.sourceTraces.isEmpty))
    "ordinary preparation accumulated traces"
  demand (after.origins.any (fun origin => !origin.sourceTraces.isEmpty))
    "opt-in module path lost traces"
  for origin in after.origins do
    for member in origin.sourceTraces do
      demand (member.trace.enabled && member.trace.complete) "module trace incomplete"
      demand (origin.members.any (fun actual => psNameEq actual.name member.name))
        "trace owner is not an actual batch member"
  match ← psHostLeanCheckPrepared (PsCompilerAdmissionReadyModule.mk after.result.declarations) with
  | .error message => throw (IO.userError message)
  | .ok _ => pure ()
  IO.println "PSC1_TRACE_MODULE: PASS one actual elaboration, origin ownership and exact admission bytes"

private def comparisonEnvelope (before after : String) (name : String := "target") : Lean.Json :=
  let request (id text : String) := Lean.Json.arr #[
    .str "psc1-compiler-service/1", .str id, .str id, .str "lean", .str "checked",
    .str "Main", .arr #[.arr #[.str "Main", .str text]]]
  Lean.Json.mkObj [
    ("protocol", .str "psc1-source-binding-comparison/1"),
    ("before", request "before" before), ("after", request "after" after),
    ("target", Lean.Json.mkObj [("module", .str "Main"),
      ("name", .arr #[.arr #[.str "s", .str name]])])]

private def checkComparison : IO Unit := do
  let original := "def target (input : Nat) : Nat := let local : Nat := Nat.succ input; local\n"
  let renamed := "def target (input : Nat) : Nat := let renamed : Nat := Nat.succ input; renamed\n"
  match Ps.Internal.SourceBindingComparison.compare (comparisonEnvelope original renamed).compress with
  | .error message => throw (IO.userError ("PSC1_TRACE_COMPARISON_POSITIVE:" ++ message))
  | .ok _ => pure ()
  let changedBody := "def target (input : Nat) : Nat := let local : Nat := Nat.succ (Nat.succ input); local\n"
  let changedType := "def target (renamedInput : Nat) : Nat := let local : Nat := Nat.succ renamedInput; local\n"
  let capture := "def target (input : Nat) : Nat := let local : Nat := Nat.succ input; input\n"
  for candidate in [changedBody, changedType, capture] do
    match Ps.Internal.SourceBindingComparison.compare (comparisonEnvelope original candidate).compress with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "PSC1_TRACE_COMPARISON_FALSE_POSITIVE")
  let otherBefore := original ++ "def other : Nat := 41\n"
  let otherAfter := renamed ++ "def other : Nat := 42\n"
  match Ps.Internal.SourceBindingComparison.compare (comparisonEnvelope otherBefore otherAfter).compress with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSC1_TRACE_OTHER_DECLARATION_CHANGED")
  match Ps.Internal.SourceBindingComparison.compare (comparisonEnvelope original renamed "missing").compress with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSC1_TRACE_MISSING_TARGET")
  IO.println "PSC1_BINDING_COMPARISON: PASS alpha-only body, exact API/other declarations, capture/body/type/owner refusals"

def main : IO Unit := do
  check "shadow-and-reuse"
    "def trace (value : Nat) : Nat :=\n  let left : Nat := (let value : Nat := Nat.succ value; value);\n  let right : Nat := (let value : Nat := Nat.succ value; value);\n  Nat.add left right\n" true
  check "branches"
    "def trace (flag : Bool) (value : Nat) : Nat :=\n  if flag then (let local : Nat := Nat.succ value; local)\n  else (let local : Nat := Nat.succ (Nat.succ value); local)\n" true
  check "lambda"
    "def trace (value : Nat) : Nat :=\n  let apply : Nat -> Nat := fun (value : Nat) => Nat.succ value;\n  apply value\n"
  check "match"
    "def trace (value : Nat) : Nat := match value with\n  | Nat.zero => 0\n  | Nat.succ previous => Nat.succ previous\n"
  check "identity-do"
    "def trace (value : Nat) : Id Nat := do\n  let first : Nat := Nat.succ value\n  return Nat.succ first\n"
  check "except-do"
    "def trace (value : Nat) : Except Nat Nat := do\n  try\n    if Nat.blt value 2 then throw value else pure value\n  catch caught =>\n    pure (Nat.succ caught)\n"
  let bad ← extract "def invalid : Nat := true\n"
  for enabled in [false, true] do
    match traceDeclaration enabled bad with
    | .error .typeMismatch => pure ()
    | _ => throw (IO.userError "PSC1_TRACE_CHANGED_REFUSAL")
  let moduleSource := "namespace TraceLibrary\ninductive Flag where\n  | off\n  | on\ndef choose (flag : Flag) (value : Nat) : Nat :=\n  let next : Nat := Nat.succ value;\n  match flag with\n  | Flag.off => next\n  | Flag.on => Nat.succ next\nend TraceLibrary\n"
  checkModule .lean moduleSource
  let ps ← match psTranslateLeanToProofScript moduleSource with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TRACE_MODULE_TRANSLATION")
  checkModule .proofScript ps
  checkComparison
  IO.println "PSC1_SOURCE_TRACE: PASS actual allocation/resolution, scope reuse, byte parity, official admission, disabled mode and refusal"
