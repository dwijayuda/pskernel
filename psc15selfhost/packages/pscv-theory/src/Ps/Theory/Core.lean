import Ps.KernelCore.Core.Expr

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
