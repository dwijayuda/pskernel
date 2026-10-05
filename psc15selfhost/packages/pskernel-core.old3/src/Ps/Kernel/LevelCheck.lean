import Ps.Kernel.Data
import Ps.Kernel.Order
import Ps.Kernel.Universe

/- Bounded normalization/equality composition; not term conversion or admission. -/
inductive PsKernelLevelCheckState where
  | left (right : PsKernelLevel) (state : PsKernelUniverseState)
  | right (left : PsKernelLevel) (state : PsKernelUniverseState)
  | order (tasks : PsKernelList PsKernelOrderTask)

inductive PsKernelLevelCheckResult where
  | outOfFuel
  | invalidState
  | equal
  | different

inductive PsKernelLevelCheckStep where
  | next (state : PsKernelLevelCheckState)
  | final (result : PsKernelLevelCheckResult)

def psKernelLevelCheckStart (left right : PsKernelLevel) : PsKernelLevelCheckState :=
  PsKernelLevelCheckState.left right (psKernelUniverseStart left)

def psKernelLevelCheckStep (state : PsKernelLevelCheckState) : PsKernelLevelCheckStep :=
  match state with
  | PsKernelLevelCheckState.left right current =>
      match psKernelUniverseStep current with
      | PsKernelUniverseStep.next next => PsKernelLevelCheckStep.next (PsKernelLevelCheckState.left right next)
      | PsKernelUniverseStep.final result =>
          match result with
          | PsKernelUniverseResult.done left => PsKernelLevelCheckStep.next (PsKernelLevelCheckState.right left (psKernelUniverseStart right))
          | _ => PsKernelLevelCheckStep.final PsKernelLevelCheckResult.invalidState
  | PsKernelLevelCheckState.right left current =>
      match psKernelUniverseStep current with
      | PsKernelUniverseStep.next next => PsKernelLevelCheckStep.next (PsKernelLevelCheckState.right left next)
      | PsKernelUniverseStep.final result =>
          match result with
          | PsKernelUniverseResult.done right => PsKernelLevelCheckStep.next (PsKernelLevelCheckState.order
              (PsKernelList.cons (PsKernelOrderTask.level left right) PsKernelList.nil))
          | _ => PsKernelLevelCheckStep.final PsKernelLevelCheckResult.invalidState
  | PsKernelLevelCheckState.order tasks =>
      match psKernelOrderStep tasks with
      | PsKernelOrderStep.next next => PsKernelLevelCheckStep.next (PsKernelLevelCheckState.order next)
      | PsKernelOrderStep.invalidState => PsKernelLevelCheckStep.final PsKernelLevelCheckResult.invalidState
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same => PsKernelLevelCheckStep.final PsKernelLevelCheckResult.equal
          | _ => PsKernelLevelCheckStep.final PsKernelLevelCheckResult.different

def psKernelLevelCheckRun (fuel : PsKernelFuel) : PsKernelLevelCheckState -> PsKernelLevelCheckResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelLevelCheckState) => PsKernelLevelCheckResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelLevelCheckState) =>
        match psKernelLevelCheckStep state with
        | PsKernelLevelCheckStep.final result => result
        | PsKernelLevelCheckStep.next next =>
            let smaller : PsKernelLevelCheckState -> PsKernelLevelCheckResult := psKernelLevelCheckRun remaining;
            smaller next
