import Lake
open Lake DSL
package psc1MinKernel

@[default_target]
lean_lib PsMinKernel where
  srcDir := "src"
  roots := #[`Ps.MinKernel.Check]
