import Ps.BackendCommon.ModuleModel
import Ps.BackendTs.Module

/-! One checked brand/tag map and shared runtime per graph. The same canonical
renderer executes natively and inside the generated modular compiler. -/
namespace Ps.Internal.ModularTs

def helpers : List String := [
  "__ps$implementations", "__ps$run", "__ps$wrap", "__ps$invoke", "__ps$tail",
  "__ps$utf8Width", "__ps$utf8", "__ps$stringGet", "__ps$stringNext", "__ps$utf8Known",
  "__ps$stringGetView", "__ps$stringNextView", "__ps$stringUtf8Size", "__ps$stringExtract",
  "__ps$cohort"]

def importText (item : PsModuleImport) : String :=
  psTextJoin "" ["import ", if item.typeOnly then "type " else "", "{ ",
    psTextJoin ", " item.names, " } from ", psJsonQuote item.source, ";\n"]

def renderUnit (plan : PsModulePlan) (digest : String)
    (brands tags : List (Prod String String)) (unit : PsModuleUnit) :
    Except String PsModuleArtifact := do
  let runtimeTypes := psListAppend ["__ps$Request", "__ps$Computation", "__ps$Utf8View"]
    (psListMap (fun (info : PsVerifiedIrStructure) => info.name) plan.raw.structures)
  let symbols := psListAppend
    (psListMap (fun (item : Prod String String) => item.snd) brands)
    (psListMap (fun (item : Prod String String) => item.snd) tags)
  let constructors := psListMap (fun (info : PsVerifiedIrInductive) => info.name) plan.raw.inductives
  let runtimeValues := psListFlatten [helpers, symbols, constructors,
    psListMap (fun (item : PsModuleOwner) => item.name)
      (psListFilter (fun (item : PsModuleOwner) => Nat.beq item.unit 0) unit.imports)]
  let imports := if Nat.beq unit.index 0 then [] else
    psListAppend [
      PsModuleImport.mk (psModuleSpecifierFor plan 0 true) runtimeValues false,
      PsModuleImport.mk (psModuleSpecifierFor plan 0 true) runtimeTypes true]
      (psListFilterMap (fun (index : Nat) =>
        let names := psListMap (fun (item : PsModuleOwner) => item.name)
          (psListFilter (fun (item : PsModuleOwner) => Nat.beq item.unit index) unit.imports);
        if psListIsEmpty names then Option.none
        else Option.some (PsModuleImport.mk (psModuleSpecifierFor plan index true) names false))
        (psModuleSourceIndices plan))
  let structures ← if Nat.beq unit.index 0 then
    psExceptMapError (fun _ => "PSC1_MODULE_TS_STRUCTURE")
      (psListMapExcept (psTsEmitStructure brands) plan.raw.structures)
    else Except.ok []
  let inductives ← if Nat.beq unit.index 0 then
    psExceptMapError (fun _ => "PSC1_MODULE_TS_INDUCTIVE")
      (psListMapExcept (psTsEmitInductive tags) plan.raw.inductives)
    else Except.ok []
  let declarations ← psListMapExcept (fun (declaration : PsVerifiedIrDeclaration) =>
    psExceptMapError (fun _ => String.Internal.append "PSC1_MODULE_TS_PRINT:" declaration.name)
      (psTsEmitDeclarationWithVisibility true brands tags declaration)) unit.declarations
  let header := if Nat.beq unit.index 0 then
      psTextJoin "" [psTsRuntimeSupport, "\nexport const __ps$cohort = ",
        psJsonQuote (psModuleCohortFor plan digest true), ";\n", "export { ",
        psTextJoin ", " (psListAppend
          (psListFilter (fun (name : String) => !psStringEq name "__ps$cohort") helpers) symbols),
        " };\n", "export type { __ps$Request, __ps$Computation, __ps$Utf8View };\n"]
    else psTextJoin "" [psTextJoin "" (psListMap importText imports), "if (__ps$cohort !== ",
      psJsonQuote (psModuleCohortFor plan digest true),
      ") throw new Error(\"PSC1_MODULE_RUNTIME_COHORT\");\n"]
  let typeNames := psModuleTypeNames plan.raw
  let typeExports := if Nat.beq unit.index 0 || psListIsEmpty typeNames then "" else
    psTextJoin "" ["export type { ", psTextJoin ", " typeNames, " } from ",
      psJsonQuote (psModuleSpecifierFor plan 0 true), ";\n"]
  return PsModuleArtifact.mk unit.index
    (psTextJoin "" [header,
      psTextJoin "\n" (psListAppend (psListFlatten structures) (psListFlatten inductives)), "\n",
      typeExports, psTextJoin "\n" declarations, "\n"]) "" imports
    (psListAppend (if Nat.beq unit.index 0 then psListFlatten [helpers, symbols, constructors] else [])
      (psListMap (fun (declaration : PsVerifiedIrDeclaration) => declaration.name) unit.declarations))

end Ps.Internal.ModularTs

