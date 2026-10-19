import Ps.Syntax.Pscv0.LocalRead

-- Closed live dispatch, shared with the independent selected-surface ledger.
-- Lean 4.35.0 Parser/Extension and Elab/Tactic/Basic use scoped keyed tables;
-- the selected PSCV0 vocabulary needs no dynamic parser/elaborator extension.
inductive PsPscv0TacticParser where
  | exactE (refine : Bool)
  | applyE
  | eliminate (induction : Bool)
  | caseE (tagged : Bool)
  | localE (isLet : Bool)
  | change (showGoal : Bool)
  | intro
  | assumption
  | reflexivity
  | constructor
  | focus (bullet : Bool)
  | each (anyGoal : Bool)

def psPscv0TacticRegistry : List (String × PsPscv0TacticParser) := [
  ("exact", .exactE false), ("refine", .exactE true), ("apply", .applyE),
  ("cases", .eliminate false), ("induction", .eliminate true),
  ("case", .caseE true), ("next", .caseE false),
  ("have", .localE false), ("let", .localE true),
  ("change", .change false), ("show", .change true), ("intro", .intro),
  ("assumption", .assumption), ("rfl", .reflexivity), ("constructor", .constructor),
  ("·", .focus true), ("focus", .focus false), ("all_goals", .each false),
  ("any_goals", .each true)]

def psPscv0TacticParserName : PsPscv0TacticParser → String
  | .exactE refine => if refine then "refine" else "exact"
  | .applyE => "apply"
  | .eliminate induction => if induction then "induction" else "cases"
  | .caseE tagged => if tagged then "case" else "next"
  | .localE isLet => if isLet then "let" else "have"
  | .change showGoal => if showGoal then "show" else "change"
  | .intro => "intro"
  | .assumption => "assumption"
  | .reflexivity => "rfl"
  | .constructor => "constructor"
  | .focus bullet => if bullet then "·" else "focus"
  | .each anyGoal => if anyGoal then "any_goals" else "all_goals"


def psPscv0IntroNames (fuel line : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := [], cursor }
    if token.span.start.line != line || ["}", ";"].contains token.text then
      return { value := [], cursor }
    let name ← psTokenCursorExpectKind cursor .identifier
    let rest ← psPscv0IntroNames fuel line name.cursor
    return {
      value := (psSyntaxNameFromToken name.token) :: rest.value
      cursor := rest.cursor }

def psPscv0CaseNames (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "=>" then return { value := [], cursor }
    let name ← psTokenCursorExpectKind cursor .identifier
    let rest ← psPscv0CaseNames fuel name.cursor
    return {
      value := (psSyntaxNameFromToken name.token) :: rest.value
      cursor := rest.cursor }

def psPscv0ReadTacticsFor (nativeLayout : Bool) (read readType : PsPscv0TermReader) (fuel : Nat)
    (boundary : Option PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxTactic)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if nativeLayout && psTokenCursorDone cursor then return { value := [], cursor }
    let some token := psTokenCursorPeek cursor
      | if nativeLayout then return { value := [], cursor }
        else throw (.unexpectedEnd "tactic block")
    if token.text == "}" ||
        (nativeLayout && [")", "]", ","].contains token.text) || boundary.any (fun pos =>
        token.span.start.line > pos.line && token.span.start.column <= pos.column) then
      return { value := [], cursor }
    let head ← psTokenCursorExpectText cursor token.text
    let some selected := psPscv0TacticRegistry.find? (fun entry => entry.1 == token.text)
      | throw (psProofScriptExpectedError "selected tactic" cursor)
    let (tactic, next) ← match selected.2 with
      | .exactE refine =>
        let value ← read head.cursor
        let span := psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value)
        pure (PsSyntaxTactic.exactE value.value refine span, value.cursor)
      | .applyE =>
        let value ← read head.cursor
        pure (PsSyntaxTactic.applyE value.value
          (psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value)), value.cursor)
      | .eliminate induction =>
        let value ← read head.cursor
        pure (.eliminate value.value induction
          (psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value)), value.cursor)
      | .caseE tagged => do
        let (tag, cursor) ← if !tagged then pure (none, head.cursor) else do
          let name ← psParseSyntaxName head.cursor
          pure (if psSyntaxNameIsAnonymous name.value then none else some name.value, name.cursor)
        let names ← psPscv0CaseNames fuel cursor
        let arrow ← psTokenCursorExpectText names.cursor "=>"
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel (some token.span.start) arrow.cursor
        if body.value.isEmpty then throw (psProofScriptExpectedError "case tactic body" arrow.cursor)
        pure (.caseE tag names.value body.value token.span, body.cursor)
      | .localE isLet =>
        let fact ← psPscv0ReadLocal read readType cursor
        pure (.localE fact.value.name fact.value.type fact.value.value
          isLet fact.value.span, fact.cursor)
      | .change showGoal =>
        let type ← readType head.cursor
        pure (.change type.value showGoal
          (psSyntaxSpanJoin token.span (psSyntaxTermSpan type.value)), type.cursor)
      | .intro =>
        let names ← psPscv0IntroNames fuel token.span.start.line head.cursor
        pure (.intro names.value token.span, names.cursor)
      | .assumption => pure (.assumption token.span, head.cursor)
      | .reflexivity => pure (.reflexivity token.span, head.cursor)
      | .constructor => pure (.constructor token.span, head.cursor)
      | .focus bullet =>
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel (some token.span.start) head.cursor
        if body.value.isEmpty then throw (psProofScriptExpectedError "focused tactic" head.cursor)
        pure (.focus body.value bullet token.span, body.cursor)
      | .each anyGoal =>
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel (some token.span.start) head.cursor
        if body.value.isEmpty then throw (psProofScriptExpectedError "focused tactic" head.cursor)
        pure (.each body.value anyGoal token.span, body.cursor)
    let consumed := cursor.remaining.take (cursor.remaining.length - next.remaining.length)
    let stop := (consumed.getLast?).map (·.span.stop) |>.getD token.span.stop
    let semicolon := nativeLayout && psTokenCursorAtText next ";"
    let next ← if semicolon then
      pure (← psTokenCursorExpectText next ";").cursor else pure next
    let termBoundary := nativeLayout && [")", "]", ","].any (psTokenCursorAtText next)
    if !psTokenCursorDone next && !psTokenCursorAtText next "}" && !termBoundary &&
        !psProofScriptLaterLine stop next && !semicolon then
      throw (psProofScriptExpectedError "newline-separated tactic" next)
    let rest ← psPscv0ReadTacticsFor nativeLayout read readType fuel boundary next
    return { value := tactic :: rest.value, cursor := rest.cursor }

def psPscv0ReadTactics := psPscv0ReadTacticsFor false

def psPscv0ReadProof (read readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "by"
  let opening ← psTokenCursorExpectText keyword.cursor "{"
  let tactics ← psPscv0ReadTactics read readType fuel none opening.cursor
  let close ← psTokenCursorExpectText tactics.cursor "}"
  return {
    value := .byE tactics.value {} (psSyntaxSpanJoin keyword.token.span close.token.span)
    cursor := close.cursor }
