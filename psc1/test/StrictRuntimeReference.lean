import Lean

-- Independent native Lean 4.34 reference. This file does not import PSC0,
-- its IR checker, erasure, emitted JavaScript, or host conformance helpers.
-- Run once with: lake env lean --run test/StrictRuntimeReference.lean
-- Each observation uses the pinned Lean primitive/reference implementation.
-- Proof-required array cases below have actual in-bounds proofs; defensive
-- invalid-bounds JS probes are deliberately not represented as Lean values.
open Lean

private def mixedText : String :=
  String.ofList [
    Char.ofNat 65, Char.ofNat 233, Char.ofNat 20013, Char.ofNat 128512,
    Char.ofNat 0, Char.ofNat 101, Char.ofNat 769
  ]

private def observation (id operation resultType : String) (value : Json) : Json :=
  Json.mkObj [
    ("id", Json.str id), ("operation", Json.str operation),
    ("resultType", Json.str resultType), ("value", value)
  ]

private def observeNat (id operation : String) (value : Nat) : Json :=
  observation id operation "nat" (Json.str (toString value))

private def observeInt (id operation : String) (value : Int) : Json :=
  observation id operation "int" (Json.str (Int.repr value))

private def observeBool (id operation : String) (value : Bool) : Json :=
  observation id operation "bool" (Json.bool value)

private def observeChar (id operation : String) (value : Char) : Json :=
  observation id operation "char" (Json.str (toString (Char.toNat value)))

private def observeString (id operation : String) (value : String) : Json :=
  observation id operation "string" (Json.str value)

private def observeUnit (id operation : String) (_value : Unit) : Json :=
  observation id operation "unit" (Json.str "unit")

private def observeNatArray (id operation : String) (value : Array Nat) : Json :=
  observation id operation "arrayNat"
    (Json.arr (value.map (fun item => Json.str (toString item))))

private def observeUnitArray (id operation : String) (value : Array Unit) : Json :=
  observation id operation "arrayUnit"
    (Json.arr (value.map (fun _ => Json.str "unit")))

private def observations : Array Json := #[
  observeNat "natAdd.large" "natAdd"
    (Nat.add (900719925474099312345678901234567890 : Nat) (17 : Nat)),
  observeNat "natAdd.zero" "natAdd"
    (Nat.add (0 : Nat) (0 : Nat)),
  observeNat "natSub.truncate" "natSub"
    (Nat.sub (2 : Nat) (5 : Nat)),
  observeNat "natSub.equal" "natSub"
    (Nat.sub (5 : Nat) (5 : Nat)),
  observeNat "natSub.large" "natSub"
    (Nat.sub (900719925474099312345678901234567890 : Nat) (7 : Nat)),
  observeNat "natMul.large" "natMul"
    (Nat.mul (900719925474099312345678901234567890 : Nat) (9 : Nat)),
  observeNat "natMul.zero" "natMul"
    (Nat.mul (0 : Nat) (900719925474099312345678901234567890 : Nat)),
  observeNat "natDiv.ordinary" "natDiv"
    (Nat.div (17 : Nat) (5 : Nat)),
  observeNat "natDiv.zero-divisor" "natDiv"
    (Nat.div (900719925474099312345678901234567890 : Nat) (0 : Nat)),
  observeNat "natDiv.large" "natDiv"
    (Nat.div (900719925474099312345678901234567890 : Nat) (11 : Nat)),
  observeNat "natMod.ordinary" "natMod"
    (Nat.mod (17 : Nat) (5 : Nat)),
  observeNat "natMod.zero-divisor" "natMod"
    (Nat.mod (900719925474099312345678901234567890 : Nat) (0 : Nat)),
  observeNat "natMod.large" "natMod"
    (Nat.mod (900719925474099312345678901234567890 : Nat) (11 : Nat)),
  observeBool "natEq.equal" "natEq"
    (decide ((900719925474099312345678901234567890 : Nat) = (900719925474099312345678901234567890 : Nat))),
  observeBool "natEq.ordered" "natEq"
    (decide ((3 : Nat) = (5 : Nat))),
  observeBool "natEq.reversed" "natEq"
    (decide ((5 : Nat) = (3 : Nat))),
  observeBool "natNe.equal" "natNe"
    (decide ((900719925474099312345678901234567890 : Nat) ≠ (900719925474099312345678901234567890 : Nat))),
  observeBool "natNe.ordered" "natNe"
    (decide ((3 : Nat) ≠ (5 : Nat))),
  observeBool "natNe.reversed" "natNe"
    (decide ((5 : Nat) ≠ (3 : Nat))),
  observeBool "natLe.equal" "natLe"
    (decide ((900719925474099312345678901234567890 : Nat) ≤ (900719925474099312345678901234567890 : Nat))),
  observeBool "natLe.ordered" "natLe"
    (decide ((3 : Nat) ≤ (5 : Nat))),
  observeBool "natLe.reversed" "natLe"
    (decide ((5 : Nat) ≤ (3 : Nat))),
  observeBool "natLt.equal" "natLt"
    (decide ((900719925474099312345678901234567890 : Nat) < (900719925474099312345678901234567890 : Nat))),
  observeBool "natLt.ordered" "natLt"
    (decide ((3 : Nat) < (5 : Nat))),
  observeBool "natLt.reversed" "natLt"
    (decide ((5 : Nat) < (3 : Nat))),
  observeInt "intOfNat.large" "intOfNat"
    (Int.ofNat (900719925474099312345678901234567890 : Nat)),
  observeString "intRepr.negative" "intRepr"
    (Int.repr (-900719925474099312345678901234567890 : Int)),
  observeString "intRepr.zero" "intRepr"
    (Int.repr (0 : Int)),
  observeInt "intNegSucc.zero" "intNegSucc"
    (Int.negSucc (0 : Nat)),
  observeInt "intNegSucc.large" "intNegSucc"
    (Int.negSucc (900719925474099312345678901234567890 : Nat)),
  observeInt "intNeg.negative" "intNeg"
    (Int.neg (-900719925474099312345678901234567890 : Int)),
  observeInt "intNeg.zero" "intNeg"
    (Int.neg (0 : Int)),
  observeInt "intAdd.mixed" "intAdd"
    (Int.add (-900719925474099312345678901234567890 : Int) (17 : Int)),
  observeInt "intSub.negative" "intSub"
    (Int.sub (-3 : Int) (5 : Int)),
  observeInt "intMul.negative" "intMul"
    (Int.mul (-900719925474099312345678901234567890 : Int) (7 : Int)),
  observeBool "intEq.equal" "intEq"
    (decide ((-7 : Int) = (-7 : Int))),
  observeBool "intEq.ordered" "intEq"
    (decide ((-7 : Int) = (3 : Int))),
  observeBool "intEq.reversed" "intEq"
    (decide ((3 : Int) = (-7 : Int))),
  observeBool "intLe.equal" "intLe"
    (decide ((-7 : Int) ≤ (-7 : Int))),
  observeBool "intLe.ordered" "intLe"
    (decide ((-7 : Int) ≤ (3 : Int))),
  observeBool "intLe.reversed" "intLe"
    (decide ((3 : Int) ≤ (-7 : Int))),
  observeBool "intLt.equal" "intLt"
    (decide ((-7 : Int) < (-7 : Int))),
  observeBool "intLt.ordered" "intLt"
    (decide ((-7 : Int) < (3 : Int))),
  observeBool "intLt.reversed" "intLt"
    (decide ((3 : Int) < (-7 : Int))),
  observeBool "boolNot.false" "boolNot"
    (Bool.not false),
  observeBool "boolNot.true" "boolNot"
    (Bool.not true),
  observeBool "boolAnd.false.false" "boolAnd"
    (false && false),
  observeBool "boolAnd.false.true" "boolAnd"
    (false && true),
  observeBool "boolAnd.true.false" "boolAnd"
    (true && false),
  observeBool "boolAnd.true.true" "boolAnd"
    (true && true),
  observeBool "boolOr.false.false" "boolOr"
    (false || false),
  observeBool "boolOr.false.true" "boolOr"
    (false || true),
  observeBool "boolOr.true.false" "boolOr"
    (true || false),
  observeBool "boolOr.true.true" "boolOr"
    (true || true),
  observeBool "boolEq.false.false" "boolEq"
    (decide (false = false)),
  observeBool "boolEq.false.true" "boolEq"
    (decide (false = true)),
  observeBool "boolEq.true.false" "boolEq"
    (decide (true = false)),
  observeBool "boolEq.true.true" "boolEq"
    (decide (true = true)),
  observeBool "boolNe.false.false" "boolNe"
    (decide (false ≠ false)),
  observeBool "boolNe.false.true" "boolNe"
    (decide (false ≠ true)),
  observeBool "boolNe.true.false" "boolNe"
    (decide (true ≠ false)),
  observeBool "boolNe.true.true" "boolNe"
    (decide (true ≠ true)),
  observeChar "charOfNat.0" "charOfNat"
    (Char.ofNat (0 : Nat)),
  observeChar "charOfNat.65" "charOfNat"
    (Char.ofNat (65 : Nat)),
  observeChar "charOfNat.127" "charOfNat"
    (Char.ofNat (127 : Nat)),
  observeChar "charOfNat.128" "charOfNat"
    (Char.ofNat (128 : Nat)),
  observeChar "charOfNat.2047" "charOfNat"
    (Char.ofNat (2047 : Nat)),
  observeChar "charOfNat.2048" "charOfNat"
    (Char.ofNat (2048 : Nat)),
  observeChar "charOfNat.55295" "charOfNat"
    (Char.ofNat (55295 : Nat)),
  observeChar "charOfNat.55296" "charOfNat"
    (Char.ofNat (55296 : Nat)),
  observeChar "charOfNat.57343" "charOfNat"
    (Char.ofNat (57343 : Nat)),
  observeChar "charOfNat.57344" "charOfNat"
    (Char.ofNat (57344 : Nat)),
  observeChar "charOfNat.65535" "charOfNat"
    (Char.ofNat (65535 : Nat)),
  observeChar "charOfNat.65536" "charOfNat"
    (Char.ofNat (65536 : Nat)),
  observeChar "charOfNat.1114111" "charOfNat"
    (Char.ofNat (1114111 : Nat)),
  observeChar "charOfNat.1114112" "charOfNat"
    (Char.ofNat (1114112 : Nat)),
  observeChar "charOfNat.900719925474099312345678901234567890" "charOfNat"
    (Char.ofNat (900719925474099312345678901234567890 : Nat)),
  observeNat "charToNat.0" "charToNat"
    (Char.toNat (Char.ofNat 0)),
  observeNat "charToNat.65" "charToNat"
    (Char.toNat (Char.ofNat 65)),
  observeNat "charToNat.128" "charToNat"
    (Char.toNat (Char.ofNat 128)),
  observeNat "charToNat.2048" "charToNat"
    (Char.toNat (Char.ofNat 2048)),
  observeNat "charToNat.128512" "charToNat"
    (Char.toNat (Char.ofNat 128512)),
  observeNat "charToNat.1114111" "charToNat"
    (Char.toNat (Char.ofNat 1114111)),
  observeString "stringPush.nul" "stringPush"
    (String.push mixedText (Char.ofNat 0)),
  observeString "stringSingleton.astral" "stringSingleton"
    (String.singleton (Char.ofNat 128512)),
  observeNat "stringLength.empty" "stringLength"
    (String.Internal.length ""),
  observeNat "stringUtf8ByteSize.empty" "stringUtf8ByteSize"
    (String.utf8ByteSize ""),
  observeNat "stringLength.mixed" "stringLength"
    (String.Internal.length mixedText),
  observeNat "stringUtf8ByteSize.mixed" "stringUtf8ByteSize"
    (String.utf8ByteSize mixedText),
  observeString "stringAppend.boundary" "stringAppend"
    (String.Internal.append (String.ofList [(Char.ofNat 233)]) (String.ofList [(Char.ofNat 128512), (Char.ofNat 101), (Char.ofNat 769)])),
  observeBool "stringEq.equal" "stringEq"
    (decide (mixedText = mixedText)),
  observeBool "stringEq.no-normalization" "stringEq"
    (decide ((String.ofList [(Char.ofNat 233)]) = (String.ofList [(Char.ofNat 101), (Char.ofNat 769)]))),
  observeChar "stringGet.0" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (0 : Nat))),
  observeNat "stringNext.0" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (0 : Nat))).byteIdx),
  observeBool "stringAtEnd.0" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (0 : Nat))),
  observeChar "stringGet.1" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (1 : Nat))),
  observeNat "stringNext.1" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (1 : Nat))).byteIdx),
  observeBool "stringAtEnd.1" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (1 : Nat))),
  observeChar "stringGet.2" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (2 : Nat))),
  observeNat "stringNext.2" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (2 : Nat))).byteIdx),
  observeBool "stringAtEnd.2" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (2 : Nat))),
  observeChar "stringGet.3" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (3 : Nat))),
  observeNat "stringNext.3" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (3 : Nat))).byteIdx),
  observeBool "stringAtEnd.3" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (3 : Nat))),
  observeChar "stringGet.4" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (4 : Nat))),
  observeNat "stringNext.4" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (4 : Nat))).byteIdx),
  observeBool "stringAtEnd.4" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (4 : Nat))),
  observeChar "stringGet.5" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (5 : Nat))),
  observeNat "stringNext.5" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (5 : Nat))).byteIdx),
  observeBool "stringAtEnd.5" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (5 : Nat))),
  observeChar "stringGet.6" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (6 : Nat))),
  observeNat "stringNext.6" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (6 : Nat))).byteIdx),
  observeBool "stringAtEnd.6" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (6 : Nat))),
  observeChar "stringGet.7" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (7 : Nat))),
  observeNat "stringNext.7" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (7 : Nat))).byteIdx),
  observeBool "stringAtEnd.7" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (7 : Nat))),
  observeChar "stringGet.8" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (8 : Nat))),
  observeNat "stringNext.8" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (8 : Nat))).byteIdx),
  observeBool "stringAtEnd.8" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (8 : Nat))),
  observeChar "stringGet.9" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (9 : Nat))),
  observeNat "stringNext.9" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (9 : Nat))).byteIdx),
  observeBool "stringAtEnd.9" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (9 : Nat))),
  observeChar "stringGet.10" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (10 : Nat))),
  observeNat "stringNext.10" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (10 : Nat))).byteIdx),
  observeBool "stringAtEnd.10" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (10 : Nat))),
  observeChar "stringGet.11" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (11 : Nat))),
  observeNat "stringNext.11" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (11 : Nat))).byteIdx),
  observeBool "stringAtEnd.11" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (11 : Nat))),
  observeChar "stringGet.12" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (12 : Nat))),
  observeNat "stringNext.12" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (12 : Nat))).byteIdx),
  observeBool "stringAtEnd.12" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (12 : Nat))),
  observeChar "stringGet.13" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (13 : Nat))),
  observeNat "stringNext.13" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (13 : Nat))).byteIdx),
  observeBool "stringAtEnd.13" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (13 : Nat))),
  observeChar "stringGet.14" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (14 : Nat))),
  observeNat "stringNext.14" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (14 : Nat))).byteIdx),
  observeBool "stringAtEnd.14" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (14 : Nat))),
  observeChar "stringGet.15" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (15 : Nat))),
  observeNat "stringNext.15" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (15 : Nat))).byteIdx),
  observeBool "stringAtEnd.15" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (15 : Nat))),
  observeChar "stringGet.900719925474099312345678901234567890" "stringGet"
    (String.Internal.get mixedText (String.Pos.Raw.mk (900719925474099312345678901234567890 : Nat))),
  observeNat "stringNext.900719925474099312345678901234567890" "stringNext"
    ((String.Internal.next mixedText (String.Pos.Raw.mk (900719925474099312345678901234567890 : Nat))).byteIdx),
  observeBool "stringAtEnd.900719925474099312345678901234567890" "stringAtEnd"
    (String.Internal.atEnd mixedText (String.Pos.Raw.mk (900719925474099312345678901234567890 : Nat))),
  observeString "stringExtract.0.1" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (0 : Nat)) (String.Pos.Raw.mk (1 : Nat))),
  observeString "stringExtract.1.3" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (1 : Nat)) (String.Pos.Raw.mk (3 : Nat))),
  observeString "stringExtract.3.6" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (3 : Nat)) (String.Pos.Raw.mk (6 : Nat))),
  observeString "stringExtract.6.10" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (6 : Nat)) (String.Pos.Raw.mk (10 : Nat))),
  observeString "stringExtract.0.14" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (0 : Nat)) (String.Pos.Raw.mk (14 : Nat))),
  observeString "stringExtract.1.2" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (1 : Nat)) (String.Pos.Raw.mk (2 : Nat))),
  observeString "stringExtract.2.900719925474099312345678901234567890" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (2 : Nat)) (String.Pos.Raw.mk (900719925474099312345678901234567890 : Nat))),
  observeString "stringExtract.0.900719925474099312345678901234567890" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (0 : Nat)) (String.Pos.Raw.mk (900719925474099312345678901234567890 : Nat))),
  observeString "stringExtract.900719925474099312345678901234567890.900719925474099312345678901234567891" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (900719925474099312345678901234567890 : Nat)) (String.Pos.Raw.mk (900719925474099312345678901234567891 : Nat))),
  observeString "stringExtract.6.3" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (6 : Nat)) (String.Pos.Raw.mk (3 : Nat))),
  observeString "stringExtract.6.6" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (6 : Nat)) (String.Pos.Raw.mk (6 : Nat))),
  observeString "stringExtract.14.15" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (14 : Nat)) (String.Pos.Raw.mk (15 : Nat))),
  observeString "stringExtract.0.0" "stringExtract"
    (String.Internal.extract mixedText (String.Pos.Raw.mk (0 : Nat)) (String.Pos.Raw.mk (0 : Nat))),
  observeNatArray "arrayEmptyWithCapacity.zero" "arrayEmptyWithCapacity"
    (Array.emptyWithCapacity (α := Nat) (0 : Nat)),
  observeNatArray "arrayEmptyWithCapacity.bounded" "arrayEmptyWithCapacity"
    (Array.emptyWithCapacity (α := Nat) (17 : Nat)),
  observeNat "arraySize.three" "arraySize"
    (Array.size (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat)),
  observeNat "arraySize.empty" "arraySize"
    (Array.size (#[] : Array Nat)),
  observeNatArray "arrayPush.large" "arrayPush"
    (Array.push (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (900719925474099312345678901234567890 : Nat)),
  observeNatArray "arrayPush.empty" "arrayPush"
    (Array.push (#[] : Array Nat) (7 : Nat)),
  observeNat "arrayGet.0" "arrayGet"
    (Array.getInternal (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (0 : Nat) (by decide)),
  observeNat "arrayGet.2" "arrayGet"
    (Array.getInternal (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (2 : Nat) (by decide)),
  observeNat "arrayGetD.1" "arrayGetD"
    (Array.getD (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (1 : Nat) (99 : Nat)),
  observeNat "arrayGetD.3" "arrayGetD"
    (Array.getD (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (3 : Nat) (99 : Nat)),
  observeNat "arrayGetD.900719925474099312345678901234567890" "arrayGetD"
    (Array.getD (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (900719925474099312345678901234567890 : Nat) (99 : Nat)),
  observeNat "arrayGetD.empty" "arrayGetD"
    (Array.getD (#[] : Array Nat) (0 : Nat) (99 : Nat)),
  observeNatArray "arraySet.0" "arraySet"
    (Array.set (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (0 : Nat) (9 : Nat) (by decide)),
  observeNatArray "arraySet.2" "arraySet"
    (Array.set (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (2 : Nat) (9 : Nat) (by decide)),
  observeNatArray "arraySetIfInBounds.1" "arraySetIfInBounds"
    (Array.setIfInBounds (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (1 : Nat) (9 : Nat)),
  observeNatArray "arraySetIfInBounds.3" "arraySetIfInBounds"
    (Array.setIfInBounds (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (3 : Nat) (9 : Nat)),
  observeNatArray "arraySetIfInBounds.900719925474099312345678901234567890" "arraySetIfInBounds"
    (Array.setIfInBounds (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (900719925474099312345678901234567890 : Nat) (9 : Nat)),
  observeNatArray "arraySetIfInBounds.empty" "arraySetIfInBounds"
    (Array.setIfInBounds (#[] : Array Nat) (0 : Nat) (9 : Nat)),
  observeNatArray "arrayMap.three" "arrayMap"
    (Array.map (fun (value : Nat) => Nat.add value 10) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat)),
  observeNatArray "arrayMap.empty" "arrayMap"
    (Array.map (fun (value : Nat) => Nat.add value 10) (#[] : Array Nat)),
  observeNat "arrayFoldl.0.3" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (0 : Nat) (3 : Nat)),
  observeNat "arrayFoldl.1.3" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (1 : Nat) (3 : Nat)),
  observeNat "arrayFoldl.0.900719925474099312345678901234567890" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (0 : Nat) (900719925474099312345678901234567890 : Nat)),
  observeNat "arrayFoldl.3.900719925474099312345678901234567890" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (3 : Nat) (900719925474099312345678901234567890 : Nat)),
  observeNat "arrayFoldl.2.1" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (2 : Nat) (1 : Nat)),
  observeNat "arrayFoldl.0.0" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[(1 : Nat), (2 : Nat), (3 : Nat)] : Array Nat) (0 : Nat) (0 : Nat)),
  observeNat "arrayFoldl.empty" "arrayFoldl"
    (Array.foldl (fun (acc value : Nat) => Nat.add (Nat.mul acc 10) value) (7 : Nat) (#[] : Array Nat) (0 : Nat) (900719925474099312345678901234567890 : Nat)),
  observeUnit "arrayGet.unit" "arrayGet"
    (Array.getInternal (#[(), ()] : Array Unit) (1 : Nat) (by decide)),
  observeUnit "arrayGetD.unit-fallback" "arrayGetD"
    (Array.getD (#[] : Array Unit) (0 : Nat) ()),
  observeUnitArray "arraySet.unit" "arraySet"
    (Array.set (#[(), ()] : Array Unit) (0 : Nat) () (by decide))
]

def main : IO Unit := do
  let receipt := Json.mkObj [
    ("schemaVersion", toJson (1 : Nat)),
    ("kind", Json.str "psc0-native-enabled-runtime-reference"),
    ("status", Json.str "reference-produced"),
    ("contractVersion", Json.str "PSC0-TSJS-runtime/1"),
    ("contractSha256", Json.str "21a9272d9d9a68ca67041a705cc049f02d4ccdf8fc258666dc59cce8c428db89"),
    ("leanVersion", Json.str Lean.versionStringCore),
    ("leanGitHash", Json.str Lean.githash),
    ("operationCount", toJson (45 : Nat)),
    ("observationCount", toJson observations.size),
    ("observations", Json.arr observations),
    ("sourceProofProvenanceReconstructed", Json.bool false),
    ("strictSh1Qualified", Json.bool false)
  ]
  IO.println ("PSC0_SH1_STRICT_NATIVE_REFERENCE: " ++ receipt.compress)
