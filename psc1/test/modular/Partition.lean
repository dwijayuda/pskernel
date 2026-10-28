import Ps.Host.ModularPilot

open Ps.Host.ModularPilot

namespace PartitionTest

def nat : PsVerifiedIrType := .primitive .nat
def literal (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
def call (name : String) (argument : PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (.var name) [] [argument]
def declaration (name : String) (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration := {
  name, typeParameters := [], parameters := [{ name := "value", type := nat }], resultType := nat, body
}
def conditional (parent : String) (base : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .ifE (.intrinsic .natEq [] [.var "value", literal 0]) base
    (call parent (.intrinsic .natSub [] [.var "value", literal 1]))
def raw : PsVerifiedIrModule := {
  psVerifiedIrModuleEmpty with declarations := [
    declaration "partitionA" (conditional "partitionB" (call "partitionLeaf" (literal 17))),
    declaration "partitionB" (conditional "partitionA" (literal 42)),
    declaration "partitionConsumer" (call "partitionA" (.var "value")),
    declaration "partitionLeaf" (.var "value")]
}
def owners : List PsModuleOwner := [
  { name := "partitionA", unit := 1 }, { name := "partitionB", unit := 2 },
  { name := "partitionConsumer", unit := 3 }, { name := "partitionLeaf", unit := 5 }]
def packages : List String := ["@proofscript/modular-pilot-runtime",
  "@proofscript/modular-pilot-a", "@proofscript/modular-pilot-b",
  "@proofscript/modular-pilot-consumer", "@proofscript/modular-pilot-types",
  "@proofscript/modular-pilot-leaf"]
def require (condition : Bool) (label : String) : IO Unit := do
  if !condition then throw (IO.userError label)
  IO.println ("PSC1_PARTITION_PASS " ++ label)
def refuse {α : Type} (value : Except String α) (label : String) : IO Unit := do
  match value with
  | .ok _ => throw (IO.userError ("unexpected partition acceptance:" ++ label))
  | .error code => IO.println ("PSC1_PARTITION_REFUSAL " ++ label ++ ":" ++ code)

def run : IO Unit := do
  let p ← liftResult (psPartitionModules raw owners packages)
  require (p.groups == [[0, 4], [5], [1, 2], [3]]) "minimal-scc-and-dependencies-first"
  require (p.sourceToUnit == [0, 2, 2, 3, 0, 1]) "total-deterministic-source-map"
  require (p.plan.packages.length == 4) "no-empty-package"
  require (p.plan.packages[2]? == some "@proofscript/modular-pilot-group-1-2") "stable-group-name"
  require ((psIrEncodeModule p.plan.raw).toOption == (psIrEncodeModule raw).toOption) "partition-preserves-ir-bytes"
  let again ← liftResult (psPartitionModules raw owners packages)
  require (again.sourceToUnit == p.sourceToUnit && again.groups == p.groups) "repeatable"
  require (p.plan.units.all (fun unit => unit.imports.all (fun item => item.unit < unit.index))) "quotient-dag"
  let shadowed ← liftResult (Ps.Internal.ModuleGraph.references 4096 []
    (.lambda [{ name := "partitionB", type := nat }] nat (.var "partitionB")))
  require shadowed.isEmpty "lexical-shadow-is-not-edge"
  require (Ps.Internal.ModulePartition.components [1, 2, 3, 4] [(1, 2), (2, 1), (3, 4), (4, 3)] ==
    [[1, 2], [3, 4]]) "separate-cycles-stay-separate"
  require (Ps.Internal.ModulePartition.components [1, 2] [(1, 1)] == [[1], [2]]) "self-cycle-and-isolate"
  let onlyTypes : PsVerifiedIrModule := { psVerifiedIrModuleEmpty with
    structures := [{ name := "PartitionPosition", typeParameters := [],
      fields := [{ name := "column", type := nat }] }] }
  let types ← liftResult (psPartitionModules onlyTypes [] packages)
  require (types.plan.units.length == 1 && types.sourceToUnit.all (fun unit => unit == 0))
    "all-type-only-runtime-owner"
  let _ ← liftResult (psEmitJsModules types.plan "type-only-fixture")
  let _ ← liftResult (psEmitTsModules types.plan "type-only-fixture")
  require true "type-only-both-emitters"
  refuse (psPlanModulesWithPackages raw owners packages "psc1-modular-pilot/2") "legacy-cycle-still-refused"
  refuse (psPartitionModules raw owners.tail packages) "missing-owner"
  refuse (psPartitionModules raw ({ name := "partitionA", unit := 9 } :: owners.tail) packages) "owner-range"
  refuse (psPartitionModules raw ({ name := "partitionB", unit := 1 } :: owners.tail) packages) "duplicate-owner"
  refuse (psPartitionModules raw owners (packages ++ List.replicate 4 "@proofscript/modular-pilot-extra")) "source-bound"
  refuse (psPartitionModules raw owners ["@proofscript/modular-pilot-runtime", "@proofscript/modular-pilot-a"]) "minimum-sources"
  refuse (psPartitionModules raw owners (packages.take 5 ++ ["../escape"])) "package-escape"
  refuse (psPartitionModules raw owners (packages.take 5 ++ ["@proofscript/modular-pilot-a"])) "package-collision"
  let initialized := { raw with declarations := raw.declarations ++ [{
    name := "eager", typeParameters := [], parameters := [], resultType := nat,
    body := call "partitionA" (literal 0) }] }
  refuse (psPartitionModules initialized (owners ++ [{ name := "eager", unit := 1 }]) packages) "eager-still-refused"
  refuse (psPartitionModules raw
    [{ name := "partitionA", unit := 0 }, { name := "partitionB", unit := 2 },
      { name := "partitionConsumer", unit := 3 }, { name := "partitionLeaf", unit := 5 }] packages) "runtime-dependency"
  refuse (Ps.Internal.ModulePartition.order 0 [(1, 2)] [0] [[1], [2]]) "bounded-order-fuel"
  let js ← liftResult (psEmitJsModules p.plan "partition-ir-fixture")
  let ts ← liftResult (psEmitTsModules p.plan "partition-ir-fixture")
  let lowered ← liftResult ((psJsLowerSpecializedModule raw).mapError (fun _ => "reference-lower"))
  let referenceJs ← liftResult ((psJsPrintModuleStackSafe lowered).mapError (fun _ => "reference-print"))
  let referenceTs ← liftResult ((psTsEmitModule raw).mapError (fun _ => "reference-ts"))
  IO.FS.writeFile "dist/modular/partition-fixture.json" (Lean.Json.mkObj [
    ("scope", .str "strict typed IR cycle fixture; not a source/Core admission or self-host claim"),
    ("groups", Lean.toJson p.groups), ("sourceToUnit", Lean.toJson p.sourceToUnit),
    ("packages", Lean.toJson p.plan.packages), ("js", Lean.toJson (js.map artifactJson)),
    ("ts", Lean.toJson (ts.map artifactJson)),
    ("referenceJs", .str referenceJs), ("referenceTs", .str referenceTs)]).compress
  IO.println "PSC1_PARTITION_TESTS_PASSED 12-invariants 11-refusals"

end PartitionTest

def main : IO Unit := PartitionTest.run
