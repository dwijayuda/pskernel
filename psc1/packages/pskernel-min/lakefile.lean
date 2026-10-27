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
