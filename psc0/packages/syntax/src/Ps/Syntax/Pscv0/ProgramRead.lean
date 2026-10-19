import Ps.Syntax.Pscv0.Instances

def psPscv0CommandNames (line fuel : Nat) (cursor : PsTokenCursor)
    (acc : List PsSyntaxName) : Except String (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw "PSCV0-COMMAND-NAME-BUDGET"
  | fuel + 1 =>
    match psTokenCursorPeek cursor with
    | none => return { value := acc.reverse, cursor }
    | some token =>
      if token.span.start.line != line then return { value := acc.reverse, cursor }
      let name ← (psParseSyntaxName cursor).mapError psPscv0ParseError
      psPscv0CommandNames line fuel name.cursor (name.value :: acc)

-- A deriving clause is parsed after the data body's closing brace,
-- before the command separator. The syntax layer selects a fixed handler
-- vocabulary; the elaborator supplies the checked generated instance.
def psPscv0SelectedDerivingNames : List String :=
  ["Inhabited", "BEq", "DecidableEq", "Repr", "Hashable"]

def psPscv0DerivingHandlers (fuel : Nat) (cursor : PsTokenCursor)
    (acc : List PsSyntaxName) : Except String (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw "PSCV0-DERIVE-HANDLER-BUDGET"
  | fuel + 1 =>
    let name ← (psParseSyntaxName cursor).mapError psPscv0ParseError
    let selected := name.value.segments
    if !(psPscv0SelectedDerivingNames.map fun name => [name]).contains selected then
      throw "PSCV0-DERIVE-HANDLER-UNKNOWN"
    if (acc.any (fun previous => previous.segments == selected)) then
      throw "PSCV0-DERIVE-HANDLER-DUPLICATE"
    let accumulated := name.value :: acc
    if psTokenCursorAtText name.cursor "," then
      let comma ← (psTokenCursorExpectText name.cursor ",").mapError psPscv0ParseError
      psPscv0DerivingHandlers fuel comma.cursor accumulated
    else return { value := accumulated.reverse, cursor := name.cursor }

-- Scope command syntax is common to the two v7.2 inputs. The caller owns
-- binder grammar; scope meaning remains exclusively in Ps.Elab.Command.
def psPscv0ReadScopeCommand
    (readBinders : PsTokenCursor → Except PsParseError
      (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))))
    (cursor : PsTokenCursor) : Except String (Option (PsParseResult PsSyntaxCommand)) := do
  let some token := psTokenCursorPeek cursor | return none
  if ["namespace", "section", "end", "open", "include", "omit", "universe"].contains token.text then
    let head ← psPscv0Expect cursor token.text
    let names ← psPscv0CommandNames token.span.start.line 4096 head.cursor []
    let stop := match names.value.getLast? with | none => token.span | some name => name.span
    let span := psSyntaxSpanJoin token.span stop
    let command ← match token.text, names.value with
      | "universe", _ :: _ => pure (.universeCmd names.value span)
      | "namespace", [name] => pure (.namespaceCmd name span)
      | "section", [] => pure (.sectionCmd none span)
      | "section", [name] => pure (.sectionCmd (some name) span)
      | "end", [] => pure (.endCmd none span)
      | "end", [name] => pure (.endCmd (some name) span)
      | "open", _ :: _ => pure (.openCmd names.value span)
      | "include", _ :: _ => pure (.includeCmd names.value span)
      | "omit", _ :: _ => pure (.omitCmd names.value span)
      | _, _ => throw "PSCV0-COMMAND-ARGUMENTS"
    return some { value := command, cursor := names.cursor }
  if token.text == "variable" then
    let head ← psPscv0Expect cursor "variable"
    let binders ← (readBinders head.cursor).mapError psPscv0ParseError
    if binders.value.isEmpty then throw "PSCV0-VARIABLE-BINDERS-REQUIRED"
    let stop := psProofScriptLastBinderStop token.span.stop binders.value
    let next ← (psParseProofScriptCommandSeparator stop binders.cursor).mapError psPscv0ParseError
    return some { value := .variableCmd binders.value { start := token.span.start, stop }, cursor := next }
  return none

def psPscv0ReadUnattributedCommand (cursor : PsTokenCursor)
    (mutualMember : Bool := false) :
    Except String (PsParseResult PsSyntaxCommand) := do
  let some first := psTokenCursorPeek cursor | throw "PSCV0-COMMAND-MISSING"
  let isPrivate := first.text == "private"
  let cursor ← if isPrivate then
    let marker ← psPscv0Expect cursor "private"
    pure marker.cursor
  else pure cursor
  let some token := psTokenCursorPeek cursor | throw "PSCV0-PRIVATE-DECLARATION-MISSING"
  if mutualMember && !["def", "function", "partial", "unsafe", "noncomputable"].contains token.text then
    throw "PSCV0-MUTUAL-HEAD: a source mutual member must use a selected def or function head"
  if isPrivate && !["instance", "abbrev", "opaque", "class", "def", "const",
      "function", "theorem", "structure", "inductive", "partial", "unsafe", "noncomputable"].contains token.text then
    throw "PSCV0-PRIVATE-DECLARATION-EXPECTED"
  if token.text == "instance" then
    let parsed ← (psPscv0ReadInstance cursor).mapError psPscv0ParseError
    let .registeredDeclaration declaration _ := parsed.value | throw "PSCV0-INSTANCE-DECLARATION"
    let next ← (psParseProofScriptCommandSeparator
      (psProofScriptDeclarationStop declaration) parsed.cursor).mapError psPscv0ParseError
    let command := match parsed.value with
      | .registeredDeclaration source registration =>
          if isPrivate then .privateRegisteredDeclaration source registration
          else parsed.value
      | _ => parsed.value
    return { value := command, cursor := next }
  if token.text == "abbrev" || token.text == "opaque" then
    let parsed ← psPscv0ReadValueDeclaration cursor
    let next ← (psParseProofScriptCommandSeparator
      (psProofScriptDeclarationStop parsed.value) parsed.cursor).mapError psPscv0ParseError
    let registration : PsSyntaxRegistration :=
      if token.text == "abbrev" then .abbrevDecl else .opaqueDecl
    let command := if isPrivate then
      PsSyntaxCommand.privateRegisteredDeclaration parsed.value registration
    else PsSyntaxCommand.registeredDeclaration parsed.value registration
    return { value := command, cursor := next }
  if token.text == "class" then
    let parsed ← (psPscv0ReadDataDeclaration cursor).mapError psPscv0ParseError
    let next ← (psParseProofScriptCommandSeparator
      (psProofScriptDeclarationStop parsed.value) parsed.cursor).mapError psPscv0ParseError
    let command := if isPrivate then
      PsSyntaxCommand.privateRegisteredDeclaration parsed.value .classDecl
    else PsSyntaxCommand.registeredDeclaration parsed.value .classDecl
    return { value := command, cursor := next }
  if token.text == "structure" || token.text == "inductive" then
    let parsed ← (psPscv0ReadDataDeclaration cursor).mapError psPscv0ParseError
    let stop := psProofScriptDeclarationStop parsed.value
    if psTokenCursorAtText parsed.cursor "deriving" then
      let marker ← (psTokenCursorExpectText parsed.cursor "deriving").mapError psPscv0ParseError
      let handlers ← psPscv0DerivingHandlers 128 marker.cursor []
      let some finalHandler := handlers.value.getLast?
        | throw "PSCV0-DERIVE-HANDLER-REQUIRED"
      let next ← (psParseProofScriptCommandSeparator finalHandler.span.stop
        handlers.cursor).mapError psPscv0ParseError
      let command := PsSyntaxCommand.derivingDeclaration
        parsed.value handlers.value isPrivate
      return { value := command, cursor := next }
    let next ← (psParseProofScriptCommandSeparator stop parsed.cursor).mapError psPscv0ParseError
    let command := if isPrivate then
      PsSyntaxCommand.privateDeclaration parsed.value
    else PsSyntaxCommand.declaration parsed.value
    return { value := command, cursor := next }
  if let some scopeCommand ← psPscv0ReadScopeCommand
      (fun cursor => psPscv0ParameterGroups (psPscv0ParseTerm true)
        (psPscv0ParseTerm false) 4096 false false false cursor []) cursor then
    return scopeCommand
  let declaration ← psPscv0ReadDeclaration cursor
  let next ← (psParseProofScriptCommandSeparator
    (psProofScriptDeclarationStop declaration.value) declaration.cursor).mapError psPscv0ParseError
  return { value := if isPrivate then .privateDeclaration declaration.value
                    else .declaration declaration.value, cursor := next }

def psPscv0SelectedAttributes : List String := ["simp", "instance", "default_instance"]

-- The selected list uses native comma ownership. Only the already-selected
-- default-instance priority spelling has an argument; simp/instance are bare.
def psPscv0ReadAttributes (fuel : Nat) (cursor : PsTokenCursor)
    (attributesRev : List PsSyntaxAttribute) :
    Except String (PsParseResult (List PsSyntaxAttribute)) := do
  match fuel with
  | 0 => throw "PSCV0-ATTRIBUTE-COUNT-BUDGET"
  | fuel + 1 =>
    let some name := psTokenCursorAdvance cursor
      | throw "PSCV0-ATTRIBUTE-NAME: expected selected attribute"
    if !psPscv0SelectedAttributes.contains name.token.text then
      throw ("PSCV0-ATTRIBUTE-NAME: unselected attribute " ++ name.token.text)
    let parsed ← if name.token.text == "default_instance" then do
      let priority ←
        if psTokenCursorAtText name.cursor "]" || psTokenCursorAtText name.cursor "," then
          pure (PsParseResult.mk 1000 name.cursor)
        else do
          let some atom := psTokenCursorAdvance name.cursor
            | throw "PSCV0-DEFAULT-INSTANCE-PRIORITY"
          let value ← (psPscv0PriorityValue atom.token.text name.cursor).mapError psPscv0ParseError
          pure (PsParseResult.mk value atom.cursor)
      pure (PsParseResult.mk (.defaultInstanceAttribute priority.value) priority.cursor)
    else
      pure (PsParseResult.mk
        (if name.token.text == "simp" then PsSyntaxAttribute.simpAttribute else .instanceAttribute)
        name.cursor)
    let attributesRev := parsed.value :: attributesRev
    if psTokenCursorAtText parsed.cursor "]" then
      let close ← psPscv0Expect parsed.cursor "]"
      return { value := attributesRev.reverse, cursor := close.cursor }
    let comma ← psPscv0Expect parsed.cursor ","
    psPscv0ReadAttributes fuel comma.cursor attributesRev

-- Preserve the established single-default AST contract. General lists keep
-- the declaration's source kind separate from its post-check registrations.
def psPscv0AttachAttributes : List PsSyntaxAttribute → PsSyntaxCommand →
    Except String PsSyntaxCommand
  | [.defaultInstanceAttribute priority], .declaration source =>
    pure (.registeredDeclaration source (.defaultInstanceDecl priority none))
  | [.defaultInstanceAttribute priority], .privateDeclaration source =>
    pure (.privateRegisteredDeclaration source (.defaultInstanceDecl priority none))
  | [.defaultInstanceAttribute priority], .registeredDeclaration source (.instanceDecl ordinary) =>
    pure (.registeredDeclaration source (.defaultInstanceDecl priority (some ordinary)))
  | [.defaultInstanceAttribute priority], .privateRegisteredDeclaration source (.instanceDecl ordinary) =>
    pure (.privateRegisteredDeclaration source (.defaultInstanceDecl priority (some ordinary)))
  | attributes, .declaration source =>
    pure (.attributedDeclaration source none false attributes)
  | attributes, .privateDeclaration source =>
    pure (.attributedDeclaration source none true attributes)
  | attributes, .registeredDeclaration source registration =>
    pure (.attributedDeclaration source (some registration) false attributes)
  | attributes, .privateRegisteredDeclaration source registration =>
    pure (.attributedDeclaration source (some registration) true attributes)
  | attributes, .derivingDeclaration source handlers isPrivate =>
    pure (.attributedDerivingDeclaration source handlers isPrivate attributes)
  | _, _ => throw "PSCV0-ATTRIBUTE-DECLARATION: selected declaration required"

def psPscv0ReadAttributedCommand
    (readCommand : PsTokenCursor → Except String (PsParseResult PsSyntaxCommand))
    (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxCommand) := do
  if !psTokenCursorAtText cursor "@" then readCommand cursor
  else
    let marker ← psPscv0Expect cursor "@"
    let opening ← psPscv0Expect marker.cursor "["
    let attributes ← psPscv0ReadAttributes 4096 opening.cursor []
    let parsed ← readCommand attributes.cursor
    let command ← psPscv0AttachAttributes attributes.value parsed.value
    return { parsed with value := command }

def psPscv0ReadOrdinaryCommand (cursor : PsTokenCursor)
    (mutualMember : Bool := false) :
    Except String (PsParseResult PsSyntaxCommand) :=
  psPscv0ReadAttributedCommand (fun cursor =>
    psPscv0ReadUnattributedCommand cursor mutualMember) cursor

-- Pinned Lean Parser.Command.mutual owns the complete ordered block before
-- elaboration partitions recursive cliques. The v7.2 source selection keeps
-- def/function heads only; existing per-head binders and suffix rules remain
-- authoritative. No provisional logical declarations are made by parsing.
def psPscv0ReadMutualMembers (fuel : Nat) (cursor : PsTokenCursor)
    (membersRev : List PsSyntaxMutualMember) :
    Except String (PsParseResult (List PsSyntaxMutualMember × PsSourceSpan)) := do
  match fuel with
  | 0 => throw "PSCV0-MUTUAL-MEMBER-BUDGET"
  | fuel + 1 =>
    if psTokenCursorDone cursor then throw "PSCV0-MUTUAL-END: missing end for mutual block"
    if psTokenCursorAtText cursor "end" then
      if membersRev.isEmpty then throw "PSCV0-MUTUAL-EMPTY: mutual requires a def or function"
      let closing ← psPscv0Expect cursor "end"
      return PsParseResult.mk (membersRev.reverse, closing.token.span) closing.cursor
    let parsed ← psPscv0ReadOrdinaryCommand cursor true
    let member ← match parsed.value with
      | .declaration declaration => pure (PsSyntaxMutualMember.mk declaration false none [])
      | .privateDeclaration declaration => pure (PsSyntaxMutualMember.mk declaration true none [])
      | .registeredDeclaration declaration registration =>
        pure (PsSyntaxMutualMember.mk declaration false (some registration) [])
      | .privateRegisteredDeclaration declaration registration =>
        pure (PsSyntaxMutualMember.mk declaration true (some registration) [])
      | .attributedDeclaration declaration registration isPrivate attributes =>
        pure { declaration, registration, isPrivate, attributes }
      | _ => throw "PSCV0-MUTUAL-HEAD: only selected function-like declarations belong to mutual"
    psPscv0ReadMutualMembers fuel parsed.cursor (member :: membersRev)

def psPscv0ReadCommand (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxCommand) := do
  if !psTokenCursorAtText cursor "mutual" then
    return ← psPscv0ReadOrdinaryCommand cursor
  let opening ← psPscv0Expect cursor "mutual"
  let parsed ← psPscv0ReadMutualMembers 4096 opening.cursor []
  let span := PsSourceSpan.mk opening.token.span.start parsed.value.2.stop
  let next ← (psParseProofScriptCommandSeparator span.stop parsed.cursor).mapError psPscv0ParseError
  return PsParseResult.mk (.mutualDeclarations parsed.value.1 span) next

def psPscv0ReadCommands (fuel : Nat) (cursor : PsTokenCursor)
    (acc : List PsSyntaxCommand) : Except String (List PsSyntaxCommand) := do
  match fuel with
  | 0 => throw "PSCV0-COMMAND-COUNT-BUDGET"
  | fuel + 1 =>
    if psTokenCursorDone cursor then return acc.reverse
    let next ← psPscv0ReadCommand cursor
    psPscv0ReadCommands fuel next.cursor (next.value :: acc)

def psPscv0ParseProgramTokens (tokens : List PsToken) : Except String PsSyntaxProgram := do
  let imports ← (psParseProofScriptImportsWithFuel (tokens.length + 1)
    (psTokenCursorFromTokens tokens) []).mapError psPscv0ParseError
  let commands ← psPscv0ReadCommands 4096 imports.cursor []
  return { imports := imports.value, commands, isModule := true }

