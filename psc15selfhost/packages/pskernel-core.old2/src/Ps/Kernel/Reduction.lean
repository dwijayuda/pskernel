import Ps.Kernel.BuiltinNat
import Ps.Kernel.BuiltinText
import Ps.Kernel.LevelCheck
import Ps.Kernel.ExprInstantiate
import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Binding
import Ps.Kernel.Environment
import Ps.Kernel.AlgebraicReduction

/- First-order beta/zeta/delta and supported inductive recursor reduction.
No primitive or quotient reduction is asserted. Type checking validates discarded terms.
All nested substitutions and lookups consume the caller's transition budget. -/
/- Closed record metadata is installed only by RecordInductive admission.
The field types are closed: projection types need no contextual substitution.
Record elimination still traverses and validates the full constructor spine. -/
inductive PsKernelEnumBranch where
  | branch (name : PsKernelName) (minor : PsKernelExpr)

inductive PsKernelSumBranch where
  | branch (name : PsKernelName) (fields : PsKernelNatural) (minor : PsKernelExpr)

inductive PsKernelRecordAction where
  | project (family : PsKernelName) (index : PsKernelNatural)
  | eliminate (fn : PsKernelExpr) (minor : PsKernelExpr)

def psKernelRecordNeutral (action : PsKernelRecordAction) (major : PsKernelExpr) : PsKernelExpr :=
  match action with
  | PsKernelRecordAction.project family index => PsKernelExpr.proj family index major
  | PsKernelRecordAction.eliminate fn unusedMinor => PsKernelExpr.app fn major

inductive PsKernelReduceTask where
  | algebraic (state : PsKernelAlgReduceState)
  | algebraicMajor (continuation : PsKernelAlgReduceContinuation)
  | sumMinors (original : PsKernelExpr) (rules : PsKernelList PsKernelSumRule)
      (args : PsKernelList PsKernelExpr) (branches : PsKernelList PsKernelSumBranch)
  | sumMajor (fn : PsKernelExpr) (branches : PsKernelList PsKernelSumBranch)
  | sumSpine (fn major cursor : PsKernelExpr) (args : PsKernelList PsKernelExpr)
      (branches : PsKernelList PsKernelSumBranch)
  | sumFind (fn major : PsKernelExpr) (name : PsKernelName) (args : PsKernelList PsKernelExpr)
      (branches : PsKernelList PsKernelSumBranch)
  | sumName (fn major : PsKernelExpr) (name : PsKernelName) (args : PsKernelList PsKernelExpr)
      (fields : PsKernelNatural) (minor : PsKernelExpr)
      (remaining : PsKernelList PsKernelSumBranch) (work : PsKernelList PsKernelOrderTask)
  | sumFields (minor : PsKernelExpr) (args : PsKernelList PsKernelExpr) (remaining : PsKernelNatural)
  | enumSpine (original cursor : PsKernelExpr) (args : PsKernelList PsKernelExpr)
  | enumLookup (original : PsKernelExpr) (args : PsKernelList PsKernelExpr)
      (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | enumMinors (original : PsKernelExpr) (constructors : PsKernelList PsKernelName)
      (args : PsKernelList PsKernelExpr) (branches : PsKernelList PsKernelEnumBranch)
  | enumMajor (fn : PsKernelExpr) (branches : PsKernelList PsKernelEnumBranch)
  | enumFind (fn major : PsKernelExpr) (name : PsKernelName) (branches : PsKernelList PsKernelEnumBranch)
  | enumName (fn major : PsKernelExpr) (name : PsKernelName) (minor : PsKernelExpr)
      (remaining : PsKernelList PsKernelEnumBranch) (work : PsKernelList PsKernelOrderTask)
  | projectLookup (family : PsKernelName) (index : PsKernelNatural) (major : PsKernelExpr) (state : PsKernelLookupState)
  | projectBound (family : PsKernelName) (index : PsKernelNatural) (major : PsKernelExpr)
      (ctor : PsKernelName) (fields pending : PsKernelList PsKernelExpr) (cursor : PsKernelNatural)
  | recordMajor (action : PsKernelRecordAction) (ctor : PsKernelName) (fields : PsKernelList PsKernelExpr)
  | recordSpine (action : PsKernelRecordAction) (major cursor : PsKernelExpr)
      (ctor : PsKernelName) (fields args : PsKernelList PsKernelExpr)
  | recordName (action : PsKernelRecordAction) (major : PsKernelExpr)
      (fields args : PsKernelList PsKernelExpr) (work : PsKernelList PsKernelOrderTask)
  | recordArity (action : PsKernelRecordAction) (major : PsKernelExpr) (fields args original : PsKernelList PsKernelExpr)
  | recordSelect (index : PsKernelNatural) (args : PsKernelList PsKernelExpr)
  | recordApply (minor : PsKernelExpr) (args : PsKernelList PsKernelExpr)
  | proj (family : PsKernelName) (index : PsKernelNatural)
  | text (value : PsKernelText) (state : PsKernelTextCheckState)
  | natural (value : PsKernelNatural) (state : PsKernelBuiltinNatState)
  | whnf (value : PsKernelExpr)
  | apply (arg : PsKernelExpr)
  | lookup (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | unitLookup (fn : PsKernelExpr) (major : PsKernelExpr) (minor : PsKernelExpr)
      (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | unitMajor (fn : PsKernelExpr) (minor : PsKernelExpr) (ctorName : PsKernelName) (levels : PsKernelList PsKernelLevel)
  | unitName (fn : PsKernelExpr) (major : PsKernelExpr) (minor : PsKernelExpr)
      (left : PsKernelList PsKernelLevel) (right : PsKernelList PsKernelLevel) (work : PsKernelList PsKernelOrderTask)
  | unitLevels (fn : PsKernelExpr) (major : PsKernelExpr) (minor : PsKernelExpr)
      (left : PsKernelList PsKernelLevel) (right : PsKernelList PsKernelLevel)
  | unitLevel (fn : PsKernelExpr) (major : PsKernelExpr) (minor : PsKernelExpr)
      (left : PsKernelList PsKernelLevel) (right : PsKernelList PsKernelLevel) (state : PsKernelLevelCheckState)
  | natLookup (fn : PsKernelExpr) (major : PsKernelExpr) (zeroCase succCase : PsKernelExpr) (state : PsKernelLookupState)
  | natMajor (fn : PsKernelExpr) (zeroCase succCase : PsKernelExpr) (zeroName succName : PsKernelName)
  | natZeroName (fn major zeroCase : PsKernelExpr) (work : PsKernelList PsKernelOrderTask)
  | natSuccName (fn major succCase predecessor : PsKernelExpr) (work : PsKernelList PsKernelOrderTask)
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
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.natural number => psKernelReduceNext env
          (PsKernelList.cons (PsKernelReduceTask.natural number (psKernelBuiltinNatStart env)) tasks) values
      | PsKernelLiteral.text text => psKernelReduceNext env
          (PsKernelList.cons (PsKernelReduceTask.text text (psKernelTextCheckStart env text)) tasks) values
  | PsKernelExpr.proj family index major => psKernelReduceNext env
      (PsKernelList.cons (PsKernelReduceTask.projectLookup family index major (PsKernelLookupState.search family env)) tasks) values
  | _ => psKernelReducePush env tasks values value

def psKernelReduceEnumApply
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelReduceTask)
    (values : PsKernelList PsKernelExpr) (fn arg : PsKernelExpr) : PsKernelReduceStep :=
  let original : PsKernelExpr := PsKernelExpr.app fn arg;
  psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.enumSpine original original PsKernelList.nil) tasks) values

def psKernelReduceNeutralApply
    (env : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelReduceTask)
    (values : PsKernelList PsKernelExpr) (fn arg : PsKernelExpr) : PsKernelReduceStep :=
  match fn with
  | PsKernelExpr.app motiveApplication minor =>
      match motiveApplication with
      | PsKernelExpr.app head unusedMotive =>
          match head with
          | PsKernelExpr.constE name levels => psKernelReduceNext env
              (PsKernelList.cons (PsKernelReduceTask.unitLookup fn arg minor levels (PsKernelLookupState.search name env)) tasks) values
          | PsKernelExpr.app natHead unusedNatMotive =>
              match natHead with
              | PsKernelExpr.constE name unusedLevels => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.natLookup fn arg unusedMotive minor
                    (PsKernelLookupState.search name env)) tasks) values
              | _ => psKernelReduceEnumApply env tasks values fn arg
          | _ => psKernelReduceEnumApply env tasks values fn arg
      | _ => psKernelReduceEnumApply env tasks values fn arg
  | _ => psKernelReduceEnumApply env tasks values fn arg

def psKernelReduceValueTask
    (env : PsKernelList PsKernelDefinition) (task : PsKernelReduceTask)
    (tasks : PsKernelList PsKernelReduceTask) (values : PsKernelList PsKernelExpr) : PsKernelReduceStep :=
  match values with
  | PsKernelList.nil => psKernelReduceReject PsKernelCheckError.invalidState
  | PsKernelList.cons top rest =>
      match task with
      | PsKernelReduceTask.algebraicMajor continuation => psKernelReduceNext env
          (PsKernelList.cons (PsKernelReduceTask.algebraic (psKernelAlgReduceResume continuation top)) tasks) rest
      | PsKernelReduceTask.sumMajor fn branches => psKernelReduceNext env
          (PsKernelList.cons (PsKernelReduceTask.sumSpine fn top top PsKernelList.nil branches) tasks) rest
      | PsKernelReduceTask.enumMajor fn branches =>
          match top with
          | PsKernelExpr.constE name levels =>
              match levels with
              | PsKernelList.nil => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.enumFind fn top name branches) tasks) rest
              | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
          | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
      | PsKernelReduceTask.recordMajor action ctor fields => psKernelReduceNext env
          (PsKernelList.cons (PsKernelReduceTask.recordSpine action top top ctor fields PsKernelList.nil) tasks) rest
      | PsKernelReduceTask.proj family index => psKernelReducePush env tasks rest (PsKernelExpr.proj family index top)
      | PsKernelReduceTask.resumeWhnf =>
          psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf top) tasks) rest
      | PsKernelReduceTask.apply arg =>
          match top with
          | PsKernelExpr.lam unusedName unusedType body unusedBinder =>
              psKernelReduceNext env
                (PsKernelList.cons (PsKernelReduceTask.binding (psKernelBindingStart
                  (PsKernelBindingMode.instantiate arg) PsKernelNatural.zero body))
                  (PsKernelList.cons PsKernelReduceTask.resumeWhnf tasks)) rest
          | _ => psKernelReduceNeutralApply env tasks rest top arg
      | PsKernelReduceTask.natMajor fn zeroCase succCase zeroName succName =>
          match top with
          | PsKernelExpr.constE majorName majorLevels =>
              match majorLevels with
              | PsKernelList.nil => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.natZeroName fn top zeroCase
                    (PsKernelList.cons (PsKernelOrderTask.name zeroName majorName) PsKernelList.nil)) tasks) rest
              | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
          | PsKernelExpr.app head predecessor =>
              match head with
              | PsKernelExpr.constE majorName majorLevels =>
                  match majorLevels with
                  | PsKernelList.nil => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.natSuccName fn top succCase predecessor
                        (PsKernelList.cons (PsKernelOrderTask.name succName majorName) PsKernelList.nil)) tasks) rest
                  | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
              | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
          | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
      | PsKernelReduceTask.unitMajor fn minor ctorName levels =>
          match top with
          | PsKernelExpr.constE majorName majorLevels =>
              match levels with
              | PsKernelList.cons unusedMotiveLevel familyLevels => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.unitName fn top minor familyLevels majorLevels
                    (PsKernelList.cons (PsKernelOrderTask.name ctorName majorName) PsKernelList.nil)) tasks) rest
              | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
          | _ => psKernelReducePush env tasks rest (PsKernelExpr.app fn top)
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
          | PsKernelExpr.proj family index major => psKernelReduceNext env
              (PsKernelList.cons (PsKernelReduceTask.normal major)
                (PsKernelList.cons (PsKernelReduceTask.proj family index) tasks)) rest
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
          | PsKernelReduceTask.algebraic current =>
              match psKernelAlgReduceStep current with
              | PsKernelAlgReduceStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.algebraic next) rest) values
              | PsKernelAlgReduceStep.major major continuation => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.whnf major)
                    (PsKernelList.cons (PsKernelReduceTask.algebraicMajor continuation) rest)) values
              | PsKernelAlgReduceStep.neutral value => psKernelReducePush env rest values value
              | PsKernelAlgReduceStep.reduced value => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.whnf value) rest) values
              | PsKernelAlgReduceStep.rejected error => psKernelReduceReject error
          | PsKernelReduceTask.enumSpine original cursor args =>
              match cursor with
              | PsKernelExpr.app fn arg => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.enumSpine original fn (PsKernelList.cons arg args)) rest) values
              | PsKernelExpr.constE name levels => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.enumLookup original args levels (PsKernelLookupState.search name env)) rest) values
              | _ => psKernelReducePush env rest values original
          | PsKernelReduceTask.enumLookup original args levels current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.enumLookup original args levels next) rest) values
              | PsKernelLookupStep.found entry =>
                  match entry with
                  | PsKernelDefinition.algebraicRecursor name unusedLevels unusedType parameters rules =>
                      match levels with
                      | PsKernelList.cons unusedLevel tail =>
                          match tail with
                          | PsKernelList.nil => psKernelReduceNext env
                              (PsKernelList.cons (PsKernelReduceTask.algebraic
                                (psKernelAlgReduceStart original (PsKernelExpr.constE name levels) parameters rules args)) rest) values
                          | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                      | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | PsKernelDefinition.sumRecursor unusedName unusedParameters unusedType rules =>
                      match levels with
                      | PsKernelList.cons unusedLevel tail =>
                          match tail with
                          | PsKernelList.nil =>
                              match args with
                              | PsKernelList.cons unusedMotive tailArgs => psKernelReduceNext env
                                  (PsKernelList.cons (PsKernelReduceTask.sumMinors original rules tailArgs PsKernelList.nil) rest) values
                              | _ => psKernelReducePush env rest values original
                          | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                      | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | PsKernelDefinition.enumRecursor unusedName unusedParameters unusedType constructors =>
                      match levels with
                      | PsKernelList.cons unusedLevel tail =>
                          match tail with
                          | PsKernelList.nil =>
                              match args with
                              | PsKernelList.cons unusedMotive tailArgs => psKernelReduceNext env
                                  (PsKernelList.cons (PsKernelReduceTask.enumMinors original constructors tailArgs PsKernelList.nil) rest) values
                              | _ => psKernelReducePush env rest values original
                          | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                      | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | _ => psKernelReducePush env rest values original
              | PsKernelLookupStep.missing => psKernelReduceReject PsKernelCheckError.unknownConstant
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.sumMinors original rules args branches =>
              match rules with
              | PsKernelList.cons rule tail =>
                  match rule with
                  | PsKernelSumRule.rule ctorName unusedFields count =>
                      match args with
                      | PsKernelList.cons minor tailArgs => psKernelReduceNext env
                          (PsKernelList.cons (PsKernelReduceTask.sumMinors original tail tailArgs
                            (PsKernelList.cons (PsKernelSumBranch.branch ctorName count minor) branches)) rest) values
                      | _ => psKernelReducePush env rest values original
              | PsKernelList.nil =>
                  match args with
                  | PsKernelList.cons major tail =>
                      match tail with
                      | PsKernelList.nil =>
                          match original with
                          | PsKernelExpr.app fn unusedMajor => psKernelReduceNext env
                              (PsKernelList.cons (PsKernelReduceTask.whnf major)
                                (PsKernelList.cons (PsKernelReduceTask.sumMajor fn branches) rest)) values
                          | _ => psKernelReduceReject PsKernelCheckError.invalidState
                      | _ => psKernelReducePush env rest values original
                  | _ => psKernelReducePush env rest values original
          | PsKernelReduceTask.sumSpine fn major cursor args branches =>
              match cursor with
              | PsKernelExpr.app head arg => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.sumSpine fn major head
                    (PsKernelList.cons arg args) branches) rest) values
              | PsKernelExpr.constE name levels =>
                  match levels with
                  | PsKernelList.nil => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.sumFind fn major name args branches) rest) values
                  | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
              | _ => psKernelReducePush env rest values (PsKernelExpr.app fn major)
          | PsKernelReduceTask.sumFind fn major name args branches =>
              match branches with
              | PsKernelList.nil => psKernelReducePush env rest values (PsKernelExpr.app fn major)
              | PsKernelList.cons branch tail =>
                  match branch with
                  | PsKernelSumBranch.branch ctorName count minor => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.sumName fn major name args count minor tail
                        (PsKernelList.cons (PsKernelOrderTask.name name ctorName) PsKernelList.nil)) rest) values
          | PsKernelReduceTask.sumName fn major name args count minor remaining work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.sumName fn major name args count minor remaining next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.sumFields minor args count) rest) values
                  | _ => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.sumFind fn major name args remaining) rest) values
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.sumFields minor args remaining =>
              match remaining with
              | PsKernelNatural.zero =>
                  match args with
                  | PsKernelList.nil => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.whnf minor) rest) values
                  | _ => psKernelReduceReject PsKernelCheckError.typeMismatch
              | _ =>
                  match args with
                  | PsKernelList.cons arg tail => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.sumFields (PsKernelExpr.app minor arg)
                        tail (psKernelNaturalPred remaining)) rest) values
                  | _ => psKernelReduceReject PsKernelCheckError.typeMismatch
          | PsKernelReduceTask.enumMinors original constructors args branches =>
              match constructors with
              | PsKernelList.cons ctorName tail =>
                  match args with
                  | PsKernelList.cons minor tailArgs => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.enumMinors original tail tailArgs
                        (PsKernelList.cons (PsKernelEnumBranch.branch ctorName minor) branches)) rest) values
                  | _ => psKernelReducePush env rest values original
              | PsKernelList.nil =>
                  match args with
                  | PsKernelList.cons major tail =>
                      match tail with
                      | PsKernelList.nil =>
                          match original with
                          | PsKernelExpr.app fn unusedMajor => psKernelReduceNext env
                              (PsKernelList.cons (PsKernelReduceTask.whnf major)
                                (PsKernelList.cons (PsKernelReduceTask.enumMajor fn branches) rest)) values
                          | _ => psKernelReduceReject PsKernelCheckError.invalidState
                      | _ => psKernelReducePush env rest values original
                  | _ => psKernelReducePush env rest values original
          | PsKernelReduceTask.enumFind fn major name branches =>
              match branches with
              | PsKernelList.nil => psKernelReducePush env rest values (PsKernelExpr.app fn major)
              | PsKernelList.cons branch tail =>
                  match branch with
                  | PsKernelEnumBranch.branch ctorName minor => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.enumName fn major name minor tail
                        (PsKernelList.cons (PsKernelOrderTask.name name ctorName) PsKernelList.nil)) rest) values
          | PsKernelReduceTask.enumName fn major name minor remaining work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.enumName fn major name minor remaining next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf minor) rest) values
                  | _ => psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.enumFind fn major name remaining) rest) values
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.projectLookup family index major current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.projectLookup family index major next) rest) values
              | PsKernelLookupStep.found entry =>
                  match entry with
                  | PsKernelDefinition.recordFamily unusedName ctor fields => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.projectBound family index major ctor fields fields index) rest) values
                  | _ => psKernelReduceReject PsKernelCheckError.unsupported
              | PsKernelLookupStep.missing => psKernelReduceReject PsKernelCheckError.unknownConstant
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.projectBound family index major ctor fields pending cursor =>
              match pending with
              | PsKernelList.nil => psKernelReduceReject PsKernelCheckError.typeMismatch
              | PsKernelList.cons unusedField tail =>
                  match cursor with
                  | PsKernelNatural.zero => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.whnf major)
                        (PsKernelList.cons (PsKernelReduceTask.recordMajor
                          (PsKernelRecordAction.project family index) ctor fields) rest)) values
                  | _ => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.projectBound family index major ctor fields tail (psKernelNaturalPred cursor)) rest) values
          | PsKernelReduceTask.recordSpine action major cursor ctor fields args =>
              match cursor with
              | PsKernelExpr.app fn arg => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.recordSpine action major fn ctor fields (PsKernelList.cons arg args)) rest) values
              | PsKernelExpr.constE name levels =>
                  match levels with
                  | PsKernelList.nil => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.recordName action major fields args
                        (PsKernelList.cons (PsKernelOrderTask.name ctor name) PsKernelList.nil)) rest) values
                  | _ => psKernelReducePush env rest values (psKernelRecordNeutral action major)
              | _ => psKernelReducePush env rest values (psKernelRecordNeutral action major)
          | PsKernelReduceTask.recordName action major fields args work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.recordName action major fields args next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.recordArity action major fields args args) rest) values
                  | _ => psKernelReducePush env rest values (psKernelRecordNeutral action major)
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.recordArity action major fields args original =>
              match fields with
              | PsKernelList.nil =>
                  match args with
                  | PsKernelList.nil =>
                      match action with
                      | PsKernelRecordAction.project unusedFamily index => psKernelReduceNext env
                          (PsKernelList.cons (PsKernelReduceTask.recordSelect index original) rest) values
                      | PsKernelRecordAction.eliminate unusedFn minor => psKernelReduceNext env
                          (PsKernelList.cons (PsKernelReduceTask.recordApply minor original) rest) values
                  | _ => psKernelReduceReject PsKernelCheckError.typeMismatch
              | PsKernelList.cons unusedField fieldTail =>
                  match args with
                  | PsKernelList.cons unusedArg argTail => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.recordArity action major fieldTail argTail original) rest) values
                  | _ => psKernelReduceReject PsKernelCheckError.typeMismatch
          | PsKernelReduceTask.recordSelect index args =>
              match args with
              | PsKernelList.nil => psKernelReduceReject PsKernelCheckError.typeMismatch
              | PsKernelList.cons arg tail =>
                  match index with
                  | PsKernelNatural.zero => psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf arg) rest) values
                  | _ => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.recordSelect (psKernelNaturalPred index) tail) rest) values
          | PsKernelReduceTask.recordApply minor args =>
              match args with
              | PsKernelList.nil => psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf minor) rest) values
              | PsKernelList.cons arg tail => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.recordApply (PsKernelExpr.app minor arg) tail) rest) values
          | PsKernelReduceTask.natLookup fn major zeroCase succCase current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.natLookup fn major zeroCase succCase next) rest) values
              | PsKernelLookupStep.found entry =>
                  match entry with
                  | PsKernelDefinition.natRecursor unusedName unusedParameters unusedType zeroName succName => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.whnf major)
                        (PsKernelList.cons (PsKernelReduceTask.natMajor fn zeroCase succCase zeroName succName) rest)) values
                  | _ => psKernelReduceEnumApply env rest values fn major
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.natZeroName fn major zeroCase current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.natZeroName fn major zeroCase next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf zeroCase) rest) values
                  | _ => psKernelReducePush env rest values (PsKernelExpr.app fn major)
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.natSuccName fn major succCase predecessor current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.natSuccName fn major succCase predecessor next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.whnf (PsKernelExpr.app
                        (PsKernelExpr.app succCase predecessor) (PsKernelExpr.app fn predecessor))) rest) values
                  | _ => psKernelReducePush env rest values (PsKernelExpr.app fn major)
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.unitLookup fn major minor levels current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.unitLookup fn major minor levels next) rest) values
              | PsKernelLookupStep.found entry =>
                  match entry with
                  | PsKernelDefinition.recordRecursor unusedName unusedParameters unusedType ctorName fields =>
                      match levels with
                      | PsKernelList.cons unusedLevel tail =>
                          match tail with
                          | PsKernelList.nil => psKernelReduceNext env
                              (PsKernelList.cons (PsKernelReduceTask.whnf major)
                                (PsKernelList.cons (PsKernelReduceTask.recordMajor
                                  (PsKernelRecordAction.eliminate fn minor) ctorName fields) rest)) values
                          | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                      | _ => psKernelReduceReject PsKernelCheckError.invalidUniverse
                  | PsKernelDefinition.unitRecursor unusedName unusedParameters unusedType ctorName => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.whnf major)
                        (PsKernelList.cons (PsKernelReduceTask.unitMajor fn minor ctorName levels) rest)) values
                  | _ => psKernelReduceEnumApply env rest values fn major
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.unitName fn major minor left right current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.unitName fn major minor left right next) rest) values
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.unitLevels fn major minor left right) rest) values
                  | _ => psKernelReducePush env rest values (PsKernelExpr.app fn major)
              | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.unitLevels fn major minor left right =>
              match left with
              | PsKernelList.nil =>
                  match right with
                  | PsKernelList.nil => psKernelReduceNext env (PsKernelList.cons (PsKernelReduceTask.whnf minor) rest) values
                  | _ => psKernelReducePush env rest values (PsKernelExpr.app fn major)
              | PsKernelList.cons head tail =>
                  match right with
                  | PsKernelList.nil => psKernelReducePush env rest values (PsKernelExpr.app fn major)
                  | PsKernelList.cons otherHead otherTail => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.unitLevel fn major minor tail otherTail
                        (psKernelLevelCheckStart head otherHead)) rest) values
          | PsKernelReduceTask.unitLevel fn major minor left right current =>
              match psKernelLevelCheckStep current with
              | PsKernelLevelCheckStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.unitLevel fn major minor left right next) rest) values
              | PsKernelLevelCheckStep.final result =>
                  match result with
                  | PsKernelLevelCheckResult.equal => psKernelReduceNext env
                      (PsKernelList.cons (PsKernelReduceTask.unitLevels fn major minor left right) rest) values
                  | PsKernelLevelCheckResult.different => psKernelReducePush env rest values (PsKernelExpr.app fn major)
                  | _ => psKernelReduceReject PsKernelCheckError.invalidState
          | PsKernelReduceTask.text text current =>
              match psKernelTextCheckStep current with
              | PsKernelTextCheckStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.text text next) rest) values
              | PsKernelTextCheckStep.ready => psKernelReducePush env rest values
                  (PsKernelExpr.lit (PsKernelLiteral.text text))
              | PsKernelTextCheckStep.rejected error => psKernelReduceReject error
          | PsKernelReduceTask.natural number current =>
              match psKernelBuiltinNatStep current with
              | PsKernelBuiltinNatStep.next next => psKernelReduceNext env
                  (PsKernelList.cons (PsKernelReduceTask.natural number next) rest) values
              | PsKernelBuiltinNatStep.rejected error => psKernelReduceReject error
              | PsKernelBuiltinNatStep.ready =>
                  match number with
                  | PsKernelNatural.zero => psKernelReducePush env rest values (PsKernelExpr.constE psKernelBuiltinNatZeroName PsKernelList.nil)
                  | PsKernelNatural.positive unused => psKernelReducePush env rest values
                      (PsKernelExpr.app (PsKernelExpr.constE psKernelBuiltinNatSuccName PsKernelList.nil)
                        (PsKernelExpr.lit (PsKernelLiteral.natural (psKernelNaturalPred number))))
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
