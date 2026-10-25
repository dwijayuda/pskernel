import Ps.Syntax.Lossless

def demand (test : Bool) (message : String) : IO Unit :=
  if test then pure () else throw (IO.userError message)

def checkSource (grammar : PsLosslessGrammar) (source : String) : IO Unit := do
  let .ok tape := psCaptureLossless grammar source
    | throw (IO.userError "capture refused")
  demand (String.intercalate "" (tape.pieces.map (fun p => p.raw)) == source) "roundtrip"
  let original := match grammar with
    | .lean => psLex source
    | .proofScript => psLexProofScript source
  match original with
  | .error _ => demand tape.lexicalError.isSome "diagnostic lost"
  | .ok tokens =>
    demand tape.lexicalError.isNone "unexpected error"
    demand (tape.tokens.length == tokens.length) "tokens changed"
    let projected := tape.pieces.filterMap (fun p => p.token)
    demand (projected.length == tokens.length) "projection length"
    for (a, b) in projected.zip tokens do
      demand (psTokenKindEq a.kind b.kind && a.text == b.text &&
        psLosslessPosEq a.span.start b.span.start &&
        psLosslessPosEq a.span.stop b.span.stop) "projection changed"

def main : IO Unit := do
  let cases := ["", " \r\n", "-- eof", "/- outer /- nested -/ end -/",
    "def x := \"/- literal -- \\\" raw\" -- tail\r\n",
    "def α := '😀'\n", "﻿def x := 2\r\n", "\tdef x := 0",
    "/- unfinished", "\"unfinished", "\"line\n", "'x", "x\r", "x﻿"]
  for source in cases do
    checkSource .lean source
    checkSource .proofScript source
  match psCaptureLosslessWithLimit 0 .lean "" with
  | .error .budgetExhausted => pure ()
  | _ => throw (IO.userError "piece budget not enforced")
  match psCaptureLosslessWithLimit 1 .lean "a b" with
  | .error .budgetExhausted => pure ()
  | _ => throw (IO.userError "piece budget not enforced")
  IO.println "PSC1_LOSSLESS_LEAN_TESTS: PASS"
