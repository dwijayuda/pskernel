import Ps.Host.NativeV7
import Pscv0M1Harness

open Lean (toJson)

private def get {α : Type} (label : String) (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (label ++ ": " ++ error))

private def parserCases : IO Unit := do
  let json ← get "parser corpus" (Lean.Json.parse
    (← IO.FS.readFile "../scripts/pscv0-m1-cases.json"))
  let good ← get "good cases" ((json.getObjVal? "good").bind Lean.Json.getArr?)
  let bad ← get "bad cases" ((json.getObjVal? "bad").bind Lean.Json.getArr?)
  for c in good do
    m1Good
      (← get "name" (c.getObjValAs? String "name"))
      (← get "source" (c.getObjValAs? String "source"))
      (← get "result" (c.getObjValAs? String "result"))
      (← get "locals" (c.getObjValAs? (List String) "locals"))
  for c in bad do
    m1Bad
      (← get "name" (c.getObjValAs? String "name"))
      (← get "source" (c.getObjValAs? String "source"))
      (← get "error" (c.getObjValAs? String "error"))

private def application : String :=
  "function keep(value: Nat): Nat := {\n" ++
  "  let selected: Nat := value\n  selected\n}\n" ++
  "const answer: Nat := keep(42)\n"

private def semanticCases : IO Unit := do
  let requests : Array PsV7Native.Request := #[
    { source := application },
    { source := "function keep(value: Nat): Except String Nat := do {\n  return value\n}\n" },
    { source := "function keep(value: Nat): Nat := value\nconst bad: Nat := keep (3)\n" },
    { source := "const bad: Nat := true\n" },
    { source := "import Missing\nconst answer: Nat := 42\n" },
    { source := "const leaked: Nat := answer\n" },
    { source := "const answer: Nat := 43\n" }]
  let expected : Array (Option String) :=
    #[none, none, some "parse", some "elaborate", some "parse", some "elaborate", none]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (reprStr error))
  for i in [:expected.size] do
    let some result := batch.results[i]?
      | throw (IO.userError "missing batch result")
    IO.println (PsV7Native.resultJson ("case-" ++ toString i) result).compress
    match expected[i]!, result with
    | none, .ok _ => pure ()
    | some phase, .error error =>
        unless error.phase == phase do
          throw (IO.userError s!"case {i}: expected {phase}, got {error.phase}")
        if i == 2 && !error.message.startsWith "PSCV0-APP-02" then
          throw (IO.userError "gap application did not reach APP-02")
        if i == 4 && error.message != "PSCV0-NATIVE-MODULE-IMPORTS-PENDING" then
          throw (IO.userError "imports were not explicitly refused")
    | _, _ => throw (IO.userError s!"case {i}: wrong acceptance outcome")
  IO.FS.createDirAll "../dist/pscv0-native"
  IO.FS.writeFile "../dist/pscv0-native/application.ps" application
  IO.FS.writeFile "../dist/pscv0-native/semantic.json"
    (Lean.Json.mkObj [
      ("preludeMs", toJson batch.preludeMs),
      ("results", Lean.Json.arr (batch.results.map (PsV7Native.resultJson "batch-case")))]).pretty
  IO.println "PSCV0_NATIVE_SEMANTICS: PASS 3 checked programs, 4 phase-specific refusals, shared-prelude isolation"

def main : IO Unit := do
  parserCases
  semanticCases
  IO.println "PSCV0_NATIVE_CHECKS: PASS; no compiler-source translation or self-host regeneration"
