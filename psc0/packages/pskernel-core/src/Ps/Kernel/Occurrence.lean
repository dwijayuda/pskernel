import Ps.Kernel.Expr
import Ps.Kernel.Order

/- A conservative occurrence scan. Free variables are relevant only when checking
covariance in the already scope-checked constructor parameter context. -/
inductive PsKernelOccurrenceTask where
  | visit (value : PsKernelExpr)
  | name (work : PsKernelList PsKernelOrderTask)

inductive PsKernelOccurrenceState where
  | state (family : PsKernelName) (parameters : PsKernelFlag)
      (tasks : PsKernelList PsKernelOccurrenceTask)

inductive PsKernelOccurrenceStep where
  | next (state : PsKernelOccurrenceState)
  | found
  | absent
  | invalidState

def psKernelOccurrenceNext (family : PsKernelName) (parameters : PsKernelFlag)
    (tasks : PsKernelList PsKernelOccurrenceTask) : PsKernelOccurrenceStep :=
  PsKernelOccurrenceStep.next (PsKernelOccurrenceState.state family parameters tasks)

def psKernelOccurrenceStep (state : PsKernelOccurrenceState) : PsKernelOccurrenceStep :=
  match state with
  | PsKernelOccurrenceState.state family parameters tasks =>
      match tasks with
      | PsKernelList.nil => PsKernelOccurrenceStep.absent
      | PsKernelList.cons task rest =>
          match task with
          | PsKernelOccurrenceTask.name current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.name next) rest)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => PsKernelOccurrenceStep.found
                  | _ => psKernelOccurrenceNext family parameters rest
              | _ => PsKernelOccurrenceStep.invalidState
          | PsKernelOccurrenceTask.visit value =>
              match value with
              | PsKernelExpr.fvar unused =>
                  match parameters with
                  | PsKernelFlag.yes => PsKernelOccurrenceStep.found
                  | PsKernelFlag.no => psKernelOccurrenceNext family parameters rest
              | PsKernelExpr.constE name unusedLevels => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.name
                    (PsKernelList.cons (PsKernelOrderTask.name name family) PsKernelList.nil)) rest)
              | PsKernelExpr.app fn arg => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.visit fn)
                    (PsKernelList.cons (PsKernelOccurrenceTask.visit arg) rest))
              | PsKernelExpr.lam unusedName type body unusedBinder => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.visit type)
                    (PsKernelList.cons (PsKernelOccurrenceTask.visit body) rest))
              | PsKernelExpr.forallE unusedName type body unusedBinder => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.visit type)
                    (PsKernelList.cons (PsKernelOccurrenceTask.visit body) rest))
              | PsKernelExpr.letE unusedName type val body => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.visit type)
                    (PsKernelList.cons (PsKernelOccurrenceTask.visit val)
                      (PsKernelList.cons (PsKernelOccurrenceTask.visit body) rest)))
              | PsKernelExpr.proj name unusedIndex major => psKernelOccurrenceNext family parameters
                  (PsKernelList.cons (PsKernelOccurrenceTask.name
                    (PsKernelList.cons (PsKernelOrderTask.name name family) PsKernelList.nil))
                    (PsKernelList.cons (PsKernelOccurrenceTask.visit major) rest))
              | _ => psKernelOccurrenceNext family parameters rest

def psKernelOccurrenceStart (family : PsKernelName) (parameters : PsKernelFlag)
    (value : PsKernelExpr) : PsKernelOccurrenceState :=
  PsKernelOccurrenceState.state family parameters
    (PsKernelList.cons (PsKernelOccurrenceTask.visit value) PsKernelList.nil)
