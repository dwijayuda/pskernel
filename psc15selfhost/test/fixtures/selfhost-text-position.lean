def replayTextBytes (text : String) : Nat := String.utf8ByteSize text

def replayTextGet (text : String) (position : Nat) : Char :=
  String.Internal.get text (String.Pos.Raw.mk position)

def replayTextNext (text : String) (position : Nat) : Nat :=
  String.Pos.Raw.byteIdx (String.Internal.next text (String.Pos.Raw.mk position))

def replayTextAtEnd (text : String) (position : Nat) : Bool :=
  String.Internal.atEnd text (String.Pos.Raw.mk position)
