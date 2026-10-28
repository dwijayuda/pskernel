import Ps.BackendCommon.Modules
import Ps.BackendJs.ModuleFiles

def psEmitJsModules (plan : PsModulePlan) (digest : String) :
    Except String (List PsModuleArtifact) := do
  let rechecked ← psPlanModulesWithPackages plan.raw plan.owners plan.packages plan.protocol
  let lowered ← (psJsLowerSpecializedModule rechecked.raw).mapError (fun _ => "PSC1_MODULE_JS_LOWER")
  let _ ← (psJsValidateModule lowered).mapError (fun _ => "PSC1_MODULE_JS_VALIDATE")
  rechecked.units.mapM (Ps.Internal.ModularJs.renderUnit rechecked lowered digest)
