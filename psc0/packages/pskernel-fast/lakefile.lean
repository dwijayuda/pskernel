import Lake
open Lake DSL

package pskernelFast where

lean_lib PSKernelFast where
  roots := #[`PSKernelFast.Name, `PSKernelFast.Level, `PSKernelFast.Core, `PSKernelFast.EvalPrototype, `PSKernelFast.Substitution, `PSKernelFast.Quote, `PSKernelFast.TinyTyping]

lean_exe pskernel_fast_mvp where
  root := `Main

lean_exe pskernel_fast_bench where
  root := `Bench
