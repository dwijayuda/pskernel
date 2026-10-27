import Lake
open Lake DSL
package psc1MinKernelProof

-- The proof builds the exact runtime source, without copying or changing it.
lean_lib PsMinKernelRuntime where
  srcDir := "../../packages/pskernel-min/src"
  roots := #[`Ps.MinKernel.Check]

-- Exact existing Core implementation used by the scope law, proof-only here.
lean_lib PsMinCoreFoundation where
  srcDir := "../../packages/foundation/src"
  roots := #[`Ps.Foundation.Name]

lean_lib PsMinCoreSyntax where
  srcDir := "../../packages/core/src"
  roots := #[`Ps.Core.Level, `Ps.Core.Expr, `Ps.Core.Subst]

lean_lib PsMinBinderRuntime where
  srcDir := "../../packages/pskernel-min/src"
  roots := #[`Ps.MinKernel.Profile.LowerUnusedBinder]

@[default_target]
lean_lib MinKernelProof where
  srcDir := "."
  roots := #[`MainTheorem, `CoreScope, `BinderLowering]
