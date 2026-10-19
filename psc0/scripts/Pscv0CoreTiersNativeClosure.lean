import Ps.Host.StandardClosure

/-!
Read-only native measurement of progressively narrower *source import roots*.

This compares:
  engineOnly = selected Core module engine alone;
  engineTs = same engine + advertised TypeScript/IR/codegen roots, excluding
             the two explicit Rust/Wasm roots;
  selectedAll = exact existing seven-root selected Core compiler inventory.

These are **candidate workload measurements only**. Neither the module
import graph nor any declaration/proof is modified or dropped inside a root.
No source package becomes optional merely because this graph is smaller.
A real Stage1 target and executable production packaging must be separately
qualified before choosing any narrower compiler/kernel scope.
-/

private def coreEngineOnlyImports : Array Lean.Import :=
  #[{ module := `Ps.Compiler.Pscv0ModuleEngine }]

private def coreEngineTsImports : Array Lean.Import :=
  #[{ module := `Ps.Compiler.Pscv0ModuleEngine },
    { module := `Ps.BackendTs.Readable },
    { module := `Ps.CompilerIr.Checked },
    { module := `Ps.Codegen.Api },
    { module := `Ps.Codegen.Provenance }]

private def toSummary
    (measured : PsV7Native.CoreNativeClosure) : Lean.Json :=
  Lean.Json.mkObj [
    ("sourceModules", Lean.toJson measured.sourceModules.size),
    ("sourceDeclarations", Lean.toJson measured.sourceDeclarations),
    ("externalRoots", Lean.toJson measured.roots.length),
    ("externalClosure", Lean.toJson measured.entries.size)]

def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError "usage: pscv0_core_tiers_native_closure OUTPUT.json")
  let engine ← PsV7Native.collectCoreNativeClosureWithImports coreEngineOnlyImports
  let engineTs ← PsV7Native.collectCoreNativeClosureWithImports coreEngineTsImports
  let selected ← PsV7Native.collectCoreSelectedNativeClosure
  let raw := Lean.Json.mkObj [
    ("schema", Lean.toJson ("psc0-core-native-tier-comparison/1" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("engineOnly", engine.report),
    ("engineTs", engineTs.report),
    ("selectedAll", selected.report),
    ("selectedProfileInstalled", Lean.toJson false),
    ("candidateKernelAdmitted", Lean.toJson false),
    ("coreCompilerSelfHost", Lean.toJson false)]
  IO.FS.writeFile (System.FilePath.mk output) (raw.compress ++ "\n")
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("psc0-core-native-tier-summary/1" : String)),
    ("engineOnly", toSummary engine),
    ("engineTs", toSummary engineTs),
    ("selectedAll", toSummary selected),
    ("candidateKernelAdmitted", Lean.toJson false)]).compress
