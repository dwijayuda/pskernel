import Ps.BackendCommon.ModuleModel
import Ps.BackendJs.Print
import Ps.BackendTs.Type

/-! Source-owned structured JsIR rendering. Nominal JS data retains the existing
$ps$tag ABI. Explicit persistent operations also execute in generated compilers. -/
namespace Ps.Internal.ModularJs

def helpers : List String := [
  "__ps$implementations", "__ps$run", "__ps$wrap", "__ps$invoke", "__ps$tailInvoke",
  "__ps$utf8Width", "__ps$utf8", "__ps$stringGet", "__ps$stringNext", "__ps$utf8Known",
  "__ps$stringGetView", "__ps$stringNextView", "__ps$stringUtf8Size", "__ps$stringExtract",
  "__ps$cohort"]

def importText (item : PsModuleImport) : String :=
  psTextJoin "" ["import ", if item.typeOnly then "type " else "", "{ ",
    psTextJoin ", " item.names, " } from ", psJsonQuote item.source, ";\n"]

def typeFields (fields : List (Prod String PsVerifiedIrType)) : Except String String := do
  let printed ← psListMapExcept (fun (field : Prod String PsVerifiedIrType) => do
    let type ← psExceptMapError (fun _ => "PSC1_MODULE_JS_DECLARATION_TYPE") (psTsEmitType field.snd)
    return psTextJoin "" ["readonly ", psJsonQuote field.fst, ": ", type, ";"]) fields
  return psTextJoin " " printed

def nominalTypes (raw : PsVerifiedIrModule) : Except String String := do
  let structures ← psListMapExcept (fun (info : PsVerifiedIrStructure) => do
    if !psListIsEmpty info.typeParameters then throw "PSC1_MODULE_OPEN_TYPE_UNQUALIFIED"
    let fields ← typeFields (psListMap
      (fun (field : PsVerifiedIrStructureField) => Prod.mk field.name field.type) info.fields)
    return psTextJoin "" ["export interface ", info.name, " { ", fields, " }\n"]) raw.structures
  let inductives ← psListMapExcept (fun (info : PsVerifiedIrInductive) => do
    if !psListIsEmpty info.typeParameters then throw "PSC1_MODULE_OPEN_TYPE_UNQUALIFIED"
    let variants ← psListMapExcept (fun (ctor : PsVerifiedIrConstructor) => do
      let fields ← typeFields (psListMap
        (fun (field : PsVerifiedIrConstructorField) => Prod.mk field.name field.type) ctor.fields)
      return psTextJoin "" ["{ readonly \"$ps$tag\": ", psJsonQuote ctor.name, "; ", fields, " }"])
      info.constructors
    return psTextJoin "" ["export type ", info.name, " = ",
      if psListIsEmpty variants then "never" else psTextJoin " | " variants, ";\n"]) raw.inductives
  return psTextJoin "" (psListAppend structures inductives)

def declarationType (declaration : PsVerifiedIrDeclaration) : Except String String := do
  let result ← psExceptMapError (fun _ => "PSC1_MODULE_JS_DECLARATION_TYPE")
    (psTsEmitType declaration.resultType)
  if psListIsEmpty declaration.parameters then
    return psTextJoin "" ["export declare const ", declaration.name, ": ", result, ";\n"]
  let parameters ← psListMapExcept (fun (parameter : PsVerifiedIrParameter) => do
    let type ← psExceptMapError (fun _ => "PSC1_MODULE_JS_DECLARATION_TYPE") (psTsEmitType parameter.type)
    return psTextJoin "" [parameter.name, ": ", type]) declaration.parameters
  return psTextJoin "" ["export declare function ", declaration.name, "(",
    psTextJoin ", " parameters, "): ", result, ";\n"]

def unitImports (plan : PsModulePlan) (unit : PsModuleUnit) : List PsModuleImport :=
  if Nat.beq unit.index 0 then []
  else
    let runtimeValues := psListAppend helpers (psListMap
      (fun (item : PsModuleOwner) => item.name)
      (psListFilter (fun (item : PsModuleOwner) => Nat.beq item.unit 0) unit.imports));
    let values : List PsModuleImport := [PsModuleImport.mk
      (psModuleSpecifierFor plan 0 false) runtimeValues false];
    let others := psListFilterMap (fun (index : Nat) =>
      let names := psListMap (fun (item : PsModuleOwner) => item.name)
        (psListFilter (fun (item : PsModuleOwner) => Nat.beq item.unit index) unit.imports);
      if psListIsEmpty names then Option.none
      else Option.some (PsModuleImport.mk (psModuleSpecifierFor plan index false) names false))
      (psModuleSourceIndices plan);
    psListAppend values others

def renderUnit (plan : PsModulePlan) (lowered : PsJsIrModule)
    (digest : String) (unit : PsModuleUnit) : Except String PsModuleArtifact := do
  let selected ← psListFilterExcept (fun (declaration : PsJsIrDeclaration) => do
    let assigned ← Ps.Internal.ModuleGraph.owner plan.owners declaration.name
    return Nat.beq assigned.unit unit.index) lowered.declarations
  let printed ← psListMapExcept (fun (declaration : PsJsIrDeclaration) =>
    psExceptMapError (fun _ => String.Internal.append "PSC1_MODULE_JS_PRINT:" declaration.name)
      (psJsPrintDeclarationStackSafeWithVisibility true declaration)) selected
  let imports := unitImports plan unit
  let header := if Nat.beq unit.index 0 then
      psTextJoin "" [psJsStringRuntimeSupport, psJsStackRuntimeSupport,
        "export const __ps$cohort = ", psJsonQuote (psModuleCohortFor plan digest false), ";\n",
        "export { ", psTextJoin ", "
          (psListFilter (fun (name : String) => !psStringEq name "__ps$cohort") helpers), " };\n"]
    else psTextJoin "" [psTextJoin "" (psListMap importText imports),
      "if (__ps$cohort !== ", psJsonQuote (psModuleCohortFor plan digest false),
      ") throw new Error(\"PSC1_MODULE_RUNTIME_COHORT\");\n"]
  let types := psModuleTypeNames plan.raw
  let typeHeader := if Nat.beq unit.index 0 || psListIsEmpty types then "" else
    psTextJoin "" ["import type { ", psTextJoin ", " types, " } from ",
      psJsonQuote (psModuleSpecifierFor plan 0 false), ";\nexport type { ",
      psTextJoin ", " types, " } from ", psJsonQuote (psModuleSpecifierFor plan 0 false), ";\n"]
  let declarations ← psListMapExcept declarationType unit.declarations
  let nominal ← if Nat.beq unit.index 0 then nominalTypes plan.raw else Except.ok ""
  return PsModuleArtifact.mk unit.index
    (psTextJoin "" (List.cons header printed))
    (psTextJoin "" [typeHeader, nominal, psTextJoin "" declarations]) imports
    (psListAppend (if Nat.beq unit.index 0 then helpers else [])
      (psListMap (fun (declaration : PsJsIrDeclaration) => declaration.name) selected))

end Ps.Internal.ModularJs

