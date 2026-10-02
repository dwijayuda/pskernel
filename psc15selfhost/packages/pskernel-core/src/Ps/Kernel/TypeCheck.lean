import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Natural
import Ps.Kernel.Binding
import Ps.Kernel.Environment
import Ps.Kernel.Reduction
import Ps.Kernel.Conversion

/- Internal dependent-function fragment. Context entries store binder types in
that binder's OUTER context; lookup lifts by index+1 into the current context.
No self-inference shortcut and no acceptance Boolean supplied by the caller.
Raw machine states are implementation data, not a checked-module capability. -/
inductive PsKernelTypeTask where
  | infer (context : PsKernelList PsKernelExpr) (value : PsKernelExpr)
  | levels (pending : PsKernelList PsKernelLevel) (result : PsKernelExpr)
  | bound (context : PsKernelList PsKernelExpr) (index : PsKernelNatural) (shift : PsKernelNatural)
  | lookup (state : PsKernelLookupState)
  | binding (state : PsKernelBindingState)
  | reduce (state : PsKernelReduceState)
  | reduceTop
  | conversion (state : PsKernelConversionState)
  | returnE (value : PsKernelExpr)
  | lamSort (context : PsKernelList PsKernelExpr) (name : PsKernelName)
      (type : PsKernelExpr) (body : PsKernelExpr) (binder : PsKernelBinder)
  | lamFinish (name : PsKernelName) (type : PsKernelExpr) (binder : PsKernelBinder)
  | piDomain (context : PsKernelList PsKernelExpr) (type : PsKernelExpr) (body : PsKernelExpr)
  | piFinish (domainLevel : PsKernelLevel)
  | appPi (context : PsKernelList PsKernelExpr) (arg : PsKernelExpr)
  | appArgument (domain : PsKernelExpr) (body : PsKernelExpr) (arg : PsKernelExpr)
  | letSort (context : PsKernelList PsKernelExpr) (type : PsKernelExpr) (value : PsKernelExpr) (body : PsKernelExpr)
  | letValue (context : PsKernelList PsKernelExpr) (type : PsKernelExpr) (value : PsKernelExpr) (body : PsKernelExpr)
  | letBody (context : PsKernelList PsKernelExpr)
  | checkSort (value : PsKernelExpr) (type : PsKernelExpr)
  | checkValue (type : PsKernelExpr)

inductive PsKernelTypeState where
  | state (environment : PsKernelList PsKernelDefinition)
      (tasks : PsKernelList PsKernelTypeTask) (values : PsKernelList PsKernelExpr)

inductive PsKernelTypeResult where
  | outOfFuel
  | rejected (error : PsKernelCheckError)
  | done (type : PsKernelExpr)

inductive PsKernelTypeStep where
  | next (state : PsKernelTypeState)
  | final (result : PsKernelTypeResult)

def psKernelTypeReject (error : PsKernelCheckError) : PsKernelTypeStep :=
  PsKernelTypeStep.final (PsKernelTypeResult.rejected error)

def psKernelTypeNext
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelTypeTask)
    (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  PsKernelTypeStep.next (PsKernelTypeState.state env tasks values)

def psKernelTypePush
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelTypeTask)
    (values : PsKernelList PsKernelExpr) (value : PsKernelExpr) : PsKernelTypeStep :=
  psKernelTypeNext env tasks (PsKernelList.cons value values)

def psKernelTypeInfer
    (env : PsKernelList PsKernelDefinition) (context : PsKernelList PsKernelExpr)
    (value : PsKernelExpr) (tasks : PsKernelList PsKernelTypeTask)
    (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  match value with
  | PsKernelExpr.sortE level =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levels
        (PsKernelList.cons level PsKernelList.nil) (PsKernelExpr.sortE (PsKernelLevel.succ level))) tasks) values
  | PsKernelExpr.bvar index =>
      psKernelTypeNext env (PsKernelList.cons
        (PsKernelTypeTask.bound context index (psKernelNaturalSucc index)) tasks) values
  | PsKernelExpr.fvar unused => psKernelTypeReject PsKernelCheckError.invalidScope
  | PsKernelExpr.constE name levels =>
      match levels with
      | PsKernelList.nil => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.lookup (PsKernelLookupState.search name env)) tasks) values
      | _ => psKernelTypeReject PsKernelCheckError.unsupported
  | PsKernelExpr.lam name type body binder =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context type)
        (PsKernelList.cons PsKernelTypeTask.reduceTop
          (PsKernelList.cons (PsKernelTypeTask.lamSort context name type body binder) tasks))) values
  | PsKernelExpr.forallE unusedName type body unusedBinder =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context type)
        (PsKernelList.cons PsKernelTypeTask.reduceTop
          (PsKernelList.cons (PsKernelTypeTask.piDomain context type body) tasks))) values
  | PsKernelExpr.app fn arg =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context fn)
        (PsKernelList.cons PsKernelTypeTask.reduceTop
          (PsKernelList.cons (PsKernelTypeTask.appPi context arg) tasks))) values
  | PsKernelExpr.letE unusedName type val body =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context type)
        (PsKernelList.cons PsKernelTypeTask.reduceTop
          (PsKernelList.cons (PsKernelTypeTask.letSort context type val body) tasks))) values
  | _ => psKernelTypeReject PsKernelCheckError.unsupported

def psKernelTypeValueTask
    (env : PsKernelList PsKernelDefinition) (task : PsKernelTypeTask)
    (tasks : PsKernelList PsKernelTypeTask) (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  match values with
  | PsKernelList.nil => psKernelTypeReject PsKernelCheckError.invalidState
  | PsKernelList.cons top rest =>
      match task with
      | PsKernelTypeTask.reduceTop =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.reduce (psKernelWhnfStart env top)) tasks) rest
      | PsKernelTypeTask.lamSort context name type body binder =>
          match top with
          | PsKernelExpr.sortE unusedLevel =>
              psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer (PsKernelList.cons type context) body)
                (PsKernelList.cons (PsKernelTypeTask.lamFinish name type binder) tasks)) rest
          | _ => psKernelTypeReject PsKernelCheckError.typeExpected
      | PsKernelTypeTask.lamFinish name type binder =>
          psKernelTypePush env tasks rest (PsKernelExpr.forallE name type top binder)
      | PsKernelTypeTask.piDomain context type body =>
          match top with
          | PsKernelExpr.sortE level =>
              psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer (PsKernelList.cons type context) body)
                (PsKernelList.cons PsKernelTypeTask.reduceTop
                  (PsKernelList.cons (PsKernelTypeTask.piFinish level) tasks))) rest
          | _ => psKernelTypeReject PsKernelCheckError.typeExpected
      | PsKernelTypeTask.piFinish domainLevel =>
          match top with
          | PsKernelExpr.sortE bodyLevel =>
              psKernelTypePush env tasks rest (PsKernelExpr.sortE (PsKernelLevel.imax domainLevel bodyLevel))
          | _ => psKernelTypeReject PsKernelCheckError.typeExpected
      | PsKernelTypeTask.appPi context arg =>
          match top with
          | PsKernelExpr.forallE unusedName domain body unusedBinder =>
              psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context arg)
                (PsKernelList.cons (PsKernelTypeTask.appArgument domain body arg) tasks)) rest
          | _ => psKernelTypeReject PsKernelCheckError.functionExpected
      | PsKernelTypeTask.appArgument domain body arg =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion (psKernelConversionStart env top domain))
            (PsKernelList.cons (PsKernelTypeTask.binding (psKernelBindingStart
              (PsKernelBindingMode.instantiate arg) PsKernelNatural.zero body)) tasks)) rest
      | PsKernelTypeTask.letSort context type value body =>
          match top with
          | PsKernelExpr.sortE unusedLevel =>
              psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context value)
                (PsKernelList.cons (PsKernelTypeTask.letValue context type value body) tasks)) rest
          | _ => psKernelTypeReject PsKernelCheckError.typeExpected
      | PsKernelTypeTask.letValue context type value body =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion (psKernelConversionStart env top type))
            (PsKernelList.cons (PsKernelTypeTask.binding (psKernelBindingStart
              (PsKernelBindingMode.instantiate value) PsKernelNatural.zero body))
              (PsKernelList.cons (PsKernelTypeTask.letBody context) tasks))) rest
      | PsKernelTypeTask.letBody context =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context top) tasks) rest
      | PsKernelTypeTask.checkSort value type =>
          match top with
          | PsKernelExpr.sortE unusedLevel =>
              psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil value)
                (PsKernelList.cons (PsKernelTypeTask.checkValue type) tasks)) rest
          | _ => psKernelTypeReject PsKernelCheckError.typeExpected
      | PsKernelTypeTask.checkValue type =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion (psKernelConversionStart env top type))
            (PsKernelList.cons (PsKernelTypeTask.returnE type) tasks)) rest
      | _ => psKernelTypeReject PsKernelCheckError.invalidState

def psKernelTypeLevels
    (env : PsKernelList PsKernelDefinition) (pending : PsKernelList PsKernelLevel) (result : PsKernelExpr)
    (tasks : PsKernelList PsKernelTypeTask) (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  match pending with
  | PsKernelList.nil => psKernelTypePush env tasks values result
  | PsKernelList.cons level rest =>
      match level with
      | PsKernelLevel.zero => psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levels rest result) tasks) values
      | PsKernelLevel.succ next => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons next rest) result) tasks) values
      | PsKernelLevel.max left right => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons left (PsKernelList.cons right rest)) result) tasks) values
      | PsKernelLevel.imax left right => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons left (PsKernelList.cons right rest)) result) tasks) values
      | PsKernelLevel.param unusedName => psKernelTypeReject PsKernelCheckError.unsupported

def psKernelTypeStep (state : PsKernelTypeState) : PsKernelTypeStep :=
  match state with
  | PsKernelTypeState.state env tasks values =>
      match tasks with
      | PsKernelList.nil =>
          match values with
          | PsKernelList.cons type rest =>
              match rest with
              | PsKernelList.nil => PsKernelTypeStep.final (PsKernelTypeResult.done type)
              | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | _ => psKernelTypeReject PsKernelCheckError.invalidState
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelTypeTask.infer context value => psKernelTypeInfer env context value rest values
          | PsKernelTypeTask.levels pending result => psKernelTypeLevels env pending result rest values
          | PsKernelTypeTask.returnE value => psKernelTypePush env rest values value
          | PsKernelTypeTask.bound context index shift =>
              match context with
              | PsKernelList.nil => psKernelTypeReject PsKernelCheckError.invalidScope
              | PsKernelList.cons type tail =>
                  match index with
                  | PsKernelNatural.zero =>
                      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.binding
                        (psKernelBindingStart (PsKernelBindingMode.lift shift) PsKernelNatural.zero type)) rest) values
                  | _ => psKernelTypeNext env
                      (PsKernelList.cons (PsKernelTypeTask.bound tail (psKernelNaturalPred index) shift) rest) values
          | PsKernelTypeTask.lookup current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next =>
                  psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.lookup next) rest) values
              | PsKernelLookupStep.missing => psKernelTypeReject PsKernelCheckError.unknownConstant
              | PsKernelLookupStep.invalidState => psKernelTypeReject PsKernelCheckError.invalidState
              | PsKernelLookupStep.found entry =>
                  match entry with
                  | PsKernelDefinition.definition unusedName type unusedValue => psKernelTypePush env rest values type
          | PsKernelTypeTask.binding current =>
              match psKernelBindingStep current with
              | PsKernelBindingStep.next next =>
                  psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.binding next) rest) values
              | PsKernelBindingStep.final result =>
                  match result with
                  | PsKernelBindingResult.done value => psKernelTypePush env rest values value
                  | PsKernelBindingResult.invalidScope => psKernelTypeReject PsKernelCheckError.invalidScope
                  | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | PsKernelTypeTask.reduce current =>
              match psKernelReduceStep current with
              | PsKernelReduceStep.next next =>
                  psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.reduce next) rest) values
              | PsKernelReduceStep.final result =>
                  match result with
                  | PsKernelReduceResult.done value => psKernelTypePush env rest values value
                  | PsKernelReduceResult.rejected error => psKernelTypeReject error
                  | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | PsKernelTypeTask.conversion current =>
              match psKernelConversionStep current with
              | PsKernelConversionStep.next next =>
                  psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion next) rest) values
              | PsKernelConversionStep.final result =>
                  match result with
                  | PsKernelConversionResult.equal => psKernelTypeNext env rest values
                  | PsKernelConversionResult.different => psKernelTypeReject PsKernelCheckError.typeMismatch
                  | PsKernelConversionResult.rejected error => psKernelTypeReject error
                  | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | _ => psKernelTypeValueTask env task rest values

def psKernelInferStart
    (env : PsKernelList PsKernelDefinition) (value : PsKernelExpr) : PsKernelTypeState :=
  PsKernelTypeState.state env (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil value) PsKernelList.nil) PsKernelList.nil

def psKernelCheckStart
    (env : PsKernelList PsKernelDefinition) (value type : PsKernelExpr) : PsKernelTypeState :=
  PsKernelTypeState.state env (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil type)
    (PsKernelList.cons PsKernelTypeTask.reduceTop
      (PsKernelList.cons (PsKernelTypeTask.checkSort value type) PsKernelList.nil))) PsKernelList.nil

def psKernelTypeRun (fuel : PsKernelFuel) : PsKernelTypeState -> PsKernelTypeResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelTypeState) => PsKernelTypeResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelTypeState) =>
        match psKernelTypeStep state with
        | PsKernelTypeStep.final result => result
        | PsKernelTypeStep.next next =>
            let smaller : PsKernelTypeState -> PsKernelTypeResult := psKernelTypeRun remaining;
            smaller next
