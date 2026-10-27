import Ps.BackendCommon.Modules
import Ps.CompilerIr.WorkerFusion
import Ps.CompilerIr.Encode

namespace TransformOriginTest

def nat : PsVerifiedIrType := .primitive .nat

def generic : PsVerifiedIrDeclaration := {
  name := "genericIdentity"
  typeParameters := [{ name := "T" }]
  parameters := [{ name := "value", type := .typeParameter "T" }]
  resultType := .function [.typeParameter "T"] (.typeParameter "T")
  body := .lambda [{ name := "other", type := .typeParameter "T" }] (.typeParameter "T") (.var "value")
}

def curved : PsVerifiedIrDeclaration := {
  name := "curved"
  typeParameters := []
  parameters := [{ name := "left", type := nat }]
  resultType := .function [nat] nat
  body := .lambda [{ name := "right", type := nat }] nat
    (.intrinsic .natAdd [] [.var "left", .var "right"])
}

def caller : PsVerifiedIrDeclaration := {
  name := "caller"
  typeParameters := []
  parameters := [{ name := "value", type := nat }]
  resultType := nat
  body := .call (.call (.var "curved") [] [
    .call (.call (.var "genericIdentity") [nat] [.var "value"]) [] [.literal (.natural 0)]]) [] [.literal (.natural 1)]
}

def collision : PsVerifiedIrDeclaration := {
  name := "curved$worker"
  typeParameters := []
  parameters := []
  resultType := nat
  body := .literal (.natural 17)
}

def input : PsVerifiedIrModule := {
  psVerifiedIrModuleEmpty with declarations := [generic, curved, caller, collision]
}

def owners : List PsModuleOwner := [
  { name := "genericIdentity", unit := 1 },
  { name := "curved", unit := 1 },
  { name := "caller", unit := 2 },
  { name := "curved$worker", unit := 2 }
]

def require (condition : Bool) (label : String) : IO Unit :=
  if condition then IO.println ("PSC1_TRANSFORM_ORIGIN_PASS " ++ label)
  else throw (IO.userError label)

def value {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok found => pure found
  | .error code => throw (IO.userError code)

def refusal {α : Type} (result : Except String α) (label : String) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected acceptance " ++ label))
  | .error code => IO.println ("PSC1_TRANSFORM_ORIGIN_REFUSAL " ++ label ++ ":" ++ code)

def check : IO Unit := do
  let checked ← value ((psStrictValidateModule input).mapError (fun _ => "fixture invalid"))
  let specialized ← value ((psIrSpecializeValidatedModuleWithOrigins checked).mapError psIrSpecializeDiagnosticText)
  let normal ← value ((psIrSpecializeValidatedModuleWithMode checked false).mapError psIrSpecializeDiagnosticText)
  require normal.origins.isEmpty "legacy-specialization-tracing-disabled"
  let normalWorker ← value (psFuseClosedWorkersWithMode (.mk normal.raw) false)
  require normalWorker.origins.isEmpty "legacy-worker-tracing-disabled"
  let selected ← value (psModuleCarryOwners input owners specialized)
  let genericRows := specialized.origins.filter (fun row =>
    row.inputName == "genericIdentity" && psModuleOriginKindEqual row.kind .declaration)
  require (genericRows.length == 1) "one-actual-generic-instantiation"
  let [clone] := genericRows | throw (IO.userError "generic origin count")
  require (!clone.arguments.isEmpty && clone.outputName != clone.inputName) "explicit-type-arguments-and-name"
  require ((← value (Ps.Internal.ModuleGraph.owner selected clone.outputName)).unit == 1) "specialized-parent-owner"
  let fused ← value (psFuseClosedWorkersWithOrigins (.mk specialized.raw))
  let fusedOwners ← value (psModuleCarryOwners specialized.raw selected fused)
  let workers := fused.origins.filter (fun row => match row.rule with | .worker => true | _ => false)
  require (workers.length == 2) "two-worker-companions"
  let [worker] := workers.filter (fun row => row.inputName == "curved") | throw (IO.userError "worker origin count")
  require (worker.inputName == "curved" && worker.outputName != "curved$worker") "fresh-name-collision"
  require ((← value (Ps.Internal.ModuleGraph.owner fusedOwners worker.outputName)).unit == 1) "worker-parent-owner"
  require ((← value (Ps.Internal.ModuleGraph.owner fusedOwners "curved$worker")).unit == 2) "authored-lookalike-owner"
  let [clonedWorker] := workers.filter (fun row => row.inputName == clone.outputName)
    | throw (IO.userError "specialized worker origin count")
  require ((← value (Ps.Internal.ModuleGraph.owner fusedOwners clonedWorker.outputName)).unit == 1)
    "specialization-to-worker-owner-composition"
  require (clonedWorker.inputName == clone.outputName) "explicit-two-stage-parent-chain"
  let originalApi ← value ((psIrSpecializeValidatedModule checked).mapError (fun _ => "legacy specialize failed"))
  let oldFusion ← value (psFuseClosedWorkers (.mk originalApi.raw))
  require ((psIrEncodeModule oldFusion.raw).toOption == (psIrEncodeModule fused.raw).toOption) "legacy-api-byte-parity"
  refusal (psModuleCarryOwners input owners { specialized with origins := specialized.origins.tail }) "missing-origin"
  refusal (psModuleCarryOwners input owners
    { specialized with origins := { clone with inputName := "missing" } :: specialized.origins.tail }) "unknown-parent"
  refusal (psModuleCarryOwners input owners
    { specialized with origins := { clone with arguments := [.typeParameter "T"] } :: specialized.origins.tail }) "open-arguments"
  refusal (psModuleCarryOwners input owners
    { specialized with origins := clone :: clone :: specialized.origins.drop 2 }) "duplicate-output"
  refusal (psModuleCarryOwners input owners
    { specialized with origins := { clone with outputName := "missing" } :: specialized.origins.tail }) "unknown-output"
  refusal (psModuleCarryOwners specialized.raw selected
    { fused with origins := workers ++ workers ++ fused.origins.drop 2 }) "duplicate-worker"
  refusal (psModuleCarryOwners input [] specialized) "missing-input-owners"
  let invalid := { fused.raw with declarations := [{ caller with body := .var "unbound" }] }
  refusal (psModuleCarryOwners specialized.raw selected { fused with raw := invalid }) "invalid-output-ir"
  IO.println "PSC1_TRANSFORM_ORIGINS_TESTS_PASSED 12-invariants 8-refusals"

end TransformOriginTest

def main : IO Unit := TransformOriginTest.check
