import Ps.BackendCommon.Plan

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_BACKEND_COMMON_FAIL: " ++ name))
  IO.println ("PSC1_BACKEND_COMMON_PASS: " ++ name)

def main : IO Unit := do
  for target in [PsBackendTarget.js, .ts, .rust, .wasmCore, .wasmComponent, .python, .php] do
    require ("target identity " ++ psBackendTargetName target)
      (psBackendTargetFromName (psBackendTargetName target) == some target)
  require "unknown target rejects" ((psBackendTargetFromName "typescript-via-js").isNone)
  require "component Bool" (psBackendPublicTypeSupported .wasmComponent (.primitive .bool))
  require "component Nat remains unavailable" (!psBackendPublicTypeSupported .wasmComponent (.primitive .nat))
  require "Python scalar" (psBackendPublicTypeSupported .python (.primitive .int))
  require "PHP machine scalar rejects" (!psBackendPublicTypeSupported .php (.primitive .uint64))
  let raw : PsVerifiedIrModule := {
    imports := [], structures := [], inductives := []
    declarations := [{
      name := "answer", typeParameters := [], parameters := []
      resultType := .primitive .nat, body := .literal (.natural 42)
    }]
  }
  let forged : PsValidatedIrModule := { raw := {
    raw with declarations := raw.declarations.map fun d => { d with body := .literal (.bool true) }
  }}
  require "constructed invalid wrapper refuses shared plan"
    (match psBackendClosedPlan forged ["answer"] with | .error _ => true | .ok _ => false)
  let source : PsValidatedIrModule := { raw := raw }
  let output ← match psBackendClosedPlan source ["answer"] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  require "shared closed plan retains public declaration"
    (output.raw.declarations.any (fun d => d.name == "answer"))
  require "missing public export rejects"
    (match psBackendCheckPublicApi .python output ["missing"] with | .error _ => true | .ok _ => false)
  require "duplicate public export rejects"
    (match psBackendCheckPublicApi .php output ["answer", "answer"] with | .error _ => true | .ok _ => false)
