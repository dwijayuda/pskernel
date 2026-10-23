import Ps.CompilerIr.Validate
import Ps.BackendPhp.Module
import Lean.Data.Json

namespace PhpUtf8Fixture
def stringT : PsVerifiedIrType := .primitive .string
def natT : PsVerifiedIrType := .primitive .nat
def raw : PsVerifiedIrModule := .mk [] [] [] [
  .mk "peek" [] [.mk "text" stringT,.mk "offset" natT] (.primitive .char)
    (.intrinsic .stringGet [] [.var "text",.var "offset"]),
  .mk "step" [] [.mk "text" stringT,.mk "offset" natT] natT
    (.intrinsic .stringNext [] [.var "text",.var "offset"]),
  .mk "extract" [] [.mk "text" stringT,.mk "start" natT,.mk "stop" natT] stringT
    (.intrinsic .stringExtract [] [.var "text",.var "start",.var "stop"]),
  .mk "append" [] [.mk "left" stringT,.mk "right" stringT] stringT
    (.intrinsic .stringAppend [] [.var "left",.var "right"])
]
def echo : PsVerifiedIrModule := .mk [] [] [] [
  .mk "echo" [] [.mk "text" stringT] stringT (.var "text")
]
end PhpUtf8Fixture

private def emitChecked (raw : PsVerifiedIrModule) (names : List String) : IO PsPhpPrintedModule := do
  let validated ← match psStrictValidateModule raw with
    | .error _ => throw (IO.userError "PSC1_PHP_UTF8_FIXTURE_IR_REFUSED")
    | .ok value => pure value
  match psPhpEmitValidatedModule validated names with
  | .error error => throw (IO.userError error)
  | .ok printed => pure printed

def main : IO Unit := do
  let mainModule ← emitChecked PhpUtf8Fixture.raw ["peek","step","extract","append"]
  let echoModule ← emitChecked PhpUtf8Fixture.echo ["echo"]
  if !echoModule.runtimeRequirements.isEmpty then
    throw (IO.userError "PSC1_PHP_STRING_ECHO_RUNTIME_FREE_REGRESSION")
  IO.FS.createDirAll "dist/scoped-correctness/php-utf8"
  IO.FS.writeFile "dist/scoped-correctness/php-utf8/module.php" mainModule.source
  IO.FS.writeFile "dist/scoped-correctness/php-utf8/echo.php" echoModule.source
  let helperSource := psPhpSelectedRuntimeSource (psPhpRuntimeClosure ["stringNext"])
  IO.FS.writeFile "dist/scoped-correctness/php-utf8/runtime.php"
    ("<?php\ndeclare(strict_types=1);\nreturn (static function (): array {\n" ++ helperSource ++
     "return ['get' => $__ps_stringGet, 'next' => $__ps_stringNext];\n})();\n")
  IO.FS.writeFile "dist/scoped-correctness/php-utf8/requirements.json"
    (Lean.Json.compress (Lean.toJson mainModule.runtimeRequirements) ++ "\n")
  IO.println "PSC1_PHP_UTF8_FIXTURE: strict-IR target and exact runtime emitted; backend test, not source admission"
