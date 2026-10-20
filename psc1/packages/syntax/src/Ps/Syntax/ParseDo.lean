import Ps.Syntax.ParseCommon
import Ps.Syntax.ParseBinding

-- Both surfaces build the same procedural AST. Layout and delimiters are
-- frontend concerns; lexical mutation and return are elaborated into checked Core.
def psParseDoTermStop (value : PsSyntaxTerm) : PsSourcePos :=
  let span := psSyntaxTermSpan value;
  span.stop

def psParseDoExpected (expected : String) (cursor : PsTokenCursor) : PsParseError :=
  match psTokenCursorPeek cursor with
  | Option.none => PsParseError.unexpectedEnd expected
  | Option.some token => PsParseError.expectedText expected token.text token.span

def psParseDoOpenToken (text : String) : Bool :=
  if psStringEq text "(" then true
  else if psStringEq text "[" then true
  else psStringEq text "{"

def psParseDoCloseToken (text : String) : Bool :=
  if psStringEq text ")" then true
  else if psStringEq text "]" then true
  else psStringEq text "}"

def psParseDoArrow (cursor : PsTokenCursor) : Bool :=
  if psTokenCursorAtText cursor "<-" then true
  else psTokenCursorAtText cursor "←"

-- Track unbracketed term conditionals so the else of an enclosing procedural
-- branch closes the statement, while an else in its RHS remains part of the term.
def psParseDoTakeStatement
    (fuel : Nat) (start : PsSourcePos) :
    Nat -> Nat -> Nat -> PsTokenCursor -> List PsToken ->
    PsParseResult (List PsToken) :=
  match fuel with
  | Nat.zero =>
      fun (_depth _conditionals _handlers : Nat) (cursor : PsTokenCursor)
          (tokensRev : List PsToken) =>
        PsParseResult.mk (psParseListReverse tokensRev) cursor
  | Nat.succ remaining =>
      fun (depth conditionals handlers : Nat) (cursor : PsTokenCursor)
          (tokensRev : List PsToken) =>
        let smaller := psParseDoTakeStatement remaining start;
        match psTokenCursorPeek cursor with
        | Option.none => PsParseResult.mk (psParseListReverse tokensRev) cursor
        | Option.some token =>
            let stop :=
              if psTokenKindEq token.kind PsTokenKind.endOfInput then true
              else if Nat.beq depth 0 then
                if psParseDoCloseToken token.text then true
                else if psStringEq token.text ";" then true
                else if psStringEq token.text "catch" then Nat.beq handlers 0
                else if psStringEq token.text "else" then Nat.beq conditionals 0
                else if Nat.ble (Nat.succ start.line) token.span.start.line then
                  -- Match alternatives may align with their match expression.
                  if psStringEq token.text "|" then
                    Nat.blt token.span.start.column start.column
                  else Nat.ble token.span.start.column start.column
                else false
              else false;
            if stop then PsParseResult.mk (psParseListReverse tokensRev) cursor
            else
              match psTokenCursorAdvance cursor with
              | Option.none => PsParseResult.mk (psParseListReverse tokensRev) cursor
              | Option.some read =>
                  let nextDepth :=
                    if psParseDoOpenToken token.text then Nat.succ depth
                    else if psParseDoCloseToken token.text then Nat.sub depth 1
                    else depth;
                  let nextConditionals :=
                    if Nat.beq depth 0 then
                      if psStringEq token.text "if" then Nat.succ conditionals
                      else if psStringEq token.text "else" then Nat.sub conditionals 1
                      else conditionals
                    else conditionals;
                  let nextHandlers :=
                    if Nat.beq depth 0 then
                      if psStringEq token.text "try" then Nat.succ handlers
                      else if psStringEq token.text "catch" then Nat.sub handlers 1
                      else handlers
                    else handlers;
                  smaller nextDepth nextConditionals nextHandlers read.cursor (List.cons token tokensRev)

inductive PsParseDoHead where
  | binding
      (name : PsSyntaxName) (annotation : Option PsSyntaxTerm)
      (value : PsSyntaxTerm) (monadic mutable : Bool) (span : PsSourceSpan)
  | patternBinding
      (pattern : PsSyntaxBindingPattern) (annotation : Option PsSyntaxTerm)
      (value : PsSyntaxTerm) (span : PsSourceSpan)
  | assignment (name : PsSyntaxName) (value : PsSyntaxTerm) (span : PsSourceSpan)
  | conditional (condition thenBody elseBody : PsSyntaxTerm) (span : PsSourceSpan)
  | forEach (name : PsSyntaxName) (collection body : PsSyntaxTerm) (span : PsSourceSpan)
  | forRange (name : PsSyntaxName) (lower upper body : PsSyntaxTerm) (span : PsSourceSpan)
  | whileLoop (condition body : PsSyntaxTerm) (span : PsSourceSpan)
  | handler (body : PsSyntaxTerm) (name : PsSyntaxName)
      (recovery : PsSyntaxTerm) (span : PsSourceSpan)
  | action (value : PsSyntaxTerm)
  | nested (body : PsSyntaxTerm) (span : PsSourceSpan)
  | returnValue (value : PsSyntaxTerm) (span : PsSourceSpan)

def psParseDoCompleteTerm
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) : Except PsParseError PsSyntaxTerm :=
  match parseTerm cursor with
  | Except.error error => Except.error error
  | Except.ok value =>
      if psTokenCursorDone value.cursor then Except.ok value.value
      else Except.error (psParseDoExpected "end of do statement" value.cursor)

def psParseDoBindingValue
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (start : PsSourcePos) (name : PsSyntaxName) (mutable : Bool)
    (annotation : Option PsSyntaxTerm) (cursor : PsTokenCursor) :
    Except PsParseError PsParseDoHead :=
  let monadic := psParseDoArrow cursor;
  if if mutable then monadic else false then
    Except.error (psParseDoExpected ":= for a mutable local" cursor)
  else if if monadic then true else psTokenCursorAtText cursor ":=" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "do binding value")
    | Option.some separator =>
        match psParseDoCompleteTerm parseTerm separator.cursor with
        | Except.error error => Except.error error
        | Except.ok value =>
            Except.ok
              (PsParseDoHead.binding name annotation value monadic mutable
                { start := start, stop := (psParseDoTermStop value) })
  else Except.error (psParseDoExpected ":= or <-" cursor)

def psParseDoNamedBinding
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (start : PsSourcePos) (mutable : Bool) (cursor : PsTokenCursor) :
    Except PsParseError PsParseDoHead :=
  match psTokenCursorExpectKind cursor PsTokenKind.identifier with
  | Except.error error => Except.error error
  | Except.ok name =>
      let sourceName : PsSyntaxName := {
        segments := [name.token.text]
        span := name.token.span
      };
      if psTokenCursorAtText name.cursor ":" then
        match psTokenCursorAdvance name.cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "binding type")
        | Option.some colon =>
            match parseTerm colon.cursor with
            | Except.error error => Except.error error
            | Except.ok annotation =>
                psParseDoBindingValue parseTerm start sourceName mutable
                  (Option.some annotation.value) annotation.cursor
      else
        psParseDoBindingValue parseTerm start sourceName mutable Option.none name.cursor

def psParseDoPatternBinding
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (start : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError PsParseDoHead :=
  match psParseBindingPatternHeader parseTerm cursor with
  | Except.error error => Except.error error
  | Except.ok header =>
      match psTokenCursorExpectText header.cursor ":=" with
      | Except.error error => Except.error error
      | Except.ok assign =>
          match psParseDoCompleteTerm parseTerm assign.cursor with
          | Except.error error => Except.error error
          | Except.ok value =>
              Except.ok (PsParseDoHead.patternBinding header.pattern header.annotation value
                { start := start, stop := psParseDoTermStop value })

def psParseDoStatement
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) : Except PsParseError PsParseDoHead :=
  if psTokenCursorAtText cursor "throw" then
    match psTokenCursorAdvance cursor with
    | none => Except.error (PsParseError.unexpectedEnd "throw value")
    | some keyword =>
        match psParseDoCompleteTerm parseTerm keyword.cursor with
        | Except.error error => Except.error error
        | Except.ok value =>
            let span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan value);
            Except.ok (PsParseDoHead.action (PsSyntaxTerm.app (psSyntaxSyntheticReference "throw" keyword.token.span) [value] span))
  else if psTokenCursorAtText cursor "return" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "return value")
    | Option.some keyword =>
        match psParseDoCompleteTerm parseTerm keyword.cursor with
        | Except.error error => Except.error error
        | Except.ok value =>
            Except.ok (PsParseDoHead.returnValue value
              { start := keyword.token.span.start, stop := (psParseDoTermStop value) })
  else if psTokenCursorAtText cursor "do" then
    match psParseDoCompleteTerm parseTerm cursor with
    | Except.error error => Except.error error
    | Except.ok value =>
        match value with
        | PsSyntaxTerm.doE body span => Except.ok (PsParseDoHead.nested body span)
        | _ => Except.error (psParseDoExpected "nested do block" cursor)
  else if psTokenCursorAtText cursor "let" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "do binding")
    | Option.some keyword =>
        if psTokenCursorAtText keyword.cursor "mut" then
          match psTokenCursorAdvance keyword.cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd "mutable local name")
          | Option.some marker =>
              psParseDoNamedBinding parseTerm keyword.token.span.start true marker.cursor
        else if psTokenCursorAtText keyword.cursor "(" then
          psParseDoPatternBinding parseTerm keyword.token.span.start keyword.cursor
        else psParseDoNamedBinding parseTerm keyword.token.span.start false keyword.cursor
  else
    let action : Except PsParseError PsParseDoHead :=
      match psParseDoCompleteTerm parseTerm cursor with
      | Except.error error => Except.error error
      | Except.ok value => Except.ok (PsParseDoHead.action value);
    match psTokenCursorAdvance cursor with
    | Option.none => action
    | Option.some name =>
        if psTokenKindEq name.token.kind PsTokenKind.identifier then
          if psTokenCursorAtText name.cursor ":=" then
            match psTokenCursorAdvance name.cursor with
            | Option.none => Except.error (PsParseError.unexpectedEnd "assignment value")
            | Option.some separator =>
                match psParseDoCompleteTerm parseTerm separator.cursor with
                | Except.error error => Except.error error
                | Except.ok value =>
                    Except.ok (PsParseDoHead.assignment
                      (PsSyntaxName.mk [name.token.text] name.token.span) value
                      { start := name.token.span.start, stop := (psParseDoTermStop value) })
          else action
        else action

def psParseDoHeadSpan (head : PsParseDoHead) : PsSourceSpan :=
  match head with
  | PsParseDoHead.binding _ _ _ _ _ span => span
  | PsParseDoHead.patternBinding _ _ _ span => span
  | PsParseDoHead.assignment _ _ span => span
  | PsParseDoHead.conditional _ _ _ span => span
  | PsParseDoHead.forEach _ _ _ span => span
  | PsParseDoHead.forRange _ _ _ _ span => span
  | PsParseDoHead.whileLoop _ _ span => span
  | PsParseDoHead.returnValue _ span => span
  | PsParseDoHead.handler _ _ _ span => span
  | PsParseDoHead.action value => psSyntaxTermSpan value
  | PsParseDoHead.nested _ span => span

def psParseDoHeadStopLine (head : PsParseDoHead) : Nat :=
  let span := psParseDoHeadSpan head;
  span.stop.line

-- A branch followed by another statement has a Unit fallthrough path.
-- Explicit returns remain separate and do not execute the continuation.
def psParseDoFallthrough (body : PsSyntaxTerm) : PsSyntaxTerm :=
  match body with
  | PsSyntaxTerm.letE name type value rest span =>
      PsSyntaxTerm.letE name type value (psParseDoFallthrough rest) span
  | PsSyntaxTerm.letPatternE pattern type value rest span =>
      PsSyntaxTerm.letPatternE pattern type value (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doLetMutE name type value rest span =>
      PsSyntaxTerm.doLetMutE name type value (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doAssignE name value rest span =>
      PsSyntaxTerm.doAssignE name value (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doBindE name type value rest span =>
      PsSyntaxTerm.doBindE name type value (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doThenE action rest span => PsSyntaxTerm.doThenE action (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doIfE condition thenBody elseBody rest span =>
      match rest with
      | PsSyntaxTerm.doEndE _ =>
          PsSyntaxTerm.doIfE condition (psParseDoFallthrough thenBody)
            (psParseDoFallthrough elseBody) rest span
      | _ => PsSyntaxTerm.doIfE condition thenBody elseBody (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doForE name collection loopBody rest span =>
      PsSyntaxTerm.doForE name collection loopBody (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doForRangeE name lower upper loopBody rest span =>
      PsSyntaxTerm.doForRangeE name lower upper loopBody (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doWhileE condition loopBody rest span =>
      PsSyntaxTerm.doWhileE condition loopBody (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doTryE action name recovery rest span =>
      match rest with
      | PsSyntaxTerm.doEndE _ =>
          PsSyntaxTerm.doTryE (psParseDoFallthrough action) name
            (psParseDoFallthrough recovery) rest span
      | _ => PsSyntaxTerm.doTryE action name recovery (psParseDoFallthrough rest) span
  | PsSyntaxTerm.doReturnE _ _ => body
  | PsSyntaxTerm.doEndE _ => body
  | _ => PsSyntaxTerm.doThenE body (PsSyntaxTerm.doEndE (psSyntaxTermSpan body)) (psSyntaxTermSpan body)

-- Lean's direct do-element nests by splicing its statement sequence. A
-- parenthesized do term remains an ordinary action with its own return context.
def psParseDoAppend (fuel : Nat) (tail : PsSyntaxTerm) :
    PsSyntaxTerm -> Except PsParseError PsSyntaxTerm :=
  match fuel with
  | Nat.zero => fun (_body : PsSyntaxTerm) => Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (body : PsSyntaxTerm) =>
        let smaller := psParseDoAppend remaining tail;
        let rebuild :
            PsSyntaxTerm -> (PsSyntaxTerm -> PsSyntaxTerm) ->
            Except PsParseError PsSyntaxTerm :=
          fun (rest : PsSyntaxTerm) (make : PsSyntaxTerm -> PsSyntaxTerm) =>
            match smaller rest with
            | Except.error error => Except.error error
            | Except.ok appended => Except.ok (make appended);
        match body with
        | PsSyntaxTerm.letE name type value rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.letE name type value appended
              (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.letPatternE pattern type value rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.letPatternE pattern type value appended
              (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doLetMutE name type value rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.doLetMutE name type value appended
              (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doAssignE name value rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.doAssignE name value appended
              (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doBindE name type value rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.doBindE name type value appended
              (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doThenE action rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.doThenE action appended
              (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doIfE condition thenBody elseBody rest span =>
            match rest with
            | PsSyntaxTerm.doEndE _ =>
                Except.ok (PsSyntaxTerm.doIfE condition
                  (psParseDoFallthrough thenBody)
                  (psParseDoFallthrough elseBody) tail
                  (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
            | _ =>
                rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.doIfE condition thenBody elseBody appended
                  (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doForE name collection loopBody rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) =>
              PsSyntaxTerm.doForE name collection loopBody appended
                (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doForRangeE name lower upper loopBody rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) =>
              PsSyntaxTerm.doForRangeE name lower upper loopBody appended
                (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doWhileE condition loopBody rest span =>
            rebuild rest (fun (appended : PsSyntaxTerm) =>
              PsSyntaxTerm.doWhileE condition loopBody appended
                (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doTryE action name recovery rest span =>
            match rest with
            | PsSyntaxTerm.doEndE _ =>
                Except.ok (PsSyntaxTerm.doTryE (psParseDoFallthrough action) name
                  (psParseDoFallthrough recovery) tail
                  (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
            | _ =>
                rebuild rest (fun (appended : PsSyntaxTerm) => PsSyntaxTerm.doTryE action name recovery appended
                  (psSyntaxSpanJoin span (psSyntaxTermSpan tail)))
        | PsSyntaxTerm.doReturnE _ _ =>
            Except.error (PsParseError.expectedText
              "terminal return in this statement sequence" "following statement"
              (psSyntaxTermSpan tail))
        | PsSyntaxTerm.doEndE _ => Except.ok tail
        | _ => Except.ok (PsSyntaxTerm.doThenE body tail
            (psSyntaxSpanJoin (psSyntaxTermSpan body) (psSyntaxTermSpan tail)))

def psParseDoCloseHead
    (head : PsParseDoHead) (tail : Option PsSyntaxTerm) :
    Except PsParseError PsSyntaxTerm :=
  let span := psParseDoHeadSpan head;
  let rest : PsSyntaxTerm :=
    match tail with
    | Option.none => PsSyntaxTerm.doEndE span
    | Option.some body => body;
  let fullSpan := psSyntaxSpanJoin span (psSyntaxTermSpan rest);
  match head with
  | PsParseDoHead.nested body _ =>
      match tail with
      | Option.none => Except.ok body
      | Option.some following => psParseDoAppend 4096 following body
  | PsParseDoHead.returnValue value returnSpan =>
      match tail with
      | Option.none => Except.ok (PsSyntaxTerm.doReturnE value returnSpan)
      | Option.some following =>
          Except.error (PsParseError.expectedText
            "terminal return in this statement sequence" "following statement"
            (psSyntaxTermSpan following))
  | PsParseDoHead.action value =>
      match tail with
      | Option.none => Except.ok value
      | Option.some following =>
          Except.ok (PsSyntaxTerm.doThenE value following fullSpan)
  | PsParseDoHead.patternBinding pattern annotation value _ =>
      Except.ok (PsSyntaxTerm.letPatternE pattern annotation value rest fullSpan)
  | PsParseDoHead.binding name annotation value monadic mutable _ =>
      if mutable then Except.ok (PsSyntaxTerm.doLetMutE name annotation value rest fullSpan)
      else if monadic then Except.ok (PsSyntaxTerm.doBindE name annotation value rest fullSpan)
      else Except.ok (PsSyntaxTerm.letE name annotation value rest fullSpan)
  | PsParseDoHead.assignment name value _ =>
      Except.ok (PsSyntaxTerm.doAssignE name value rest fullSpan)
  | PsParseDoHead.forEach name collection body _ =>
      Except.ok (PsSyntaxTerm.doForE name collection (psParseDoFallthrough body) rest fullSpan)
  | PsParseDoHead.forRange name lower upper body _ =>
      Except.ok (PsSyntaxTerm.doForRangeE name lower upper (psParseDoFallthrough body) rest fullSpan)
  | PsParseDoHead.whileLoop condition body _ =>
      Except.ok (PsSyntaxTerm.doWhileE condition (psParseDoFallthrough body) rest fullSpan)
  | PsParseDoHead.handler action name recovery _ =>
      match tail with
      | none => Except.ok (PsSyntaxTerm.doTryE action name recovery rest fullSpan)
      | some _ => Except.ok (PsSyntaxTerm.doTryE (psParseDoFallthrough action) name
          (psParseDoFallthrough recovery) rest fullSpan)
  | PsParseDoHead.conditional condition thenBody elseBody _ =>
      match tail with
      | Option.none => Except.ok (PsSyntaxTerm.doIfE condition thenBody elseBody rest fullSpan)
      | Option.some _ =>
          Except.ok (PsSyntaxTerm.doIfE condition
            (psParseDoFallthrough thenBody)
            (psParseDoFallthrough elseBody) rest fullSpan)

def psParseDoBranch
    (parseBody : Bool -> Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (allowLayout : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if psTokenCursorAtText cursor "{" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "branch body")
    | Option.some opening =>
        if psTokenCursorAtText opening.cursor "}" then
          Except.error (psParseDoExpected "nonempty procedural branch" opening.cursor)
        else
          match psTokenCursorPeek opening.cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd "branch body")
          | Option.some first =>
              match parseBody true first.span.start.column opening.cursor with
              | Except.error error => Except.error error
              | Except.ok body =>
                  match psTokenCursorExpectText body.cursor "}" with
                  | Except.error error => Except.error error
                  | Except.ok closing => Except.ok (PsParseResult.mk body.value closing.cursor)
  else if allowLayout then
    match psTokenCursorPeek cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "branch body")
    | Option.some first =>
        if psTokenCursorAtText cursor "else" || psTokenCursorAtText cursor "catch" then
          Except.error (psParseDoExpected "branch body" cursor)
        else parseBody false first.span.start.column cursor
  else Except.error (psParseDoExpected "{" cursor)

def psParseDoConditional
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (parseBody : Bool -> Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (native : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsParseDoHead) :=
  match psTokenCursorExpectText cursor "if" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      let condition : Except PsParseError (PsParseResult PsSyntaxTerm) :=
        if native then
          match parseTerm keyword.cursor with
          | Except.error error => Except.error error
          | Except.ok value =>
              match psTokenCursorExpectText value.cursor "then" with
              | Except.error error => Except.error error
              | Except.ok separator => Except.ok (PsParseResult.mk value.value separator.cursor)
        else
          match psTokenCursorExpectText keyword.cursor "(" with
          | Except.error error => Except.error error
          | Except.ok opening =>
              match parseTerm opening.cursor with
              | Except.error error => Except.error error
              | Except.ok value =>
                  match psTokenCursorExpectText value.cursor ")" with
                  | Except.error error => Except.error error
                  | Except.ok closing => Except.ok (PsParseResult.mk value.value closing.cursor);
      match condition with
      | Except.error error => Except.error error
      | Except.ok condition =>
          match psParseDoBranch parseBody native condition.cursor with
          | Except.error error => Except.error error
          | Except.ok thenBody =>
              let hasElse : Bool :=
                if psTokenCursorAtText thenBody.cursor "else" then
                  if native then
                    match psTokenCursorPeek thenBody.cursor with
                    | Option.none => false
                    | Option.some token =>
                        Nat.ble keyword.token.span.start.column token.span.start.column
                  else true
                else false;
              let elseBody : Except PsParseError (PsParseResult PsSyntaxTerm) :=
                if hasElse then
                  match psTokenCursorAdvance thenBody.cursor with
                  | Option.none => Except.error (PsParseError.unexpectedEnd "else branch")
                  | Option.some keyword => psParseDoBranch parseBody native keyword.cursor
                else Except.ok (PsParseResult.mk
                  (PsSyntaxTerm.doEndE (psSyntaxTermSpan thenBody.value)) thenBody.cursor);
              match elseBody with
              | Except.error error => Except.error error
              | Except.ok elseBody =>
                  Except.ok (PsParseResult.mk
                    (PsParseDoHead.conditional condition.value thenBody.value elseBody.value
                      { start := keyword.token.span.start,
                        stop := (psParseDoTermStop elseBody.value) }) elseBody.cursor)


-- A procedural header ends at an outer delimiter. This prevents the PS body
-- brace from being mistaken for a native record argument to the iterable.
def psParseDoTakeHeader (delimiter : String) (fuel : Nat) :
    Nat -> PsTokenCursor -> List PsToken ->
    Except PsParseError (PsParseResult (List PsToken)) :=
  match fuel with
  | Nat.zero =>
      fun (_depth : Nat) (_cursor : PsTokenCursor) (_tokensRev : List PsToken) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (depth : Nat) (cursor : PsTokenCursor) (tokensRev : List PsToken) =>
        let smaller :
            Nat -> PsTokenCursor -> List PsToken ->
            Except PsParseError (PsParseResult (List PsToken)) :=
          psParseDoTakeHeader delimiter remaining;
        match psTokenCursorPeek cursor with
        | Option.none => Except.error (psParseDoExpected delimiter cursor)
        | Option.some token =>
            if if Nat.beq depth 0 then psStringEq token.text delimiter else false then
              Except.ok (PsParseResult.mk (psParseListReverse tokensRev) cursor)
            else if psTokenKindEq token.kind PsTokenKind.endOfInput then
              Except.error (psParseDoExpected delimiter cursor)
            else
              match psTokenCursorAdvance cursor with
              | Option.none => Except.error (psParseDoExpected delimiter cursor)
              | Option.some read =>
                  let nextDepth :=
                    if psParseDoOpenToken token.text then Nat.succ depth
                    else if psParseDoCloseToken token.text then Nat.sub depth 1
                    else depth;
                  smaller nextDepth read.cursor
                    (List.cons token tokensRev)

def psParseDoLoopBody
    (parseBody : Bool -> Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (native : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if native then
    match psTokenCursorExpectText cursor "do" with
    | Except.error error => Except.error error
    | Except.ok keyword => psParseDoBranch parseBody true keyword.cursor
  else psParseDoBranch parseBody false cursor

-- A bracketed List literal is an ordinary iterable. Only a colon at the
-- outer bracket level selects range syntax; nested type/group delimiters do not.
def psParseDoRangeColon (tokens : List PsToken) : Nat -> Bool :=
  match tokens with
  | List.nil => fun (_depth : Nat) => false
  | List.cons token rest =>
      fun (depth : Nat) =>
        let smaller : Nat -> Bool := psParseDoRangeColon rest;
        if Nat.beq depth 0 && psStringEq token.text "]" then false
        else if Nat.beq depth 0 && psStringEq token.text ":" then true
        else
          let nextDepth :=
            if psParseDoOpenToken token.text then Nat.succ depth
            else if psParseDoCloseToken token.text then Nat.sub depth 1
            else depth;
          smaller nextDepth

def psParseDoIsRange (cursor : PsTokenCursor) : Bool :=
  if psTokenCursorAtText cursor "[" then
    match psTokenCursorAdvance cursor with
    | none => false
    | some opening => psParseDoRangeColon opening.cursor.remaining 0
  else false

def psParseDoFor
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (parseBody : Bool -> Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (native : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsParseDoHead) :=
  match psTokenCursorExpectText cursor "for" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psTokenCursorExpectKind keyword.cursor PsTokenKind.identifier with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psTokenCursorExpectText name.cursor "in" with
          | Except.error error => Except.error error
          | Except.ok separator =>
              let sourceName := PsSyntaxName.mk [name.token.text] name.token.span;
              let delimiter := if native then "do" else "{";
              match psParseDoTakeHeader delimiter
                  (Nat.succ (psParseListLength separator.cursor.remaining))
                  0 separator.cursor [] with
              | Except.error error => Except.error error
              | Except.ok header =>
                  let headerCursor := PsTokenCursor.mk header.value;
                  let iterable :
                      Except PsParseError (Prod PsSyntaxTerm (Option PsSyntaxTerm)) :=
                    if psParseDoIsRange headerCursor then
                      match psTokenCursorAdvance headerCursor with
                      | Option.none => Except.error (PsParseError.unexpectedEnd "range")
                      | Option.some opening =>
                          let lower : Except PsParseError (PsParseResult PsSyntaxTerm) :=
                            if psTokenCursorAtText opening.cursor ":" then
                              Except.ok (PsParseResult.mk
                                (PsSyntaxTerm.natural "0" opening.token.span) opening.cursor)
                            else parseTerm opening.cursor;
                          match lower with
                          | Except.error error => Except.error error
                          | Except.ok lower =>
                              match psTokenCursorExpectText lower.cursor ":" with
                              | Except.error error => Except.error error
                              | Except.ok colon =>
                                  match parseTerm colon.cursor with
                                  | Except.error error => Except.error error
                                  | Except.ok upper =>
                                      match psTokenCursorExpectText upper.cursor "]" with
                                      | Except.error error => Except.error error
                                      | Except.ok closing =>
                                          if psTokenCursorDone closing.cursor then
                                            Except.ok (Prod.mk lower.value (Option.some upper.value))
                                          else Except.error
                                            (psParseDoExpected "end of unit-step range" closing.cursor)
                    else
                      match psParseDoCompleteTerm parseTerm headerCursor with
                      | Except.error error => Except.error error
                      | Except.ok collection => Except.ok (Prod.mk collection Option.none);
                  match iterable with
                  | Except.error error => Except.error error
                  | Except.ok iterable =>
                      match psParseDoLoopBody parseBody native header.cursor with
                      | Except.error error => Except.error error
                      | Except.ok body =>
                          let span : PsSourceSpan := {
                            start := keyword.token.span.start
                            stop := (psParseDoTermStop body.value)
                          };
                          let head : PsParseDoHead :=
                            match iterable.snd with
                            | Option.none =>
                                PsParseDoHead.forEach sourceName iterable.fst body.value span
                            | Option.some upper =>
                                PsParseDoHead.forRange sourceName iterable.fst upper body.value span;
                          Except.ok (PsParseResult.mk head body.cursor)

def psParseDoWhile
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (parseBody : Bool -> Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (native : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsParseDoHead) :=
  match psTokenCursorExpectText cursor "while" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      let condition : Except PsParseError (PsParseResult PsSyntaxTerm) :=
        if native then parseTerm keyword.cursor
        else
          match psTokenCursorExpectText keyword.cursor "(" with
          | Except.error error => Except.error error
          | Except.ok opening =>
              match parseTerm opening.cursor with
              | Except.error error => Except.error error
              | Except.ok value =>
                  match psTokenCursorExpectText value.cursor ")" with
                  | Except.error error => Except.error error
                  | Except.ok closing => Except.ok (PsParseResult.mk value.value closing.cursor);
      match condition with
      | Except.error error => Except.error error
      | Except.ok condition =>
          match psParseDoLoopBody parseBody native condition.cursor with
          | Except.error error => Except.error error
          | Except.ok body =>
              Except.ok (PsParseResult.mk
                (PsParseDoHead.whileLoop condition.value body.value
                  { start := keyword.token.span.start,
                    stop := (psParseDoTermStop body.value) }) body.cursor)

-- A single typed catch delimits the handler scope. Braces are required by PS;
-- native Lean may use layout. A nested try may not steal an outer catch.
def psParseDoTry
    (parseBody : Bool -> Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (native : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsParseDoHead) :=
  match psTokenCursorExpectText cursor "try" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseDoBranch parseBody native keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok body =>
          match psTokenCursorExpectText body.cursor "catch" with
          | Except.error error => Except.error error
          | Except.ok catchToken =>
              if native && Nat.blt catchToken.token.span.start.column keyword.token.span.start.column then
                Except.error (psParseDoExpected "catch aligned with its try" body.cursor)
              else
                match psTokenCursorExpectKind catchToken.cursor PsTokenKind.identifier with
                | Except.error error => Except.error error
                | Except.ok binder =>
                    match psTokenCursorExpectText binder.cursor "=>" with
                    | Except.error error => Except.error error
                    | Except.ok separator =>
                        match psParseDoBranch parseBody native separator.cursor with
                        | Except.error error => Except.error error
                        | Except.ok recovery =>
                            let name := PsSyntaxName.mk [binder.token.text] binder.token.span;
                            let span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan recovery.value);
                            Except.ok (PsParseResult.mk
                              (PsParseDoHead.handler body.value name recovery.value span) recovery.cursor)

def psParseDoBody
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (allowSemicolon : Bool) (fuel : Nat) :
    Bool -> Nat -> PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | Nat.zero =>
      fun (_braced : Bool) (_column : Nat) (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (braced : Bool) (column : Nat) (cursor : PsTokenCursor) =>
        let smaller := psParseDoBody parseTerm allowSemicolon remaining;
        match psTokenCursorPeek cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
        | Option.some first =>
            let parsedHead : Except PsParseError (PsParseResult PsParseDoHead) :=
              if psTokenCursorAtText cursor "if" then
                psParseDoConditional parseTerm smaller allowSemicolon cursor
              else if psTokenCursorAtText cursor "for" then
                psParseDoFor parseTerm smaller allowSemicolon cursor
              else if psTokenCursorAtText cursor "try" then
                psParseDoTry smaller allowSemicolon cursor
              else if psTokenCursorAtText cursor "while" then
                psParseDoWhile parseTerm smaller allowSemicolon cursor
              else
                let chunk := psParseDoTakeStatement
                  (Nat.succ (psParseListLength cursor.remaining)) first.span.start 0 0 0 cursor [];
                match psParseDoStatement parseTerm (PsTokenCursor.mk chunk.value) with
                | Except.error error => Except.error error
                | Except.ok head => Except.ok (PsParseResult.mk head chunk.cursor);
            match parsedHead with
            | Except.error error => Except.error error
            | Except.ok parsed =>
                let next : Except PsParseError (Prod Bool PsTokenCursor) :=
                  if psTokenCursorAtText parsed.cursor ";" then
                    if allowSemicolon then
                      match psTokenCursorAdvance parsed.cursor with
                      | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
                      | Option.some separator => Except.ok (Prod.mk true separator.cursor)
                    else Except.error
                      (psParseDoExpected "newline-separated do statements, without semicolon" parsed.cursor)
                  else Except.ok (Prod.mk false parsed.cursor);
                match next with
                | Except.error error => Except.error error
                | Except.ok next =>
                    let hasNext : Bool :=
                      if psTokenCursorDone next.snd then false
                      else if psTokenCursorAtText next.snd "}" then false
                      else if psTokenCursorAtText next.snd "catch" then false
                      else if psTokenCursorAtText next.snd "else" then false
                      else if braced then true
                      else
                        match psTokenCursorPeek next.snd with
                        | Option.none => false
                        | Option.some token =>
                            if psParseDoCloseToken token.text then false
                            else if next.fst then
                              if Nat.beq token.span.start.line
                                  (psParseDoHeadStopLine parsed.value) then true
                              else Nat.ble column token.span.start.column
                            else
                              if Nat.ble (Nat.succ (psParseDoHeadStopLine parsed.value))
                                  token.span.start.line then
                                Nat.beq column token.span.start.column
                              else false;
                    if hasNext then
                      match smaller braced column next.snd with
                      | Except.error error => Except.error error
                      | Except.ok tail =>
                          match psParseDoCloseHead parsed.value (Option.some tail.value) with
                          | Except.error error => Except.error error
                          | Except.ok value => Except.ok (PsParseResult.mk value tail.cursor)
                    else
                      match psParseDoCloseHead parsed.value Option.none with
                      | Except.error error => Except.error error
                      | Except.ok value => Except.ok (PsParseResult.mk value next.snd)

def psParseDo
    (parseTerm : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (allowSemicolon requireBraces : Bool)
    (start : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  let braced := psTokenCursorAtText cursor "{";
  if if requireBraces then if braced then false else true else false then
    Except.error (psParseDoExpected "{" cursor)
  else
    let bodyCursor : PsTokenCursor :=
      if braced then
        match psTokenCursorAdvance cursor with
        | Option.none => cursor
        | Option.some opening => opening.cursor
      else cursor;
    match psTokenCursorPeek bodyCursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
    | Option.some first =>
        match psParseDoBody parseTerm allowSemicolon
            (Nat.succ (psParseListLength bodyCursor.remaining))
            braced first.span.start.column bodyCursor with
        | Except.error error => Except.error error
        | Except.ok body =>
            if braced then
              match psTokenCursorExpectText body.cursor "}" with
              | Except.error error => Except.error error
              | Except.ok close =>
                  Except.ok (PsParseResult.mk
                    (PsSyntaxTerm.doE body.value
                      { start := start, stop := close.token.span.stop }) close.cursor)
            else
              Except.ok (PsParseResult.mk
                (PsSyntaxTerm.doE body.value
                  { start := start, stop := (psParseDoTermStop body.value) }) body.cursor)
