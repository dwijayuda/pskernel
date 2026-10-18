/-!
PSC0 v7.2 native-Lean source used only to qualify the current Wasm-GC backend.

This is *not* a Lean kernel, cannot accept proof admissions, and is not a
substitute for Lean 4.35.0 Kernel.Environment.addDeclCore.

The record is deliberately retained in the computation to exercise GC
structure allocation and projection rather than a scalar-only wasm build.
-/

structure PsKernelGcPair where
  left : Bool
  right : Bool

def pskernelWasmGcProbe (left : Bool) (right : Bool) : Bool :=
  let cell : PsKernelGcPair := { left := left, right := right }
  if cell.left then cell.right else false
