import Ps.BackendCommon.ModuleModel
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
  "import " ++ (if item.typeOnly then "type " else "") ++ "{ " ++
    String.intercalate ", " item.names ++ " } from " ++ psJsonQuote item.source ++ ";\n"

def renderUnit (plan : PsModulePlan) (digest : String)
    (brands tags : List (String × String)) (unit : PsModuleUnit) :
    Except String PsModuleArtifact := do
  let runtimeTypes := ["__ps$Request", "__ps$Computation", "__ps$Utf8View"] ++
    plan.raw.structures.map (fun info => info.name)
  let symbols := brands.map Prod.snd ++ tags.map Prod.snd
  let constructors := plan.raw.inductives.map (fun info => info.name)
  let runtimeValues := helpers ++ symbols ++ constructors ++
    (unit.imports.filter (fun item => item.unit == 0)).map (fun item => item.name)
  let imports : List PsModuleImport := if unit.index == 0 then [] else
    [{ source := psModuleSpecifierFor plan 0 true, names := runtimeValues },
      { source := psModuleSpecifierFor plan 0 true, names := runtimeTypes, typeOnly := true }] ++
      ((psModuleSourceIndices plan).filterMap fun index =>
        let names := (unit.imports.filter (fun item => item.unit == index)).map (fun item => item.name)
        if names.isEmpty then none else some { source := psModuleSpecifierFor plan index true, names })
  let structures ← if unit.index == 0 then
    (plan.raw.structures.mapM (psTsEmitStructure brands)).mapError (fun _ => "PSC1_MODULE_TS_STRUCTURE")
    else pure []
  let inductives ← if unit.index == 0 then
    (plan.raw.inductives.mapM (psTsEmitInductive tags)).mapError (fun _ => "PSC1_MODULE_TS_INDUCTIVE")
    else pure []
  let declarations ← unit.declarations.mapM fun declaration =>
    (psTsEmitDeclarationWithVisibility true brands tags declaration).mapError
      (fun _ => "PSC1_MODULE_TS_PRINT:" ++ declaration.name)
  let header := if unit.index == 0 then
      psTsRuntimeSupport ++ "\nexport const __ps$cohort = " ++
      psJsonQuote (psModuleCohortFor plan digest true) ++ ";\n" ++
      "export { " ++ String.intercalate ", " ((helpers.filter (fun name => name != "__ps$cohort")) ++ symbols) ++ " };\n" ++
      "export type { __ps$Request, __ps$Computation, __ps$Utf8View };\n"
    else String.join (imports.map importText) ++
      "if (__ps$cohort !== " ++ psJsonQuote (psModuleCohortFor plan digest true) ++
      ") throw new Error(\"PSC1_MODULE_RUNTIME_COHORT\");\n"
  let typeNames := psModuleTypeNames plan.raw
  let typeExports := if unit.index == 0 || typeNames.isEmpty then "" else
    "export type { " ++ String.intercalate ", " typeNames ++ " } from " ++
      psJsonQuote (psModuleSpecifierFor plan 0 true) ++ ";\n"
  return {
    unit := unit.index
    source := header ++ String.intercalate "\n" (structures.flatten ++ inductives.flatten) ++ "\n" ++
      typeExports ++ String.intercalate "\n" declarations ++ "\n"
    declarations := ""
    imports := imports
    exports := (if unit.index == 0 then helpers ++ symbols ++ constructors else []) ++
      unit.declarations.map (fun d => d.name)
  }

end Ps.Internal.ModularTs

