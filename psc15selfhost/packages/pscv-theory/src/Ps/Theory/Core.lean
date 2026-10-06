import Ps.KernelCore.Core.Expr
import Ps.CompilerIr.Model

structure PsKernelExactDefEqWitness where
  expr : PsKernelExpr

def psKernelExactDefEqWitnessLeft
    (witness : PsKernelExactDefEqWitness) : PsKernelExpr :=
  witness.expr

def psKernelExactDefEqWitnessRight
    (witness : PsKernelExactDefEqWitness) : PsKernelExpr :=
  witness.expr

def psTheorySpecializationU32 : PsVerifiedIrType :=
  PsVerifiedIrType.primitive
    PsVerifiedIrPrimitiveType.uint32

def psTheorySpecializationModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "answer"
        typeParameters := []
        parameters := []
        resultType := psTheorySpecializationU32
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.machineInteger
              PsVerifiedIrMachineIntegerType.uint32
              42)
      }
    ]
  }
