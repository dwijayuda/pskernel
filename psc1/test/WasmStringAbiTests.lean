import Ps.BackendWasm.StringComponent
import Ps.BackendWasm.Lower

private def require (label : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_WASM_STRING_ABI_FAIL: " ++ label))
  IO.println ("PSC1_WASM_STRING_ABI_PASS: " ++ label)

private def get {A : Type} (value : Except String A) : IO A :=
  match value with | .ok value => pure value | .error error => throw (IO.userError error)

def main : IO Unit := do
  let raw : PsVerifiedIrModule := {
    imports := [], structures := [], inductives := []
    declarations := [{
      name := "echo", typeParameters := []
      parameters := [{ name := "text", type := .primitive .string }]
      resultType := .primitive .string, body := .var "text" }]
  }
  let source <- match psStrictValidateModule raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError "test IR invalid")
  require "default component String refusal remains"
    (match psBackendCheckPublicApi .wasmComponent source ["echo"] with
      | .error _ => true | .ok _ => false)
  let plan <- get (psWasmStringAbiMakePlan source ["echo"] false)
  let lowered <- match psWasmLowerSpecializedModule { wordSize := .wasm32 } raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError "test lower failed")
  let adapted <- get (psWasmStringAbiAdapt plan source lowered)
  require "adapted module passes structural and operand validation"
    (match psWasmIrValidateModule adapted with | .ok _ => true | .error _ => false)
  require "memory op without ABI refuses"
    (match psWasmIrValidateModule { adapted with abiMemory := false } with
      | .error _ => true | .ok _ => false)
  let malformed : PsWasmModule := { psWasmModuleEmpty with
    abiMemory := true, functions := [{
      name := "bad", typeName := none
      parameters := [], results := [], locals := [], body := [.i32Store 0] }] }
  require "memory operand underflow refuses"
    (match psWasmIrValidateModule malformed with | .error _ => true | .ok _ => false)
  let foreign := { adapted with functionImports := [{
    moduleName := "arbitrary", importName := "foreign"
    function := {
      name := "foreign", typeName := none
      parameters := [.i32, .i32, .i32], results := [], locals := [], body := [] } }] }
  require "unqualified foreign import refuses"
    (match psWasmIrValidateModule foreign with | .error _ => true | .ok _ => false)
  require "forged source wrapper refuses"
    (match psWasmStringAbiMakePlan { raw := { raw with declarations :=
      raw.declarations.map (fun d => { d with body := .literal (.bool true) }) } } ["echo"] false with
      | .error _ => true | .ok _ => false)
  let artifacts <- get (psWasmStringAbiComponent source plan adapted)
  require "mismatched component schema refuses"
    (match psWasmStringAbiComponent source { plan with exports := [{
      name := "echo",
      parameters := [], resultString := true }] } adapted with
      | .error _ => true | .ok _ => false)
  require "same-core-type forged result schema refuses"
    (match psWasmStringAbiComponent source { plan with exports := [{ name := "echo",
      parameters := [("text", true)], resultString := false }] } adapted with
      | .error _ => true | .ok _ => false)
  IO.FS.createDirAll "dist/scoped-correctness/wasm-string-native"
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/echo-core.wasm"
    (ByteArray.mk artifacts.coreBytes.toArray)
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/echo-component.wasm"
    (ByteArray.mk artifacts.componentBytes.toArray)
  require "canonical String schema" (artifacts.wit ==
    "package proofscript:psc1;\n\nworld app {\n  export echo: func(text: string) -> string;\n}\n")
