import Ps.Kernel.Expr
import Ps.Kernel.Binding
import Ps.Kernel.LevelInstantiate

/- Universe instantiation under every expression constructor. Term variables and
binder names are unchanged; this traversal is not term-scope or type checking.
The initial parameter check also runs for expressions containing no universes.
Every nested level operation consumes the surrounding transition budget. -/
inductive PsKernelExprInstantiateTask where
  | validate (target : PsKernelExpr) (state : PsKernelLevelInstantiateState)
  | visit (value : PsKernelExpr)
  | sort (state : PsKernelLevelInstantiateState)
  | constant (name : PsKernelName) (remaining : PsKernelList PsKernelLevel)
      (reversed : PsKernelList PsKernelLevel)
  | constantLevel (name : PsKernelName) (remaining : PsKernelList PsKernelLevel)
      (reversed : PsKernelList PsKernelLevel) (state : PsKernelLevelInstantiateState)
  | constantReverse (name : PsKernelName) (remaining : PsKernelList PsKernelLevel)
      (levels : PsKernelList PsKernelLevel)
  | rebuild (task : PsKernelBindingTask)

inductive PsKernelExprInstantiateState where
  | state (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
      (tasks : PsKernelList PsKernelExprInstantiateTask) (values : PsKernelList PsKernelExpr)

inductive PsKernelExprInstantiateResult where
  | outOfFuel
  | invalidState
  | invalidParameters
  | undeclaredParameter
  | done (value : PsKernelExpr)

inductive PsKernelExprInstantiateStep where
  | next (state : PsKernelExprInstantiateState)
  | final (result : PsKernelExprInstantiateResult)

def psKernelExprInstantiateNext
    (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
    (tasks : PsKernelList PsKernelExprInstantiateTask)
    (values : PsKernelList PsKernelExpr) : PsKernelExprInstantiateStep :=
  PsKernelExprInstantiateStep.next (PsKernelExprInstantiateState.state names levels tasks values)

def psKernelExprInstantiateLevelError (result : PsKernelLevelInstantiateResult) : PsKernelExprInstantiateStep :=
  match result with
  | PsKernelLevelInstantiateResult.invalidParameters => PsKernelExprInstantiateStep.final PsKernelExprInstantiateResult.invalidParameters
  | PsKernelLevelInstantiateResult.undeclaredParameter => PsKernelExprInstantiateStep.final PsKernelExprInstantiateResult.undeclaredParameter
  | _ => PsKernelExprInstantiateStep.final PsKernelExprInstantiateResult.invalidState

def psKernelExprInstantiateVisit
    (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
    (value : PsKernelExpr) (tasks : PsKernelList PsKernelExprInstantiateTask)
    (values : PsKernelList PsKernelExpr) : PsKernelExprInstantiateStep :=
  match value with
  | PsKernelExpr.sortE level => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.sort (psKernelLevelInstantiateStart names levels level)) tasks) values
  | PsKernelExpr.constE name arguments => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.constant name arguments PsKernelList.nil) tasks) values
  | PsKernelExpr.app fn arg => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.visit fn)
        (PsKernelList.cons (PsKernelExprInstantiateTask.visit arg)
          (PsKernelList.cons (PsKernelExprInstantiateTask.rebuild PsKernelBindingTask.app) tasks))) values
  | PsKernelExpr.lam name type body binder => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.visit type)
        (PsKernelList.cons (PsKernelExprInstantiateTask.visit body)
          (PsKernelList.cons (PsKernelExprInstantiateTask.rebuild (PsKernelBindingTask.lam name binder)) tasks))) values
  | PsKernelExpr.forallE name type body binder => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.visit type)
        (PsKernelList.cons (PsKernelExprInstantiateTask.visit body)
          (PsKernelList.cons (PsKernelExprInstantiateTask.rebuild (PsKernelBindingTask.forallE name binder)) tasks))) values
  | PsKernelExpr.letE name type val body => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.visit type)
        (PsKernelList.cons (PsKernelExprInstantiateTask.visit val)
          (PsKernelList.cons (PsKernelExprInstantiateTask.visit body)
            (PsKernelList.cons (PsKernelExprInstantiateTask.rebuild (PsKernelBindingTask.letE name)) tasks)))) values
  | PsKernelExpr.proj family index val => psKernelExprInstantiateNext names levels
      (PsKernelList.cons (PsKernelExprInstantiateTask.visit val)
        (PsKernelList.cons (PsKernelExprInstantiateTask.rebuild (PsKernelBindingTask.proj family index)) tasks)) values
  | _ => psKernelExprInstantiateNext names levels tasks (PsKernelList.cons value values)

def psKernelExprInstantiateTaskStep
    (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
    (task : PsKernelExprInstantiateTask) (rest : PsKernelList PsKernelExprInstantiateTask)
    (values : PsKernelList PsKernelExpr) : PsKernelExprInstantiateStep :=
  match task with
  | PsKernelExprInstantiateTask.visit value => psKernelExprInstantiateVisit names levels value rest values
  | PsKernelExprInstantiateTask.validate target current =>
      match psKernelLevelInstantiateStep current with
      | PsKernelLevelInstantiateStep.next next => psKernelExprInstantiateNext names levels
          (PsKernelList.cons (PsKernelExprInstantiateTask.validate target next) rest) values
      | PsKernelLevelInstantiateStep.final result =>
          match result with
          | PsKernelLevelInstantiateResult.done unused => psKernelExprInstantiateNext names levels
              (PsKernelList.cons (PsKernelExprInstantiateTask.visit target) rest) values
          | _ => psKernelExprInstantiateLevelError result
  | PsKernelExprInstantiateTask.sort current =>
      match psKernelLevelInstantiateStep current with
      | PsKernelLevelInstantiateStep.next next => psKernelExprInstantiateNext names levels
          (PsKernelList.cons (PsKernelExprInstantiateTask.sort next) rest) values
      | PsKernelLevelInstantiateStep.final result =>
          match result with
          | PsKernelLevelInstantiateResult.done value => psKernelExprInstantiateNext names levels rest
              (PsKernelList.cons (PsKernelExpr.sortE value) values)
          | _ => psKernelExprInstantiateLevelError result
  | PsKernelExprInstantiateTask.constant name remaining reversed =>
      match remaining with
      | PsKernelList.nil => psKernelExprInstantiateNext names levels
          (PsKernelList.cons (PsKernelExprInstantiateTask.constantReverse name reversed PsKernelList.nil) rest) values
      | PsKernelList.cons level tail => psKernelExprInstantiateNext names levels
          (PsKernelList.cons (PsKernelExprInstantiateTask.constantLevel name tail reversed
            (psKernelLevelInstantiateStart names levels level)) rest) values
  | PsKernelExprInstantiateTask.constantLevel name remaining reversed current =>
      match psKernelLevelInstantiateStep current with
      | PsKernelLevelInstantiateStep.next next => psKernelExprInstantiateNext names levels
          (PsKernelList.cons (PsKernelExprInstantiateTask.constantLevel name remaining reversed next) rest) values
      | PsKernelLevelInstantiateStep.final result =>
          match result with
          | PsKernelLevelInstantiateResult.done value => psKernelExprInstantiateNext names levels
              (PsKernelList.cons (PsKernelExprInstantiateTask.constant name remaining (PsKernelList.cons value reversed)) rest) values
          | _ => psKernelExprInstantiateLevelError result
  | PsKernelExprInstantiateTask.constantReverse name remaining arguments =>
      match remaining with
      | PsKernelList.nil => psKernelExprInstantiateNext names levels rest
          (PsKernelList.cons (PsKernelExpr.constE name arguments) values)
      | PsKernelList.cons value tail => psKernelExprInstantiateNext names levels
          (PsKernelList.cons (PsKernelExprInstantiateTask.constantReverse name tail (PsKernelList.cons value arguments)) rest) values
  | PsKernelExprInstantiateTask.rebuild rebuild =>
      match psKernelBindingRebuild rebuild PsKernelList.nil values with
      | PsKernelBindingStep.next next =>
          match next with
          | PsKernelBindingState.state unusedTasks updated => psKernelExprInstantiateNext names levels rest updated
      | _ => PsKernelExprInstantiateStep.final PsKernelExprInstantiateResult.invalidState

def psKernelExprInstantiateStep (state : PsKernelExprInstantiateState) : PsKernelExprInstantiateStep :=
  match state with
  | PsKernelExprInstantiateState.state names levels tasks values =>
      match tasks with
      | PsKernelList.nil =>
          match psKernelBindingFinish values with
          | PsKernelBindingResult.done value => PsKernelExprInstantiateStep.final (PsKernelExprInstantiateResult.done value)
          | _ => PsKernelExprInstantiateStep.final PsKernelExprInstantiateResult.invalidState
      | PsKernelList.cons task rest => psKernelExprInstantiateTaskStep names levels task rest values

def psKernelExprInstantiateStart
    (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
    (target : PsKernelExpr) : PsKernelExprInstantiateState :=
  PsKernelExprInstantiateState.state names levels
    (PsKernelList.cons (PsKernelExprInstantiateTask.validate target
      (psKernelLevelInstantiateStart names levels PsKernelLevel.zero)) PsKernelList.nil) PsKernelList.nil

def psKernelExprInstantiateRun (fuel : PsKernelFuel) : PsKernelExprInstantiateState -> PsKernelExprInstantiateResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelExprInstantiateState) => PsKernelExprInstantiateResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelExprInstantiateState) =>
        match psKernelExprInstantiateStep state with
        | PsKernelExprInstantiateStep.final result => result
        | PsKernelExprInstantiateStep.next next =>
            let smaller : PsKernelExprInstantiateState -> PsKernelExprInstantiateResult := psKernelExprInstantiateRun remaining;
            smaller next
