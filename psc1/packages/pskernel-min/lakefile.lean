import Lake
open Lake DSL
package psc1MinKernel

@[default_target]
lean_lib PsMinKernel where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Check]

lean_lib PsMinKernelTestVectors where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Tests.Vectors]

lean_exe minkernel_tests where
  srcDir := "test"
  root := `NativeTests
