import Ps.Host.CompilerDriver
import Ps.Host.LeanChecked
import Ps.Host.SourceSnapshot
import Ps.Host.ArtifactBundle
import Ps.Host.DirectSourceMap
import Ps.CompilerIr.Validate
import Ps.BackendJs.Print
import Ps.BackendRust.Module
import Ps.BackendWasm.Binary
import Ps.BackendWasm.Lower
import Ps.BackendTs.Module

/-- Host-owned immutable session. Its private constructor prevents callers from
substituting a different raw IR after source admission. This is source checking
and bounded runtime typing, not a theorem of backend semantic preservation. -/
structure PsHostDirectPrepared where
  private mk ::
  captured : PsHostCapturedProject
  admissions : String
  validated : PsValidatedIrModule
  publicNames : List String

private def checkedInput (inputPath : String) :
    IO (PsHostCapturedProject × PsCompilerAdmissionReadyModule × String) := do
  let captured ← psHostCaptureProject psSelfHostProdPreludeEnvironment inputPath
  let prepared ← match psCompilerPrepareElaborated
      { environment := captured.environment, declarations := captured.declarations } with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PREPARATION_FAILED: phase=canonical-core")
  let admissions ← match ← psHostLeanCheckPrepared prepared with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_KERNEL_ADMISSION_FAILED: " ++ reason))
  return (captured, prepared, admissions)

private def irFailureText (raw : PsVerifiedIrModule) : String :=
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw
  let details := report.findings.take 8 |>.map fun finding =>
    finding.owner ++ ":" ++ finding.path ++ ":" ++ finding.code ++ ":" ++ finding.detail
  "visited=" ++ toString report.visitedSteps ++ "; complete=" ++
    toString report.traversalComplete ++ "; findings=" ++ toString report.findingCount ++
    "; " ++ String.intercalate "; " details

private def specializeFailureText : PsIrSpecializeError → String
  | .fuelExhausted => "specialization fuel exhausted"
  | .unresolvedTypeParameter name => "unresolved type parameter: " ++ name
  | .nonGroundType name => "non-ground type: " ++ name
  | .typeArgumentArity name => "type argument arity: " ++ name
  | .unknownTarget name => "unknown specialization target: " ++ name
  | .unsupportedGenericCall => "unsupported generic call"
  | .validationBudgetExhausted => "IR validation budget exhausted"
  | .inputValidationFailed => "specialization input validation failed"
  | .outputValidationFailed => "specialization output validation failed"

def psHostDirectType (value : PsVerifiedIrType) : Except String String :=
  -- Preserve the existing scalar public ABI. Internal generic data can still
  -- specialize; this repair does not invent an unqualified aggregate JS ABI.
  match value with
  | .primitive _ =>
    match psTsEmitType value with
    | .ok printed => .ok printed
    | .error _ => .error "PSC1_PUBLIC_TYPE_UNSUPPORTED"
  | _ => .error "PSC1_PUBLIC_NONSCALAR_SIGNATURE_UNQUALIFIED"

def psHostDirectParameter (value : PsVerifiedIrParameter) : Except String String := do
  let type ← psHostDirectType value.type
  return value.name ++ ": " ++ type

def psHostDirectDeclaration (value : PsVerifiedIrDeclaration) : Except String String := do
  if !value.typeParameters.isEmpty then throw "PSC1_PUBLIC_GENERIC_SIGNATURE_UNQUALIFIED"
  let outputType ← psHostDirectType value.resultType
  let args ← value.parameters.mapM psHostDirectParameter
  if value.parameters.isEmpty then
    return "export declare const " ++ value.name ++ ": " ++ outputType ++ ";"
  else
    return "export declare function " ++ value.name ++ "(" ++
      String.intercalate ", " args ++ "): " ++ outputType ++ ";"

def psHostDirectPrepare (inputPath : String) : IO PsHostDirectPrepared := do
  let (captured, prepared, admissions) ← checkedInput inputPath
  -- Erase exactly the immutable declaration graph accepted above.
  let raw ← match psCompilerVerifiedIrFromPrepared prepared with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_ERASURE_FAILED: phase=runtime-erasure")
  let validated ← match psStrictValidateModule raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError ("PSC1_IR_VALIDATION_FAILED: " ++ irFailureText raw))
  let some entry := captured.sources.find? (fun source => source.path == captured.entryPath)
    | throw (IO.userError "PSC1_ENTRY_SNAPSHOT_MISSING")
  let authoredNames := entry.parsed.declarations.map psHostSyntaxDeclarationName
  let publicDeclarations := raw.declarations.filter (fun declaration => authoredNames.contains declaration.name)
  for declaration in publicDeclarations do
    if !psJsIdentifierSupported declaration.name then
      throw (IO.userError ("PSC1_PUBLIC_IDENTIFIER_UNSUPPORTED: " ++ declaration.name))
    match psHostDirectDeclaration declaration with
    | .ok _ => pure ()
    | .error reason => throw (IO.userError (reason ++ ": declaration=" ++ declaration.name))
  let specialized ← match psIrSpecializeValidatedModule validated with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_SPECIALIZATION_FAILED: " ++ specializeFailureText reason))
  let finalIr ← match psStrictValidateModule specialized.raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError ("PSC1_POST_SPECIALIZATION_INVALID: " ++ irFailureText specialized.raw))
  let publicNames := publicDeclarations.map (fun declaration => declaration.name)
  for name in publicNames do
    if !finalIr.raw.declarations.any (fun declaration => declaration.name == name) then
      throw (IO.userError ("PSC1_PUBLIC_DECLARATION_LOST: " ++ name))
  return { captured := captured, admissions := admissions, validated := finalIr, publicNames := publicNames }

def psHostDirectValidatedIr (inputPath : String) : IO PsValidatedIrModule := do
  return (← psHostDirectPrepare inputPath).validated

def psHostDirectCheck (inputPath : String) : IO Unit := do
  let (_, prepared, _) ← checkedInput inputPath
  IO.println ("PSC1_KERNEL_CHECK: PASS (" ++ toString prepared.declarations.length ++ " declarations; Lean 4.34.0)")

def psHostDirectAdmissions (inputPath : String) : IO Unit := do
  let (_, _, admissions) ← checkedInput inputPath
  IO.print admissions

private def sourceJson (source : PsHostCapturedSource) : String :=
  let origins := source.parsed.declarations.filterMap fun declaration =>
    let position := (psElabOriginSource declaration).2.start
    match psDirectSourceUtf16Column source.text position with
    | none => none
    | some column => some ("{\"name\":" ++ psJsonQuote (psHostSyntaxDeclarationName declaration) ++
      ",\"line\":" ++ toString (position.line - 1) ++ ",\"column\":" ++ toString column ++ "}")
  "{\"path\":" ++ psJsonQuote source.path ++ ",\"text\":" ++ psJsonQuote source.text ++
    ",\"origins\":" ++ psJsonArray origins ++ "}"

def psHostDirectWriteProvenance
    (session : PsHostDirectPrepared) (stage : System.FilePath) : IO Unit := do
  let metadata := "{\"profile\":\"psc1-checked-direct/1\",\"compiler\":\"PSC1 native / Lean 4.34.0\"," ++
    "\"entryPath\":" ++ psJsonQuote session.captured.entryPath ++
    ",\"publicNames\":" ++ psJsonArray (session.publicNames.map psJsonQuote) ++
    ",\"sources\":" ++ psJsonArray (session.captured.sources.map sourceJson) ++ "}\n"
  IO.FS.writeFile (stage / "psc1-input.json") metadata
  IO.FS.writeFile (stage / "admissions.json") session.admissions

private def declarationSource (session : PsHostDirectPrepared) : IO String := do
  let selected := session.validated.raw.declarations.filter (fun declaration => session.publicNames.contains declaration.name)
  match selected.mapM psHostDirectDeclaration with
  | .error reason => throw (IO.userError reason)
  | .ok declarations => return "// Public API from the same revalidated specialized IR as the implementation.\n" ++
      String.intercalate "\n" declarations ++ "\n"

private def withoutExport (text : String) : String :=
  if text.startsWith "export " then String.ofList (text.toList.drop 7) else text

private def jsSource (session : PsHostDirectPrepared) : IO String := do
  let lowered ← match psJsLowerValidatedModule session.validated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_JS_LOWER_FAILED: phase=jsir; source-profile=checked-direct/1")
  match psJsValidateModule lowered with
  | .error _ => throw (IO.userError "PSC1_JS_TARGET_VALIDATION_FAILED")
  | .ok _ => pure ()
  let printed ← lowered.declarations.mapM fun declaration => do
    let text ← match psJsPrintDeclarationStackSafe declaration with
      | .ok value => pure value
      | .error _ => throw (IO.userError ("PSC1_JS_PRINT_FAILED: declaration=" ++ declaration.name))
    return if session.publicNames.contains declaration.name then text else withoutExport text
  return psJsPrintStackSafePrelude lowered ++ String.intercalate "\n" printed

private def tsSource (session : PsHostDirectPrepared) : IO String := do
  let raw := session.validated.raw
  let brands := psTsBuildBrandMap raw
  let tags := psTsBuildTagMap raw
  let structures ← match raw.structures.mapM (psTsEmitStructure brands) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TS_STRUCTURE_PRINT_FAILED")
  let inductives ← match raw.inductives.mapM (psTsEmitInductive tags) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_TS_INDUCTIVE_PRINT_FAILED")
  let declarations ← raw.declarations.mapM fun declaration => do
    let text ← match psTsEmitDeclaration brands tags declaration with
      | .ok value => pure value
      | .error _ => throw (IO.userError ("PSC1_TS_PRINT_FAILED: declaration=" ++ declaration.name))
    return if session.publicNames.contains declaration.name then text else withoutExport text
  let internalTypes := (structures.flatten ++ inductives.flatten).map withoutExport
  return String.intercalate "\n" (
    ["// PSC1: independently admitted source; revalidated specialized IR.", psTsRuntimeSupport] ++
    raw.imports.map psTsEmitImport ++ internalTypes ++ declarations) ++ "\n"

def psHostDirectTypeScriptSource (inputPath : String) : IO String := do
  tsSource (← psHostDirectPrepare inputPath)

private def emitEcma
    (session : PsHostDirectPrepared) (outputPath kind : String) : IO Unit := do
  if !outputPath.endsWith ("." ++ kind) then
    throw (IO.userError ("PSC1_OUTPUT_EXTENSION: expected ." ++ kind))
  let name := psHostArtifactFileName outputPath ("module." ++ kind)
  let declarations ← declarationSource session
  let emitted ← if kind == "js" then jsSource session else tsSource session
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeFile (stage / name) emitted
    IO.FS.writeFile (stage / (name.dropRight 3 ++ ".d.ts")) declarations
    let _ ← psHostArtifactTool #["format", stage.toString, kind, name]
    psHostPublishArtifactStage stage outputPath kind
  IO.println ("PSC1_DIRECT_" ++ (if kind == "js" then "JS" else "TS") ++ ": " ++ outputPath)

def psHostDirectEmitJavaScript (session : PsHostDirectPrepared) (outputPath : String) : IO Unit :=
  emitEcma session outputPath "js"

def psHostDirectEmitTypeScript (session : PsHostDirectPrepared) (outputPath : String) : IO Unit :=
  emitEcma session outputPath "ts"

def psHostDirectJavaScript (inputPath outputPath : String) : IO Unit := do
  psHostDirectEmitJavaScript (← psHostDirectPrepare inputPath) outputPath

def psHostDirectTypeScript (inputPath outputPath : String) : IO Unit := do
  psHostDirectEmitTypeScript (← psHostDirectPrepare inputPath) outputPath

private def rustVisibility (publicNames : List String) (source : String) : String :=
  -- The owned Rust printer emits each top-level item at column zero and escapes
  -- newlines in user string literals. Change only that item's leading visibility;
  -- retain every declaration, body, field and symbol needed by linked dependencies.
  let keep := fun (line : String) => publicNames.any fun name =>
    line.startsWith ("pub fn " ++ name ++ "(") || line.startsWith ("pub fn " ++ name ++ "<") ||
    line.startsWith ("pub const " ++ name ++ ":")
  String.intercalate "\n" ((source.splitOn "\n").map fun line =>
    if line.startsWith "pub " && !keep line then String.ofList (line.toList.drop 4) else line)

def psHostDirectEmitRust (session : PsHostDirectPrepared) (outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".rs" then throw (IO.userError "PSC1_OUTPUT_EXTENSION: expected .rs")
  let emitted ← match psRustEmitValidatedModule session.validated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_RUST_TARGET_UNSUPPORTED: phase=rust-lowering")
  let name := psHostArtifactFileName outputPath "module.rs"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeFile (stage / name) (rustVisibility session.publicNames emitted)
    let _ ← psHostArtifactTool #["rust", stage.toString, name]
    psHostPublishArtifactStage stage outputPath "rust"
  IO.println ("PSC1_DIRECT_RUST: " ++ outputPath)

def psHostDirectRust (inputPath outputPath : String) : IO Unit := do
  psHostDirectEmitRust (← psHostDirectPrepare inputPath) outputPath

def psHostWasmTool (arguments : Array String) (phase : String) : IO String := do
  let result ← IO.Process.output { cmd := "wasm-tools", args := arguments }
  if result.exitCode != 0 then
    throw (IO.userError ("PSC1_WASM_" ++ phase ++ "_FAILED: " ++ result.stderr))
  return result.stdout

def psHostWriteWat (binaryPath watPath : System.FilePath) : IO Unit := do
  let text ← psHostWasmTool #["print", binaryPath.toString] "PRINT"
  if text.isEmpty then throw (IO.userError "PSC1_WAT_EMPTY")
  IO.FS.writeFile watPath text

def psHostDirectEmitWasmCore (session : PsHostDirectPrepared) (outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".wasm" then throw (IO.userError "PSC1_OUTPUT_EXTENSION: expected .wasm")
  let lowered ← match psWasmLowerValidatedModule { wordSize := PsWasmWordSize.wasm32 } session.validated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_WASM_LOWER_UNSUPPORTED")
  let selected := { lowered with exports := lowered.exports.filter (fun export => session.publicNames.contains export.1) }
  let encoded ← match psWasmEncodeModule selected with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_WASM_BINARY_UNSUPPORTED")
  let name := psHostArtifactFileName outputPath "module.wasm"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeBinFile (stage / name) (ByteArray.mk encoded.toArray)
    let _ ← psHostWasmTool #["validate", (stage / name).toString] "VALIDATE"
    psHostWriteWat (stage / name) (stage / (name.dropRight 5 ++ ".wat"))
    psHostPublishArtifactStage stage outputPath "wasm-core"
  IO.println ("PSC1_DIRECT_WASM_CORE: " ++ outputPath)

def psHostDirectWasmCore (inputPath outputPath : String) : IO Unit := do
  psHostDirectEmitWasmCore (← psHostDirectPrepare inputPath) outputPath

/-- A binary-to-text conversion is not a source-admission claim. Write its single
output through an adjacent temporary file, and never overwrite managed bundles. -/
def psHostWasmBinaryToWat (binaryPath watPath : String) : IO Unit := do
  if !binaryPath.endsWith ".wasm" || !watPath.endsWith ".wat" then
    throw (IO.userError "PSC1_WAT_OUTPUT_EXTENSION")
  let text ← psHostWasmTool #["print", binaryPath] "PRINT"
  if text.isEmpty then throw (IO.userError "PSC1_WAT_EMPTY")
  let parent := (System.FilePath.mk watPath).parent.getD (System.FilePath.mk ".")
  IO.FS.createDirAll parent
  let result ← IO.Process.output { cmd := "mktemp", args := #[watPath ++ ".stage-XXXXXX"] }
  if result.exitCode != 0 then throw (IO.userError ("PSC1_WAT_STAGE_FAILED: " ++ result.stderr))
  let temporary := System.FilePath.mk result.stdout.trimAscii.toString
  try
    IO.FS.writeFile temporary text
    let check ← IO.Process.output { cmd := "readlink", args := #[watPath] }
    if check.exitCode == 0 then throw (IO.userError "PSC1_WAT_REFUSES_MANAGED_OR_LINKED_OUTPUT")
    IO.FS.rename temporary (System.FilePath.mk watPath)
  finally
    if ← temporary.pathExists then IO.FS.removeFile temporary
  IO.println ("PSC1_DIRECT_WAT: " ++ watPath)
