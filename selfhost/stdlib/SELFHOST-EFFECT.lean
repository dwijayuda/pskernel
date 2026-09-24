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
