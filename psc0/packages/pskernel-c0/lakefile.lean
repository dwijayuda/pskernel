import Lake
open Lake DSL

package pskernelC0

@[default_target]
lean_lib PsKernelC0 where
  srcDir := "src"
  roots := #[`Ps.KernelCore.SelfHost]

lean_exe pskernel_c0_beta_tests where
  srcDir := "test"
  root := `C0BetaTests
