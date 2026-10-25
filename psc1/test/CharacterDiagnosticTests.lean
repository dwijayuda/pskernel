import Ps.Syntax.Lossless

/-! The baseline leaf is copied verbatim from qualified PR #182. A CI guard
checks its exact bytes against the immutable Git object, rather than accepting
a handwritten reference lexer. Only diagnostic locations may differ. -/

def legacyPsLexReadCharacterBody
    (remaining : List Char)
    (position : PsSourcePos)
    (start : PsSourcePos)
    (charsRev : List Char) :
    Except PsLexError PsLexRead :=
  match remaining with
  | List.nil =>
      psLexCharacterError start position
  | List.cons first rest =>
      if psLexCharEq first '\n' then
        psLexCharacterError start position
      else if psLexCharEq first '\\' then
        match rest with
        | List.nil =>
            psLexCharacterError start position
        | List.cons escaped tail =>
            if psLexCharEq escaped 'x' then
              psLexReadCharacterHex2
                position
                start
                charsRev
                tail
            else if psLexCharEq escaped 'u' then
              psLexReadCharacterHex4
                position
                start
                charsRev
                tail
            else
              match tail with
              | List.nil =>
                  psLexCharacterError start position
              | List.cons close afterClose =>
                  if psLexCharEq close '\'' then
                    if psLexCharacterEscapeAllowed escaped then
                      let afterSlash :=
                        psLexAdvanceChar position first;
                      let afterEscape :=
                        psLexAdvanceChar afterSlash escaped;
                      let stop :=
                        psLexAdvanceChar afterEscape close;
                      Except.ok {
                        cursor := {
                          remaining := afterClose
                          position := stop
                        }
                        charsRev :=
                          List.cons close
                            (List.cons escaped
                              (List.cons first charsRev))
                      }
                    else
                      psLexCharacterError start position
                  else
                    psLexCharacterError start position
      else
        match rest with
        | List.nil =>
            psLexCharacterError start position
        | List.cons close tail =>
            if psLexCharEq close '\'' then
              let afterChar :=
                psLexAdvanceChar position first;
              let stop :=
                psLexAdvanceChar afterChar close;
              Except.ok {
                cursor := {
                  remaining := tail
                  position := stop
                }
                charsRev :=
                  List.cons close
                    (List.cons first charsRev)
              }
            else
              psLexCharacterError
                start
                (psLexAdvanceChar position close)

-- Retain every success field and the error constructor/reason, erasing spans only.
def characterErrorClass : PsLexError → Nat × String
  | .unterminatedBlockComment _ => (0, "")
  | .unterminatedString _ => (1, "")
  | .newlineInString _ => (2, "")
  | .unterminatedCharacter _ => (3, "")
  | .fuelExhausted => (4, "")
  | .invalidSource reason _ => (5, reason)

def characterObservation : Except PsLexError PsLexRead → Except (Nat × String) PsLexRead
  | .ok value => .ok value
  | .error error => .error (characterErrorClass error)

/-- For all inputs and cursor states, successful tokens/cursors and the exact
error classification/reason agree with the qualified pre-fix leaf. -/
theorem characterDiagnostic_preserves_observation
    (remaining : List Char) (position start : PsSourcePos) (charsRev : List Char) :
    characterObservation (psLexReadCharacterBody remaining position start charsRev) =
      characterObservation (legacyPsLexReadCharacterBody remaining position start charsRev) := by
  unfold psLexReadCharacterBody legacyPsLexReadCharacterBody
  repeat
    first
    | rfl
    | split

/-- Malformed unescaped characters report the end of the actual consumed prefix,
including both scalar widths and LF/column effects in their original order. -/
theorem characterDiagnostic_uses_actual_prefix
    (first close : Char) (tail : List Char) (position start : PsSourcePos)
    (charsRev : List Char)
    (notNewline : psLexCharEq first '\n' = false)
    (notSlash : psLexCharEq first '\\' = false)
    (notQuote : psLexCharEq close '\'' = false) :
    psLexReadCharacterBody (first :: close :: tail) position start charsRev =
      .error (.unterminatedCharacter (psLexSpan start (psLexAdvanceTwo position first close))) := by
  simp [psLexReadCharacterBody, notNewline, notSlash, notQuote, psLexCharacterError]

def characterDemand (value : Bool) (message : String) : IO Unit :=
  if value then pure () else throw (IO.userError message)

def characterCheck (grammar : PsLosslessGrammar) (source : String) : IO Unit := do
  let .ok tape := psCaptureLossless grammar source
    | throw (IO.userError "PSC1_CHARACTER_CAPTURE_FAILED")
  characterDemand (String.intercalate "" (tape.pieces.map (fun p => p.raw)) == source)
    "PSC1_CHARACTER_ROUNDTRIP"
  match tape.lexicalError with
  | none => pure ()
  | some error =>
    let span := match error with
      | .unterminatedBlockComment span | .unterminatedString span
      | .newlineInString span | .unterminatedCharacter span | .invalidSource _ span => some span
      | .fuelExhausted => none
    match span with
    | none => pure ()
    | some span =>
      let initial := psLosslessInitial grammar source
      for position in [span.start, span.stop] do
        let .ok cursor := psLosslessAdvanceTo (source.utf8ByteSize + 1)
          position.byteOffset initial.cursor
          | throw (IO.userError "PSC1_CHARACTER_NON_BOUNDARY")
        characterDemand (psLosslessPosEq position cursor.position)
          "PSC1_CHARACTER_POSITION_MISMATCH"

def main : IO Unit := do
  let bodies : List Char := ['a', 'α', '中', '😀', '\r', '\t', '﻿']
  let closes : List Char := ['x', 'β', '界', '🚀', '\n', '\r', '\t', '/', '-']
  let prefixes := ["", "-- before\r\n", "/- before 😀 -/\n", "def value := "]
  let mut checked := 0
  for grammar in [PsLosslessGrammar.lean, PsLosslessGrammar.proofScript] do
    for prefix in prefixes do
      for body in bodies do
        for close in closes do
          characterCheck grammar
            (prefix ++ "'" ++ String.singleton body ++ String.singleton close ++ " tail")
          checked := checked + 1
    for source in ["'a'", "'α'", "'😀'", "'\\n'", "'\\x41'", "'\\u03B1'",
      "'\\uD800'", "'\\xGG'", "'\\uGGGG'", "'\\'", "'\n", "'", "'😀",
      "'αx", "'😀β", "'a🚀", "'\rβ"] do
      characterCheck grammar source
      checked := checked + 1
  IO.println ("PSC1_CHARACTER_DIAGNOSTICS: PASS " ++ toString checked ++ " position cases")
