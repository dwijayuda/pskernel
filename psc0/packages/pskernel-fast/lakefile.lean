import Lake
open Lake DSL

package pskernelFast where

lean_lib PSKernelFast where
  roots := #[`PSKernelFast.Core]

lean_exe pskernel_fast_mvp where
  root := `Main
