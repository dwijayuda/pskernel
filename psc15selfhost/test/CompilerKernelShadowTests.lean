import Ps.Compiler.Api

def psPhase13KernelShadowMinimalSource : String :=
  "def answer : Nat := 42"

def psPhase13KernelShadowMinimalPass : Bool :=
  match
      psCompilerKernelShadowCheckSource
        PsCompilerSourceKind.lean
        psPhase13KernelShadowMinimalSource with
  | Except.error _ => false
  | Except.ok report => Nat.beq report.checkedDeclarations 1

def main : IO Unit := do
  if psPhase13KernelShadowMinimalPass then
    IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_MINIMAL: PASS"
  else
    throw
      (IO.userError
        "PSC2_KERNEL_CORE_PHASE13_SHADOW_MINIMAL: FAIL")
