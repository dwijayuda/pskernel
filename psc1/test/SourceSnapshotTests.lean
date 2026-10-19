import Ps.Host.WasmComponent

-- A small host regression, not compiler/kernel self-generation. The source is
-- changed after admission; both emitted targets must still use the captured true.
def main (args : List String) : IO Unit := do
  let [input, jsOutput, tsOutput] := args
    | throw (IO.userError "PSC1_SNAPSHOT_TEST_USAGE")
  IO.FS.writeFile input "def answer : Bool := true\n"
  let session ← psHostDirectPrepare input
  IO.FS.writeFile input "def answer : Bool := false\n"
  psHostDirectEmitJavaScript session jsOutput
  psHostDirectEmitTypeScript session tsOutput
  IO.println "PSC1_CAPTURED_SOURCE_SESSION: PASS"
