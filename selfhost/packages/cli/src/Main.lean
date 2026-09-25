import Ps.Host.CompilerDriver

def psCliUsage : String :=
  "ProofScript PSC1 Lean bootstrap\n" ++
  "usage:\n" ++
  "  psc1 check <input.lean|input.ps>\n" ++
  "  psc1 build <input.lean|input.ps> --out <output.ts>\n" ++
  "  psc1 translate <input.lean|input.ps> --to <lean|ps>\n" ++
  "  psc1 translate <input.lean|input.ps> --to <lean|ps> --out <output>\n" ++
  "  psc1 emit-lean <input.lean|input.ps> [--out <output.lean>]\n" ++
  "  psc1 emit-ps <input.lean|input.ps> [--out <output.ps>]\n" ++
  "  psc1 admissions <input.lean|input.ps>\n" ++
  "  psc1 typescript <input.lean|input.ps>\n" ++
  "  psc1 compile <input.lean|input.ps> --out <output.ts>"

def main (args : List String) : IO Unit := do
  match args with
  | [] =>
      IO.println "ProofScript PSC1 Lean bootstrap"
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
  | ["build", inputPath, "--out", outputPath] =>
      psHostCompilerBuild inputPath outputPath
  | ["compile", inputPath, "--out", outputPath] =>
      psHostCompilerBuild inputPath outputPath
  | _ =>
      throw (IO.userError psCliUsage)
