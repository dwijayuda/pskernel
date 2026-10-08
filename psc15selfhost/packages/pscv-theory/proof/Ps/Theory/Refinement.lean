import Ps.Theory.Core
import Ps.Erasure.Definition
import Ps.CompilerIr.Specialize

inductive PsDeclarativeConversion :
    PsKernelExpr -> PsKernelExpr -> Prop where
  | refl (expr : PsKernelExpr) :
      PsDeclarativeConversion expr expr

theorem psDeclarativeConversionRefl
    (expr : PsKernelExpr) :
    PsDeclarativeConversion expr expr :=
  PsDeclarativeConversion.refl expr


theorem psKernelExactDefEqWitnessSound
    (witness : PsKernelExactDefEqWitness) :
    PsDeclarativeConversion
      witness.expr
      witness.expr :=
  PsDeclarativeConversion.refl witness.expr

theorem psKernelExactDefEqSound
    (expr : PsKernelExpr) :
    PsDeclarativeConversion expr expr :=
  psKernelExactDefEqWitnessSound
    (PsKernelExactDefEqWitness.mk expr)


theorem psErasureProofDeclarationOmitted
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
  if_pos isProof

theorem psSpecializationLiteralModulePreserves :
    psIrSpecializeModule
      psTheorySpecializationModule =
      Except.ok psTheorySpecializationModule :=
  Eq.refl
    (Except.ok psTheorySpecializationModule)
