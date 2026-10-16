import Ps.Host.NativeV7
import Ps.BackendEcma.Lower

open Lean (toJson)

-- Focused M3 emitter boundary checks; existing measurement workloads below are
-- unchanged. These are recognizer checks, not a compiler-preservation proof.
private def checkEcmaLowering : IO Unit := do
  let nat := PsVerifiedIrType.primitive .nat
  let type := PsVerifiedIrType.typeParameter "T"
  let mk : List PsVerifiedIrType → PsVerifiedIrDeclaration := fun types => {
    name := "m3Tail", typeParameters := [{ name := "T" }]
    parameters := [{ name := "n", type := nat }], resultType := nat
    body := .ifE (.intrinsic .natEq [] [.var "n", .literal (.natural 0)])
      (.literal (.natural 0))
      (.call (.var "m3Tail") types [.intrinsic .natSub [] [.var "n", .literal (.natural 1)]]) }
  for (label, types, expected) in [("uniform", [type], true), ("type-changing", [nat], false)] do
    let emitted ← match PsEcma.declaration [] [] (mk types) with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    let direct := match emitted with
      | [.functionD _ false _ "<T>" _ _ body] => body.all (PsEcma.stmtSynchronous 4096)
      | _ => false
    if direct != expected then throw (IO.userError ("M3 tail boundary: " ++ label))
  let alias := PsVerifiedIrExpr.lambda [{ name := "k", type := nat }] nat
    (.call (.var "m3Tail") [type] [.var "k"])
  if (PsEcma.tailAliasValue (mk [type]) "again" alias).isNone then
    throw (IO.userError "M3 uniform generic alias was not recognized")
  let callback ← match PsEcma.intrinsic .arrayBuild [nat, nat]
      [PsEcma.id "count", PsEcma.id "seed", PsEcma.id "head", PsEcma.id "tail"] with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  if PsEcma.exprSynchronous 4096 callback || PsEcma.exprSynchronous 0 (PsEcma.id "x") then
    throw (IO.userError "M3 suspension/exhaustion fallback was bypassed")
  let simple ← match PsEcma.lower [] [] 4096
      (.lambda [{ name := "x", type := nat }] nat (.var "x")) with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  if !PsEcma.exprSynchronous 4096 simple then
    throw (IO.userError "M3 pure lambda unnecessarily suspended")
  IO.println "PSCV0_M3_ECMA: PASS uniform tail/alias, type-changing fallback, callback suspension, budget fallback and direct lambda"

-- This is a host-only measurement harness, never part of the portable closure.
-- The reference operations are compiled by the pinned official Lean compiler.
@[noinline] private def referenceListAt (xs : List Nat) (i : Nat) : Nat :=
  xs[i]?.getD 0
@[noinline] private def referenceArrayAt (xs : Array Nat) (i : Nat) : Nat :=
  xs[i]?.getD 0
@[noinline] private def referenceFromList (xs : List Nat) : Array Nat := xs.toArray
@[noinline] private def referenceToList (xs : Array Nat) : List Nat := xs.toList

private def sample (operation : Nat → Nat) (iterations expected : Nat) :
    IO (Array Nat) := do
  let mut times := #[]
  for trial in [:6] do
    let start ← IO.monoNanosNow
    let mut checksum := 0
    for i in [:iterations] do
      checksum := checksum + operation i
    let stop ← IO.monoNanosNow
    if checksum != expected then throw (IO.userError "M1 reference benchmark checksum mismatch")
    if trial > 0 then times := times.push (stop - start)
  return times

private def runtimeReference : IO (Array Lean.Json) := do
  let mut rows := #[]
  for size in [256, 8192] do
    let xs := (List.range size).map Nat.succ
    let array := xs.toArray
    for (name, operation, iterations, expected) in [
        ("listHead", fun i => referenceListAt xs (i % 2), 128, 192),
        ("listTail", fun i => referenceListAt xs (size - 1 + i % 2), 16, 8 * size),
        ("arrayHead", fun i => referenceArrayAt array (i % 2), 128, 192),
        ("arrayTail", fun i => referenceArrayAt array (size - 1 + i % 2), 128, 64 * size),
        ("fromList", fun i => (referenceFromList xs).size + i % 2, 8, 8 * size + 4),
        ("toList", fun i => (referenceToList array).length + i % 2, 8, 8 * size + 4)] do
      let times ← sample operation iterations expected
      rows := rows.push (Lean.Json.mkObj [
        ("name", toJson name), ("size", toJson size),
        ("iterations", toJson iterations), ("checksum", toJson expected),
        ("samplesNs", toJson times)])
  return rows

private def runtimeSource : String :=
  "function m1MakeWorker(n: Nat, xs: List Nat): List Nat := match n with { | 0 => xs | k + 1 => m1MakeWorker(k, List.cons(n, xs)) }\n" ++
  "function m1MakeList(n: Nat): List Nat := m1MakeWorker(n, [])\n" ++
  "function m1MakeArray(n: Nat): Array Nat := List.toArray(m1MakeList(n))\n" ++
  "function m1ListAt(xs: List Nat, i: Nat): Nat := Option.getD(xs[i]?, 0)\n" ++
  "function m1ArrayAt(xs: Array Nat, i: Nat): Nat := Option.getD(xs[i]?, 0)\n" ++
  "function m1FromList(xs: List Nat): Nat := Array.size(List.toArray(xs))\n" ++
  "function m1ToList(xs: Array Nat): Nat := List.length(Array.toList(xs))\n" ++
  "function m3Keep(alpha: Type, n: Nat, x: alpha): alpha := match n with { | 0 => x | k + 1 => m3Keep(alpha, k, x) }\n"

private def compilerSource (count : Nat) (indexed : Bool) : String :=
  String.join ((List.range count).map fun n =>
    "function sample" ++ toString n ++
    "(xs: Array Nat, i: Nat, h: Nat.lt(i, Array.size(xs))): Nat := " ++
    (if indexed then "xs[i]" else "i") ++ "\n")

private def timingJson (t : PsV7Native.Timings) : Lean.Json :=
  Lean.Json.mkObj [
    ("parseMs", toJson t.parseMs), ("elaborateMs", toJson t.elaborateMs),
    ("prepareMs", toJson t.prepareMs), ("kernelMs", toJson t.kernelMs),
    ("eraseMs", toJson t.eraseMs), ("emitMs", toJson t.emitMs)]

def main (args : List String) : IO Unit := do
  checkEcmaLowering
  let directory := System.FilePath.mk (args.headD "../dist/pscv0-native/m1-performance")
  IO.FS.createDirAll directory
  let mut requests : Array PsV7Native.Request := #[]
  let mut labels : Array (Nat × Bool) := #[]
  for count in [16, 128] do
    for indexed in [false, true] do
      let source := compilerSource count indexed
      let name := (if indexed then "indexed" else "baseline") ++ toString count ++ ".ps"
      IO.FS.writeFile (directory / name) source
      for _ in [:4] do
        requests := requests.push {
          source, sourceName := name, targets := [.javascript] }
        labels := labels.push (count, indexed)
  requests := requests.push {
    source := runtimeSource, sourceName := "runtime.ps",
    outputStem := "runtime", targets := [.javascript] }
  IO.FS.writeFile (directory / "runtime.ps") runtimeSource
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  let mut compilerRows := #[]
  for i in [:batch.results.size] do
    let some outcome := batch.results[i]? | throw (IO.userError "M1 benchmark result missing")
    let result ← match outcome with
      | .ok value => pure value
      | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
    if let some (count, indexed) := labels[i]? then
      compilerRows := compilerRows.push (Lean.Json.mkObj [
        ("count", toJson count), ("indexed", toJson indexed),
        ("trial", toJson (i % 4)), ("timings", timingJson result.timings)])
    else
      for artifact in result.artifacts do
        for file in artifact.files do
          match file.payload with
          | .text value => IO.FS.writeFile (directory / file.path) value
          | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let report := Lean.Json.mkObj [
    ("schema", toJson ("pscv0-m1-performance/1" : String)),
    ("leanCommit", toJson Lean.githash), ("leanVersion", toJson Lean.versionString),
    ("preludeMs", toJson batch.preludeMs),
    ("compilerSamples", toJson compilerRows),
    ("nativeLeanRuntime", toJson (← runtimeReference))]
  IO.FS.writeFile (directory / "native.json") report.pretty
  IO.println "PSCV0_M1_PERFORMANCE: native reference and checked compiler samples recorded"
