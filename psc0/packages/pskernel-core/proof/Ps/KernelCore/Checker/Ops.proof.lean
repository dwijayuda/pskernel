import Ps.KernelCore.Checker.Ops

theorem psKernelCheckerOps_eta
    (ops : PsKernelCheckerOps) :
    PsKernelCheckerOps.mk
        ops.infer
        ops.check
        ops.whnfCore
        ops.whnf
        ops.defeq
        ops.reduceRecursor =
      ops := by
  cases ops
  rfl
