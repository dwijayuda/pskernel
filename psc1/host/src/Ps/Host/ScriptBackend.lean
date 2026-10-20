import Ps.Host.DirectBackend
import Ps.BackendPython.Module
import Ps.BackendPhp.Module

/-- Python/PHP share the existing checked input and closed specialization plan.
Their public scalar ABI does not silently widen when a host runtime has extra types. -/
private def scriptPlan (target : PsBackendTarget) (session : PsHostDirectPrepared) :
    IO PsValidatedIrModule := do
  match psBackendCheckPublicApi target session.validated session.publicNames with
  | .ok _ => pure ()
  | .error reason => throw (IO.userError reason)
  match psBackendClosedPlan session.validated session.publicNames with
  | .ok plan => return plan
  | .error reason => throw (IO.userError reason)

def psHostDirectEmitPython (session : PsHostDirectPrepared) (outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".py" then throw (IO.userError "PSC1_OUTPUT_EXTENSION: expected .py")
  let plan ← scriptPlan .python session
  let printed ← match psPythonEmitModule plan session.publicNames with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_PYTHON_TARGET_UNSUPPORTED: " ++ reason))
  let name := psHostArtifactFileName outputPath "module.py"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeFile (stage / name) printed.source
    IO.FS.writeFile (stage / ((name.dropEnd 3).toString ++ ".pyi")) printed.stub
    psHostWriteArtifactTargetPlans stage [
      psHostArtifactTargetPlanJson "python" name "psc1-python-runtime/1"
        printed.runtimeSource printed.runtimeHelpers printed.declarationLines]
    let _ ← psHostArtifactTool #["script", stage.toString, "python", name]
    psHostPublishArtifactStage stage outputPath "python"
  IO.println ("PSC1_DIRECT_PYTHON: " ++ outputPath)

def psHostDirectEmitPhp (session : PsHostDirectPrepared) (outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".php" then throw (IO.userError "PSC1_OUTPUT_EXTENSION: expected .php")
  let plan ← scriptPlan .php session
  let printed ← match psPhpEmitValidatedModule plan session.publicNames with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_PHP_TARGET_UNSUPPORTED: " ++ reason))
  let name := psHostArtifactFileName outputPath "module.php"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeFile (stage / name) printed.source
    IO.FS.writeFile (stage / ((name.dropEnd 4).toString ++ ".composer.json")) printed.composer
    psHostWriteArtifactTargetPlans stage [
      psHostArtifactTargetPlanJson "php" name "psc1-php-runtime/1"
        printed.runtimeSource printed.runtimeRequirements printed.declarationLines]
    let _ ← psHostArtifactTool #["script", stage.toString, "php", name]
    psHostPublishArtifactStage stage outputPath "php"
  IO.println ("PSC1_DIRECT_PHP: " ++ outputPath)
