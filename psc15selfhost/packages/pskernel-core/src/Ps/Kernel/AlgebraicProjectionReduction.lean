import Ps.Kernel.AlgebraicProjection

inductive PsKernelAlgProjectReduceContinuation where
  | continuation (family : PsKernelName) (index : PsKernelNatural) (info : PsKernelAlgProjectInfo)

inductive PsKernelAlgProjectReduceTask where
  | metadata (state : PsKernelAlgProjectMetaState)
  | spine (cursor : PsKernelExpr) (info : PsKernelAlgProjectInfo) (arguments : PsKernelList PsKernelExpr)
  | name (info : PsKernelAlgProjectInfo) (arguments : PsKernelList PsKernelExpr) (work : PsKernelList PsKernelOrderTask)
  | drop (remaining : PsKernelNatural) (fields arguments : PsKernelList PsKernelExpr)
  | arity (fields arguments original : PsKernelList PsKernelExpr)
  | select (index : PsKernelNatural) (arguments : PsKernelList PsKernelExpr)

inductive PsKernelAlgProjectReduceState where
  | state (family : PsKernelName) (index : PsKernelNatural) (major : PsKernelExpr) (task : PsKernelAlgProjectReduceTask)

inductive PsKernelAlgProjectReduceStep where
  | next (state : PsKernelAlgProjectReduceState)
  | major (value : PsKernelExpr) (continuation : PsKernelAlgProjectReduceContinuation)
  | neutral (value : PsKernelExpr)
  | reduced (value : PsKernelExpr)
  | rejected (error : PsKernelCheckError)

def psKernelAlgProjectReduceNext (family : PsKernelName) (index : PsKernelNatural)
    (major : PsKernelExpr) (task : PsKernelAlgProjectReduceTask) : PsKernelAlgProjectReduceStep :=
  PsKernelAlgProjectReduceStep.next (PsKernelAlgProjectReduceState.state family index major task)

def psKernelAlgProjectReduceStep (state : PsKernelAlgProjectReduceState) : PsKernelAlgProjectReduceStep :=
  match state with
  | PsKernelAlgProjectReduceState.state family index major task =>
      match task with
      | PsKernelAlgProjectReduceTask.metadata current =>
          match psKernelAlgProjectMetaStep current with
          | PsKernelAlgProjectMetaStep.next next => psKernelAlgProjectReduceNext family index major (PsKernelAlgProjectReduceTask.metadata next)
          | PsKernelAlgProjectMetaStep.rejected error => PsKernelAlgProjectReduceStep.rejected error
          | PsKernelAlgProjectMetaStep.ready info => PsKernelAlgProjectReduceStep.major major
              (PsKernelAlgProjectReduceContinuation.continuation family index info)
      | PsKernelAlgProjectReduceTask.spine cursor info arguments =>
          match cursor with
          | PsKernelExpr.app fn arg => psKernelAlgProjectReduceNext family index major
              (PsKernelAlgProjectReduceTask.spine fn info (PsKernelList.cons arg arguments))
          | PsKernelExpr.constE name levels =>
              match levels with
              | PsKernelList.nil =>
                  match info with
                  | PsKernelAlgProjectInfo.info constructor unusedParameters unusedFields unusedSelected => psKernelAlgProjectReduceNext family index major
                      (PsKernelAlgProjectReduceTask.name info arguments
                        (PsKernelList.cons (PsKernelOrderTask.name name constructor) PsKernelList.nil))
              | _ => PsKernelAlgProjectReduceStep.neutral (PsKernelExpr.proj family index major)
          | _ => PsKernelAlgProjectReduceStep.neutral (PsKernelExpr.proj family index major)
      | PsKernelAlgProjectReduceTask.name info arguments current =>
          match psKernelOrderStep current with
          | PsKernelOrderStep.next next => psKernelAlgProjectReduceNext family index major
              (PsKernelAlgProjectReduceTask.name info arguments next)
          | PsKernelOrderStep.done order =>
              match order with
              | PsKernelOrder.same =>
                  match info with
                  | PsKernelAlgProjectInfo.info unusedConstructor parameters fields unusedSelected => psKernelAlgProjectReduceNext family index major
                      (PsKernelAlgProjectReduceTask.drop parameters fields arguments)
              | _ => PsKernelAlgProjectReduceStep.neutral (PsKernelExpr.proj family index major)
          | _ => PsKernelAlgProjectReduceStep.rejected PsKernelCheckError.invalidState
      | PsKernelAlgProjectReduceTask.drop remaining fields arguments =>
          match remaining with
          | PsKernelNatural.zero => psKernelAlgProjectReduceNext family index major
              (PsKernelAlgProjectReduceTask.arity fields arguments arguments)
          | _ =>
              match arguments with
              | PsKernelList.cons unused rest => psKernelAlgProjectReduceNext family index major
                  (PsKernelAlgProjectReduceTask.drop (psKernelNaturalPred remaining) fields rest)
              | _ => PsKernelAlgProjectReduceStep.rejected PsKernelCheckError.typeMismatch
      | PsKernelAlgProjectReduceTask.arity fields arguments original =>
          match fields with
          | PsKernelList.nil =>
              match arguments with
              | PsKernelList.nil => psKernelAlgProjectReduceNext family index major (PsKernelAlgProjectReduceTask.select index original)
              | _ => PsKernelAlgProjectReduceStep.rejected PsKernelCheckError.typeMismatch
          | PsKernelList.cons unused rest =>
              match arguments with
              | PsKernelList.cons unusedArg tail => psKernelAlgProjectReduceNext family index major
                  (PsKernelAlgProjectReduceTask.arity rest tail original)
              | _ => PsKernelAlgProjectReduceStep.rejected PsKernelCheckError.typeMismatch
      | PsKernelAlgProjectReduceTask.select cursor arguments =>
          match arguments with
          | PsKernelList.nil => PsKernelAlgProjectReduceStep.rejected PsKernelCheckError.typeMismatch
          | PsKernelList.cons arg rest =>
              match cursor with
              | PsKernelNatural.zero => PsKernelAlgProjectReduceStep.reduced arg
              | _ => psKernelAlgProjectReduceNext family index major (PsKernelAlgProjectReduceTask.select (psKernelNaturalPred cursor) rest)

def psKernelAlgProjectReduceStart (env : PsKernelList PsKernelDefinition) (family : PsKernelName)
    (index : PsKernelNatural) (major : PsKernelExpr) : PsKernelAlgProjectReduceState :=
  PsKernelAlgProjectReduceState.state family index major
    (PsKernelAlgProjectReduceTask.metadata (psKernelAlgProjectMetaStart env family index))

def psKernelAlgProjectReduceResume (continuation : PsKernelAlgProjectReduceContinuation)
    (major : PsKernelExpr) : PsKernelAlgProjectReduceState :=
  match continuation with
  | PsKernelAlgProjectReduceContinuation.continuation family index info =>
      PsKernelAlgProjectReduceState.state family index major (PsKernelAlgProjectReduceTask.spine major info PsKernelList.nil)
