import Ps.BackendTs.Compiler

-- Compiler-only self-host composition root.
-- Kernel checking is a host-side gate and is deliberately outside the generated
-- bootstrap closure. The default host checker is the pinned Lean 4.34 WASM provider.
