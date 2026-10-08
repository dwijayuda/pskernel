import Ps.Host.ProjectCompiler
import Ps.Bridge.CheckedAdmissions
import Ps.Environment.SelfHostProd
import Lean.Data.Json

-- Read-only native audit. This exports elaborated data, never checked handles.
def psInventoryExpr (value : PsExpr) : IO Lean.Json := do
  let .ok encoded := psEncodeCodecExpr value
    | throw (IO.userError "PSC2_INVENTORY_UNENCODABLE_EXPRESSION")
  let .ok json := Lean.Json.parse encoded
    | throw (IO.userError "PSC2_INVENTORY_EXPRESSION_JSON")
  pure json

def psInventoryKind : PsDeclaration -> String
  | .axiomDecl .. => "axiom"
  | .definitionDecl .. => "definition"
  | .theoremDecl .. => "theorem"
  | .partialDecl .. => "partial"
  | .opaqueDecl .. => "opaque"
  | .inductiveDecl .. => "inductive"
  | .constructorDecl .. => "constructor"
  | .recursorDecl .. => "recursor"

def psInventoryDeclaration (declaration : PsDeclaration) : IO Lean.Json := do
  let type ← psInventoryExpr (psDeclarationType declaration)
  let value ← match psDeclarationValue declaration with
    | none => pure Lean.Json.null
    | some value => psInventoryExpr value
  let metadata := match declaration with
    | .inductiveDecl info => Lean.Json.mkObj [
        ("parameters", Lean.toJson info.numParams), ("indices", Lean.toJson info.numIndices),
        ("constructors", Lean.toJson (info.constructors.map psNameToString)),
        ("structure", Lean.toJson info.isStructure)]
    | .constructorDecl info => Lean.Json.mkObj [
        ("family", Lean.toJson (psNameToString info.inductiveName)),
        ("index", Lean.toJson info.constructorIndex), ("parameters", Lean.toJson info.numParams),
        ("fields", Lean.toJson info.numFields), ("recursiveFields", Lean.toJson info.recursiveFields)]
    | .recursorDecl info => Lean.Json.mkObj [
        ("families", Lean.toJson (info.inductiveNames.map psNameToString)),
        ("parameters", Lean.toJson info.numParams), ("indices", Lean.toJson info.numIndices),
        ("motives", Lean.toJson info.numMotives), ("minors", Lean.toJson info.numMinors)]
    | _ => Lean.Json.null
  pure (Lean.Json.mkObj [
    ("name", Lean.toJson (psNameToString (psDeclarationName declaration))),
    ("kind", Lean.toJson (psInventoryKind declaration)),
    ("levelParameters", Lean.toJson ((psDeclarationLevelParams declaration).map psNameToString)),
    ("type", type), ("value", value), ("metadata", metadata)])

def psInventoryNestedFailures (all : List PsDeclaration) : IO (Array Lean.Json) := do
  let mut failures := #[]
  for declaration in all do
    if let .inductiveDecl info := declaration then
      if let .error _ := psCheckedNestedCollect all [declaration] then
        failures := failures.push (Lean.Json.mkObj [
          ("name", Lean.toJson (psNameToString info.name)),
          ("phase", Lean.toJson "canonical-nested-recursor-adapter"),
          ("error", Lean.toJson "unsupported-inductive-shape")])
  pure failures

def main (args : List String) : IO Unit := do
  if let ["--prelude", output] := args then
    let declarations ← psSelfHostProdPreludeEnvironment.declarations.mapM psInventoryDeclaration
    IO.FS.writeFile output ((Lean.Json.arr declarations.toArray).compress ++ "\n")
    IO.println s!"PSC2_PRELUDE_INVENTORY: {declarations.length} declarations"
    return
  let [compilerEntry, kernelEntry, output] := args
    | throw (IO.userError "usage: psc2_joint_closure_inventory <compiler-entry> <kernel-entry> <output.json>")
  let compiler ← psHostLoadProject psSelfHostProdPreludeEnvironment compilerEntry
  let kernel ← psHostLoadProject psSelfHostProdPreludeEnvironment kernelEntry
  let prelude ← psSelfHostProdPreludeEnvironment.declarations.mapM psInventoryDeclaration
  let compilerJson ← compiler.declarations.mapM psInventoryDeclaration
  let kernelJson ← kernel.declarations.mapM psInventoryDeclaration
  let failures ← psInventoryNestedFailures kernel.declarations
  let result := Lean.Json.mkObj [
    ("schemaVersion", Lean.toJson (1 : Nat)), ("authoritative", Lean.toJson false),
    ("prelude", Lean.Json.arr prelude.toArray),
    ("compiler", Lean.Json.arr compilerJson.toArray),
    ("kernel", Lean.Json.arr kernelJson.toArray), ("kernelAdmissionBlockers", Lean.Json.arr failures)]
  IO.FS.writeFile output (result.compress ++ "\n")
  IO.println s!"PSC2_JOINT_INVENTORY: compiler={compiler.declarations.length} kernel={kernel.declarations.length} prelude={prelude.length} adapter-blockers={failures.size}"
