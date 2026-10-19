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

def psLeanProgramUnattributedCommand (cursor : PsTokenCursor) (mutualMember : Bool) (defaultPrivate : Bool := false) :
    Except String (PsParseResult PsSyntaxCommand) := do
  if !mutualMember then
    if let some parsed ← psPscv0ReadInspectionCommand
        (psLeanReadTerm false) psLeanFinishCommand false cursor then return parsed
  if !mutualMember then
    if let some scopeCommand ← psPscv0ReadScopeCommand psLeanProgramBinders cursor then
      return scopeCommand
  let some first := psTokenCursorPeek cursor | throw "PSCV0-LEAN-COMMAND"
  let hasVisibility := first.text == "private" || first.text == "public"
  let isPrivate := if hasVisibility then first.text == "private" else defaultPrivate
  let cursor ← if hasVisibility then pure (← psPscv0Expect cursor first.text).cursor else pure cursor
  let some token := psTokenCursorPeek cursor | throw "PSCV0-LEAN-DECLARATION"
  if ["private", "public"].contains token.text then
    throw "PSCV0-LEAN-VISIBILITY-MODIFIER"
  if hasVisibility && ["section", "namespace"].contains token.text then
    throw "PSCV0-LEAN-VISIBILITY-SCOPE-UNSUPPORTED"
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

def psLeanProgramOrdinaryCommand (cursor : PsTokenCursor) (mutualMember : Bool := false)
    (defaultPrivate : Bool := false) :
    Except String (PsParseResult PsSyntaxCommand) :=
  psPscv0ReadAttributedCommand (fun cursor =>
    psLeanProgramUnattributedCommand cursor mutualMember defaultPrivate) cursor

def psLeanProgramMutual (fuel : Nat) (cursor : PsTokenCursor)
    (membersRev : List PsSyntaxMutualMember) (defaultPrivate : Bool := false) :
    Except String (PsParseResult (List PsSyntaxMutualMember × PsSourceSpan)) := do
  match fuel with
  | 0 => throw "PSCV0-MUTUAL-MEMBER-BUDGET"
  | fuel + 1 =>
    if psTokenCursorAtText cursor "end" then
      if membersRev.isEmpty then throw "PSCV0-MUTUAL-EMPTY"
      let closing ← psPscv0Expect cursor "end"
      return { value := (membersRev.reverse, closing.token.span), cursor := closing.cursor }
    let parsed ← psLeanProgramOrdinaryCommand cursor true defaultPrivate
    let member ← match parsed.value with
      | .declaration declaration => pure (PsSyntaxMutualMember.mk declaration false none [])
      | .privateDeclaration declaration => pure (PsSyntaxMutualMember.mk declaration true none [])
      | .registeredDeclaration declaration registration =>
        pure (PsSyntaxMutualMember.mk declaration false (some registration) [])
      | .privateRegisteredDeclaration declaration registration =>
        pure (PsSyntaxMutualMember.mk declaration true (some registration) [])
      | .attributedDeclaration declaration registration isPrivate attributes =>
        pure { declaration, registration, isPrivate, attributes }
      | _ => throw "PSCV0-MUTUAL-HEAD"
    psLeanProgramMutual fuel parsed.cursor (member :: membersRev) defaultPrivate

-- Native public-section syntax lowers to the existing scope command and final
-- declaration modifiers. Names, binders and end validation remain in the shared
-- scope owner; this adapter only expands Lean's inherited visibility default.
def psLeanProgramPublicSection (cursor : PsTokenCursor) :
    Except String (Option (PsParseResult PsSyntaxCommand)) := do
  if !psTokenCursorAtText cursor "public" then return none
  let marker ← psPscv0Expect cursor "public"
  if !psTokenCursorAtText marker.cursor "section" then return none
  let some parsed ← psPscv0ReadScopeCommand psLeanProgramBinders marker.cursor
    | throw "PSCV0-LEAN-PUBLIC-SECTION"
  let .sectionCmd name span := parsed.value
    | throw "PSCV0-LEAN-PUBLIC-SECTION"
  return some { parsed with
    value := .sectionCmd name { span with start := marker.token.span.start } }

def psLeanProgramCommands (fuel : Nat) (cursor : PsTokenCursor)
    (commandsRev : List PsSyntaxCommand) (defaultPrivate : Bool := false)
    (visibilityDefaults : List Bool := []) :
    Except String (List PsSyntaxCommand) := do
  match fuel with
  | 0 => throw "PSCV0-LEAN-COMMAND-BUDGET"
  | fuel + 1 =>
    if psTokenCursorDone cursor then return commandsRev.reverse
    if psTokenCursorAtText cursor "module" then
      throw "PSCV0-LEAN-MODULE-HEADER: module must be the first token and occur once"
    if psTokenCursorAtText cursor "import" then
      throw "PSCV0-LEAN-IMPORT-ORDER: imports must precede commands"
    if psTokenCursorAtText cursor "public" then
      let marker ← psPscv0Expect cursor "public"
      if psTokenCursorAtText marker.cursor "import" then
        throw "PSCV0-LEAN-IMPORT-ORDER: imports must precede commands"
    let publicSection ← psLeanProgramPublicSection cursor
    let parsed ← match publicSection with
      | some parsed => pure parsed
      | none =>
        if psTokenCursorAtText cursor "mutual" then do
          let opening ← psPscv0Expect cursor "mutual"
          let members ← psLeanProgramMutual 4096 opening.cursor [] defaultPrivate
          pure (PsParseResult.mk (.mutualDeclarations members.value.1
            { start := opening.token.span.start, stop := members.value.2.stop }) members.cursor)
        else psLeanProgramOrdinaryCommand cursor false defaultPrivate
    let pushVisibility := fun (components : List String) (isPublic : Bool) =>
      components.foldl (fun (state : Bool × List Bool) _ =>
        (state.fst && !isPublic, state.fst :: state.snd))
        (defaultPrivate, visibilityDefaults)
    let (nextPrivate, nextDefaults) := match parsed.value with
      | .sectionCmd name _ =>
          pushVisibility ((name.map (·.segments)).getD [""]) publicSection.isSome
      | .namespaceCmd name _ => pushVisibility name.segments false
      | .endCmd name _ =>
          ((name.map (·.segments)).getD [""]).foldl
            (fun (state : Bool × List Bool) _ => match state.snd with
              | saved :: rest => (saved, rest)
              | [] => (state.fst, []))
            (defaultPrivate, visibilityDefaults)
      | _ => (defaultPrivate, visibilityDefaults)
    psLeanProgramCommands fuel parsed.cursor (parsed.value :: commandsRev)
      nextPrivate nextDefaults

-- Selected native headers follow pinned Parser.Module.Syntax and parseHeader.
-- Public imports require module mode. The existing no-header input route keeps
-- its prior visibility; module declarations default private unless marked public.
def psLeanProgramImports (fuel : Nat) (cursor : PsTokenCursor)
    (hasModuleHeader : Bool) (importsRev : List PsSyntaxImport) :
    Except String (PsParseResult (List PsSyntaxImport)) := do
  match fuel with
  | 0 => throw "PSCV0-LEAN-IMPORT-BUDGET"
  | fuel + 1 =>
    if psTokenCursorAtText cursor "import" then
      let parsed ← (psParseLeanImport cursor).mapError psPscv0ParseError
      psLeanProgramImports fuel parsed.cursor hasModuleHeader (parsed.value :: importsRev)
    else if psTokenCursorAtText cursor "public" then
      let marker ← psPscv0Expect cursor "public"
      if !psTokenCursorAtText marker.cursor "import" then
        return { value := importsRev.reverse, cursor }
      if !hasModuleHeader then
        throw "PSCV0-LEAN-MODULE-REQUIRED: public import requires a leading module header"
      let parsed ← (psParseLeanImport marker.cursor).mapError psPscv0ParseError
      let sourceImport := { parsed.value with
        isPublic := true
        span := { parsed.value.span with start := marker.token.span.start } }
      psLeanProgramImports fuel parsed.cursor hasModuleHeader (sourceImport :: importsRev)
    else return { value := importsRev.reverse, cursor }

def psLeanParseProgram (source : String) : Except String PsSyntaxProgram := do
  if source.utf8ByteSize > 1048576 then throw "PSCV0-SOURCE-BYTE-BUDGET"
  let tokens ← (psLex source).mapError (fun _ => "PSCV0-LEAN-LEX")
  if tokens.length > 65536 then throw "PSCV0-SOURCE-TOKEN-BUDGET"
  let cursor := psTokenCursorFromTokens tokens
  let hasModuleHeader := psTokenCursorAtText cursor "module"
  let cursor ← if hasModuleHeader then pure (← psPscv0Expect cursor "module").cursor else pure cursor
  let imports ← psLeanProgramImports (tokens.length + 1) cursor hasModuleHeader []
  let commands ← psLeanProgramCommands 4096 imports.cursor [] hasModuleHeader
  return { imports := imports.value, commands, isModule := hasModuleHeader }
