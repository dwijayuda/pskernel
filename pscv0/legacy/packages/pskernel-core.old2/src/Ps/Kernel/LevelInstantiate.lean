import Ps.Kernel.Data
import Ps.Kernel.Order

/- Simultaneous universe instantiation with an explicitly declared parameter
context. Arity, nonanonymous names and uniqueness are checked before traversal.
An undeclared parameter is rejected. Replacements are inserted once, never
recursively substituted. Each name-comparison and traversal transition shares
the caller's budget. This operation alone grants no declaration authority. -/
inductive PsKernelLevelAssignment where
  | assignment (name : PsKernelName) (value : PsKernelLevel)

inductive PsKernelLevelInstantiateTask where
  | visit (value : PsKernelLevel)
  | succ
  | max
  | imax
  | lookup (name : PsKernelName) (remaining : PsKernelList PsKernelLevelAssignment)
  | compare (name : PsKernelName) (replacement : PsKernelLevel)
      (remaining : PsKernelList PsKernelLevelAssignment) (work : PsKernelList PsKernelOrderTask)

inductive PsKernelLevelInstantiateState where
  | parameters (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
      (assignments : PsKernelList PsKernelLevelAssignment) (target : PsKernelLevel)
  | unique (name : PsKernelName) (value : PsKernelLevel)
      (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
      (assignments : PsKernelList PsKernelLevelAssignment)
      (remaining : PsKernelList PsKernelLevelAssignment) (target : PsKernelLevel)
  | compare (name : PsKernelName) (value : PsKernelLevel)
      (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
      (assignments : PsKernelList PsKernelLevelAssignment)
      (remaining : PsKernelList PsKernelLevelAssignment) (target : PsKernelLevel)
      (work : PsKernelList PsKernelOrderTask)
  | running (assignments : PsKernelList PsKernelLevelAssignment)
      (tasks : PsKernelList PsKernelLevelInstantiateTask) (values : PsKernelList PsKernelLevel)

inductive PsKernelLevelInstantiateResult where
  | outOfFuel
  | invalidState
  | invalidParameters
  | undeclaredParameter
  | done (value : PsKernelLevel)

inductive PsKernelLevelInstantiateStep where
  | next (state : PsKernelLevelInstantiateState)
  | final (result : PsKernelLevelInstantiateResult)

def psKernelLevelInstantiateNext
    (assignments : PsKernelList PsKernelLevelAssignment)
    (tasks : PsKernelList PsKernelLevelInstantiateTask)
    (values : PsKernelList PsKernelLevel) : PsKernelLevelInstantiateStep :=
  PsKernelLevelInstantiateStep.next (PsKernelLevelInstantiateState.running assignments tasks values)

def psKernelLevelInstantiateVisit
    (assignments : PsKernelList PsKernelLevelAssignment) (value : PsKernelLevel)
    (rest : PsKernelList PsKernelLevelInstantiateTask)
    (values : PsKernelList PsKernelLevel) : PsKernelLevelInstantiateStep :=
  match value with
  | PsKernelLevel.zero => psKernelLevelInstantiateNext assignments rest (PsKernelList.cons value values)
  | PsKernelLevel.param name => psKernelLevelInstantiateNext assignments
      (PsKernelList.cons (PsKernelLevelInstantiateTask.lookup name assignments) rest) values
  | PsKernelLevel.succ inner => psKernelLevelInstantiateNext assignments
      (PsKernelList.cons (PsKernelLevelInstantiateTask.visit inner)
        (PsKernelList.cons PsKernelLevelInstantiateTask.succ rest)) values
  | PsKernelLevel.max left right => psKernelLevelInstantiateNext assignments
      (PsKernelList.cons (PsKernelLevelInstantiateTask.visit left)
        (PsKernelList.cons (PsKernelLevelInstantiateTask.visit right)
          (PsKernelList.cons PsKernelLevelInstantiateTask.max rest))) values
  | PsKernelLevel.imax left right => psKernelLevelInstantiateNext assignments
      (PsKernelList.cons (PsKernelLevelInstantiateTask.visit left)
        (PsKernelList.cons (PsKernelLevelInstantiateTask.visit right)
          (PsKernelList.cons PsKernelLevelInstantiateTask.imax rest))) values

def psKernelLevelInstantiateRebuild
    (assignments : PsKernelList PsKernelLevelAssignment) (task : PsKernelLevelInstantiateTask)
    (rest : PsKernelList PsKernelLevelInstantiateTask)
    (values : PsKernelList PsKernelLevel) : PsKernelLevelInstantiateStep :=
  match values with
  | PsKernelList.nil => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState
  | PsKernelList.cons right tail =>
      match task with
      | PsKernelLevelInstantiateTask.succ => psKernelLevelInstantiateNext assignments rest
          (PsKernelList.cons (PsKernelLevel.succ right) tail)
      | _ =>
          match tail with
          | PsKernelList.nil => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState
          | PsKernelList.cons left remaining =>
              match task with
              | PsKernelLevelInstantiateTask.max => psKernelLevelInstantiateNext assignments rest
                  (PsKernelList.cons (PsKernelLevel.max left right) remaining)
              | PsKernelLevelInstantiateTask.imax => psKernelLevelInstantiateNext assignments rest
                  (PsKernelList.cons (PsKernelLevel.imax left right) remaining)
              | _ => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState

def psKernelLevelInstantiateTaskStep
    (assignments : PsKernelList PsKernelLevelAssignment) (task : PsKernelLevelInstantiateTask)
    (rest : PsKernelList PsKernelLevelInstantiateTask)
    (values : PsKernelList PsKernelLevel) : PsKernelLevelInstantiateStep :=
  match task with
  | PsKernelLevelInstantiateTask.visit value => psKernelLevelInstantiateVisit assignments value rest values
  | PsKernelLevelInstantiateTask.lookup name remaining =>
      match remaining with
      | PsKernelList.nil => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.undeclaredParameter
      | PsKernelList.cons entry tail =>
          match entry with
          | PsKernelLevelAssignment.assignment candidate replacement =>
              psKernelLevelInstantiateNext assignments
                (PsKernelList.cons (PsKernelLevelInstantiateTask.compare name replacement tail
                  (PsKernelList.cons (PsKernelOrderTask.name name candidate) PsKernelList.nil)) rest) values
  | PsKernelLevelInstantiateTask.compare name replacement remaining work =>
      match psKernelOrderStep work with
      | PsKernelOrderStep.next next => psKernelLevelInstantiateNext assignments
          (PsKernelList.cons (PsKernelLevelInstantiateTask.compare name replacement remaining next) rest) values
      | PsKernelOrderStep.invalidState => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same => psKernelLevelInstantiateNext assignments rest (PsKernelList.cons replacement values)
          | _ => psKernelLevelInstantiateNext assignments
              (PsKernelList.cons (PsKernelLevelInstantiateTask.lookup name remaining) rest) values
  | _ => psKernelLevelInstantiateRebuild assignments task rest values

def psKernelLevelInstantiateStep (state : PsKernelLevelInstantiateState) : PsKernelLevelInstantiateStep :=
  match state with
  | PsKernelLevelInstantiateState.parameters names levels assignments target =>
      match names with
      | PsKernelList.nil =>
          match levels with
          | PsKernelList.nil => psKernelLevelInstantiateNext assignments
              (PsKernelList.cons (PsKernelLevelInstantiateTask.visit target) PsKernelList.nil) PsKernelList.nil
          | _ => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidParameters
      | PsKernelList.cons name rest =>
          match levels with
          | PsKernelList.nil => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidParameters
          | PsKernelList.cons value tail =>
              match name with
              | PsKernelName.anonymous => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidParameters
              | _ => PsKernelLevelInstantiateStep.next
                  (PsKernelLevelInstantiateState.unique name value rest tail assignments assignments target)
  | PsKernelLevelInstantiateState.unique name value names levels assignments remaining target =>
      match remaining with
      | PsKernelList.nil => PsKernelLevelInstantiateStep.next
          (PsKernelLevelInstantiateState.parameters names levels
            (PsKernelList.cons (PsKernelLevelAssignment.assignment name value) assignments) target)
      | PsKernelList.cons entry tail =>
          match entry with
          | PsKernelLevelAssignment.assignment candidate unusedValue => PsKernelLevelInstantiateStep.next
              (PsKernelLevelInstantiateState.compare name value names levels assignments tail target
                (PsKernelList.cons (PsKernelOrderTask.name name candidate) PsKernelList.nil))
  | PsKernelLevelInstantiateState.compare name value names levels assignments remaining target work =>
      match psKernelOrderStep work with
      | PsKernelOrderStep.next next => PsKernelLevelInstantiateStep.next
          (PsKernelLevelInstantiateState.compare name value names levels assignments remaining target next)
      | PsKernelOrderStep.invalidState => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidParameters
          | _ => PsKernelLevelInstantiateStep.next
              (PsKernelLevelInstantiateState.unique name value names levels assignments remaining target)
  | PsKernelLevelInstantiateState.running assignments tasks values =>
      match tasks with
      | PsKernelList.nil =>
          match values with
          | PsKernelList.nil => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState
          | PsKernelList.cons value rest =>
              match rest with
              | PsKernelList.nil => PsKernelLevelInstantiateStep.final (PsKernelLevelInstantiateResult.done value)
              | _ => PsKernelLevelInstantiateStep.final PsKernelLevelInstantiateResult.invalidState
      | PsKernelList.cons task rest => psKernelLevelInstantiateTaskStep assignments task rest values

def psKernelLevelInstantiateStart
    (names : PsKernelList PsKernelName) (levels : PsKernelList PsKernelLevel)
    (target : PsKernelLevel) : PsKernelLevelInstantiateState :=
  PsKernelLevelInstantiateState.parameters names levels PsKernelList.nil target

def psKernelLevelInstantiateRun (fuel : PsKernelFuel) : PsKernelLevelInstantiateState -> PsKernelLevelInstantiateResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelLevelInstantiateState) => PsKernelLevelInstantiateResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelLevelInstantiateState) =>
        match psKernelLevelInstantiateStep state with
        | PsKernelLevelInstantiateStep.final result => result
        | PsKernelLevelInstantiateStep.next next =>
            let smaller : PsKernelLevelInstantiateState -> PsKernelLevelInstantiateResult := psKernelLevelInstantiateRun remaining;
            smaller next
