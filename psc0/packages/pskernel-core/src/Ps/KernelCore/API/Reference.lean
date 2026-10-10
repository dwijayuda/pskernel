import Ps.KernelCore.API.Kernel

/-!
Executable reference entry points. Each fixes the disabled semantic cache policy
at elaboration; callers cannot replace it by supplying a different instance.
These use the same checking/admission rules and resource errors as the existing
API. A successful run is not yet a full semantic soundness theorem.
-/
abbrev psKernelReferenceCheckExpression :=
  @psKernelV1CheckExpression psKernelReferenceCachePolicy

abbrev psKernelReferenceWhnf :=
  @psKernelV1Whnf psKernelReferenceCachePolicy

abbrev psKernelReferenceIsDefEq :=
  @psKernelV1IsDefEq psKernelReferenceCachePolicy

abbrev psKernelReferenceCheckDeclaration :=
  @psKernelV1CheckDeclaration psKernelReferenceCachePolicy

abbrev psKernelReferenceAdmitDeclaration :=
  @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy

abbrev psKernelReferenceAdmitChecked :=
  @psKernelV1AdmitChecked psKernelReferenceCachePolicy
