import Ps.KernelCore.Research.ExprV2PortableInstantiate

/-
Expression V2 M3: portable checked head-reduction primitives.

These implement ONLY the isolated semantic head steps below, using the
qualified sharing-aware instantiate1:
  (fun x => body) arg  --> instantiate1(body, arg)
  let x := value; body --> instantiate1(body, value)
  mdata metadata body  --> body

Neutral applications, sorts, projections and other constructors are left
unchanged. This is NOT a complete WHNF algorithm: head normalization of an
arbitrary application function, delta, recursor/iota, projections, primitives,
universe comparisons and theorem checking remain explicitly out of scope.

A canonical V2 DAG must be reconstructed from validated source metadata
before either reduction; no hash or node ID alone authorizes a result.
-/

def psKernelExprV2PortableHeadStepChecked
    (source : PsKernelExprV2ChunkedArena)
    (root : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2PortableValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2ChunkedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_HEAD_STEP_INVALID_ROOT"
      | Option.some entry =>
          match entry.node with
          | PsKernelExprV2Node.letE _ _ value body _ =>
              psKernelExprV2PortableInstantiate1Checked
                canonical body value
          | PsKernelExprV2Node.app fn arg =>
              match psKernelExprV2ChunkedFind canonical fn with
              | Option.none =>
                  Except.error "PSKERNEL_V2_HEAD_STEP_INVALID_FUNCTION"
              | Option.some fnEntry =>
                  match fnEntry.node with
                  | PsKernelExprV2Node.lam _ _ body _ =>
                      psKernelExprV2PortableInstantiate1Checked
                        canonical body arg
                  | _ =>
                      Except.ok (Prod.mk canonical root)
          | PsKernelExprV2Node.mdata _ body =>
              Except.ok (Prod.mk canonical body)
          | _ =>
              Except.ok (Prod.mk canonical root)
