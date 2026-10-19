import Ps.Host.WasmComponent

-- Native and npm launchers use this one command model. There is no implicit
-- fallback to the archived generated PSC0 compiler or its stale kernel artifact.
def psCliUsage : String :=
  "ProofScript PSC1 checked native compiler (Lean 4.34.0)\n" ++
  "usage:\n" ++
  "  psc1 check <input.lean|input.ps>\n" ++
  "  psc1 build <input.lean|input.ps> --out <output.js|output.ts>\n" ++
  "  psc1 build <input.lean|input.ps> --target <js|ts|rust|wasm-core> --out <output>\n" ++
  "  psc1 build <input.lean|input.ps> --target wasm-component --export <name> --out <component.wasm>\n" ++
  "  psc1 translate <input.lean|input.ps> --to <lean|ps> [--out <output>]\n" ++
  "  psc1 emit-lean <input.lean|input.ps> [--out <output.lean>]\n" ++
  "  psc1 emit-ps <input.lean|input.ps> [--out <output.ps>]\n" ++
  "  psc1 admissions <input.lean|input.ps>\n" ++
  "  psc1 typescript <input.lean|input.ps>\n" ++
  "  psc1 wat <input.wasm> --out <output.wat>\n" ++
  "Direct builds require installed PSC1 host-tools; Rust also requires cargo/rustfmt, Wasm requires wasm-tools."

private def buildDefault (inputPath outputPath : String) : IO Unit := do
  if outputPath.endsWith ".js" then psHostDirectJavaScript inputPath outputPath
  else if outputPath.endsWith ".ts" then psHostDirectTypeScript inputPath outputPath
  else throw (IO.userError "PSC1_OUTPUT_EXTENSION: use --target for Rust or Wasm")

def main (args : List String) : IO Unit := do
  match args with
  | [] | ["--help"] | ["-h"] => IO.println psCliUsage
  | ["--version"] => IO.println "PSC1 0.1.0-psc1.1 (checked native; Lean 4.34.0)"
  | ["--identity"] => IO.println "{\"protocol\":\"psc1-native/1\",\"profile\":\"psc1-checked-direct/1\",\"lean\":\"4.34.0\"}"
  | ["check", inputPath] => psHostDirectCheck inputPath
  | ["admissions", inputPath] => psHostDirectAdmissions inputPath
  | ["typescript", inputPath] => IO.print (← psHostDirectTypeScriptSource inputPath)
  | ["translate", inputPath, "--to", target] => psHostCompilerTranslate inputPath target
  | ["translate", inputPath, "--to", target, "--out", outputPath] =>
      psHostCompilerTranslateToFile inputPath target outputPath
  | ["emit-lean", inputPath] => psHostCompilerTranslate inputPath "lean"
  | ["emit-lean", inputPath, "--out", outputPath] => psHostCompilerTranslateToFile inputPath "lean" outputPath
  | ["emit-ps", inputPath] => psHostCompilerTranslate inputPath "ps"
  | ["emit-ps", inputPath, "--out", outputPath] => psHostCompilerTranslateToFile inputPath "ps" outputPath
  | ["build", inputPath, "--target", "js", "--out", outputPath] => psHostDirectJavaScript inputPath outputPath
  | ["build", inputPath, "--target", "ts", "--out", outputPath] => psHostDirectTypeScript inputPath outputPath
  | ["build", inputPath, "--target", "rust", "--out", outputPath] => psHostDirectRust inputPath outputPath
  | ["build", inputPath, "--target", "wasm-core", "--out", outputPath] => psHostDirectWasmCore inputPath outputPath
  | ["build", inputPath, "--target", "wasm-component", "--export", exportName, "--out", outputPath] =>
      psHostDirectWasmComponent inputPath exportName outputPath
  | ["build", inputPath, "--out", outputPath] | ["compile", inputPath, "--out", outputPath] =>
      buildDefault inputPath outputPath
  | ["wat", binaryPath, "--out", watPath] => psHostWasmBinaryToWat binaryPath watPath
  | _ => throw (IO.userError psCliUsage)
