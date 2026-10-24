import Ps.BackendPython.Module
import Lean.Data.Json

theorem psPythonNoLambdaBudget (expr : PsVerifiedIrExpr) :
    PsPython.noLambdaWithFuel 0 expr = false := by rfl
theorem psPythonSelfTailBudget (name : String) (arity : Nat) (bound : List String) (expr : PsVerifiedIrExpr) :
    PsPython.hasSelfTailWithFuel name arity 0 bound expr = false := by rfl

private def natT : PsVerifiedIrType := .primitive .nat
private def strT : PsVerifiedIrType := .primitive .string
private def thunkT : PsVerifiedIrType := .function [] natT
private def binaryT : PsVerifiedIrType := .function [natT,natT] natT
private def ioT : PsVerifiedIrType := .function [strT] strT
private def chainT : PsVerifiedIrType := .named "Chain" []
private def p (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter := {name,type}
private def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
private def s (value : String) : PsVerifiedIrExpr := .literal (.string value)
private def call (name : String) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (.var name) [] args
private def dec : PsVerifiedIrExpr := .intrinsic .natSub [] [.var "fuel",n 1]
private def zero : PsVerifiedIrExpr := .intrinsic .natEq [] [.var "fuel",n 0]
private def d (name : String) (parameters : List PsVerifiedIrParameter) (resultType : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration := {name,parameters,resultType,body,typeParameters := []}
private def chain : PsVerifiedIrInductive := {name := "Chain",typeParameters := [],constructors := [
  {name := "nil",fields := []},
  {name := "cons",fields := [{name := "head",type := natT},{name := "tail",type := chainT}]}
]}
private def module : PsVerifiedIrModule := {
  imports := [],structures := [],inductives := [chain],declarations := [
    d "count" [p "fuel" natT,p "acc" natT] natT
      (.ifE zero (.var "acc") (call "count" [dec,.intrinsic .natAdd [] [.var "acc",n 1]])),
    d "swap" [p "fuel" natT,p "left" natT,p "right" natT] natT
      (.ifE zero (.intrinsic .natAdd [] [.intrinsic .natMul [] [.var "left",n 1000000],.var "right"])
        (call "swap" [dec,.var "right",.var "left"])),
    d "build" [p "fuel" natT,p "acc" chainT] chainT
      (.ifE zero (.var "acc") (call "build" [dec,.constructor "Chain" "cons" [] [("head",.var "fuel"),("tail",.var "acc")]])),
    d "length" [p "items" chainT,p "acc" natT] natT
      (.matchE "Chain" [] (.var "items") [
        ("nil",([],.var "acc")),
        ("cons",([{field := "tail",name := "rest",type := chainT},{field := "head",name := "head",type := natT}],
          call "length" [.var "rest",.intrinsic .natAdd [] [.var "acc",n 1]]))]),
    d "chain" [p "fuel" natT] natT
      (call "length" [call "build" [.var "fuel",.constructor "Chain" "nil" [] []],n 0]),
    d "closure" [p "fuel" natT,p "acc" thunkT] natT
      (.ifE zero (call "acc" [])
        (.letE "next" thunkT (.lambda [] natT (.var "fuel")) (call "closure" [dec,.var "next"]))),
    d "closureRun" [p "fuel" natT] natT (call "closure" [.var "fuel",.lambda [] natT (n 0)]),
    d "add2" [p "left" natT,p "right" natT] natT (.intrinsic .natAdd [] [.var "left",.var "right"]),
    d "shadow" [p "shadow" binaryT,p "fuel" natT] natT (call "shadow" [.var "fuel",.var "fuel"]),
    d "shadowRun" [p "fuel" natT] natT (call "shadow" [.var "add2",.var "fuel"]),
    d "ordered" [p "fuel" natT,p "dispatcher" ioT,p "left" strT,p "right" strT] strT
      (.ifE zero (.intrinsic .stringAppend [] [.var "left",.var "right"])
        (call "ordered" [dec,.var "dispatcher",
          call "dispatcher" [.intrinsic .stringAppend [] [s "first:",.intrinsic .intRepr [] [.intrinsic .intOfNat [] [.var "fuel"]]]],
          call "dispatcher" [.intrinsic .stringAppend [] [s "second:",.intrinsic .intRepr [] [.intrinsic .intOfNat [] [.var "fuel"]]]]]))
  ]
}
private def requireOk (value : Except String α) : IO α :=
  match value with
  | .error error => throw (IO.userError error)
  | .ok value => pure value

def main : IO Unit := do
  unless !PsPython.noLambdaWithFuel 4096 (.lambda [] natT (n 0)) &&
      !PsPython.exactSelfCall "shadow" 2 ["shadow","fuel"] (call "shadow" [n 1,n 2]) do
    throw (IO.userError "Python lexical capture/shadow loop guard")
  let checked <- match psStrictValidateModule module with
    | .error _ => do
        let report := psCheckVerifiedIrModule psIrCheckDefaultOptions module
        for finding in report.findings do IO.println (finding.code ++ ":" ++ finding.owner ++ ":" ++ finding.detail)
        throw (IO.userError "Python loop fixture did not strictly validate")
    | .ok checked => pure checked
  let names := ["count","swap","chain","closureRun","shadowRun","ordered"]
  let actual <- requireOk (psPythonEmitModuleWithIoAndOptimizations checked names true true true)
  let retained <- requireOk (psPythonEmitModuleWithIoAndOptimizations checked names true true false)
  unless actual.stub == retained.stub && actual.runtimeHelpers == retained.runtimeHelpers &&
      actual.runtimeSource == retained.runtimeSource &&
      actual.declarationLines.map Prod.fst == retained.declarationLines.map Prod.fst do
    throw (IO.userError "Python loop unrelated runtime/stub/origin identities")
  let lines := actual.source.splitOn "\n"
  for declaration in module.declarations do
    let entry <- match actual.declarationLines.find? (fun entry => entry.1 == declaration.name) with
      | .none => throw (IO.userError "missing loop declaration origin")
      | .some entry => pure entry
    match lines[entry.2 - 1]? with
    | .some line =>
        unless entry.2 > 0 && line.startsWith ("def " ++ PsPython.globalName declaration.name ++ "(") do
          throw (IO.userError "wrong loop declaration origin")
    | .none => throw (IO.userError "loop declaration origin out of source")
  IO.FS.createDirAll "dist/python-tail"
  IO.FS.writeFile "dist/python-tail/actual.py" actual.source
  IO.FS.writeFile "dist/python-tail/retained.py" retained.source
  let boundary <- IO.Process.output {
    cmd := "python3",args := #["-I","scripts/python-utf8-token-comparison.py","dist/python-tail/actual.py","dist/python-tail/retained.py"] }
  unless boundary.exitCode == 0 do throw (IO.userError (boundary.stdout ++ boundary.stderr))
  IO.print boundary.stdout
  let runtime <- IO.Process.output {
    cmd := "python3",args := #["-I","scripts/python-tail-loop-tests.py","dist/python-tail"] }
  unless runtime.exitCode == 0 do throw (IO.userError (runtime.stdout ++ runtime.stderr))
  IO.print runtime.stdout
