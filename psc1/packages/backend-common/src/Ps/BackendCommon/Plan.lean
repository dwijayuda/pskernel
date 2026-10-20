import Ps.CompilerIr.Validate

/-- Built-in targets share admission and IR. A target is not a trust provider. -/
inductive PsBackendTarget where
  | js | ts | rust | wasmCore | wasmComponent | python | php
  deriving BEq, Repr

def psBackendTargets : List PsBackendTarget :=
  [.js, .ts, .rust, .wasmCore, .wasmComponent, .python, .php]

def psBackendTargetName : PsBackendTarget → String
  | .js => "js"
  | .ts => "ts"
  | .rust => "rust"
  | .wasmCore => "wasm-core"
  | .wasmComponent => "wasm-component"
  | .python => "python"
  | .php => "php"

def psBackendTargetFromName : String → Option PsBackendTarget
  | "js" => some .js
  | "ts" => some .ts
  | "rust" => some .rust
  | "wasm-core" => some .wasmCore
  | "wasm-component" => some .wasmComponent
  | "python" => some .python
  | "php" => some .php
  | _ => none

def psBackendTargetExtension : PsBackendTarget → String
  | .js => ".js"
  | .ts => ".ts"
  | .rust => ".rs"
  | .wasmCore | .wasmComponent => ".wasm"
  | .python => ".py"
  | .php => ".php"

def psBackendRuntimeContractVersion : String := "psc1-runtime-semantics/1"

def psBackendActivePrimitive : PsVerifiedIrPrimitiveType → Bool
  | .nat | .int | .bool | .char | .string | .unit => true
  | _ => false

/-- This is a target capability boundary, not a preservation theorem.
Rust retains its checked generic ABI. Dynamic source targets initially expose
the same scalar signatures as JS/TS; aggregate values remain internal. -/
partial def psBackendPublicTypeSupported (target : PsBackendTarget)
    (type : PsVerifiedIrType) : Bool :=
  match type with
  | .unknown => false
  | .primitive scalar =>
      if target == .wasmComponent then
        match scalar with | .bool => true | _ => false
      else psBackendActivePrimitive scalar
  | .typeParameter _ => target == .rust
  | .function parameters result =>
      (target == .rust || target == .wasmCore) &&
        parameters.all (psBackendPublicTypeSupported target) &&
        psBackendPublicTypeSupported target result
  | .named _ arguments =>
      (target == .rust || target == .wasmCore) &&
        arguments.all (psBackendPublicTypeSupported target)

def psBackendCheckPublicApi (target : PsBackendTarget)
    (source : PsValidatedIrModule) (publicNames : List String) : Except String Unit := do
  if publicNames.eraseDups.length != publicNames.length then
    throw "PSC1_PUBLIC_DECLARATION_DUPLICATE"
  for name in publicNames do
    let some declaration := source.raw.declarations.find? (fun d => d.name == name)
      | throw ("PSC1_PUBLIC_DECLARATION_MISSING: " ++ name)
    if target != .rust && !declaration.typeParameters.isEmpty then
      throw ("PSC1_PUBLIC_GENERIC_SIGNATURE_UNQUALIFIED: " ++ name)
    if !psBackendPublicTypeSupported target declaration.resultType ||
        !declaration.parameters.all (fun p => psBackendPublicTypeSupported target p.type) then
      throw ("PSC1_PUBLIC_TARGET_SIGNATURE_UNQUALIFIED: " ++ psBackendTargetName target ++ ":" ++ name)

/-- One deterministic, closed specialized plan can feed multiple printers.
The wrapper is deliberately revalidated: constructing its data is not evidence
of independent logical admission. Only the host's captured session can publish. -/
def psBackendClosedPlan (source : PsValidatedIrModule)
    (publicNames : List String) : Except String PsValidatedIrModule := do
  let input ← match psStrictValidateModule source.raw with
    | .ok value => pure value
    | .error _ => throw "PSC1_BACKEND_INPUT_IR_INVALID"
  let specialized ← match psIrSpecializeValidatedModule input with
    | .ok value => pure value
    | .error _ => throw "PSC1_BACKEND_SPECIALIZATION_FAILED"
  let output ← match psStrictValidateModule specialized.raw with
    | .ok value => pure value
    | .error _ => throw "PSC1_BACKEND_SPECIALIZED_IR_INVALID"
  for name in publicNames do
    if !output.raw.declarations.any (fun d => d.name == name) then
      throw ("PSC1_PUBLIC_DECLARATION_LOST: " ++ name)
  return output
