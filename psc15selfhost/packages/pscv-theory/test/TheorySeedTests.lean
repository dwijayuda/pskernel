import Ps.Theory.Refinement

def psTheorySeedExpr : PsKernelExpr :=
  PsKernelExpr.bvar 0

def psTheorySeedProof :
    PsDeclarativeConversion
      psTheorySeedExpr
      psTheorySeedExpr :=
  psKernelExactDefEqSound psTheorySeedExpr

def main : IO Unit := do
  IO.println "PSCV_THEORY_SEED_TESTS: PASS"


def psTheorySpecializationProof :
    psIrSpecializeModule
      psTheorySpecializationModule =
      Except.ok psTheorySpecializationModule :=
  psSpecializationLiteralModulePreserves
