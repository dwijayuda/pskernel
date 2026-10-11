import Ps.Host.NativeV7

open Lean (toJson)
open PsV7Native

private def writeArtifact (output : String) (artifact : PsEmissionArtifact) : IO Unit := do
  let file := System.FilePath.mk output
  let directory := file.parent.getD "."
  IO.FS.createDirAll directory
  -- All selected targets have succeeded before any artifact is published.
  IO.FS.writeFile file artifact.source.text
  if !artifact.runtime.isEmpty then
    IO.FS.writeFile (directory / "pscv0_runtime.rs") artifact.runtime
  let symbols := artifact.symbols.map fun s => Lean.Json.mkObj [
    ("semantic", toJson s.semanticName), ("output", toJson s.outputName)]
  let ranges := artifact.source.ranges.map fun r => Lean.Json.mkObj [
    ("output", toJson r.symbol), ("startByte", toJson r.startByte), ("endByte", toJson r.endByte)]
  IO.FS.writeFile (output ++ ".origins.json") (Lean.Json.mkObj [
    ("schema", toJson ("pscv0-origins/1" : String)),
    ("target", toJson (psEmissionTargetName artifact.target)),
    ("kernel", toJson ("official-lean4-cpp" : String)),
    ("irValidation", toJson ("accepted-complete" : String)),
    ("leanCommit", toJson Lean.githash), ("profile", toJson profile),
    ("coordinates", toJson ("utf8-bytes" : String)),
    ("runtimeDependencies", toJson (if artifact.target == .rust then
      ["num-bigint=0.4.6", "num-traits=0.2.19"] else [])),
    ("symbols", toJson symbols), ("ranges", toJson ranges)]).pretty

private def run (paths : List String) (outputs : List (PsEmissionTarget × String)) : IO UInt32 := do
  let requests ← paths.toArray.mapM fun (path : String) => do
    if !path.endsWith ".ps" then
      throw (IO.userError "PSCV0-NATIVE-INPUT: expected .ps application input")
    return { source := ← IO.FS.readFile (System.FilePath.mk path), targets := outputs.map (·.1) : Request }
  match ← runBatch requests with
  | .error error =>
      IO.eprintln (error.phase ++ ": " ++ error.message)
      return 1
  | .ok batch =>
      IO.println (Lean.Json.mkObj [
        ("phase", toJson ("prelude" : String)), ("elapsedMs", toJson batch.preludeMs)]).compress
      let mut failed := false
      for (path, result) in paths.toArray.zip batch.results do
        IO.println (resultJson path result).compress
        match result with
        | .error _ => failed := true
        | .ok value =>
            for (target, output) in outputs do
              let some artifact := value.artifacts.find? (fun artifact => artifact.target == target)
                | throw (IO.userError "PSCV0-NATIVE-OUTPUT-MISSING")
              writeArtifact output artifact
      return if failed then 1 else 0

def main (args : List String) : IO UInt32 := do
  try
    match args with
    | ["--version"] =>
        IO.println (Lean.Json.mkObj [
          ("leanVersion", toJson Lean.versionString), ("leanCommit", toJson Lean.githash),
          ("profile", toJson profile)]).compress
        return 0
    | "--check" :: first :: rest => run (first :: rest) []
    | ["--emit", input, output] =>
        let target ← if output.endsWith ".ts" then pure PsEmissionTarget.typescript
          else if output.endsWith ".rs" then pure PsEmissionTarget.rust
          else throw (IO.userError "PSCV0-NATIVE-OUTPUT: expected .ts or .rs output")
        run [input] [(target, output)]
    | ["--emit-both", input, stem] =>
        run [input] [(.typescript, stem ++ ".ts"), (.rust, stem ++ ".rs")]
    | _ =>
        IO.eprintln "usage: pscv0_native --check <application.ps>... | --emit <application.ps> <output.ts|output.rs> | --emit-both <application.ps> <output-stem> | --version"
        return 2
  catch error =>
    IO.eprintln (toString error)
    return 1
