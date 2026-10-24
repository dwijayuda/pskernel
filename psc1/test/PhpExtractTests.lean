import Ps.BackendPhp.Module
import PhpExtractReference

private def natT : PsVerifiedIrType := .primitive .nat
private def strT : PsVerifiedIrType := .primitive .string
private def p (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter := {name,type}
private def module : PsVerifiedIrModule := {
  imports := [], structures := [], inductives := [], declarations := [{
    name := "extract", typeParameters := [],
    parameters := [p "source" strT,p "begin" natT,p "end" natT],
    resultType := strT, body := .intrinsic .stringExtract [] [.var "source",.var "begin",.var "end"]
  }]
}
private def requireOk (value : Except String α) : IO α :=
  match value with
  | .error error => throw (IO.userError error)
  | .ok value => pure value

def main : IO Unit := do
  let checked <- match psStrictValidateModule module with
    | .error _ => throw (IO.userError "PHP extraction fixture did not strictly validate")
    | .ok value => pure value
  let actual <- requireOk (psPhpEmitModuleWithIo checked ["extract"] false)
  let retained <- requireOk (psPhpEmitModuleWithIoAndPolicies checked ["extract"] false true false)
  unless actual.composer == retained.composer && actual.declarations == retained.declarations do
    throw (IO.userError "PHP extraction unrelated API metadata changed")
  let requirements := psPhpRuntimeClosure ["stringExtract"]
  unless requirements == ["gmp","utf8Valid","unicodeChars","stringExtract"] do
    throw (IO.userError "PHP extraction dependency inventory changed")
  let oldRequirements := PsScriptRuntimeReference.Php.psPhpRuntimeClosure ["stringExtract"]
  unless psPhpRuntimeClosureWithExtractionPolicy ["stringExtract"] false == oldRequirements do
    throw (IO.userError "PHP retained extraction closure changed")
  IO.FS.createDirAll "dist/php-extract"
  IO.FS.writeFile "dist/php-extract/actual.php" actual.source
  IO.FS.writeFile "dist/php-extract/retained.php" retained.source
  IO.FS.writeFile "dist/php-extract/actual-helper.php"
    ("<?php\n" ++ psPhpSelectedRuntimeSource requirements ++ "\nreturn $__ps_stringExtract;\n")
  IO.FS.writeFile "dist/php-extract/retained-helper.php"
    ("<?php\n" ++ PsScriptRuntimeReference.Php.psPhpSelectedRuntimeSource oldRequirements ++ "\nreturn $__ps_stringExtract;\n")
  let result <- IO.Process.output {
    cmd := "php"
    args := #["-d","memory_limit=1G","scripts/php-extract-runtime-tests.php","dist/php-extract"]
  }
  unless result.exitCode == 0 do throw (IO.userError (result.stdout ++ result.stderr))
  IO.print result.stdout
