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

-- Experimental Core syntax helper; the existing default checker root is unchanged.
lean_lib PsMinProfileFoundation where
  srcDir := "../foundation/src"
  roots := #[`Ps.Foundation.Name]

lean_lib PsMinProfileSyntax where
  srcDir := "../core/src"
  roots := #[`Ps.Core.Level, `Ps.Core.Expr, `Ps.Core.Equality]

lean_lib PsMinBinderProfile where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Profile.LowerUnusedBinder, `Ps.MinKernel.Tests.BinderVectors]

lean_exe minkernel_binder_tests where
  srcDir := "test"
  root := `BinderTests

lean_lib PsMinRegularProfile where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Profile.RegularProfile, `Ps.MinKernel.Profile.RegularCheck,
    `Ps.MinKernel.Profile.RegularNames, `Ps.MinKernel.Tests.RegularVectors]

lean_exe minkernel_regular_tests where
  srcDir := "test"
  root := `RegularTests

lean_lib PsMinOperationalProfile where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Profile.OperationalProfile, `Ps.MinKernel.Profile.OperationalCheck,
    `Ps.MinKernel.Tests.OperationalVectors]

lean_exe minkernel_operational_tests where
  srcDir := "test"
  root := `OperationalTests

lean_lib PsMinCoreIngress where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Profile.CoreBytes, `Ps.MinKernel.Profile.CoreIngress, `Ps.MinKernel.Tests.IngressVectors]

lean_exe minkernel_ingress_tests where
  srcDir := "test"
  root := `IngressTests

lean_lib PsMinRegularCoreIngress where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Profile.RegularIngressProfile, `Ps.MinKernel.Profile.RegularIngressOperational, `Ps.MinKernel.Profile.RegularIngressCheck,
    `Ps.MinKernel.Profile.RegularIngressBytes, `Ps.MinKernel.Tests.RegularIngressVectors]

lean_exe minkernel_regular_ingress_tests where
  srcDir := "test"
  root := `RegularIngressTests

-- R5 test-only source; excluded from the connected checker scope.
lean_lib PsMinCompilerScalarFixture where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Tests.CompilerScalar]

-- R6 test-only compatibility fixture; not in the connected checker.
lean_lib PsMinStringBridgeFixture where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Tests.StringBridge, `Ps.MinKernel.Tests.EmitterBridge]
