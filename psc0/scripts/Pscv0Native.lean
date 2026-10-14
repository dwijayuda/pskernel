import Ps.Host.StandardExport
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

-- The host reads an explicit project manifest. The portable compiler receives
-- only immutable named source strings and never consults the filesystem.
-- Paths are project-relative POSIX spellings with no parent traversal.
private def projectField (object : Lean.Json) (key : String) : IO String :=
  match object.getObjValAs? String key with
  | .ok value => pure value
  | .error _ => throw (IO.userError ("PSCV0-PROJECT-MANIFEST: expected string " ++ key))

private def projectPathValid (path : String) : Bool :=
  !path.isEmpty && path.endsWith ".ps" &&
  !path.startsWith "/" && !path.startsWith "\\" &&
  !path.toList.contains '\\' && !path.toList.contains ':' &&
  (path.splitOn "/").all (fun component =>
    !component.isEmpty && component != "." && component != "..")

private def readProjectManifest (manifest : String) :
    IO (String × PsPscv0ModuleSource × List PsPscv0ModuleSource) := do
  let json ← match Lean.Json.parse (← IO.FS.readFile (System.FilePath.mk manifest)) with
    | .ok value => pure value
    | .error message => throw (IO.userError ("PSCV0-PROJECT-MANIFEST: " ++ message))
  let entry ← projectField json "entry"
  let rows ← match json.getObjValAs? (Array Lean.Json) "modules" with
    | .ok entries => pure entries
    | .error _ => throw (IO.userError "PSCV0-PROJECT-MANIFEST: expected modules array")
  if rows.isEmpty || rows.size > 256 then
    throw (IO.userError "PSCV0-PROJECT-MANIFEST: source count budget")
  let root := (System.FilePath.mk manifest).parent.getD "."
  let sources ← rows.toList.mapM fun row => do
    let name ← projectField row "name"
    let relativePath ← projectField row "path"
    if !projectPathValid relativePath then
      throw (IO.userError ("PSCV0-PROJECT-MANIFEST: unsafe source path " ++ relativePath))
    let source ← IO.FS.readFile (root / relativePath)
    return ({ name, source, sourceName := relativePath } : PsPscv0ModuleSource)
  let some selected := sources.find? (fun item => item.name == entry)
    | throw (IO.userError ("PSCV0-PROJECT-MANIFEST: missing entry " ++ entry))
  return (entry, selected, sources.filter (fun item => item.name != entry))

private def runProject (manifest : String)
    (outputs : List (PsEmissionTarget × String))
    (exposure : PsApiExposure := .allRuntime) : IO UInt32 := do
  let (entry, selected, dependencies) ← readProjectManifest manifest
  let outputStem := match outputs.head? with
    | none => "module"
    | some (_, output) => ((System.FilePath.mk output).fileStem).getD "module"
  let request : Request := {
    source := selected.source
    sourceName := selected.sourceName
    moduleName := entry
    modules := dependencies
    outputStem
    targets := outputs.map (·.1)
    exports := exposure }
  match ← runBatch #[request] with
  | .error error =>
    IO.eprintln (error.phase ++ ": " ++ error.message)
    return 1
  | .ok batch =>
    IO.println (Lean.Json.mkObj [
      ("phase", toJson ("prelude" : String)), ("elapsedMs", toJson batch.preludeMs)]).compress
    let some outcome := batch.results[0]? | throw (IO.userError "PSCV0-PROJECT: result missing")
    IO.println (resultJson selected.sourceName outcome).compress
    match outcome with
    | .error _ => return 1
    | .ok value =>
      let files ← outputs.mapM fun (target, output) => do
        let some artifact := value.artifacts.find? (fun artifact => artifact.target == target)
          | throw (IO.userError "PSCV0-PROJECT: missing target artifact")
        return artifactFiles output artifact
      writeFiles files.flatten
      return 0

def main (args : List String) : IO UInt32 := do
  try
    match args with
    | ["--check-quotient-foundation"] =>
        checkQuotientFoundation
        return 0
    | ["--export-float-identity-candidate", output] =>
        exportFloatIdentityCandidate (System.FilePath.mk output)
        return 0
    | ["--export-float-bits-candidate", output] =>
        exportFloatBitsCandidate (System.FilePath.mk output)
        return 0
    | ["--export-signed-identity-candidate", output] =>
        exportSignedIdentityCandidate (System.FilePath.mk output)
        return 0
    | ["--export-float-tobits-candidate", output] =>
        exportFloatToBitsCandidate (System.FilePath.mk output)
        return 0
    | ["--export-signed-operations-candidate", output] =>
        exportSignedOperationsCandidate (System.FilePath.mk output)
        return 0
    | ["--export-signed-shiftleft-candidate", output] =>
        exportSignedShiftLeftCandidate (System.FilePath.mk output)
        return 0
    | ["--export-unsigned-operations-candidate", output] =>
        exportUnsignedOperationsCandidate (System.FilePath.mk output)
        return 0
    | ["--export-hash-foundation", output] =>
        exportHashFoundation (System.FilePath.mk output)
        return 0
    | ["--export-unsigned-foundation", output] =>
        exportUnsignedFoundation (System.FilePath.mk output)
        return 0
    | ["--export-scalar-arithmetic", output] =>
        exportScalarArithmetic (System.FilePath.mk output)
        return 0
    | ["--audit-standard-closure"] =>
        IO.println (← standardClosureAudit).pretty
        return 0
    | ["--audit-primitives"] =>
        IO.println (← primitiveAudit).pretty
        return 0
    | ["--version"] =>
        IO.println (Lean.Json.mkObj [
          ("leanVersion", toJson Lean.versionString), ("leanCommit", toJson Lean.githash),
          ("profile", toJson profile)]).compress
        return 0
    | ["--check-project", manifest] =>
        runProject manifest []
    | ["--emit-project", manifest, output] =>
        let target ← if output.endsWith ".ts" then pure PsEmissionTarget.typescript
          else if output.endsWith ".rs" then pure PsEmissionTarget.rust
          else if output.endsWith ".js" then pure PsEmissionTarget.javascript
          else throw (IO.userError "PSCV0-PROJECT-OUTPUT: expected .ts, .js or .rs")
        runProject manifest [(target, output)]
    | ["--emit-project-all", manifest, stem] =>
        runProject manifest [(.typescript, stem ++ ".ts"),
          (.rust, stem ++ ".rs"), (.javascript, stem ++ ".js")]
    | ["--emit-project-wasm-core", manifest, stem] =>
        runProject manifest [(.wasmCore, stem ++ ".wasm")]
    | ["--emit-project-wasm", manifest, stem, exportManifest] =>
        let json ← match Lean.Json.parse (← IO.FS.readFile exportManifest) with
          | .ok value => pure value
          | .error message => throw (IO.userError message)
        let names ← match Lean.fromJson? json with
          | .ok (names : List String) => pure names
          | .error message => throw (IO.userError ("PSCV0-EXPORT-MANIFEST: " ++ message))
        if names.isEmpty then throw (IO.userError "PSCV0-EXPORT-MANIFEST: empty selection")
        runProject manifest [(.wasmComponent, stem ++ ".wasm")] (.selected names)
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
        IO.eprintln "usage: pscv0_native --check <application.ps>... | --emit <application.ps> <output.ts|output.js|output.rs> | --emit-both <application.ps> <output-stem> | --emit-all <application.ps> <output-stem> | --emit-wasm-core <application.ps> <output-stem> | --emit-wasm <application.ps> <output-stem> <exports.json> | --check-project <manifest.json> | --emit-project <manifest.json> <output.ts|output.js|output.rs> | --emit-project-all <manifest.json> <stem> | --emit-project-wasm-core <manifest.json> <stem> | --emit-project-wasm <manifest.json> <stem> <exports.json> | --audit-primitives | --audit-standard-closure | --export-scalar-arithmetic <output.lean> | --export-unsigned-foundation <output.lean> | --export-hash-foundation <output.lean> | --export-unsigned-operations-candidate <output.lean> | --export-float-identity-candidate <output.lean> | --export-float-bits-candidate <output.lean> | --export-signed-identity-candidate <output.lean> | --export-float-tobits-candidate <output.lean> | --export-signed-operations-candidate <output.lean> | --export-signed-shiftleft-candidate <output.lean> | --version"
        return 2
  catch error =>
    IO.eprintln (toString error)
    return 1
