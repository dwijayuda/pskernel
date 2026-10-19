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
def psHostDirectValidatedIr (inputPath : String) : IO PsValidatedIrModule := do
  let elaborated ← psHostCompilerElaborateProject inputPath
  let raw ← match psCompilerVerifiedIrFromElaborated elaborated with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_DIRECT_ERASURE_FAILED")
  match psValidateErasedIrModule { raw := raw } with
  | .ok value => pure value
  | .error _ => throw (IO.userError "PSC1_DIRECT_IR_VALIDATION_FAILED")

def psHostDirectEnsureParent (path : String) : IO Unit := do
  if let some parent := (System.FilePath.mk path).parent then
    IO.FS.createDirAll parent

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
  let validated ← psHostDirectValidatedIr inputPath
  let declaration ← match psHostDirectDeclarationSource validated with
    | .ok text => pure text
    | .error reason => throw (IO.userError reason)
  let emitted ← match psJsEmitValidatedModuleWithPositions validated with
    | .ok text => pure text
    | .error _ => throw (IO.userError "PSC1_DIRECT_JS_TARGET_UNSUPPORTED")
  let sourceText ← IO.FS.readFile inputPath
  let parsed ← psHostParseSource inputPath sourceText
  let name := ((System.FilePath.mk outputPath).fileName).getD "module.js"
  let stem := outputPath.dropRight 3
  -- Source positions are owned by the actual parser; generated columns are
  -- measured from the final JS layout. Imported/generated declarations remain
  -- unmapped when their original source file was not identified.
  let mapping := psDirectSourceMap
    (((System.FilePath.mk inputPath).fileName).getD inputPath)
    sourceText name parsed emitted
  psHostDirectEnsureParent outputPath
  IO.FS.writeFile outputPath (emitted.text ++ "\n//# sourceMappingURL=" ++ name ++ ".map\n")
  IO.FS.writeFile (stem ++ ".d.ts") declaration
  IO.FS.writeFile (outputPath ++ ".map") mapping
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

-- WAT is produced from the *actual final binary*. The independent wabt
-- disassembler is required explicitly; missing or rejected tooling fails closed.
def psHostWasmBinaryToWat (binaryPath watPath : String) : IO Unit := do
  if !binaryPath.endsWith ".wasm" || !watPath.endsWith ".wat" then
    throw (IO.userError "PSC1_WAT_OUTPUT_EXTENSION")
  let output ← IO.Process.output {
    cmd := "wasm2wat"
    args := #[binaryPath, "--enable-gc"]
  }
  if output.exitCode != 0 || output.stdout.isEmpty then
    throw (IO.userError ("PSC1_WAT_DECODE_FAILED: " ++ output.stderr))
  psHostDirectEnsureParent watPath
  IO.FS.writeFile watPath output.stdout
  IO.println ("PSC1_DIRECT_WAT: " ++ watPath)
