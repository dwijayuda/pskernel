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
  let forgedRaw : PsVerifiedIrModule := { raw with
    declarations := raw.declarations.map (fun d => { d with body := .literal (.bool true) }) }
  require "forged source wrapper refuses"
    (match psWasmStringAbiMakePlan { raw := forgedRaw } ["echo"] false with
      | .error _ => true | .ok _ => false)
  let artifacts <- get (psWasmStringAbiComponent source plan adapted)
  require "mismatched component schema refuses"
    (match psWasmStringAbiComponent source { plan with exports := [{
      name := "echo",
      parameters := [], resultString := true }] } adapted with
      | .error _ => true | .ok _ => false)
  require "same-core-type forged result schema refuses"
    (match psWasmStringAbiComponent source { plan with exports := [{
      name := "echo",
      parameters := [("text", true)], resultString := false }] } adapted with
      | .error _ => true | .ok _ => false)
  IO.FS.createDirAll "dist/scoped-correctness/wasm-string-native"
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/echo-core.wasm"
    (ByteArray.mk artifacts.coreBytes.toArray)
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/echo-component.wasm"
    (ByteArray.mk artifacts.componentBytes.toArray)
  require "canonical String schema" (artifacts.wit ==
    "package proofscript:psc1;\n\nworld app {\n  export echo: func(text: string) -> string;\n}\n")


  -- Positional scalar ABI must survive source/target hygiene. A valid raw
  -- label arg0 beside an invalid internal label must not collide after mapping.
  let renamedDeclarations := raw.declarations.map fun d =>
    { d with
      parameters := [
        { name := "__ps_internal_arguments", type := .primitive .string },
        { name := "arg0", type := .primitive .bool }]
      body := .var "__ps_internal_arguments" }
  let renamedRaw : PsVerifiedIrModule := { raw with declarations := renamedDeclarations }
  let renamedSource <- match psStrictValidateModule renamedRaw with
    | .ok value => pure value
    | .error _ => throw (IO.userError "renamed test IR invalid")
  let renamedPlan <- get (psWasmStringAbiMakePlan renamedSource ["echo"] false)
  require "hygienic parameters get distinct ordered public labels"
    (renamedPlan.exports.map (fun x => x.parameters) == [[("arg0",true),("arg1",false)]])
  for label in ["type", "MixedCase", "unicodeΩ", "_temporary", "valid-label"] do
    let labelDeclarations := raw.declarations.map fun d =>
      { d with
        parameters := [{ name := label, type := .primitive .string }]
        body := .var label }
    let labelRaw : PsVerifiedIrModule := { raw with declarations := labelDeclarations }
    let labelSource <- match psStrictValidateModule labelRaw with
      | .ok value => pure value
      | .error _ => throw (IO.userError "label test IR invalid")
    let labelPlan <- get (psWasmStringAbiMakePlan labelSource ["echo"] false)
    let expected := if psWasmComponentWitIdent label then label else "arg0"
    require ("public label policy: " ++ label)
      (labelPlan.exports.map (fun x => x.parameters) == [[(expected,true)]])
  let renamedLowered <- match psWasmLowerSpecializedModule { wordSize := .wasm32 } renamedRaw with
    | .ok value => pure value
    | .error _ => throw (IO.userError "renamed test lower failed")
  let renamedAdapted <- get (psWasmStringAbiAdapt renamedPlan renamedSource renamedLowered)
  let renamedArtifacts <- get (psWasmStringAbiComponent renamedSource renamedPlan renamedAdapted)
  require "canonical label component WIT"
    (renamedArtifacts.wit == "package proofscript:psc1;\n\nworld app {\n  export echo: func(arg0: string, arg1: bool) -> string;\n}\n")
  let swappedExports := renamedPlan.exports.map fun x =>
    { x with parameters := [("arg0",false),("arg1",true)] }
  let swapped : PsWasmStringAbiPlan := { renamedPlan with exports := swappedExports }
  require "same flattened i32 signature cannot forge argument schema"
    (match psWasmStringAbiAdapt swapped renamedSource renamedLowered with
      | .error _ => true | .ok _ => false)
  require "component repeats source schema check after label adaptation"
    (match psWasmStringAbiComponent renamedSource swapped renamedAdapted with
      | .error _ => true | .ok _ => false)
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/renamed-core.wasm"
    (ByteArray.mk renamedArtifacts.coreBytes.toArray)
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/renamed-component.wasm"
    (ByteArray.mk renamedArtifacts.componentBytes.toArray)

  -- Exercise refusal before any foreign dispatch, without first constructing a
  -- giant JSON source literal. NUL bytes are valid owned UTF-8 scalars.
  let base := "Psc1.Test.Dispatch"
  let code := "Psc1.Test.Code"
  let oversized : PsWasmModule := { psWasmModuleEmpty with
    abiMemory := true
    structures := psWasmStringRuntimeStructures ++ [{
      name := base, superType := none, isFinal := true
      fields := [{ name := "code", storageType := .value .funcRef }] }]
    arrays := psWasmStringRuntimeArrays
    functionTypes := [{
      name := code, parameters := [.refT base, psWasmStringRef], results := [psWasmStringRef] }]
    functionImports := [{
      moduleName := "psc1:io", importName := "dispatch"
      function := {
        name := "__psc1_abi_host_dispatch", typeName := none
        parameters := [.i32, .i32, .i32], results := [], locals := [], body := [] } }]
    functions := psWasmStringAbiFunctions ++ [psWasmStringAbiDispatchFunction base code, {
      name := "oversize", typeName := none, parameters := [], results := [.i32], locals := []
      body := [
        .refFunc "__psc1_abi_dispatch_gc", .structNew base,
        .i32Const 16777153, .arrayNewDefault psWasmStringBytesName,
        .i32Const 16777153, .structNew psWasmStringName,
        .call "__psc1_abi_dispatch_gc", .call "__psc1_abi_to_memory"] }]
    functionRefs := ["__psc1_abi_dispatch_gc"]
    exports := [("oversize", "oversize")]
  }
  require "oversized dispatcher boundary passes strict target validation"
    (match psWasmIrValidateModule oversized with | .ok _ => true | .error _ => false)
  let bytes <- match psWasmEncodeModule oversized with
    | .ok value => pure value
    | .error _ => throw (IO.userError "oversized boundary binary failed")
  IO.FS.writeBinFile "dist/scoped-correctness/wasm-string-native/oversize-core.wasm"
    (ByteArray.mk bytes.toArray)
