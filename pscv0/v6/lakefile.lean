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

-- Research-only source compatibility probes. These roots are not linked into
-- the V6 core or CLI. They test whether selected old Lean algorithms can be
-- extracted under the current Lean 4.35 toolchain without preserving old APIs.
lean_lib PscvReuseProbeFoundation where
  srcDir := "../packages/foundation/src"
  roots := #[`Ps.Foundation.Name, `Ps.Foundation.List, `Ps.Foundation.Source, `Ps.Foundation.Text, `Ps.Foundation.Diagnostic]

lean_lib PscvReuseProbeRuntimeIr where
  srcDir := "../packages/compiler-ir/src"
  roots := #[`Ps.CompilerIr.Model]

lean_lib PscvReuseProbeInterfaceIr where
  srcDir := "../packages/interface-ir/src"
  roots := #[`Ps.InterfaceIr.Model, `Ps.InterfaceIr.Validate]

-- Research-only behavioral probe of imported old typed IR/WIT validators.
lean_exe pscv_v6_reuse_smoke where
  srcDir := "test/lean"
  root := `ReuseBehavior

-- Import only the old .ps parser source to test 4.35 build compatibility.
-- This is NOT the extensible V6 parser and is not linked into pscv_v6_dev.
lean_lib PscvReuseProbeSyntax where
  srcDir := "../packages/syntax/src"
  roots := #[
    `Ps.Syntax.Token,
    `Ps.Syntax.Cursor,
    `Ps.Syntax.Lexer,
    `Ps.Syntax.Ast,
    `Ps.Syntax.ParserState,
    `Ps.Syntax.ParseCommon,
    `Ps.Syntax.ParseProofScript
  ]

-- Independent kernel host: not linked into the small native compiler CLI.
lean_exe pscv_v6_kernel_dev where
  srcDir := "packages/kernel/src"
  root := `PscvKernelMain

-- Research-only pure Lean executable baseline: measure default runtime overhead.
lean_exe pscv_v6_minimal_probe where
  srcDir := "test/lean"
  root := `MinimalProbe
