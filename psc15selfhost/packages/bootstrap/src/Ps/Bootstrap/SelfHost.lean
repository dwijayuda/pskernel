import Ps.BackendTs.Compiler
import Ps.Kernel.Admission
import Ps.Kernel.Structural
import Ps.Kernel.ExprInstantiate

-- The joint fixed-point closure contains the compiler and the owned kernel.
-- Source-profile regressions are validated through that transitive compiler closure.
-- Duplicate-name source normalization is verified by the focused self-host gate.
-- Match-fields patch transport is temporary and does not change bootstrap semantics.
-- Match-fields line-safe transport rerun.
