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
