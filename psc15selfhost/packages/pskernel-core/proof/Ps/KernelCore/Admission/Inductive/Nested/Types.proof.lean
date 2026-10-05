import Ps.KernelCore.Admission.Inductive.Nested.Types

theorem psKernelSimpleNestedMapState_eta
    (state : PsKernelSimpleNestedMapState) :
    PsKernelSimpleNestedMapState.mk
        state.aux
        state.fresh
        state.created =
      state := by
  cases state
  rfl
