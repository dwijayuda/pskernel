import Ps.BackendPython.Module
import PythonUtf8Reference
import ScriptEmitterReference

private def strT : PsVerifiedIrType := .primitive .string
private def natT : PsVerifiedIrType := .primitive .nat
private def param (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter := {name, type}
private def declaration (name : String) (parameters : List PsVerifiedIrParameter)
    (resultType : PsVerifiedIrType) (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  {name, typeParameters := [], parameters, resultType, body := .intrinsic operation [] arguments}
private def module : PsVerifiedIrModule := {
  imports := [], structures := [], inductives := [], declarations := [
    declaration "get" [param "text" strT, param "position" natT] (.primitive .char)
      .stringGet [.var "text", .var "position"],
    declaration "next" [param "text" strT, param "position" natT] natT
      .stringNext [.var "text", .var "position"],
    declaration "extract" [param "text" strT, param "start" natT, param "stop" natT] strT
      .stringExtract [.var "text", .var "start", .var "stop"],
    declaration "size" [param "text" strT] natT .stringUtf8ByteSize [.var "text"],
    declaration "atEnd" [param "text" strT, param "position" natT] (.primitive .bool)
      .stringAtEnd [.var "text", .var "position"]
  ]
}
private def requireOk (value : Except String α) : IO α :=
  match value with
  | .error error => throw (IO.userError error)
  | .ok result => pure result
private def run (arguments : Array String) : IO Unit := do
  let result <- IO.Process.output {
    cmd := "python3"
    args := arguments
  }
  unless result.exitCode == 0 do throw (IO.userError (result.stdout ++ result.stderr))
  IO.print result.stdout

def main : IO Unit := do
  let checked <- match psStrictValidateModule module with
    | .error _ => throw (IO.userError "UTF8 intrinsic fixture did not strictly validate")
    | .ok checked => pure checked
  let names := ["get", "next", "extract", "size", "atEnd"]
  let actual <- requireOk (psPythonEmitModule checked names)
  let reference <- requireOk (PsScriptEmitterReference.Python.psPythonEmitModule checked names)
  IO.FS.createDirAll "dist/python-utf8"
  IO.FS.writeFile "dist/python-utf8/actual.py" actual.source
  IO.FS.writeFile "dist/python-utf8/reference.py" reference.source
  let requested := ["string-get", "string-next", "string-extract"]
  IO.FS.writeFile "dist/python-utf8/runtime.py" (psPythonRuntimeSource (psPythonRuntimeClosure requested))
  IO.FS.writeFile "dist/python-utf8/legacy-runtime.py"
    (PsScriptRuntimeReference.Python.psPythonRuntimeSource
      (PsScriptRuntimeReference.Python.psPythonRuntimeClosure requested))
  run #["-I", "scripts/python-utf8-token-comparison.py",
    "dist/python-utf8/actual.py", "dist/python-utf8/reference.py"]
  run #["-I", "scripts/python-utf8-cache-tests.py", "dist/python-utf8"]
