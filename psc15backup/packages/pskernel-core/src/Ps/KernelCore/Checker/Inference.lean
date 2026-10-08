import Ps.KernelCore.Checker.Inference.Core

/-
Public inference/check entry points.

`psKernelInferWithFuel` performs inference-only checking.
`psKernelCheckWithFuel` performs the fully checked path.
Both delegate to the same syntax-directed core so the semantic difference is
explicit and small.
-/

def psKernelInferWithFuel
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelInferCoreWithFuel
    fuel
    whnf
    defeq
    context
    state
    expr
    true

def psKernelCheckWithFuel
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelInferCoreWithFuel
    fuel
    whnf
    defeq
    context
    state
    expr
    false
