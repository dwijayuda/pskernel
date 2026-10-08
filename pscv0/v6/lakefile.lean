import Lake
open Lake DSL

package pscvV6 where
  -- Lean 4 is the build host; native artifacts are packaged separately for npm.
  moreLeanArgs := #[]

lean_lib PscvCore where
  srcDir := "packages/core/src"
  roots := #[`Pscv.Core.Model]

lean_lib PscvExtensions where
  srcDir := "packages/extensions/src"
  roots := #[`Pscv.Extensions.Policy]

lean_lib PscvKernel where
  srcDir := "packages/kernel/src"
  roots := #[`Pscv.Kernel.Checker]

@[default_target]
lean_exe pscv_v6_dev where
  srcDir := "packages/cli/src"
  root := `PscvDevMain

lean_exe pscv_v6_native_tests where
  srcDir := "test/lean"
  root := `NativeSmoke
