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

private def allowedCommand (s : Syntax) : Bool :=
  let k := s.getKind.toString
  if k == "Lean.Parser.Command.declaration" then
    allowedDeclarationKind s[1].getKind.toString
  else
    ([
      "PSCVL.pscvConst", "PSCVL.pscvFunction1", "PSCVL.pscvFunction2",
      "Lean.Parser.Command.namespace", "Lean.Parser.Command.section",
      "Lean.Parser.Command.end", "Lean.Parser.Command.open",
      "Lean.Parser.Command.variable", "Lean.Parser.Command.universe",
      "Lean.Parser.Command.include", "Lean.Parser.Command.omit"
    ] : List String).contains k

/-- Reject known metaprogramming and proof escapes before the Lean elaborator
runs. Ordinary strings and comments are syntax leaves, not command text. -/
private partial def forbiddenSyntax (s : Syntax) : Option String :=
  match s with
  | .node _ kind args =>
    let k := kind.toString
    if k == "Lean.Parser.Term.runTactic" || k == "Lean.Parser.Tactic.runTac" then
      some s!"untrusted metaprogramming syntax `{k}`"
    else
      args.toList.findSome? forbiddenSyntax
  | .atom _ value =>
    if (["run_tac", "native_decide", "sorry", "unsafe", "partial",
         "macro", "macro_rules", "elab", "initialize", "set_option",
         "syntax", "declare_syntax_cat", "implemented_by", "extern",
         "run_cmd"] : List String).contains value then
      some s!"forbidden PSCV source token `{value}`"
    else none
  | _ => none

/-- Inspect a closed set of command kinds with Lean's actual parser. Do not
elaborate anything before this check. Every source import is rejected as a
top-level terminal command until a versioned dependency manifest exists. -/
def validateSourceSyntax (source fileName : String) (env : Environment)
    (opts : Options) : Except String Unit := Id.run do
  let input := Parser.mkInputContext source fileName
  let mut parserState : Parser.ModuleParserState := {}
  let mut messages : MessageLog := {}
  repeat
    let (stx, next, nextMessages) :=
      Parser.parseCommand input
        { env := env, options := opts, currNamespace := .anonymous, openDecls := [] }
        parserState messages
    if nextMessages.hasErrors then
      return .error "Lean parser rejected source before PSCV elaboration"
    if stx.isOfKind ``Parser.Command.eoi then
      return .ok ()
    if Parser.isTerminalCommand stx then
      return .error s!"PSCVL prohibits import/exit commands: {stx.getKind}"
    if next.pos == parserState.pos then
      return .error "PSCVL parser did not advance"
    unless allowedCommand stx do
      return .error s!"PSCVL closed command profile rejects: {stx.getKind}"
    if let some why := forbiddenSyntax stx then
      return .error why
    parserState := next
    messages := nextMessages

end PSCVL
