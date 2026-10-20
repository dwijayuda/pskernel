import Ps.KernelCore.SelfHost
import Ps.KernelCore.Research.ExprV2ResearchAll

/-
Non-trusted integration/benchmark root. Both the published 79-module
PSKernel-Core checker and the V2 research graph run inside one generated
JavaScript artifact, with *no* production imports of Research V2.
This root exists ONLY to exercise matched executable positive and negative
checker verdicts and to expose end-to-end V2 conversion overhead.
-/
def psKernelExprV2CheckerBridgeRoot : Bool := true
