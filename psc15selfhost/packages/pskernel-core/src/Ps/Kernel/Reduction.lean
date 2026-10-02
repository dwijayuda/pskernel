import Ps.Kernel.ExprInstantiate
import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Binding
import Ps.Kernel.Environment

/- First-order beta/zeta/delta reducer. No primitive, quotient or recursor
reduction is asserted. Type checking, not reduction, validates discarded terms.
All nested substitutions and lookups consume the caller's transition budget. -/
inductive PsKernelReduceTask where
  | whnf (value : PsKernelExpr)
  | apply (arg : PsKernelExpr)
  | lookup (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | opaqueConstant (value : PsKernelExpr) (state : PsKernelLevelInstantiateState)
  | instantiate (state : PsKernelExprInstantiateState)
  | binding (state : PsKernelBindingState)
  | resumeWhnf
  | normal (value : PsKernelExpr)
  | expand
  | app
  | lam (name : PsKernelName) (binder : PsKernelBinder)
  | forallE (name : PsKernelName) (binder : PsKernelBinder)

inductive PsKernelReduceState where
  | state (environment : PsKernelList PsKernelDefinition)
      (tasks : PsKernelList PsKernelReduceTask) (values : PsKernelList PsKernelExpr)

inductive PsKernelReduceResult where
  | outOfFuel
  | rejected (error : PsKernelCheckError)
  | done (value : PsKernelExpr)

inductive PsKernelReduceStep where
  | next (state : PsKernelReduceState)
  | final (result : PsKernelReduceResult)

def psKernelReduceReject (error : PsKernelCheckError) : PsKernelReduceStep :=
  PsKernelReduceStep.final (PsKernelReduceResult.rejected error)

def psKernelReduceNext
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelReduceTask)
    (values : PsKernelList PsKernelExpr) : PsKernelReduceStep :=
  PsKernelReduceStep.next (PsKernelReduceState.state env tasks values)

def psKernelReducePush
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelReduceTask)
    (values : PsKernelList PsKernelExpr) (value : PsKernelExpr) : PsKernelReduceStep :=
  psKernelReduceNext env tasks (PsKernelList.cons value values)

def psKernelReduceWhnf
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelReduceTask)
    (values : PsKernelList PsKernelExpr) (value : PsKernelExpr) : PsKernelReduceStep :=
  match value with
  | PsKernelExpr.app fn arg =>
      psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf fn)
        (PsKernelList.cons (PsKernelReduceTask.apply arg) tasks)) values
  | PsKernelExpr.letE unusedName unusedType val body =>
      psKernelReduceNext env
        (PsKernelList.cons (PsKernelReduceTask.binding (psKernelBindingStart
          (PsKernelBindingMode.instantiate val) PsKernelNatural.zero body))
          (PsKernelList.cons PsKernelReduceTask.resumeWhnf tasks)) values
  | PsKernelExpr.constE name levels =>
      psKernelReduceNext env
        (PsKernelList.cons (PsKernelReduceTask.lookup levels (PsKernelLookupState.search name env)) tasks) values
  | PsKernelExpr.fvar unused => psKernelReduceReject PsKernelCheckError.invalidScope
  | PsKernelExpr.lit unused => psKernelReduceReject PsKernelCheckError.unsupported
  | PsKernelExpr.proj unusedName unusedIndex unusedValue => psKernelReduceReject PsKernelCheckError.unsupported
  | _ => psKernelReducePush env tasks values value

def psKernelReduceValueTask
    (env : PsKernelList PsKernelDefinition) (task : PsKernelReduceTask)
    (tasks : PsKernelList PsKernelReduceTask) (values : PsKernelList PsKernelExpr) : PsKernelReduceStep :=
  match values with
  | PsKernelList.nil => psKernelReduceReject PsKernelCheckError.invalidState
  | PsKernelList.cons top rest =>
      match task with
      | PsKernelReduceTask.resumeWhnf =>
          psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf top) tasks) rest
      | PsKernelReduceTask.apply arg =>
          match top with
          | PsKernelExpr.lam unusedName unusedType body unusedBinder =>
              psKernelReduceNext env
                (PsKernelList.cons (PsKernelReduceTask.binding (psKernelBindingStart
                  (PsKernelBindingMode.instantiate arg) PsKernelNatural.zero body))
                  (PsKernelList.cons PsKernelReduceTask.resumeWhnf tasks)) rest
          | _ => psKernelReducePush env tasks rest (PsKernelExpr.app top arg)
      | PsKernelReduceTask.expand =>
          match top with
          | PsKernelExpr.app fn arg =>
              psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.normal fn)
                (PsKernelList.cons (PsKernelReduceTask.normal arg)
                  (PsKernelList.cons PsKernelReduceTask.app tasks))) rest
          | PsKernelExpr.lam name type body binder =>
              psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.normal type)
                (PsKernelList.cons (PsKernelReduceTask.normal body)
                  (PsKernelList.cons (PsKernelReduceTask.lam name binder) tasks))) rest
          | PsKernelExpr.forallE name type body binder =>
              psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.normal type)
                (PsKernelList.cons (PsKernelReduceTask.normal body)
                  (PsKernelList.cons (PsKernelReduceTask.forallE name binder) tasks))) rest
          | _ => psKernelReducePush env tasks rest top
      | PsKernelReduceTask.app =>
          match rest with
          | PsKernelList.cons fn tail => psKernelReducePush env tasks tail (PsKernelExpr.app fn top)
          | _ => psKernelReduceReject PsKernelCheckError.invalidState
      | PsKernelReduceTask.lam name binder =>
          match rest with
          | PsKernelList.cons type tail => psKernelReducePush env tasks tail (PsKernelExpr.lam name type top binder)
          | _ => psKernelReduceReject PsKernelCheckError.invalidState
      | PsKernelReduceTask.forallE name binder =>
          match rest with
          | PsKernelList.cons type tail => psKernelReducePush env tasks tail (PsKernelExpr.forallE name type top binder)
          | _ => psKernelReduceReject PsKernelCheckError.invalidState
      | _ => psKernelReduceReject PsKernelCheckError.invalidState

def psKernelReduceStep (state : PsKernelReduceState) : PsKernelReduceStep :=
  match state with
  | PsKernelReduceState.state env tasks values =>
      match tasks with
      | PsKernelList.nil =>
          match values with
          | PsKernelList.cons value rest =>
              match rest with
              | PsKernelList.nil => PsKernelReduceStep.final (PsKernelReduceResult.done value)
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | _ => psKernelReduceReject PsKernelCheckError.invalidState
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelReduceTask.whnf value => psKernelReduceWhnf env rest values value
          | PsKernelReduceTask.normal value =>
              psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf value)
                (PsKernelList.cons PsKernelReduceTask.expand rest)) values
          | PsKernelReduceTask.lookup levels current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next =>
                  psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.lookup levels next) rest) values
              | PsKernelLookupStep.missing => psKernelReduceReject PsKernelCheckError.unknownConstant
              | PsKernelLookupStep.invalidState => psKernelReduceReject PsKernelCheckError.invalidState
              | PsKernelLookupStep.found entry =>
                  match psKernelDefinitionBody entry with
                  | PsKernelDefinitionBody.transparent value => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.instantiate
                        (psKernelExprInstantiateStart (psKernelDefinitionParameters entry) levels value))
                        (PsKernelList.cons PsKernelReduceTask.resumeWhnf rest)) values
                  | PsKernelDefinitionBody.opaque => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.opaqueConstant
                        (PsKernelExpr.constE (psKernelDefinitionName entry) levels)
                        (psKernelLevelInstantiateStart (psKernelDefinitionParameters entry) levels PsKernelLevel.zero)) rest) values
          | PsKernelReduceTask.opaqueConstant value current =>
              match psKernelLevelInstantiateStep current with
              | PsKernelLevelInstantiateStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.opaqueConstant value next) rest) values
              | PsKernelLevelInstantiateStep.final result =>
                  match result with
                  | PsKernelLevelInstantiateResult.done unused => psKernelReducePush env rest values value
                  | PsKernelLevelInstantiateResult.invalidParameters => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.instantiate current =>
              match psKernelExprInstantiateStep current with
              | PsKernelExprInstantiateStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.instantiate next) rest) values
              | PsKernelExprInstantiateStep.final result =>
                  match result with
                  | PsKernelExprInstantiateResult.done value => psKernelReducePush env rest values value
                  | PsKernelExprInstantiateResult.invalidParameters => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | PsKernelExprInstantiateResult.undeclaredParameter => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.binding current =>
              match psKernelBindingStep current with
              | PsKernelBindingStep.next next =>
                  psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.binding next) rest) values
              | PsKernelBindingStep.final result =>
                  match result with
                  | PsKernelBindingResult.done value => psKernelReducePush env rest values value
                  | PsKernelBindingResult.invalidScope => psKernelReduceReject PsKernelCheckError.invalidScope
                  | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | _ => psKernelReduceValueTask env task rest values

def psKernelWhnfStart
    (env : PsKernelList PsKernelDefinition) (value : PsKernelExpr) : PsKernelReduceState :=
  PsKernelReduceState.state env (PsKernelList.cons (PsKernelReduceTask.whnf value) PsKernelList.nil) PsKernelList.nil

def psKernelNormalStart
    (env : PsKernelList PsKernelDefinition) (value : PsKernelExpr) : PsKernelReduceState :=
  PsKernelReduceState.state env (PsKernelList.cons (PsKernelReduceTask.normal value) PsKernelList.nil) PsKernelList.nil

def psKernelReduceRun (fuel : PsKernelFuel) : PsKernelReduceState -> PsKernelReduceResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelReduceState) => PsKernelReduceResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelReduceState) =>
        match psKernelReduceStep state with
        | PsKernelReduceStep.final result => result
        | PsKernelReduceStep.next next =>
            let smaller : PsKernelReduceState -> PsKernelReduceResult := psKernelReduceRun remaining;
            smaller next
