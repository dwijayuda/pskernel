import Ps.BackendCommon.Modules
import Ps.BackendTs.ModuleFiles

def psEmitTsModules (plan : PsModulePlan) (digest : String) :
    Except String (List PsModuleArtifact) := do
  let rechecked ← psPlanModulesWithPackages plan.raw plan.owners plan.packages plan.protocol
  let brands := psTsBuildBrandMap rechecked.raw
  let tags := psTsBuildTagMap rechecked.raw
  rechecked.units.mapM (Ps.Internal.ModularTs.renderUnit rechecked digest brands tags)
