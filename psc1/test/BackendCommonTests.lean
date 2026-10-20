import Ps.Host.ProjectCompiler
import Ps.BackendCommon.Plan
import Ps.BackendWasm.Component

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_BACKEND_COMMON_FAIL: " ++ name))
  IO.println ("PSC1_BACKEND_COMMON_PASS: " ++ name)

def main : IO Unit := do
  require "workspace import package BackendCommon"
    (psHostPackageDirectory ["Ps", "BackendCommon", "Module"] == some "backend-common")
  require "workspace import package BackendJs"
    (psHostPackageDirectory ["Ps", "BackendJs", "Module"] == some "backend-js")
  require "workspace import package BackendRust"
    (psHostPackageDirectory ["Ps", "BackendRust", "Module"] == some "backend-rust")
  require "workspace import package BackendWasm"
    (psHostPackageDirectory ["Ps", "BackendWasm", "Module"] == some "backend-wasm")
  require "workspace import package BackendPython"
    (psHostPackageDirectory ["Ps", "BackendPython", "Module"] == some "backend-python")
  require "workspace import package BackendPhp"
    (psHostPackageDirectory ["Ps", "BackendPhp", "Module"] == some "backend-php")
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
  let output <- match psBackendClosedPlan source ["answer"] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  require "shared closed plan retains public declaration"
    (output.raw.declarations.any (fun d => d.name == "answer"))
  require "missing public export rejects"
    (match psBackendCheckPublicApi .python output ["missing"] with | .error _ => true | .ok _ => false)
  require "duplicate public export rejects"
    (match psBackendCheckPublicApi .php output ["answer", "answer"] with | .error _ => true | .ok _ => false)

  let boolSource : PsValidatedIrModule := { raw := {
    imports := [], structures := [], inductives := []
    declarations := [{
      name := "identity", typeParameters := []
      parameters := [{ name := "value", type := .primitive .bool }]
      resultType := .primitive .bool, body := .var "value"
    }]
  }}
  let componentPlan <- match psWasmComponentMakePlan boolSource ["identity"] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let core : PsWasmModule := { psWasmModuleEmpty with
    functions := [{
      name := "identity", typeName := none, parameters := [.i32], results := [.i32]
      locals := [], body := [.localGet 0]
    }]
    exports := [("identity", "identity")]
  }
  let component <- match psWasmComponentEmit componentPlan core with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  require "direct component magic and version"
    (component.componentBytes.take 8 == [0, 97, 115, 109, 13, 0, 1, 0])
  require "one schema prints Bool calling convention"
    (component.wit == "package proofscript:psc1;\n\nworld app {\n  export identity: func(value: bool) -> bool;\n}\n")
  let invalidBoolSource : PsValidatedIrModule := { raw := {
    boolSource.raw with declarations := boolSource.raw.declarations.map fun d =>
      { d with body := .literal (.natural 1) }
  }}
  require "component schema rejects constructed invalid IR wrapper"
    (match psWasmComponentMakePlan invalidBoolSource ["identity"] with
      | .error _ => true | .ok _ => false)
  require "component schema refuses duplicate argument names"
    (match psWasmComponentValidatePlan { exports := [{ name := "both", parameters := ["value", "value"] }] } with
      | .error _ => true | .ok _ => false)
  require "component schema refuses indirect arguments without adapters"
    (match psWasmComponentValidatePlan { exports := [{
        name := "many", parameters := (List.range 17).map (fun n => "value" ++ toString n)
      }] } with | .error _ => true | .ok _ => false)
  require "component schema refuses duplicate exports"
    (match psWasmComponentValidatePlan { exports := componentPlan.exports ++ componentPlan.exports } with
      | .error _ => true | .ok _ => false)
  let wrongSignature : PsWasmModule := { core with functions := [{
    name := "identity", typeName := none, parameters := [.i32], results := [.i64]
    locals := [], body := [.i64Const 1]
  }] }
  require "component lift refuses a valid core with mismatched result signature"
    (match psWasmComponentEmit componentPlan wrongSignature with
      | .error "PSC1_COMPONENT_CORE_SIGNATURE_MISMATCH" => true | _ => false)
  let extraExport : PsWasmModule := { core with exports := [("identity", "identity"), ("extra", "identity")] }
  require "component lift refuses a different core export set"
    (match psWasmComponentEmit componentPlan extraExport with
      | .error "PSC1_COMPONENT_CORE_EXPORT_SET_MISMATCH" => true | _ => false)


  -- Exact token keywords from the pinned wasm-tools 1.254.0 WIT lexer.
  -- Public schema validation must refuse before emitting invalid WIT.
  for keyword in ["use", "type", "func", "u8", "u16", "u32", "u64", "s8", "s16", "s32", "s64", "f32", "f64", "char", "resource", "own", "borrow", "record", "flags", "variant", "enum", "bool", "string", "option", "result", "future", "stream", "error-context", "list", "map", "_", "as", "from", "static", "interface", "tuple", "world", "import", "export", "package", "constructor", "include", "with", "async"] do
    require ("WIT keyword is not a bare identifier: " ++ keyword)
      (!psWasmComponentWitIdent keyword)
    require ("WIT keyword export refuses: " ++ keyword)
      (match psWasmComponentValidatePlan { exports := [{ name := keyword, parameters := [] }] } with
        | .error "PSC1_COMPONENT_WIT_EXPORT_NAME_UNSUPPORTED" => true | _ => false)
    require ("WIT keyword argument refuses: " ++ keyword)
      (match psWasmComponentValidatePlan { exports := [{ name := "identity", parameters := [keyword] }] } with
        | .error "PSC1_COMPONENT_WIT_ARGUMENT_NAME_UNSUPPORTED" => true | _ => false)
  require "WIT keyword substring remains a legal identifier"
    (psWasmComponentWitIdent "option-value")
