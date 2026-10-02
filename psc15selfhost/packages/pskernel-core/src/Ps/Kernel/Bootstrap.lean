import Ps.Kernel.JointAdmission

/- The initial Nat prelude is generated source data submitted to the same owned
inductive checker. No assumed environment or caller-supplied builtin constants.
Literal and arithmetic primitive semantics remain unsupported. -/
def psKernelBootstrapNatName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) PsKernelText.empty)))

def psKernelBootstrapNat : PsKernelNatDeclaration :=
  PsKernelNatDeclaration.declaration psKernelBootstrapNatName psKernelNatFamilySort
    (PsKernelName.str psKernelBootstrapNatName (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) PsKernelText.empty)))))
    (psKernelNatExpectedConstructor psKernelBootstrapNatName PsKernelNatPhase.zero)
    (PsKernelName.str psKernelBootstrapNatName (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) PsKernelText.empty)))))
    (psKernelNatExpectedConstructor psKernelBootstrapNatName PsKernelNatPhase.succ)

inductive PsKernelBootstrapState where
  | prelude (entries : PsKernelList PsKernelJointEntry) (state : PsKernelNatAdmissionState)
  | declarations (state : PsKernelJointState)

inductive PsKernelBootstrapStep where
  | next (state : PsKernelBootstrapState)
  | final (result : PsKernelAdmissionResult)

def psKernelBootstrapStep (state : PsKernelBootstrapState) : PsKernelBootstrapStep :=
  match state with
  | PsKernelBootstrapState.prelude entries current =>
      match psKernelNatAdmissionStep current with
      | PsKernelNatAdmissionStep.next next => PsKernelBootstrapStep.next (PsKernelBootstrapState.prelude entries next)
      | PsKernelNatAdmissionStep.final result =>
          match result with
          | PsKernelAdmissionResult.admitted env => PsKernelBootstrapStep.next
              (PsKernelBootstrapState.declarations (PsKernelJointState.pending env entries))
          | _ => PsKernelBootstrapStep.final result
  | PsKernelBootstrapState.declarations current =>
      match psKernelJointStep current with
      | PsKernelJointStep.next next => PsKernelBootstrapStep.next (PsKernelBootstrapState.declarations next)
      | PsKernelJointStep.final result => PsKernelBootstrapStep.final result

def psKernelBootstrapStart (entries : PsKernelList PsKernelJointEntry) : PsKernelBootstrapState :=
  PsKernelBootstrapState.prelude entries (psKernelNatAdmissionStart PsKernelList.nil psKernelBootstrapNat)

def psKernelBootstrapRun (fuel : PsKernelFuel) : PsKernelBootstrapState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelBootstrapState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelBootstrapState) =>
        match psKernelBootstrapStep state with
        | PsKernelBootstrapStep.final result => result
        | PsKernelBootstrapStep.next next =>
            let smaller : PsKernelBootstrapState -> PsKernelAdmissionResult := psKernelBootstrapRun remaining;
            smaller next
