import Ps.Kernel.NatInductive

/- The only mixed admission entry point starts with an empty environment.
Each declaration uses the same outer transition budget. Partial state is private
to the driver; rejection and exhaustion expose no environment. -/
inductive PsKernelJointEntry where
  | definition (entry : PsKernelDefinition)
  | unitInductive (entry : PsKernelUnitDeclaration)
  | natInductive (entry : PsKernelNatDeclaration)

inductive PsKernelJointState where
  | pending (environment : PsKernelList PsKernelDefinition) (entries : PsKernelList PsKernelJointEntry)
  | definition (rest : PsKernelList PsKernelJointEntry) (state : PsKernelAdmissionState)
  | unitInductive (rest : PsKernelList PsKernelJointEntry) (state : PsKernelUnitState)
  | natInductive (rest : PsKernelList PsKernelJointEntry) (state : PsKernelNatAdmissionState)

inductive PsKernelJointStep where
  | next (state : PsKernelJointState)
  | final (result : PsKernelAdmissionResult)

def psKernelJointContinue (rest : PsKernelList PsKernelJointEntry) (result : PsKernelAdmissionResult) : PsKernelJointStep :=
  match result with
  | PsKernelAdmissionResult.admitted env => PsKernelJointStep.next (PsKernelJointState.pending env rest)
  | _ => PsKernelJointStep.final result

def psKernelJointStep (state : PsKernelJointState) : PsKernelJointStep :=
  match state with
  | PsKernelJointState.pending env entries =>
      match entries with
      | PsKernelList.nil => PsKernelJointStep.final (PsKernelAdmissionResult.admitted env)
      | PsKernelList.cons entry rest =>
          match entry with
          | PsKernelJointEntry.definition definition => PsKernelJointStep.next
              (PsKernelJointState.definition rest (PsKernelAdmissionState.pending env (PsKernelList.cons definition PsKernelList.nil)))
          | PsKernelJointEntry.unitInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.unitInductive rest (psKernelUnitStart env declaration))
          | PsKernelJointEntry.natInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.natInductive rest (psKernelNatAdmissionStart env declaration))
  | PsKernelJointState.definition rest current =>
      match psKernelAdmissionStep current with
      | PsKernelAdmissionStep.next next => PsKernelJointStep.next (PsKernelJointState.definition rest next)
      | PsKernelAdmissionStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.unitInductive rest current =>
      match psKernelUnitStep current with
      | PsKernelUnitStep.next next => PsKernelJointStep.next (PsKernelJointState.unitInductive rest next)
      | PsKernelUnitStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.natInductive rest current =>
      match psKernelNatAdmissionStep current with
      | PsKernelNatAdmissionStep.next next => PsKernelJointStep.next (PsKernelJointState.natInductive rest next)
      | PsKernelNatAdmissionStep.final result => psKernelJointContinue rest result

def psKernelJointStart (entries : PsKernelList PsKernelJointEntry) : PsKernelJointState :=
  PsKernelJointState.pending PsKernelList.nil entries

def psKernelJointRun (fuel : PsKernelFuel) : PsKernelJointState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelJointState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelJointState) =>
        match psKernelJointStep state with
        | PsKernelJointStep.final result => result
        | PsKernelJointStep.next next =>
            let smaller : PsKernelJointState -> PsKernelAdmissionResult := psKernelJointRun remaining;
            smaller next
