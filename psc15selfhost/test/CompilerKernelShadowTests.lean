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

def psPhase13KernelShadowTheoremPass : Bool :=
  let pName := psRootName "p";
  let hName := psRootName "h";
  let theoremType :=
    PsExpr.forallE
      pName
      (PsExpr.sortE PsLevel.zero)
      (PsExpr.forallE
        hName
        (PsExpr.bvar 0)
        (PsExpr.bvar 1)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let theoremProof :=
    PsExpr.lam
      pName
      (PsExpr.sortE PsLevel.zero)
      (PsExpr.lam
        hName
        (PsExpr.bvar 0)
        (PsExpr.bvar 0)
        PsBinderInfo.explicit)
      PsBinderInfo.explicit;
  let declaration :=
    PsDeclaration.theoremDecl
      (psRootName "identityProof")
      []
      theoremType
      theoremProof;
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error _ => false
  | Except.ok report => Nat.beq report.checkedDeclarations 1

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
    psPhase13KernelShadowTheoremPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_THEOREM"
  psPhase13Require
    psPhase13KernelShadowSequentialPass
    "PSC2_KERNEL_CORE_PHASE13_SHADOW_SEQUENTIAL"
  IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_MINIMAL: PASS"
  IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_POSITIVE: PASS"
