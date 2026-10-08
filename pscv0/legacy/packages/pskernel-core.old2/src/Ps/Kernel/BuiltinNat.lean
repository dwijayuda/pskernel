import Ps.Kernel.Environment

/- Literal interpretation requires metadata produced by owned Nat admission.
Matching spelling alone, opaque constants and caller-supplied declarations do
not authorize primitive semantics. All lookups/comparisons share caller fuel. -/
def psKernelBuiltinNatName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.empty))))

def psKernelBuiltinNatZeroName : PsKernelName :=
  PsKernelName.str psKernelBuiltinNatName (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.empty)))))

def psKernelBuiltinNatSuccName : PsKernelName :=
  PsKernelName.str psKernelBuiltinNatName (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.one)))))))) (PsKernelText.empty)))))

inductive PsKernelBuiltinNatState where
  | lookup (state : PsKernelLookupState)
  | names (tasks : PsKernelList PsKernelOrderTask)

inductive PsKernelBuiltinNatStep where
  | next (state : PsKernelBuiltinNatState)
  | ready
  | rejected (error : PsKernelCheckError)

def psKernelBuiltinNatStart (env : PsKernelList PsKernelDefinition) : PsKernelBuiltinNatState :=
  PsKernelBuiltinNatState.lookup (PsKernelLookupState.search psKernelBuiltinNatName env)

def psKernelBuiltinNatStep (state : PsKernelBuiltinNatState) : PsKernelBuiltinNatStep :=
  match state with
  | PsKernelBuiltinNatState.lookup current =>
      match psKernelLookupStep current with
      | PsKernelLookupStep.next next => PsKernelBuiltinNatStep.next (PsKernelBuiltinNatState.lookup next)
      | PsKernelLookupStep.missing => PsKernelBuiltinNatStep.rejected PsKernelCheckError.unknownConstant
      | PsKernelLookupStep.invalidState => PsKernelBuiltinNatStep.rejected PsKernelCheckError.invalidState
      | PsKernelLookupStep.found entry =>
          match entry with
          | PsKernelDefinition.natFamily unusedName zeroName succName => PsKernelBuiltinNatStep.next
              (PsKernelBuiltinNatState.names (PsKernelList.cons (PsKernelOrderTask.name zeroName psKernelBuiltinNatZeroName)
                (PsKernelList.cons (PsKernelOrderTask.name succName psKernelBuiltinNatSuccName) PsKernelList.nil)))
          | _ => PsKernelBuiltinNatStep.rejected PsKernelCheckError.unsupported
  | PsKernelBuiltinNatState.names current =>
      match psKernelOrderStep current with
      | PsKernelOrderStep.next next => PsKernelBuiltinNatStep.next (PsKernelBuiltinNatState.names next)
      | PsKernelOrderStep.invalidState => PsKernelBuiltinNatStep.rejected PsKernelCheckError.invalidState
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same => PsKernelBuiltinNatStep.ready
          | _ => PsKernelBuiltinNatStep.rejected PsKernelCheckError.unsupported
