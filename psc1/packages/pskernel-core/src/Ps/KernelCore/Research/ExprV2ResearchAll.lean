import Ps.KernelCore.Research.ExprV2IndexedBuilder
import Ps.KernelCore.Research.ExprV2Chunked
import Ps.KernelCore.Research.ExprV2ChunkedBuilder
import Ps.KernelCore.Research.ExprV2PortableValidation
import Ps.KernelCore.Research.ExprV2PortableLift
import Ps.KernelCore.Research.ExprV2PortableInstantiate
import Ps.KernelCore.Research.ExprV2PortableReduction
import Ps.KernelCore.Research.ExprV2PortableHeadSequence
import Ps.KernelCore.Research.ExprV2PortableHeadMachine
import Ps.KernelCore.Research.ExprV2PortableEquality
import Ps.KernelCore.Research.ExprV2PortableEqualityBatch
import Ps.KernelCore.Research.ExprV2PortableImport

/- Test-only composition root to compile every V2 storage model with the real PSC1 compiler. -/
def psKernelExprV2ResearchAllPresent : Bool := true
