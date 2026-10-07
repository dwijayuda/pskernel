import KernelCore.Foundation.KernelContract
import KernelCore.Foundation.AdmissionRuntime
import KernelCore.Foundation.CheckerOps

def psKernelContractExpressionDiagnostic : String :=
  match psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault with
  | Except.error error =>
      "session=" ++ toString (psKernelContractOutcomeTag (psKernelErrorOutcome error))
  | Except.ok session =>
      let invalidApp := PsKernelExpr.app
        (PsKernelExpr.lam PsKernelName.anonymous psKernelContractSort
          (PsKernelExpr.bvar 0) PsKernelBinderInfo.default)
        psKernelContractSort
      "sort=" ++
        toString (psKernelContractResultTag (psKernelV1CheckExpression session List.nil
          PsKernelDefinitionSafety.safe psKernelContractSort)) ++
      ";check-invalid=" ++
        toString (psKernelContractResultTag (psKernelV1CheckExpression session List.nil
          PsKernelDefinitionSafety.safe invalidApp)) ++
      ";whnf-invalid=" ++
        toString (psKernelContractResultTag (psKernelV1Whnf session List.nil
          PsKernelDefinitionSafety.safe invalidApp)) ++
      ";defeq-invalid=" ++
        toString (psKernelContractResultTag (psKernelV1IsDefEq session List.nil
          PsKernelDefinitionSafety.safe invalidApp invalidApp)) ++
      ";defeq-sort=" ++
        (match psKernelV1IsDefEq session List.nil PsKernelDefinitionSafety.safe
            psKernelContractSort psKernelContractSort with
         | Except.ok equal => toString equal
         | Except.error error =>
             "error:" ++ toString (psKernelContractOutcomeTag (psKernelErrorOutcome error)))

def main : IO Unit :=
  if !psKernelContractDiagnosticTests then
    throw (IO.userError "PSC1_KERNEL_CONTRACT_DIAGNOSTICS: FAIL")
  else if !psKernelContractAdmissionTests then
    throw (IO.userError "PSC1_KERNEL_CONTRACT_ADMISSION: FAIL")
  else if !psKernelContractExpressionTests then
    throw (IO.userError
      ("PSC1_KERNEL_CONTRACT_EXPRESSION: FAIL; " ++ psKernelContractExpressionDiagnostic))
  else if !psKernelContractResourceTests then
    throw (IO.userError "PSC1_KERNEL_CONTRACT_RESOURCE: FAIL")
  else if !psKernelContractProviderTests then
    throw (IO.userError "PSC1_KERNEL_CONTRACT_PROVIDER: FAIL")
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
