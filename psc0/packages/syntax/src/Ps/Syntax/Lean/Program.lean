import Ps.Syntax.ParseLean
import Ps.Syntax.Lean.Term
import Ps.Syntax.Pscv0.ProgramRead

-- Owned native surface adapter, following Lean 4.35.0 Parser.Command and
-- Parser.Module.topLevelCommandParserFn. This produces the same v7.2 program
-- AST as ProofScript; it never invokes Lean's host parser/elaborator or rewrites
-- source text. Unsupported native forms fail before the shared semantic owner.
def psLeanProgramBinders (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  psPscv0ParameterGroups (psLeanReadTerm true) (psLeanReadTerm false) 4096 false false false cursor []

-- Groups retain syntax ownership; shared scope/elaboration processes their
-- binder views in native order, including annotation/default shadowing.
def psLeanProgramResult (required : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if !required && psTokenCursorAtText cursor ":=" then
    let some token := psTokenCursorPeek cursor | throw (.unexpectedEnd "result")
    return { value := .omittedType { start := token.span.start, stop := token.span.start }, cursor }
  let colon ← psTokenCursorExpectText cursor ":"
  psLeanReadTerm true colon.cursor

def psLeanProgramValue (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  let some first := psTokenCursorAdvance cursor | throw "PSCV0-LEAN-DECLARATION"
  let modifier := first.token.text
  let head ← if ["partial", "noncomputable"].contains modifier then
    psPscv0Expect first.cursor "def"
  else pure first
  if !["def", "theorem", "abbrev", "opaque"].contains head.token.text then
    throw "PSCV0-LEAN-DECLARATION: selected value declaration required"
  let name ← (psParseSyntaxName head.cursor).mapError psPscv0ParseError
  let binders ← (psLeanProgramBinders name.cursor).mapError psPscv0ParseError
  let type ← (psLeanProgramResult (head.token.text != "def") binders.cursor).mapError
    psPscv0ParseError
  let assign ← psPscv0Expect type.cursor ":="
  let body ← (psLeanReadTerm false assign.cursor).mapError psPscv0ParseError
  let span := PsSourceSpan.mk first.token.span.start (psLeanTermStop body.value)
  let declaration :=
    if modifier == "partial" then
      PsSyntaxDeclaration.partialDefinition name.value binders.value type.value body.value span
    else if modifier == "noncomputable" then
      .noncomputableDefinition name.value binders.value type.value body.value span
    else if head.token.text == "theorem" then
      .theoremDecl name.value binders.value type.value body.value span
    else .definition name.value binders.value type.value body.value span
  if psTokenCursorAtText body.cursor "decreasing_by" then
    throw "PSCV0-TERM-01: decreasing_by requires a preceding termination_by measure"
  if psTokenCursorAtText body.cursor "partial_fixpoint" then
    if modifier != "def" then
      throw "PSCV0-REC-STRATEGY-01: partial_fixpoint requires an ordinary def"
    let suffix ← psPscv0Expect body.cursor "partial_fixpoint"
    if ["partial_fixpoint", "termination_by", "decreasing_by", "monotonicity"].any
        (psTokenCursorAtText suffix.cursor) then
      throw "PSCV0-FIXPOINT-01: duplicate, incompatible or unselected fixedpoint suffix"
    let declaration := PsSyntaxDeclaration.fixedpointDefinition
      name.value binders.value type.value body.value { span with stop := suffix.token.span.stop }
    return { value := declaration, cursor := suffix.cursor }
  -- Explicit decreasing proofs are owned by the future native tactic adapter;
  -- a native by block must never be reinterpreted as a ProofScript brace block.
  if psTokenCursorAtText body.cursor "termination_by" then
    if !["def", "abbrev", "opaque"].contains modifier then
      throw "PSCV0-REC-STRATEGY-01: termination_by requires a total value declaration"
    let suffix ← psPscv0Expect body.cursor "termination_by"
    if psTokenCursorAtText suffix.cursor "structural" then
      throw "PSCV0-TERM-01: termination_by structural is not selected"
    let measure ← (psLeanReadTerm false suffix.cursor).mapError psPscv0ParseError
    if ["termination_by", "decreasing_by", "partial_fixpoint"].any
        (psTokenCursorAtText measure.cursor) then
      throw "PSCV0-LEAN-TERMINATION: duplicate suffix or unsupported native decreasing proof"
    let stop := psLeanTermStop measure.value
    let termination : PsSyntaxTermination := {
      measure := measure.value, span := { start := suffix.token.span.start, stop } }
    let declaration := PsSyntaxDeclaration.wellFoundedDefinition
      name.value binders.value type.value body.value termination { span with stop }
    return { value := declaration, cursor := measure.cursor }
  return { value := declaration, cursor := body.cursor }

def psLeanProgramOrdinaryCommand (cursor : PsTokenCursor) (mutualMember : Bool := false) :
    Except String (PsParseResult PsSyntaxCommand) := do
  if !mutualMember then
    if let some scopeCommand ← psPscv0ReadScopeCommand psLeanProgramBinders cursor then
      return scopeCommand
  let some first := psTokenCursorPeek cursor | throw "PSCV0-LEAN-COMMAND"
  let isPrivate := first.text == "private"
  let cursor ← if isPrivate then pure (← psPscv0Expect cursor "private").cursor else pure cursor
  let some token := psTokenCursorPeek cursor | throw "PSCV0-LEAN-DECLARATION"
  if mutualMember && !["def", "partial", "noncomputable"].contains token.text then
    throw "PSCV0-MUTUAL-HEAD: selected function-like native declaration required"
  let parsed ← if ["inductive", "structure"].contains token.text then
    (psParseLeanDeclaration cursor).mapError psPscv0ParseError
  else psLeanProgramValue cursor
  let registration := if token.text == "abbrev" then some PsSyntaxRegistration.abbrevDecl
    else if token.text == "opaque" then some .opaqueDecl else none
  let command := match registration with
    | some registration => if isPrivate then
        PsSyntaxCommand.privateRegisteredDeclaration parsed.value registration
      else .registeredDeclaration parsed.value registration
    | none => if isPrivate then .privateDeclaration parsed.value else .declaration parsed.value
  -- Native commands must end before the next line. The term reader retains
  -- exact token spans, including multiline bodies; no semicolon/braces adapter.
  if let some next := psTokenCursorPeek parsed.cursor then
    if !psTokenCursorDone parsed.cursor &&
        next.span.start.line <= (psProofScriptDeclarationStop parsed.value).line then
      throw "PSCV0-LEAN-COMMAND-SEPARATOR: expected a new command line"
  return { value := command, cursor := parsed.cursor }

def psLeanProgramMutual (fuel : Nat) (cursor : PsTokenCursor)
    (membersRev : List PsSyntaxMutualMember) :
    Except String (PsParseResult (List PsSyntaxMutualMember × PsSourceSpan)) := do
  match fuel with
  | 0 => throw "PSCV0-MUTUAL-MEMBER-BUDGET"
  | fuel + 1 =>
    if psTokenCursorAtText cursor "end" then
      if membersRev.isEmpty then throw "PSCV0-MUTUAL-EMPTY"
      let closing ← psPscv0Expect cursor "end"
      return { value := (membersRev.reverse, closing.token.span), cursor := closing.cursor }
    let parsed ← psLeanProgramOrdinaryCommand cursor true
    let member ← match parsed.value with
      | .declaration declaration => pure (PsSyntaxMutualMember.mk declaration false none)
      | .privateDeclaration declaration => pure (PsSyntaxMutualMember.mk declaration true none)
      | _ => throw "PSCV0-MUTUAL-HEAD"
    psLeanProgramMutual fuel parsed.cursor (member :: membersRev)

def psLeanProgramCommands (fuel : Nat) (cursor : PsTokenCursor)
    (commandsRev : List PsSyntaxCommand) : Except String (List PsSyntaxCommand) := do
  match fuel with
  | 0 => throw "PSCV0-LEAN-COMMAND-BUDGET"
  | fuel + 1 =>
    if psTokenCursorDone cursor then return commandsRev.reverse
    let parsed ← if psTokenCursorAtText cursor "mutual" then do
      let opening ← psPscv0Expect cursor "mutual"
      let members ← psLeanProgramMutual 4096 opening.cursor []
      pure (PsParseResult.mk (.mutualDeclarations members.value.1
        { start := opening.token.span.start, stop := members.value.2.stop }) members.cursor)
    else psLeanProgramOrdinaryCommand cursor
    psLeanProgramCommands fuel parsed.cursor (parsed.value :: commandsRev)

def psLeanParseProgram (source : String) : Except String PsSyntaxProgram := do
  if source.utf8ByteSize > 1048576 then throw "PSCV0-SOURCE-BYTE-BUDGET"
  let tokens ← (psLex source).mapError (fun _ => "PSCV0-LEAN-LEX")
  if tokens.length > 65536 then throw "PSCV0-SOURCE-TOKEN-BUDGET"
  let imports ← (psParseLeanImportsWithFuel (tokens.length + 1)
    (psTokenCursorFromTokens tokens) []).mapError psPscv0ParseError
  let commands ← psLeanProgramCommands 4096 imports.cursor []
  return { imports := imports.value, commands }
