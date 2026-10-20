import Ps.Host.CompilerDriver
import Ps.Host.LeanChecked
import Ps.Host.SourceSnapshot
import Ps.Host.ArtifactBundle
import Ps.Host.DirectSourceMap
import Ps.Compiler.Ordinary
import Ps.CompilerIr.Validate
import Ps.BackendJs.Print
import Ps.BackendRust.Module
import Ps.BackendWasm.Binary
import Ps.BackendWasm.Lower
import Ps.BackendTs.Module

/-- Requested execution assurance. The current direct pipeline proves admission
of the logical declarations; it has no behavioral verification certificate. -/
inductive PsHostAssurance where
  | checked
  | ordinary
  | verified
  deriving BEq

def psHostAssuranceName : PsHostAssurance → String
  | .checked => "checked-logical"
  | .ordinary => "ordinary-checked"
  | .verified => "verified"

/-- Host-owned immutable accepted input. Source admission does not impose the
scalar ECMAScript ABI on Rust or core Wasm. The constructor is module-private. -/
structure PsHostDirectPrepared where
  private mk ::
  captured : PsHostCapturedProject
  admissions : String
  validated : PsValidatedIrModule
  declarationNames : List (PsName × String)
  publicNames : List String
  authoredTypeNames : List String
  assurance : PsHostAssurance
  partialNames : List PsName

private def checkedInput (inputPath : String) :
    IO (PsHostCapturedProject × PsCompilerAdmissionReadyModule × String) := do
  let captured ← psHostCaptureProject psSelfHostProdPreludeEnvironment inputPath
  let elaborated : PsElabModuleResult := {
    environment := captured.environment
    declarations := captured.declarations
  }
  let prepared ← match psCompilerPrepareElaborated elaborated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_PREPARATION_FAILED: phase=canonical-core")
  let admissions ← match ← psHostLeanCheckPrepared prepared with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_KERNEL_ADMISSION_FAILED: " ++ reason))
  return (captured, prepared, admissions)

private def ordinaryInput (inputPath : String) :
    IO (PsHostCapturedProject × PsCompilerOrdinaryModule × String) := do
  let captured ← psHostCaptureProject psSelfHostProdPreludeEnvironment inputPath
  let elaborated : PsElabModuleResult := {
    environment := captured.environment
    declarations := captured.declarations
  }
  let prepared ← match psCompilerPrepareOrdinary elaborated with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let admissions ← match ← psHostLeanCheckPrepared prepared.logical with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_KERNEL_ADMISSION_FAILED: " ++ reason))
  return (captured, prepared, admissions)

private def irFailureText (raw : PsVerifiedIrModule) : String :=
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw
  let details := (report.findings.take 8).map fun finding =>
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

private def coreNameOfSyntaxName (name : PsSyntaxName) : Option PsName :=
  if name.segments.isEmpty then none
  else some (name.segments.foldl PsName.str PsName.anonymous)

private def syntaxCoreName : PsSyntaxDeclaration → Option PsName
  | .definition name _ _ _ _ => coreNameOfSyntaxName name
  | .partialDefinition name _ _ _ _ => coreNameOfSyntaxName name
  | .theoremDecl name _ _ _ _ => coreNameOfSyntaxName name
  | .inductiveDecl name _ _ _ _ => coreNameOfSyntaxName name
  | .structureDecl name _ _ _ => coreNameOfSyntaxName name

private def runtimeName
    (names : List (PsName × String)) (declaration : PsSyntaxDeclaration) : Option String := do
  let coreName ← syntaxCoreName declaration
  let entry ← names.find? (fun entry => psNameEq entry.1 coreName)
  return entry.2

def psHostDirectPrepareFor (inputPath : String) (assurance : PsHostAssurance) :
    IO PsHostDirectPrepared := do
  let (captured, declarations, admissions, raw, partialNames) ← match assurance with
    | .verified =>
        throw (IO.userError "PSC1_VERIFIED_EXECUTION_UNAVAILABLE: no behavioral certificate; no ordinary fallback")
    | .checked => do
        let (captured, prepared, admissions) ← checkedInput inputPath
        let raw ← match psCompilerVerifiedIrFromPrepared prepared with
          | .ok value => pure value
          | .error _ => throw (IO.userError "PSC1_ERASURE_FAILED: phase=runtime-erasure")
        pure (captured, prepared.declarations, admissions, raw, [])
    | .ordinary => do
        let (captured, prepared, admissions) ← ordinaryInput inputPath
        let raw ← match psCompilerOrdinaryIr prepared with
          | .ok value => pure value
          | .error reason => throw (IO.userError reason)
        pure (captured, prepared.source.declarations, admissions, raw, prepared.partialNames)
  let validated ← match psStrictValidateModule raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError ("PSC1_IR_VALIDATION_FAILED: " ++ irFailureText raw))
  let some entry := captured.sources.find? (fun source => source.path == captured.entryPath)
    | throw (IO.userError "PSC1_ENTRY_SNAPSHOT_MISSING")
  -- Names come from the original runtime graph, never from inhabitant witnesses
  -- or the logical body-marker declarations used for independent admission.
  let names := psErasureDeclarationNames
    (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd declarations)
  let authoredNames := entry.parsed.declarations.filterMap (runtimeName names)
  let publicNames := (raw.declarations.filter (fun d => authoredNames.contains d.name)).map (fun d => d.name)
  let authoredTypeNames := (raw.structures.map (fun s => s.name) ++ raw.inductives.map (fun i => i.name)).filter authoredNames.contains
  return {
    captured := captured
    admissions := admissions
    validated := validated
    declarationNames := names
    publicNames := publicNames
    authoredTypeNames := authoredTypeNames
    assurance := assurance
    partialNames := partialNames
  }

def psHostDirectPrepare (inputPath : String) : IO PsHostDirectPrepared :=
  psHostDirectPrepareFor inputPath .checked

def psHostDirectValidatedIr (inputPath : String) : IO PsValidatedIrModule := do
  return (← psHostDirectPrepare inputPath).validated

def psHostDirectCheck (inputPath : String) : IO Unit := do
  let (_, prepared, _) ← checkedInput inputPath
  IO.println ("PSC1_KERNEL_CHECK: PASS (" ++ toString prepared.declarations.length ++ " declarations; Lean 4.35.0)")

def psHostDirectAdmissions (inputPath : String) : IO Unit := do
  let (_, _, admissions) ← checkedInput inputPath
  IO.print admissions

def psHostDirectCheckFor (inputPath : String) (assurance : PsHostAssurance) : IO Unit := do
  match assurance with
  | .verified =>
      throw (IO.userError "PSC1_VERIFIED_EXECUTION_UNAVAILABLE: no behavioral certificate; no ordinary fallback")
  | .checked => psHostDirectCheck inputPath
  | .ordinary =>
      let (_, prepared, _) ← ordinaryInput inputPath
      IO.println ("PSC1_KERNEL_CHECK: PASS (" ++ toString prepared.logical.declarations.length ++
        " logical declarations; ordinary-checked; behavioral verification unavailable)")

def psHostDirectAdmissionsFor (inputPath : String) (assurance : PsHostAssurance) : IO Unit := do
  match assurance with
  | .verified =>
      throw (IO.userError "PSC1_VERIFIED_EXECUTION_UNAVAILABLE: no behavioral certificate; no ordinary fallback")
  | .checked => psHostDirectAdmissions inputPath
  | .ordinary =>
      let (_, _, admissions) ← ordinaryInput inputPath
      IO.print admissions

def psHostDirectType (value : PsVerifiedIrType) : Except String String :=
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

/-- One checked closed plan for ECMAScript implementation and declarations.
Internal generic dependencies may specialize without exporting unqualified public
signatures, or imposing that ECMAScript ABI restriction on other targets. -/
private def ecmaPlan (session : PsHostDirectPrepared) : IO PsValidatedIrModule := do
  for declaration in session.validated.raw.declarations do
    if session.publicNames.contains declaration.name then
      if !psJsIdentifierSupported declaration.name then
        throw (IO.userError ("PSC1_PUBLIC_IDENTIFIER_UNSUPPORTED: " ++ declaration.name))
      match psHostDirectDeclaration declaration with
      | .ok _ => pure ()
      | .error reason => throw (IO.userError (reason ++ ": declaration=" ++ declaration.name))
  let specialized ← match psIrSpecializeValidatedModule session.validated with
    | .ok value => pure value
    | .error reason => throw (IO.userError ("PSC1_SPECIALIZATION_FAILED: " ++ specializeFailureText reason))
  let plan ← match psStrictValidateModule specialized.raw with
    | .ok value => pure value
    | .error _ => throw (IO.userError ("PSC1_POST_SPECIALIZATION_INVALID: " ++ irFailureText specialized.raw))
  for name in session.publicNames do
    if !plan.raw.declarations.any (fun declaration => declaration.name == name) then
      throw (IO.userError ("PSC1_PUBLIC_DECLARATION_LOST: " ++ name))
  return plan

private def sourceJson (session : PsHostDirectPrepared) (source : PsHostCapturedSource) : String :=
  let origins := source.parsed.declarations.filterMap fun declaration => do
    let name ← runtimeName session.declarationNames declaration
    let position := (psElabOriginSource declaration).2.start
    let column ← psDirectSourceUtf16Column source.text position
    return "{\"name\":" ++ psJsonQuote name ++
      ",\"sourceName\":" ++ psJsonQuote (psHostSyntaxDeclarationName declaration) ++
      ",\"line\":" ++ toString (position.line - 1) ++ ",\"column\":" ++ toString column ++ "}"
  "{\"path\":" ++ psJsonQuote source.path ++ ",\"text\":" ++ psJsonQuote source.text ++
    ",\"origins\":" ++ psJsonArray origins ++ "}"

def psHostDirectWriteSelectedProvenance
    (session : PsHostDirectPrepared) (stage : System.FilePath) (selected : List String) : IO Unit := do
  if !selected.all session.publicNames.contains then
    throw (IO.userError "PSC1_PROVENANCE_PUBLIC_API_NOT_CHECKED")
  let metadata := "{\"profile\":\"psc1-checked-direct/1\",\"compiler\":\"PSC1 native / Lean 4.35.0\"," ++
    "\"leanVersion\":" ++ psJsonQuote Lean.versionString ++
    ",\"leanCommit\":" ++ psJsonQuote Lean.githash ++
    ",\"assurance\":" ++ psJsonQuote (psHostAssuranceName session.assurance) ++
    ",\"behaviorallyVerified\":false" ++
    ",\"partialDeclarations\":" ++ psJsonArray (session.partialNames.map (fun name => psJsonQuote (psNameToString name))) ++
    ",\"entryPath\":" ++ psJsonQuote session.captured.entryPath ++
    ",\"publicNames\":" ++ psJsonArray (selected.map psJsonQuote) ++
    ",\"sources\":" ++ psJsonArray (session.captured.sources.map (sourceJson session)) ++ "}\n"
  IO.FS.writeFile (stage / "psc1-input.json") metadata
  IO.FS.writeFile (stage / "admissions.json") session.admissions

def psHostDirectWriteProvenance (session : PsHostDirectPrepared) (stage : System.FilePath) : IO Unit :=
  psHostDirectWriteSelectedProvenance session stage session.publicNames

private def declarationSource (session : PsHostDirectPrepared) (plan : PsValidatedIrModule) : IO String := do
  let selected := plan.raw.declarations.filter (fun declaration => session.publicNames.contains declaration.name)
  match selected.mapM psHostDirectDeclaration with
  | .error reason => throw (IO.userError reason)
  | .ok declarations => return "// Public API from the same revalidated specialized IR as the implementation.\n" ++
      String.intercalate "\n" declarations ++ "\n" ++
      (if session.publicNames.isEmpty then "export {};\n" else "")

private def withoutExport (text : String) : String :=
  if text.startsWith "export " then String.ofList (text.toList.drop 7) else text

private def jsSource (session : PsHostDirectPrepared) (plan : PsValidatedIrModule) : IO String := do
  let lowered ← match psJsLowerValidatedModule plan with
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
  return psJsPrintStackSafePrelude lowered ++ String.intercalate "\n" printed ++
    (if session.publicNames.isEmpty then "\nexport {};\n" else "")

private def tsSource (session : PsHostDirectPrepared) (plan : PsValidatedIrModule) : IO String := do
  let raw := plan.raw
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
    raw.imports.map psTsEmitImport ++ internalTypes ++ declarations) ++ "\n" ++
    (if session.publicNames.isEmpty then "export {};\n" else "")

def psHostDirectTypeScriptSource (inputPath : String) : IO String := do
  let session ← psHostDirectPrepare inputPath
  tsSource session (← ecmaPlan session)

def psHostDirectTypeScriptSourceFor
    (inputPath : String) (assurance : PsHostAssurance) : IO String := do
  let session ← psHostDirectPrepareFor inputPath assurance
  tsSource session (← ecmaPlan session)

private def emitEcma (session : PsHostDirectPrepared) (outputPath kind : String) : IO Unit := do
  if !outputPath.endsWith ("." ++ kind) then
    throw (IO.userError ("PSC1_OUTPUT_EXTENSION: expected ." ++ kind))
  let plan ← ecmaPlan session
  let name := psHostArtifactFileName outputPath ("module." ++ kind)
  let declarations ← declarationSource session plan
  let emitted ← if kind == "js" then jsSource session plan else tsSource session plan
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeFile (stage / name) emitted
    IO.FS.writeFile (stage / ((name.dropEnd 3).toString ++ ".d.ts")) declarations
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

private partial def namedTypes : PsVerifiedIrType → List String
  | .named name arguments => name :: arguments.flatMap namedTypes
  | .function parameters result => parameters.flatMap namedTypes ++ namedTypes result
  | _ => []

private def publicTypeClosure
    (raw : PsVerifiedIrModule) (fuel : Nat) (pending seen : List String) : Except String (List String) := do
  match pending with
  | [] => return seen
  | name :: rest =>
    match fuel with
    | 0 => throw "PSC1_PUBLIC_TYPE_CLOSURE_BUDGET_EXHAUSTED"
    | remaining + 1 =>
      if seen.contains name then publicTypeClosure raw remaining rest seen
      else
        let fields := match raw.structures.find? (fun value => value.name == name) with
          | some value => value.fields.flatMap (fun field => namedTypes field.type)
          | none => match raw.inductives.find? (fun value => value.name == name) with
            | some value => value.constructors.flatMap (fun ctor => ctor.fields.flatMap (fun field => namedTypes field.type))
            | none => []
        publicTypeClosure raw remaining (fields ++ rest) (name :: seen)

private def rustVisibility (valueNames typeNames : List String) (source : String) : String :=
  let keep := fun (line : String) =>
    valueNames.any (fun name => line.startsWith ("pub fn " ++ name ++ "(") ||
      line.startsWith ("pub fn " ++ name ++ "<") || line.startsWith ("pub const " ++ name ++ ":")) ||
    typeNames.any (fun name => ["struct ", "enum ", "type "].any (fun kind =>
      line.startsWith ("pub " ++ kind ++ name ++ " ") || line.startsWith ("pub " ++ kind ++ name ++ "<") ||
      line.startsWith ("pub " ++ kind ++ name ++ "(") || line == "pub " ++ kind ++ name ++ ";"))
  String.intercalate "\n" ((source.splitOn "\n").map fun line =>
    if line.startsWith "pub " && !keep line then String.ofList (line.toList.drop 4) else line)

def psHostDirectEmitRust (session : PsHostDirectPrepared) (outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".rs" then throw (IO.userError "PSC1_OUTPUT_EXTENSION: expected .rs")
  let emitted ← match psRustEmitValidatedModule session.validated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_RUST_TARGET_UNSUPPORTED: phase=rust-lowering")
  let signatures := session.validated.raw.declarations.filter (fun d => session.publicNames.contains d.name)
  let seeds := session.authoredTypeNames ++ signatures.flatMap (fun d =>
    namedTypes d.resultType ++ d.parameters.flatMap (fun p => namedTypes p.type))
  let types ← match publicTypeClosure session.validated.raw 4096 seeds [] with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let name := psHostArtifactFileName outputPath "module.rs"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeFile (stage / name) (rustVisibility session.publicNames types emitted)
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

def psHostWasmLowerErrorText : PsWasmLowerError -> String
  | .unsupportedType => "unsupported type"
  | .unsupportedTypeContext context => "unsupported type: " ++ context
  | .unsupportedExpression => "unsupported expression"
  | .unsupportedExpressionContext context reason => context ++ ": " ++ reason
  | .specializationFailed error => "specialization: " ++ specializeFailureText error
  | .unsupportedIntrinsic => "unsupported intrinsic"
  | .invalidIntrinsicArity => "invalid intrinsic arity"
  | .invalidCallArity => "invalid call arity"
  | .unknownVariable name => "unknown variable: " ++ name
  | .unknownStructure name => "unknown structure: " ++ name
  | .unknownStructureField name field => "unknown structure field: " ++ name ++ "." ++ field
  | .missingRecordField name field => "missing record field: " ++ name ++ "." ++ field
  | .unknownInductive name => "unknown inductive: " ++ name
  | .unknownConstructor name constructorName => "unknown constructor: " ++ name ++ "." ++ constructorName
  | .unknownConstructorField name constructorName field =>
      "unknown constructor field: " ++ name ++ "." ++ constructorName ++ "." ++ field
  | .missingConstructorField name constructorName field =>
      "missing constructor field: " ++ name ++ "." ++ constructorName ++ "." ++ field
  | .unsupportedModuleFeature => "unsupported module feature"

def psHostDirectEmitWasmCore (session : PsHostDirectPrepared) (outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".wasm" then throw (IO.userError "PSC1_OUTPUT_EXTENSION: expected .wasm")
  let lowered ← match psWasmLowerValidatedModule { wordSize := PsWasmWordSize.wasm32 } session.validated with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_WASM_LOWER_UNSUPPORTED: " ++ psHostWasmLowerErrorText error))
  for name in session.publicNames do
    if !lowered.exports.any (fun item => item.1 == name) then
      throw (IO.userError ("PSC1_WASM_PUBLIC_DECLARATION_NOT_LOWERED: " ++ name))
  let selected := { lowered with exports := lowered.exports.filter (fun item => session.publicNames.contains item.1) }
  let encoded ← match psWasmEncodeModule selected with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_WASM_BINARY_UNSUPPORTED")
  let name := psHostArtifactFileName outputPath "module.wasm"
  psHostWithArtifactStage outputPath fun stage => do
    psHostDirectWriteProvenance session stage
    IO.FS.writeBinFile (stage / name) (ByteArray.mk encoded.toArray)
    let _ ← psHostWasmTool #["validate", (stage / name).toString] "VALIDATE"
    psHostWriteWat (stage / name) (stage / ((name.dropEnd 5).toString ++ ".wat"))
    psHostPublishArtifactStage stage outputPath "wasm-core"
  IO.println ("PSC1_DIRECT_WASM_CORE: " ++ outputPath)

def psHostDirectWasmCore (inputPath outputPath : String) : IO Unit := do
  psHostDirectEmitWasmCore (← psHostDirectPrepare inputPath) outputPath

-- A single-file conversion is not a source-admission claim. Refuse managed
-- aliases and replace only the requested ordinary WAT file through one rename.
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
