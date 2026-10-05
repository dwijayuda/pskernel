import Ps.Kernel.AlgebraicConstructor
import Ps.Kernel.Parameters
import Ps.Kernel.UnitInductive

/- Derive the dependent minor type for a uniform Type0 constructor. Fields are
opened from previously checked parameter-only templates. Direct recursive fields
receive induction hypotheses after all fields. Nested recursion is not enabled by
this fragment: a residual occurrence rejects, rather than losing a hypothesis. -/

inductive PsKernelAlgMinorFrame where
  | frame (pending : PsKernelList PsKernelExpr) (value : PsKernelExpr) (nextId : PsKernelNatural)
      (binders : PsKernelList PsKernelAlgBinder) (recursive : PsKernelList PsKernelExpr)
      (flags : PsKernelList (PsKernelOption PsKernelName))

inductive PsKernelAlgMinorTask where
  | parameters (pending : PsKernelList PsKernelExpr) (value : PsKernelExpr)
  | fields (frame : PsKernelAlgMinorFrame)
  | instantiate (frame : PsKernelAlgMinorFrame) (state : PsKernelParameterState)
  | equal (frame : PsKernelAlgMinorFrame) (type : PsKernelExpr) (state : PsKernelExprEqualState)
  | occurrence (frame : PsKernelAlgMinorFrame) (type : PsKernelExpr) (state : PsKernelOccurrenceState)
  | reverseFlags (frame : PsKernelAlgMinorFrame) (pending flags : PsKernelList (PsKernelOption PsKernelName))
  | reverseRecursive (frame : PsKernelAlgMinorFrame) (flags : PsKernelList (PsKernelOption PsKernelName))
      (pending recursive : PsKernelList PsKernelExpr)
  | hypotheses (value : PsKernelExpr) (nextId : PsKernelNatural) (binders : PsKernelList PsKernelAlgBinder)
      (flags : PsKernelList (PsKernelOption PsKernelName)) (pending : PsKernelList PsKernelExpr)
  | close (flags : PsKernelList (PsKernelOption PsKernelName)) (state : PsKernelCloseState)

inductive PsKernelAlgMinorState where
  | state (header : PsKernelAlgHeader) (constructor : PsKernelAlgConstructor)
      (fieldStart : PsKernelNatural) (task : PsKernelAlgMinorTask)

inductive PsKernelAlgMinorStep where
  | next (state : PsKernelAlgMinorState)
  | ready (type : PsKernelExpr) (recursiveFields : PsKernelList (PsKernelOption PsKernelName))
  | rejected (error : PsKernelCheckError)

def psKernelAlgMinorNext (header : PsKernelAlgHeader) (constructor : PsKernelAlgConstructor)
    (fieldStart : PsKernelNatural) (task : PsKernelAlgMinorTask) : PsKernelAlgMinorStep :=
  PsKernelAlgMinorStep.next (PsKernelAlgMinorState.state header constructor fieldStart task)

def psKernelAlgMinorContinue (header : PsKernelAlgHeader) (constructor : PsKernelAlgConstructor)
    (fieldStart : PsKernelNatural) (frame : PsKernelAlgMinorFrame) (type : PsKernelExpr)
    (flag : PsKernelOption PsKernelName) (recursive : PsKernelList PsKernelExpr) : PsKernelAlgMinorStep :=
  match frame with
  | PsKernelAlgMinorFrame.frame pending value nextId binders unusedRecursive flags =>
      psKernelAlgMinorNext header constructor fieldStart (PsKernelAlgMinorTask.fields
        (PsKernelAlgMinorFrame.frame pending (PsKernelExpr.app value (PsKernelExpr.fvar nextId))
          (psKernelNaturalSucc nextId)
          (PsKernelList.cons (PsKernelAlgBinder.binder nextId type PsKernelBinder.explicit) binders)
          recursive (PsKernelList.cons flag flags)))

def psKernelAlgMinorStep (state : PsKernelAlgMinorState) : PsKernelAlgMinorStep :=
  match state with
  | PsKernelAlgMinorState.state header constructor fieldStart task =>
      match header with
      | PsKernelAlgHeader.header family unusedType parameters arguments unusedBinders uniform =>
          match task with
          | PsKernelAlgMinorTask.parameters pending value =>
              match pending with
              | PsKernelList.cons arg tail => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.parameters tail (PsKernelExpr.app value arg))
              | PsKernelList.nil =>
                  match constructor with
                  | PsKernelAlgConstructor.constructor unusedName unusedConstructorType fields =>
                      psKernelAlgMinorNext header constructor fieldStart (PsKernelAlgMinorTask.fields
                        (PsKernelAlgMinorFrame.frame fields value fieldStart PsKernelList.nil PsKernelList.nil PsKernelList.nil))
          | PsKernelAlgMinorTask.fields frame =>
              match frame with
              | PsKernelAlgMinorFrame.frame pending value nextId binders recursive flags =>
                  match pending with
                  | PsKernelList.nil => psKernelAlgMinorNext header constructor fieldStart
                      (PsKernelAlgMinorTask.reverseFlags frame flags PsKernelList.nil)
                  | PsKernelList.cons template rest => psKernelAlgMinorNext header constructor fieldStart
                      (PsKernelAlgMinorTask.instantiate
                        (PsKernelAlgMinorFrame.frame rest value nextId binders recursive flags)
                        (psKernelParameterStart arguments template))
          | PsKernelAlgMinorTask.instantiate frame current =>
              match psKernelParameterStep current with
              | PsKernelParameterStep.next next => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.instantiate frame next)
              | PsKernelParameterStep.final result =>
                  match result with
                  | PsKernelParameterResult.done type => psKernelAlgMinorNext header constructor fieldStart
                      (PsKernelAlgMinorTask.equal frame type (psKernelExprEqualStart type uniform))
                  | PsKernelParameterResult.invalidScope => PsKernelAlgMinorStep.rejected PsKernelCheckError.invalidScope
                  | _ => PsKernelAlgMinorStep.rejected PsKernelCheckError.invalidState
          | PsKernelAlgMinorTask.equal frame type current =>
              match psKernelExprEqualStep current with
              | PsKernelExprEqualStep.next next => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.equal frame type next)
              | PsKernelExprEqualStep.equal =>
                  match frame with
                  | PsKernelAlgMinorFrame.frame unusedPending unusedValue nextId unusedBinders recursive unusedFlags =>
                      psKernelAlgMinorContinue header constructor fieldStart frame type
                        (PsKernelOption.some (psKernelUnitRecursorName family))
                        (PsKernelList.cons (PsKernelExpr.fvar nextId) recursive)
              | PsKernelExprEqualStep.different => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.occurrence frame type (psKernelOccurrenceStart family PsKernelFlag.no type))
              | _ => PsKernelAlgMinorStep.rejected PsKernelCheckError.invalidState
          | PsKernelAlgMinorTask.occurrence frame type current =>
              match psKernelOccurrenceStep current with
              | PsKernelOccurrenceStep.next next => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.occurrence frame type next)
              | PsKernelOccurrenceStep.absent =>
                  match frame with
                  | PsKernelAlgMinorFrame.frame unusedPending unusedValue unusedId unusedBinders recursive unusedFlags =>
                      psKernelAlgMinorContinue header constructor fieldStart frame type PsKernelOption.none recursive
              | PsKernelOccurrenceStep.found => PsKernelAlgMinorStep.rejected PsKernelCheckError.unsupported
              | _ => PsKernelAlgMinorStep.rejected PsKernelCheckError.invalidState
          | PsKernelAlgMinorTask.reverseFlags frame pending flags =>
              match pending with
              | PsKernelList.cons flag rest => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.reverseFlags frame rest (PsKernelList.cons flag flags))
              | PsKernelList.nil =>
                  match frame with
                  | PsKernelAlgMinorFrame.frame unusedPending unusedValue unusedId unusedBinders recursive unusedFlags =>
                      psKernelAlgMinorNext header constructor fieldStart
                        (PsKernelAlgMinorTask.reverseRecursive frame flags recursive PsKernelList.nil)
          | PsKernelAlgMinorTask.reverseRecursive frame flags pending recursive =>
              match pending with
              | PsKernelList.cons value rest => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.reverseRecursive frame flags rest (PsKernelList.cons value recursive))
              | PsKernelList.nil =>
                  match frame with
                  | PsKernelAlgMinorFrame.frame unusedPending value nextId binders unusedRecursive unusedFlags =>
                      psKernelAlgMinorNext header constructor fieldStart
                        (PsKernelAlgMinorTask.hypotheses value nextId binders flags recursive)
          | PsKernelAlgMinorTask.hypotheses value nextId binders flags pending =>
              match pending with
              | PsKernelList.cons field rest => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.hypotheses value (psKernelNaturalSucc nextId)
                    (PsKernelList.cons (PsKernelAlgBinder.binder nextId
                      (PsKernelExpr.app (PsKernelExpr.fvar parameters) field) PsKernelBinder.explicit) binders) flags rest)
              | PsKernelList.nil => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.close flags (psKernelCloseStart PsKernelCloseMode.pi binders
                    (PsKernelExpr.app (PsKernelExpr.fvar parameters) value)))
          | PsKernelAlgMinorTask.close flags current =>
              match psKernelCloseStep current with
              | PsKernelCloseStep.next next => psKernelAlgMinorNext header constructor fieldStart
                  (PsKernelAlgMinorTask.close flags next)
              | PsKernelCloseStep.done value => PsKernelAlgMinorStep.ready value flags
              | _ => PsKernelAlgMinorStep.rejected PsKernelCheckError.invalidState

def psKernelAlgMinorStart (header : PsKernelAlgHeader) (constructor : PsKernelAlgConstructor)
    (fieldStart : PsKernelNatural) : PsKernelAlgMinorState :=
  match header with
  | PsKernelAlgHeader.header unusedName unusedType unusedParameters arguments unusedBinders unusedUniform =>
      match constructor with
      | PsKernelAlgConstructor.constructor name unusedConstructorType unusedFields =>
          PsKernelAlgMinorState.state header constructor fieldStart
            (PsKernelAlgMinorTask.parameters arguments (PsKernelExpr.constE name PsKernelList.nil))
