import Ps.BackendTs.Compiler

-- Keep this bootstrap root intentionally minimal: the fixed-point closure starts here.
-- Source-profile regressions are validated through that transitive compiler closure.
-- Duplicate-name source normalization is verified by the focused self-host gate.
-- Patch transport diagnostics are temporary and do not change bootstrap semantics.
