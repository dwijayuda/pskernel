import Ps.KernelCore.API.Dag

/- Actual mutual routing equations. Public resource/capability/atomic-publication
   protocol is the unchanged generic worker, covered by all retained ordinary
   public proofs. These equations do not certify forged internal owners. -/
namespace PsKernelMutualAdmissionPublicProofs
variable (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
  (levels : List PsKernelName) (safety : PsKernelDefinitionSafety)
  (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
  (value : PsKernelDagInductiveGroup)

theorem original_boundary_decode_failure_precedes_all_mutual_work
    (error : String)
    (failed : psKernelDagDecodeDeclaration input (.mutualInductive value) = Except.error error) :
    psKernelDagRunOwnedCommandWithSource input execution levels safety arena built
      (.admit (.mutualInductive value)) = Except.error (PsKernelError.rejectedInvalid error) := by
  simp only [psKernelDagRunOwnedCommandWithSource, failed]

theorem complete_mutual_result_enters_original_public_transaction
    (declaration : PsKernelDeclarationRequest)
    (decoded : psKernelDagDecodeDeclaration input (.mutualInductive value) = Except.ok declaration) :
    psKernelDagRunOwnedCommandWithSource input execution levels safety arena built
      (.admit (.mutualInductive value)) =
      psKernelDagRunOrdinaryOwnedWith
        (fun owner => psKernelExprV2MutualAdmitWithFuel execution.session.resources.fuel
          (psKernelKernelSessionEnvironment execution.session)
          execution.session.resources.maxRecDepth execution.session.resources.maxNatSize input owner value)
        input execution levels safety arena built (.mutualInductive value) declaration := by
  simp only [psKernelDagRunOwnedCommandWithSource, decoded]

#print axioms original_boundary_decode_failure_precedes_all_mutual_work
#print axioms complete_mutual_result_enters_original_public_transaction
end PsKernelMutualAdmissionPublicProofs
