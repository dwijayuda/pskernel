import Ps.Kernel.Binding
import Ps.Kernel.AlgebraicData

/- Close fresh internal variables, innermost binder first. The existing binding
machine performs capture-avoiding abstraction one charged transition at a time. -/
inductive PsKernelCloseMode where
  | pi
  | lambda

inductive PsKernelCloseTask where
  | binders (pending : PsKernelList PsKernelAlgBinder) (value : PsKernelExpr)
  | abstract (binder : PsKernelAlgBinder) (pending : PsKernelList PsKernelAlgBinder)
      (state : PsKernelBindingState)

inductive PsKernelCloseState where
  | state (mode : PsKernelCloseMode) (task : PsKernelCloseTask)

inductive PsKernelCloseStep where
  | next (state : PsKernelCloseState)
  | done (value : PsKernelExpr)
  | invalidState

inductive PsKernelCloseResult where
  | done (value : PsKernelExpr)
  | invalidState
  | outOfFuel

def psKernelCloseNext (mode : PsKernelCloseMode) (task : PsKernelCloseTask) : PsKernelCloseStep :=
  PsKernelCloseStep.next (PsKernelCloseState.state mode task)

def psKernelCloseStep (state : PsKernelCloseState) : PsKernelCloseStep :=
  match state with
  | PsKernelCloseState.state mode task =>
      match task with
      | PsKernelCloseTask.binders pending value =>
          match pending with
          | PsKernelList.nil => PsKernelCloseStep.done value
          | PsKernelList.cons binder rest =>
              match binder with
              | PsKernelAlgBinder.binder id unusedType unusedVisibility => psKernelCloseNext mode
                  (PsKernelCloseTask.abstract binder rest
                    (psKernelBindingStart (PsKernelBindingMode.abstract id) PsKernelNatural.zero value))
      | PsKernelCloseTask.abstract binder pending current =>
          match psKernelBindingStep current with
          | PsKernelBindingStep.next next => psKernelCloseNext mode (PsKernelCloseTask.abstract binder pending next)
          | PsKernelBindingStep.final result =>
              match result with
              | PsKernelBindingResult.done value =>
                  match binder with
                  | PsKernelAlgBinder.binder unusedId type visibility =>
                      match mode with
                      | PsKernelCloseMode.pi => psKernelCloseNext mode
                          (PsKernelCloseTask.binders pending (PsKernelExpr.forallE PsKernelName.anonymous type value visibility))
                      | PsKernelCloseMode.lambda => psKernelCloseNext mode
                          (PsKernelCloseTask.binders pending (PsKernelExpr.lam PsKernelName.anonymous type value visibility))
              | _ => PsKernelCloseStep.invalidState

def psKernelCloseStart (mode : PsKernelCloseMode) (reversedBinders : PsKernelList PsKernelAlgBinder)
    (value : PsKernelExpr) : PsKernelCloseState :=
  PsKernelCloseState.state mode (PsKernelCloseTask.binders reversedBinders value)

def psKernelCloseRun (fuel : PsKernelFuel) : PsKernelCloseState -> PsKernelCloseResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelCloseState) => PsKernelCloseResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelCloseState) =>
        match psKernelCloseStep state with
        | PsKernelCloseStep.done value => PsKernelCloseResult.done value
        | PsKernelCloseStep.invalidState => PsKernelCloseResult.invalidState
        | PsKernelCloseStep.next next =>
            let smaller : PsKernelCloseState -> PsKernelCloseResult := psKernelCloseRun remaining;
            smaller next
