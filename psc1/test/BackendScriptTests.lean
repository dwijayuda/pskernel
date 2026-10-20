import Ps.BackendPython.Module
import Ps.BackendPhp.Module

private def natT : PsVerifiedIrType := .primitive .nat
private def boxT : PsVerifiedIrType := .named "Box" []
private def param (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter :=
  { name := name, type := type }
private def natE (n : Nat) : PsVerifiedIrExpr := .literal (.natural n)

private def badModule : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations := [{
      name := "forged"
      typeParameters := []
      parameters := []
      resultType := natT
      body := .literal (.bool true)
    }] }

private def boxLayout : PsVerifiedIrStructure := {
  name := "Box"
  typeParameters := []
  fields := [{ name := "value", type := natT }]
}

private def abiModule : PsVerifiedIrModule := {
  imports := []
  structures := [boxLayout]
  inductives := []
  declarations := [{
    name := "readBox"
    typeParameters := []
    parameters := [param "box" boxT]
    resultType := natT
    body := .projection "Box" [] (.var "box") "value"
  }]
}

private def captureBody : PsVerifiedIrExpr :=
  .letE "box" boxT (.record "Box" [] [("value", .var "n")])
    (.letE "closure" (.function [natT] natT)
      (.lambda [param "x" natT] natT
        (.intrinsic .natAdd [] [
          .projection "Box" [] (.var "box") "value", .var "x"]))
      (.letE "box" boxT (.record "Box" [] [("value", natE 1000)])
        (.call (.var "closure") [] [natE 1])))

private def captureModule : PsVerifiedIrModule := {
  imports := []
  structures := [boxLayout]
  inductives := []
  declarations := [{
    name := "answer"
    typeParameters := []
    parameters := [param "n" natT]
    resultType := natT
    body := captureBody
  }]
}

private def rejectWith (marker : String) (result : Except String α) : IO Unit :=
  match result with
  | .error message =>
      unless message.startsWith marker do
        throw (IO.userError ("wrong rejection: " ++ message))
  | .ok _ => throw (IO.userError ("unexpected acceptance: " ++ marker))

private def validate (raw : PsVerifiedIrModule) : IO PsValidatedIrModule :=
  match psStrictValidateModule raw with
  | .ok checked => pure checked
  | .error _ => throw (IO.userError "test fixture IR did not validate")

private def requireResult (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

def main (args : List String) : IO UInt32 := do
  rejectWith "PSC1_PYTHON_IR_VALIDATION_FAILED"
    (psPythonEmitModule { raw := badModule } [])
  rejectWith "PSC1_PHP_IR_VALIDATION_FAILED"
    (psPhpEmitValidatedModule { raw := badModule } [])
  let abi ← validate abiModule
  rejectWith "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED"
    (psPythonEmitModule abi ["readBox"])
  rejectWith "PSC1_PHP_PUBLIC_ABI_UNSUPPORTED"
    (psPhpEmitValidatedModule abi ["readBox"])
  let capture ← validate captureModule
  let python ← requireResult (psPythonEmitModule capture ["answer"])
  let php ← requireResult (psPhpEmitValidatedModule capture ["answer"])
  unless python.runtimeHelpers.contains "calls" && php.runtimeRequirements.contains "calls" do
    throw (IO.userError "closure call runtime was not selected")
  unless python.declarationLines.length == 1 && php.declarationLines.length == 1 do
    throw (IO.userError "declaration source origin missing")
  rejectWith "PSC1_PYTHON_DUPLICATE_PUBLIC_DECLARATION"
    (psPythonEmitModule capture ["answer", "answer"])
  rejectWith "PSC1_PHP_DUPLICATE_PUBLIC_DECLARATION"
    (psPhpEmitValidatedModule capture ["answer", "answer"])
  let emptyPython ← requireResult (psPythonEmitModule { raw := psVerifiedIrModuleEmpty } [])
  let emptyPhp ← requireResult (psPhpEmitValidatedModule { raw := psVerifiedIrModuleEmpty } [])
  unless emptyPython.runtimeSource.isEmpty && emptyPython.runtimeHelpers.isEmpty &&
      emptyPhp.runtimeSource.isEmpty && emptyPhp.runtimeRequirements.isEmpty do
    throw (IO.userError "empty checked module acquired runtime dependencies")
  if let some outputBase := args.head? then
    IO.FS.writeFile (outputBase ++ ".py") python.source
    IO.FS.writeFile (outputBase ++ ".php") php.source
  IO.println "Direct scripting IR boundaries: 8 groups passed"
  return 0
