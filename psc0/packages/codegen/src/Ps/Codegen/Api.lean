import Ps.Codegen.Artifact

inductive PsApiExposure where
  | allRuntime
  | selected (names : List String)

structure PsPublicApi where
  structures : List PsVerifiedIrStructure
  inductives : List PsVerifiedIrInductive
  exports : List PsVerifiedIrDeclaration

-- Consume only after the checked-IR gate. Selection affects the foreign ABI,
-- not internal reachability or the checked source graph.
def psPublicApi (ir : PsVerifiedIrModule) (exposure : PsApiExposure := .allRuntime) :
    Except String PsPublicApi := do
  let exports ← match exposure with
    | .allRuntime => pure ir.declarations
    | .selected names => names.mapM fun name =>
        match ir.declarations.find? (fun d => d.name == name) with
        | some d => pure d
        | none => throw ("PSCV0-EXPORT: no runtime declaration " ++ name)
  return { structures := ir.structures, inductives := ir.inductives, exports }

-- WIT has no implicit encoding for unbounded integers, recursive values,
-- closures or type parameters. Adapters are a later explicit ABI policy.
def psWitTypeReason (api : PsPublicApi) : Nat → List String → PsVerifiedIrType → Option String
  | 0, _, _ => some "representation traversal budget"
  | n + 1, seen, type =>
    match type with
    | .unknown => some "unknown runtime type"
    | .typeParameter _ => some "generic export requires concrete instantiation"
    | .function .. => some "function value requires a resource/callback adapter"
    | .primitive .nat | .primitive .int => some "unbounded integer requires an explicit adapter"
    | .primitive .usize | .primitive .isize => some "target word size requires an explicit policy"
    | .primitive _ => none
    | .named "Array" [element] => psWitTypeReason api n seen element
    | .named name arguments =>
      if seen.contains name then some "recursive value requires a resource/view adapter"
      else if !arguments.isEmpty then some "generic data requires concrete instantiation"
      else
        let fields : Option (List PsVerifiedIrType) := match api.structures.find? (fun (s : PsVerifiedIrStructure) => s.name == name) with
          | some s => some (s.fields.map PsVerifiedIrStructureField.type)
          | none => (api.inductives.find? (fun (i : PsVerifiedIrInductive) => i.name == name)).map
              (fun (i : PsVerifiedIrInductive) => i.constructors.flatMap fun c => c.fields.map PsVerifiedIrConstructorField.type)
        match fields with
        | none => some ("unknown data type " ++ name)
        | some fields => fields.findSome? (psWitTypeReason api n (name :: seen))

def psWitExportReason (api : PsPublicApi) (d : PsVerifiedIrDeclaration) : Option String :=
  if !d.typeParameters.isEmpty then some "generic export requires concrete instantiation"
  else ((d.parameters.map (·.type)) ++ [d.resultType]).findSome? (psWitTypeReason api 4096 [])

structure PsTargetCapabilities where
  target : PsEmissionTarget
  dialect : String
  arbitraryPrecision : Bool
  stackSafeCalls : Bool
  externalImports : Bool
  sourceMaps : Bool

def psTargetCapabilities : PsEmissionTarget → PsTargetCapabilities
  | .typescript => {
      target := .typescript
      dialect := "typescript-es2020"
      arbitraryPrecision := true
      stackSafeCalls := true
      externalImports := false
      sourceMaps := false }
  | .javascript => {
      target := .javascript
      dialect := "ecmascript-2020-esm"
      arbitraryPrecision := true
      stackSafeCalls := true
      externalImports := false
      sourceMaps := true }
  | .rust => {
      target := .rust
      dialect := "rust-2021"
      arbitraryPrecision := true
      stackSafeCalls := false
      externalImports := false
      sourceMaps := false }

def psApiExports (ir : PsVerifiedIrModule) : Except String (List PsApiExport) := do
  let api ← psPublicApi ir
  return api.exports.map fun d => {
    semanticName := d.name
    typeParameters := d.typeParameters
    parameters := d.parameters
    result := d.resultType
    witReason := psWitExportReason api d }
