import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Order

/- Internal monomorphic definitions. A list is NOT a trusted environment merely
because it has this representation. Only fresh replay through Admission checks it. -/
inductive PsKernelDefinition where
  | definition (name : PsKernelName) (type : PsKernelExpr) (value : PsKernelExpr)

inductive PsKernelCheckError where
  | invalidState
  | invalidScope
  | unknownConstant
  | unsupported
  | typeExpected
  | functionExpected
  | typeMismatch
  | duplicateName
  | invalidName

inductive PsKernelLookupState where
  | search (name : PsKernelName) (entries : PsKernelList PsKernelDefinition)
  | compare (name : PsKernelName) (entry : PsKernelDefinition)
      (rest : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelOrderTask)

inductive PsKernelLookupStep where
  | next (state : PsKernelLookupState)
  | found (entry : PsKernelDefinition)
  | missing
  | invalidState

def psKernelLookupStep (state : PsKernelLookupState) : PsKernelLookupStep :=
  match state with
  | PsKernelLookupState.search name entries =>
      match entries with
      | PsKernelList.nil => PsKernelLookupStep.missing
      | PsKernelList.cons entry rest =>
          match entry with
          | PsKernelDefinition.definition candidate unusedType unusedValue =>
              PsKernelLookupStep.next (PsKernelLookupState.compare name entry rest
                (PsKernelList.cons (PsKernelOrderTask.name name candidate) PsKernelList.nil))
  | PsKernelLookupState.compare name entry rest tasks =>
      match psKernelOrderStep tasks with
      | PsKernelOrderStep.next next =>
          PsKernelLookupStep.next (PsKernelLookupState.compare name entry rest next)
      | PsKernelOrderStep.invalidState => PsKernelLookupStep.invalidState
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same => PsKernelLookupStep.found entry
          | _ => PsKernelLookupStep.next (PsKernelLookupState.search name rest)
