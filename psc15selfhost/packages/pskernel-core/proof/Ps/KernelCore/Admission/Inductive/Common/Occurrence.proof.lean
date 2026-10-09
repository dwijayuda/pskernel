import Ps.KernelCore.Metatheory.AdmissionNoTargetOccurrenceConfiguration
import Ps.KernelCore.Metatheory.AdmissionUniformOccurrenceConfiguration

/-
Canonical source/proof companion.  The standalone metatheory module now owns
these reusable soundness proofs so concrete admission refinement may import
them without copying the large fuel induction.  The source implementation is
unchanged; all proofs retain their original names and statements.
-/

#check psKernelSimpleCheckUniformOccurrenceHead_true_refines
#check psKernelSimpleCheckUniformOccurrenceWithFuel_success_refines
#check psKernelSimpleCheckUniformOccurrence_success_refines
#check psKernelSimpleCheckUniformOccurrences_success_refines

#print axioms psKernelExprContainsConst_false_concrete_absence
#print axioms psKernelValidateSimpleConstructorResult_concrete_indices_absent
