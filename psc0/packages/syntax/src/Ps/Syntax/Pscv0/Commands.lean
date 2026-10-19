import Ps.Syntax.Pscv0.Read
import Ps.Syntax.Pscv0.Data

-- The header owns whether its result annotation exists. Lean's omitted
-- result is not an explicit `_`; retain that distinction through printing.
def psPscv0ReadDeclarationResult (required : Bool) (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxTerm) := do
  if !required && psTokenCursorAtText cursor ":=" then
    let some token := psTokenCursorPeek cursor | throw "PSCV0-DECLARATION-MISSING"
    let span := PsSourceSpan.mk token.span.start token.span.start
    return PsParseResult.mk (.omittedType span) cursor
  let colon ← psPscv0Expect cursor ":"
  psPscv0ReadAnnotation true colon.cursor

-- The annotation parser owns nested terms; the declaration consumes only its
-- own assignment token. No scan to the first top-level := is involved.
def psPscv0ReadValueDeclarationBody (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorAdvance cursor with
  | none => Except.error "PSCV0-DECLARATION-MISSING"
  | some keyword =>
      match psParseProofScriptDeclaredName keyword.cursor with
      | Except.error error => Except.error (psPscv0ParseError error)
      | Except.ok name =>
          let bindersResult : Except PsParseError
              (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
            if psStringEq keyword.token.text "const" then
              Except.ok (PsParseResult.mk [] name.cursor)
            else psPscv0ParameterGroups (psPscv0ParseTerm true) (psPscv0ParseTerm false)
              (Nat.succ (psParseListLength name.cursor.remaining)) true
              (psStringEq keyword.token.text "function") false name.cursor [];
          match bindersResult with
          | Except.error error => Except.error (psPscv0ParseError error)
          | Except.ok binders =>
              let signatureValid :=
                if psStringEq keyword.token.text "function" then
                  psProofScriptBindersHaveExplicit binders.value
                else true;
              if signatureValid then
                -- Omission is selected here for the shared value owner. The
                -- inferred abbrev uses its checked registration finalizer;
                -- v7.2 requires an explicit result annotation for opaque.
                match psPscv0ReadDeclarationResult
                    (!["def", "function", "const", "abbrev"].contains keyword.token.text)
                    binders.cursor with
                | Except.error error => Except.error error
                | Except.ok resultType =>
                    match psPscv0Expect resultType.cursor ":=" with
                    | Except.error error => Except.error error
                    | Except.ok assign =>
                        match psPscv0ParseDefinitionBody assign.cursor with
                        | Except.error error => Except.error (psPscv0ParseError error)
                        | Except.ok body =>
                            let span := PsSourceSpan.mk keyword.token.span.start
                              (psProofScriptTermStop body.value);
                            let declaration : PsSyntaxDeclaration :=
                              if psStringEq keyword.token.text "theorem" then
                                PsSyntaxDeclaration.theoremDecl name.value binders.value
                                  resultType.value body.value span
                              else PsSyntaxDeclaration.definition name.value binders.value
                                resultType.value body.value span;
                            Except.ok (PsParseResult.mk declaration body.cursor)
              else Except.error "PSCV0-NULLARY-DECLARATION-NOT-YET-SUPPORTED"

-- v7.2 selects measure-first termination and owns the decreasing_by by {...}
-- transformation. Retain the complete byE (including its scope and span), so
-- the elaborator can run one tactic sequence over its ordered call goals.
def psPscv0ReadTermination (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxTermination) := do
  let keyword ← psPscv0Expect cursor "termination_by"
  if psTokenCursorAtText keyword.cursor "structural" then
    throw "PSCV0-TERM-01: termination_by structural is not selected; provide a measure"
  if psTokenCursorAtText keyword.cursor "partial_fixpoint" then
    throw "PSCV0-REC-STRATEGY-01: total and fixedpoint suffixes cannot combine"
  let measure ← (psPscv0ParseTerm false keyword.cursor).mapError psPscv0ParseError
  let (decreasing, next, stop) ←
    if psTokenCursorAtText measure.cursor "decreasing_by" then do
      let decrease ← psPscv0Expect measure.cursor "decreasing_by"
      if !psTokenCursorAtText decrease.cursor "by" then
        throw "PSCV0-TERM-01: decreasing_by requires by { tactics }"
      let byKeyword ← psPscv0Expect decrease.cursor "by"
      if !psTokenCursorAtText byKeyword.cursor "{" then
        throw "PSCV0-TERM-01: decreasing_by requires by { tactics }"
      let proof ← (psPscv0ParseTerm false decrease.cursor).mapError psPscv0ParseError
      let .byE _ _ span := proof.value
        | throw "PSCV0-TERM-01: decreasing_by requires a proof sequence"
      pure (some proof.value, proof.cursor, span.stop)
    else pure (none, measure.cursor, psProofScriptTermStop measure.value)
  if ["termination_by", "decreasing_by", "partial_fixpoint"].any
      (psTokenCursorAtText next) then
    throw "PSCV0-REC-STRATEGY-01: duplicate or incompatible recursion suffix"
  let span := PsSourceSpan.mk keyword.token.span.start stop
  let termination := PsSyntaxTermination.mk measure.value decreasing span
  return PsParseResult.mk termination next

-- Lean 4.35 Parser.Termination.suffix and elabTerminationHints retain the
-- strategy after the body. The source parser owns that syntax; elaboration
-- owns the construction's dependency/assumption gate. In particular, never
-- reinterpret a valid P1 suffix as the head of the following declaration.
def psPscv0ReadValueDeclarationWithoutWhere (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  let parsed ← psPscv0ReadValueDeclarationBody cursor
  if psTokenCursorAtText parsed.cursor "decreasing_by" then
    throw "PSCV0-TERM-01: decreasing_by requires a preceding termination_by measure"
  if psTokenCursorAtText parsed.cursor "termination_by" then do
    let some head := psTokenCursorPeek cursor | throw "PSCV0-DECLARATION-MISSING"
    if !["def", "function", "const", "abbrev", "opaque"].contains head.text then
      throw "PSCV0-REC-STRATEGY-01: total recursion suffix requires a selected total value declaration"
    let termination ← psPscv0ReadTermination parsed.cursor
    let .definition name binders type value span := parsed.value
      | throw "PSCV0-REC-STRATEGY-01: total suffix requires a value declaration"
    let sourceSpan := PsSourceSpan.mk span.start termination.value.span.stop
    let declaration := PsSyntaxDeclaration.wellFoundedDefinition
      name binders type value termination.value sourceSpan
    return PsParseResult.mk declaration termination.cursor
  if !psTokenCursorAtText parsed.cursor "partial_fixpoint" then return parsed
  let some head := psTokenCursorPeek cursor | throw "PSCV0-DECLARATION-MISSING"
  if !["def", "function"].contains head.text then
    throw "PSCV0-REC-STRATEGY-01: partial_fixpoint requires an ordinary def or function"
  let suffix ← psPscv0Expect parsed.cursor "partial_fixpoint"
  if ["partial_fixpoint", "termination_by", "decreasing_by"].any
      (psTokenCursorAtText suffix.cursor) then
    throw "PSCV0-REC-STRATEGY-01: fixedpoint cannot combine with another recursion suffix"
  if psTokenCursorAtText suffix.cursor "monotonicity" then
    throw "PSCV0-FIXPOINT-01: explicit monotonicity syntax is not selected by v7.2"
  let .definition name binders type value span := parsed.value
    | throw "PSCV0-REC-STRATEGY-01: fixedpoint requires a function-like declaration"
  let sourceSpan := PsSourceSpan.mk span.start suffix.token.span.stop
  let declaration := PsSyntaxDeclaration.fixedpointDefinition
    name binders type value sourceSpan
  return PsParseResult.mk declaration suffix.cursor

def psPscv0ReadLocalDefinition (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxLocalDefinition) := do
  if !psTokenCursorAtText cursor "def" then
    throw "PSCV0-D-WHERE-01: where admits only selected local def declarations"
  let keyword ← psPscv0Expect cursor "def"
  let name ← (psParseProofScriptDeclaredName keyword.cursor).mapError psPscv0ParseError
  if name.value.segments.length != 1 then
    throw "PSCV0-D-WHERE-01: local definition requires one unqualified identifier"
  let binders ← (psPscv0ParameterGroups (psPscv0ParseTerm true) (psPscv0ParseTerm false)
    (name.cursor.remaining.length + 1) true false false name.cursor []).mapError psPscv0ParseError
  let (type, next) ← if psTokenCursorAtText binders.cursor ":" then do
      let colon ← psPscv0Expect binders.cursor ":"
      let type ← psPscv0ReadAnnotation true colon.cursor
      pure (some type.value, type.cursor)
    else pure (none, binders.cursor)
  let assign ← psPscv0Expect next ":="
  let body ← (psPscv0ParseDefinitionBody assign.cursor).mapError psPscv0ParseError
  let (recursion, next, stop) ←
    if psTokenCursorAtText body.cursor "termination_by" then do
      let suffix ← psPscv0ReadTermination body.cursor
      pure (some (PsSyntaxLocalRecursion.total suffix.value), suffix.cursor, suffix.value.span.stop)
    else if psTokenCursorAtText body.cursor "partial_fixpoint" then do
      let suffix ← psPscv0Expect body.cursor "partial_fixpoint"
      pure (some (PsSyntaxLocalRecursion.fixedpoint suffix.token.span), suffix.cursor, suffix.token.span.stop)
    else pure (none, body.cursor, psProofScriptTermStop body.value)
  if ["termination_by", "decreasing_by", "partial_fixpoint"].any (psTokenCursorAtText next) then
    throw "PSCV0-REC-STRATEGY-01: duplicate or incompatible local recursion suffix"
  if psTokenCursorAtText next "monotonicity" then
    throw "PSCV0-FIXPOINT-01: explicit monotonicity syntax is not selected by v7.2"
  if psTokenCursorAtText next "where" then
    throw "PSCV0-D-WHERE-01: nested local where declarations are not selected"
  let localDefinition : PsSyntaxLocalDefinition := {
    name := name.value
    binders := binders.value
    type
    value := body.value
    recursion
    span := PsSourceSpan.mk keyword.token.span.start stop }
  return PsParseResult.mk localDefinition next

def psPscv0ReadLocalDefinitions (fuel : Nat) (cursor : PsTokenCursor)
    (localsRev : List PsSyntaxLocalDefinition) :
    Except String (PsParseResult (List PsSyntaxLocalDefinition)) := do
  match fuel with
  | 0 => throw "PSCV0-D-WHERE-01: local declaration budget exhausted"
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then
      if localsRev.isEmpty then throw "PSCV0-D-WHERE-01: where requires a local definition"
      return PsParseResult.mk localsRev.reverse cursor
    let localDefinition ← psPscv0ReadLocalDefinition cursor
    if localsRev.any (fun previous => previous.name.segments == localDefinition.value.name.segments) then
      throw "PSCV0-D-WHERE-01: duplicate local definition"
    let next ← if psTokenCursorAtText localDefinition.cursor "}" then pure localDefinition.cursor
      else (psParseProofScriptCommandSeparator localDefinition.value.span.stop
        localDefinition.cursor).mapError psPscv0ParseError
    psPscv0ReadLocalDefinitions fuel next (localDefinition.value :: localsRev)

def psPscv0ReadWhereSuffix (parsed : PsParseResult PsSyntaxDeclaration) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  if !psTokenCursorAtText parsed.cursor "where" then return parsed
  let keyword ← psPscv0Expect parsed.cursor "where"
  let opening ← psPscv0Expect keyword.cursor "{"
  let locals ← psPscv0ReadLocalDefinitions (opening.cursor.remaining.length + 1) opening.cursor []
  let closing ← psPscv0Expect locals.cursor "}"
  if ["termination_by", "decreasing_by", "partial_fixpoint", "where"].any
      (psTokenCursorAtText closing.cursor) then
    throw "PSCV0-REC-STRATEGY-01: recursion suffix belongs before where"
  let whereSpan := PsSourceSpan.mk keyword.token.span.start closing.token.span.stop
  return PsParseResult.mk (.whereDeclaration parsed.value locals.value whereSpan) closing.cursor

def psPscv0ReadValueDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  psPscv0ReadWhereSuffix (← psPscv0ReadValueDeclarationWithoutWhere cursor)

def psPscv0ReadSelectedDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  (psPscv0ReadDataDeclaration cursor).mapError psPscv0ParseError

-- v7.2 head ownership is separate from execution admission. The body stays in
-- partialDefinition; it is never relabeled as a total logical definition.
-- Lean 4.35.0 Command.declModifiers and PreDefinition.addAndCompilePartial
-- separate these same syntactic/semantic responsibilities. PSCV0's selected
-- modifier matrix is deliberately narrower than unrestricted native Lean.
def psPscv0ReadSpecialDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  let some marker := psTokenCursorAdvance cursor | throw "PSCV0-DECLARATION-MISSING"
  let some head := psTokenCursorPeek marker.cursor | throw "PSCV0-REC-STRATEGY-01: missing declaration head"
  if ["partial", "unsafe", "noncomputable"].contains head.text then
    throw "PSCV0-REC-STRATEGY-01: duplicate or combined special modifiers"
  if !["def", "function"].contains head.text then
    throw "PSCV0-TERM-02-HEAD: special modifier requires def or function"
  if !["partial", "noncomputable"].contains marker.token.text then
    throw ("PSCV0-FEATURE-UNAVAILABLE: " ++ marker.token.text ++ " requires selected semantic admission")
  let parsed ← psPscv0ReadValueDeclarationBody marker.cursor
  let .definition name binders type value span := parsed.value
    | throw "PSCV0-TERM-02-HEAD: expected function-like declaration"
  if ["partial_fixpoint", "termination_by", "decreasing_by"].any
      (psTokenCursorAtText parsed.cursor) then
    throw ("PSCV0-REC-STRATEGY-01: " ++ marker.token.text ++
      " modifier cannot own a total or fixedpoint suffix")
  let sourceSpan := PsSourceSpan.mk marker.token.span.start span.stop
  let declaration := if marker.token.text == "noncomputable" then
    PsSyntaxDeclaration.noncomputableDefinition name binders type value sourceSpan
  else PsSyntaxDeclaration.partialDefinition name binders type value sourceSpan
  psPscv0ReadWhereSuffix { parsed with value := declaration }

def psPscv0ReadDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  if ["partial", "unsafe", "noncomputable"].any (psTokenCursorAtText cursor) then
    psPscv0ReadSpecialDeclaration cursor
  else if psTokenCursorAtText cursor "partial_fixpoint" then
    Except.error "PSCV0-FIXPOINT-01: partial_fixpoint is a post-body suffix, not a declaration head"
  else if psTokenCursorAtText cursor "axiom" then Except.error "PSCV0-SOURCE-AXIOM-EXCLUDED"
  else if psTokenCursorAtText cursor "verify" then Except.error "PSCV0-VERIFY-REMOVED"
  else if psTokenCursorAtText cursor "ghost" then Except.error "PSCV0-GHOST-REMOVED"
  else if psTokenCursorAtText cursor "def" then psPscv0ReadValueDeclaration cursor
  else if psTokenCursorAtText cursor "const" then psPscv0ReadValueDeclaration cursor
  else if psTokenCursorAtText cursor "function" then psPscv0ReadValueDeclaration cursor
  else if psTokenCursorAtText cursor "structure" then psPscv0ReadSelectedDeclaration cursor
  else if psTokenCursorAtText cursor "inductive" then psPscv0ReadSelectedDeclaration cursor
  else if psTokenCursorAtText cursor "theorem" then psPscv0ReadValueDeclaration cursor
  else Except.error "PSCV0-COMMAND-NOT-YET-SUPPORTED"

def psPscv0ReadDeclarations (fuel : Nat) (cursor : PsTokenCursor)
    (declarationsRev : List PsSyntaxDeclaration) : Except String (List PsSyntaxDeclaration) :=
  match fuel with
  | 0 => Except.error "PSCV0-DECLARATION-COUNT-BUDGET"
  | remaining + 1 =>
      if psTokenCursorDone cursor then Except.ok (psListReverse declarationsRev)
      else
        match psPscv0ReadDeclaration cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            match psParseProofScriptCommandSeparator (psProofScriptDeclarationStop parsed.value) parsed.cursor with
            | Except.error error => Except.error (psPscv0ParseError error)
            | Except.ok next =>
                psPscv0ReadDeclarations remaining next (List.cons parsed.value declarationsRev)

def psPscv0ParseTokens (tokens : List PsToken) : Except String PsSyntaxModule :=
  match psParseProofScriptImportsWithFuel (psParseListLength tokens)
      (psTokenCursorFromTokens tokens) [] with
  | Except.error error => Except.error (psPscv0ParseError error)
  | Except.ok imports =>
      match psPscv0ReadDeclarations 4096 imports.cursor [] with
      | Except.error error => Except.error error
      | Except.ok declarations => Except.ok (PsSyntaxModule.mk imports.value declarations)

