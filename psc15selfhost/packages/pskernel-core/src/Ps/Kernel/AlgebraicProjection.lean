import Ps.Kernel.Environment
import Ps.Kernel.Occurrence
import Ps.Kernel.Parameters

/- Projection metadata is obtained only from completed algebraic admission.
This fragment allows one constructor with nonrecursive parameter-only fields;
recursive and dependent fields never acquire projection authority. All lookups,
field scans, parameter counts and substitutions share the outer budget. -/

inductive PsKernelAlgProjectInfo where
  | info (constructor : PsKernelName) (parameters : PsKernelNatural)
      (fields : PsKernelList PsKernelExpr) (selected : PsKernelExpr)

inductive PsKernelAlgProjectMetaTask where
  | lookup (state : PsKernelLookupState)
  | select (constructor : PsKernelName) (parameters : PsKernelNatural)
      (fields pending : PsKernelList PsKernelExpr) (index : PsKernelNatural)
  | scan (info : PsKernelAlgProjectInfo) (fields : PsKernelList PsKernelExpr)
  | occurrence (info : PsKernelAlgProjectInfo) (fields : PsKernelList PsKernelExpr) (state : PsKernelOccurrenceState)

inductive PsKernelAlgProjectMetaState where
  | state (family : PsKernelName) (index : PsKernelNatural) (task : PsKernelAlgProjectMetaTask)

inductive PsKernelAlgProjectMetaStep where
  | next (state : PsKernelAlgProjectMetaState)
  | ready (info : PsKernelAlgProjectInfo)
  | rejected (error : PsKernelCheckError)

def psKernelAlgProjectMetaNext (family : PsKernelName) (index : PsKernelNatural)
    (task : PsKernelAlgProjectMetaTask) : PsKernelAlgProjectMetaStep :=
  PsKernelAlgProjectMetaStep.next (PsKernelAlgProjectMetaState.state family index task)

def psKernelAlgProjectMetaStep (state : PsKernelAlgProjectMetaState) : PsKernelAlgProjectMetaStep :=
  match state with
  | PsKernelAlgProjectMetaState.state family index task =>
      match task with
      | PsKernelAlgProjectMetaTask.lookup current =>
          match psKernelLookupStep current with
          | PsKernelLookupStep.next next => psKernelAlgProjectMetaNext family index (PsKernelAlgProjectMetaTask.lookup next)
          | PsKernelLookupStep.missing => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.unknownConstant
          | PsKernelLookupStep.invalidState => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.invalidState
          | PsKernelLookupStep.found entry =>
              match entry with
              | PsKernelDefinition.algebraicFamily unusedName unusedType parameters constructors =>
                  match constructors with
                  | PsKernelList.cons constructor tail =>
                      match tail with
                      | PsKernelList.nil =>
                          match constructor with
                          | PsKernelAlgConstructor.constructor name unusedType fields => psKernelAlgProjectMetaNext family index
                              (PsKernelAlgProjectMetaTask.select name parameters fields fields index)
                      | _ => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.unsupported
                  | _ => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.unsupported
              | _ => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.unsupported
      | PsKernelAlgProjectMetaTask.select constructor parameters fields pending cursor =>
          match pending with
          | PsKernelList.nil => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.typeMismatch
          | PsKernelList.cons field rest =>
              match cursor with
              | PsKernelNatural.zero => psKernelAlgProjectMetaNext family index
                  (PsKernelAlgProjectMetaTask.scan (PsKernelAlgProjectInfo.info constructor parameters fields field) fields)
              | _ => psKernelAlgProjectMetaNext family index
                  (PsKernelAlgProjectMetaTask.select constructor parameters fields rest (psKernelNaturalPred cursor))
      | PsKernelAlgProjectMetaTask.scan info pending =>
          match pending with
          | PsKernelList.nil => PsKernelAlgProjectMetaStep.ready info
          | PsKernelList.cons field rest => psKernelAlgProjectMetaNext family index
              (PsKernelAlgProjectMetaTask.occurrence info rest (psKernelOccurrenceStart family PsKernelFlag.no field))
      | PsKernelAlgProjectMetaTask.occurrence info fields current =>
          match psKernelOccurrenceStep current with
          | PsKernelOccurrenceStep.next next => psKernelAlgProjectMetaNext family index
              (PsKernelAlgProjectMetaTask.occurrence info fields next)
          | PsKernelOccurrenceStep.absent => psKernelAlgProjectMetaNext family index (PsKernelAlgProjectMetaTask.scan info fields)
          | PsKernelOccurrenceStep.found => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.unsupported
          | _ => PsKernelAlgProjectMetaStep.rejected PsKernelCheckError.invalidState

def psKernelAlgProjectMetaStart (env : PsKernelList PsKernelDefinition) (family : PsKernelName)
    (index : PsKernelNatural) : PsKernelAlgProjectMetaState :=
  PsKernelAlgProjectMetaState.state family index (PsKernelAlgProjectMetaTask.lookup (PsKernelLookupState.search family env))

inductive PsKernelAlgProjectInferTask where
  | spine (type : PsKernelExpr) (arguments : PsKernelList PsKernelExpr)
  | name (arguments : PsKernelList PsKernelExpr) (tasks : PsKernelList PsKernelOrderTask)
  | metadata (arguments : PsKernelList PsKernelExpr) (state : PsKernelAlgProjectMetaState)
  | arity (arguments pending : PsKernelList PsKernelExpr) (remaining : PsKernelNatural) (field : PsKernelExpr)
  | instantiate (state : PsKernelParameterState)

inductive PsKernelAlgProjectInferState where
  | state (environment : PsKernelList PsKernelDefinition) (family : PsKernelName)
      (index : PsKernelNatural) (task : PsKernelAlgProjectInferTask)

inductive PsKernelAlgProjectInferStep where
  | next (state : PsKernelAlgProjectInferState)
  | done (type : PsKernelExpr)
  | rejected (error : PsKernelCheckError)

def psKernelAlgProjectInferNext (env : PsKernelList PsKernelDefinition) (family : PsKernelName)
    (index : PsKernelNatural) (task : PsKernelAlgProjectInferTask) : PsKernelAlgProjectInferStep :=
  PsKernelAlgProjectInferStep.next (PsKernelAlgProjectInferState.state env family index task)

def psKernelAlgProjectInferStep (state : PsKernelAlgProjectInferState) : PsKernelAlgProjectInferStep :=
  match state with
  | PsKernelAlgProjectInferState.state env family index task =>
      match task with
      | PsKernelAlgProjectInferTask.spine type arguments =>
          match type with
          | PsKernelExpr.app fn arg => psKernelAlgProjectInferNext env family index
              (PsKernelAlgProjectInferTask.spine fn (PsKernelList.cons arg arguments))
          | PsKernelExpr.constE actual levels =>
              match levels with
              | PsKernelList.nil => psKernelAlgProjectInferNext env family index
                  (PsKernelAlgProjectInferTask.name arguments (PsKernelList.cons (PsKernelOrderTask.name family actual) PsKernelList.nil))
              | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.unsupported
          | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.typeMismatch
      | PsKernelAlgProjectInferTask.name arguments current =>
          match psKernelOrderStep current with
          | PsKernelOrderStep.next next => psKernelAlgProjectInferNext env family index (PsKernelAlgProjectInferTask.name arguments next)
          | PsKernelOrderStep.done order =>
              match order with
              | PsKernelOrder.same => psKernelAlgProjectInferNext env family index
                  (PsKernelAlgProjectInferTask.metadata arguments (psKernelAlgProjectMetaStart env family index))
              | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.typeMismatch
          | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.invalidState
      | PsKernelAlgProjectInferTask.metadata arguments current =>
          match psKernelAlgProjectMetaStep current with
          | PsKernelAlgProjectMetaStep.next next => psKernelAlgProjectInferNext env family index
              (PsKernelAlgProjectInferTask.metadata arguments next)
          | PsKernelAlgProjectMetaStep.rejected error => PsKernelAlgProjectInferStep.rejected error
          | PsKernelAlgProjectMetaStep.ready info =>
              match info with
              | PsKernelAlgProjectInfo.info unusedConstructor parameters unusedFields field => psKernelAlgProjectInferNext env family index
                  (PsKernelAlgProjectInferTask.arity arguments arguments parameters field)
      | PsKernelAlgProjectInferTask.arity arguments pending remaining field =>
          match remaining with
          | PsKernelNatural.zero =>
              match pending with
              | PsKernelList.nil => psKernelAlgProjectInferNext env family index
                  (PsKernelAlgProjectInferTask.instantiate (psKernelParameterStart arguments field))
              | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.typeMismatch
          | _ =>
              match pending with
              | PsKernelList.cons unused rest => psKernelAlgProjectInferNext env family index
                  (PsKernelAlgProjectInferTask.arity arguments rest (psKernelNaturalPred remaining) field)
              | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.typeMismatch
      | PsKernelAlgProjectInferTask.instantiate current =>
          match psKernelParameterStep current with
          | PsKernelParameterStep.next next => psKernelAlgProjectInferNext env family index (PsKernelAlgProjectInferTask.instantiate next)
          | PsKernelParameterStep.final result =>
              match result with
              | PsKernelParameterResult.done type => PsKernelAlgProjectInferStep.done type
              | PsKernelParameterResult.invalidScope => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.invalidScope
              | _ => PsKernelAlgProjectInferStep.rejected PsKernelCheckError.invalidState

def psKernelAlgProjectInferStart (env : PsKernelList PsKernelDefinition) (family : PsKernelName)
    (index : PsKernelNatural) (majorType : PsKernelExpr) : PsKernelAlgProjectInferState :=
  PsKernelAlgProjectInferState.state env family index (PsKernelAlgProjectInferTask.spine majorType PsKernelList.nil)
