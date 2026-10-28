import Ps.Foundation.Source

-- Test consumers of the actual compiler source module; never counted as modules.
def psMinSourceByteOffset (offset : Nat) (line : Nat) (column : Nat) : Nat :=
  let position := PsSourcePos.mk offset line column;
  position.byteOffset

def psMinSourceLine (offset : Nat) (line : Nat) (column : Nat) : Nat :=
  let position := PsSourcePos.mk offset line column;
  position.line

def psMinSourceColumn (offset : Nat) (line : Nat) (column : Nat) : Nat :=
  let position := PsSourcePos.mk offset line column;
  position.column

def psMinSourceSpanStartOffset (a : Nat) (b : Nat) (c : Nat) (d : Nat) (e : Nat) (f : Nat) : Nat :=
  let span := PsSourceSpan.mk (PsSourcePos.mk a b c) (PsSourcePos.mk d e f);
  span.start.byteOffset

def psMinSourceSpanStartLine (a : Nat) (b : Nat) (c : Nat) (d : Nat) (e : Nat) (f : Nat) : Nat :=
  let span := PsSourceSpan.mk (PsSourcePos.mk a b c) (PsSourcePos.mk d e f);
  span.start.line

def psMinSourceSpanStartColumn (a : Nat) (b : Nat) (c : Nat) (d : Nat) (e : Nat) (f : Nat) : Nat :=
  let span := PsSourceSpan.mk (PsSourcePos.mk a b c) (PsSourcePos.mk d e f);
  span.start.column

def psMinSourceSpanStopOffset (a : Nat) (b : Nat) (c : Nat) (d : Nat) (e : Nat) (f : Nat) : Nat :=
  let span := PsSourceSpan.mk (PsSourcePos.mk a b c) (PsSourcePos.mk d e f);
  span.stop.byteOffset

def psMinSourceSpanStopLine (a : Nat) (b : Nat) (c : Nat) (d : Nat) (e : Nat) (f : Nat) : Nat :=
  let span := PsSourceSpan.mk (PsSourcePos.mk a b c) (PsSourcePos.mk d e f);
  span.stop.line

def psMinSourceSpanStopColumn (a : Nat) (b : Nat) (c : Nat) (d : Nat) (e : Nat) (f : Nat) : Nat :=
  let span := PsSourceSpan.mk (PsSourcePos.mk a b c) (PsSourcePos.mk d e f);
  span.stop.column
