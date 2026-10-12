import Ps.Host.NativeV7
import Ps.Host.PrimitiveAudit

open Lean (toJson)
open PsV7Native

private def writeArtifact (output : String) (artifact : PsEmissionArtifact) : IO Unit := do
  let file := System.FilePath.mk output
  let directory := file.parent.getD "."
  IO.FS.createDirAll directory
  -- All selected targets have succeeded before any artifact is published.
  -- Validation and generation finish before publication. The host does not
  -- claim crash-atomic replacement of unrelated filesystem paths.
  for entry in artifact.files do
    match entry.payload with
    | .text value => IO.FS.writeFile (directory / entry.path) value
    | .binary value => IO.FS.writeBinFile (directory / entry.path) value
  let symbols := artifact.symbols.map fun s => Lean.Json.mkObj [
    ("semantic", toJson s.semanticName), ("output", toJson s.outputName)]
  let ranges := artifact.source.ranges.map fun r => Lean.Json.mkObj [
    ("output", toJson r.symbol), ("startByte", toJson r.startByte), ("endByte", toJson r.endByte)]
  IO.FS.writeFile (output ++ ".origins.json") (Lean.Json.mkObj [
    ("schema", toJson ("pscv0-origins/2" : String)),
    ("target", toJson (psEmissionTargetName artifact.target)),
    ("kernel", toJson ("official-lean4-cpp" : String)),
    ("irValidation", toJson ("accepted-complete" : String)),
    ("leanCommit", toJson Lean.githash), ("profile", toJson profile),
    ("coordinates", toJson ("utf8-bytes" : String)),
    ("runtimeDependencies", toJson artifact.dependencies),
    ("sourceResolution", toJson ("owning-declaration-span" : String)),
    ("origins", toJson (artifact.origins.map fun (name, origin) => Lean.Json.mkObj [
      ("semantic", toJson name), ("file", toJson origin.identity.file),
      ("sourceStartByte", toJson origin.span.start.byteOffset),
      ("sourceEndByte", toJson origin.span.stop.byteOffset),
      ("generatedReason", toJson origin.generatedReason)])),
    ("exports", toJson (artifact.exports.map fun entry => Lean.Json.mkObj [
      ("semantic", toJson entry.semanticName),
      ("typeParameters", toJson (entry.typeParameters.map (·.name))),
      ("parameters", toJson (entry.parameters.map fun p => Lean.Json.mkObj [
        ("name", toJson p.name), ("runtimeType", toJson ((psTsEmitType p.type).toOption.getD "unsupported"))])),
      ("result", toJson ((psTsEmitType entry.result).toOption.getD "unsupported")),
      ("witRefusal", toJson entry.witReason)])),
    ("symbols", toJson symbols), ("ranges", toJson ranges)]).pretty

private def run (paths : List String) (outputs : List (PsEmissionTarget × String)) : IO UInt32 := do
  let requests ← paths.toArray.mapM fun (path : String) => do
    if !path.endsWith ".ps" then
      throw (IO.userError "PSCV0-NATIVE-INPUT: expected .ps application input")
    let outputStem := match outputs.head? with
      | none => "module"
      | some (_, output) => ((System.FilePath.mk output).fileStem).getD "module"
    return {
      source := ← IO.FS.readFile (System.FilePath.mk path)
      sourceName := (System.FilePath.mk path).fileName.getD path
      outputStem := outputStem
      targets := outputs.map (·.1) : Request }
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
    | ["--audit-primitives"] =>
        IO.println (← primitiveAudit).pretty
        return 0
    | ["--version"] =>
        IO.println (Lean.Json.mkObj [
          ("leanVersion", toJson Lean.versionString), ("leanCommit", toJson Lean.githash),
          ("profile", toJson profile)]).compress
        return 0
    | "--check" :: first :: rest => run (first :: rest) []
    | ["--emit", input, output] =>
        let target ← if output.endsWith ".ts" then pure PsEmissionTarget.typescript
          else if output.endsWith ".rs" then pure PsEmissionTarget.rust
          else if output.endsWith ".js" then pure PsEmissionTarget.javascript
          else throw (IO.userError "PSCV0-NATIVE-OUTPUT: expected .ts, .js or .rs output")
        run [input] [(target, output)]
    | ["--emit-all", input, stem] =>
        run [input] [(.typescript, stem ++ ".ts"), (.rust, stem ++ ".rs"), (.javascript, stem ++ ".js")]
    | ["--emit-both", input, stem] =>
        run [input] [(.typescript, stem ++ ".ts"), (.rust, stem ++ ".rs")]
    | _ =>
        IO.eprintln "usage: pscv0_native --check <application.ps>... | --emit <application.ps> <output.ts|output.js|output.rs> | --emit-both <application.ps> <output-stem> | --emit-all <application.ps> <output-stem> | --audit-primitives | --version"
        return 2
  catch error =>
    IO.eprintln (toString error)
    return 1
