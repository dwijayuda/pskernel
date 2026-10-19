import Ps.Syntax.ParseProofScript

abbrev PsPscv0TermReader :=
  PsTokenCursor → Except PsParseError (PsParseResult PsSyntaxTerm)

def psPscv0ReservedArgument (text : String) : Bool :=
  psProofScriptReservedArgument text ||
    -- Total suffixes are already reserved by the shared reader. Keep the P1
    -- suffix out of ordinary application arguments as well, regardless of
    -- its line or indentation, so the declaration reader retains ownership.
    ["partial_fixpoint", "by", "have", "show", "suffices", "exists", "∃", "from", "return", "do", "←", "<-", "at"].contains text

-- All binder contexts use the caller's v7 annotation reader. Grammar policy
-- stays here: declarations own comma groups/defaults; terms own native binders.
def psPscv0BinderNames (fuel : Nat) (cursor : PsTokenCursor)
    (accRev : List PsSyntaxName) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psTokenCursorPeek cursor with
    | some token =>
      if psTokenKindEq token.kind .identifier && !psPscv0ReservedArgument token.text then
        let name ← psTokenCursorExpectKind cursor .identifier
        psPscv0BinderNames fuel name.cursor
          ((psSyntaxNameFromToken name.token) :: accRev)
      else return { value := accRev.reverse, cursor }
    | none => return { value := accRev.reverse, cursor }

def psPscv0BinderEntry (readType readValue : PsPscv0TermReader) (fuel : Nat)
    (kind : PsSyntaxBinderKind) (requireType defaults multiName : Bool)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (Prod PsSyntaxBinderHead PsSyntaxTerm)) := do
  let name ← psTokenCursorExpectKind cursor .identifier
  let names ← if multiName then
      psPscv0BinderNames fuel name.cursor []
    else pure (PsParseResult.mk [] name.cursor)
  let type ←
    if psTokenCursorAtText names.cursor ":" then do
      let colon ← psTokenCursorExpectText names.cursor ":"
      readType colon.cursor
    else if requireType then throw (psProofScriptExpectedError "typed binder" names.cursor)
    else pure (PsParseResult.mk (.hole name.token.span) names.cursor)
  let annotation ←
    if psTokenCursorAtText type.cursor ":=" then do
      if !defaults then throw (psProofScriptExpectedError "binder without default" type.cursor)
      match kind with
      | .explicit => pure ()
      | _ => throw (psProofScriptExpectedError "default on explicit parameter" type.cursor)
      let assign ← psTokenCursorExpectText type.cursor ":="
      let value ← readValue assign.cursor
      pure (PsParseResult.mk
        (.optionalType type.value value.value
          (psSyntaxSpanJoin (psSyntaxTermSpan type.value) (psSyntaxTermSpan value.value)))
        value.cursor)
    else pure type
  let head := PsSyntaxBinderHead.group
    ((psSyntaxNameFromToken name.token)) kind
    (psSyntaxSpanJoin name.token.span (psSyntaxTermSpan annotation.value)) names.value none
  return { value := (head, annotation.value), cursor := annotation.cursor }

def psPscv0BinderEntries (readType readValue : PsPscv0TermReader)
    (fuel : Nat) (opening : PsSyntaxBinderOpening)
    (commaGroup requireType defaults : Bool) (cursor : PsTokenCursor)
    (acc : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let entry ← psPscv0BinderEntry readType readValue (fuel + 1) opening.kind requireType defaults
      (!commaGroup && match opening.kind with | .instanceImplicit => false | _ => true) cursor
    let acc := entry.value :: acc
    if commaGroup && psTokenCursorAtText entry.cursor "," then
      let comma ← psTokenCursorExpectText entry.cursor ","
      if psTokenCursorAtText comma.cursor ")" then
        let close ← psParseBinderClosing opening comma.cursor
        return { value := acc.reverse, cursor := close.cursor }
      psPscv0BinderEntries readType readValue fuel opening commaGroup requireType defaults comma.cursor acc
    else
      let close ← psParseBinderClosing opening entry.cursor
      let entries := acc.reverse
      let entries := match entries with
        | [(head, type)] => [({ head with span := close.value }, type)]
        | _ => entries
      return { value := entries, cursor := close.cursor }

def psPscv0BinderGroup (readType readValue : PsPscv0TermReader)
    (fuel : Nat) (opening : PsSyntaxBinderOpening)
    (commaGroup requireType defaults : Bool) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match opening.kind with
  | .instanceImplicit =>
    let named := match psTokenCursorAdvance opening.cursor with
      | some first => psTokenKindEq first.token.kind .identifier &&
          psTokenCursorAtText first.cursor ":"
      | none => false
    if !named then
      let type ← readType opening.cursor
      let close ← psParseBinderClosing opening type.cursor
      -- '$' is not a source identifier character. Every anonymous binder gets
      -- a distinct local identity and is found only through instance search.
      let name := PsSyntaxName.mk
        ["$psc0Inst" ++ psNatToString opening.start.byteOffset] close.value
      return { value := [(PsSyntaxBinderHead.mk name .instanceImplicit close.value, type.value)]
               cursor := close.cursor }
  | _ => pure ()
  psPscv0BinderEntries readType readValue fuel opening commaGroup requireType defaults opening.cursor []

def psPscv0ParameterGroups (readType readValue : PsPscv0TermReader)
    (fuel : Nat) (declaration nullary previousExplicit : Bool)
    (cursor : PsTokenCursor) (accRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psTokenCursorAtBinderStart cursor then return { value := accRev.reverse, cursor }
    let opening ← psParseBinderOpening cursor
    let explicit := match opening.kind with | .explicit => true | _ => false
    if declaration && previousExplicit && explicit then
      throw (psProofScriptExpectedError "PSCV0-BIND-02: one explicit comma group" cursor)
    if explicit && psTokenCursorAtText opening.cursor ")" then
      if !nullary then throw (psProofScriptExpectedError "nonempty binder group" opening.cursor)
      let close ← psParseBinderClosing opening opening.cursor
      if psTokenCursorAtBinderStart close.cursor then
        throw (psProofScriptExpectedError "final nullary function group" close.cursor)
      let name := PsSyntaxName.mk ["_"] close.value
      let head := PsSyntaxBinderHead.mk name .explicit close.value
      let type := PsSyntaxTerm.reference (PsSyntaxName.mk ["_root_", "Unit"] close.value)
      return { value := accRev.reverse ++ [(head, type)], cursor := close.cursor }
    let group ← psPscv0BinderGroup readType readValue (fuel + 1) opening
      (declaration && explicit) true true
    psPscv0ParameterGroups readType readValue fuel declaration nullary explicit
      group.cursor (group.value.reverse ++ accRev)

def psPscv0AtLambdaArrow (cursor : PsTokenCursor) : Bool :=
  psTokenCursorAtText cursor "=>" || psTokenCursorAtText cursor "↦"

-- Native term binders never acquire declaration commas or a hidden Unit.
-- A native group retains its names together; shared elaboration visits each
-- annotation at its ordered prefix. Instances keep their one-name grammar.
def psPscv0TermBinders (read : PsPscv0TermReader) (quantified : Bool)
    (fuel : Nat) (cursor : PsTokenCursor)
    (acc : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let done := if quantified then psTokenCursorAtText cursor "," else psPscv0AtLambdaArrow cursor
    if done then
      if acc.isEmpty then throw (psProofScriptExpectedError "nonempty term binders" cursor)
      return { value := acc.reverse, cursor }
    if psTokenCursorAtBinderStart cursor then
      let opening ← psParseBinderOpening cursor
      let group ← psPscv0BinderGroup read read (fuel + 1) opening false false false
      psPscv0TermBinders read quantified fuel group.cursor (group.value.reverse ++ acc)
    else
      let entry ←
        if quantified then psPscv0BinderEntry read read (fuel + 1) .explicit false false true cursor
        else do
          let name ← psTokenCursorExpectKind cursor .identifier
          let head := PsSyntaxBinderHead.mk
            ((psSyntaxNameFromToken name.token)) .explicit name.token.span
          pure (PsParseResult.mk (head, PsSyntaxTerm.hole name.token.span) name.cursor)
      if quantified && !psTokenCursorAtText entry.cursor "," then
        throw (psProofScriptExpectedError "comma after quantified binder group" entry.cursor)
      psPscv0TermBinders read quantified fuel entry.cursor (entry.value :: acc)

def psPscv0BoundTerm (readType readBody : PsPscv0TermReader)
    (quantified : Bool) (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "binder keyword")
  let binders ← psPscv0TermBinders readType quantified fuel keyword.cursor []
  let delimiter ←
    if quantified then psTokenCursorExpectText binders.cursor ","
    else if psPscv0AtLambdaArrow binders.cursor then
      match psTokenCursorAdvance binders.cursor with
      | some arrow => pure arrow
      | none => throw (.unexpectedEnd "lambda arrow")
    else throw (psProofScriptExpectedError "lambda arrow" binders.cursor)
  let body ← readBody delimiter.cursor
  let span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan body.value)
  return { value := if quantified then .forallE binders.value body.value span
                   else .lambda binders.value body.value span
           cursor := body.cursor }

def psPscv0DependentBinder (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (Prod PsSyntaxBinderHead PsSyntaxTerm)) := do
  let opening ← psParseBinderOpening cursor
  let group ← psPscv0BinderGroup read read fuel opening false true false
  match group.value with
  | [binder] => return { value := binder, cursor := group.cursor }
  | _ => throw (psProofScriptExpectedError "one dependent binder" cursor)

