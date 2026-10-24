import Ps.BackendPython.Module
import Ps.BackendCommon.DirectCalls

theorem psBackendDirectBudgetFallback (known values : PsStringSet)
    (bound : List String) (expr : PsVerifiedIrExpr) :
    psBackendDirectSafeWithFuel 0 known values bound expr = false := by rfl

private def natT : PsVerifiedIrType := .primitive .nat
private def fnT : PsVerifiedIrType := .function [natT] natT
private def p (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter := {name, type}
private def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
private def call (name : String) (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (.var name) [] arguments
private def d (name : String) (parameters : List PsVerifiedIrParameter) (resultType : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration := {name, parameters, resultType, body, typeParameters := []}
private def module : PsVerifiedIrModule := {
  imports := [], structures := [], inductives := [], declarations := [
    d "leaf" [p "x" natT] natT (.intrinsic .natAdd [] [.var "x",n 1]),
    d "wrap" [p "x" natT] natT (call "leaf" [.var "x"]),
    d "third" [p "x" natT] natT (call "wrap" [.var "x"]),
    d "self" [p "x" natT] natT
      (.ifE (.intrinsic .natEq [] [.var "x",n 0]) (n 0)
        (call "self" [.intrinsic .natSub [] [.var "x",n 1]])),
    d "apply" [p "fn" fnT,p "x" natT] natT (call "fn" [.var "x"]),
    d "shadow" [p "leaf" fnT,p "x" natT] natT (call "leaf" [.var "x"]),
    d "alias" [] fnT (.var "self"),
    d "useAlias" [p "x" natT] natT (call "alias" [.var "x"]),
    d "localShadow" [p "x" natT] natT
      (.letE "leaf" fnT (.var "self") (call "leaf" [.var "x"])),
    d "run" [p "x" natT] natT
      (.intrinsic .natAdd [] [
        call "third" [.var "x"],
        .intrinsic .natAdd [] [call "useAlias" [.var "x"], .intrinsic .natAdd [] [call "localShadow" [.var "x"], .intrinsic .natAdd [] [call "apply" [.var "self",.var "x"],call "shadow" [.var "self",.var "x"]]]]])
  ]
}
private def requireOk (value : Except String α) : IO α :=
  match value with
  | .error error => throw (IO.userError error)
  | .ok result => pure result

def main : IO Unit := do
  let known := psBackendDirectCallNames module.declarations
  unless psStringSetContains known "leaf" && psStringSetContains known "wrap" do
    throw (IO.userError "two immutable pure layers not selected")
  for name in ["third","self","apply","shadow","alias","useAlias","localShadow","run"] do
    when psStringSetContains known name do throw (IO.userError ("unsafe direct selection: " ++ name))
  let reversed := psBackendDirectCallNames module.declarations.reverse
  for name in ["leaf","wrap","third","self","alias","useAlias"] do
    unless psStringSetContains known name == psStringSetContains reversed name do
      throw (IO.userError "declaration order changed direct layers")
  unless !psBackendDirectGlobalCall known ["leaf"] (.var "leaf") &&
      !psBackendDirectGlobalCall known [] (.lambda [p "x" natT] natT (.var "x")) &&
      !psBackendDirectIntrinsic .arrayMap && !psBackendDirectIntrinsic .arrayFoldl &&
      !psBackendDirectIntrinsic (.machineIntBinary .uint32 .add) do
    throw (IO.userError "shadow/dynamic/callback/unsupported direct-call refusal")
  let captured := psBackendDirectSafeWithFuel 32 known PsStringSet.empty []
    (.lambda [p "leaf" fnT] natT (call "leaf" [n 1]))
  when captured do throw (IO.userError "nested callback shadow incorrectly pure")
  let checked <- match psStrictValidateModule module with
    | .error _ => throw (IO.userError "direct-call fixture did not strictly validate")
    | .ok checked => pure checked
  let actual <- requireOk (psPythonEmitModuleWithIoAndDirectCalls checked ["run"] false true)
  let legacy <- requireOk (psPythonEmitModuleWithIoAndDirectCalls checked ["run"] false false)
  unless actual.stub == legacy.stub && actual.runtimeHelpers == legacy.runtimeHelpers &&
      actual.runtimeSource == legacy.runtimeSource && actual.declarationLines == legacy.declarationLines do
    throw (IO.userError "direct-call unrelated metadata changed")
  IO.FS.createDirAll "dist/python-direct"
  IO.FS.writeFile "dist/python-direct/actual.py" actual.source
  IO.FS.writeFile "dist/python-direct/legacy.py" legacy.source
  let boundary <- IO.Process.output {
    cmd := "python3"
    args := #["-I","scripts/python-utf8-token-comparison.py","dist/python-direct/actual.py","dist/python-direct/legacy.py"]
  }
  unless boundary.exitCode == 0 do throw (IO.userError (boundary.stdout ++ boundary.stderr))
  IO.print boundary.stdout
  let runtime <- IO.Process.output {
    cmd := "python3"
    args := #["-I","scripts/python-direct-call-tests.py","dist/python-direct"]
  }
  unless runtime.exitCode == 0 do throw (IO.userError (runtime.stdout ++ runtime.stderr))
  IO.print runtime.stdout
