import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Environment
import Ps.Kernel.Reduction
import Ps.Kernel.LevelCheck

/- Conservative conversion for the present fragment: alpha/beta/zeta/delta and
universe normalization. A mismatch is NOT a claim of full Lean inequivalence.
Eta, proof irrelevance, primitive and recursor conversion remain separate work. -/
inductive PsKernelConversionTask where
  | expr (left : PsKernelExpr) (right : PsKernelExpr)
  | names (state : PsKernelList PsKernelOrderTask)
  | levels (left : PsKernelList PsKernelLevel) (right : PsKernelList PsKernelLevel)
  | natural (state : PsKernelNumericState)
  | level (state : PsKernelLevelCheckState)

inductive PsKernelConversionState where
  | left (environment : PsKernelList PsKernelDefinition) (right : PsKernelExpr) (state : PsKernelReduceState)
  | right (left : PsKernelExpr) (state : PsKernelReduceState)
  | compare (tasks : PsKernelList PsKernelConversionTask)

inductive PsKernelConversionResult where
  | outOfFuel
  | rejected (error : PsKernelCheckError)
  | equal
  | different

inductive PsKernelConversionStep where
  | next (state : PsKernelConversionState)
  | final (result : PsKernelConversionResult)

def psKernelConversionReject (error : PsKernelCheckError) : PsKernelConversionStep :=
  PsKernelConversionStep.final (PsKernelConversionResult.rejected error)

def psKernelConversionTasks (tasks : PsKernelList PsKernelConversionTask) : PsKernelConversionStep :=
  PsKernelConversionStep.next (PsKernelConversionState.compare tasks)

def psKernelConversionExpr
    (left right : PsKernelExpr) (tasks : PsKernelList PsKernelConversionTask) : PsKernelConversionStep :=
  match left with
  | PsKernelExpr.bvar index =>
      match right with
      | PsKernelExpr.bvar other => psKernelConversionTasks (PsKernelList.cons
          (PsKernelConversionTask.natural (PsKernelNumericState.order index other PsKernelOrder.same)) tasks)
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.sortE level =>
      match right with
      | PsKernelExpr.sortE other => psKernelConversionTasks
          (PsKernelList.cons (PsKernelConversionTask.level (psKernelLevelCheckStart level other)) tasks)
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.constE name levels =>
      match right with
      | PsKernelExpr.constE otherName otherLevels => psKernelConversionTasks
          (PsKernelList.cons (PsKernelConversionTask.names
            (PsKernelList.cons (PsKernelOrderTask.name name otherName) PsKernelList.nil))
            (PsKernelList.cons (PsKernelConversionTask.levels levels otherLevels) tasks))
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.app fn arg =>
      match right with
      | PsKernelExpr.app otherFn otherArg => psKernelConversionTasks
          (PsKernelList.cons (PsKernelConversionTask.expr fn otherFn)
            (PsKernelList.cons (PsKernelConversionTask.expr arg otherArg) tasks))
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.proj family index value =>
      match right with
      | PsKernelExpr.proj otherFamily otherIndex otherValue => psKernelConversionTasks
          (PsKernelList.cons (PsKernelConversionTask.names
            (PsKernelList.cons (PsKernelOrderTask.name family otherFamily) PsKernelList.nil))
            (PsKernelList.cons (PsKernelConversionTask.natural
              (PsKernelNumericState.order index otherIndex PsKernelOrder.same))
              (PsKernelList.cons (PsKernelConversionTask.expr value otherValue) tasks)))
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.lam unusedName type body unusedBinder =>
      match right with
      | PsKernelExpr.lam unusedOtherName otherType otherBody unusedOtherBinder => psKernelConversionTasks
          (PsKernelList.cons (PsKernelConversionTask.expr type otherType)
            (PsKernelList.cons (PsKernelConversionTask.expr body otherBody) tasks))
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.forallE unusedName type body unusedBinder =>
      match right with
      | PsKernelExpr.forallE unusedOtherName otherType otherBody unusedOtherBinder => psKernelConversionTasks
          (PsKernelList.cons (PsKernelConversionTask.expr type otherType)
            (PsKernelList.cons (PsKernelConversionTask.expr body otherBody) tasks))
      | _ => PsKernelConversionStep.final PsKernelConversionResult.different
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.text text =>
          match right with
          | PsKernelExpr.lit otherLiteral =>
              match otherLiteral with
              | PsKernelLiteral.text other => psKernelConversionTasks
                  (PsKernelList.cons (PsKernelConversionTask.names
                    (PsKernelList.cons (PsKernelOrderTask.text text other) PsKernelList.nil)) tasks)
              | _ => PsKernelConversionStep.final PsKernelConversionResult.different
          | _ => PsKernelConversionStep.final PsKernelConversionResult.different
      | _ => psKernelConversionReject PsKernelCheckError.unsupported
  | _ => psKernelConversionReject PsKernelCheckError.unsupported

def psKernelConversionStep (state : PsKernelConversionState) : PsKernelConversionStep :=
  match state with
  | PsKernelConversionState.left env right current =>
      match psKernelReduceStep current with
      | PsKernelReduceStep.next next => PsKernelConversionStep.next (PsKernelConversionState.left env right next)
      | PsKernelReduceStep.final result =>
          match result with
          | PsKernelReduceResult.done left => PsKernelConversionStep.next
              (PsKernelConversionState.right left (psKernelNormalStart env right))
          | PsKernelReduceResult.rejected error => psKernelConversionReject error
          | _ => psKernelConversionReject PsKernelCheckError.invalidState
  | PsKernelConversionState.right left current =>
      match psKernelReduceStep current with
      | PsKernelReduceStep.next next => PsKernelConversionStep.next (PsKernelConversionState.right left next)
      | PsKernelReduceStep.final result =>
          match result with
          | PsKernelReduceResult.done right => psKernelConversionTasks
              (PsKernelList.cons (PsKernelConversionTask.expr left right) PsKernelList.nil)
          | PsKernelReduceResult.rejected error => psKernelConversionReject error
          | _ => psKernelConversionReject PsKernelCheckError.invalidState
  | PsKernelConversionState.compare tasks =>
      match tasks with
      | PsKernelList.nil => PsKernelConversionStep.final PsKernelConversionResult.equal
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelConversionTask.expr left right => psKernelConversionExpr left right rest
          | PsKernelConversionTask.names current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelConversionTasks
                  (PsKernelList.cons (PsKernelConversionTask.names next) rest)
              | PsKernelOrderStep.invalidState => psKernelConversionReject PsKernelCheckError.invalidState
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelConversionTasks rest
                  | _ => PsKernelConversionStep.final PsKernelConversionResult.different
          | PsKernelConversionTask.levels left right =>
              match left with
              | PsKernelList.nil =>
                  match right with
                  | PsKernelList.nil => psKernelConversionTasks rest
                  | _ => PsKernelConversionStep.final PsKernelConversionResult.different
              | PsKernelList.cons head tail =>
                  match right with
                  | PsKernelList.nil => PsKernelConversionStep.final PsKernelConversionResult.different
                  | PsKernelList.cons otherHead otherTail => psKernelConversionTasks
                      (PsKernelList.cons (PsKernelConversionTask.level (psKernelLevelCheckStart head otherHead))
                        (PsKernelList.cons (PsKernelConversionTask.levels tail otherTail) rest))
          | PsKernelConversionTask.natural current =>
              match psKernelNumericStep current with
              | PsKernelNumericStep.next next => psKernelConversionTasks (PsKernelList.cons (PsKernelConversionTask.natural next) rest)
              | PsKernelNumericStep.ordered order =>
                  match order with
                  | PsKernelOrder.same => psKernelConversionTasks rest
                  | _ => PsKernelConversionStep.final PsKernelConversionResult.different
              | _ => psKernelConversionReject PsKernelCheckError.invalidState
          | PsKernelConversionTask.level current =>
              match psKernelLevelCheckStep current with
              | PsKernelLevelCheckStep.next next => psKernelConversionTasks (PsKernelList.cons (PsKernelConversionTask.level next) rest)
              | PsKernelLevelCheckStep.final result =>
                  match result with
                  | PsKernelLevelCheckResult.equal => psKernelConversionTasks rest
                  | PsKernelLevelCheckResult.different => PsKernelConversionStep.final PsKernelConversionResult.different
                  | _ => psKernelConversionReject PsKernelCheckError.invalidState

def psKernelConversionStart
    (env : PsKernelList PsKernelDefinition) (left right : PsKernelExpr) : PsKernelConversionState :=
  PsKernelConversionState.left env right (psKernelNormalStart env left)

def psKernelConversionRun (fuel : PsKernelFuel) : PsKernelConversionState -> PsKernelConversionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelConversionState) => PsKernelConversionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelConversionState) =>
        match psKernelConversionStep state with
        | PsKernelConversionStep.final result => result
        | PsKernelConversionStep.next next =>
            let smaller : PsKernelConversionState -> PsKernelConversionResult := psKernelConversionRun remaining;
            smaller next
