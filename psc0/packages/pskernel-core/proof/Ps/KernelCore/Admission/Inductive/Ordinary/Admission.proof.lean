import Ps.KernelCore.Metatheory.AdmissionOrdinaryTransactionConfiguration
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission

theorem psKernelCheckFreshInductiveNames_nil
    (environment : PsKernelEnvironment) :
    psKernelCheckFreshInductiveNames List.nil environment =
      Except.ok Unit.unit := by
  rfl

#print axioms psKernelAddSimpleInductive_concrete_transaction_refines
