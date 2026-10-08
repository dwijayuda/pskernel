import Lake
open Lake DSL

package psc2LeanChecked

require proofscriptSelfhost from ".."

lean_lib PsKernelLean where
  srcDir := "../packages/pskernel-lean/provider"
  roots := #[`PsKernelLean.Error, `PsKernelLean.Convert, `PsKernelLean.Protocol,
    `PsKernelLean.Prelude, `PsKernelLean.Admission, `PsKernelLean.Response,
    `PsKernelLean.Main]

lean_lib PsLeanChecked where
  srcDir := "../host/src"
  roots := #[`Ps.Host.LeanChecked, `Ps.Host.CheckedSeedProducts]

@[default_target]
lean_exe psc2_lean_checked_seed where
  srcDir := "../scripts"
  root := `LeanCheckedSeed

lean_exe psc2_lean_kernel_provider where
  srcDir := "../packages/pskernel-lean/provider"
  root := `PsKernelLean.Main

lean_exe psc2_lean_kernel_provider_tests where
  srcDir := "../packages/pskernel-lean/provider-test"
  root := `PsKernelLeanTests
