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
