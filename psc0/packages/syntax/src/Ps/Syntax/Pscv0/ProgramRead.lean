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

def psPscv0ReadCommand (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxCommand) := do
  let some token := psTokenCursorPeek cursor | throw "PSCV0-COMMAND-MISSING"
  if token.text == "instance" then
    let parsed ← (psPscv0ReadInstance cursor).mapError psPscv0ParseError
    let .registeredDeclaration declaration _ := parsed.value | throw "PSCV0-INSTANCE-DECLARATION"
    let next ← (psParseProofScriptCommandSeparator
      (psProofScriptDeclarationStop declaration) parsed.cursor).mapError psPscv0ParseError
    return { parsed with cursor := next }
  if token.text == "class" then
    let parsed ← (psPscv0ReadDataDeclaration cursor).mapError psPscv0ParseError
    let next ← (psParseProofScriptCommandSeparator
      (psProofScriptDeclarationStop parsed.value) parsed.cursor).mapError psPscv0ParseError
    return { value := .registeredDeclaration parsed.value .classDecl, cursor := next }
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
    return { value := command, cursor := names.cursor }
  if token.text == "variable" then
    let head ← psPscv0Expect cursor "variable"
    let binders ← (psPscv0ParameterGroups (psPscv0ParseTerm true) (psPscv0ParseTerm false) 4096 false false false head.cursor []).mapError psPscv0ParseError
    if binders.value.isEmpty then throw "PSCV0-VARIABLE-BINDERS-REQUIRED"
    let stop := psProofScriptLastBinderStop token.span.stop binders.value
    let next ← (psParseProofScriptCommandSeparator stop binders.cursor).mapError psPscv0ParseError
    return { value := .variableCmd binders.value { start := token.span.start, stop }, cursor := next }
  let declaration ← psPscv0ReadDeclaration cursor
  let next ← (psParseProofScriptCommandSeparator
    (psProofScriptDeclarationStop declaration.value) declaration.cursor).mapError psPscv0ParseError
  return { value := .declaration declaration.value, cursor := next }

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
  return { imports := imports.value, commands }
