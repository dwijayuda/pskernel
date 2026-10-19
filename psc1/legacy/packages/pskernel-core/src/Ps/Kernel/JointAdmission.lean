import Ps.Kernel.NatInductive
import Ps.Kernel.RecordInductive
import Ps.Kernel.EnumInductive
import Ps.Kernel.SumInductive
import Ps.Kernel.AlgebraicAdmission

/- The only mixed admission entry point starts with an empty environment.
Each declaration uses the same outer transition budget. Partial state is private
to the driver; rejection and exhaustion expose no environment. -/
inductive PsKernelJointEntry where
  | algebraic (entry : PsKernelAlgDeclaration)
  | definition (entry : PsKernelDefinition)
  | unitInductive (entry : PsKernelUnitDeclaration)
  | recordInductive (entry : PsKernelUnitDeclaration)
  | enumInductive (entry : PsKernelEnumDeclaration)
  | sumInductive (entry : PsKernelEnumDeclaration)
  | natInductive (entry : PsKernelNatDeclaration)

inductive PsKernelJointState where
  | algebraic (rest : PsKernelList PsKernelJointEntry) (state : PsKernelAlgAdmissionState)
  | pending (environment : PsKernelList PsKernelDefinition) (entries : PsKernelList PsKernelJointEntry)
  | definition (rest : PsKernelList PsKernelJointEntry) (state : PsKernelAdmissionState)
  | unitInductive (rest : PsKernelList PsKernelJointEntry) (state : PsKernelUnitState)
  | recordInductive (rest : PsKernelList PsKernelJointEntry) (state : PsKernelRecordState)
  | enumInductive (rest : PsKernelList PsKernelJointEntry) (state : PsKernelEnumState)
  | sumInductive (rest : PsKernelList PsKernelJointEntry) (state : PsKernelSumState)
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
          | PsKernelJointEntry.algebraic declaration => PsKernelJointStep.next
              (PsKernelJointState.algebraic rest (psKernelAlgAdmissionStart env declaration))
          | PsKernelJointEntry.definition definition => PsKernelJointStep.next
              (PsKernelJointState.definition rest (PsKernelAdmissionState.pending env (PsKernelList.cons definition PsKernelList.nil)))
          | PsKernelJointEntry.unitInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.unitInductive rest (psKernelUnitStart env declaration))
          | PsKernelJointEntry.recordInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.recordInductive rest (psKernelRecordStart env declaration))
          | PsKernelJointEntry.enumInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.enumInductive rest (psKernelEnumStart env declaration))
          | PsKernelJointEntry.sumInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.sumInductive rest (psKernelSumStart env declaration))
          | PsKernelJointEntry.natInductive declaration => PsKernelJointStep.next
              (PsKernelJointState.natInductive rest (psKernelNatAdmissionStart env declaration))
  | PsKernelJointState.algebraic rest current =>
      match psKernelAlgAdmissionStep current with
      | PsKernelAlgAdmissionStep.next next => PsKernelJointStep.next (PsKernelJointState.algebraic rest next)
      | PsKernelAlgAdmissionStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.definition rest current =>
      match psKernelAdmissionStep current with
      | PsKernelAdmissionStep.next next => PsKernelJointStep.next (PsKernelJointState.definition rest next)
      | PsKernelAdmissionStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.unitInductive rest current =>
      match psKernelUnitStep current with
      | PsKernelUnitStep.next next => PsKernelJointStep.next (PsKernelJointState.unitInductive rest next)
      | PsKernelUnitStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.recordInductive rest current =>
      match psKernelRecordStep current with
      | PsKernelRecordStep.next next => PsKernelJointStep.next (PsKernelJointState.recordInductive rest next)
      | PsKernelRecordStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.enumInductive rest current =>
      match psKernelEnumStep current with
      | PsKernelEnumStep.next next => PsKernelJointStep.next (PsKernelJointState.enumInductive rest next)
      | PsKernelEnumStep.final result => psKernelJointContinue rest result
  | PsKernelJointState.sumInductive rest current =>
      match psKernelSumStep current with
      | PsKernelSumStep.next next => PsKernelJointStep.next (PsKernelJointState.sumInductive rest next)
      | PsKernelSumStep.final result => psKernelJointContinue rest result
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
