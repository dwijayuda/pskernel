import Ps.Syntax.ParseLean
import Ps.Syntax.Lean.Declarations
import Ps.Syntax.Pscv0.ProgramRead

-- Owned native surface adapter, following Lean 4.35.0 Parser.Command and
-- Parser.Module.topLevelCommandParserFn. This produces the same v7.2 program
-- AST as ProofScript; it never invokes Lean's host parser/elaborator or rewrites
-- source text. Unsupported native forms fail before the shared semantic owner.
def psLeanFinishCommand (command : PsSyntaxCommand) (stop : PsSourcePos)
    (cursor : PsTokenCursor) : Except String (PsParseResult PsSyntaxCommand) := do
  if let some next := psTokenCursorPeek cursor then
    if !psTokenCursorDone cursor && next.span.start.line <= stop.line then
      throw "PSCV0-LEAN-COMMAND-SEPARATOR: expected a new command line"
  return { value := command, cursor }

def psLeanProgramUnattributedCommand (cursor : PsTokenCursor) (mutualMember : Bool) :
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
  let parsed ← if token.text == "instance" then do
    let parsed ← (psLeanReadInstance cursor).mapError psPscv0ParseError
    let command := PsSyntaxCommand.registeredDeclaration parsed.value.1 (.instanceDecl parsed.value.2)
    psLeanFinishCommand command (psProofScriptDeclarationStop parsed.value.1) parsed.cursor
  else if ["inductive", "structure", "class"].contains token.text then do
    let parsed ← (psLeanReadData cursor).mapError psPscv0ParseError
    if token.text != "class" && psTokenCursorAtText parsed.cursor "deriving" then
      let marker ← psPscv0Expect parsed.cursor "deriving"
      let handlers ← psPscv0DerivingHandlers 128 marker.cursor []
      let some last := handlers.value.getLast? | throw "PSCV0-DERIVE-HANDLER-REQUIRED"
      psLeanFinishCommand (.derivingDeclaration parsed.value handlers.value false) last.span.stop handlers.cursor
    else
      let command := if token.text == "class" then
        PsSyntaxCommand.registeredDeclaration parsed.value .classDecl
      else .declaration parsed.value
      psLeanFinishCommand command (psProofScriptDeclarationStop parsed.value) parsed.cursor
  else do
    let parsed ← psLeanProgramValue cursor
    let command := if token.text == "abbrev" then
      PsSyntaxCommand.registeredDeclaration parsed.value .abbrevDecl
    else if token.text == "opaque" then .registeredDeclaration parsed.value .opaqueDecl
    else .declaration parsed.value
    psLeanFinishCommand command (psProofScriptDeclarationStop parsed.value) parsed.cursor
  let command := if !isPrivate then parsed.value else match parsed.value with
    | .declaration source => .privateDeclaration source
    | .registeredDeclaration source registration => .privateRegisteredDeclaration source registration
    | .derivingDeclaration source handlers _ => .derivingDeclaration source handlers true
    | command => command
  return { parsed with value := command }

def psLeanProgramOrdinaryCommand (cursor : PsTokenCursor) (mutualMember : Bool := false) :
    Except String (PsParseResult PsSyntaxCommand) :=
  psPscv0ReadAttributedCommand (fun cursor =>
    psLeanProgramUnattributedCommand cursor mutualMember) cursor

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
      | .registeredDeclaration declaration registration =>
        pure (PsSyntaxMutualMember.mk declaration false (some registration))
      | .privateRegisteredDeclaration declaration registration =>
        pure (PsSyntaxMutualMember.mk declaration true (some registration))
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
