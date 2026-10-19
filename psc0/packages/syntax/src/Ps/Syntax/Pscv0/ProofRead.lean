import Ps.Syntax.Pscv0.LocalRead
import Ps.Syntax.Pscv0.RCasesRead

-- Closed live dispatch, shared with the independent selected-surface ledger.
-- Lean 4.35.0 Parser/Extension and Elab/Tactic/Basic use scoped keyed tables;
-- the selected PSCV0 vocabulary needs no dynamic parser/elaborator extension.
inductive PsPscv0TacticParser where
  | exactE (refine : Bool)
  | applyE
  | eliminate (induction : Bool)
  | rcasesE
  | rintroE
  | obtainE
  | byCases
  | exfalso
  | decide
  | extE
  | caseE (tagged : Bool)
  | localE (isLet : Bool)
  | change (showGoal : Bool)
  | intro
  | intros
  | suffices
  | classicalE
  | group
  | bracedGroup
  | assumption
  | reflexivity
  | constructor
  | constructorFirst
  | focus (bullet : Bool)
  | each (anyGoal : Bool)

def psPscv0TacticRegistry : List (String × PsPscv0TacticParser) := [
  ("exact", .exactE false), ("refine", .exactE true), ("apply", .applyE),
  ("cases", .eliminate false), ("induction", .eliminate true),
  ("rcases", .rcasesE), ("rintro", .rintroE), ("obtain", .obtainE),
  ("by_cases", .byCases), ("exfalso", .exfalso), ("decide", .decide), ("ext", .extE),
  ("case", .caseE true), ("next", .caseE false),
  ("have", .localE false), ("let", .localE true),
  ("change", .change false), ("show", .change true), ("intro", .intro),
  ("intros", .intros), ("suffices", .suffices), ("classical", .classicalE), ("(", .group), ("{", .bracedGroup),
  ("assumption", .assumption), ("rfl", .reflexivity), ("constructor", .constructor),
  ("constructor!", .constructorFirst),
  ("·", .focus true), ("focus", .focus false), ("all_goals", .each false),
  ("any_goals", .each true)]

def psPscv0TacticParserName : PsPscv0TacticParser → String
  | .exactE refine => if refine then "refine" else "exact"
  | .applyE => "apply"
  | .eliminate induction => if induction then "induction" else "cases"
  | .rcasesE => "rcases"
  | .rintroE => "rintro"
  | .obtainE => "obtain"
  | .byCases => "by_cases"
  | .exfalso => "exfalso"
  | .decide => "decide"
  | .extE => "ext"
  | .caseE tagged => if tagged then "case" else "next"
  | .localE isLet => if isLet then "let" else "have"
  | .change showGoal => if showGoal then "show" else "change"
  | .intro => "intro"
  | .intros => "intros"
  | .suffices => "suffices"
  | .classicalE => "classical"
  | .group => "("
  | .bracedGroup => "{"
  | .assumption => "assumption"
  | .reflexivity => "rfl"
  | .constructor => "constructor"
  | .constructorFirst => "constructor!"
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

-- Named introductions follow native colGt layout. Punctuation ends the
-- argument list before a sequence delimiter or the selected <;> combinator.
def psPscv0ReadIntroNames (fuel : Nat) (start : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := [], cursor }
    if psTokenCursorDone cursor || ["}", ")", "]", ",", ";", "<;>"].contains token.text ||
        (token.span.start.line > start.line && token.span.start.column <= start.column) then
      return { value := [], cursor }
    let name ← psTokenCursorExpectKind cursor .identifier
    let rest ← psPscv0ReadIntroNames fuel start name.cursor
    return { value := psSyntaxNameFromToken name.token :: rest.value, cursor := rest.cursor }

-- Native Init/Tactics lowers <;> through focus and all_goals. Reading one
-- right operand preserves its precedence; repeating here gives left association.
def psPscv0ReadAndThen
    (readOne : PsTokenCursor → Except PsParseError (PsParseResult (List PsSyntaxTactic)))
    (fuel : Nat) (span : PsSourceSpan) (left : PsSyntaxTactic) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTactic) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psTokenCursorAtText cursor "<;>" then return { value := left, cursor }
    let operator ← psTokenCursorExpectText cursor "<;>"
    let right ← readOne operator.cursor
    let [rightTactic] := right.value
      | throw (psProofScriptExpectedError "tactic after <;>" operator.cursor)
    let consumed := operator.cursor.remaining.take
      (operator.cursor.remaining.length - right.cursor.remaining.length)
    let stop := (consumed.getLast?).map (·.span.stop) |>.getD operator.token.span.stop
    let span := PsSourceSpan.mk span.start stop
    let combined := PsSyntaxTactic.focus
      [left, .each [rightTactic] false operator.token.span] false span
    psPscv0ReadAndThen readOne fuel span combined right.cursor

def psPscv0ReadTacticsFor (nativeLayout : Bool) (read readType : PsPscv0TermReader) (fuel : Nat)
    (boundary : Option PsSourcePos) (cursor : PsTokenCursor)
    (single : Bool := false) (closing : String := "}") :
    Except PsParseError (PsParseResult (List PsSyntaxTactic)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if nativeLayout && psTokenCursorDone cursor then return { value := [], cursor }
    let some token := psTokenCursorPeek cursor
      | if nativeLayout then return { value := [], cursor }
        else throw (.unexpectedEnd "tactic block")
    if token.text == closing || token.text == "}" ||
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
      | .rcasesE =>
        let result ← psPscv0ReadRCases read readType fuel head
        pure (result.value, result.cursor)
      | .rintroE =>
        let result ← psPscv0ReadRIntro readType fuel head
        pure (result.value, result.cursor)
      | .obtainE =>
        let result ← psPscv0ReadObtain read readType fuel head
        pure (result.value, result.cursor)
      | .byCases => do
        let named := (head.cursor.remaining.drop 1).head?.any (fun token => token.text == ":")
        let (name, next) ← if named then do
          let name ← psParseSyntaxName head.cursor
          let colon ← psTokenCursorExpectText name.cursor ":"
          pure (some name.value, colon.cursor)
        else pure (none, head.cursor)
        let proposition ← readType next
        pure (.byCases name proposition.value
          (psSyntaxSpanJoin token.span (psSyntaxTermSpan proposition.value)), proposition.cursor)
      | .exfalso => pure (.exfalso token.span, head.cursor)
      | .decide => pure (.decide token.span, head.cursor)
      | .extE => do
        let patterns ← psPscv0RIntroPatterns readType fuel
          (some token.span.start) head.cursor
        let (depth, next) ← if psTokenCursorAtText patterns.cursor ":" then do
          let colon ← psTokenCursorExpectText patterns.cursor ":"
          let some numeral := psTokenCursorPeek colon.cursor
            | throw (psProofScriptExpectedError "ext depth" colon.cursor)
          let some depth := psParseNaturalText numeral.text
            | throw (psProofScriptExpectedError "natural ext depth" colon.cursor)
          let number ← psTokenCursorExpectText colon.cursor numeral.text
          pure (depth, number.cursor)
        else pure (100, patterns.cursor)
        pure (.extE patterns.value depth token.span, next)
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
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel (some token.span.start) arrow.cursor false closing
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
        let names ← psPscv0ReadIntroNames fuel token.span.start head.cursor
        pure (.intro names.value token.span, names.cursor)
      | .intros =>
        let names ← psPscv0ReadIntroNames fuel token.span.start head.cursor
        pure (.intros names.value token.span, names.cursor)
      | .suffices =>
        let fact ← psPscv0ReadSuffices read readType cursor
        let some type := fact.value.type | throw (.unexpectedEnd "suffices type")
        pure (.suffices fact.value.name type fact.value.value fact.value.span, fact.cursor)
      | .classicalE => do
        let body ← if psTokenCursorAtText head.cursor "{" then
            psPscv0ReadTacticsFor nativeLayout read readType fuel boundary head.cursor true closing
          else do
            let some first := psTokenCursorPeek head.cursor
              | throw (psProofScriptExpectedError "classical tactic body" head.cursor)
            if boundary.any (fun position =>
                first.span.start.line > position.line &&
                first.span.start.column <= position.column) then
              throw (psProofScriptExpectedError "classical tactic body" head.cursor)
            -- Native sepBy1Indent fixes this scope at the first body tactic.
            -- A printed or source-written dedent resumes the outer sequence.
            let position := { first.span.start with column := first.span.start.column - 1 }
            psPscv0ReadTacticsFor nativeLayout read readType fuel (some position) head.cursor false closing
        if body.value.isEmpty then throw (psProofScriptExpectedError "classical tactic body" head.cursor)
        pure (.classicalE body.value token.span, body.cursor)
      | .bracedGroup => do
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel none head.cursor false "}"
        let close ← psTokenCursorExpectText body.cursor "}"
        pure (.focus body.value true (psSyntaxSpanJoin token.span close.token.span), close.cursor)
      | .group =>
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel none head.cursor false ")"
        if body.value.isEmpty then throw (psProofScriptExpectedError "parenthesized tactic" head.cursor)
        let close ← psTokenCursorExpectText body.cursor ")"
        pure (.focus body.value false (psSyntaxSpanJoin token.span close.token.span), close.cursor)
      | .assumption => pure (.assumption token.span, head.cursor)
      | .reflexivity => pure (.reflexivity token.span, head.cursor)
      | .constructor => pure (.constructor token.span, head.cursor)
      | .constructorFirst => pure (.constructorFirst token.span, head.cursor)
      | .focus bullet =>
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel (some token.span.start) head.cursor false closing
        if body.value.isEmpty then throw (psProofScriptExpectedError "focused tactic" head.cursor)
        pure (.focus body.value bullet token.span, body.cursor)
      | .each anyGoal =>
        let body ← psPscv0ReadTacticsFor nativeLayout read readType fuel (some token.span.start) head.cursor false closing
        if body.value.isEmpty then throw (psProofScriptExpectedError "focused tactic" head.cursor)
        pure (.each body.value anyGoal token.span, body.cursor)
    if single then return { value := [tactic], cursor := next }
    let chain ← psPscv0ReadAndThen
      (fun current => psPscv0ReadTacticsFor nativeLayout read readType fuel boundary current true closing)
      fuel token.span tactic next
    let tactic := chain.value
    let next := chain.cursor
    let consumed := cursor.remaining.take (cursor.remaining.length - next.remaining.length)
    let stop := (consumed.getLast?).map (·.span.stop) |>.getD token.span.stop
    let semicolon := nativeLayout && psTokenCursorAtText next ";"
    let next ← if semicolon then
      pure (← psTokenCursorExpectText next ";").cursor else pure next
    let termBoundary := nativeLayout && [")", "]", ","].any (psTokenCursorAtText next)
    if !psTokenCursorDone next && !psTokenCursorAtText next closing &&
        !psTokenCursorAtText next "}" && !termBoundary &&
        !psProofScriptLaterLine stop next && !semicolon then
      throw (psProofScriptExpectedError "newline-separated tactic" next)
    let rest ← psPscv0ReadTacticsFor nativeLayout read readType fuel boundary next false closing
    return { value := tactic :: rest.value, cursor := rest.cursor }

def psPscv0ReadTactics (read readType : PsPscv0TermReader) (fuel : Nat)
    (boundary : Option PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxTactic)) :=
  psPscv0ReadTacticsFor false read readType fuel boundary cursor false "}"

def psPscv0ReadProof (read readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "by"
  let opening ← psTokenCursorExpectText keyword.cursor "{"
  let tactics ← psPscv0ReadTactics read readType fuel none opening.cursor
  let close ← psTokenCursorExpectText tactics.cursor "}"
  return {
    value := .byE tactics.value {} (psSyntaxSpanJoin keyword.token.span close.token.span)
    cursor := close.cursor }
