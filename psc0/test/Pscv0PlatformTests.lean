import Ps.Host.NativeV7

/-!
Focused target-profile qualification. Native USize/ISize checks use the pinned
64-bit Linux toolchain. Explicit 32-bit execution is compared to Lean's
UInt32/Int32 model; it never claims to run a 32-bit Lean executable.
Both fixtures use the same cases and independently stated expected boundaries.
-/
private def platformNativeOracle : IO Unit := do
  unless System.Platform.numBits == 64 do
    throw (IO.userError "platform native oracle requires explicit 64-bit Linux host")
  let native64 : List Bool := [
    (System.Platform.numBits == 64),
    ((System.Platform.getNumBits ()).val == 64),
    (USize.size == 18446744073709551616),
    ((USize.ofNat 18446744073709551616).toNat == 0),
    ((USize.ofInt (-2)).toNat == 18446744073709551614),
    (((USize.ofNat 18446744073709551615) + 1).toNat == 0),
    ((USize.div 17 0).toNat == 0),
    ((USize.mod 17 0).toNat == 17),
    ((USize.shiftLeft 1 65).toNat == 2),
    ((ISize.shiftRight (-8) 1).toInt == -4),
    ((ISize.shiftRight ISize.minValue (-1)).toInt == -1),
    ((ISize.div ISize.minValue (-1)).toInt == -9223372036854775808),
    ((ISize.mod (-7) 3).toInt == -1),
    ((USize.pow 3 5).toNat == 243),
    ((ISize.pow (-3) 5).toInt == -243),
    ((USize.ofNatClamp 18446744073709551621).toNat == 18446744073709551615),
    ((ISize.ofIntClamp (-18446744073709551616)).toInt == -9223372036854775808),
    ((ISize.abs ISize.minValue).toInt == -9223372036854775808),
    ((USize.toUInt8 (USize.ofNat 511)).toNat == 255),
    ((UInt64.toUSize (UInt64.ofNat 4294967297)).toNat == 4294967297),
    ((ISize.toInt64 (Int8.toISize (Int8.ofInt (-7)))).toInt == -7),
    ((Float.toUSize Float.inf).toNat == 18446744073709551615),
    ((Float32.toISize Float32.nan).toInt == 0),
    ((ISize.toFloat32 (-7)).toBits.toNat == 3235905536),
    (decide ((-1 : ISize) < 1)),
    (decide (USize.ofNat 42 = USize.ofNat 42)),
    (decide (ISize.ofInt (-7) = ISize.ofInt (-7))),
    (toString (ISize.ofInt (-7)) == "-7"),
    ((hash (ISize.ofInt (-1))).toNat == 18446744073709551615)]
  let model32 : List Bool := [
    (UInt32.size == 4294967296),
    ((UInt32.ofNat 4294967296).toNat == 0),
    ((UInt32.ofInt (-2)).toNat == 4294967294),
    (((UInt32.ofNat 4294967295) + 1).toNat == 0),
    ((UInt32.div 17 0).toNat == 0),
    ((UInt32.mod 17 0).toNat == 17),
    ((UInt32.shiftLeft 1 33).toNat == 2),
    ((Int32.shiftRight (-8) 1).toInt == -4),
    ((Int32.shiftRight Int32.minValue (-1)).toInt == -1),
    ((Int32.div Int32.minValue (-1)).toInt == -2147483648),
    ((Int32.mod (-7) 3).toInt == -1),
    ((UInt32.pow 3 5).toNat == 243),
    ((Int32.pow (-3) 5).toInt == -243),
    ((UInt32.ofNatClamp 4294967301).toNat == 4294967295),
    ((Int32.ofIntClamp (-4294967296)).toInt == -2147483648),
    ((Int32.abs Int32.minValue).toInt == -2147483648),
    ((UInt32.toUInt8 (UInt32.ofNat 511)).toNat == 255),
    ((UInt64.toUInt32 (UInt64.ofNat 4294967297)).toNat == 1),
    ((Int32.toInt64 (Int8.toInt32 (Int8.ofInt (-7)))).toInt == -7),
    ((Float.toUInt32 Float.inf).toNat == 4294967295),
    ((Float32.toInt32 Float32.nan).toInt == 0),
    ((Int32.toFloat32 (-7)).toBits.toNat == 3235905536),
    (decide ((-1 : Int32) < 1)),
    (decide (UInt32.ofNat 42 = UInt32.ofNat 42)),
    (decide (Int32.ofInt (-7) = Int32.ofInt (-7))),
    (toString (Int32.ofInt (-7)) == "-7"),
    ((hash (Int32.ofInt (-1))).toNat == 4294967295)]
  unless native64.all id && model32.all id do
    throw (IO.userError "PSCV0_PLATFORM_ORACLE: pinned native/model mismatch")
  IO.println "PSCV0_PLATFORM_ORACLE: PASS native64 and fixed32 independent contracts"

private def platformSource32 : String :=
  "const checkWidth: Bool := Nat.beq(System.Platform.numBits, 32)\nconst checkGetWidth: Bool := Nat.beq((System.Platform.getNumBits(())).val, 32)\nconst checkSize: Bool := Nat.beq(USize.size, 4294967296)\nconst checkWrap: Bool := Nat.beq(USize.toNat(USize.ofNat(4294967296)), 0)\nconst checkNegative: Bool := Nat.beq(USize.toNat(USize.ofInt(-2)), 4294967294)\nconst checkAdd: Bool := Nat.beq(USize.toNat(USize.ofNat(4294967295) + 1), 0)\nconst checkDivision: Bool := Nat.beq(USize.toNat(USize.div(17, 0)), 0)\nconst checkRemainder: Bool := Nat.beq(USize.toNat(USize.mod(17, 0)), 17)\nconst checkShift: Bool := Nat.beq(USize.toNat(USize.shiftLeft(1, 33)), 2)\nconst checkSignedShift: Bool := if (ISize.toInt(ISize.shiftRight(-8, 1)) = -4) { true } else { false }\nconst checkNegativeShift: Bool := if (ISize.toInt(ISize.shiftRight(ISize.minValue, -1)) = -1) { true } else { false }\nconst checkMinDivision: Bool := if (ISize.toInt(ISize.div(ISize.minValue, -1)) = -2147483648) { true } else { false }\nconst checkSignedRemainder: Bool := if (ISize.toInt(ISize.mod(-7, 3)) = -1) { true } else { false }\nconst checkPower: Bool := Nat.beq(USize.toNat(USize.pow(3, 5)), 243)\nconst checkSignedPower: Bool := if (ISize.toInt(ISize.pow(-3, 5)) = -243) { true } else { false }\nconst checkClamp: Bool := Nat.beq(USize.toNat(USize.ofNatClamp(4294967301)), 4294967295)\nconst checkSignedClamp: Bool := if (ISize.toInt(ISize.ofIntClamp(-4294967296)) = -2147483648) { true } else { false }\nconst checkAbs: Bool := if (ISize.toInt(ISize.abs(ISize.minValue)) = -2147483648) { true } else { false }\nconst checkNarrow: Bool := Nat.beq(UInt8.toNat(USize.toUInt8(USize.ofNat(511))), 255)\nconst checkWide: Bool := Nat.beq(USize.toNat(UInt64.toUSize(UInt64.ofNat(4294967297))), 1)\nconst checkSignExtend: Bool := if (Int64.toInt(ISize.toInt64(Int8.toISize(Int8.ofInt(-7)))) = -7) { true } else { false }\nconst checkFloatSaturation: Bool := Nat.beq(USize.toNat(Float.toUSize(Float.inf)), 4294967295)\nconst checkFloatNaN: Bool := if (ISize.toInt(Float32.toISize(Float32.nan)) = 0) { true } else { false }\nconst checkFloatNegative: Bool := Nat.beq(UInt32.toNat(Float32.toBits(ISize.toFloat32(-7))), 3235905536)\nconst checkOrder: Bool := if ((-1 : ISize) < (1 : ISize)) { true } else { false }\nconst checkEquality: Bool := if (USize.ofNat(42) = USize.ofNat(42)) { true } else { false }\nconst checkSignedEquality: Bool := if (ISize.ofInt(-7) = ISize.ofInt(-7)) { true } else { false }\nconst checkDisplay: Bool := if (toString(ISize.ofInt(-7)) = \"-7\") { true } else { false }\nconst checkHash: Bool := Nat.beq(UInt64.toNat(hash(ISize.ofInt(-1))), 4294967295)\nfunction genericAdd{A: Type}[Add A](a: A, b: A): A := a + b\nfunction applyWord(f: Int -> USize, n: Int): USize := f(n)\nfunction captureWord(x: USize): USize -> USize := fun y => x + y\nstructure WordPair where { unsigned: USize\n signed: ISize }\nfunction pairValue(p: WordPair): USize := p.unsigned\nconst checkGeneric: Bool := Nat.beq(USize.toNat(genericAdd(USize.ofNat(4294967295), 1)), 0)\nconst checkPartial: Bool := Nat.beq(USize.toNat(applyWord(USize.ofInt, -1)), 4294967295)\nconst checkCapture: Bool := Nat.beq(USize.toNat(captureWord(USize.ofNat(4294967295))(1)), 0)\nconst checkRecord: Bool := Nat.beq(USize.toNat(pairValue(WordPair.mk(17, -7))), 17)\nconst checkModel: Bool := Nat.beq(USize.toNat(USize.ofBitVec(USize.toBitVec(USize.ofInt(-1)))), 4294967295)\nconst checkRepr: Bool := if (Std.Format.pretty(reprPrec(ISize.ofInt(-7), 1024)) = \"(-7)\") { true } else { false }\nfunction echoUnsigned(value: USize): USize := value\nfunction echoSigned(value: ISize): ISize := value\n"

private def platformSource64 : String :=
  "const checkWidth: Bool := Nat.beq(System.Platform.numBits, 64)\nconst checkGetWidth: Bool := Nat.beq((System.Platform.getNumBits(())).val, 64)\nconst checkSize: Bool := Nat.beq(USize.size, 18446744073709551616)\nconst checkWrap: Bool := Nat.beq(USize.toNat(USize.ofNat(18446744073709551616)), 0)\nconst checkNegative: Bool := Nat.beq(USize.toNat(USize.ofInt(-2)), 18446744073709551614)\nconst checkAdd: Bool := Nat.beq(USize.toNat(USize.ofNat(18446744073709551615) + 1), 0)\nconst checkDivision: Bool := Nat.beq(USize.toNat(USize.div(17, 0)), 0)\nconst checkRemainder: Bool := Nat.beq(USize.toNat(USize.mod(17, 0)), 17)\nconst checkShift: Bool := Nat.beq(USize.toNat(USize.shiftLeft(1, 65)), 2)\nconst checkSignedShift: Bool := if (ISize.toInt(ISize.shiftRight(-8, 1)) = -4) { true } else { false }\nconst checkNegativeShift: Bool := if (ISize.toInt(ISize.shiftRight(ISize.minValue, -1)) = -1) { true } else { false }\nconst checkMinDivision: Bool := if (ISize.toInt(ISize.div(ISize.minValue, -1)) = -9223372036854775808) { true } else { false }\nconst checkSignedRemainder: Bool := if (ISize.toInt(ISize.mod(-7, 3)) = -1) { true } else { false }\nconst checkPower: Bool := Nat.beq(USize.toNat(USize.pow(3, 5)), 243)\nconst checkSignedPower: Bool := if (ISize.toInt(ISize.pow(-3, 5)) = -243) { true } else { false }\nconst checkClamp: Bool := Nat.beq(USize.toNat(USize.ofNatClamp(18446744073709551621)), 18446744073709551615)\nconst checkSignedClamp: Bool := if (ISize.toInt(ISize.ofIntClamp(-18446744073709551616)) = -9223372036854775808) { true } else { false }\nconst checkAbs: Bool := if (ISize.toInt(ISize.abs(ISize.minValue)) = -9223372036854775808) { true } else { false }\nconst checkNarrow: Bool := Nat.beq(UInt8.toNat(USize.toUInt8(USize.ofNat(511))), 255)\nconst checkWide: Bool := Nat.beq(USize.toNat(UInt64.toUSize(UInt64.ofNat(4294967297))), 4294967297)\nconst checkSignExtend: Bool := if (Int64.toInt(ISize.toInt64(Int8.toISize(Int8.ofInt(-7)))) = -7) { true } else { false }\nconst checkFloatSaturation: Bool := Nat.beq(USize.toNat(Float.toUSize(Float.inf)), 18446744073709551615)\nconst checkFloatNaN: Bool := if (ISize.toInt(Float32.toISize(Float32.nan)) = 0) { true } else { false }\nconst checkFloatNegative: Bool := Nat.beq(UInt32.toNat(Float32.toBits(ISize.toFloat32(-7))), 3235905536)\nconst checkOrder: Bool := if ((-1 : ISize) < (1 : ISize)) { true } else { false }\nconst checkEquality: Bool := if (USize.ofNat(42) = USize.ofNat(42)) { true } else { false }\nconst checkSignedEquality: Bool := if (ISize.ofInt(-7) = ISize.ofInt(-7)) { true } else { false }\nconst checkDisplay: Bool := if (toString(ISize.ofInt(-7)) = \"-7\") { true } else { false }\nconst checkHash: Bool := Nat.beq(UInt64.toNat(hash(ISize.ofInt(-1))), 18446744073709551615)\nfunction genericAdd{A: Type}[Add A](a: A, b: A): A := a + b\nfunction applyWord(f: Int -> USize, n: Int): USize := f(n)\nfunction captureWord(x: USize): USize -> USize := fun y => x + y\nstructure WordPair where { unsigned: USize\n signed: ISize }\nfunction pairValue(p: WordPair): USize := p.unsigned\nconst checkGeneric: Bool := Nat.beq(USize.toNat(genericAdd(USize.ofNat(18446744073709551615), 1)), 0)\nconst checkPartial: Bool := Nat.beq(USize.toNat(applyWord(USize.ofInt, -1)), 18446744073709551615)\nconst checkCapture: Bool := Nat.beq(USize.toNat(captureWord(USize.ofNat(18446744073709551615))(1)), 0)\nconst checkRecord: Bool := Nat.beq(USize.toNat(pairValue(WordPair.mk(17, -7))), 17)\nconst checkModel: Bool := Nat.beq(USize.toNat(USize.ofBitVec(USize.toBitVec(USize.ofInt(-1)))), 18446744073709551615)\nconst checkRepr: Bool := if (Std.Format.pretty(reprPrec(ISize.ofInt(-7), 1024)) = \"(-7)\") { true } else { false }\nfunction echoUnsigned(value: USize): USize := value\nfunction echoSigned(value: ISize): ISize := value\n"

def platformWordCases : IO Unit := do
  platformNativeOracle
  let transport := "function identity(value: USize): USize := value\n"
  let requests : Array PsV7Native.Request := #[
    { source := transport },
    { source := transport, targets := [.javascript] },
    { source := "const width: Nat := System.Platform.numBits\n", targets := [.javascript] },
    { source := "theorem bad: System.Platform.numBits = 64 := by { rfl }\n",
      targetWordSize := some .bits64 }]
  let .ok batch ← PsV7Native.runBatch requests
    | throw (IO.userError "platform refusal batch initialization failed")
  unless batch.results.size == 4 && batch.results[0]!.isOk do
    throw (IO.userError "abstract platform transport must check without an execution profile")
  for i in [1,2] do
    match batch.results[i]! with
    | .error error =>
      unless error.phase == "erase" && error.message.startsWith "PSCV0-ERASURE: explicit target word size" do
        throw (IO.userError ("platform refusal phase: " ++ error.message))
    | .ok _ => throw (IO.userError "unprofiled platform execution accepted")
  match batch.results[3]! with
  | .error error =>
    unless error.phase == "elaborate" || error.phase == "kernel" do
      throw (IO.userError ("unexpected platform proof refusal phase: " ++ error.phase))
  | .ok _ => throw (IO.userError "execution width leaked into logical reduction")
  let root : System.FilePath := "../dist/pscv0-native/platform"
  IO.FS.createDirAll root
  IO.FS.writeFile (root / "words32.ps") platformSource32
  IO.FS.writeFile (root / "words64.ps") platformSource64
  IO.FS.writeFile (root / "checks.json")
    (Lean.toJson (["checkWidth", "checkGetWidth", "checkSize", "checkWrap", "checkNegative", "checkAdd", "checkDivision", "checkRemainder", "checkShift", "checkSignedShift", "checkNegativeShift", "checkMinDivision", "checkSignedRemainder", "checkPower", "checkSignedPower", "checkClamp", "checkSignedClamp", "checkAbs", "checkNarrow", "checkWide", "checkSignExtend", "checkFloatSaturation", "checkFloatNaN", "checkFloatNegative", "checkOrder", "checkEquality", "checkSignedEquality", "checkDisplay", "checkHash", "checkGeneric", "checkPartial", "checkCapture", "checkRecord", "checkModel", "checkRepr"] : List String)).compress
  IO.FS.writeFile (root / "exports.json")
    (Lean.toJson (["checkWidth", "checkGetWidth", "checkSize", "checkWrap", "checkNegative", "checkAdd", "checkDivision", "checkRemainder", "checkShift", "checkSignedShift", "checkNegativeShift", "checkMinDivision", "checkSignedRemainder", "checkPower", "checkSignedPower", "checkClamp", "checkSignedClamp", "checkAbs", "checkNarrow", "checkWide", "checkSignExtend", "checkFloatSaturation", "checkFloatNaN", "checkFloatNegative", "checkOrder", "checkEquality", "checkSignedEquality", "checkDisplay", "checkHash", "checkGeneric", "checkPartial", "checkCapture", "checkRecord", "checkModel", "checkRepr", "echoUnsigned", "echoSigned"] : List String)).compress
  IO.println "PSCV0_PLATFORM_BOUNDARY: PASS abstract checking, explicit execution and opaque width refusal"
