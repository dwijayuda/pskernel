import Lake
open Lake DSL

package pskernelFast where
  version := v!"0.1.0"

lean_lib PSKernelFast where
  srcDir := "src"

@[default_target]
lean_exe pskernel_fast_smoke where
  root := `PSKernelFast.Smoke
  srcDir := "src"

lean_exe pskernel_fast_eval_smoke where
  root := `PSKernelFast.ReductionSmoke
  srcDir := "src"

lean_exe pskernel_fast_eval_bench where
  root := `PSKernelFast.ReductionBench
  srcDir := "src"

lean_exe pskernel_fast_core_syntax_smoke where
  root := `PSKernelFast.CoreSyntaxSmoke
  srcDir := "src"

lean_exe pskernel_fast_symbolic_level_smoke where
  root := `PSKernelFast.SymbolicLevelSmoke
  srcDir := "src"

lean_exe pskernel_fast_catalog_smoke where
  root := `PSKernelFast.CandidateCatalogSmoke
  srcDir := "src"

lean_exe pskernel_fast_sort_fragment_smoke where
  root := `PSKernelFast.SortFragmentSmoke
  srcDir := "src"

lean_exe pskernel_fast_scoped_context_smoke where
  root := `PSKernelFast.ScopedContextSmoke
  srcDir := "src"

lean_exe pskernel_fast_general_pi_smoke where
  root := `PSKernelFast.GeneralPiFormationSmoke
  srcDir := "src"

lean_exe pskernel_fast_typed_conversion_smoke where
  root := `PSKernelFast.TypedConversionSmoke
  srcDir := "src"

lean_exe pskernel_fast_typed_conversion_bench where
  root := `PSKernelFast.TypedConversionBench
  srcDir := "src"
