import Ps.Bridge.Json

/-- Locate the installed host-side formatter/publisher. It has no kernel authority.
The native compiler remains responsible for source admission and all IR passes. -/
def psHostArtifactToolPath : IO String := do
  if let some configured ← IO.getEnv "PSC1_HOST_TOOLS" then
    if ← (System.FilePath.mk configured).pathExists then return configured
    throw (IO.userError ("PSC1_HOST_TOOLS_MISSING: " ++ configured))
  let executable ← IO.appPath
  let bin := executable.parent.getD (System.FilePath.mk ".")
  let build := bin.parent.getD bin
  let lake := build.parent.getD build
  let root := lake.parent.getD lake
  let candidates := [
    bin / "host-tools" / "artifacts.mjs",
    root / "host-tools" / "artifacts.mjs",
    System.FilePath.mk "host-tools/artifacts.mjs",
    System.FilePath.mk "psc1/host-tools/artifacts.mjs"]
  for candidate in candidates do
    if ← candidate.pathExists then
      return (← IO.FS.realPath candidate).toString
  throw (IO.userError "PSC1_HOST_TOOLS_MISSING: install host-tools dependencies and set PSC1_HOST_TOOLS to artifacts.mjs")

def psHostArtifactTool (arguments : Array String) : IO String := do
  let tool ← psHostArtifactToolPath
  let result ← IO.Process.output { cmd := "node", args := #[tool] ++ arguments }
  if result.exitCode != 0 then
    throw (IO.userError ("PSC1_ARTIFACT_PHASE_FAILED: " ++ result.stderr))
  return result.stdout.trimAscii.toString

/-- A private staging directory in the output filesystem. The publisher exposes
only a complete generation, through one atomic current-pointer replacement. -/
def psHostWithArtifactStage {α : Type}
    (outputPath : String) (action : System.FilePath → IO α) : IO α := do
  let stageText ← psHostArtifactTool #["stage", outputPath]
  if stageText.isEmpty then throw (IO.userError "PSC1_ARTIFACT_STAGE_EMPTY")
  let stage := System.FilePath.mk stageText
  try
    action stage
  finally
    -- Successful publication moved this stage into an immutable generation.
    -- A failed compilation leaves no new official output, only private staging.
    if ← stage.pathExists then
      try IO.FS.removeDirAll stage catch _ => pure ()

def psHostPublishArtifactStage
    (stage : System.FilePath) (outputPath target : String) : IO Unit := do
  let receipt ← psHostArtifactTool #["publish", stage.toString, outputPath, target]
  IO.println ("PSC1_BUNDLE: " ++ receipt)

def psHostArtifactFileName (path : String) (fallback : String) : String :=
  ((System.FilePath.mk path).fileName).getD fallback
