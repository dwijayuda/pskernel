import Ps.KernelCore.Admission.Inductive.Nested.Flatten

theorem psKernelSimpleNestedMapExprWithFuel_zero
    (environment : PsKernelEnvironment)
    (declLevels newNames : List PsKernelName)
    (canonicalParams currentParams : List PsKernelOpenBinder)
    (expr : PsKernelExpr)
    (state : PsKernelSimpleNestedMapState) :
    psKernelSimpleNestedMapExprWithFuel
        0 environment declLevels newNames canonicalParams
        currentParams expr state =
      Except.error
        "nested expression mapping budget exhausted" := by
  rfl

theorem psKernelSimpleNestedProcessQueueWithFuel_zero
    (environment : PsKernelEnvironment)
    (declLevels newNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (pending done : List PsKernelSimpleMutualTypeDecl)
    (state : PsKernelSimpleNestedMapState) :
    psKernelSimpleNestedProcessQueueWithFuel
        0 environment declLevels newNames canonicalParams
        numParams pending done state =
      Except.error
        "nested preprocessing queue budget exhausted" := by
  rfl
