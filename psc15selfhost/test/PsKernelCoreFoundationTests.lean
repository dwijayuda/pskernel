import KernelCore.Foundation.KernelContract
import KernelCore.Foundation.AdmissionRuntime
import KernelCore.Foundation.CheckerOps

def main : IO Unit :=
  if !psKernelContractTests then
    throw (IO.userError "PSC1_KERNEL_CONTRACT_V1: FAIL")
  else if !psKernelCheckerOpsTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_CHECKER_OPS_CONFORMANCE: FAIL")
  else if !psKernelCoreNameTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_NAME_DIFFERENTIAL: FAIL")
  else if !psKernelCoreLevelTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_LEVEL_DIFFERENTIAL: FAIL")
  else if !psKernelCoreExprTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_EXPR_DIFFERENTIAL: FAIL")
  else if !psKernelCoreInstantiateTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_INSTANTIATE_DIFFERENTIAL: FAIL")
  else if !psKernelCorePrimitiveTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_PRIMITIVE_DIFFERENTIAL: FAIL")
  else if !psKernelDefEqSpecialRuleTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_DEFEQ_SPECIAL_CONFORMANCE: FAIL")
  else if !psKernelCoreQuotTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_QUOT_CONFORMANCE: FAIL")
  else if !psKernelAdmissionConformanceTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_ADMISSION_CONFORMANCE: FAIL")
  else if !psKernelRuntimeInvariantTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_RUNTIME_INVARIANT: FAIL")
  else if !psKernelCoreWhnfTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_WHNF_DIFFERENTIAL: FAIL")
  else if !psKernelCoreInferTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_INFER_DIFFERENTIAL: FAIL")
  else if !psKernelCoreProjectionTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_PROJECTION_DIFFERENTIAL: FAIL")
  else if !psKernelCoreRecursorTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_RECURSOR_DIFFERENTIAL: FAIL")
  else if !psKernelCoreDefEqTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_DEFEQ_DIFFERENTIAL: FAIL")
  else if !psKernelCoreNestedTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_NESTED_DIFFERENTIAL: FAIL")
  else if !psKernelCoreNestedMultiFamilyTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_NESTED_MULTI_FAMILY_CONFORMANCE: FAIL")
  else if !psKernelCoreNestedRejectionTests then
    throw
      (IO.userError
        "PSC1_KERNEL_CORE_NESTED_REJECTION_DIFFERENTIAL: FAIL")
  else
    IO.println
      "PSC1_KERNEL_CORE_FOUNDATION_DIFFERENTIAL: PASS"
