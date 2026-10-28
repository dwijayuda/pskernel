import Ps.BackendJs.Emit
import Ps.BackendTs.Emit
import Ps.BackendRust.Emit
import Ps.BackendWasm.Emit

-- These imports must remain sufficient without the frontend/compiler driver.
namespace EmitterBoundaryTests

def require (condition : Bool) (label : String) : IO Unit :=
  if condition then pure () else throw (IO.userError label)

def raw : PsVerifiedIrModule :=
  { imports := [], structures := [], inductives := [], declarations := [
    { name := "answer", typeParameters := [], parameters := [], resultType := .primitive .nat,
      body := .literal (.natural 42) }] }

def emitted (label : String)
    (result : Except Ps.Internal.CompilerService.Error (String × List String)) : IO String :=
  match result with
  | .ok value => do
    require (!value.1.isEmpty) (label ++ ":empty")
    return value.1
  | .error error => throw (IO.userError (label ++ ":" ++ error.phase ++ ":" ++ error.code))

def main : IO Unit := do
  let validated ← match psStrictValidateModule raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError "strict-positive")
  let js ← emitted "js" (Ps.Internal.JsCompilerService.emit validated ["answer"])
  let ts ← emitted "ts" (Ps.Internal.TsCompilerService.emit validated ["answer"])
  let rust ← emitted "rust" (Ps.Internal.RustCompilerService.emit validated ["answer"])
  let wasm ← emitted "wasm" (Ps.Internal.WasmCompilerService.emit validated ["answer"])
  require (js.contains '4' && ts.contains '4' && rust.contains '4') "literal-retained"
  require (wasm.startsWith "psc1-wasm-hex/1:") "wasm-owned-bytes"
  let malformed := { raw with declarations := [
    { name := "wrong", typeParameters := [], parameters := [], resultType := .primitive .nat,
      body := .literal (.bool true) }] }
  match psStrictValidateModule malformed with
  | .ok _ => throw (IO.userError "ill-typed-ir-accepted")
  | .error _ => pure ()
  let error := Ps.Internal.CompilerService.failure "emission" "refused"
  require (error.phase == "emission" && error.code == "refused" &&
    error.moduleName == "" && error.declaration == "" && error.line == 0 && error.column == 0)
    "shared-error-contract"
  IO.FS.createDirAll "dist/executable-packages/emitted"
  IO.FS.writeFile "dist/executable-packages/emitted/candidate.mjs" js
  IO.FS.writeFile "dist/executable-packages/emitted/candidate.mts" ts
  IO.FS.writeFile "dist/executable-packages/emitted/candidate.rs" rust
  IO.FS.writeFile "dist/executable-packages/emitted/candidate.wasm.hex" wasm
  IO.println "PSC1_PRODUCTION_EMITTER_BOUNDARY_PASS four-real-emitters strict-positive strict-negative preserved-error-data"
  IO.println "Scope: target candidates from strict IR; independent Core admission remains a separate host obligation."

end EmitterBoundaryTests

def main : IO Unit := EmitterBoundaryTests.main
