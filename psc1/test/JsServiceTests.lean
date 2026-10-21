import Ps.BackendJs.CompilerService
import Ps.Host.LeanChecked
import Lean.Data.Json

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_JS_SERVICE_FAIL: " ++ name))
  IO.println ("PSC1_JS_SERVICE_PASS: " ++ name)

private def field (value : Lean.Json) (key : String) : IO Lean.Json := do
  match value.getObjVal? key with
  | .error code => throw (IO.userError code)
  | .ok item => pure item

private def textField (value : Lean.Json) (key : String) : IO String := do
  match <- field value key with
  | .str text => pure text
  | _ => throw (IO.userError ("expected string field: " ++ key))

private def request (grammar assurance entry : String)
    (sources : List (String × String)) : String :=
  psJsonArray [
    psJsonQuote "psc1-compiler-service/1", psJsonQuote "native-facade-test",
    psJsonQuote "unit-test-correlation-only", psJsonQuote grammar,
    psJsonQuote assurance, psJsonQuote entry,
    psJsonArray (sources.map (fun source => psJsonArray [psJsonQuote source.1, psJsonQuote source.2]))
  ]

private def response (input : String) : IO Lean.Json := do
  match Lean.Json.parse (psCompilerJsServiceCandidate input) with
  | .error code => throw (IO.userError code)
  | .ok value => pure value

private def refusal (name input phase : String) : IO Unit := do
  let result <- response input
  require name ((<- textField result "status") == "refused" &&
    (<- textField result "phase") == phase &&
    (<- textField result "admission") == "not-run")

def main : IO Unit := do
  IO.FS.createDirAll "dist/generated-service-native"
  for grammar in ["lean", "ps"] do
    -- Authored independently; no translation call supplies the PS request.
    let sources : List (String × String) :=
      if grammar == "lean" then [
        ("Lib", "namespace Lib\ndef base : Nat := 40\nend Lib\n"),
        ("Entry", "import Lib\ndef Ps.Internal.ServiceFixture.hidden : Nat := Lib.base\ndef answer : Nat := Ps.Internal.ServiceFixture.hidden + 2\n")
      ] else [
        ("Lib", "namespace Lib\ndef base : Nat := 40\nend Lib\n"),
        ("Entry", "import Lib\ndef Ps.Internal.ServiceFixture.hidden : Nat := Lib.base\ndef answer : Nat := Ps.Internal.ServiceFixture.hidden + 2\n")
      ]
    let candidate <- response (request grammar "checked" "Entry" sources)
    require (grammar ++ ": provisional status is explicit")
      ((<- textField candidate "status") == "candidate" &&
        (<- textField candidate "admission") == "not-run" &&
        (<- field candidate "candidateOnly").compress == "true")
    require (grammar ++ ": only entry public value is exported")
      ((<- field candidate "publicNames").compress == "[\"answer\"]")
    let envelope <- field candidate "admissionRequest"
    let admissions <- textField envelope "admissions"
    match <- PsKernelLean.admitCanonicalAdmissions admissions with
    | .error error => throw (IO.userError ("independent facade graph refused: " ++ error.message))
    | .ok _ => pure ()
    IO.println ("PSC1_JS_SERVICE_PASS: " ++ grammar ++ ": exact facade graph independently admitted")
    let output := "dist/generated-service-native/" ++ grammar ++ ".mjs"
    IO.FS.writeFile output (<- textField candidate "source")
    let targetSyntax <- IO.Process.output { cmd := "node", args := #["--check", output] }
    require (grammar ++ ": actual emitted module passes target syntax")
      (targetSyntax.exitCode == 0)
    let consumer := "dist/generated-service-native/" ++ grammar ++ "-consumer.mjs"
    IO.FS.writeFile consumer
      ("import * as compiled from './" ++ grammar ++ ".mjs';\n" ++
        "if (compiled.answer !== 42n || Object.keys(compiled).join(',') !== 'answer') throw Error('facade target behavior/export ownership');\n")
    let execution <- IO.Process.output { cmd := "node", args := #[consumer] }
    require (grammar ++ ": target executes with imported/internal ownership")
      (execution.exitCode == 0)

    refusal (grammar ++ ": missing import")
      (request grammar "checked" "Entry" [("Entry", "import Missing\ndef answer : Nat := 1\n")]) "capture"
    refusal (grammar ++ ": duplicate module")
      (request grammar "checked" "Entry" [("Entry", "def a : Nat := 1\n"), ("Entry", "def b : Nat := 2\n")]) "capture"
    refusal (grammar ++ ": extra module")
      (request grammar "checked" "Entry" [("Unused", "def unused : Nat := 0\n"), ("Entry", "def answer : Nat := 1\n")]) "capture"
    refusal (grammar ++ ": missing entry")
      (request grammar "checked" "Missing" [("Entry", "def answer : Nat := 1\n")]) "capture"
    refusal (grammar ++ ": invalid source")
      (request grammar "checked" "Entry" [("Entry", "def answer : Nat :=\n")]) "parse"
    refusal (grammar ++ ": wrong body")
      (request grammar "checked" "Entry" [("Entry", "def answer : Nat := true\n")]) "elaboration"
    refusal (grammar ++ ": checked-only partial source")
      (request grammar "checked" "Entry" [("Entry", "partial def spin (n : Nat) : Nat := spin n\n")]) "preparation"
    refusal (grammar ++ ": verified request")
      (request grammar "verified" "Entry" [("Entry", "def answer : Nat := 1\n")]) "wire"
    refusal (grammar ++ ": unknown source grammar")
      (request "native-lean" "checked" "Entry" [("Entry", "def answer : Nat := 1\n")]) "wire"
  refusal "malformed JSON refuses before compiler execution" "{" "wire"
  refusal "object request cannot inject host capabilities" "{\"checker\":\"outside-tool\"}" "wire"
