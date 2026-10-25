import Ps.Syntax.Lexer

/-!
# Lossless lexical capture

This sidecar consumes the existing lexer's token stream; it does not introduce
another parser or change lexical acceptance. Raw slices and individual trivia
ranges retain exact UTF-8 spelling. Positions use the existing cursor convention:
byte offsets, one-based scalar columns, and LF line increments. A leading .ps BOM
is retained as a piece while remaining column-neutral, exactly as psLexProofScript.

Unlexable text is retained as one explicitly unlexed piece with the original
lexical diagnostic. Capturing or reconstructing source grants no checking,
semantic-equivalence, filesystem-editing or publication authority.
-/

inductive PsLosslessGrammar where
  | lean
  | proofScript

inductive PsSourcePieceKind where
  | token
  | whitespace
  | lineComment
  | blockComment
  | byteOrderMark
  | unlexed

structure PsSourcePiece where
  ordinal : Nat
  kind : PsSourcePieceKind
  span : PsSourceSpan
  raw : String
  token : Option PsToken

structure PsLosslessTape where
  pieces : List PsSourcePiece
  tokens : List PsToken
  lexicalError : Option PsLexError
  byteLength : Nat

inductive PsLosslessError where
  | budgetExhausted
  | invalidSpan

structure PsLosslessState where
  cursor : PsLexCursor
  reversed : List PsSourcePiece
  nextOrdinal : Nat

def psLosslessPosEq (left right : PsSourcePos) : Bool :=
  if Nat.beq left.byteOffset right.byteOffset then
    if Nat.beq left.line right.line then Nat.beq left.column right.column
    else false
  else false

-- All slices are taken only after cursor traversal confirms their boundaries.
def psLosslessRaw (source : String) (start stop : PsSourcePos) : String :=
  String.Internal.extract source
    (String.Pos.Raw.mk start.byteOffset)
    (String.Pos.Raw.mk stop.byteOffset)

def psLosslessPiece (source : String) (ordinal : Nat) (kind : PsSourcePieceKind)
    (start stop : PsSourcePos) (token : Option PsToken) : PsSourcePiece :=
  { ordinal := ordinal, kind := kind, span := psLexSpan start stop,
    raw := psLosslessRaw source start stop, token := token }

def psLosslessAdvanceTo (fuel : Nat) (stop : Nat) (cursor : PsLexCursor) :
    Except PsLosslessError PsLexCursor :=
  if Nat.beq cursor.position.byteOffset stop then Except.ok cursor
  else
    match fuel with
    | Nat.zero => Except.error PsLosslessError.budgetExhausted
    | Nat.succ remaining =>
        if Nat.ble stop cursor.position.byteOffset then
          Except.error PsLosslessError.invalidSpan
        else
          match psLexCursorAdvance cursor with
          | Option.none => Except.error PsLosslessError.invalidSpan
          | Option.some next => psLosslessAdvanceTo remaining stop next.cursor

def psLosslessWhitespace (remaining : List Char) (position : PsSourcePos) : PsLexCursor :=
  match remaining with
  | List.nil => { remaining := List.nil, position := position }
  | List.cons char rest =>
      if psLexWhitespace char then
        psLosslessWhitespace rest (psLexAdvanceChar position char)
      else
        { remaining := List.cons char rest, position := position }

def psLosslessTrivia (cursor : PsLexCursor) :
    Except PsLosslessError (Prod PsSourcePieceKind PsLexCursor) :=
  match cursor.remaining with
  | List.nil => Except.error PsLosslessError.invalidSpan
  | List.cons first rest =>
      if psLexWhitespace first then
        Except.ok (Prod.mk PsSourcePieceKind.whitespace
          (psLosslessWhitespace rest (psLexAdvanceChar cursor.position first)))
      else
        match rest with
        | List.nil => Except.error PsLosslessError.invalidSpan
        | List.cons second tail =>
            let afterPrefix := psLexAdvanceTwo cursor.position first second;
            if psLexPairEq first second '-' '-' then
              Except.ok (Prod.mk PsSourcePieceKind.lineComment
                (psLexSkipLineComment tail afterPrefix))
            else if psLexPairEq first second '/' '-' then
              match psLexSkipBlockComment 1 tail cursor.position afterPrefix with
              | Except.error _ => Except.error PsLosslessError.invalidSpan
              | Except.ok next => Except.ok (Prod.mk PsSourcePieceKind.blockComment next)
            else
              Except.error PsLosslessError.invalidSpan

def psLosslessInitial (grammar : PsLosslessGrammar) (source : String) : PsLosslessState :=
  let original := psLexCursorFromString source;
  match grammar with
  | PsLosslessGrammar.lean =>
      { cursor := original, reversed := List.nil, nextOrdinal := 0 }
  | PsLosslessGrammar.proofScript =>
      match original.remaining with
      | List.nil => { cursor := original, reversed := List.nil, nextOrdinal := 0 }
      | List.cons first rest =>
          if Nat.beq (Char.toNat first) 65279 then
            let stop : PsSourcePos := { byteOffset := 3, line := 1, column := 1 };
            let piece := psLosslessPiece source 0 PsSourcePieceKind.byteOrderMark
              original.position stop Option.none;
            { cursor := { remaining := rest, position := stop },
              reversed := List.cons piece List.nil, nextOrdinal := 1 }
          else
            { cursor := original, reversed := List.nil, nextOrdinal := 0 }

def psLosslessAppend (source : String) (state : PsLosslessState)
    (kind : PsSourcePieceKind) (next : PsLexCursor) (token : Option PsToken) :
    PsLosslessState :=
  let piece := psLosslessPiece source state.nextOrdinal kind
    state.cursor.position next.position token;
  { cursor := next, reversed := List.cons piece state.reversed,
    nextOrdinal := Nat.succ state.nextOrdinal }

def psLosslessCaptureWorker (fuel : Nat) (inputBound pieceLimit : Nat) (source : String)
    (tokens : List PsToken) (state : PsLosslessState) :
    Except PsLosslessError (List PsSourcePiece) :=
  match fuel with
  | Nat.zero => Except.error PsLosslessError.budgetExhausted
  | Nat.succ remaining =>
      if Nat.ble pieceLimit state.nextOrdinal then
        Except.error PsLosslessError.budgetExhausted
      else
        match tokens with
        | List.nil => Except.error PsLosslessError.invalidSpan
        | List.cons token rest =>
            if Nat.beq state.cursor.position.byteOffset token.span.start.byteOffset then
              if !psLosslessPosEq state.cursor.position token.span.start then
                Except.error PsLosslessError.invalidSpan
              else if psTokenKindEq token.kind PsTokenKind.endOfInput then
                if psLexCursorDone state.cursor then
                  if !psLosslessPosEq token.span.start token.span.stop then
                    Except.error PsLosslessError.invalidSpan
                  else
                    match rest with
                    | List.nil =>
                        Except.ok (psListReverse
                          (psLosslessAppend source state PsSourcePieceKind.token
                            state.cursor (Option.some token)).reversed)
                    | List.cons _ _ => Except.error PsLosslessError.invalidSpan
                else Except.error PsLosslessError.invalidSpan
              else
                match psLosslessAdvanceTo inputBound token.span.stop.byteOffset state.cursor with
                | Except.error error => Except.error error
                | Except.ok next =>
                    if !psLosslessPosEq next.position token.span.stop then
                      Except.error PsLosslessError.invalidSpan
                    else if Nat.beq next.position.byteOffset state.cursor.position.byteOffset then
                      Except.error PsLosslessError.invalidSpan
                    else
                      psLosslessCaptureWorker remaining inputBound pieceLimit source rest
                        (psLosslessAppend source state PsSourcePieceKind.token next
                          (Option.some token))
            else if Nat.ble token.span.start.byteOffset state.cursor.position.byteOffset then
              Except.error PsLosslessError.invalidSpan
            else
              match psLosslessTrivia state.cursor with
              | Except.error error => Except.error error
              | Except.ok trivia =>
                  if Nat.ble trivia.snd.position.byteOffset state.cursor.position.byteOffset then
                    Except.error PsLosslessError.invalidSpan
                  else if Nat.ble trivia.snd.position.byteOffset token.span.start.byteOffset then
                    psLosslessCaptureWorker remaining inputBound pieceLimit source tokens
                      (psLosslessAppend source state trivia.fst trivia.snd Option.none)
                  else
                    Except.error PsLosslessError.invalidSpan

def psCaptureLosslessWithLimit (pieceLimit : Nat) (grammar : PsLosslessGrammar)
    (source : String) : Except PsLosslessError PsLosslessTape :=
  let initial := psLosslessInitial grammar source;
  let bytes := String.utf8ByteSize source;
  let bound := Nat.succ bytes;
  let lexical :=
    match grammar with
    | PsLosslessGrammar.lean => psLex source
    | PsLosslessGrammar.proofScript => psLexProofScript source;
  match lexical with
  | Except.ok tokens =>
      match psLosslessCaptureWorker (Nat.add bound 1) bound pieceLimit source tokens initial with
      | Except.error error => Except.error error
      | Except.ok pieces =>
          Except.ok {
            pieces := pieces
            tokens := tokens
            lexicalError := Option.none
            byteLength := bytes }
  | Except.error error =>
      if Nat.beq pieceLimit 0 then Except.error PsLosslessError.budgetExhausted
      else
        match psLosslessAdvanceTo bound bytes initial.cursor with
        | Except.error failure => Except.error failure
        | Except.ok final =>
            let start : PsSourcePos := { byteOffset := 0, line := 1, column := 1 };
            let piece := psLosslessPiece source 0 PsSourcePieceKind.unlexed
              start final.position Option.none;
            Except.ok {
              pieces := List.cons piece List.nil
              tokens := List.nil
              lexicalError := Option.some error
              byteLength := bytes }

def psCaptureLossless (grammar : PsLosslessGrammar) (source : String) :
    Except PsLosslessError PsLosslessTape :=
  psCaptureLosslessWithLimit 262144 grammar source
