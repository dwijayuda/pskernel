import Lake
open Lake DSL

package pscv0Native

-- The official RC4 toolchain compiles the shared sources directly.
-- The historical parent workspace/toolchain and portable closure are unchanged.
require proofscriptSelfhost from ".."

lean_lib PsV7Syntax where
  srcDir := "../packages/syntax/src"
  roots := #[`Ps.Syntax.Pscv0.TermRead, `Ps.Syntax.Pscv0.Surface,
    `Ps.Syntax.Pscv0.Read, `Ps.Syntax.Pscv0.Commands,
    `Ps.Syntax.Pscv0.TypePrint, `Ps.Syntax.Pscv0.Module]

lean_lib PsV7Compiler where
  srcDir := "../packages/compiler/src"
  roots := #[`Ps.Compiler.Pscv0]

-- Host-only conversion and canonical decoder; no provider executable/kernel build.
-- Protocol's historical 4.34 identity functions are not used by NativeV7.
lean_lib PsKernelLean where
  srcDir := "../packages/pskernel-lean/provider"
  roots := #[`PsKernelLean.Error, `PsKernelLean.Convert,
    `PsKernelLean.Protocol, `PsKernelLean.Prelude]

lean_lib PsV7Host where
  srcDir := "../host/src"
  roots := #[`Ps.Host.NativeV7]

lean_lib PsV7ParserChecks where
  srcDir := "../scripts"
  roots := #[`Pscv0M1Harness]

@[default_target]
lean_exe pscv0_native where
  srcDir := "../scripts"
  root := `Pscv0Native

lean_exe pscv0_native_checks where
  srcDir := "../test"
  root := `Pscv0NativeTests
