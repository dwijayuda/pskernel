import Ps.Kernel.JointAdmission

/- The initial Nat prelude is generated source data submitted to the same owned
inductive checker. No assumed environment or caller-supplied builtin constants.
Nat literals require checked Nat metadata. The fixed intrinsic String type is
installed next; arithmetic and String operations remain unsupported. -/
def psKernelBootstrapNatName : PsKernelName := psKernelBuiltinNatName

def psKernelBootstrapNat : PsKernelNatDeclaration :=
  PsKernelNatDeclaration.declaration psKernelBuiltinNatName psKernelNatFamilySort
    psKernelBuiltinNatZeroName (psKernelNatExpectedConstructor psKernelBuiltinNatName PsKernelNatPhase.zero)
    psKernelBuiltinNatSuccName (psKernelNatExpectedConstructor psKernelBuiltinNatName PsKernelNatPhase.succ)

inductive PsKernelBootstrapState where
  | prelude (entries : PsKernelList PsKernelJointEntry) (state : PsKernelNatAdmissionState)
  | textPrelude (entries : PsKernelList PsKernelJointEntry) (state : PsKernelStringPreludeState)
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
              (PsKernelBootstrapState.textPrelude entries (psKernelStringPreludeStart env))
          | _ => PsKernelBootstrapStep.final result
  | PsKernelBootstrapState.textPrelude entries current =>
      match psKernelStringPreludeStep current with
      | PsKernelStringPreludeStep.next next => PsKernelBootstrapStep.next (PsKernelBootstrapState.textPrelude entries next)
      | PsKernelStringPreludeStep.ready env => PsKernelBootstrapStep.next
          (PsKernelBootstrapState.declarations (PsKernelJointState.pending env entries))
      | PsKernelStringPreludeStep.rejected error => PsKernelBootstrapStep.final (PsKernelAdmissionResult.rejected error)
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
