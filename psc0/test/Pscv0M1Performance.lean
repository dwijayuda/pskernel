import Ps.Host.NativeV7
import Ps.BackendEcma.Lower

open Lean (toJson)

-- Source-strategy qualification remains distinct from partial runtime admission.
private def checkV72PartialGrammar : IO Unit := do
  for (source, privateExpected) in [
      ("partial def spin(n: Nat): Nat := spin(n)\n", false),
      ("partial function spin(n: Nat): Nat := spin(n)\n", false),
      ("partial function spin(): Nat := spin()\n", false),
      ("private partial function spin(n: Nat): Nat := spin(n)\n", true)] do
    let program ← match psPscv0ParseProgram source with
      | .ok value => pure value
      | .error message => throw (IO.userError ("v7.2 partial source: " ++ message))
    let declaration ← match program.commands with
      | [.declaration value] =>
        if privateExpected then throw (IO.userError "partial privacy lost") else pure value
      | [.privateDeclaration value] =>
        if privateExpected then pure value else throw (IO.userError "unexpected private partial")
      | _ => throw (IO.userError "partial command shape changed")
    match declaration with
    | .partialDefinition name _ _ _ span =>
      if name.segments != ["spin"] || span.start.byteOffset != (if privateExpected then 8 else 0) then
        throw (IO.userError "partial name/modifier source span was not retained")
    | _ => throw (IO.userError "partial strategy was erased to a total definition")
  for (source, expected) in [
      ("partial const x: Nat := 0\n", "PSCV0-TERM-02-HEAD"),
      ("partial theorem x: True := True.intro\n", "PSCV0-TERM-02-HEAD"),
      ("partial partial def x: Nat := 0\n", "PSCV0-REC-STRATEGY-01"),
      ("partial unsafe def x: Nat := 0\n", "PSCV0-REC-STRATEGY-01"),
      ("unsafe partial def x: Nat := 0\n", "PSCV0-REC-STRATEGY-01"),
      ("partial noncomputable def x: Nat := 0\n", "PSCV0-REC-STRATEGY-01"),
      ("partial def spin(n: Nat): Nat := spin(n)\npartial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      ("partial def spin(n: Nat): Nat := spin(n)\ntermination_by n\n", "PSCV0-REC-STRATEGY-01"),
      ("partial_fixpoint def spin(n: Nat): Nat := spin(n)\n", "PSCV0-FIXPOINT-01")] do
    match psPscv0ParseProgram source with
    | .ok _ => throw (IO.userError ("v7.2 invalid strategy accepted: " ++ source))
    | .error message =>
      if !message.startsWith expected then
        throw (IO.userError ("v7.2 strategy rejected for wrong rule: " ++ message))
  let surface ← match psPscv0ParseSource true "partial def spin(n: Nat): Nat := spin(n)\n" with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let lowered ← match psPscv0LowerModule surface with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  match lowered.declarations with
  | [.partialDefinition ..] => pure ()
  | _ => throw (IO.userError "source translation discarded partial strategy")
  IO.println "PSCV0_V72_PARTIAL_SOURCE: PASS def/function/nullary/private ownership, modifier conflicts and retained strategy; runtime admission remains pending"

-- Inspect the actual retained graph, not a separately invented safety flag.
-- The end-to-end requests below independently send both bodies to the kernel.
private def checkV72PartialOwnership : IO Unit := do
  let program ← match psPscv0ParseProgram "partial function spin(n: Nat): Nat := spin(n)\n" with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let elaborated ← match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment program with
    | .ok value => pure value
    | .error error => throw (IO.userError (psCompilerPscv0ElabError error))
  match elaborated.result.declarations with
  | [.opaqueDecl name levels type witness, .partialDecl implementation bodyLevels bodyType body] =>
    if !psNameEq implementation (.num name 0) || levels.length != bodyLevels.length ||
        !psExprAlphaEq type bodyType || psExprAlphaEq witness body then
      throw (IO.userError "partial logical identity and actual body were conflated")
    if !elaborated.privateNames.any (psNameEq implementation) ||
        elaborated.privateNames.any (psNameEq name) then
      throw (IO.userError "partial implementation privacy is incorrect")
    if elaborated.result.environment.instances.entries.length !=
        psSelfHostProdPreludeEnvironment.instances.entries.length then
      throw (IO.userError "partial witness instances escaped their local scope")
    let prepared ← match psCompilerPrepareElaboratedWithOutput elaborated.result with
      | .ok value => pure value
      | .error error => throw (IO.userError (psCompilerPscv0Error error))
    match prepared.prepared.declarations, psCompilerLogicalCheckingView prepared.prepared.declarations with
    | [_, .partialDecl retained ..], [_, .opaqueDecl checked _ _ checkedBody] =>
      if !psNameEq retained implementation || !psNameEq checked implementation ||
          !psExprAlphaEq checkedBody body then
        throw (IO.userError "partial checking view changed body identity")
    | _, _ => throw (IO.userError "partial preparation lost the runtime refusal marker")
  | _ => throw (IO.userError "partial declaration must own separate logical/body members")
  IO.println "PSCV0_V72_PARTIAL_OWNERSHIP: PASS separate inhabitant/body, private numeric identity, local witnesses and retained runtime marker"

private structure PartialCheck where
  label : String
  request : PsV7Native.Request
  failure : Option (String × String) := none

private def partialChecks : Array PartialCheck :=
  let spin := "partial function spin(n: Nat): Nat := spin(n)\n"
  let library : PsPscv0ModuleSource := {
    name := "Lib", sourceName := "Lib.ps"
    source := "namespace Lib\n" ++ spin ++ "end Lib\n" }
  let client := "import Lib\nfunction main(n: Nat): Nat := Lib.spin(n)\n"
  let runtimeFailure := some ("erase", "PSCV0-PREPARATION: PSCV0-PARTIAL-RUNTIME-PENDING:")
  #[
    { label := "recursive-body-and-reflexivity", request := {
        source := spin ++ "theorem identity(n: Nat): spin(n) = spin(n) := by { rfl }\n" } },
    { label := "universe-parameter-inhabitant", request := {
        source := "universe u\npartial function keep {alpha: Type u}(x: alpha): alpha := keep(x)\n" } },
    { label := "private-nullary", request := {
        source := "private partial function loop(): Nat := loop()\n" } },
    { label := "captured-section-parameter", request := {
        source := "universe u\nsection\nvariable (alpha: Type u)\npartial function keep(x: alpha): alpha := keep(x)\nend\n" } },
    { label := "empty-result", request := {
        source := "inductive EmptyResult where { }\npartial function bad(n: Nat): EmptyResult := bad(n)\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-TERM-02-INHABITED:") },
    { label := "false-result", request := {
        source := "partial function bad(n: Nat): False := bad(n)\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-TERM-02-INHABITED:") },
    { label := "body-type", request := {
        source := "partial function bad(n: Nat): Nat := true\n" }
      failure := some ("elaborate", "PSCV0-TYPE-MISMATCH") },
    { label := "no-defining-equation", request := {
        source := spin ++ "theorem equation: spin(0) = 0 := by { rfl }\n" }
      failure := some ("elaborate", "PSCV0-PROOF:") },
    { label := "function-only", request := {
        source := "partial def value: Nat := 0\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-TERM-02-FUNCTION:") },
    { label := "all-targets-refused", request := {
        source := spin, targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] }
      failure := runtimeFailure },
    { label := "imported-logical-interface", request := {
        source := client, modules := [library] } },
    { label := "imported-runtime-refused", request := {
        source := client, modules := [library], targets := [.javascript, .typescript, .rust] }
      failure := runtimeFailure } ]

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
  checkV72PartialGrammar
  checkV72PartialOwnership
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
  -- Preserve original measured requests, then reuse their immutable prelude
  -- for phase-specific logical/body and executable-refusal qualification.
  let checks := partialChecks
  for check in checks do
    requests := requests.push { check.request with
      sourceName := "v72-partial-" ++ check.label ++ ".ps" }
  IO.FS.writeFile (directory / "runtime.ps") runtimeSource
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  let mut compilerRows := #[]
  for i in [:batch.results.size] do
    let some outcome := batch.results[i]? | throw (IO.userError "M1 benchmark result missing")
    if i > labels.size then
      let some check := checks[i - labels.size - 1]?
        | throw (IO.userError "partial qualification result index mismatch")
      match check.failure, outcome with
      | none, .ok result =>
        if !result.artifacts.isEmpty then
          throw (IO.userError ("check-only partial produced artifacts: " ++ check.label))
      | some (phase, diagnosticPrefix), .error error =>
        if error.phase != phase || !error.message.startsWith diagnosticPrefix then
          throw (IO.userError ("partial wrong rejection for " ++ check.label ++ ": " ++ error.phase ++ ": " ++ error.message))
      | none, .error error =>
        throw (IO.userError ("partial expected acceptance for " ++ check.label ++ ": " ++ error.phase ++ ": " ++ error.message))
      | some _, .ok _ =>
        throw (IO.userError ("partial expected refusal for " ++ check.label))
      IO.println ("PSCV0_V72_PARTIAL_CHECK: PASS " ++ check.label)
    else
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
