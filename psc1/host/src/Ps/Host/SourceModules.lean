import Ps.Host.SourceOwnership
import Ps.BackendCommon.ModuleModel

/-! Exact erasure/source ownership from the captured production elaboration.
This metadata selects a file, never a checker or an admission authority. -/
namespace Ps.Host.SourceModules
open Ps.Internal.CompilerService

def jsonRows (value : Lean.Json) (key : String) : Except String (List Lean.Json) := do
  return (← (← value.getObjVal? key).getArr?).toList

def sourceOwners (rows : Array Lean.Json) : Except String (List (Lean.Json × Nat)) := do
  let mut result := []
  for index in [:rows.size] do
    for origin in ← jsonRows rows[index]! "origins" do
      for member in ← jsonRows origin "members" do
        result := result ++ [(← member.getObjVal? "name", index + 1)]
  return result

def originalOwners (semantic : Semantic) (rows : Array Lean.Json) :
    Except String (List PsModuleOwner) := do
  let authored ← sourceOwners rows
  let names := psErasureDeclarationNames
    (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd semantic.source)
  semantic.raw.declarations.mapM fun declaration => do
    let matchingNames := names.filter (fun item => item.2 == declaration.name)
    let [entry] := matchingNames | throw ("PSC1_MODULE_ERASURE_OWNER:" ++ declaration.name)
    let tagged := Lean.toJson (psOwnershipName entry.1)
    let sources := authored.filter (fun item => item.1.compress == tagged.compress)
    let unit ← match sources with
      | [item] => pure item.2
      | [] =>
        if psSelfHostRuntimePreludeDeclarationsWithProd.any
            (fun core => psNameEq (psDeclarationName core) entry.1) then pure 0
        else throw ("PSC1_MODULE_UNKNOWN_OWNER:" ++ declaration.name)
      | _ => throw ("PSC1_MODULE_DUPLICATE_ORIGIN:" ++ declaration.name)
    return { name := declaration.name, unit }


end Ps.Host.SourceModules
