import KernelSelfHost.Foundation.KernelContract
import KernelSelfHost.Foundation.AdmissionRuntime
import KernelSelfHost.Foundation.CheckerOps

def main : IO Unit :=
  if !psKernelContractTests then
    throw (IO.userError "PSC1_KERNEL_CONTRACT_V1: FAIL")
  else if !psKernelCheckerOpsTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_CHECKER_OPS_CONFORMANCE: FAIL")
  else if !psKernelSelfHostNameTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NAME_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostLevelTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_LEVEL_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostExprTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_EXPR_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostInstantiateTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_INSTANTIATE_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostPrimitiveTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_PRIMITIVE_DIFFERENTIAL: FAIL")
  else if !psKernelDefEqSpecialRuleTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_DEFEQ_SPECIAL_CONFORMANCE: FAIL")
  else if !psKernelSelfHostQuotTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_QUOT_CONFORMANCE: FAIL")
  else if !psKernelAdmissionConformanceTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_ADMISSION_CONFORMANCE: FAIL")
  else if !psKernelRuntimeInvariantTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_RUNTIME_INVARIANT: FAIL")
  else if !psKernelSelfHostWhnfTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_WHNF_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostInferTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_INFER_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostProjectionTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_PROJECTION_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostRecursorTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_RECURSOR_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostDefEqTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_DEFEQ_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostNestedTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NESTED_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostNestedMultiFamilyTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NESTED_MULTI_FAMILY_CONFORMANCE: FAIL")
  else if !psKernelSelfHostNestedRejectionTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NESTED_REJECTION_DIFFERENTIAL: FAIL")
  else
    IO.println
      "PSC1_KERNEL_SELFHOST_FOUNDATION_DIFFERENTIAL: PASS"
