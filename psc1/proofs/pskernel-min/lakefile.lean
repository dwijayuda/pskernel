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

lean_lib PsMinRegularRuntime where
  srcDir := "../../packages/pskernel-min/src"
  roots := #[`Ps.MinKernel.Profile.RegularProfile, `Ps.MinKernel.Profile.RegularCheck,
    `Ps.MinKernel.Profile.RegularNames, `Ps.MinKernel.Tests.RegularVectors]

lean_lib PsMinOperationalRuntime where
  srcDir := "../../packages/pskernel-min/src"
  roots := #[`Ps.MinKernel.Profile.OperationalProfile, `Ps.MinKernel.Profile.OperationalCheck]

@[default_target]
lean_lib MinKernelProof where
  srcDir := "."
  roots := #[`MainTheorem, `CoreScope, `BinderLowering, `RegularModel, `RegularSoundness, `RegularValidation, `RegularNames, `RegularSourceInstance, `OperationalProjection, `OperationalFoundation, `OperationalSoundness]

lean_exe regular_core_witness where
  srcDir := "."
  root := `RegularCoreWitness
