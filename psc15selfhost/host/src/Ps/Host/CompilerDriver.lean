import Ps.Compiler.Api
import Ps.DriverTs.Compiler
import Ps.DriverJs.Compiler
import Ps.DriverWasm.Compiler
import Ps.DriverRust.Compiler
import Ps.Host.ProjectCompiler
import Ps.Host.TypeScriptCompiler
import Ps.Host.RustCoverage

def psHostCompilerTranslationErrorCode
    (error : PsCompilerError) : String :=
  match error with
  | PsCompilerError.translation translationError =>
      match translationError with
      | PsTranslationError.leanFrontend frontendError =>
          match frontendError with
          | PsLeanFrontendError.lex lexError =>
              String.Internal.append
                "translation.lean.lex:"
                (psHostLexErrorText lexError)
          | PsLeanFrontendError.parse parseError =>
              String.Internal.append
                "translation.lean.parse:"
                (psHostParseErrorText parseError)
      | PsTranslationError.proofScriptFrontend _ =>
          "translation.proofscript-frontend"
      | PsTranslationError.print printError =>
          match printError with
          | PsSourcePrintError.fuelExhausted =>
              "translation.print.fuel-exhausted"
          | PsSourcePrintError.unsupportedApplication =>
              "translation.print.unsupported-application"
          | PsSourcePrintError.emptyName =>
              "translation.print.empty-name"
  | PsCompilerError.leanFrontend _ => "lean-frontend"
  | PsCompilerError.proofScriptFrontend _ => "proofscript-frontend"
  | PsCompilerError.elaboration _ => "elaboration"
  | PsCompilerError.admission _ => "admission"
  | PsCompilerError.erasure _ => "erasure"
  | PsCompilerError.irValidation _ => "ir-validation"

def psHostCompilerSourceKindFromPath
    (path : String) : Option PsCompilerSourceKind :=
  if path.endsWith ".lean" then
    some PsCompilerSourceKind.lean
  else if path.endsWith ".ps" then
    some PsCompilerSourceKind.proofScript
  else
    none

def psHostCompilerTargetKind
    (target : String) : Option PsCompilerSourceKind :=
  if target == "lean" || target == ".lean" then
    some PsCompilerSourceKind.lean
  else if target == "ps" || target == ".ps" then
    some PsCompilerSourceKind.proofScript
  else
    none

def psHostCompilerTranslatedSource
    (inputPath : String)
    (targetText : String) : IO String := do
  let sourceKind ←
    match psHostCompilerSourceKindFromPath inputPath with
    | none =>
        throw
          (IO.userError
            ("PSC2_CLI_SOURCE_KIND: expected .lean or .ps input, got " ++
              inputPath))
    | some kind => pure kind
  let targetKind ←
    match psHostCompilerTargetKind targetText with
    | none =>
        throw
          (IO.userError
            ("PSC2_CLI_TRANSLATION_TARGET: expected ps or lean, got " ++
              targetText))
    | some kind => pure kind
  let source ← IO.FS.readFile inputPath
  match psCompilerTranslateSource sourceKind targetKind source with
  | Except.error error =>
      throw
        (IO.userError
          (String.Internal.append
            "PSC2_CLI_TRANSLATION_FAILED: "
            (psHostCompilerTranslationErrorCode error)))
  | Except.ok output =>
      pure output

def psHostCompilerTranslate
    (inputPath : String)
    (targetText : String) : IO Unit := do
  IO.print (← psHostCompilerTranslatedSource inputPath targetText)

def psHostCompilerTranslateToFile
    (inputPath : String)
    (targetText : String)
    (outputPath : String) : IO Unit := do
  let output ← psHostCompilerTranslatedSource inputPath targetText
  IO.FS.writeFile outputPath output
  IO.println
    ("PSC2_TRANSLATE: " ++ inputPath ++ " -> " ++ outputPath)

def psHostCompilerElaborateProject
    (inputPath : String) : IO PsElabModuleResult :=
  psHostLoadProject
    psSelfHostProdPreludeEnvironment
    inputPath

def psHostCompilerCheck
    (inputPath : String) : IO Unit := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerCheckElaborated elaborated with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC2_CHECK_FAILED: elaborated source is not admission-ready")
  | Except.ok prepared =>
      IO.println
        ("PSC2_CHECK: PASS (" ++
          toString prepared.declarations.length ++
          " declarations)")

def psHostCompilerAdmissions
    (inputPath : String) : IO Unit := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerAdmissionsFromElaborated elaborated with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC2_CLI_ADMISSION_CODEC_FAILED: elaborated source is not persistable")
  | Except.ok encoded =>
      IO.print encoded

-- Preserve the typed failure stage and named subject at the host boundary.
-- A generic "outside subset" message hides validation failures as emitter gaps.
def psHostCompilerTypeScriptFailure (error : PsCompilerTypeScriptError) : String :=
  match error with
  | PsCompilerTypeScriptError.emit inner =>
      match inner with
      | PsTsEmitError.fuelExhausted => "emit.fuel-exhausted"
      | PsTsEmitError.unsupportedIntrinsic => "emit.unsupported-intrinsic"
      | PsTsEmitError.intrinsicArity => "emit.intrinsic-arity"
      | PsTsEmitError.unknownStructure name => "emit.unknown-structure:" ++ name
      | PsTsEmitError.unknownInductive name => "emit.unknown-inductive:" ++ name
      | PsTsEmitError.genericValueUnsupported name => "emit.generic-value:" ++ name
      | PsTsEmitError.targetWordSizeRequired => "emit.target-word-size-required"
  | PsCompilerTypeScriptError.compiler inner =>
      match inner with
      | PsCompilerError.erasure erased =>
          match erased with
          | PsErasureError.fuelExhausted => "compiler.erasure.fuel-exhausted"
          | PsErasureError.binderMismatch => "compiler.erasure.binder-mismatch"
          | PsErasureError.looseBoundVariable => "compiler.erasure.loose-bound-variable"
          | PsErasureError.unresolvedMetavariable => "compiler.erasure.unresolved-metavariable"
          | PsErasureError.unknownLocal id => "compiler.erasure.unknown-local:" ++ toString id
          | PsErasureError.erasedLocalUsed id => "compiler.erasure.erased-local-used:" ++ toString id
          | PsErasureError.unsupportedRuntimeTerm => "compiler.erasure.unsupported-runtime-term"
          | PsErasureError.unsupportedApplication => "compiler.erasure.unsupported-application"
          | PsErasureError.unknownConstant name => "compiler.erasure.unknown-constant:" ++ psEncodeCodecName name
      | PsCompilerError.irValidation invalid =>
          match invalid with
          | PsVerifiedIrValidationError.unresolvedRuntimeType => "compiler.ir-validation.unresolved-runtime-type"
          | PsVerifiedIrValidationError.validationFuelExhausted => "compiler.ir-validation.fuel-exhausted"
          | PsVerifiedIrValidationError.unknownStructure name => "compiler.ir-validation.unknown-structure:" ++ name
          | PsVerifiedIrValidationError.unknownInductive name => "compiler.ir-validation.unknown-inductive:" ++ name
          | PsVerifiedIrValidationError.unknownConstructor owner name => "compiler.ir-validation.unknown-constructor:" ++ owner ++ ":" ++ name
          | PsVerifiedIrValidationError.unknownStructureField owner field => "compiler.ir-validation.unknown-field:" ++ owner ++ ":" ++ field
          | PsVerifiedIrValidationError.unknownConstructorField owner name field => "compiler.ir-validation.unknown-constructor-field:" ++ owner ++ ":" ++ name ++ ":" ++ field
          | PsVerifiedIrValidationError.typeArgumentArity name => "compiler.ir-validation.type-argument-arity:" ++ name
          | PsVerifiedIrValidationError.invalidMachineIntegerLiteral _ => "compiler.ir-validation.invalid-machine-literal"
          | PsVerifiedIrValidationError.duplicateGlobalName name => "compiler.ir-validation.duplicate-global:" ++ name
          | PsVerifiedIrValidationError.duplicateTypeParameter name => "compiler.ir-validation.duplicate-type-parameter:" ++ name
          | PsVerifiedIrValidationError.duplicateParameter name => "compiler.ir-validation.duplicate-parameter:" ++ name
          | PsVerifiedIrValidationError.duplicateField owner field => "compiler.ir-validation.duplicate-field:" ++ owner ++ ":" ++ field
          | PsVerifiedIrValidationError.duplicateAlternative name => "compiler.ir-validation.duplicate-alternative:" ++ name
          | PsVerifiedIrValidationError.unknownTypeName name => "compiler.ir-validation.unknown-type:" ++ name
          | PsVerifiedIrValidationError.unknownTypeParameter name => "compiler.ir-validation.unknown-type-parameter:" ++ name
          | PsVerifiedIrValidationError.unknownVariable name => "compiler.ir-validation.unknown-variable:" ++ name
          | PsVerifiedIrValidationError.expressionTypeMismatch => "compiler.ir-validation.expression-type-mismatch"
          | PsVerifiedIrValidationError.callArity => "compiler.ir-validation.call-arity"
          | PsVerifiedIrValidationError.intrinsicArity => "compiler.ir-validation.intrinsic-arity"
          | PsVerifiedIrValidationError.intrinsicTypeArgumentArity => "compiler.ir-validation.intrinsic-type-argument-arity"
          | PsVerifiedIrValidationError.fieldCompleteness owner => "compiler.ir-validation.field-completeness:" ++ owner
          | PsVerifiedIrValidationError.matchExhaustiveness owner => "compiler.ir-validation.match-exhaustiveness:" ++ owner
          | PsVerifiedIrValidationError.invalidExternalImport name => "compiler.ir-validation.invalid-import:" ++ name
          | PsVerifiedIrValidationError.emptyMatch => "compiler.ir-validation.empty-match"
      | _ => "compiler." ++ psHostCompilerTranslationErrorCode inner

def psHostCompilerTypeScriptSource
    (inputPath : String) : IO String := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerTypeScriptFromElaborated elaborated with
  | Except.error error =>
      throw
        (IO.userError
          ("PSC2_CLI_TS_EMIT_FAILED: " ++ psHostCompilerTypeScriptFailure error))
  | Except.ok output =>
      pure output

def psHostCompilerTypeScript
    (inputPath : String) : IO Unit := do
  IO.print (← psHostCompilerTypeScriptSource inputPath)

def psHostCompilerJavaScriptSource
    (inputPath : String) : IO String := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerJavaScriptFromElaborated elaborated with
  | Except.error error =>
      throw
        (IO.userError
          (String.Internal.append
            "PSC2_CLI_DIRECT_JS_EMIT_FAILED: "
            (psCompilerJavaScriptErrorCode error)))
  | Except.ok output =>
      pure output

def psHostCompilerJavaScript
    (inputPath : String) : IO Unit := do
  IO.print (← psHostCompilerJavaScriptSource inputPath)

def psHostCompilerWasm32Bytes
    (inputPath : String) : IO (List UInt8) := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match
      psCompilerWasmFromElaborated
        psCompilerWasm32Target
        elaborated with
  | Except.error error =>
      throw
        (IO.userError
          (String.Internal.append
            "PSC2_CLI_DIRECT_WASM_EMIT_FAILED: "
            (psCompilerWasmErrorCode error)))
  | Except.ok bytes =>
      pure bytes

def psHostCompilerWasm32ToFile
    (inputPath outputPath : String) : IO Unit := do
  let bytes ← psHostCompilerWasm32Bytes inputPath
  IO.FS.writeBinFile outputPath (ByteArray.mk bytes.toArray)
  IO.println
    ("PSC2_DIRECT_WASM: " ++ inputPath ++ " -> " ++ outputPath)

def psHostCompilerRustSource
    (inputPath : String) : IO String := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerRustFromElaborated elaborated with
  | Except.error error =>
      throw
        (IO.userError
          (String.Internal.append
            "PSC2_CLI_DIRECT_RUST_EMIT_FAILED: "
            (psCompilerRustErrorCode error)))
  | Except.ok output =>
      pure output

def psHostCompilerRust
    (inputPath : String) : IO Unit := do
  IO.print (← psHostCompilerRustSource inputPath)

def psHostCompilerRustToFile
    (inputPath outputPath : String) : IO Unit := do
  let output ← psHostCompilerRustSource inputPath
  IO.FS.writeFile outputPath output
  IO.println
    ("PSC2_DIRECT_RUST: " ++ inputPath ++ " -> " ++ outputPath)

def psHostCompilerRustCoverage
    (inputPath : String) : IO Unit := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      throw
        (IO.userError
          (String.Internal.append
            "PSC2_CLI_DIRECT_RUST_COVERAGE_FAILED: "
            (psCompilerRustErrorCode
              (PsCompilerRustError.compiler error))))
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error error =>
          throw
            (IO.userError
              (String.Internal.append
                "PSC2_CLI_DIRECT_RUST_COVERAGE_FAILED: "
                (psCompilerRustErrorCode
                  (PsCompilerRustError.compiler error))))
      | Except.ok validated =>
          IO.print
            (psRustCoverageReport
              (psRustCoverageModule validated.raw))

def psHostCompilerBuild
    (inputPath outputPath : String) : IO Unit := do
  let typeScriptPath ←
    if outputPath.endsWith ".ts" then
      pure outputPath
    else if outputPath.endsWith ".js" then
      pure (outputPath.dropRight 3 ++ ".ts")
    else
      throw
        (IO.userError
          "PSC2_CLI_OUTPUT_KIND: build output must end in .js or .ts")
  let source ← psHostCompilerTypeScriptSource inputPath
  let result ← psWriteAndCompileTypeScript source typeScriptPath
  IO.println
    ("PSC2_COMPILE: " ++ result.typeScriptPath ++
      " -> " ++ result.javascriptPath)
  IO.println
    ("PSC2_DECLARATION: " ++ result.declarationPath)
  IO.println
    ("PSC2_SOURCE_MAP: " ++ result.sourceMapPath)
  IO.println
    ("PSC2_TYPESCRIPT: " ++ result.typescriptVersion)
