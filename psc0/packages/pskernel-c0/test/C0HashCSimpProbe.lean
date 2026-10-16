import Ps.KernelCore.Runtime.Acceleration.CertifiedHashMemo

/-!
Compile-only proof-safe csimp check: this intentionally invokes the ORIGINAL
source hash on a shared DAG too large for repeated tree expansion. A native
compiler that recognizes the Lean-checked @f=@g csimp theorem replaces the
runtime call with exactly equivalent memoized hashing. An interpreter run
is NOT a valid performance test for this compiler optimization.
-/
def c0MemoCSimpExpected (start : Nat) (depth : Nat) : Nat :=
  (List.range depth).foldl
    (fun h (_ : Nat) => psKernelCacheMix (psKernelCacheMix 26 h) h)
    start

def main : IO Unit := do
  let base : PsKernelExpr := .lit (.nat 13)
  let depth := 30
  let expr := (List.range depth).foldl
    (fun x (_ : Nat) => .app x x) base
  let start ← IO.monoNanosNow
  -- The original source symbol MUST be invoked in this compiled test:
  -- csimp is responsible for choosing the certified fast implementation.
  let hash := psKernelExprHash expr
  let finish ← IO.monoNanosNow
  let expected := c0MemoCSimpExpected (psKernelExprHash base) depth
  if hash != expected then
    throw (IO.userError "csimp emitted a wrong C0 source expression hash")
  IO.println s!"C0_HASH_CSIMP_NATIVE depth={depth} exact_source=pass elapsed_ms={(finish-start)/1000000}"
