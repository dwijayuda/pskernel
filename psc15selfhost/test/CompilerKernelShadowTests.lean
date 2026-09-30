import Ps.Compiler.Api

def psPhase13KernelShadowCheckCount
    (sourceKind : PsCompilerSourceKind)
    (source : String)
    (expected : Nat) : Bool :=
  match psCompilerKernelShadowCheckSource sourceKind source with
  | Except.error _ => false
  | Except.ok report => Nat.beq report.checkedDeclarations expected

def psPhase13KernelShadowMinimalSource : String :=
  "def answer : Nat := 42"

def psPhase13KernelShadowTheoremSource : String :=
  "theorem selfEq(x: Nat): x = x := by rfl;"

def psPhase13KernelShadowMinimalPass : Bool :=
  psPhase13KernelShadowCheckCount
    PsCompilerSourceKind.lean
    psPhase13KernelShadowMinimalSource
    1

def psPhase13KernelShadowProofScriptPass : Bool :=
  psPhase13KernelShadowCheckCount
    PsCompilerSourceKind.proofScript
    "def answer: Nat := 42;"
    1

def psPhase13KernelShadowFunctionPass : Bool :=
  psPhase13KernelShadowCheckCount
    PsCompilerSourceKind.lean
    "def idNat (x : Nat) : Nat := x"
    1

def psPhase13KernelShadowPolymorphicPass : Bool :=
  psPhase13KernelShadowCheckCount
    PsCompilerSourceKind.lean
    "def identity (α : Type) (x : α) : α := x"
    1

def psPhase13KernelShadowTheoremPreparePass : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.proofScript
        psPhase13KernelShadowTheoremSource with
  | Except.error _ => false
  | Except.ok _ => true

def psPhase13KernelShadowTheoremPass : Bool :=
  psPhase13KernelShadowCheckCount
    PsCompilerSourceKind.proofScript
    psPhase13KernelShadowTheoremSource
    1

def psPhase13KernelShadowSequentialPass : Bool :=
  psPhase13KernelShadowCheckCount
    PsCompilerSourceKind.lean
    ("def first : Nat := 41\n" ++
      "def second : Nat := first")
    2

def psPhase13Require
    (condition : Bool)
    (marker : String) : IO Unit := do
  if condition then
    IO.println (marker ++ ": PASS")
  else
    throw (IO.userError (marker ++ ": FAIL"))

def psPhase13RequireTheoremShadow : IO Unit := do
  match
      psCompilerKernelShadowCheckSource
        PsCompilerSourceKind.proofScript
        psPhase13KernelShadowTheoremSource with
  | Except.ok report =>
      psPhase13Require
        (Nat.beq report.checkedDeclarations 1)
        "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM"
  | Except.error (PsCompilerKernelShadowApiError.compiler _) =>
      throw
        (IO.userError
          "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_COMPILER: FAIL")
  | Except.error (PsCompilerKernelShadowApiError.shadow shadowError) =>
      match shadowError with
      | PsCompilerKernelShadowError.universeMetavariable =>
          throw (IO.userError "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_UNIVERSE_MVAR: FAIL")
      | PsCompilerKernelShadowError.freeVariable =>
          throw (IO.userError "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_FVAR: FAIL")
      | PsCompilerKernelShadowError.expressionMetavariable =>
          throw (IO.userError "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_MVAR: FAIL")
      | PsCompilerKernelShadowError.unsupportedDeclaration =>
          throw (IO.userError "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_UNSUPPORTED: FAIL")
      | PsCompilerKernelShadowError.duplicatePreludeAssumption =>
          throw (IO.userError "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_DUP_PRELUDE: FAIL")
      | PsCompilerKernelShadowError.kernelRejected message =>
          throw
            (IO.userError
              ("PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_KERNEL: FAIL: " ++ message))

def main : IO Unit := do
  psPhase13Require
    psPhase13KernelShadowMinimalPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_LEAN_LITERAL"
  psPhase13Require
    psPhase13KernelShadowProofScriptPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_PROOFSCRIPT_LITERAL"
  psPhase13Require
    psPhase13KernelShadowFunctionPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_FUNCTION"
  psPhase13Require
    psPhase13KernelShadowPolymorphicPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_POLYMORPHIC"
  psPhase13Require
    psPhase13KernelShadowTheoremPreparePass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM_PREPARE"
  psPhase13RequireTheoremShadow
  psPhase13Require
    psPhase13KernelShadowSequentialPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_SEQUENTIAL"
  IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_MINIMAL: PASS"
  IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_POSITIVE: PASS"
