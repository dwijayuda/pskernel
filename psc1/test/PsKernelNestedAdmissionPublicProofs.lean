import Ps.KernelCore.API.Dag

/- Actual nested routing equations. Public resource/capability/atomic-publication
   protocol is the unchanged generic worker, covered by all retained ordinary
   public proofs. These equations do not certify forged internal owners. -/
namespace PsKernelNestedAdmissionPublicProofs
variable (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
  (levels : List PsKernelName) (safety : PsKernelDefinitionSafety)
  (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
  (value : PsKernelDagInductiveGroup)

theorem original_boundary_decode_failure_precedes_all_nested_work
    (error : String)
    (failed : psKernelDagDecodeDeclaration input (.nestedInductive value) = Except.error error) :
    psKernelDagRunOwnedCommandWithSource input execution levels safety arena built
      (.admit (.nestedInductive value)) = Except.error (PsKernelError.rejectedInvalid error) := by
  simp only [psKernelDagRunOwnedCommandWithSource, failed]

theorem complete_nested_result_enters_original_public_transaction
    (declaration : PsKernelDeclarationRequest)
    (decoded : psKernelDagDecodeDeclaration input (.nestedInductive value) = Except.ok declaration) :
    psKernelDagRunOwnedCommandWithSource input execution levels safety arena built
      (.admit (.nestedInductive value)) =
      psKernelDagRunOrdinaryOwnedWith
        (fun owner => psKernelExprV2NestedAdmitWithFuel execution.session.resources.fuel
          (psKernelKernelSessionEnvironment execution.session)
          execution.session.resources.maxRecDepth execution.session.resources.maxNatSize input owner value)
        input execution levels safety arena built (.nestedInductive value) declaration := by
  simp only [psKernelDagRunOwnedCommandWithSource, decoded]

#print axioms original_boundary_decode_failure_precedes_all_nested_work
#print axioms complete_nested_result_enters_original_public_transaction
end PsKernelNestedAdmissionPublicProofs
