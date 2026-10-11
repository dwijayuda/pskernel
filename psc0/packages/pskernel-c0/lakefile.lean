import Lake
open Lake DSL

package pskernelC0

-- Native Lean-only build of C0; no compiler bootstrap or self-host run.
lean_lib PsKernelC0 where
  srcDir := "src"
  roots := #[`Ps.KernelCore.SelfHost]
