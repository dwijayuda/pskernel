import Lean
import PSCVL.Syntax

/-!
Pre-elaboration gate for the **currently implemented** PSCVL command fragment.

Lean's extensible grammar is intentionally *not* a PSCV grammar. We accept
an explicit set of top-level command AST kinds, reject other commands BEFORE
running their elaborators, and refuse errors/recovery. This is not yet the
full recursive A.18 source-grammar conformance validator or a security sandbox.
-/

open Lean

namespace PSCVL

private def allowedDeclarationKind (kind : String) : Bool :=
  ([
    "Lean.Parser.Command.definition",
    "Lean.Parser.Command.theorem",
    "Lean.Parser.Command.example",
    "Lean.Parser.Command.abbrev",
    "Lean.Parser.Command.opaque",
    "Lean.Parser.Command.structure",
    "Lean.Parser.Command.classInductive",
    "Lean.Parser.Command.inductive",
    "Lean.Parser.Command.instance"
  ] : List String).contains kind

/-- Only the finite PSCV/Lean Standard and PSCVL bookkeeping attributes are
admitted on declarations. Checking the elaborated declaration afterward is
not sufficient: a registered Lean attribute may run user-visible code. -/
private partial def attributeIdentifiers (s : Syntax) : List Name :=
  match s with
  | .ident _ _ val _ => [val]
  | .node _ _ args => args.toList.flatMap attributeIdentifiers
  | _ => []

private def rejectAttributes (s : Syntax) : Option String := Id.run do
  unless s.getKind.toString == "Lean.Parser.Command.declaration" do
    return none
  -- declaration[0] is declModifiers; its optional attribute block is field 1.
  let attrs := s[0][1]
  let permitted : List String := [
    "simp", "instance", "default_instance", "priority",
    "pscv_export", "pscv_type_spec"
  ]
  if let some bad := (attributeIdentifiers attrs).find? (fun id =>
      !permitted.contains id.toString) then
    return some s!"PSCVL rejects undeclared attribute '{bad}'"
  return none

private def allowedCommand (s : Syntax) : Bool :=
  let k := s.getKind.toString
  if k == "Lean.Parser.Command.declaration" then
    allowedDeclarationKind s[1].getKind.toString
  else
    ([
      "PSCVL.pscvConst", "PSCVL.pscvConstInferred",
      "PSCVL.pscvFunction", "PSCVL.pscvImplicitFunction",
      "PSCVL.pscvFunctionContract", "PSCVL.pscvFunctionEnsures", "PSCVL.pscvFunctionRequires",
      "PSCVL.pscvRefine", "PSCVL.pscvExceptErrors", "PSCVL.pscvExceptEnsuresErrors",
      "Lean.Parser.Command.namespace", "Lean.Parser.Command.section",
      "Lean.Parser.Command.end", "Lean.Parser.Command.open",
      "Lean.Parser.Command.variable", "Lean.Parser.Command.universe",
      "Lean.Parser.Command.include", "Lean.Parser.Command.omit"
    ] : List String).contains k

/-- Reject known metaprogramming and proof escapes before the Lean elaborator
runs. Ordinary strings and comments are syntax leaves, not command text. -/
private def excludedName (name : Name) : Bool :=
  let value := name.toString
  (["sorry", "sorryAx", "unsafeCast", "unsafePerformIO",
    "native_decide", "run_tac", "run_cmd", "erased",
    "partial_fixpoint", "unsafe", "macro", "macro_rules",
    "extern", "nativeDecide", "evalConst", "EIO", "BaseIO",
    "IO"] : List String).any (fun banned =>
      value == banned || value.endsWith ("." ++ banned))

/- An identifier is different from a keyword token in Lean's syntax tree.
Apply the source exclusions to both; otherwise imported built-in primitives
can bypass restrictions that checked only `Syntax.atom` keywords. -/
/-- The PSCV A.18 while grammar requires both an invariant and a
decreasing measure. Lean accepts weaker loop surface forms; parse-time
normalization must NOT silently promote those forms to PSCV. -/
private partial def forbiddenLoop (s : Syntax) : Option String :=
  match s with
  | .node _ kind args =>
    if kind == ``Lean.Parser.Term.doWhile then
      if s[2].isNone then
        some "PSCV while requires an explicit invariant"
      else if s[3].isNone then
        some "PSCV while requires an explicit decreasing measure"
      else
        args.toList.findSome? forbiddenLoop
    else if kind == ``Lean.Parser.Term.doRepeat ||
            kind == ``Lean.Parser.Term.doRepeatUntil then
      some "PSCV does not admit Lean repeat/repeat-until loops"
    else if kind == ``Lean.Parser.Term.doFor then
      if s[1].getSepArgs.size != 1 then
        some "PSCV for requires exactly one collection"
      else if !(s[3].isNone) then
        some "PSCV for loops do not take a decreasing clause"
      else
        args.toList.findSome? forbiddenLoop
    else
      args.toList.findSome? forbiddenLoop
  | _ => none

private partial def forbiddenSyntax (s : Syntax) : Option String :=
  match s with
  | .node _ kind args =>
    let k := kind.toString
    if k == "Lean.Parser.Term.runTactic" || k == "Lean.Parser.Tactic.runTac"
        || k == "Lean.Parser.Term.doErased"
        || k == "Lean.Parser.Term.doErasedArrow" then
      some s!"untrusted metaprogramming syntax `{k}`"
    else
      args.toList.findSome? forbiddenSyntax
  | .ident _ _ name _ =>
    if excludedName name then some s!"forbidden PSCV identifier '{name}'"
    else none
  | .atom _ value =>
    if value == ";" then
      some "PSCV does not admit Lean semicolon statement/tactic separators"
    else if (["run_tac", "native_decide", "sorry", "unsafe", "partial",
         "macro", "macro_rules", "elab", "initialize", "set_option",
         "syntax", "declare_syntax_cat", "implemented_by", "extern",
         "run_cmd", "deriving", "scoped", "assert!"] : List String).contains value then
      some s!"forbidden PSCV source token `{value}`"
    else none
  | _ => none

/-- This is the *implemented normative fragment*, deliberately smaller
than the complete Appendix A/Chapter 20 grammar. It fails closed on known
Lean-only forms; the development-preview mode keeps the earlier prototype
examples separate from claims of Standard PSCV source acceptance.

Authority: ProofScript PSCV Normative RC v2, §§5, 8-10, 19-20, A.6, A.14-18.
A full recursive allowlist is still required for release conformance. -/
private partial def normativeRejection (s : Syntax) : Option String :=
  match s with
  | .node _ kind args =>
    let k := kind.toString
    if k == "Lean.Parser.Term.doSeqIndent" then
      some "PSCV Standard requires braced do { ... } with newline sequencing (A.18)"
    else if k == "Lean.Parser.Tactic.tacticSeq1Indented" then
      some "PSCV Standard requires braced by { ... } proof terms (A.15)"
    else if k == "Lean.Parser.Command.declValEqns" then
      some "PSCV Standard does not admit native Lean equation-declaration bodies (A.8)"
    else if k == "termIfThenElse" || k == "termDepIfThenElse" then
      some "PSCV Standard uses braced if (condition) { ... } else { ... } (A.6)"
    else if k == "Lean.Parser.Term.match" then
      some "PSCV Standard match requires the owned braced single-scrutinee form (A.11)"
    else if k == "Lean.Parser.Tactic.tacticSeq1Indented" then
      some "PSCV Standard forbids unbraced proof tactic sequences"
    else if k.startsWith "Lean.Parser.Tactic." &&
      !(["Lean.Parser.Tactic.tacticSeq", "Lean.Parser.Tactic.tacticSeqBracketed",
         "Lean.Parser.Tactic.tacticRfl", "Lean.Parser.Tactic.exact",
         "Lean.Parser.Tactic.intro", "Lean.Parser.Tactic.intros",
         "Lean.Parser.Tactic.assumption", "Lean.Parser.Tactic.constructor",
         "Lean.Parser.Tactic.apply", "Lean.Parser.Tactic.refine",
         "Lean.Parser.Tactic.decide", "Lean.Parser.Tactic.omega",
         "Lean.Parser.Tactic.simp", "Lean.Parser.Tactic.simpa",
         "Lean.Parser.Tactic.rw", "Lean.Parser.Tactic.change",
         "Lean.Parser.Tactic.unfold", "Lean.Parser.Tactic.dsimp",
         "Lean.Parser.Tactic.byCases", "Lean.Parser.Tactic.byContra",
         "Lean.Parser.Tactic.cases", "Lean.Parser.Tactic.induction",
         "Lean.Parser.Tactic.exfalso", "Lean.Parser.Tactic.subst",
         "Lean.Parser.Tactic.generalize", "Lean.Parser.Tactic.rcases",
         "Lean.Parser.Tactic.rintro", "Lean.Parser.Tactic.obtain",
         "Lean.Parser.Tactic.use", "Lean.Parser.Tactic.ext",
         "Lean.Parser.Tactic.exact?", "Lean.Parser.Tactic.grind",
         "Lean.Parser.Tactic.classical", "Lean.Parser.Tactic.calc",
         "Lean.Parser.Tactic.optConfig"] : List String).contains k then
      some s!"PSCV Standard does not admit this Lean tactic node: {k} (Chapter 20)"
    else
      args.toList.findSome? normativeRejection
  | _ => none

/-- Inspect a closed set of command kinds with Lean's actual parser. Do not
elaborate anything before this check. Every source import is rejected as a
top-level terminal command until a versioned dependency manifest exists. -/
private partial def syntaxNodeKinds (s : Syntax) : Array String :=
  match s with
  | .node _ k args =>
      args.foldl (fun names child => names ++ syntaxNodeKinds child) #[k.toString]
  | _ => #[]

/-- Return every distinct syntax-node kind encountered by the *accepted*
fragment. This is a development aid to mechanize Appendix A compatibility
rather than inferring allowed syntax from text or tests. No elaboration runs. -/
def auditSourceSyntax (source fileName : String) (env : Environment)
    (opts : Options) (normative : Bool := false) :
    Except String (Array String) := Id.run do
  let input := Parser.mkInputContext source fileName
  let mut parserState : Parser.ModuleParserState := {}
  let mut messages : MessageLog := {}
  let mut encountered := #[]
  repeat
    let (stx, next, nextMessages) :=
      Parser.parseCommand input
        { env := env, options := opts, currNamespace := .anonymous, openDecls := [] }
        parserState messages
    if nextMessages.hasErrors then
      return .error "Lean parser rejected source before PSCV elaboration"
    if stx.isOfKind ``Parser.Command.eoi then
      return .ok encountered
    if Parser.isTerminalCommand stx then
      return .error s!"PSCVL prohibits import/exit commands: {stx.getKind}"
    if next.pos == parserState.pos then
      return .error "PSCVL parser did not advance"
    unless allowedCommand stx do
      return .error s!"PSCVL closed command profile rejects: {stx.getKind}"
    if let some why := forbiddenSyntax stx then
      return .error why
    if let some why := forbiddenLoop stx then
      return .error why
    if normative then
      if let some why := normativeRejection stx then
        return .error why
    if let some why := rejectAttributes stx then
      return .error why
    for kind in syntaxNodeKinds stx do
      unless encountered.contains kind do
        encountered := encountered.push kind
    parserState := next
    messages := nextMessages

def validateSourceSyntax (source fileName : String) (env : Environment)
    (opts : Options) (normative : Bool := false) : Except String Unit := do
  let _ ← auditSourceSyntax source fileName env opts normative
  return ()

end PSCVL
