import Ps.CompilerIr.Specialize
import Ps.CompilerIr.Encode

def benchmarkNat : PsVerifiedIrType := .primitive .nat

def benchmarkBody : Nat -> PsVerifiedIrExpr
  | 0 => .call (.var "sharedIdentity") [benchmarkNat] [.literal (.natural 0)]
  | n + 1 =>
      let child := benchmarkBody n
      .intrinsic .natAdd [] [child, child]

def benchmarkModule : PsVerifiedIrModule :=
  let generic := PsVerifiedIrDeclaration.mk "sharedIdentity"
    [PsVerifiedIrTypeParameter.mk "A"]
    [PsVerifiedIrParameter.mk "value" (.typeParameter "A")]
    (.typeParameter "A") (.var "value")
  let concrete := (List.range 128).map (fun n =>
    PsVerifiedIrDeclaration.mk ("entry" ++ toString n) [] [] benchmarkNat (benchmarkBody 8))
  PsVerifiedIrModule.mk [] [] [] (generic :: concrete)

def main (args : List String) : IO Unit := do
  let directory : System.FilePath := args.headD "dist/specialize-queue"
  IO.FS.createDirAll directory
  let input := benchmarkModule
  let inputReport := psCheckVerifiedIrModule psIrCheckDefaultOptions input
  unless inputReport.accepted && inputReport.traversalComplete do
    throw (IO.userError "PSC1_QUEUE_BENCHMARK_INPUT_INVALID")
  let encoded <- match psIrEncodeModule input with
    | .ok value => pure value
    | .error _ => throw (IO.userError "PSC1_QUEUE_BENCHMARK_INPUT_ENCODING_REFUSED")
  IO.FS.writeFile (directory / "input.ir.json") encoded
  match psIrSpecializeValidatedModuleDetailed (PsValidatedIrModule.mk input) with
  | .error diagnostic =>
      let result := psJsonObject [
        ("status", psJsonQuote "refused"),
        ("phase", psJsonQuote diagnostic.phase),
        ("code", psJsonQuote (psIrSpecializeErrorCode diagnostic.error)),
        ("inputDeclarations", toString input.declarations.length),
        ("repeatedReferences", "32768")]
      IO.FS.writeFile (directory / "result.json") result
      IO.println ("PSC1_QUEUE_BENCHMARK: " ++ result)
  | .ok output =>
      let report := psCheckVerifiedIrModule psIrCheckDefaultOptions output.raw
      unless report.accepted && report.traversalComplete do
        throw (IO.userError "PSC1_QUEUE_BENCHMARK_OUTPUT_INVALID")
      let expected := (List.range 128).map (fun n => "entry" ++ toString n)
      unless output.raw.declarations.length == 129 &&
          expected.all (fun name => output.raw.declarations.any (fun d => d.name == name)) &&
          output.raw.declarations.countP (fun d => d.name == "sharedIdentity$spec$Nat") == 1 do
        throw (IO.userError "PSC1_QUEUE_BENCHMARK_LOST_DECLARATION")
      let transformed <- match psIrEncodeModule output.raw with
        | .ok value => pure value
        | .error _ => throw (IO.userError "PSC1_QUEUE_BENCHMARK_OUTPUT_ENCODING_REFUSED")
      IO.FS.writeFile (directory / "output.ir.json") transformed
      let result := psJsonObject [
        ("status", psJsonQuote "accepted"),
        ("inputDeclarations", toString input.declarations.length),
        ("outputDeclarations", toString output.raw.declarations.length),
        ("repeatedReferences", "32768"),
        ("allConcreteDeclarationsRetained", "true"),
        ("specializedIdentityCopies", "1")]
      IO.FS.writeFile (directory / "result.json") result
      IO.println ("PSC1_QUEUE_BENCHMARK: " ++ result)
