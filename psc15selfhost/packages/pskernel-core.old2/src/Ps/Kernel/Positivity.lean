import Ps.Kernel.Occurrence
import Ps.Kernel.Environment
import Ps.Kernel.ExpressionEquality

/- Type0 uniform algebraic fragment. All free variables must first have been
checked as the declared type parameters. A relevant occurrence is permitted only
as a parameter, the uniform recursive family, or an argument of a previously
validated covariant algebraic family. Negative and unknown functor uses reject. -/
inductive PsKernelPositiveFieldTask where
  | fields (pending : PsKernelList PsKernelExpr)
  | occurrence (value : PsKernelExpr) (pending : PsKernelList PsKernelExpr)
      (state : PsKernelOccurrenceState)
  | uniform (value : PsKernelExpr) (pending : PsKernelList PsKernelExpr)
      (state : PsKernelExprEqualState)
  | spine (value : PsKernelExpr) (arguments pending : PsKernelList PsKernelExpr)
  | lookup (arguments pending : PsKernelList PsKernelExpr) (state : PsKernelLookupState)
  | arity (remaining : PsKernelNatural) (arguments pending : PsKernelList PsKernelExpr)

inductive PsKernelPositiveFieldState where
  | state (environment : PsKernelList PsKernelDefinition) (family : PsKernelName)
      (uniform : PsKernelExpr) (task : PsKernelPositiveFieldTask)

inductive PsKernelPositiveFieldStep where
  | next (state : PsKernelPositiveFieldState)
  | accepted
  | rejected (error : PsKernelCheckError)

inductive PsKernelPositiveFieldResult where
  | accepted
  | rejected (error : PsKernelCheckError)
  | outOfFuel

def psKernelPositiveFieldNext (env : PsKernelList PsKernelDefinition)
    (family : PsKernelName) (uniform : PsKernelExpr) (task : PsKernelPositiveFieldTask) : PsKernelPositiveFieldStep :=
  PsKernelPositiveFieldStep.next (PsKernelPositiveFieldState.state env family uniform task)

def psKernelPositiveFieldStep (state : PsKernelPositiveFieldState) : PsKernelPositiveFieldStep :=
  match state with
  | PsKernelPositiveFieldState.state env family uniform task =>
      match task with
      | PsKernelPositiveFieldTask.fields pending =>
          match pending with
          | PsKernelList.nil => PsKernelPositiveFieldStep.accepted
          | PsKernelList.cons value rest => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.occurrence value rest (psKernelOccurrenceStart family PsKernelFlag.yes value))
      | PsKernelPositiveFieldTask.occurrence value pending current =>
          match psKernelOccurrenceStep current with
          | PsKernelOccurrenceStep.next next => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.occurrence value pending next)
          | PsKernelOccurrenceStep.absent => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.fields pending)
          | PsKernelOccurrenceStep.found =>
              match value with
              | PsKernelExpr.fvar unused => psKernelPositiveFieldNext env family uniform
                  (PsKernelPositiveFieldTask.fields pending)
              | _ => psKernelPositiveFieldNext env family uniform
                  (PsKernelPositiveFieldTask.uniform value pending (psKernelExprEqualStart value uniform))
          | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.invalidState
      | PsKernelPositiveFieldTask.uniform value pending current =>
          match psKernelExprEqualStep current with
          | PsKernelExprEqualStep.next next => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.uniform value pending next)
          | PsKernelExprEqualStep.equal => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.fields pending)
          | PsKernelExprEqualStep.different => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.spine value PsKernelList.nil pending)
          | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.invalidState
      | PsKernelPositiveFieldTask.spine value arguments pending =>
          match value with
          | PsKernelExpr.app fn arg => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.spine fn (PsKernelList.cons arg arguments) pending)
          | PsKernelExpr.constE name levels =>
              match levels with
              | PsKernelList.nil => psKernelPositiveFieldNext env family uniform
                  (PsKernelPositiveFieldTask.lookup arguments pending (PsKernelLookupState.search name env))
              | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.unsupported
          | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.unsupported
      | PsKernelPositiveFieldTask.lookup arguments pending current =>
          match psKernelLookupStep current with
          | PsKernelLookupStep.next next => psKernelPositiveFieldNext env family uniform
              (PsKernelPositiveFieldTask.lookup arguments pending next)
          | PsKernelLookupStep.found entry =>
              match entry with
              | PsKernelDefinition.algebraicFamily unusedName unusedType parameters unusedConstructors => psKernelPositiveFieldNext env family uniform
                  (PsKernelPositiveFieldTask.arity parameters arguments pending)
              | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.unsupported
          | PsKernelLookupStep.missing => PsKernelPositiveFieldStep.rejected PsKernelCheckError.unknownConstant
          | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.invalidState
      | PsKernelPositiveFieldTask.arity remaining arguments pending =>
          match remaining with
          | PsKernelNatural.zero =>
              match arguments with
              | PsKernelList.nil => psKernelPositiveFieldNext env family uniform (PsKernelPositiveFieldTask.fields pending)
              | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.typeMismatch
          | _ =>
              match arguments with
              | PsKernelList.cons argument rest => psKernelPositiveFieldNext env family uniform
                  (PsKernelPositiveFieldTask.arity (psKernelNaturalPred remaining) rest (PsKernelList.cons argument pending))
              | _ => PsKernelPositiveFieldStep.rejected PsKernelCheckError.typeMismatch

def psKernelPositiveFieldStart (env : PsKernelList PsKernelDefinition) (family : PsKernelName)
    (uniform value : PsKernelExpr) : PsKernelPositiveFieldState :=
  PsKernelPositiveFieldState.state env family uniform
    (PsKernelPositiveFieldTask.fields (PsKernelList.cons value PsKernelList.nil))

def psKernelPositiveFieldRun (fuel : PsKernelFuel) : PsKernelPositiveFieldState -> PsKernelPositiveFieldResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelPositiveFieldState) => PsKernelPositiveFieldResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelPositiveFieldState) =>
        match psKernelPositiveFieldStep state with
        | PsKernelPositiveFieldStep.accepted => PsKernelPositiveFieldResult.accepted
        | PsKernelPositiveFieldStep.rejected error => PsKernelPositiveFieldResult.rejected error
        | PsKernelPositiveFieldStep.next next =>
            let smaller : PsKernelPositiveFieldState -> PsKernelPositiveFieldResult := psKernelPositiveFieldRun remaining;
            smaller next
