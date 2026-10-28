-- A streaming, exact-byte verifier. A parser only proposes the typed source.
-- Numeric bytes are interpreted in base ten with Nat addition, without division
-- intrinsics or unary re-encoding proportional to the numeric value.
import Ps.MinKernel.Profile.RegularIngressCheck

structure PsMinRegByteNumber where
  value : Nat
  rest : List Nat

def psMinRegByteLiteral (literal : List Nat) (bytes : List Nat) : Option (List Nat) :=
  match literal with
  | List.nil => Option.some bytes
  | List.cons expected tail =>
    match bytes with
    | List.nil => Option.none
    | List.cons actual rest =>
      if Nat.beq expected actual then psMinRegByteLiteral tail rest else Option.none

def psMinRegByteThen (input : Option (List Nat)) (next : List Nat -> Option (List Nat)) :
    Option (List Nat) :=
  match input with
  | Option.none => Option.none
  | Option.some bytes => next bytes

def psMinRegByteDigit (byte : Nat) : Bool :=
  if Nat.blt byte 48 then false else if Nat.blt 57 byte then false else true

def psMinRegByteTimesTen (value : Nat) : Nat :=
  let twice : Nat := Nat.add value value;
  let four : Nat := Nat.add twice twice;
  let eight : Nat := Nat.add four four;
  Nat.add eight twice

def psMinRegByteReadTail (fuel : Nat) (bytes : List Nat) (value : Nat) :
    Option PsMinRegByteNumber :=
  match bytes with
  | List.nil => Option.some (PsMinRegByteNumber.mk value List.nil)
  | List.cons head rest =>
    if psMinRegByteDigit head then
      match fuel with
      | Nat.zero => Option.none
      | Nat.succ remaining =>
        let next : Nat := Nat.add (psMinRegByteTimesTen value) (Nat.sub head 48);
        if psMinRegCoreScalarValid next then psMinRegByteReadTail remaining rest next else Option.none
    else Option.some (PsMinRegByteNumber.mk value bytes)

def psMinRegByteReadNumber (bytes : List Nat) : Option PsMinRegByteNumber :=
  match bytes with
  | List.nil => Option.none
  | List.cons head rest => if Nat.beq head 48 then
      Option.some (PsMinRegByteNumber.mk 0 rest)
    else if psMinRegByteDigit head then
      psMinRegByteReadTail 6 rest (Nat.sub head 48)
    else Option.none

def psMinRegByteNumber (expected : Nat) (bytes : List Nat) : Option (List Nat) :=
  match psMinRegByteReadNumber bytes with
  | Option.none => Option.none
  | Option.some result => if Nat.beq result.value expected then Option.some result.rest else Option.none

def psMinRegByteQuotedNumber (expected : Nat) (bytes : List Nat) : Option (List Nat) :=
  psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [34] byteTail0)) (fun byteTail1 => psMinRegByteNumber expected byteTail1)) (fun byteTail2 => psMinRegByteLiteral [34] byteTail2)

def psMinRegByteText (text : List Nat) (bytes : List Nat) : Option (List Nat) :=
  psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [34] byteTail0)) (fun byteTail1 => psMinRegByteLiteral text byteTail1)) (fun byteTail2 => psMinRegByteLiteral [34] byteTail2)

def psMinRegByteName (name : PsMinCoreName) (bytes : List Nat) : Option (List Nat) :=
  match name with
  | .anonymous => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 97, 34, 125] bytes
  | .str parent text =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 112, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteName parent byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteText text byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4)
  | .num parent value =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 110, 34, 44, 34, 112, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteName parent byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteQuotedNumber value byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4)

def psMinRegByteLevel (level : Nat) (bytes : List Nat) : Option (List Nat) :=
  match level with
  | Nat.zero => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 122, 34, 125] bytes
  | Nat.succ rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 115, 34, 44, 34, 111, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteLevel rest byteTail1)) (fun byteTail2 => psMinRegByteLiteral [125] byteTail2)

def psMinRegByteLevelsTail (levels : List Nat) (bytes : List Nat) : Option (List Nat) :=
  match levels with
  | List.nil => Option.some bytes
  | List.cons level rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [44] byteTail0)) (fun byteTail1 => psMinRegByteLevel level byteTail1)) (fun byteTail2 => psMinRegByteLevelsTail rest byteTail2)

def psMinRegByteLevels (levels : List Nat) (bytes : List Nat) : Option (List Nat) :=
  match levels with
  | List.nil => psMinRegByteLiteral [91, 93] bytes
  | List.cons level rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [91] byteTail0)) (fun byteTail1 => psMinRegByteLevel level byteTail1)) (fun byteTail2 => psMinRegByteLevelsTail rest byteTail2)) (fun byteTail3 => psMinRegByteLiteral [93] byteTail3)

def psMinRegByteBinder (binder : Nat) (bytes : List Nat) : Option (List Nat) :=
  if Nat.beq binder 0 then psMinRegByteLiteral [34, 100, 101, 102, 97, 117, 108, 116, 34] bytes else
  if Nat.beq binder 1 then psMinRegByteLiteral [34, 105, 109, 112, 108, 105, 99, 105, 116, 34] bytes else
  if Nat.beq binder 2 then psMinRegByteLiteral [34, 115, 116, 114, 105, 99, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34] bytes else
  if Nat.beq binder 3 then psMinRegByteLiteral [34, 105, 110, 115, 116, 73, 109, 112, 108, 105, 99, 105, 116, 34] bytes else Option.none

def psMinRegByteExpr (fuel : Nat) (expr : PsMinCoreExpr) (bytes : List Nat) : Option (List Nat) :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
    match expr with
    | .bvar index =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 105, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteNumber index byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 98, 34, 125] byteTail2)
    | .natural value =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 110, 97, 116, 34, 44, 34, 118, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteQuotedNumber value byteTail1)) (fun byteTail2 => psMinRegByteLiteral [125] byteTail2)
    | .sort level =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 115, 111, 114, 116, 34, 44, 34, 108, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteLevel level byteTail1)) (fun byteTail2 => psMinRegByteLiteral [125] byteTail2)
    | .constant name levels =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 107, 34, 58, 34, 99, 111, 110, 115, 116, 34, 44, 34, 108, 115, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteLevels levels byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4)
    | .app fn arg =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 97, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr remaining arg byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 102, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteExpr remaining fn byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 97, 112, 112, 34, 125] byteTail4)
    | .lam name binder type body =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 98, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr remaining body byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 98, 105, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteBinder binder byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 108, 97, 109, 34, 44, 34, 110, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteName name byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr remaining type byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125] byteTail8)
    | .forallE name binder type body =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 98, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr remaining body byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 98, 105, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteBinder binder byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 102, 111, 114, 97, 108, 108, 34, 44, 34, 110, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteName name byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr remaining type byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125] byteTail8)
    | .letE name type value body =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 98, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr remaining body byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 108, 101, 116, 34, 44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteExpr remaining type byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr remaining value byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125] byteTail8)
    | .projection name index value =>
      psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 101, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteExpr remaining value byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 105, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteNumber index byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 112, 114, 111, 106, 34, 44, 34, 110, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteName name byteTail5)) (fun byteTail6 => psMinRegByteLiteral [125] byteTail6)

def psMinRegByteDefinition (decl : PsMinCoreDeclaration) (bytes : List Nat) : Option (List Nat) :=
  psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 104, 34, 58, 123, 34, 104, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteQuotedNumber decl.height byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 107, 34, 58, 34, 114, 101, 103, 117, 108, 97, 114, 34, 125, 44, 34, 107, 34, 58, 34, 100, 101, 102, 105, 110, 105, 116, 105, 111, 110, 34, 44, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName decl.name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 115, 34, 58, 34, 115, 97, 102, 101, 34, 44, 34, 116, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteExpr 256 decl.type byteTail5)) (fun byteTail6 => psMinRegByteLiteral [44, 34, 118, 34, 58] byteTail6)) (fun byteTail7 => psMinRegByteExpr 256 decl.value byteTail7)) (fun byteTail8 => psMinRegByteLiteral [125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 99, 111, 110, 115, 116, 97, 110, 116, 34, 125] byteTail8)

def psMinRegByteConstructor (ctor : PsMinRegCoreConstructor) (bytes : List Nat) : Option (List Nat) :=
  psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 110, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteName ctor.name byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteExpr 256 ctor.type byteTail3)) (fun byteTail4 => psMinRegByteLiteral [125] byteTail4)

def psMinRegByteConstructorsTail (constructors : List PsMinRegCoreConstructor) (bytes : List Nat) :
    Option (List Nat) :=
  match constructors with
  | List.nil => Option.some bytes
  | List.cons ctor rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [44] byteTail0)) (fun byteTail1 => psMinRegByteConstructor ctor byteTail1)) (fun byteTail2 => psMinRegByteConstructorsTail rest byteTail2)

def psMinRegByteConstructors (constructors : List PsMinRegCoreConstructor) (bytes : List Nat) :
    Option (List Nat) :=
  match constructors with
  | List.nil => psMinRegByteLiteral [91, 93] bytes
  | List.cons ctor rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [91] byteTail0)) (fun byteTail1 => psMinRegByteConstructor ctor byteTail1)) (fun byteTail2 => psMinRegByteConstructorsTail rest byteTail2)) (fun byteTail3 => psMinRegByteLiteral [93] byteTail3)

def psMinRegByteGroup (group : PsMinRegCoreGroup) (bytes : List Nat) : Option (List Nat) :=
  psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 100, 101, 99, 108, 97, 114, 97, 116, 105, 111, 110, 34, 58, 123, 34, 108, 112, 34, 58, 91, 93, 44, 34, 110, 112, 34, 58, 48, 44, 34, 116, 115, 34, 58, 91, 123, 34, 99, 115, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteConstructors group.constructors byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 110, 34, 58] byteTail2)) (fun byteTail3 => psMinRegByteName group.name byteTail3)) (fun byteTail4 => psMinRegByteLiteral [44, 34, 116, 34, 58] byteTail4)) (fun byteTail5 => psMinRegByteExpr 256 group.type byteTail5)) (fun byteTail6 => psMinRegByteLiteral [125, 93, 125, 44, 34, 107, 105, 110, 100, 34, 58, 34, 105, 110, 100, 117, 99, 116, 105, 118, 101, 34, 125] byteTail6)

def psMinRegByteEntry (entry : PsMinRegCoreEntry) (bytes : List Nat) : Option (List Nat) :=
  match entry with
  | .definition decl => psMinRegByteDefinition decl bytes
  | .inductiveE group => psMinRegByteGroup group bytes

def psMinRegByteEntriesTail (entries : List PsMinRegCoreEntry) (bytes : List Nat) : Option (List Nat) :=
  match entries with
  | List.nil => Option.some bytes
  | List.cons entry rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [44] byteTail0)) (fun byteTail1 => psMinRegByteEntry entry byteTail1)) (fun byteTail2 => psMinRegByteEntriesTail rest byteTail2)

def psMinRegByteEntries (entries : List PsMinRegCoreEntry) (bytes : List Nat) : Option (List Nat) :=
  match entries with
  | List.nil => psMinRegByteLiteral [91, 93] bytes
  | List.cons entry rest =>
    psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [91] byteTail0)) (fun byteTail1 => psMinRegByteEntry entry byteTail1)) (fun byteTail2 => psMinRegByteEntriesTail rest byteTail2)) (fun byteTail3 => psMinRegByteLiteral [93] byteTail3)

def psMinRegBytePacket (entries : List PsMinRegCoreEntry) (bytes : List Nat) : Option (List Nat) :=
  psMinRegByteThen (psMinRegByteThen (psMinRegByteThen (Option.some bytes) (fun byteTail0 => psMinRegByteLiteral [123, 34, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 58] byteTail0)) (fun byteTail1 => psMinRegByteEntries entries byteTail1)) (fun byteTail2 => psMinRegByteLiteral [44, 34, 102, 111, 114, 109, 97, 116, 34, 58, 34, 112, 114, 111, 111, 102, 115, 99, 114, 105, 112, 116, 45, 99, 104, 101, 99, 107, 101, 100, 45, 97, 100, 109, 105, 115, 115, 105, 111, 110, 115, 34, 44, 34, 118, 101, 114, 115, 105, 111, 110, 34, 58, 50, 125] byteTail2)

def psMinRegCoreConstructorValid (ctor : PsMinRegCoreConstructor) : Bool :=
  if psMinCoreNameValid 16 ctor.name then psMinRegCoreExprValid 256 ctor.type else false

def psMinRegCoreConstructorsValid (fuel : Nat) (constructors : List PsMinRegCoreConstructor) : Bool :=
  match constructors with
  | List.nil => true
  | List.cons ctor rest => match fuel with
    | Nat.zero => false
    | Nat.succ remaining => if psMinRegCoreConstructorValid ctor then
        psMinRegCoreConstructorsValid remaining rest else false

def psMinRegCoreEntryValid (entry : PsMinRegCoreEntry) : Bool :=
  match entry with
  | .definition decl => if psMinCoreNameValid 16 decl.name then if psMinRegCoreScalarValid decl.height then
      if psMinRegCoreExprValid 256 decl.type then psMinRegCoreExprValid 256 decl.value else false else false else false
  | .inductiveE group => if psMinCoreNameValid 16 group.name then
      if psMinRegCoreExprValid 256 group.type then psMinRegCoreConstructorsValid 512 group.constructors
      else false else false

def psMinRegCoreEntriesValid (fuel : Nat) (entries : List PsMinRegCoreEntry) : Bool :=
  match entries with
  | List.nil => true
  | List.cons entry rest => match fuel with
    | Nat.zero => false
    | Nat.succ remaining => if psMinRegCoreEntryValid entry then
        psMinRegCoreEntriesValid remaining rest else false

def psMinRegCoreDecodeCertificate (bytes : List Nat) (candidate : List PsMinRegCoreEntry) :
    Option (List PsMinRegCoreEntry) :=
  if psMinByteLengthAtMost psMinRegCoreByteBudget bytes then
    if psMinRegCoreEntriesValid 512 candidate then
      match psMinRegBytePacket candidate bytes with
      | Option.none => Option.none
      | Option.some remaining => match remaining with
        | List.nil => Option.some candidate
        | List.cons _ _ => Option.none
    else Option.none
  else Option.none

structure PsMinRegCoreAdmission where
  source : List PsMinRegCoreEntry
  checked : PsMinRegCoreChecked

def psMinRegCoreAdmit (bytes : List Nat) (candidate : List PsMinRegCoreEntry) : Option PsMinRegCoreAdmission :=
  match psMinRegCoreDecodeCertificate bytes candidate with
  | Option.none => Option.none
  | Option.some source => match psMinRegCoreCheckEntries source with
    | Option.none => Option.none
    | Option.some checked => Option.some (PsMinRegCoreAdmission.mk source checked)

def psMinRegCoreMakeConstructor (name : PsMinCoreName) (type : PsMinCoreExpr) : PsMinRegCoreConstructor :=
  PsMinRegCoreConstructor.mk name type

def psMinRegCoreMakeGroup (name : PsMinCoreName) (type : PsMinCoreExpr)
    (constructors : List PsMinRegCoreConstructor) : PsMinRegCoreGroup :=
  PsMinRegCoreGroup.mk name type constructors
