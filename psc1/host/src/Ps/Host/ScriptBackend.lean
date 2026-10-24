import Ps.Host.DirectBackend
import Ps.Host.BackendProviderProtocol

/-- Core retains admission, strict planning, ABI policy and atomic publication.
Python/PHP emitters are separate optional processes with no source/checker access. -/
private def scriptPlan (target : PsBackendTarget) (session : PsHostDirectPrepared) :
    IO PsValidatedIrModule := do
  match psHostDirectCheckPublicApi target session with
  | .ok _ => pure ()
  | .error reason => throw (IO.userError reason)
  match psBackendClosedPlan session.validated session.publicNames with
  | .ok plan => return plan
  | .error reason => throw (IO.userError reason)

private def emitProvider (target : PsBackendTarget) (session : PsHostDirectPrepared)
    (outputPath : String) : IO Unit := do
  let python := target == .python
  let extension := if python then ".py" else ".php"
  if !outputPath.endsWith extension then
    throw (IO.userError ("PSC1_OUTPUT_EXTENSION: expected " ++ extension))
  let plan ← scriptPlan target session
  let name := psHostArtifactFileName outputPath ("module" ++ extension)
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    let request : PsBackendProviderRequest := {
      protocol := psBackendProviderProtocol
      target := psBackendTargetName target
      leanVersion := Lean.versionString
      leanCommit := Lean.githash
      ir := plan.raw
      publicNames := session.publicNames
      ioDispatcherAbi := session.ioDispatcherAbi
    }
    let requestPath := stage / "backend-request.json"
    let encoded := (Lean.toJson request).compress
    if encoded.utf8ByteSize > psBackendProviderMaxBytes then
      throw (IO.userError "PSC1_PROVIDER_REQUEST_LIMIT")
    IO.FS.writeFile requestPath encoded
    let result ← psHostArtifactTool #["provider", stage.toString,
      psBackendTargetName target, requestPath.toString, session.captured.entryPath]
    IO.FS.removeFile requestPath
    let parsed ← match Lean.Json.parse result with
      | .ok value => pure value
      | .error _ => throw (IO.userError "PSC1_PROVIDER_RESPONSE_JSON")
    let response : PsBackendProviderResponse ← match Lean.fromJson? parsed with
      | .ok value => pure value
      | .error _ => throw (IO.userError "PSC1_PROVIDER_RESPONSE_SCHEMA")
    if parsed != Lean.toJson response || response.protocol != psBackendProviderProtocol ||
        response.target != request.target || response.leanVersion != Lean.versionString ||
        response.leanCommit != Lean.githash || !response.candidateOnly ||
        response.publicNames != request.publicNames ||
        response.ioDispatcherAbi != request.ioDispatcherAbi ||
        response.runtimeVersion != "psc1-" ++ request.target ++ "-runtime/1" then
      throw (IO.userError "PSC1_PROVIDER_RESPONSE_IDENTITY")
    IO.FS.writeFile (stage / name) response.source
    let auxiliaryName := (name.dropEnd extension.length).toString ++
      (if python then ".pyi" else ".composer.json")
    IO.FS.writeFile (stage / auxiliaryName) response.auxiliary
    psHostWriteArtifactTargetPlans stage [
      psHostArtifactTargetPlanJson request.target name response.runtimeVersion
        response.runtimeSource response.runtimeRequirements response.declarationLines]
    let _ ← psHostArtifactTool #["script", stage.toString, request.target, name]
    psHostPublishArtifactStage stage outputPath request.target
  IO.println ("PSC1_DIRECT_" ++ (if python then "PYTHON" else "PHP") ++ ": " ++ outputPath)

def psHostDirectEmitPython (session : PsHostDirectPrepared) (outputPath : String) : IO Unit :=
  emitProvider .python session outputPath

def psHostDirectEmitPhp (session : PsHostDirectPrepared) (outputPath : String) : IO Unit :=
  emitProvider .php session outputPath
