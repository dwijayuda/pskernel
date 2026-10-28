import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Encode
import Ps.MinKernel.Tests.StringBridge
import Lean

-- Linux Actions host-only harness. Source inputs are exact owned files.
def r6Json (fields : List (String × Lean.Json)) : Lean.Json := Lean.Json.mkObj fields
def r6String (s : String) : Lean.Json := Lean.Json.str s
def r6Nat (n : Nat) : Lean.Json := Lean.toJson n
def r6Bytes (s : String) : List Nat := s.toByteArray.data.toList.map UInt8.toNat

-- Independent chronological byte fold: no string append or psTsJoin in the oracle.
def r6Oracle (separator : List Nat) (fragments : List (List Nat)) : List Nat :=
  match fragments with
  | [] => []
  | first :: rest => rest.foldl (fun acc next => (acc ++ separator) ++ next) first

def r6CheckInputs (path : String) : IO (List PsSh1SourceInput) := do
  let text ← IO.FS.readFile path
  let json ← match Lean.Json.parse text with
    | .error error => throw (IO.userError error)
    | .ok value => pure value
  let rows ← match json.getArr? with
    | .error error => throw (IO.userError error)
    | .ok value => pure value
  rows.toList.mapM fun row => do
    let name ← match row.getObjValAs? (Array String) "moduleName" with
      | .error error => throw (IO.userError error)
      | .ok value => pure value
    let source ← match row.getObjValAs? String "source" with
      | .error error => throw (IO.userError error)
      | .ok value => pure value
    pure (psSh1SourceInput name.toList source)

def r6Compile (inputs : List PsSh1SourceInput) (stem : String) : IO Unit := do
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions psIrCheckDefaultOptions
      PsCompilerSourceKind.lean inputs with
  | .error _ => throw (IO.userError ("R6_SOURCE_REFUSED: " ++ stem))
  | .ok result =>
    if !result.sourcePolicy.accepted || !result.targetPolicy.accepted ||
        !result.checkReport.accepted || !result.checkReport.traversalComplete then
      throw (IO.userError "R6_SOURCE_OR_IR_REFUSED")
    IO.FS.writeFile (stem ++ ".ts") result.typeScript
    IO.FS.writeFile (stem ++ ".admissions.json") result.admissions
    match psIrEncodeModule result.originalIr with
    | .error _ => throw (IO.userError "R6_IR_ENCODING_REFUSED")
    | .ok ir => IO.FS.writeFile (stem ++ ".ir.json") ir
    IO.FS.writeFile (stem ++ ".policy.json")
      (r6Json [("sourceAccepted", Lean.toJson result.sourcePolicy.accepted),
        ("targetAccepted", Lean.toJson result.targetPolicy.accepted),
        ("originalIrAccepted", Lean.toJson result.checkReport.accepted),
        ("providerChecked", Lean.toJson result.providerChecked),
        ("semanticContractQualified", Lean.toJson result.semanticContractQualified),
        ("strictSh1Qualified", Lean.toJson result.strictSh1Qualified),
        ("moduleCount", r6Nat result.sourcePolicy.moduleCount),
        ("originModuleCount", r6Nat result.origins.length)]).compress

def main : IO Unit := do
  let dir := "dist/pskernel-min/text-preservation"
  IO.FS.createDirAll dir
  let nul := String.singleton (Char.ofNat 0)
  let scalarCodes : List Nat := [127, 128, 2047, 2048, 65535, 65536, 1114111]
  let boundaries := scalarCodes.map (fun n => String.singleton (Char.ofNat n))
  let strings := ["", "a", "ab", "é", "λ", "🙂", "é", nul, "\n",
    "\"\\", String.ofList (List.replicate 4096 'x')] ++ boundaries
  let mut appendRows : List Lean.Json := []
  for left in strings do
    for right in strings do
      let expected := r6Bytes left ++ r6Bytes right
      unless r6Bytes (psR6ModernAppend left right) == expected &&
          r6Bytes (psR6LegacyAppend left right) == expected do
        throw (IO.userError "R6_NATIVE_APPEND_MISMATCH")
      appendRows := appendRows ++ [r6Json [
        ("left", r6String left), ("right", r6String right), ("bytes", Lean.toJson expected)]]
  let fragmentLists : List (List String) := [[], [""], ["a"], ["",""], ["a","b"],
    ["λ","🙂","é"], [nul,"\n","\"\\"], strings,
    List.replicate 64 "", List.replicate 256 "λ"]
  let separators := ["", ",", "🙂", nul, "\n"]
  let mut joinRows : List Lean.Json := []
  for separator in separators do
    for fragments in fragmentLists do
      let expected := r6Oracle (r6Bytes separator) (fragments.map r6Bytes)
      unless r6Bytes (psTsJoin separator fragments) == expected do
        throw (IO.userError "R6_NATIVE_ACTUAL_JOIN_MISMATCH")
      joinRows := joinRows ++ [r6Json [
        ("separator", r6String separator), ("fragments", Lean.toJson fragments),
        ("bytes", Lean.toJson expected)]]
  let emitPairs := [("", ""), ("a", "b"), ("λ", "🙂"), ("é", nul),
    ("\n", "\"\\"), (nul, "λ"), ("🙂", "é"), ("a", ""), ("", "b"),
    (String.ofList (List.replicate 4096 'x'), "🙂")]
  let emitters : List (String × (String → String → String) × List String × List String × List String) :=
    [("psR6EmitAdd", psR6EmitAdd, ["("], [" + "], [")"]),
     ("psR6EmitAnd", psR6EmitAnd, ["("], [" && "], [")"]),
     ("psR6EmitSub", psR6EmitSub,
       ["((__ps_a: bigint, __ps_b: bigint) => ",
        "(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))("], [", "], [")"])]
  let mut emitterRows : List Lean.Json := []
  for (name, emit, prefix, middle, suffix) in emitters do
    for (left, right) in emitPairs do
      let expected := r6Oracle [] ((prefix ++ [left] ++ middle ++ [right] ++ suffix).map r6Bytes)
      unless r6Bytes (emit left right) == expected do
        throw (IO.userError "R6_NATIVE_ACTUAL_EMITTER_BYTES_MISMATCH")
      emitterRows := emitterRows ++ [r6Json [
        ("name", r6String name), ("left", r6String left), ("right", r6String right),
        ("bytes", Lean.toJson expected)]]
  IO.FS.writeFile (dir ++ "/native.json")
    (r6Json [("schema",r6String "psc1-r6-text-native/1"),
      ("append",Lean.toJson appendRows),("join",Lean.toJson joinRows),
      ("emitter",Lean.toJson emitterRows)]).compress
  let actual ← r6CheckInputs (dir ++ "/actual.inputs.json")
  let fixture ← r6CheckInputs (dir ++ "/fixture.inputs.json")
  r6Compile actual (dir ++ "/actual")
  r6Compile fixture (dir ++ "/fixture")
  IO.println "PSC1_R6_NATIVE_TEXT_PASS"
