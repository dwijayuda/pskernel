import Ps.BackendCommon.Modules
import Ps.BackendJs.Print
import Ps.BackendTs.Type

/-! Genuine JS units are rendered from structured JsIR declarations. The TS type
renderer is reused solely for .d.mts syntax; JS nominal data keeps its existing
structural $ps$tag ABI rather than borrowing the TS Symbol ABI. -/

namespace Ps.Internal.ModularJs

def helpers : List String := [
  "__ps$implementations", "__ps$run", "__ps$wrap", "__ps$invoke", "__ps$tailInvoke",
  "__ps$utf8Width", "__ps$utf8", "__ps$stringGet", "__ps$stringNext", "__ps$utf8Known",
  "__ps$stringGetView", "__ps$stringNextView", "__ps$stringUtf8Size", "__ps$stringExtract",
  "__ps$cohort"
]

def importText (item : PsModuleImport) : String :=
  psTextJoin "" ["import ", (if item.typeOnly then "type " else ""), "{ ",
    psTextJoin ", " item.names, " } from ", psJsonQuote item.source, ";\n"]

def typeFields (fields : List (String × PsVerifiedIrType)) : Except String String :=
  let printField : Prod String PsVerifiedIrType -> Except String String :=
    fun (field : Prod String PsVerifiedIrType) =>
      match psTsEmitType field.snd with
      | Except.error _ => Except.error "PSC1_MODULE_JS_DECLARATION_TYPE"
      | Except.ok type =>
          Except.ok (psTextJoin "" ["readonly ", psJsonQuote field.fst, ": ", type, ";"]);
  match psListMapExcept printField fields with
  | Except.error error => Except.error error
  | Except.ok printed => Except.ok (psTextJoin " " printed)

def structureType (info : PsVerifiedIrStructure) : Except String String :=
  if psListIsEmpty info.typeParameters then
    let fields := psListMap
      (fun (field : PsVerifiedIrStructureField) => Prod.mk field.name field.type) info.fields;
    match typeFields fields with
    | Except.error error => Except.error error
    | Except.ok printed =>
        Except.ok (psTextJoin "" ["export interface ", info.name, " { ", printed, " }\n"])
  else Except.error "PSC1_MODULE_OPEN_TYPE_UNQUALIFIED"

def constructorType (ctor : PsVerifiedIrConstructor) : Except String String :=
  let fields := psListMap
    (fun (field : PsVerifiedIrConstructorField) => Prod.mk field.name field.type) ctor.fields;
  match typeFields fields with
  | Except.error error => Except.error error
  | Except.ok printed =>
      Except.ok (psTextJoin "" ["{ readonly \"$ps$tag\": ", psJsonQuote ctor.name, "; ", printed, " }"])

def inductiveType (info : PsVerifiedIrInductive) : Except String String :=
  if psListIsEmpty info.typeParameters then
    match psListMapExcept constructorType info.constructors with
    | Except.error error => Except.error error
    | Except.ok variants =>
        Except.ok (psTextJoin "" ["export type ", info.name, " = ",
          (if psListIsEmpty variants then "never" else psTextJoin " | " variants), ";\n"])
  else Except.error "PSC1_MODULE_OPEN_TYPE_UNQUALIFIED"

def nominalTypes (raw : PsVerifiedIrModule) : Except String String :=
  match psListMapExcept structureType raw.structures with
  | Except.error error => Except.error error
  | Except.ok structures =>
      match psListMapExcept inductiveType raw.inductives with
      | Except.error error => Except.error error
      | Except.ok inductives =>
          Except.ok (psTextJoin "" [psTextJoin "" structures, psTextJoin "" inductives])

def parameterType (parameter : PsVerifiedIrParameter) : Except String String :=
  match psTsEmitType parameter.type with
  | Except.error _ => Except.error "PSC1_MODULE_JS_DECLARATION_TYPE"
  | Except.ok type => Except.ok (psTextJoin "" [parameter.name, ": ", type])

def declarationType (declaration : PsVerifiedIrDeclaration) : Except String String :=
  match psTsEmitType declaration.resultType with
  | Except.error _ => Except.error "PSC1_MODULE_JS_DECLARATION_TYPE"
  | Except.ok result =>
      if psListIsEmpty declaration.parameters then
        Except.ok (psTextJoin "" ["export declare const ", declaration.name, ": ", result, ";\n"])
      else
        match psListMapExcept parameterType declaration.parameters with
        | Except.error error => Except.error error
        | Except.ok parameters =>
            Except.ok (psTextJoin "" ["export declare function ", declaration.name, "(",
              psTextJoin ", " parameters, "): ", result, ";\n"])

def importedNames (imports : List PsModuleOwner) (index : Nat) : List String :=
  psListMap (fun (item : PsModuleOwner) => item.name)
    (Ps.Internal.ModuleGraph.filter
      (fun (item : PsModuleOwner) => Nat.beq item.unit index) imports)

def unitImports (plan : PsModulePlan) (unit : PsModuleUnit) : List PsModuleImport :=
  if Nat.beq unit.index 0 then []
  else
    let runtimeValues := psListAppend helpers (importedNames unit.imports 0);
    let values : List PsModuleImport :=
      [PsModuleImport.mk (psModuleSpecifierFor plan 0 false) runtimeValues false];
    let sourceImport : Nat -> Option PsModuleImport := fun (index : Nat) =>
      let names := importedNames unit.imports index;
      if psListIsEmpty names then Option.none
      else Option.some (PsModuleImport.mk (psModuleSpecifierFor plan index false) names false);
    psListAppend values (Ps.Internal.ModuleGraph.filterMap sourceImport (psModuleSourceIndices plan))

def selectedDeclarations (owners : List PsModuleOwner) (index : Nat)
    (declarations : List PsJsIrDeclaration) : Except String (List PsJsIrDeclaration) :=
  match declarations with
  | List.nil => Except.ok []
  | List.cons declaration rest =>
      match Ps.Internal.ModuleGraph.owner owners declaration.name with
      | Except.error error => Except.error error
      | Except.ok assigned =>
          match selectedDeclarations owners index rest with
          | Except.error error => Except.error error
          | Except.ok others =>
              Except.ok (if Nat.beq assigned.unit index then List.cons declaration others else others)

def printedDeclaration (declaration : PsJsIrDeclaration) : Except String String :=
  match psJsPrintDeclarationStackSafeWithVisibility true declaration with
  | Except.error _ => Except.error (String.Internal.append "PSC1_MODULE_JS_PRINT:" declaration.name)
  | Except.ok printed => Except.ok printed

def renderUnit (plan : PsModulePlan) (lowered : PsJsIrModule)
    (digest : String) (unit : PsModuleUnit) : Except String PsModuleArtifact :=
  match selectedDeclarations plan.owners unit.index lowered.declarations with
  | Except.error error => Except.error error
  | Except.ok selected =>
      match psListMapExcept printedDeclaration selected with
      | Except.error error => Except.error error
      | Except.ok printed =>
          let imports := unitImports plan unit;
          let ordinaryHelpers := Ps.Internal.ModuleGraph.filter
            (fun (name : String) => if psStringEq name "__ps$cohort" then false else true) helpers;
          let header := if Nat.beq unit.index 0 then
              psTextJoin "" [psJsStringRuntimeSupport, psJsStackRuntimeSupport,
                "export const __ps$cohort = ", psJsonQuote (psModuleCohortFor plan digest false), ";\n",
                "export { ", psTextJoin ", " ordinaryHelpers, " };\n"]
            else
              psTextJoin "" [psTextJoin "" (psListMap importText imports),
                "if (__ps$cohort !== ", psJsonQuote (psModuleCohortFor plan digest false),
                ") throw new Error(\"PSC1_MODULE_RUNTIME_COHORT\");\n"];
          let types := psModuleTypeNames plan.raw;
          let typeHeader := if Nat.beq unit.index 0 then "" else if psListIsEmpty types then "" else
            psTextJoin "" ["import type { ", psTextJoin ", " types, " } from ",
              psJsonQuote (psModuleSpecifierFor plan 0 false), ";\nexport type { ",
              psTextJoin ", " types, " } from ", psJsonQuote (psModuleSpecifierFor plan 0 false), ";\n"];
          match psListMapExcept declarationType unit.declarations with
          | Except.error error => Except.error error
          | Except.ok declarations =>
              let nominal : Except String String :=
                if Nat.beq unit.index 0 then nominalTypes plan.raw else Except.ok "";
              match nominal with
              | Except.error error => Except.error error
              | Except.ok types =>
                  Except.ok (PsModuleArtifact.mk unit.index
                    (psTextJoin "" [header, psTextJoin "" printed])
                    (psTextJoin "" [typeHeader, types, psTextJoin "" declarations])
                    imports
                    (psListAppend (if Nat.beq unit.index 0 then helpers else [])
                      (psListMap (fun (declaration : PsJsIrDeclaration) => declaration.name) selected)))

end Ps.Internal.ModularJs

def psEmitJsModules (plan : PsModulePlan) (digest : String) :
    Except String (List PsModuleArtifact) :=
  match psPlanModulesWithPackages plan.raw plan.owners plan.packages plan.protocol with
  | Except.error error => Except.error error
  | Except.ok rechecked =>
      match psJsLowerSpecializedModule rechecked.raw with
      | Except.error _ => Except.error "PSC1_MODULE_JS_LOWER"
      | Except.ok lowered =>
          match psJsValidateModule lowered with
          | Except.error _ => Except.error "PSC1_MODULE_JS_VALIDATE"
          | Except.ok _ =>
              psListMapExcept (Ps.Internal.ModularJs.renderUnit rechecked lowered digest) rechecked.units
