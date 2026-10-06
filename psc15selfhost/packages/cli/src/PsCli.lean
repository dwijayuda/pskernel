import Ps.Host.CompilerDriver

def psCliUsage : String :=
  "ProofScript PSC2 native compiler (Lean 4.34 bootstrap implementation)\n" ++
  "usage:\n" ++
  "  psc check <input.lean|input.ps>\n" ++
  "  psc build <input.lean|input.ps> --out <output.js|output.ts>\n" ++
  "  psc translate <input.lean|input.ps> --to <lean|ps>\n" ++
  "  psc translate <input.lean|input.ps> --to <lean|ps> --out <output>\n" ++
  "  psc emit-lean <input.lean|input.ps> [--out <output.lean>]\n" ++
  "  psc emit-ps <input.lean|input.ps> [--out <output.ps>]\n" ++
  "  psc admissions <input.lean|input.ps>\n" ++
  "  psc typescript <input.lean|input.ps>\n" ++
  "  psc javascript <input.lean|input.ps>\n" ++
  "  psc rust <input.lean|input.ps> [--out <output.rs>]\n" ++
  "  psc rust-coverage <input.lean|input.ps>\n" ++
  "  psc wasm <input.lean|input.ps> --out <output.wasm>\n" ++
  "  psc compile <input.lean|input.ps> --out <output.js|output.ts>"

def psCliMain (args : List String) : IO Unit := do
  match args with
  | [] =>
      IO.println "ProofScript PSC2 native compiler (Lean 4.34 bootstrap implementation)"
  | ["--help"] =>
      IO.println psCliUsage
  | ["--version"] =>
      IO.println "psc native-bootstrap 0.1 (Lean 4.34.0)"
  | ["check", inputPath] =>
      psHostCompilerCheck inputPath
  | ["translate", inputPath, "--to", target] =>
      psHostCompilerTranslate inputPath target
  | ["translate", inputPath, "--to", target, "--out", outputPath] =>
      psHostCompilerTranslateToFile inputPath target outputPath
  | ["emit-lean", inputPath] =>
      psHostCompilerTranslate inputPath "lean"
  | ["emit-lean", inputPath, "--out", outputPath] =>
      psHostCompilerTranslateToFile inputPath "lean" outputPath
  | ["emit-ps", inputPath] =>
      psHostCompilerTranslate inputPath "ps"
  | ["emit-ps", inputPath, "--out", outputPath] =>
      psHostCompilerTranslateToFile inputPath "ps" outputPath
  | ["admissions", inputPath] =>
      psHostCompilerAdmissions inputPath
  | ["typescript", inputPath] =>
      psHostCompilerTypeScript inputPath
  | ["javascript", inputPath] =>
      psHostCompilerJavaScript inputPath
  | ["rust", inputPath] =>
      psHostCompilerRust inputPath
  | ["rust", inputPath, "--out", outputPath] =>
      psHostCompilerRustToFile inputPath outputPath
  | ["rust-coverage", inputPath] =>
      psHostCompilerRustCoverage inputPath
  | ["wasm", inputPath, "--out", outputPath] =>
      psHostCompilerWasm32ToFile inputPath outputPath
  | ["build", inputPath, "--out", outputPath] =>
      psHostCompilerBuild inputPath outputPath
  | ["compile", inputPath, "--out", outputPath] =>
      psHostCompilerBuild inputPath outputPath
  | _ =>
      throw (IO.userError psCliUsage)
