import Ps.BackendCommon.Modules
import Ps.BackendTs.Module

/-! One complete brand/tag map is built from the checked graph. Types, symbols,
UTF-8 caches and the implementation WeakMap are emitted exactly once. -/

namespace Ps.Internal.ModularTs

def helpers : List String := [
  "__ps$implementations", "__ps$run", "__ps$wrap", "__ps$invoke", "__ps$tail",
  "__ps$utf8Width", "__ps$utf8", "__ps$stringGet", "__ps$stringNext", "__ps$utf8Known",
  "__ps$stringGetView", "__ps$stringNextView", "__ps$stringUtf8Size", "__ps$stringExtract",
  "__ps$cohort"
]

def importText (item : PsModuleImport) : String :=
  psTextJoin "" ["import ", (if item.typeOnly then "type " else ""), "{ ",
    psTextJoin ", " item.names, " } from ", psJsonQuote item.source, ";\n"]

def importedNames (imports : List PsModuleOwner) (index : Nat) : List String :=
  psListMap (fun (item : PsModuleOwner) => item.name)
    (Ps.Internal.ModuleGraph.filter
      (fun (item : PsModuleOwner) => Nat.beq item.unit index) imports)

def printedDeclaration (brands tags : List (String × String))
    (declaration : PsVerifiedIrDeclaration) : Except String String :=
  match psTsEmitDeclarationWithVisibility true brands tags declaration with
  | Except.error _ => Except.error (String.Internal.append "PSC1_MODULE_TS_PRINT:" declaration.name)
  | Except.ok printed => Except.ok printed

def renderUnit (plan : PsModulePlan) (digest : String)
    (brands tags : List (String × String)) (unit : PsModuleUnit) :
    Except String PsModuleArtifact :=
  let runtimeTypes := psListAppend ["__ps$Request", "__ps$Computation", "__ps$Utf8View"]
    (psListMap (fun (info : PsVerifiedIrStructure) => info.name) plan.raw.structures);
  let symbolNames : List (Prod String String) -> List String :=
    fun (entries : List (Prod String String)) => psListMap (fun (entry : Prod String String) => entry.snd) entries;
  let symbols := psListAppend (symbolNames brands) (symbolNames tags);
  let constructors := psListMap (fun (info : PsVerifiedIrInductive) => info.name) plan.raw.inductives;
  let runtimeValues := psListAppend helpers
    (psListAppend symbols (psListAppend constructors (importedNames unit.imports 0)));
  let sourceImport : Nat -> Option PsModuleImport := fun (index : Nat) =>
    let names := importedNames unit.imports index;
    if psListIsEmpty names then Option.none
    else Option.some (PsModuleImport.mk (psModuleSpecifierFor plan index true) names false);
  let imports : List PsModuleImport := if Nat.beq unit.index 0 then [] else
    psListAppend
      [PsModuleImport.mk (psModuleSpecifierFor plan 0 true) runtimeValues false,
        PsModuleImport.mk (psModuleSpecifierFor plan 0 true) runtimeTypes true]
      (Ps.Internal.ModuleGraph.filterMap sourceImport (psModuleSourceIndices plan));
  let structureResult : Except String (List (List String)) := if Nat.beq unit.index 0 then
    Ps.Internal.ModuleGraph.mapError
      (fun (_error : PsTsEmitError) => "PSC1_MODULE_TS_STRUCTURE")
      (psListMapExcept (psTsEmitStructure brands) plan.raw.structures)
    else Except.ok [];
  match structureResult with
  | Except.error error => Except.error error
  | Except.ok structures =>
      let inductiveResult : Except String (List (List String)) := if Nat.beq unit.index 0 then
        Ps.Internal.ModuleGraph.mapError
          (fun (_error : PsTsEmitError) => "PSC1_MODULE_TS_INDUCTIVE")
          (psListMapExcept (psTsEmitInductive tags) plan.raw.inductives)
        else Except.ok [];
      match inductiveResult with
      | Except.error error => Except.error error
      | Except.ok inductives =>
          match psListMapExcept (printedDeclaration brands tags) unit.declarations with
          | Except.error error => Except.error error
          | Except.ok declarations =>
              let ordinaryHelpers := Ps.Internal.ModuleGraph.filter
                (fun (name : String) => if psStringEq name "__ps$cohort" then false else true) helpers;
              let header := if Nat.beq unit.index 0 then
                  psTextJoin "" [psTsRuntimeSupport, "\nexport const __ps$cohort = ",
                    psJsonQuote (psModuleCohortFor plan digest true), ";\n",
                    "export { ", psTextJoin ", " (psListAppend ordinaryHelpers symbols), " };\n",
                    "export type { __ps$Request, __ps$Computation, __ps$Utf8View };\n"]
                else psTextJoin "" [psTextJoin "" (psListMap importText imports),
                  "if (__ps$cohort !== ", psJsonQuote (psModuleCohortFor plan digest true),
                  ") throw new Error(\"PSC1_MODULE_RUNTIME_COHORT\");\n"];
              let typeNames := psModuleTypeNames plan.raw;
              let typeExports := if Nat.beq unit.index 0 then "" else if psListIsEmpty typeNames then "" else
                psTextJoin "" ["export type { ", psTextJoin ", " typeNames, " } from ",
                  psJsonQuote (psModuleSpecifierFor plan 0 true), ";\n"];
              let typeLines := psListAppend (Ps.Internal.ModuleGraph.flatten structures)
                (Ps.Internal.ModuleGraph.flatten inductives);
              let exports := psListAppend
                (if Nat.beq unit.index 0 then psListAppend helpers (psListAppend symbols constructors) else [])
                (psListMap (fun (declaration : PsVerifiedIrDeclaration) => declaration.name) unit.declarations);
              Except.ok (PsModuleArtifact.mk unit.index
                (psTextJoin "" [header, psTextJoin "\n" typeLines, "\n",
                  typeExports, psTextJoin "\n" declarations, "\n"])
                "" imports exports)

end Ps.Internal.ModularTs

def psEmitTsModules (plan : PsModulePlan) (digest : String) :
    Except String (List PsModuleArtifact) :=
  match psPlanModulesWithPackages plan.raw plan.owners plan.packages plan.protocol with
  | Except.error error => Except.error error
  | Except.ok rechecked =>
      let brands := psTsBuildBrandMap rechecked.raw;
      let tags := psTsBuildTagMap rechecked.raw;
      psListMapExcept (Ps.Internal.ModularTs.renderUnit rechecked digest brands tags) rechecked.units
