import Ps.Host.NativeV7
import Ps.BackendWasm.Natural

namespace PsWasm

-- Focused compatibility fixture: a GC allocation/read lies on the executed
-- path of a lifted component export. No JS semantic imports or WAT assembler.
def gcComponentProbe : ScalarComponent := {
  core := { psWasmModuleEmpty with
    structures := [{
      name := "CapturedValue", superType := none, isFinal := true,
      fields := [{ name := "value", storageType := .value .i32 }] }]
    functions := [{
      name := "readCaptured", typeName := none, parameters := [.i32], results := [.i32], locals := [],
      body := [.localGet 0, .structNew "CapturedValue", .structGet "CapturedValue" 0] }]
    exports := [("readCaptured", "readCaptured")] }
  locals := [("readCaptured", ["value"])]
  exports := [{
    sourceName := "readCaptured", foreignName := "read-captured",
    parameters := [("value", .u32)], result := some .u32 }] }

-- One runtime qualification fixture covers limb carries/borrows, multiplication,
-- quotient/remainder and Lean's total division-by-zero semantics. The expected
-- values come from native Lean Nat; the generated functions execute GC arithmetic.
def naturalComponentProbe : Except String ScalarComponent := do
  let runtime ← naturalRuntime
  let large := 2^64 - 1
  let dividend := 2^130 + 5
  let divisor := 2^65 + 1
  let cases : List (String × String × Nat × Nat × Nat) := [
    ("checkCarry", "add", large, 1, large + 1),
    ("checkBorrow", "sub", 2^64, 1, large),
    ("checkSaturating", "sub", 1, large, 0),
    ("checkProduct", "mul", large, large, large * large),
    ("checkQuotient", "div", dividend, divisor, dividend / divisor),
    ("checkRemainder", "mod", dividend, divisor, dividend % divisor),
    ("checkWordQuotient", "div", large, 10, large / 10),
    ("checkWordRemainder", "mod", large, 10, large % 10),
    ("checkDivisionZero", "div", large, 0, 0),
    ("checkRemainderZero", "mod", large, 0, large)]
  let checks := cases.map fun (name, operation, left, right, expected) => {
    name, typeName := none, parameters := [], results := [.i32], locals := []
    body := naturalLiteral left ++ naturalLiteral right ++
      [.call ("__ps_nat_" ++ operation)] ++ naturalLiteral expected ++ [.call "__ps_nat_eq"]
    : PsWasmFunction }
  let core := {
    psWasmModuleEmpty with
    structures := valueStructures, arrays := valueArrays
    functions := runtime.map (·.function) ++ checks
    exports := checks.map fun f => (f.name, f.name) }
  return {
    core, locals := runtime.map fun d => (d.function.name, d.names)
    exports := checks.map fun f => {
      sourceName := f.name, foreignName := witName f.name, parameters := [], result := some .bool } }

end PsWasm


private def unwrap {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def writePlan (stem : String) (plan : PsWasm.ScalarComponent) : IO Unit := do
  let core ← unwrap (PsWasm.checkedCore plan.core plan.locals)
  let wasm ← unwrap (PsWasm.scalarComponentBinary plan)
  let wat ← unwrap (psRenderDoc (PsWasm.scalarComponentWat plan))
  let coreWat ← unwrap (psRenderDoc (PsWasm.watModuleDoc plan.core plan.locals))
  IO.FS.writeBinFile (stem ++ ".core.wasm") core
  IO.FS.writeBinFile (stem ++ ".wasm") wasm
  IO.FS.writeFile (stem ++ ".wat") (wat.text ++ "\n")
  IO.FS.writeFile (stem ++ ".core.wat") (coreWat.text ++ "\n")
  IO.FS.writeFile (stem ++ ".wit") (PsWasm.scalarWit plan)

def main : IO Unit := do
  -- WAT and binary debug names share the target field table. A malformed
  -- table must fail before either artifact can be emitted.
  let duplicateFields : PsWasmModule := {
    psWasmModuleEmpty with
    structures := [{
      name := "DuplicateFields", superType := none, isFinal := true
      fields := [
        { name := "payload", storageType := .value .i32 },
        { name := "payload", storageType := .value .i32 }] }] }
  match psWasmIrValidateModuleStructure duplicateFields with
  | .error (.duplicateFieldName "DuplicateFields") => pure ()
  | _ => throw (IO.userError "duplicate target field names escaped validation")
  let directory := "../dist/pscv0-native/wasm"
  IO.FS.createDirAll directory
  writePlan (directory ++ "/gc-probe") PsWasm.gcComponentProbe
  writePlan (directory ++ "/natural-probe") (← unwrap PsWasm.naturalComponentProbe)
  let source := "function scalarBits64(value: Float): UInt64 := Float.toBits(value)\nfunction scalarBits32(value: Float32): UInt32 := Float32.toBits(value)\nfunction scalarMake64(value: UInt64): Float := Float.ofBits(value)\nfunction scalarMake32(value: UInt32): Float32 := Float32.ofBits(value)\n" ++
    "function both(left: Bool, right: Bool): Bool := if (left) { right } else { false }\n" ++
    "function invert(value: Bool): Bool := if (value) { false } else { true }\n"
  IO.FS.writeFile (directory ++ "/scalar.ps") source
  IO.FS.writeFile (directory ++ "/exports.json") "[\"both\", \"invert\", \"scalarBits64\", \"scalarBits32\", \"scalarMake64\", \"scalarMake32\"]"
  IO.FS.writeFile (directory ++ "/aggregate.ps") ("function echoNatural(value: Nat): Nat := value\nfunction addNatural(left: Nat, right: Nat): Nat := Nat.add(left, right)\nfunction echoInteger(value: Int): Int := value\nfunction showInteger(value: Int): String := Int.repr(value)\nfunction echoText(value: String): String := value\nfunction echoArray(value: Array Nat): Array Nat := value\nstructure Packet where {\n  count: Nat\n  text: String\n  enabled: Bool\n}\nfunction echoPacket(value: Packet): Packet := value\ninductive Choice where {\n  | vacant: Choice\n  | present(value: Nat): Choice\n}\nfunction echoChoice(value: Choice): Choice := value\nfunction many(p0: Bool, p1: Bool, p2: Bool, p3: Bool, p4: Bool, p5: Bool, p6: Bool, p7: Bool, p8: Bool, p9: Bool, p10: Bool, p11: Bool, p12: Bool, p13: Bool, p14: Bool, p15: Bool, p16: Bool): Bool := p16\nstructure Box(A: Type) where { value: A }\nfunction echoBox(value: Box Bool): Box Bool := value\nfunction echoChar(value: Char): Char := value\nfunction consume(value: String): Unit := Unit.unit\nfunction echoWide(value: UInt64): UInt64 := value\nstructure UnsignedBox where { narrow: UInt8\n wide: UInt64 }\nfunction echoUnsignedBox(value: UnsignedBox): UnsignedBox := value\ninductive UnsignedChoice where { | narrow(value: UInt8) | wide(value: UInt64) }\nfunction echoUnsignedChoice(value: UnsignedChoice): UnsignedChoice := value\nfunction wideResult(value: String): UInt64 := UInt64.ofNat(18446744073709551615)\n" ++
    "function echoFloat64(value: Float): Float := value\nfunction echoFloat32(value: Float32): Float32 := value\nfunction echoFloatBox(value: Box Float): Box Float := value\nfunction echoFloatArray(value: Array Float32): Array Float32 := value\nstructure FloatPair where { narrow: Float32\n wide: Float }\nfunction echoFloatPair(value: FloatPair): FloatPair := value\ninductive FloatNarrowChoice where { | word(value: UInt32) | single(value: Float32) }\nfunction echoFloatNarrowChoice(value: FloatNarrowChoice): FloatNarrowChoice := value\ninductive FloatWideChoice where { | word(value: UInt64) | single(value: Float32) | double(value: Float) }\nfunction echoFloatWideChoice(value: FloatWideChoice): FloatWideChoice := value\nfunction manyFloats(p0: Float32, p1: Float32, p2: Float32, p3: Float32, p4: Float32, p5: Float32, p6: Float32, p7: Float32, p8: Float32, p9: Float32, p10: Float32, p11: Float32, p12: Float32, p13: Float32, p14: Float32, p15: Float32, p16: Float32): Float32 := p16\n")
  IO.FS.writeFile (directory ++ "/aggregate.exports.json") "[\"echoNatural\",\"addNatural\",\"echoInteger\",\"showInteger\",\"echoText\",\"echoArray\",\"echoPacket\",\"echoChoice\",\"many\",\"echoBox\",\"echoChar\",\"consume\",\"echoWide\",\"echoUnsignedBox\",\"echoUnsignedChoice\",\"wideResult\",\"echoFloat64\",\"echoFloat32\",\"echoFloatBox\",\"echoFloatArray\",\"echoFloatPair\",\"echoFloatNarrowChoice\",\"echoFloatWideChoice\",\"manyFloats\"]"
  let requests : Array PsV7Native.Request := #[
    { source, targets := [.wasmComponent], outputStem := "scalar",
      exports := .selected ["both", "invert", "scalarBits64", "scalarBits32", "scalarMake64", "scalarMake32"] },
    { source := "function generic{A: Type}(value: A): A := value\n", targets := [.wasmComponent] },
    { source, targets := [.wasmComponent], exports := .selected ["missing"] },
    { source := "structure Refined where {\n  value: Nat\n  proof: Eq(value, 0)\n}\nfunction echo(value: Refined): Refined := value\n",
      targets := [.wasmComponent], exports := .selected ["echo"] }]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok b => pure b
    | .error e => throw (IO.userError (reprStr e))
  for (result, i) in batch.results.toList.zipIdx do
    if i == 0 then
      let value ← match result with
        | .ok v => pure v
        | .error e => throw (IO.userError (reprStr e))
      for artifact in value.artifacts do
        for file in artifact.files do
          let path := directory ++ "/" ++ file.path
          match file.payload with
          | .text s => IO.FS.writeFile path s
          | .binary b => IO.FS.writeBinFile path b
    else
      match result with
      | .ok _ => throw (IO.userError "expected bounded-profile/export refusal")
      | .error e =>
        if e.phase != "ir/emit" then throw (IO.userError ("unexpected refusal phase: " ++ e.phase))
        if i == 3 && (e.message.splitOn "PSCV0-WIT-INVARIANT").length <= 1 then
          throw (IO.userError ("missing foreign invariant refusal: " ++ e.message))
  -- Coherent four-width signed scalar source/ABI fixture. Every declaration
  -- enters source elaboration, native kernel admission, typed erasure and
  -- Wasm GC + Canonical ABI through one production emitter.
  let signedSource : String := "function signedEightAdd(a: Int8, b: Int8): Int8 := Int8.add(a, b)\nfunction signedEightDiv(a: Int8, b: Int8): Int8 := Int8.div(a, b)\nfunction signedEightMod(a: Int8, b: Int8): Int8 := Int8.mod(a, b)\nfunction signedSixteenSub(a: Int16, b: Int16): Int16 := Int16.sub(a, b)\nfunction signedSixteenMul(a: Int16, b: Int16): Int16 := Int16.mul(a, b)\nfunction signedThirtyTwoDiv(a: Int32, b: Int32): Int32 := Int32.div(a, b)\nfunction signedThirtyTwoMod(a: Int32, b: Int32): Int32 := Int32.mod(a, b)\nfunction signedSixtyFourAdd(a: Int64, b: Int64): Int64 := Int64.add(a, b)\nfunction signedSixtyFourDiv(a: Int64, b: Int64): Int64 := Int64.div(a, b)\n"
  let signedBatch ← match ← PsV7Native.runBatch #[{
    source := signedSource, targets := [.wasmComponent], outputStem := "signed",
    exports := .selected ["signedEightAdd","signedEightDiv","signedEightMod","signedSixteenSub","signedSixteenMul","signedThirtyTwoDiv","signedThirtyTwoMod","signedSixtyFourAdd","signedSixtyFourDiv"] }] with
    | .ok result => pure result
    | .error problem => throw (IO.userError ("signed Wasm prelude: " ++ problem.message))
  let some signedResult := signedBatch.results[0]? |
    throw (IO.userError "missing signed Wasm compilation")
  let signedArtifacts ← match signedResult with
    | .ok result => pure result.artifacts
    | .error problem => throw (IO.userError ("signed Wasm " ++ problem.phase ++
        ": " ++ problem.message))
  for artifact in signedArtifacts do
    for file in artifact.files do
      let path := directory ++ "/" ++ file.path
      match file.payload with
      | .text text => IO.FS.writeFile path text
      | .binary bytes => IO.FS.writeBinFile path bytes
  IO.println "Wasm: scalar, signed four-width, three refusals and GC/component fixture emitted."
