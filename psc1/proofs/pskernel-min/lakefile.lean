import Lake
open Lake DSL
package psc1MinKernelProof

-- The proof builds the exact runtime source, without copying or changing it.
lean_lib PsMinKernelRuntime where
  srcDir := "../../packages/pskernel-min/src"
  roots := #[`Ps.MinKernel.Check]

@[default_target]
lean_lib MinKernelProof where
  srcDir := "."
  roots := #[`MainTheorem]
