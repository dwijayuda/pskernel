import Ps.Compiler.Pscv0
import Ps.Compiler.Pscv0ModuleEngine

-- Preserve the selected Full project's public shape and validation order.
-- The graph, visibility and source preparation owner is shared with explicit
-- environment callers; only this compatibility composition selects Full.
def psCompilerPreparePscv0Project (entryName : String)
    (sources : List PsPscv0ModuleSource) : Except String PsPscv0ProjectOutput := do
  psCompilerValidatePscv0Standard
  let output ← psCompilerEnginePreparePscv0Project
    psCompilerFullProfileContext entryName sources
  let prepared : PsCompilerAdmissionReadyModule := {
    declarations := output.prepared.declarations
    recursorWorkerGroups := output.prepared.recursorWorkerGroups
    noncomputableNames := output.prepared.noncomputableNames }
  return {
    prepared, admissions := output.admissions
    mainNames := output.mainNames, libraryNames := output.libraryNames
    origins := output.origins, moduleProfiles := output.moduleProfiles }
