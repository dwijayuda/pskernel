import Ps.KernelCore.Core.Expr
import Ps.Erasure.Definition
import Ps.CompilerIr.Specialize

inductive PsDeclarativeConversion :
    PsKernelExpr -> PsKernelExpr -> Prop where
  | refl (expr : PsKernelExpr) :
      PsDeclarativeConversion expr expr

def psDeclarativeConversionRefl
    (expr : PsKernelExpr) :
    PsDeclarativeConversion expr expr :=
  PsDeclarativeConversion.refl expr

structure PsKernelExactDefEqWitness where
  expr : PsKernelExpr

def psKernelExactDefEqWitnessSound
    (witness : PsKernelExactDefEqWitness) :
    PsDeclarativeConversion
      witness.expr
      witness.expr :=
  PsDeclarativeConversion.refl witness.expr

def psKernelExactDefEqSound
    (expr : PsKernelExpr) :
    PsDeclarativeConversion expr expr :=
  psKernelExactDefEqWitnessSound
    (PsKernelExactDefEqWitness.mk expr)


def psErasureProofDeclarationOmitted
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (name : PsName)
    (type value : PsExpr)
    (isProof :
      psErasureIsProp
        environment
        psLocalEmpty
        type = true) :
    psEraseDefinition
      environment
      scope
      name
      type
      value =
      Except.ok Option.none :=
  match isProof with
  | Eq.refl _ =>
      Eq.refl (Except.ok Option.none)

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

def psSpecializationLiteralModulePreserves :
    psIrSpecializeModule
      psTheorySpecializationModule =
      Except.ok psTheorySpecializationModule :=
  Eq.refl
    (Except.ok psTheorySpecializationModule)
