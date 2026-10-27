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
  "import " ++ (if item.typeOnly then "type " else "") ++ "{ " ++
    String.intercalate ", " item.names ++ " } from " ++ psJsonQuote item.source ++ ";\n"

def typeFields (fields : List (String × PsVerifiedIrType)) : Except String String := do
  let printed ← fields.mapM fun field => do
    let type ← (psTsEmitType field.2).mapError (fun _ => "PSC1_MODULE_JS_DECLARATION_TYPE")
    return "readonly " ++ psJsonQuote field.1 ++ ": " ++ type ++ ";"
  return String.intercalate " " printed

def nominalTypes (raw : PsVerifiedIrModule) : Except String String := do
  let structures ← raw.structures.mapM fun info => do
    if !info.typeParameters.isEmpty then throw "PSC1_MODULE_OPEN_TYPE_UNQUALIFIED"
    let fields ← typeFields (info.fields.map (fun field => (field.name, field.type)))
    return "export interface " ++ info.name ++ " { " ++ fields ++ " }\n"
  let inductives ← raw.inductives.mapM fun info => do
    if !info.typeParameters.isEmpty then throw "PSC1_MODULE_OPEN_TYPE_UNQUALIFIED"
    let variants ← info.constructors.mapM fun ctor => do
      let fields ← typeFields (ctor.fields.map (fun field => (field.name, field.type)))
      return "{ readonly \"$ps$tag\": " ++ psJsonQuote ctor.name ++ "; " ++ fields ++ " }"
    return "export type " ++ info.name ++ " = " ++
      (if variants.isEmpty then "never" else String.intercalate " | " variants) ++ ";\n"
  return String.join structures ++ String.join inductives

def declarationType (declaration : PsVerifiedIrDeclaration) : Except String String := do
  let result ← (psTsEmitType declaration.resultType).mapError (fun _ => "PSC1_MODULE_JS_DECLARATION_TYPE")
  if declaration.parameters.isEmpty then
    return "export declare const " ++ declaration.name ++ ": " ++ result ++ ";\n"
  let parameters ← declaration.parameters.mapM fun parameter => do
    let type ← (psTsEmitType parameter.type).mapError (fun _ => "PSC1_MODULE_JS_DECLARATION_TYPE")
    return parameter.name ++ ": " ++ type
  return "export declare function " ++ declaration.name ++ "(" ++
    String.intercalate ", " parameters ++ "): " ++ result ++ ";\n"

def unitImports (plan : PsModulePlan) (unit : PsModuleUnit) : List PsModuleImport :=
  if unit.index == 0 then []
  else
    let runtimeValues := helpers ++ (unit.imports.filter (fun item => item.unit == 0)).map (fun item => item.name)
    let values : List PsModuleImport := [{ source := psModuleSpecifierFor plan 0 false, names := runtimeValues }]
    values ++ ((psModuleSourceIndices plan).filterMap fun index =>
      let names := (unit.imports.filter (fun item => item.unit == index)).map (fun item => item.name)
      if names.isEmpty then none else some { source := psModuleSpecifierFor plan index false, names })

def renderUnit (plan : PsModulePlan) (lowered : PsJsIrModule)
    (digest : String) (unit : PsModuleUnit) : Except String PsModuleArtifact := do
  let selected ← lowered.declarations.filterM fun declaration => do
    return (← Ps.Internal.ModuleGraph.owner plan.owners declaration.name).unit == unit.index
  let printed ← selected.mapM fun declaration =>
    (psJsPrintDeclarationStackSafeWithVisibility true declaration).mapError
      (fun _ => "PSC1_MODULE_JS_PRINT:" ++ declaration.name)
  let imports := unitImports plan unit
  let header := if unit.index == 0 then
      psJsStringRuntimeSupport ++ psJsStackRuntimeSupport ++
      "export const __ps$cohort = " ++ psJsonQuote (psModuleCohortFor plan digest false) ++ ";\n" ++
      "export { " ++ String.intercalate ", " (helpers.filter (fun name => name != "__ps$cohort")) ++ " };\n"
    else
      String.join (imports.map importText) ++
      "if (__ps$cohort !== " ++ psJsonQuote (psModuleCohortFor plan digest false) ++
      ") throw new Error(\"PSC1_MODULE_RUNTIME_COHORT\");\n"
  let types := psModuleTypeNames plan.raw
  let typeHeader := if unit.index == 0 || types.isEmpty then "" else
    "import type { " ++ String.intercalate ", " types ++ " } from " ++
      psJsonQuote (psModuleSpecifierFor plan 0 false) ++ ";\nexport type { " ++
      String.intercalate ", " types ++ " } from " ++ psJsonQuote (psModuleSpecifierFor plan 0 false) ++ ";\n"
  let declarations ← unit.declarations.mapM declarationType
  let nominal ← if unit.index == 0 then nominalTypes plan.raw else pure ""
  return {
    unit := unit.index
    source := header ++ String.join printed
    declarations := typeHeader ++ nominal ++ String.join declarations
    imports := imports
    exports := (if unit.index == 0 then helpers else []) ++ selected.map (fun d => d.name)
  }

end Ps.Internal.ModularJs

def psEmitJsModules (plan : PsModulePlan) (digest : String) :
    Except String (List PsModuleArtifact) := do
  let rechecked ← psPlanModulesWithPackages plan.raw plan.owners plan.packages plan.protocol
  let lowered ← (psJsLowerSpecializedModule rechecked.raw).mapError (fun _ => "PSC1_MODULE_JS_LOWER")
  let _ ← (psJsValidateModule lowered).mapError (fun _ => "PSC1_MODULE_JS_VALIDATE")
  rechecked.units.mapM (Ps.Internal.ModularJs.renderUnit rechecked lowered digest)
