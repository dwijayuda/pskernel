import Ps.KernelCore.Core.Declaration

theorem psKernelConstantInfoName_is_base_name
    (info : PsKernelConstantInfo) :
    psKernelConstantInfoName info =
      (psKernelConstantInfoBase info).name := by
  rfl

theorem psKernelConstantInfoLevelParams_is_base
    (info : PsKernelConstantInfo) :
    psKernelConstantInfoLevelParams info =
      (psKernelConstantInfoBase info).levelParams := by
  rfl

theorem psKernelConstantInfoType_is_base_type
    (info : PsKernelConstantInfo) :
    psKernelConstantInfoType info =
      (psKernelConstantInfoBase info).type := by
  rfl

theorem psKernelTheorem_not_unsafe
    (value : PsKernelTheoremInfo) :
    psKernelConstantInfoIsUnsafe
        (PsKernelConstantInfo.thmInfo value) =
      false := by
  rfl

theorem psKernelQuot_not_unsafe
    (value : PsKernelQuotInfo) :
    psKernelConstantInfoIsUnsafe
        (PsKernelConstantInfo.quotInfo value) =
      false := by
  rfl

theorem psKernelDefinition_delta_value
    (value : PsKernelDefinitionInfo) :
    psKernelConstantInfoDeltaValue
        (PsKernelConstantInfo.defnInfo value) =
      Option.some value.value := by
  rfl

theorem psKernelTheorem_no_delta_value
    (value : PsKernelTheoremInfo) :
    psKernelConstantInfoDeltaValue
        (PsKernelConstantInfo.thmInfo value) =
      Option.none := by
  rfl
