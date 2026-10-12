import Ps.Host.NativeV7
import Ps.Host.PrimitiveAudit

open Lean (toJson)
open PsV7Native

private def artifactFiles (output : String) (artifact : PsEmissionArtifact) :
    List (System.FilePath × PsArtifactPayload) :=
  let directory := (System.FilePath.mk output).parent.getD "."
  let capabilities := psTargetCapabilities artifact.target
  let symbols := artifact.symbols.map fun s => Lean.Json.mkObj [
    ("semantic", toJson s.semanticName), ("output", toJson s.outputName)]
  let ranges := artifact.source.ranges.map fun r => Lean.Json.mkObj [
    ("output", toJson r.symbol), ("startByte", toJson r.startByte), ("endByte", toJson r.endByte)]
  let manifest := (Lean.Json.mkObj [
    ("schema", toJson ("pscv0-origins/2" : String)),
    ("target", toJson (psEmissionTargetName artifact.target)),
    ("kernel", toJson ("official-lean4-cpp" : String)),
    ("irValidation", toJson ("accepted-complete" : String)),
    ("leanCommit", toJson Lean.githash), ("profile", toJson profile),
    ("coordinates", toJson ("utf8-bytes" : String)),
    ("runtimeDependencies", toJson artifact.dependencies),
    ("capabilities", Lean.Json.mkObj [
      ("dialect", toJson capabilities.dialect),
      ("arbitraryPrecision", toJson capabilities.arbitraryPrecision),
      ("stackSafeCalls", toJson capabilities.stackSafeCalls),
      ("externalImports", toJson capabilities.externalImports),
      ("sourceMaps", toJson capabilities.sourceMaps)]),
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

  (artifact.files.map fun entry => (directory / entry.path, entry.payload)) ++
    [(System.FilePath.mk (output ++ ".origins.json"), .text manifest)]

private def writeFiles (files : List (System.FilePath × PsArtifactPayload)) : IO Unit := do
  -- Resolve every bundle and manifest before publication. Collision checks run
  -- before any write; this is not a multi-file filesystem transaction.
  let _ ← files.foldlM (fun seen (path, _) => do
    let key := path.toString.toLower
    if seen.contains key then throw (IO.userError ("PSCV0-OUTPUT-COLLISION: " ++ path.toString))
    return key :: seen) ([] : List String)
  for (path, payload) in files do
    IO.FS.createDirAll (path.parent.getD ".")
    match payload with
    | .text value => IO.FS.writeFile path value
    | .binary value => IO.FS.writeBinFile path value

private def run (paths : List String) (outputs : List (PsEmissionTarget × String)) (exposure : PsApiExposure := .allRuntime) : IO UInt32 := do
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
      targets := outputs.map (·.1)
      exports := exposure : Request }
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
            let files ← outputs.mapM fun (target, output) => do
              let some artifact := value.artifacts.find? (fun artifact => artifact.target == target)
                | throw (IO.userError "PSCV0-NATIVE-OUTPUT-MISSING")
              return artifactFiles output artifact
            writeFiles files.flatten
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
    | ["--emit-wasm-core", input, stem] =>
        run [input] [(.wasmCore, stem ++ ".wasm")]
    | ["--emit-wasm", input, stem, manifest] =>
        let json ← match Lean.Json.parse (← IO.FS.readFile manifest) with
          | .ok value => pure value
          | .error message => throw (IO.userError message)
        let names ← match Lean.fromJson? json with
          | .ok (names : List String) => pure names
          | .error message => throw (IO.userError ("PSCV0-EXPORT-MANIFEST: " ++ message))
        if names.isEmpty then throw (IO.userError "PSCV0-EXPORT-MANIFEST: empty selection")
        run [input] [(.wasmComponent, stem ++ ".wasm")] (.selected names)
    | ["--emit-all", input, stem] =>
        run [input] [(.typescript, stem ++ ".ts"), (.rust, stem ++ ".rs"), (.javascript, stem ++ ".js")]
    | ["--emit-both", input, stem] =>
        run [input] [(.typescript, stem ++ ".ts"), (.rust, stem ++ ".rs")]
    | _ =>
        IO.eprintln "usage: pscv0_native --check <application.ps>... | --emit <application.ps> <output.ts|output.js|output.rs> | --emit-both <application.ps> <output-stem> | --emit-all <application.ps> <output-stem> | --emit-wasm-core <application.ps> <output-stem> | --emit-wasm <application.ps> <output-stem> <exports.json> | --audit-primitives | --version"
        return 2
  catch error =>
    IO.eprintln (toString error)
    return 1
