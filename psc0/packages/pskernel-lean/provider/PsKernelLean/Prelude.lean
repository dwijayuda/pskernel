import Ps.Environment.SelfHostProd
import PsKernelLean.Replay

namespace PsKernelLean

def buildLeanPreludeEnvironment : IO (Except PsKernelLeanError Lean.Kernel.Environment) := do
  let declarations := psSelfHostProdPreludeEnvironment.declarations
  -- Lean 4.35.0 Environment.lean import path checks immutable declarations
  -- with kenv.addDeclCore 0 0. This provider entry is only for the selected,
  -- separately SHA/FNV-guarded Standard. Ordinary source admission retains
  -- 2,000,000 heartbeats and depth 20,000 in NativeV7.check/Admission.
  -- 0 is Lean's import-time resource policy, NOT unchecked insertion.
  buildLeanPreludeEnvironmentFromDeclarations declarations 0 0

end PsKernelLean
