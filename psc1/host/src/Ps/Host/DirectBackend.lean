import Ps.Host.CompilerDriver
import Ps.Host.DirectSourceMap
import Ps.CompilerIr.Validate
import Ps.BackendJs.Print
import Ps.BackendRust.Module
import Ps.BackendWasm.Binary
import Ps.BackendWasm.Lower
import Ps.BackendTs.Type
import Ps.Bridge.Json

-- Host-only adapter; not part of the portable bootstrap compiler closure.
-- This selected source pipeline is admission-ready and IR validated. It does not
-- misrepresent the bootstrap codec as independent kernel admission.
-- All artifacts from a direct compilation use the same entry-source bytes.
-- Imported source graph identities are not yet preserved in emitted public APIs,
-- so refuse imports rather than accidentally exporting flattened dependencies.
structure PsHostDirectPrepared where
  validated : PsValidatedIrModule
  sourceText : String
  sourceModule : PsSyntaxModule

def psHostDirectPrepare (inputPath : String) : IO PsHostDirectPrepared := do
  let sourceText ← IO.FS.readFile inputPath
  let sourceModule ← psHostParseSource inputPath sourceText
  if !sourceModule.imports.isEmpty then
    throw (IO.userError "PSC1_DIRECT_IMPORT_GRAPH_UNQUALIFIED")
  let elaborated ← psHostCompilerElaborateProject inputPath
  let afterElaboration ← IO.FS.readFile inputPath
  if afterElaboration != sourceText then
    throw (IO.userError "PSC1_DIRECT_SOURCE_CHANGED_DURING_COMPILE")
  let raw ← match psCompilerVerifiedIrFromElaborated elaborated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_DIRECT_ERASURE_FAILED")
  let validated ← match psValidateErasedIrModule { raw := raw } with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_DIRECT_IR_VALIDATION_FAILED")
  pure { validated := validated, sourceText := sourceText, sourceModule := sourceModule }

def psHostDirectValidatedIr (inputPath : String) : IO PsValidatedIrModule := do
  let prepared ← psHostDirectPrepare inputPath
  pure prepared.validated

def psHostDirectEnsureParent (path : String) : IO Unit := do
  if let some parent := (System.FilePath.mk path).parent then
    IO.FS.createDirAll parent

-- Staging must live alongside the official artifacts for same-filesystem rename.
-- createTempDir supplies a fresh, unpredictable OS token; no abandoned fixed
-- .psc1-stage directory is reused. This does not promise crash-atomic updates.
def psHostDirectStageDirectory (outputPath : String) : IO System.FilePath := do
  let entropy ← IO.FS.createTempDir
  let suffix := entropy.fileName.getD ""
  IO.FS.removeDirAll entropy
  if suffix.isEmpty then
    throw (IO.userError "PSC1_OUTPUT_STAGE_TOKEN_MISSING")
  let stage := System.FilePath.mk (outputPath ++ ".psc1-stage-" ++ suffix)
  IO.FS.createDir stage
  return stage

structure PsHostPublicationFile where
  staged : System.FilePath
  destination : System.FilePath
  backup : System.FilePath

-- Preflight every path, back up all originals, then install each staged file.
-- On ordinary IO errors restore exact previous bytes. If restoration itself
-- fails, backups stay in the private stage and the caller preserves that stage.
def psHostPublishPreparedFilesWithFailureAfter
    (files : List PsHostPublicationFile)
    (failureAfter : Option Nat) : IO Unit := do
  let mut planned : List (PsHostPublicationFile × Bool) := []
  for file in files do
    if !(← file.staged.pathExists) then
      throw (IO.userError "PSC1_OUTPUT_STAGED_FILE_MISSING")
    if ← file.backup.pathExists then
      throw (IO.userError "PSC1_OUTPUT_BACKUP_PATH_OCCUPIED")
    let existed ← file.destination.pathExists
    if existed then
      if ← file.destination.isDir then
        throw (IO.userError "PSC1_OUTPUT_DESTINATION_IS_DIRECTORY")
    planned := (file, existed) :: planned
  let planned := planned.reverse
  try
    for (file, existed) in planned do
      if existed then
        IO.FS.rename file.destination file.backup
    let mut installed : Nat := 0
    for (file, _) in planned do
      if failureAfter == some installed then
        throw (IO.userError "PSC1_OUTPUT_TEST_INJECTED_PUBLICATION_FAILURE")
      IO.FS.rename file.staged file.destination
      installed := installed + 1
  catch originalError =>
    try
      for (file, existed) in planned.reverse do
        if ← file.backup.pathExists then
          if ← file.destination.pathExists then
            IO.FS.removeFile file.destination
          IO.FS.rename file.backup file.destination
        else if !existed then
          if ← file.destination.pathExists then
            IO.FS.removeFile file.destination
    catch restoreError =>
      throw (IO.userError ("PSC1_OUTPUT_ROLLBACK_FAILED: " ++
        toString restoreError ++ "; previous: " ++ toString originalError))
    throw originalError

def psHostPublishPreparedFiles (files : List PsHostPublicationFile) : IO Unit :=
  psHostPublishPreparedFilesWithFailureAfter files none

def psHostDiscardStageAfterFailure
    (stage : System.FilePath) (files : List PsHostPublicationFile) : IO Unit := do
  let mut preserve := false
  for file in files do
    if ← file.backup.pathExists then
      preserve := true
  if !preserve then
    IO.FS.removeDirAll stage

def psHostDirectType (value : PsVerifiedIrType) : Except String String :=
  -- Only scalar public declarations have a qualified .d.ts representation yet.
  match value with
  | .primitive _ =>
      match psTsEmitType value with
      | .ok printed => .ok printed
      | .error _ => .error "PSC1_DIRECT_DECLARATION_TYPE_UNSUPPORTED"
  | _ => .error "PSC1_DIRECT_NONSCALAR_PUBLIC_SIGNATURE_UNQUALIFIED"

def psHostDirectParameter (value : PsVerifiedIrParameter) : Except String String := do
  let type ← psHostDirectType value.type
  pure (value.name ++ ": " ++ type)

def psHostDirectDeclaration (value : PsVerifiedIrDeclaration) : Except String String := do
  -- DirectJS's validated JSIR currently requires closed specialization.
  -- Do not publish generic signatures that are not in the emitted target.
  if !value.typeParameters.isEmpty then
    throw "PSC1_DIRECT_GENERIC_DECLARATION_NOT_QUALIFIED"
  let outputType ← psHostDirectType value.resultType
  let args ← psListMapExcept psHostDirectParameter value.parameters
  if value.parameters.isEmpty then
    pure ("export declare const " ++ value.name ++ ": " ++ outputType ++ ";")
  else
    pure ("export declare function " ++ value.name ++ "(" ++
      String.intercalate ", " args ++ "): " ++ outputType ++ ";")

def psHostDirectDeclarationSource (module : PsValidatedIrModule) :
    Except String String := do
  let declarations ← psListMapExcept psHostDirectDeclaration module.raw.declarations
  pure ("// PSC1 direct JS declarations from checked typed IR\n" ++
    String.intercalate "\n" declarations ++ "\n")

def psHostDirectJavaScript
    (inputPath outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".js" then
    throw (IO.userError "PSC1_DIRECT_JS_OUTPUT_EXTENSION: expected .js")
  let prepared ← psHostDirectPrepare inputPath
  let validated := prepared.validated
  let declaration ← match psHostDirectDeclarationSource validated with
    | .ok text => pure text
    | .error reason => throw (IO.userError reason)
  let emitted ← match psJsEmitValidatedModuleWithPositions validated with
    | .ok text => pure text
    | .error _ => throw (IO.userError "PSC1_DIRECT_JS_TARGET_UNSUPPORTED")
  let sourceText := prepared.sourceText
  let parsed := prepared.sourceModule
  let name := ((System.FilePath.mk outputPath).fileName).getD "module.js"
  let stem := outputPath.dropRight 3
  -- Source positions are owned by the actual parser; generated columns are
  -- measured from the final JS layout. Imported/generated declarations remain
  -- unmapped when their original source file was not identified.
  let mapping := psDirectSourceMap
    (((System.FilePath.mk inputPath).fileName).getD inputPath)
    sourceText name parsed emitted
  psHostDirectEnsureParent outputPath
  let stage ← psHostDirectStageDirectory outputPath
  let stagedJs := stage / "module.js"
  let stagedTypes := stage / "module.d.ts"
  let stagedMap := stage / "module.js.map"
  let files : List PsHostPublicationFile := [
    { staged := stagedJs, destination := System.FilePath.mk outputPath,
      backup := stage / "previous.js" },
    { staged := stagedTypes, destination := System.FilePath.mk (stem ++ ".d.ts"),
      backup := stage / "previous.d.ts" },
    { staged := stagedMap, destination := System.FilePath.mk (outputPath ++ ".map"),
      backup := stage / "previous.js.map" }
  ]
  try
    IO.FS.writeFile stagedJs (emitted.text ++ "\n//# sourceMappingURL=" ++ name ++ ".map\n")
    IO.FS.writeFile stagedTypes declaration
    IO.FS.writeFile stagedMap mapping
    psHostPublishPreparedFiles files
    IO.FS.removeDirAll stage
  catch error =>
    psHostDiscardStageAfterFailure stage files
    throw error
  IO.println ("PSC1_DIRECT_JS: " ++ outputPath)
  IO.println ("PSC1_DIRECT_DECLARATION: " ++ stem ++ ".d.ts")
  IO.println ("PSC1_DIRECT_SOURCE_MAP: " ++ outputPath ++ ".map")

def psHostDirectRust
    (inputPath outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".rs" then
    throw (IO.userError "PSC1_DIRECT_RUST_OUTPUT_EXTENSION: expected .rs")
  let validated ← psHostDirectValidatedIr inputPath
  let emitted ← match psRustEmitValidatedModule validated with
    | .ok text => pure text
    | .error _ => throw (IO.userError "PSC1_DIRECT_RUST_TARGET_UNSUPPORTED")
  psHostDirectEnsureParent outputPath
  IO.FS.writeFile outputPath emitted
  IO.println ("PSC1_DIRECT_RUST: " ++ outputPath)

def psHostDirectWasmCore
    (inputPath outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".wasm" then
    throw (IO.userError "PSC1_DIRECT_WASM_OUTPUT_EXTENSION: expected .wasm")
  let validated ← psHostDirectValidatedIr inputPath
  let lowered ← match psWasmLowerValidatedModule
      { wordSize := PsWasmWordSize.wasm32 } validated with
    | .ok module => pure module
    | .error _ => throw (IO.userError "PSC1_DIRECT_WASM_LOWER_UNSUPPORTED")
  let encoded ← match psWasmEncodeModule lowered with
    | .ok bytes => pure bytes
    | .error _ => throw (IO.userError "PSC1_DIRECT_WASM_BINARY_UNSUPPORTED")
  psHostDirectEnsureParent outputPath
  IO.FS.writeBinFile outputPath (ByteArray.mk encoded.toArray)
  IO.println ("PSC1_DIRECT_WASM_CORE: " ++ outputPath)

-- WAT is produced from the *actual final binary*. The pinned wasm-tools
-- printer supports Wasm GC recursive groups, which older WABT decoders reject.
-- Missing or rejected tooling fails closed; never synthesize fake WAT.
def psHostWasmBinaryToWat (binaryPath watPath : String) : IO Unit := do
  if !binaryPath.endsWith ".wasm" || !watPath.endsWith ".wat" then
    throw (IO.userError "PSC1_WAT_OUTPUT_EXTENSION")
  let output ← IO.Process.output {
    cmd := "wasm-tools"
    args := #["print", binaryPath]
  }
  if output.exitCode != 0 || output.stdout.isEmpty then
    throw (IO.userError ("PSC1_WAT_DECODE_FAILED: " ++ output.stderr))
  psHostDirectEnsureParent watPath
  IO.FS.writeFile watPath output.stdout
  IO.println ("PSC1_DIRECT_WAT: " ++ watPath)
