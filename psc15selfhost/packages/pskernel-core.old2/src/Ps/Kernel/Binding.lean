import Ps.Kernel.Data
import Ps.Kernel.Natural
import Ps.Kernel.Expr

/- First-order traversal with a shared task budget. Abstraction follows Lean's
fvar abstraction: existing bound variables are not shifted. Scope checking here
covers variables, NOT typing, universe parameters or literal/primitive validity. -/
def psKernelBindingPush
    (tasks : PsKernelList PsKernelBindingTask) (values : PsKernelList PsKernelExpr)
    (value : PsKernelExpr) : PsKernelBindingStep :=
  PsKernelBindingStep.next (PsKernelBindingState.state tasks (PsKernelList.cons value values))

def psKernelBindingAfterOrder
    (mode : PsKernelBindingMode) (depth index : PsKernelNatural) (order : PsKernelOrder)
    (tasks : PsKernelList PsKernelBindingTask) (values : PsKernelList PsKernelExpr) : PsKernelBindingStep :=
  match mode with
  | PsKernelBindingMode.lift amount =>
      match order with
      | PsKernelOrder.less => psKernelBindingPush tasks values (PsKernelExpr.bvar index)
      | _ =>
          PsKernelBindingStep.next (PsKernelBindingState.state
            (PsKernelList.cons (PsKernelBindingTask.sumIndex
              (PsKernelNumericState.add index amount PsKernelBit.zero PsKernelList.nil)) tasks) values)
  | PsKernelBindingMode.instantiate replacement =>
      match order with
      | PsKernelOrder.less => psKernelBindingPush tasks values (PsKernelExpr.bvar index)
      | PsKernelOrder.greater => psKernelBindingPush tasks values (PsKernelExpr.bvar (psKernelNaturalPred index))
      | PsKernelOrder.same =>
          PsKernelBindingStep.next (PsKernelBindingState.state
            (PsKernelList.cons (PsKernelBindingTask.visit
              (PsKernelBindingMode.lift depth) PsKernelNatural.zero replacement) tasks) values)
  | PsKernelBindingMode.abstract unusedId => psKernelBindingPush tasks values (PsKernelExpr.bvar index)
  | PsKernelBindingMode.closed =>
      match order with
      | PsKernelOrder.less => psKernelBindingPush tasks values (PsKernelExpr.bvar index)
      | _ => PsKernelBindingStep.final PsKernelBindingResult.invalidScope

def psKernelBindingVisit
    (mode : PsKernelBindingMode) (depth : PsKernelNatural) (value : PsKernelExpr)
    (tasks : PsKernelList PsKernelBindingTask) (values : PsKernelList PsKernelExpr) : PsKernelBindingStep :=
  match value with
  | PsKernelExpr.bvar index =>
      match mode with
      | PsKernelBindingMode.abstract unusedId => psKernelBindingPush tasks values value
      | _ =>
          PsKernelBindingStep.next (PsKernelBindingState.state
            (PsKernelList.cons (PsKernelBindingTask.orderIndex mode depth index
              (PsKernelNumericState.order index depth PsKernelOrder.same)) tasks) values)
  | PsKernelExpr.fvar id =>
      match mode with
      | PsKernelBindingMode.closed => PsKernelBindingStep.final PsKernelBindingResult.invalidScope
      | PsKernelBindingMode.abstract target =>
          PsKernelBindingStep.next (PsKernelBindingState.state
            (PsKernelList.cons (PsKernelBindingTask.orderFree depth id
              (PsKernelNumericState.order id target PsKernelOrder.same)) tasks) values)
      | _ => psKernelBindingPush tasks values value
  | PsKernelExpr.sortE unused => psKernelBindingPush tasks values value
  | PsKernelExpr.constE unusedName unusedLevels => psKernelBindingPush tasks values value
  | PsKernelExpr.lit unused => psKernelBindingPush tasks values value
  | PsKernelExpr.app fn arg =>
      PsKernelBindingStep.next (PsKernelBindingState.state
        (PsKernelList.cons (PsKernelBindingTask.visit mode depth fn)
          (PsKernelList.cons (PsKernelBindingTask.visit mode depth arg)
            (PsKernelList.cons PsKernelBindingTask.app tasks))) values)
  | PsKernelExpr.lam name type body binder =>
      PsKernelBindingStep.next (PsKernelBindingState.state
        (PsKernelList.cons (PsKernelBindingTask.visit mode depth type)
          (PsKernelList.cons (PsKernelBindingTask.visit mode (psKernelNaturalSucc depth) body)
            (PsKernelList.cons (PsKernelBindingTask.lam name binder) tasks))) values)
  | PsKernelExpr.forallE name type body binder =>
      PsKernelBindingStep.next (PsKernelBindingState.state
        (PsKernelList.cons (PsKernelBindingTask.visit mode depth type)
          (PsKernelList.cons (PsKernelBindingTask.visit mode (psKernelNaturalSucc depth) body)
            (PsKernelList.cons (PsKernelBindingTask.forallE name binder) tasks))) values)
  | PsKernelExpr.letE name type val body =>
      PsKernelBindingStep.next (PsKernelBindingState.state
        (PsKernelList.cons (PsKernelBindingTask.visit mode depth type)
          (PsKernelList.cons (PsKernelBindingTask.visit mode depth val)
            (PsKernelList.cons (PsKernelBindingTask.visit mode (psKernelNaturalSucc depth) body)
              (PsKernelList.cons (PsKernelBindingTask.letE name) tasks)))) values)
  | PsKernelExpr.proj family index target =>
      PsKernelBindingStep.next (PsKernelBindingState.state
        (PsKernelList.cons (PsKernelBindingTask.visit mode depth target)
          (PsKernelList.cons (PsKernelBindingTask.proj family index) tasks)) values)

def psKernelBindingRebuild
    (task : PsKernelBindingTask) (tasks : PsKernelList PsKernelBindingTask)
    (values : PsKernelList PsKernelExpr) : PsKernelBindingStep :=
  match values with
  | PsKernelList.nil => PsKernelBindingStep.final PsKernelBindingResult.invalidState
  | PsKernelList.cons top rest =>
      match task with
      | PsKernelBindingTask.proj family index => psKernelBindingPush tasks rest (PsKernelExpr.proj family index top)
      | PsKernelBindingTask.app =>
          match rest with
          | PsKernelList.nil => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | PsKernelList.cons fn tail => psKernelBindingPush tasks tail (PsKernelExpr.app fn top)
      | PsKernelBindingTask.lam name binder =>
          match rest with
          | PsKernelList.nil => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | PsKernelList.cons type tail => psKernelBindingPush tasks tail (PsKernelExpr.lam name type top binder)
      | PsKernelBindingTask.forallE name binder =>
          match rest with
          | PsKernelList.nil => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | PsKernelList.cons type tail => psKernelBindingPush tasks tail (PsKernelExpr.forallE name type top binder)
      | PsKernelBindingTask.letE name =>
          match rest with
          | PsKernelList.nil => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | PsKernelList.cons val tail =>
              match tail with
              | PsKernelList.nil => PsKernelBindingStep.final PsKernelBindingResult.invalidState
              | PsKernelList.cons type remaining => psKernelBindingPush tasks remaining (PsKernelExpr.letE name type val top)
      | _ => PsKernelBindingStep.final PsKernelBindingResult.invalidState

def psKernelBindingFinish (values : PsKernelList PsKernelExpr) : PsKernelBindingResult :=
  match values with
  | PsKernelList.nil => PsKernelBindingResult.invalidState
  | PsKernelList.cons value rest =>
      match rest with
      | PsKernelList.nil => PsKernelBindingResult.done value
      | _ => PsKernelBindingResult.invalidState

def psKernelBindingStep (state : PsKernelBindingState) : PsKernelBindingStep :=
  match state with
  | PsKernelBindingState.state tasks values =>
      match tasks with
      | PsKernelList.nil => PsKernelBindingStep.final (psKernelBindingFinish values)
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelBindingTask.visit mode depth value => psKernelBindingVisit mode depth value rest values
          | PsKernelBindingTask.orderIndex mode depth index numeric =>
              match psKernelNumericStep numeric with
              | PsKernelNumericStep.next next =>
                  PsKernelBindingStep.next (PsKernelBindingState.state
                    (PsKernelList.cons (PsKernelBindingTask.orderIndex mode depth index next) rest) values)
              | PsKernelNumericStep.ordered order => psKernelBindingAfterOrder mode depth index order rest values
              | _ => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | PsKernelBindingTask.orderFree depth id numeric =>
              match psKernelNumericStep numeric with
              | PsKernelNumericStep.next next =>
                  PsKernelBindingStep.next (PsKernelBindingState.state
                    (PsKernelList.cons (PsKernelBindingTask.orderFree depth id next) rest) values)
              | PsKernelNumericStep.ordered order =>
                  match order with
                  | PsKernelOrder.same => psKernelBindingPush rest values (PsKernelExpr.bvar depth)
                  | _ => psKernelBindingPush rest values (PsKernelExpr.fvar id)
              | _ => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | PsKernelBindingTask.sumIndex numeric =>
              match psKernelNumericStep numeric with
              | PsKernelNumericStep.next next =>
                  PsKernelBindingStep.next (PsKernelBindingState.state
                    (PsKernelList.cons (PsKernelBindingTask.sumIndex next) rest) values)
              | PsKernelNumericStep.sum index => psKernelBindingPush rest values (PsKernelExpr.bvar index)
              | _ => PsKernelBindingStep.final PsKernelBindingResult.invalidState
          | _ => psKernelBindingRebuild task rest values

def psKernelBindingStart
    (mode : PsKernelBindingMode) (depth : PsKernelNatural) (value : PsKernelExpr) : PsKernelBindingState :=
  PsKernelBindingState.state (PsKernelList.cons (PsKernelBindingTask.visit mode depth value) PsKernelList.nil) PsKernelList.nil

def psKernelBindingRun (fuel : PsKernelFuel) : PsKernelBindingState -> PsKernelBindingResult :=
  match fuel with
  | PsKernelFuel.stop =>
      fun (state : PsKernelBindingState) =>
        match state with
        | PsKernelBindingState.state tasks values =>
            match tasks with
            | PsKernelList.nil => psKernelBindingFinish values
            | _ => PsKernelBindingResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelBindingState) =>
        match psKernelBindingStep state with
        | PsKernelBindingStep.final result => result
        | PsKernelBindingStep.next next =>
            let smaller : PsKernelBindingState -> PsKernelBindingResult := psKernelBindingRun remaining;
            smaller next
