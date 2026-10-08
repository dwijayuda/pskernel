import ProofScript.Compiler.Effect

structure EffectContext where
  label : String

structure EffectState where
  count : Nat

def effectIncrementState (state : EffectState) : EffectState :=
  EffectState.mk (Nat.add state.count 1)

def effectIncrement : CompilerM EffectContext EffectState String Unit :=
  compilerModify effectIncrementState

def effectReadLabelNext
    (context : EffectContext) :
    CompilerM EffectContext EffectState String String :=
  compilerPure context.label

def effectReadLabel : CompilerM EffectContext EffectState String String :=
  compilerBind (compilerRead Unit.unit) effectReadLabelNext

def effectGetCountNext
    (state : EffectState) :
    CompilerM EffectContext EffectState String Nat :=
  compilerPure state.count

def effectGetCount : CompilerM EffectContext EffectState String Nat :=
  compilerBind (compilerGet Unit.unit) effectGetCountNext

def effectFailure : CompilerM EffectContext EffectState String Nat :=
  compilerThrow "failed"

def effectRecover
    (error : String) :
    CompilerM EffectContext EffectState String Nat :=
  compilerPure 7

def effectRecovered : CompilerM EffectContext EffectState String Nat :=
  compilerTryCatch effectFailure effectRecover

def effectRollbackRecovered :
    CompilerM EffectContext EffectState String Nat :=
  compilerRollback effectFailure effectRecover

def effectRunRecovered
    (context : EffectContext)
    (state : EffectState) :
    Result (Prod Nat EffectState) String :=
  effectRollbackRecovered.run context state

def effectDoCount :
    CompilerM EffectContext EffectState String Nat :=
  do
    let state : EffectState <- compilerGet Unit.unit;
    return state.count

def effectOrElse : CompilerM EffectContext EffectState String Nat :=
  compilerOrElse effectFailure (compilerPure 9)

def effectCheckpointThenRestoreNext
    (saved : EffectState) :
    CompilerM EffectContext EffectState String Unit :=
  compilerRestore saved

def effectCheckpointThenRestore :
    CompilerM EffectContext EffectState String Unit :=
  compilerBind
    (compilerCheckpoint Unit.unit)
    effectCheckpointThenRestoreNext


def effectSetFive : CompilerM EffectContext EffectState String Unit :=
  compilerSet (EffectState.mk 5)

def effectInnerContext (context : EffectContext) : EffectContext :=
  EffectContext.mk "inner"

def effectWithReader : CompilerM EffectContext EffectState String String :=
  compilerWithReader effectReadLabel effectInnerContext

def effectFailureAlias : CompilerM EffectContext EffectState String Nat :=
  compilerFailure "failed-alias"

def effectCommitted : CompilerM EffectContext EffectState String Unit :=
  compilerCommit Unit.unit

def effectWhenTrue : CompilerM EffectContext EffectState String Unit :=
  compilerWhen true effectIncrement

def effectWhenFalse : CompilerM EffectContext EffectState String Unit :=
  compilerWhen false effectIncrement

def effectUnlessTrue : CompilerM EffectContext EffectState String Unit :=
  compilerUnless true effectIncrement

def effectUnlessFalse : CompilerM EffectContext EffectState String Unit :=
  compilerUnless false effectIncrement
