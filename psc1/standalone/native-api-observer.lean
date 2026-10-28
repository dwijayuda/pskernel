-- Native compatibility only. The identical observer is run against both trees.
import Ps.BackendCommon.Modules
import Ps.BackendPython.Module
import Ps.BackendPhp.Module
import Lean.Data.Json

example (v : PsValidatedIrModule) (names : List String) :
    psPythonEmitModule v names = psPythonEmitModuleWithIo v names false := rfl
example (v : PsValidatedIrModule) (names : List String) :
    psPythonEmitModule v names false = psPythonEmitModuleWithIo v names false := rfl
example (v : PsValidatedIrModule) (names : List String) :
    psPythonEmitModule v names (ioAbi := true) = psPythonEmitModuleWithIo v names true := rfl
example (v : PsValidatedIrModule) (names : List String) :
    psPhpEmitValidatedModule v names = psPhpEmitValidatedModule v names false := rfl
example (v : PsValidatedIrModule) (names : List String) :
    psPhpEmitValidatedModule v names (ioAbi := true) = psPhpEmitValidatedModule v names true := rfl
example :
    ({source := "fixture", names := []} : PsModuleImport).typeOnly = false := rfl
example :
    ({source := "fixture", names := [], typeOnly := true} : PsModuleImport).typeOnly = true := rfl
example :
    (PsModuleImport.mk "fixture" [] false).typeOnly = false := rfl
example :
    ({source := "", composer := "", runtimeSource := "", runtimeRequirements := [],
      declarations := [], declarationLines := []} : PsPhpPrintedModule).runtimeVersion = psPhpRuntimeVersion := rfl

def main : IO Unit := do
  let omitted : PsModuleImport := {source := "fixture", names := []}
  let explicit : PsModuleImport := {source := "fixture", names := [], typeOnly := true}
  let php : PsPhpPrintedModule := {source := "", composer := "", runtimeSource := "", runtimeRequirements := [], declarations := [], declarationLines := []}
  if omitted.typeOnly || !explicit.typeOnly || php.runtimeVersion != psPhpRuntimeVersion then
    throw (IO.userError "native compatibility default changed")
  IO.println (Lean.Json.mkObj [
    ("schema", .str "psc1-native-api-observer/1"),
    ("checkedEqualities", Lean.toJson (9 : Nat)),
    ("moduleImportOmittedTypeOnly", .bool omitted.typeOnly),
    ("moduleImportExplicitTypeOnly", .bool explicit.typeOnly),
    ("phpRuntimeVersion", .str php.runtimeVersion),
    ("nativeDefaultsPreserved", .bool true)]).compress
