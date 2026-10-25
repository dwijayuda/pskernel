import Ps.Host.LeanChecked
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
  let syntax ← extract source
  let before ← match traceDeclaration false syntax with
    | .ok result => pure result
    | .error error => throw (IO.userError (label ++ ": " ++ psHostElabErrorText error))
  let after ← match traceDeclaration true syntax with
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
  IO.println "PSC1_SOURCE_TRACE: PASS actual allocation/resolution, scope reuse, byte parity, official admission, disabled mode and refusal"
