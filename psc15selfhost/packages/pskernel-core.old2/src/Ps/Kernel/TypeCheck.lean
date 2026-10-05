import Ps.Kernel.BuiltinNat
import Ps.Kernel.BuiltinText
import Ps.Kernel.ExprInstantiate
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
  | text (state : PsKernelTextCheckState)
  | natural (state : PsKernelBuiltinNatState)
  | infer (context : PsKernelList PsKernelExpr) (value : PsKernelExpr)
  | levels (pending : PsKernelList PsKernelLevel)
  | levelName (name : PsKernelName) (remaining : PsKernelList PsKernelName) (pending : PsKernelList PsKernelLevel)
  | levelNameCompare (name : PsKernelName) (remaining : PsKernelList PsKernelName)
      (pending : PsKernelList PsKernelLevel) (work : PsKernelList PsKernelOrderTask)
  | parameterArguments (remaining : PsKernelList PsKernelName) (reversed : PsKernelList PsKernelLevel)
      (value : PsKernelExpr) (type : PsKernelExpr)
  | parameters (state : PsKernelLevelInstantiateState) (value : PsKernelExpr) (type : PsKernelExpr)
  | instantiate (state : PsKernelExprInstantiateState)
  | bound (context : PsKernelList PsKernelExpr) (index : PsKernelNatural) (shift : PsKernelNatural)
  | lookup (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | binding (state : PsKernelBindingState)
  | reduce (state : PsKernelReduceState)
  | reduceTop
  | projectType (family : PsKernelName) (index : PsKernelNatural)
  | projectName (family : PsKernelName) (index : PsKernelNatural) (work : PsKernelList PsKernelOrderTask)
  | projectLookup (index : PsKernelNatural) (state : PsKernelLookupState)
  | projectField (index : PsKernelNatural) (fields : PsKernelList PsKernelExpr)
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
  | state (environment : PsKernelTypingContext)
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
    (env : PsKernelTypingContext) (tasks : PsKernelList PsKernelTypeTask)
    (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  PsKernelTypeStep.next (PsKernelTypeState.state env tasks values)

def psKernelTypePush
    (env : PsKernelTypingContext) (tasks : PsKernelList PsKernelTypeTask)
    (values : PsKernelList PsKernelExpr) (value : PsKernelExpr) : PsKernelTypeStep :=
  psKernelTypeNext env tasks (PsKernelList.cons value values)

def psKernelTypeInfer
    (env : PsKernelTypingContext) (context : PsKernelList PsKernelExpr)
    (value : PsKernelExpr) (tasks : PsKernelList PsKernelTypeTask)
    (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  match value with
  | PsKernelExpr.sortE level =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons level PsKernelList.nil))
        (PsKernelList.cons (PsKernelTypeTask.returnE (PsKernelExpr.sortE (PsKernelLevel.succ level))) tasks)) values
  | PsKernelExpr.bvar index =>
      psKernelTypeNext env (PsKernelList.cons
        (PsKernelTypeTask.bound context index (psKernelNaturalSucc index)) tasks) values
  | PsKernelExpr.fvar unused => psKernelTypeReject PsKernelCheckError.invalidScope
  | PsKernelExpr.constE name levels =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levels levels)
        (PsKernelList.cons (PsKernelTypeTask.lookup levels (PsKernelLookupState.search name (psKernelTypingDeclarations env))) tasks)) values
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.natural unused => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.natural (psKernelBuiltinNatStart (psKernelTypingDeclarations env))) tasks) values
      | PsKernelLiteral.text text => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.text (psKernelTextCheckStart (psKernelTypingDeclarations env) text)) tasks) values
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
  | PsKernelExpr.proj family index major =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context major)
        (PsKernelList.cons PsKernelTypeTask.reduceTop
          (PsKernelList.cons (PsKernelTypeTask.projectType family index) tasks))) values
  | PsKernelExpr.letE unusedName type val body =>
      psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context type)
        (PsKernelList.cons PsKernelTypeTask.reduceTop
          (PsKernelList.cons (PsKernelTypeTask.letSort context type val body) tasks))) values

def psKernelTypeValueTask
    (env : PsKernelTypingContext) (task : PsKernelTypeTask)
    (tasks : PsKernelList PsKernelTypeTask) (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  match values with
  | PsKernelList.nil => psKernelTypeReject PsKernelCheckError.invalidState
  | PsKernelList.cons top rest =>
      match task with
      | PsKernelTypeTask.reduceTop =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.reduce (psKernelWhnfStart (psKernelTypingDeclarations env) top)) tasks) rest
      | PsKernelTypeTask.projectType family index =>
          match top with
          | PsKernelExpr.constE majorFamily levels =>
              match levels with
              | PsKernelList.nil => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.projectName family index
                    (PsKernelList.cons (PsKernelOrderTask.name family majorFamily) PsKernelList.nil)) tasks) rest
              | _ => psKernelTypeReject PsKernelCheckError.unsupported
          | _ => psKernelTypeReject PsKernelCheckError.typeMismatch
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
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion (psKernelConversionStart (psKernelTypingDeclarations env) top domain))
            (PsKernelList.cons (PsKernelTypeTask.binding (psKernelBindingStart
              (PsKernelBindingMode.instantiate arg) PsKernelNatural.zero body)) tasks)) rest
      | PsKernelTypeTask.letSort context type value body =>
          match top with
          | PsKernelExpr.sortE unusedLevel =>
              psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.infer context value)
                (PsKernelList.cons (PsKernelTypeTask.letValue context type value body) tasks)) rest
          | _ => psKernelTypeReject PsKernelCheckError.typeExpected
      | PsKernelTypeTask.letValue context type value body =>
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion (psKernelConversionStart (psKernelTypingDeclarations env) top type))
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
          psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.conversion (psKernelConversionStart (psKernelTypingDeclarations env) top type))
            (PsKernelList.cons (PsKernelTypeTask.returnE type) tasks)) rest
      | _ => psKernelTypeReject PsKernelCheckError.invalidState

def psKernelTypeLevels
    (env : PsKernelTypingContext) (pending : PsKernelList PsKernelLevel)
    (tasks : PsKernelList PsKernelTypeTask) (values : PsKernelList PsKernelExpr) : PsKernelTypeStep :=
  match pending with
  | PsKernelList.nil => psKernelTypeNext env tasks values
  | PsKernelList.cons level rest =>
      match level with
      | PsKernelLevel.zero => psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levels rest) tasks) values
      | PsKernelLevel.succ next => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons next rest)) tasks) values
      | PsKernelLevel.max left right => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons left (PsKernelList.cons right rest))) tasks) values
      | PsKernelLevel.imax left right => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levels (PsKernelList.cons left (PsKernelList.cons right rest))) tasks) values
      | PsKernelLevel.param name => psKernelTypeNext env
          (PsKernelList.cons (PsKernelTypeTask.levelName name (psKernelTypingParameters env) rest) tasks) values

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
          | PsKernelTypeTask.projectName family index work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.projectName family index next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelTypeNext env
                      (PsKernelList.cons (PsKernelTypeTask.projectLookup index
                        (PsKernelLookupState.search family (psKernelTypingDeclarations env))) rest) values
                  | _ => psKernelTypeReject PsKernelCheckError.typeMismatch
              | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | PsKernelTypeTask.projectLookup index current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.projectLookup index next) rest) values
              | PsKernelLookupStep.found entry =>
                  match entry with
                  | PsKernelDefinition.recordFamily unusedName unusedCtor fields => psKernelTypeNext env
                      (PsKernelList.cons (PsKernelTypeTask.projectField index fields) rest) values
                  | _ => psKernelTypeReject PsKernelCheckError.unsupported
              | PsKernelLookupStep.missing => psKernelTypeReject PsKernelCheckError.unknownConstant
              | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | PsKernelTypeTask.projectField index fields =>
              match fields with
              | PsKernelList.nil => psKernelTypeReject PsKernelCheckError.typeMismatch
              | PsKernelList.cons field tail =>
                  match index with
                  | PsKernelNatural.zero => psKernelTypePush env rest values field
                  | _ => psKernelTypeNext env
                      (PsKernelList.cons (PsKernelTypeTask.projectField (psKernelNaturalPred index) tail) rest) values
          | PsKernelTypeTask.text current =>
              match psKernelTextCheckStep current with
              | PsKernelTextCheckStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.text next) rest) values
              | PsKernelTextCheckStep.ready => psKernelTypePush env rest values
                  (PsKernelExpr.constE psKernelBuiltinStringName PsKernelList.nil)
              | PsKernelTextCheckStep.rejected error => psKernelTypeReject error
          | PsKernelTypeTask.natural current =>
              match psKernelBuiltinNatStep current with
              | PsKernelBuiltinNatStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.natural next) rest) values
              | PsKernelBuiltinNatStep.ready => psKernelTypePush env rest values (PsKernelExpr.constE psKernelBuiltinNatName PsKernelList.nil)
              | PsKernelBuiltinNatStep.rejected error => psKernelTypeReject error
          | PsKernelTypeTask.infer context value => psKernelTypeInfer env context value rest values
          | PsKernelTypeTask.levels pending => psKernelTypeLevels env pending rest values
          | PsKernelTypeTask.levelName name remaining pending =>
              match remaining with
              | PsKernelList.nil => psKernelTypeReject PsKernelCheckError.invalidUniverse
              | PsKernelList.cons candidate tail => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.levelNameCompare name tail pending
                    (PsKernelList.cons (PsKernelOrderTask.name name candidate) PsKernelList.nil)) rest) values
          | PsKernelTypeTask.levelNameCompare name remaining pending work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.levelNameCompare name remaining pending next) rest) values
              | PsKernelOrderStep.invalidState => psKernelTypeReject PsKernelCheckError.invalidState
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levels pending) rest) values
                  | _ => psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.levelName name remaining pending) rest) values
          | PsKernelTypeTask.parameterArguments remaining reversed value type =>
              match remaining with
              | PsKernelList.nil => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.parameters
                    (psKernelLevelInstantiateStart (psKernelTypingParameters env) reversed PsKernelLevel.zero) value type) rest) values
              | PsKernelList.cons unusedName tail => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.parameterArguments tail (PsKernelList.cons PsKernelLevel.zero reversed) value type) rest) values
          | PsKernelTypeTask.parameters current value type =>
              match psKernelLevelInstantiateStep current with
              | PsKernelLevelInstantiateStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.parameters next value type) rest) values
              | PsKernelLevelInstantiateStep.final result =>
                  match result with
                  | PsKernelLevelInstantiateResult.done unused => psKernelTypeNext env
                      (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil type)
                        (PsKernelList.cons PsKernelTypeTask.reduceTop (PsKernelList.cons (PsKernelTypeTask.checkSort value type) rest))) values
                  | PsKernelLevelInstantiateResult.invalidParameters => psKernelTypeReject PsKernelCheckError.invalidUniverse
                  | _ => psKernelTypeReject PsKernelCheckError.invalidState
          | PsKernelTypeTask.instantiate current =>
              match psKernelExprInstantiateStep current with
              | PsKernelExprInstantiateStep.next next => psKernelTypeNext env
                  (PsKernelList.cons (PsKernelTypeTask.instantiate next) rest) values
              | PsKernelExprInstantiateStep.final result =>
                  match result with
                  | PsKernelExprInstantiateResult.done value => psKernelTypePush env rest values value
                  | PsKernelExprInstantiateResult.invalidParameters => psKernelTypeReject PsKernelCheckError.invalidUniverse
                  | PsKernelExprInstantiateResult.undeclaredParameter => psKernelTypeReject PsKernelCheckError.invalidUniverse
                  | _ => psKernelTypeReject PsKernelCheckError.invalidState
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
          | PsKernelTypeTask.lookup levels current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next =>
                  psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.lookup levels next) rest) values
              | PsKernelLookupStep.missing => psKernelTypeReject PsKernelCheckError.unknownConstant
              | PsKernelLookupStep.invalidState => psKernelTypeReject PsKernelCheckError.invalidState
              | PsKernelLookupStep.found entry =>
                  psKernelTypeNext env (PsKernelList.cons (PsKernelTypeTask.instantiate
                    (psKernelExprInstantiateStart (psKernelDefinitionParameters entry) levels (psKernelDefinitionType entry))) rest) values
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
  PsKernelTypeState.state (PsKernelTypingContext.context env PsKernelList.nil) (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil value) PsKernelList.nil) PsKernelList.nil

def psKernelCheckWithParametersStart
    (env : PsKernelList PsKernelDefinition) (parameters : PsKernelList PsKernelName)
    (value type : PsKernelExpr) : PsKernelTypeState :=
  PsKernelTypeState.state (PsKernelTypingContext.context env parameters)
    (PsKernelList.cons (PsKernelTypeTask.parameterArguments parameters PsKernelList.nil value type) PsKernelList.nil) PsKernelList.nil

def psKernelCheckStart
    (env : PsKernelList PsKernelDefinition) (value type : PsKernelExpr) : PsKernelTypeState :=
  psKernelCheckWithParametersStart env PsKernelList.nil value type

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
