import Lake
open Lake DSL

package proofscriptSelfhost

-- PSC1's independent kernel is intentionally opt-in: no default compiler target
-- imports this library or treats it as an automatically qualified proof provider.
lean_lib PsKernelCore where
  srcDir := "packages/pskernel-core/src"
  roots := #[`Ps.KernelCore.SelfHost]

lean_exe psc1_kernel_regression where
  srcDir := "test"
  root := `PsKernelCoreRegression
